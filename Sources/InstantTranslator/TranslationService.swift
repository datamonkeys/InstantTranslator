import Foundation

@MainActor
class TranslationService {
    private let apiClient: ClaudeAPIClient
    private let clipboardManager: ClipboardManager
    private let statusBarController: StatusBarController
    private var isProcessing = false

    init(apiClient: ClaudeAPIClient, clipboardManager: ClipboardManager, statusBarController: StatusBarController) {
        self.apiClient = apiClient
        self.clipboardManager = clipboardManager
        self.statusBarController = statusBarController
    }

    func handle(mode: TranslationMode) async {
        guard !isProcessing else { return }
        isProcessing = true

        let previousChangeCount = clipboardManager.currentChangeCount()

        defer {
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                // Don't restore clipboard - keep translation for multiple pastes
                self.isProcessing = false
            }
        }

        statusBarController.setIcon(.loading)

        // Simulate Cmd+C to copy selected text
        await clipboardManager.simulateCopy()

        // Wait for clipboard to update
        let changed = await clipboardManager.waitForClipboardChange(previousChangeCount: previousChangeCount)
        guard changed, let selectedText = clipboardManager.readText(), !selectedText.isEmpty else {
            statusBarController.showError("No text selected")
            return
        }

        // Send to Claude API
        do {
            let targetLanguage = AppSettings.shared.targetLanguage
            let result = try await apiClient.send(text: selectedText, mode: mode, targetLanguage: targetLanguage)

            // Write result to clipboard and paste
            clipboardManager.writeText(result)
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
            await clipboardManager.simulatePaste()

            statusBarController.setIcon(.idle)
        } catch let error as TranslationError {
            statusBarController.showError(error.errorDescription ?? "Unknown error")
        } catch {
            statusBarController.showError("Error: \(error.localizedDescription)")
        }
    }

    func handlePaste(mode: TranslationMode) async {
        guard !isProcessing else { return }
        isProcessing = true

        defer {
            isProcessing = false
        }

        statusBarController.setIcon(.loading)

        // Read directly from clipboard
        guard let clipboardText = clipboardManager.readText(), !clipboardText.isEmpty else {
            statusBarController.showError("Clipboard is empty")
            statusBarController.setIcon(.idle)
            return
        }

        // Send to Claude API
        do {
            let targetLanguage = AppSettings.shared.targetLanguage
            let result = try await apiClient.send(text: clipboardText, mode: mode, targetLanguage: targetLanguage)

            // Write result back to clipboard
            clipboardManager.writeText(result)

            statusBarController.setIcon(.idle)
            // Success - result is now in clipboard ready to paste
        } catch let error as TranslationError {
            statusBarController.showError(error.errorDescription ?? "Unknown error")
        } catch {
            statusBarController.showError("Error: \(error.localizedDescription)")
        }
    }
}
