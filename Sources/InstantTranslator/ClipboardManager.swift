import Cocoa
import CoreGraphics

struct ClipboardEntry {
    let types: [NSPasteboard.PasteboardType]
    let dataByType: [NSPasteboard.PasteboardType: Data]
}

class ClipboardManager {
    private let pasteboard = NSPasteboard.general

    func saveClipboard() -> [ClipboardEntry] {
        guard let items = pasteboard.pasteboardItems else { return [] }
        return items.map { item in
            var dataByType: [NSPasteboard.PasteboardType: Data] = [:]
            for type in item.types {
                if let data = item.data(forType: type) {
                    dataByType[type] = data
                }
            }
            return ClipboardEntry(types: item.types, dataByType: dataByType)
        }
    }

    func restoreClipboard(_ entries: [ClipboardEntry]) {
        pasteboard.clearContents()
        guard !entries.isEmpty else { return }
        let items = entries.map { entry -> NSPasteboardItem in
            let item = NSPasteboardItem()
            for type in entry.types {
                if let data = entry.dataByType[type] {
                    item.setData(data, forType: type)
                }
            }
            return item
        }
        pasteboard.writeObjects(items)
    }

    func readText() -> String? {
        return pasteboard.string(forType: .string)
    }

    func writeText(_ text: String) {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    func simulateCopy() async {
        // Release all modifier keys first so Cmd+C is clean
        releaseAllModifiers()
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms wait for keys to release
        simulateKeyCombo(keyCode: 0x08, flags: .maskCommand) // C
    }

    func simulatePaste() async {
        releaseAllModifiers()
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
        simulateKeyCombo(keyCode: 0x09, flags: .maskCommand) // V
    }

    func currentChangeCount() -> Int {
        return pasteboard.changeCount
    }

    func waitForClipboardChange(previousChangeCount: Int) async -> Bool {
        let deadline = Date().addingTimeInterval(1.0) // longer timeout
        while Date() < deadline {
            if pasteboard.changeCount != previousChangeCount {
                return true
            }
            try? await Task.sleep(nanoseconds: 20_000_000) // 20ms
        }
        return false
    }

    private func releaseAllModifiers() {
        let source = CGEventSource(stateID: .hidSystemState)
        let modifiers: [(CGKeyCode, CGEventFlags)] = [
            (0x37, .maskCommand),    // Left Command
            (0x36, .maskCommand),    // Right Command
            (0x38, .maskShift),      // Left Shift
            (0x3C, .maskShift),      // Right Shift
            (0x3A, .maskAlternate),  // Left Option
            (0x3D, .maskAlternate),  // Right Option
            (0x3B, .maskControl),    // Left Control
            (0x3E, .maskControl),    // Right Control
        ]

        for (keyCode, _) in modifiers {
            if let event = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) {
                event.flags = []
                event.post(tap: .cghidEventTap)
            }
        }
    }

    private func simulateKeyCombo(keyCode: CGKeyCode, flags: CGEventFlags) {
        let source = CGEventSource(stateID: .hidSystemState)

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else {
            return
        }

        keyDown.flags = flags
        keyDown.post(tap: .cghidEventTap)

        keyUp.flags = flags
        keyUp.post(tap: .cghidEventTap)
    }
}
