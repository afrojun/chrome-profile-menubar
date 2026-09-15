import AppKit
import ApplicationServices

struct ChromeProfile {
    let directory: String
    let name: String
    let personName: String?

    init(directory: String, name: String, personName: String?) throws {
        guard Self.isValidDirectory(directory) else {
            throw ProfileSwitcherError("The Chrome profile directory is invalid.")
        }
        self.directory = directory
        self.name = name
        self.personName = personName
    }

    private static func isValidDirectory(_ directory: String) -> Bool {
        !directory.isEmpty
            && directory != "."
            && directory != ".."
            && !directory.contains("/")
            && !directory.contains("\\")
            && !directory.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains)
    }
}

struct ProfileSwitcherError: LocalizedError {
    let errorDescription: String?
    init(_ message: String) { errorDescription = message }
}

enum ChromeProfileStore {
    static func load() throws -> [ChromeProfile] {
        let localStateURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Google/Chrome/Local State")
        let data = try Data(contentsOf: localStateURL)
        guard
            let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let profile = root["profile"] as? [String: Any],
            let cache = profile["info_cache"] as? [String: [String: Any]]
        else {
            throw ProfileSwitcherError("Chrome's profile list could not be read.")
        }

        return try cache.map { directory, details in
            let name = nonEmpty(details["name"] as? String)
                ?? nonEmpty(details["shortcut_name"] as? String)
                ?? directory
            return try ChromeProfile(
                directory: directory,
                name: name,
                personName: nonEmpty(details["gaia_given_name"] as? String)
            )
        }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private static func nonEmpty(_ value: String?) -> String? {
        value.flatMap { $0.isEmpty ? nil : $0 }
    }
}

enum ChromeProfileActivator {
    static func activate(_ profile: ChromeProfile) throws {
        guard let chrome = NSRunningApplication.runningApplications(withBundleIdentifier: "com.google.Chrome").first else {
            try launch(profile)
            return
        }

        let trustedOptions = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        guard AXIsProcessTrustedWithOptions(trustedOptions) else {
            throw ProfileSwitcherError("Allow Profile Switcher in System Settings → Privacy & Security → Accessibility, then try again.")
        }

        let application = AXUIElementCreateApplication(chrome.processIdentifier)
        if let window = windows(of: application).first(where: {
            ChromeWindowTitleMatcher.matches(
                windowTitle: stringAttribute($0, kAXTitleAttribute),
                profileName: profile.name,
                personName: profile.personName
            )
        }) {
            try raise(window, in: application, chrome: chrome)
        } else {
            try launch(profile)
        }
    }

    private static func launch(_ profile: ChromeProfile) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-na", "Google Chrome", "--args", "--profile-directory=\(profile.directory)"]
        do {
            try process.run()
        } catch {
            throw ProfileSwitcherError("Chrome could not open the “\(profile.name)” profile: \(error.localizedDescription)")
        }
    }

    private static func raise(_ window: AXUIElement, in application: AXUIElement, chrome: NSRunningApplication) throws {
        AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
        AXUIElementSetAttributeValue(application, kAXFocusedWindowAttribute as CFString, window)
        let result = AXUIElementPerformAction(window, kAXRaiseAction as CFString)
        guard result == .success else {
            throw ProfileSwitcherError("Chrome's window could not be raised (Accessibility error \(result.rawValue)).")
        }
        chrome.activate()
    }

    private static func stringAttribute(_ element: AXUIElement, _ attribute: String) -> String {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else { return "" }
        return value as? String ?? ""
    }

    private static func windows(of application: AXUIElement) -> [AXUIElement] {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(application, kAXWindowsAttribute as CFString, &value) == .success else { return [] }
        return value as? [AXUIElement] ?? []
    }
}
