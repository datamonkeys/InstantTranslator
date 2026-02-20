import Cocoa

enum MenuBarIconState {
    case idle
    case loading
    case error
}

class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let onSettings: () -> Void
    private let onQuit: () -> Void
    private let onPasteAndTranslate: () -> Void
    private let onPasteAndFixGrammar: () -> Void
    private var errorMenuItem: NSMenuItem?

    private let languages = [
        "English", "Portuguese", "Spanish", "French", "German",
        "Italian", "Chinese (Simplified)", "Chinese (Traditional)",
        "Japanese", "Korean", "Russian", "Arabic", "Hindi",
        "Dutch", "Swedish", "Polish", "Turkish", "Vietnamese",
    ]

    init(onSettings: @escaping () -> Void,
         onQuit: @escaping () -> Void,
         onPasteAndTranslate: @escaping () -> Void,
         onPasteAndFixGrammar: @escaping () -> Void) {
        self.onSettings = onSettings
        self.onQuit = onQuit
        self.onPasteAndTranslate = onPasteAndTranslate
        self.onPasteAndFixGrammar = onPasteAndFixGrammar
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        setupButton()
        setupMenu()
    }

    private func setupButton() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "character.bubble", accessibilityDescription: "InstantTranslator")
            button.image?.isTemplate = true
        }
    }

    private func setupMenu() {
        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(NSMenuItem(title: "InstantTranslator", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        // Keyboard shortcuts info
        menu.addItem(NSMenuItem(title: "⌥⇧T  Translate Selected", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "⌥⇧G  Fix Grammar", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        // Paste and translate options
        let pasteTranslateItem = NSMenuItem(title: "Paste and Translate", action: #selector(pasteAndTranslateTapped), keyEquivalent: "")
        pasteTranslateItem.target = self
        menu.addItem(pasteTranslateItem)

        let pasteGrammarItem = NSMenuItem(title: "Paste and Fix Grammar", action: #selector(pasteAndFixGrammarTapped), keyEquivalent: "")
        pasteGrammarItem.target = self
        menu.addItem(pasteGrammarItem)

        menu.addItem(NSMenuItem.separator())

        // Language switcher submenu
        let languageItem = NSMenuItem(title: "Target Language", action: nil, keyEquivalent: "")
        let languageMenu = NSMenu()
        for lang in languages {
            let item = NSMenuItem(title: lang, action: #selector(languageSelected(_:)), keyEquivalent: "")
            item.target = self
            item.state = (lang == AppSettings.shared.targetLanguage) ? .on : .off
            languageMenu.addItem(item)
        }
        languageItem.submenu = languageMenu
        menu.addItem(languageItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(settingsTapped), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitTapped), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    func setIcon(_ state: MenuBarIconState) {
        guard let button = statusItem.button else { return }
        switch state {
        case .idle:
            button.image = NSImage(systemSymbolName: "character.bubble", accessibilityDescription: "InstantTranslator")
            removeErrorMenuItem()
        case .loading:
            button.image = NSImage(systemSymbolName: "ellipsis.circle", accessibilityDescription: "Translating...")
        case .error:
            button.image = NSImage(systemSymbolName: "exclamationmark.triangle", accessibilityDescription: "Error")
        }
        button.image?.isTemplate = true
    }

    func showError(_ message: String) {
        setIcon(.error)
        removeErrorMenuItem()
        let item = NSMenuItem(title: "⚠ \(message)", action: nil, keyEquivalent: "")
        item.isEnabled = false
        errorMenuItem = item
        statusItem.menu?.insertItem(item, at: 5)

        DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [weak self] in
            self?.removeErrorMenuItem()
            self?.setIcon(.idle)
        }
    }

    private func removeErrorMenuItem() {
        if let item = errorMenuItem {
            statusItem.menu?.removeItem(item)
            errorMenuItem = nil
        }
    }

    @objc private func settingsTapped() {
        onSettings()
    }

    @objc private func quitTapped() {
        onQuit()
    }

    @objc private func pasteAndTranslateTapped() {
        onPasteAndTranslate()
    }

    @objc private func pasteAndFixGrammarTapped() {
        onPasteAndFixGrammar()
    }

    @objc private func languageSelected(_ sender: NSMenuItem) {
        AppSettings.shared.targetLanguage = sender.title
        updateLanguageCheckmarks()
    }

    private func updateLanguageCheckmarks() {
        guard let menu = statusItem.menu,
              let languageMenuItem = menu.item(withTitle: "Target Language"),
              let languageSubmenu = languageMenuItem.submenu else { return }

        for item in languageSubmenu.items {
            item.state = (item.title == AppSettings.shared.targetLanguage) ? .on : .off
        }
    }
}

extension StatusBarController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        updateLanguageCheckmarks()
    }
}
