import AppKit
import Carbon

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
        exit(1)
    }
}

@main
struct ChromeWindowTitleMatcherTests {
    static func main() {
        expect(
            ChromeWindowTitleMatcher.matches(
                windowTitle: "Calendar - Google Chrome – Taylor (Work)",
                profileName: "Work",
                personName: "Taylor"
            ),
            "a qualified work-profile window should match"
        )
        expect(
            ChromeWindowTitleMatcher.matches(
                windowTitle: "Image generation review - Google Chrome – Personal",
                profileName: "Personal",
                personName: "Personal"
            ),
            "a personal-profile window should match"
        )
        expect(
            !ChromeWindowTitleMatcher.matches(
                windowTitle: "Calendar - Google Chrome – Taylor (Side Project)",
                profileName: "Work",
                personName: "Taylor"
            ),
            "another profile must not match"
        )
        expect(
            !ChromeWindowTitleMatcher.matches(
                windowTitle: "A page mentioning Taylor (Work)",
                profileName: "Work",
                personName: "Taylor"
            ),
            "page content without Chrome's title separator must not match"
        )
        expect(
            ChromeWindowTitleMatcher.matchesProfileMenuItem(
                title: "Taylor (Work)",
                profileName: "Work",
                personName: "Taylor"
            ),
            "a qualified profile menu item should match"
        )
        expect(
            ChromeWindowTitleMatcher.matchesProfileMenuItem(
                title: "Personal",
                profileName: "Personal",
                personName: "Personal"
            ),
            "a plain profile menu item should match"
        )
        expect(
            !ChromeWindowTitleMatcher.matchesProfileMenuItem(
                title: "Taylor",
                profileName: "Work",
                personName: "Taylor"
            ),
            "a shared person name must not identify a profile"
        )
        expect(
            (try? ChromeProfile(directory: "Default", name: "Personal", personName: nil)) != nil,
            "a normal directory should be valid"
        )
        for directory in ["", ".", "..", "../Work", "Work/Profile", "Work\\Profile", "Work\0Profile"] {
            expect(
                (try? ChromeProfile(directory: directory, name: "Work", personName: nil)) == nil,
                "an unsafe directory must be rejected"
            )
        }

        let hotKey = ProfileHotKey(
            keyCode: 18,
            modifiers: UInt32(controlKey | optionKey),
            keyLabel: "1"
        )
        expect(hotKey.displayName == "⌃⌥1", "a shortcut should use standard macOS modifier symbols")
        let shiftedNumber = ProfileHotKey(
            keyCode: 25,
            modifiers: UInt32(controlKey | optionKey | shiftKey),
            keyLabel: "9"
        )
        expect(
            shiftedNumber.displayName == "⌃⌥⇧9",
            "a shifted shortcut should show the physical key"
        )

        let suiteName = "ProfileBarTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let preferences = ProfileShortcutPreferences(defaults: defaults)
        expect(preferences.isProfileVisible("Default"), "profile icons should be visible by default")
        defaults.set(false, forKey: "showProfileIcons")
        expect(!preferences.isProfileVisible("Default"), "the old visibility setting should remain the default")
        preferences.setProfileVisible(true, for: "Profile 1")
        preferences.setShortcut(hotKey, for: "Profile 1")
        expect(preferences.isProfileVisible("Profile 1"), "profile visibility should persist by directory")
        expect(!preferences.isProfileVisible("Profile 2"), "an unset profile should keep the old default")
        expect(preferences.shortcuts["Profile 1"] == hotKey, "shortcuts should persist by profile directory")
        preferences.setShortcut(nil, for: "Profile 1")
        expect(preferences.shortcuts["Profile 1"] == nil, "clearing a shortcut should remove it")

        let symbol = ProfileBarSymbol.image()
        expect(symbol.size == NSSize(width: 18, height: 18), "menu-bar symbol should use the native status-item size")
        expect(symbol.isTemplate, "menu-bar symbol should adapt to the menu-bar appearance")
        expect(symbol.tiffRepresentation != nil, "menu-bar symbol should render")
        print("PASS: ProfileBar tests")
    }
}
