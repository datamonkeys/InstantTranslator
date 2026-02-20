import SwiftUI

struct SettingsView: View {
    @State private var targetLanguage: String = AppSettings.shared.targetLanguage
    @State private var showSaved: Bool = false

    private let languages = [
        "English", "Portuguese", "Spanish", "French", "German",
        "Italian", "Chinese (Simplified)", "Chinese (Traditional)",
        "Japanese", "Korean", "Russian", "Arabic", "Hindi",
        "Dutch", "Swedish", "Polish", "Turkish", "Vietnamese",
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 4) {
                Image(systemName: "character.bubble")
                    .font(.system(size: 28))
                    .foregroundColor(.accentColor)
                Text("InstantTranslator")
                    .font(.headline)
            }
            .padding(.top, 20)
            .padding(.bottom, 16)

            Form {
                Section("Authentication") {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Using Claude CLI")
                            .font(.body)
                        Spacer()
                    }
                    Text("Run 'claude setup-token' in Terminal if not authenticated")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Translation") {
                    Picker("Target Language", selection: $targetLanguage) {
                        ForEach(languages, id: \.self) { lang in
                            Text(lang).tag(lang)
                        }
                    }
                }

                Section("Shortcuts") {
                    HStack {
                        Text("Translate")
                        Spacer()
                        Text("⌥⇧T")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Fix Grammar")
                        Spacer()
                        Text("⌥⇧G")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                if showSaved {
                    Text("Saved!")
                        .foregroundColor(.green)
                        .font(.caption)
                        .transition(.opacity)
                }
                Spacer()
                Button("Save") {
                    save()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .frame(width: 380, height: 420)
        .onAppear { load() }
    }

    private func load() {
        targetLanguage = AppSettings.shared.targetLanguage
    }

    private func save() {
        AppSettings.shared.targetLanguage = targetLanguage
        withAnimation {
            showSaved = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showSaved = false
            }
        }
    }
}
