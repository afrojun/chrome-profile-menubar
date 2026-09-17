# Direct distribution outside the Mac App Store

- **Status:** Accepted
- **Date:** 18 September 2026

## Context

ProfileBar's defining behavior is switching directly to an existing Chrome profile window. It uses macOS Accessibility to invoke Chrome's profile command or raise the matching window. It also reads Chrome's local profile list and saved avatars from the user's Application Support directory.

The Mac App Store requires App Sandbox. Sandboxing would prevent the current Accessibility-based switching flow and direct Chrome profile discovery without a substantially different permission and onboarding model. A store edition that only opened profiles would be a weaker product with different behavior.

ProfileBar is a focused utility, not a browser router. Existing products already cover link routing, rules, multi-browser support, and separate Dock identities. ProfileBar's useful distinction is narrower: each Chrome profile remains one click or one shortcut away, and existing windows stay where the user put them.

## Decision

Distribute ProfileBar as a free, open-source download through GitHub Releases.

Each release will be:

- Built for Apple silicon and the minimum macOS version declared in `Info.plist`.
- Signed with a Developer ID Application certificate and the hardened runtime.
- Packaged as a drag-to-Applications DMG.
- Notarized and stapled before publication.
- Published with a SHA-256 checksum.

ProfileBar will not pursue the Mac App Store, a paid edition, an automatic updater, link-routing rules, or support for other browsers without evidence that users need them.

## Consequences

- Users must grant Accessibility access directly to ProfileBar.
- GitHub Releases is the installation and update channel.
- The project must explain its local Chrome data access and Accessibility use clearly.
- Chrome profile metadata and menu labels remain upstream implementation details that may require maintenance.
- Release automation and its signing credentials are part of the project's security boundary.

## Revisit this decision when

- Apple provides a sandbox-compatible API for focusing a specific Chrome profile window.
- Chrome provides a supported profile-switching API.
- User demand justifies another distribution channel or browser.
- Supporting Intel Macs becomes a stated project goal.

## References

- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Protecting user data with App Sandbox](https://developer.apple.com/documentation/security/protecting-user-data-with-app-sandbox)
- [Accessibility API](https://developer.apple.com/documentation/applicationservices/axuielement_h)
- [Notarizing macOS software before distribution](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)
