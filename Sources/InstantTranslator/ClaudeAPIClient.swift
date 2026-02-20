import Foundation

enum TranslationError: LocalizedError {
    case noTextSelected
    case cliNotFound
    case cliError(statusCode: Int, message: String)
    case networkError(underlying: Error)
    case rateLimited(retryAfterSeconds: Int?)
    case responseParsingFailed

    var errorDescription: String? {
        switch self {
        case .noTextSelected:
            return "No text selected"
        case .cliNotFound:
            return "Claude CLI not found. Install it from https://docs.anthropic.com/en/docs/claude-code or run: brew install anthropics/claude/claude"
        case .cliError(let code, let msg):
            return "Claude error (\(code)): \(msg)"
        case .networkError(let err):
            return "Error: \(err.localizedDescription)"
        case .rateLimited(let retry):
            if let seconds = retry {
                return "Rate limited. Retry in \(seconds)s"
            }
            return "Rate limited"
        case .responseParsingFailed:
            return "Could not parse response"
        }
    }
}

class ClaudeAPIClient {
    init() {
        // No initialization needed for CLI approach
    }

    private func findClaudeCLI() -> URL? {
        // Common installation paths for Claude CLI
        let possiblePaths = [
            "/usr/local/bin/claude",
            "/opt/homebrew/bin/claude",
            "\(NSHomeDirectory())/.local/bin/claude"
        ]

        for path in possiblePaths {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }

        return nil
    }

    private func runCLICommand(_ prompt: String) async throws -> String {
        guard let claudePath = findClaudeCLI() else {
            throw TranslationError.cliNotFound
        }

        let process = Process()
        process.executableURL = claudePath
        // Use Haiku model for faster responses and pass prompt as argument
        process.arguments = ["--model", "claude-haiku-4-5-20251001", prompt]

        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.standardOutput = outputPipe
        process.standardError = errorPipe

        return try await withCheckedThrowingContinuation { continuation in
            do {
                try process.run()
                process.waitUntilExit()

                if process.terminationStatus != 0 {
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                    continuation.resume(throwing: TranslationError.cliError(statusCode: Int(process.terminationStatus), message: errorMessage.trimmingCharacters(in: .whitespacesAndNewlines)))
                    return
                }

                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                guard let output = String(data: outputData, encoding: .utf8), !output.isEmpty else {
                    continuation.resume(throwing: TranslationError.responseParsingFailed)
                    return
                }

                continuation.resume(returning: output.trimmingCharacters(in: .whitespacesAndNewlines))
            } catch {
                continuation.resume(throwing: TranslationError.networkError(underlying: error))
            }
        }
    }


    func send(text: String, mode: TranslationMode, targetLanguage: String) async throws -> String {
        // Build a simple user-facing prompt that includes the instructions
        let instruction: String
        switch mode {
        case .translate:
            instruction = "Translate the following text to \(targetLanguage). Only return the translation, nothing else:"
        case .grammarFix:
            instruction = "Fix the grammar and spelling in the following text. Only return the corrected text, nothing else:"
        }

        let fullPrompt = "\(instruction)\n\n\(text)"

        // Run via CLI
        return try await runCLICommand(fullPrompt)
    }
}
