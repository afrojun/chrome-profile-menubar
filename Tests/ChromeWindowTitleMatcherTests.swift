import Foundation

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
        print("PASS: Profile switcher tests")
    }
}
