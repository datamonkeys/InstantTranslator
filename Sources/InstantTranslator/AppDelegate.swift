import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController!
    private var translationService: TranslationService!
    private var settingsWindowController: SettingsWindowController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        AccessibilityChecker.checkAndPrompt()

        settingsWindowController = SettingsWindowController()

        let apiClient = ClaudeAPIClient()
        let clipboardManager = ClipboardManager()

        // Create status bar with callbacks first
        statusBarController = StatusBarController(
            onSettings: { [weak self] in self?.settingsWindowController.show() },
            onQuit: { NSApp.terminate(nil) },
            onPasteAndTranslate: { [weak self] in
                Task { @MainActor in
                    await self?.translationService.handlePaste(mode: .translate)
                }
            },
            onPasteAndFixGrammar: { [weak self] in
                Task { @MainActor in
                    await self?.translationService.handlePaste(mode: .grammarFix)
                }
            }
        )

        translationService = TranslationService(
            apiClient: apiClient,
            clipboardManager: clipboardManager,
            statusBarController: statusBarController
        )

        HotKeyManager.shared.register(
            translateHandler: { [weak self] in
                Task { @MainActor in
                    await self?.translationService.handle(mode: .translate)
                }
            },
            grammarHandler: { [weak self] in
                Task { @MainActor in
                    await self?.translationService.handle(mode: .grammarFix)
                }
            }
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        HotKeyManager.shared.unregister()
    }
}
