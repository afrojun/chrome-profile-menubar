import Foundation

enum ChromeWindowTitleMatcher {
    private static func profileLabel(profileName: String, personName: String?) -> String {
        guard
            let personName = personName?.trimmingCharacters(in: .whitespacesAndNewlines),
            !personName.isEmpty,
            personName.caseInsensitiveCompare(profileName) != .orderedSame
        else { return profileName }
        return "\(personName) (\(profileName))"
    }

    static func matches(windowTitle: String, profileName: String, personName: String?) -> Bool {
        let title = windowTitle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let label = profileLabel(profileName: profileName, personName: personName).lowercased()
        return title == label
            || title.hasSuffix(" – \(label)")
            || title.hasSuffix(" — \(label)")
            || title.hasSuffix(" - \(label)")
    }
}
