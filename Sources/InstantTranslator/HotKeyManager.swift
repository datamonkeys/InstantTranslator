import Carbon

final class HotKeyManager {
    typealias Handler = () -> Void

    private var translateHotKeyRef: EventHotKeyRef?
    private var grammarHotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    private var translateHandler: Handler?
    private var grammarHandler: Handler?

    private static let translateID: UInt32 = 1
    private static let grammarID: UInt32 = 2

    static let shared = HotKeyManager()
    private init() {}

    func register(translateHandler: @escaping Handler, grammarHandler: @escaping Handler) {
        self.translateHandler = translateHandler
        self.grammarHandler = grammarHandler

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let handler: EventHandlerUPP = { _, event, _ -> OSStatus in
            return HotKeyManager.shared.handleCarbonEvent(event)
        }

        InstallEventHandler(
            GetEventDispatcherTarget(),
            handler,
            1,
            &eventType,
            nil,
            &eventHandler
        )

        let optionShift = UInt32(optionKey | shiftKey)
        let signature = OSType(0x4954_726E) // "ITrn"

        let translateHotKeyID = EventHotKeyID(signature: signature, id: Self.translateID)
        RegisterEventHotKey(
            UInt32(kVK_ANSI_T),
            optionShift,
            translateHotKeyID,
            GetEventDispatcherTarget(),
            0,
            &translateHotKeyRef
        )

        let grammarHotKeyID = EventHotKeyID(signature: signature, id: Self.grammarID)
        RegisterEventHotKey(
            UInt32(kVK_ANSI_G),
            optionShift,
            grammarHotKeyID,
            GetEventDispatcherTarget(),
            0,
            &grammarHotKeyRef
        )
    }

    private func handleCarbonEvent(_ event: EventRef?) -> OSStatus {
        guard let event = event else { return OSStatus(eventNotHandledErr) }

        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            UInt32(kEventParamDirectObject),
            UInt32(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )

        guard status == noErr else { return status }

        switch hotKeyID.id {
        case Self.translateID:
            translateHandler?()
            return noErr
        case Self.grammarID:
            grammarHandler?()
            return noErr
        default:
            return OSStatus(eventNotHandledErr)
        }
    }

    func unregister() {
        if let ref = translateHotKeyRef {
            UnregisterEventHotKey(ref)
            translateHotKeyRef = nil
        }
        if let ref = grammarHotKeyRef {
            UnregisterEventHotKey(ref)
            grammarHotKeyRef = nil
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }
}
