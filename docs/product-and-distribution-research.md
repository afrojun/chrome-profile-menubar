# Product and distribution research

_Research date: 15 September 2026. Sources are limited to product owners, maintained project repositories, Chromium source, and Apple documentation. Public download and revenue data for the direct competitors was not available, so this is a product-fit assessment rather than a market-size estimate._

## Recommendation

There is a real but narrow niche, and there is already one near-exact competitor. Package Profile Switcher as a small, free, notarized download outside the Mac App Store if the goal is to make a polished open-source utility. Do not invest in a Mac App Store submission or build a paid product yet.

Its clearest promise is narrower than the competitors':

> Each Chrome profile avatar is always visible in the menu bar. One click focuses an open profile or opens it when closed, without a picker, profile menu, or window rearrangement.

That interaction is meaningfully different, but probably not enough of a moat for substantial commercial investment. Validate demand with a signed GitHub release before adding more browsers, routing rules, analytics, licensing, or an updater.

## Similar products

| Product | What it does | Confirmed status or price | Relationship to this app |
| --- | --- | --- | --- |
| [Chrome Hopping](https://amirtito.com/chrome_hopping/) | Raises all windows for a chosen Chrome profile or launches the profile if closed; also provides keyboard cycling and generated Dock/Spotlight apps. | v1.1; free for personal use under PolyForm Noncommercial; macOS 12+ and Python 3.10+; requires Accessibility and Full Disk Access. | The closest competitor and validation of almost the same workflow. It is more featureful, but uses a menu/generated apps and moves windows. Profile Switcher's direct, permanent avatar buttons and leave-windows-alone behavior remain distinct. |
| [DockSpark](https://dockspark.app/en) | Shows browser profiles when the pointer hovers over a browser's Dock icon; supports several browsers and private mode. | v0.3.2; macOS 14+; launch pricing starts at $4.99 for one Mac; distributed directly/Homebrew; Accessibility and sometimes Automation or Full Disk Access. | Broader browser support, but switching requires hover then selection rather than one click on an always-visible profile. |
| [Unbundle](https://www.unbundle.app/) | Creates a separate macOS app, Dock icon, Cmd-Tab entry, and Space assignment for each Chrome profile. | $6.99 one-time; macOS 13+; roughly 500 MB per copied profile according to its site. | Solves profile separation rather than fast menu-bar focus. It has better OS-level identity but a much heavier mechanism. |
| [Velja](https://sindresorhus.com/velja) | Routes links to browsers, native apps, and supported browser profiles using prompts or rules. Its site says it is sandboxed and available in the App Store. | Paid; macOS 26+; the developer reports almost 130,000 users, but that self-reported figure covers the broader link-routing use case. | Strong evidence that browser-profile selection is useful, but it decides where a URL opens rather than bringing an existing profile context forward. |
| [Choosy](https://choosy.app/) | Routes links by prompt or rules and supports Chrome, Edge, Brave, and Vivaldi profiles. | v2.5.2; $10. | An established adjacent product, not a context switcher. |
| [AppCat](https://github.com/rmarinsky/AppCat) | An MIT-licensed link, file, app, and window picker. It reads Chromium `Local State` for profiles and requests Accessibility for its window switcher. | Source and direct DMG are published on GitHub; macOS 14+. | It combines adjacent routing and window switching, but requires a picker or keyboard switcher rather than exposing direct profile buttons. |

Other adjacent open-source link pickers exist, including [Browser Picker](https://github.com/mertizci/browser-picker). [Browserosaurus](https://github.com/will-stone/browserosaurus) demonstrates longstanding interest in the category, but its repository was archived in August 2025 and says the app is unmaintained.

The competitive lesson is to preserve the narrow interaction instead of expanding into link routing, which already has mature choices. Chrome Hopping is the product to watch most closely.

## Mac App Store feasibility

The current core behavior is not a good fit for the Mac App Store.

1. **Existing-window focusing conflicts with the required sandbox.** Mac App Store apps must be sandboxed under [App Review Guideline 2.4.5(i)](https://developer.apple.com/app-store/review/guidelines/#2.4.5). Apple's current sandbox guidance lists use of accessibility APIs by assistive apps as incompatible with App Sandbox. Apple defines the `AXUIElement` API used here as the interface through which assistive apps communicate with and control other applications. Profile Switcher uses it to find, unminimize, focus, and raise Chrome windows in [`ChromeProfileActivator`](../Sources/ProfileSwitcher/ChromeProfile.swift). On those definitions, the app's defining focus-existing-window path is incompatible with the store sandbox. See [Protecting user data with App Sandbox](https://developer.apple.com/documentation/security/protecting-user-data-with-app-sandbox) and [`AXUIElement.h`](https://developer.apple.com/documentation/applicationservices/axuielement_h).

2. **Automatic Chrome profile and avatar discovery also needs redesign.** A sandboxed app has no unrestricted access to the user's home folder; it normally gets its own container plus explicitly granted locations. The current app directly reads Chrome's `Local State` and per-profile avatar files under `~/Library/Application Support/Google/Chrome`. A store version could ask the user to select the Chrome data folder and retain read-only access, but that adds onboarding and permission state. Apple documents user-selected file access as the supported route. Velja's App Store version similarly asks users to grant profile access, which is evidence that this part alone is solvable. See [Accessing files from the macOS App Sandbox](https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox) and [Configuring the macOS App Sandbox](https://developer.apple.com/documentation/xcode/configuring-the-macos-app-sandbox).

3. **Launching a closed profile is technically replaceable, but insufficient on its own.** Chromium currently defines `--profile-directory` as selecting the profile for the first browser launched, so the launch mechanism has an upstream implementation contract in [Chromium's switch definitions](https://chromium.googlesource.com/chromium/src/+/refs/heads/main/chrome/common/chrome_switches.h). A packaged app should replace the `/usr/bin/open` subprocess with the public [`NSWorkspace.openApplication`](https://developer.apple.com/documentation/appkit/nsworkspace/openapplication(at:configuration:completionhandler:)) API and its launch-argument configuration. That could support opening a closed profile in a sandbox, but it does not restore the one-click focus behavior that makes this app useful.

A store-specific version that only opens profiles would be a materially different and weaker product. It would also require an Xcode project, App Store metadata and screenshots, a privacy policy/support URL, sandboxed profile-folder onboarding, and review work. Apple requires App Store submissions to be packaged with Xcode, and the Apple Developer Program costs $99 per year. See [App Review Guideline 2.4.5(ii)](https://developer.apple.com/app-store/review/guidelines/#2.4.5), [Preparing an app for distribution](https://developer.apple.com/documentation/xcode/preparing-your-app-for-distribution), and [Apple Developer Program membership](https://developer.apple.com/programs/whats-included/).

## Smallest worthwhile distribution path

1. **Keep the source release as the validation channel.** Describe the single-click distinction clearly and collect issues before expanding scope.
2. **Create one proper direct-download build.** Adopt a unique bundle identifier, app icon, explicit deployment target, Release configuration, hardened runtime, and a Developer ID Application signature. Produce a universal build if Intel support is intended; otherwise state Apple silicon support plainly.
3. **Notarize and staple it, then publish a versioned ZIP on GitHub Releases.** Apple recommends Developer ID signing, hardened runtime, secure timestamping, and notarization for software distributed outside the store. See [Notarizing macOS software before distribution](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution) and [Apple's distribution overview](https://developer.apple.com/documentation/technologyoverviews/distribution).
4. **Make first-run permissions understandable.** Explain why Accessibility is needed before prompting, report the permission state accurately, and say that Chrome names and avatars are read locally and never transmitted.
5. **Stop there initially.** A DMG, automatic updater, Homebrew cask, login-item integration, preferences UI, support for other Chromium browsers, and App Store work should follow only if users request them. A ZIP avoids installer engineering while still providing a normal drag-to-Applications experience.

This path preserves the feature that cannot survive App Sandbox, gives users Gatekeeper verification, and limits the first packaging pass to work that improves trust rather than broadening the product.

## Remaining uncertainties

- No first-party source publishes reliable downloads, active users, or revenue for Chrome Hopping, DockSpark, or Unbundle. Velja's developer reports almost 130,000 users, but that is not independent evidence and measures a wider category.
- Chrome profile metadata and window-title conventions are implementation details rather than stable public APIs. The command-line switch is present in current Chromium source, but `Local State`, avatar filenames, and title suffixes could change.
- App Review outcomes can vary, but the recommendation does not depend on predicting a reviewer: the current focus path conflicts with Apple's documented sandbox restrictions, while sandboxing is a stated Mac App Store requirement.
