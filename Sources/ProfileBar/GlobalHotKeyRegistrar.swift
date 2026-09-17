import Carbon

@MainActor
final class GlobalHotKeyRegistrar {
    private static let signature: OSType = 0x5053_5743  // PSWC

    private var eventHandler: EventHandlerRef?
    private var hotKeyRefs: [EventHotKeyRef] = []
    private var profilesByHotKeyID: [UInt32: ChromeProfile] = [:]
    private let activate: (ChromeProfile) -> Void

    init(activate: @escaping (ChromeProfile) -> Void) {
        self.activate = activate
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else { return OSStatus(eventNotHandledErr) }
                let registrar = Unmanaged<GlobalHotKeyRegistrar>.fromOpaque(userData).takeUnretainedValue()
                return MainActor.assumeIsolated { registrar.handle(event) }
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )
    }

    deinit {
        for hotKeyRef in hotKeyRefs {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandler { RemoveEventHandler(eventHandler) }
    }

    func register(profiles: [ChromeProfile], shortcuts: [String: ProfileHotKey]) -> Set<String> {
        unregisterAll()
        var failedDirectories: Set<String> = []

        for (index, profile) in profiles.enumerated() {
            guard let shortcut = shortcuts[profile.directory] else { continue }
            let id = UInt32(index + 1)
            let hotKeyID = EventHotKeyID(signature: Self.signature, id: id)
            var hotKeyRef: EventHotKeyRef?
            let status = RegisterEventHotKey(
                shortcut.keyCode,
                shortcut.modifiers,
                hotKeyID,
                GetApplicationEventTarget(),
                0,
                &hotKeyRef
            )
            if status == noErr, let hotKeyRef {
                hotKeyRefs.append(hotKeyRef)
                profilesByHotKeyID[id] = profile
            } else {
                failedDirectories.insert(profile.directory)
            }
        }

        return failedDirectories
    }

    private func unregisterAll() {
        for hotKeyRef in hotKeyRefs {
            UnregisterEventHotKey(hotKeyRef)
        }
        hotKeyRefs.removeAll()
        profilesByHotKeyID.removeAll()
    }

    private func handle(_ event: EventRef) -> OSStatus {
        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )
        guard
            status == noErr,
            hotKeyID.signature == Self.signature,
            let profile = profilesByHotKeyID[hotKeyID.id]
        else { return OSStatus(eventNotHandledErr) }

        activate(profile)
        return noErr
    }
}
