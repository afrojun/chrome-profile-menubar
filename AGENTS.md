# AGENTS.md

## Purpose

Profile Switcher is a native macOS menu-bar app. One action must switch to an open Chrome profile, even across desktop Spaces, or open it when no window exists.

## Product invariants

- Profile-avatar clicks and global shortcuts must call the same switch-or-open path.
- Never copy, reopen, or forward the current page URL while changing profiles.
- Use Accessibility to run Chrome's profile command without showing its Profiles menu.
- Keep window-title lookup and safe profile launch as fallbacks.
- Match profile menu labels exactly by profile name or by Chrome's qualified `Person (Profile)` form. A person name alone is ambiguous.
- Store profile preferences by Chrome's stable profile directory, not by display name or list position.
- Profile-avatar status items are optional. Keep the ellipsis item so settings and Quit are always available.
- Reuse the Keyboard Shortcuts window. Repeated menu actions must not open copies.
- Shortcut recording must require at least one modifier. Escape cancels recording; Delete clears the assignment.
- Register only assigned hotkeys. Do not install a global keyboard monitor or save typed input.

## Architecture

- `ChromeProfile.swift` owns profile loading, validation, and activation.
- `ChromeWindowTitleMatcher.swift` owns Chrome label matching and should remain independently testable.
- `ProfileShortcut.swift` owns persisted shortcut values and profile-icon visibility.
- `GlobalHotKeyRegistrar.swift` owns Carbon hotkey registration and dispatch only.
- `ShortcutSettingsWindowController.swift` owns the native shortcut settings UI and local recording state.
- `ProfileAvatarRenderer.swift` owns avatar and monogram rendering.
- `main.swift` coordinates the app. Keep policy here and mechanics in the focused types above.

Prefer a small native AppKit solution. Add a package manager or third-party dependency only when platform APIs cannot meet an agreed need.

## Working method

For a feature:

1. State the user-visible outcome and the rules it must preserve.
2. Find which file owns the behavior before adding a type or stored state.
3. Keep pure rules separate and testable; keep AppKit flow thin.
4. Build the smallest complete change.
5. Test the main path and its fallback in the installed app.

For a bug:

1. Write a fast, repeatable command that shows the exact bug.
2. Capture the failure before changing code, then shrink the steps while they still fail.
3. List testable causes and check the most likely one first.
4. Test the code that failed. If AppKit behavior has no useful unit test, record the live UI check in the handoff.
5. Apply the smallest fix. Rerun both the short check and the original stress case.
6. Remove test probes, logs, binaries, and preferences.

Before finishing non-trivial code, read the diff as a new reviewer. The main flow should read top-to-bottom at one level. Extract helpers only for clear duties. Avoid pass-through helpers, unneeded fallbacks, parallel collections, and state that can be derived.

## Security and privacy

- Treat Chrome's `Local State` and profile directories as read-only inputs.
- Check profile directories at the process-launch boundary. Never put an unchecked directory in a shell command.
- Use `Process` arguments rather than shell evaluation.
- Do not commit real profile names, account names, email addresses, home-directory paths, screenshots, Chrome data, certificates, private keys, or Accessibility database state.
- Keep signing keys in Keychain. `setup-signing.sh` may make a local identity, but key material never belongs in the repository.
- Do not use private SkyLight or CGS APIs. They are fragile and block standard distribution.
- Do not bypass macOS privacy controls. The user must grant Accessibility access in System Settings.
- Preserve unrelated working-tree changes. Do not use destructive Git or filesystem commands to clean up user-owned work.

## UI conventions

- Use native AppKit controls, system colors, SF typography, and standard macOS shortcut symbols.
- Use Chrome profile avatars as the visual cue; keep the rest of the UI quiet and compact.
- Use plain, action-oriented labels such as `Keyboard Shortcuts…`, `Show Profile Icons`, and `Launch at Login`.
- Show actionable errors. A shortcut conflict should leave the previous assignment intact.
- Preserve the user's shortcuts and icon setting during UI tests. Restore any state the test changes.

## Build and test

Run the unit suite:

```zsh
./test.sh
```

Build and sign the app:

```zsh
./build.sh
```

Before handing back a change:

1. Run `./test.sh`.
2. Run `./build.sh` with warnings treated as errors.
3. Verify the built signature with `codesign --verify --deep --strict`.
4. Run `git diff --check`.
5. Check the diff for credentials, personal data, user paths, and generated files.
6. Read the main flow top-to-bottom and remove unneeded state or indirection.
7. Confirm the installed app and repository build came from the same source revision.

The scripts create throwaway test binaries. In a restricted environment, point `CLANG_MODULE_CACHE_PATH` and `SWIFT_MODULECACHE_PATH` to a writable temporary directory instead of changing the scripts.

## Regression coverage

- Add focused cases to `Tests/ChromeWindowTitleMatcherTests.swift` for matching, checks, shortcut formatting, and preferences.
- Use an installed, signed build to test Accessibility, menu-bar items, global hotkeys, and cross-Space switching. A test binary has a different Accessibility identity.
- For window bugs, repeat the real menu action and check the live window count. Add timing stress for intermittent bugs.
- After rebuilding the installed app, verify Accessibility trust. A changed signing identity may require the user to approve access again.

## Documentation and distribution

- Update `README.md` whenever user-visible behavior, permissions, settings, build steps, or limitations change.
- Keep local self-signed builds separate from public releases. Public binaries need an Apple Developer ID signature and notarization, or Mac App Store signing.
- Do not commit the built `.app`; `build/` remains generated output.
