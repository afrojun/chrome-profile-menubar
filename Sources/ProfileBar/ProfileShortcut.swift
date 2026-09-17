import AppKit
import Carbon

struct ProfileHotKey: Codable, Equatable {
    let keyCode: UInt32
    let modifiers: UInt32
    let keyLabel: String

    init(keyCode: UInt32, modifiers: UInt32, keyLabel: String) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.keyLabel = keyLabel
    }

    init?(event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        var modifiers: UInt32 = 0
        if flags.contains(.control) { modifiers |= UInt32(controlKey) }
        if flags.contains(.option) { modifiers |= UInt32(optionKey) }
        if flags.contains(.shift) { modifiers |= UInt32(shiftKey) }
        if flags.contains(.command) { modifiers |= UInt32(cmdKey) }
        guard modifiers != 0, let keyLabel = Self.keyLabel(for: event) else { return nil }

        self.init(keyCode: UInt32(event.keyCode), modifiers: modifiers, keyLabel: keyLabel)
    }

    var displayName: String {
        var result = ""
        if modifiers & UInt32(controlKey) != 0 { result += "⌃" }
        if modifiers & UInt32(optionKey) != 0 { result += "⌥" }
        if modifiers & UInt32(shiftKey) != 0 { result += "⇧" }
        if modifiers & UInt32(cmdKey) != 0 { result += "⌘" }
        return result + keyLabel
    }

    static func == (lhs: ProfileHotKey, rhs: ProfileHotKey) -> Bool {
        lhs.keyCode == rhs.keyCode && lhs.modifiers == rhs.modifiers
    }

    private static func keyLabel(for event: NSEvent) -> String? {
        switch event.keyCode {
        case 36: return "↩"
        case 48: return "⇥"
        case 49: return "Space"
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        default:
            guard let characters = event.characters(byApplyingModifiers: []), characters.count == 1 else { return nil }
            return characters.uppercased()
        }
    }
}

final class ProfileShortcutPreferences {
    private let defaults: UserDefaults
    private let shortcutsKey = "profileShortcuts"
    private let visibilityKey = "profileVisibility"
    private let oldVisibilityKey = "showProfileIcons"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var shortcuts: [String: ProfileHotKey] {
        get {
            guard let data = defaults.data(forKey: shortcutsKey) else { return [:] }
            return (try? JSONDecoder().decode([String: ProfileHotKey].self, from: data)) ?? [:]
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            defaults.set(data, forKey: shortcutsKey)
        }
    }

    func setShortcut(_ shortcut: ProfileHotKey?, for profileDirectory: String) {
        var shortcuts = shortcuts
        shortcuts[profileDirectory] = shortcut
        self.shortcuts = shortcuts
    }

    func isProfileVisible(_ profileDirectory: String) -> Bool {
        if let value = visibility[profileDirectory] { return value }
        guard defaults.object(forKey: oldVisibilityKey) != nil else { return true }
        return defaults.bool(forKey: oldVisibilityKey)
    }

    func setProfileVisible(_ isVisible: Bool, for profileDirectory: String) {
        var visibility = visibility
        visibility[profileDirectory] = isVisible
        self.visibility = visibility
    }

    private var visibility: [String: Bool] {
        get {
            guard let data = defaults.data(forKey: visibilityKey) else { return [:] }
            return (try? JSONDecoder().decode([String: Bool].self, from: data)) ?? [:]
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            defaults.set(data, forKey: visibilityKey)
        }
    }
}
