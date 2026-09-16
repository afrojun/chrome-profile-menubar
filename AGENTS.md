# AGENTS.md

## Purpose

Profile Switcher is a small native macOS menu-bar app for switching directly to Chrome profiles. Preserve its core interaction: one action switches to an existing profile window, including across desktop Spaces, or opens the profile when no window exists.

## Product invariants

- Profile-avatar clicks and global shortcuts must call the same switch-or-open path.
- Never copy, reopen, or forward the current page URL while changing profiles.
- Invoke Chrome's native profile command through Accessibility without visibly opening its Profiles menu.
- Keep the existing window-title lookup and safe profile launch as fallbacks.
- Match profile menu labels exactly by profile name or by Chrome's qualified `Person (Profile)` form. A person name alone is ambiguous.
- Store profile preferences by Chrome's stable profile directory, not by display name or list position.
- The profile-avatar status items are optional. The ellipsis utility item must remain available so settings and Quit are always reachable.
- Reuse the visible Keyboard Shortcuts window. Repeated menu actions must never create duplicate settings windows.
- Shortcut recording must require at least one modifier. Escape cancels recording; Delete clears the assignment.
- Register only assigned hotkey combinations. Do not install a global keyboard monitor or persist typed input.

## Architecture

- `ChromeProfile.swift` owns profile loading, validation, and activation.
- `ChromeWindowTitleMatcher.swift` owns Chrome label matching and should remain independently testable.
- `ProfileShortcut.swift` owns persisted shortcut values and profile-icon visibility.
- `GlobalHotKeyRegistrar.swift` owns Carbon hotkey registration and dispatch only.
- `ShortcutSettingsWindowController.swift` owns the native shortcut settings UI and local recording state.
- `ProfileAvatarRenderer.swift` owns avatar and monogram rendering.
- `main.swift` coordinates the app. Keep policy here and mechanics in the focused types above.

Prefer the smallest native AppKit implementation. Do not add a package manager or third-party dependency unless the platform APIs cannot meet a concrete requirement and the trade-off has been agreed explicitly.

## Working method

For a feature:

1. State the observable user outcome and the invariants it must preserve.
2. Inspect the existing ownership boundary before adding a new type or state store.
3. Put deterministic logic behind a testable seam; keep AppKit coordination thin.
4. Implement the smallest coherent vertical slice.
5. Exercise both the normal path and the relevant fallback in the installed app.

For a bug:

1. Build a fast, deterministic command that reproduces the user's exact symptom.
2. Run it and capture the failing result before changing code.
3. Reduce the reproduction to the smallest sequence that still fails.
4. List a few falsifiable causes and test the most likely one first.
5. Add a regression test at the real seam when one exists. For AppKit lifecycle behavior without a useful unit seam, retain the exact live UI assertion used to validate the fix in the handoff notes.
6. Apply the smallest fix, rerun the minimal reproduction, then rerun the original stress case.
7. Remove temporary probes, logs, binaries, and test preferences.

Before finalizing non-trivial code, read the diff as a reviewer unfamiliar with the project. The main workflow should read top-to-bottom at one level of abstraction. Extract a helper only when it owns a coherent responsibility; avoid pass-through helpers, speculative fallbacks, parallel collections, or state that can be derived when needed.

## Security and privacy

- Treat Chrome's `Local State` and profile directories as read-only inputs.
- Keep profile-directory validation at the process-launch boundary. Never interpolate an unvalidated directory into a shell command.
- Use `Process` arguments rather than shell evaluation.
- Do not commit real profile names, account names, email addresses, home-directory paths, screenshots, Chrome data, certificates, private keys, or Accessibility database state.
- Keep signing keys in Keychain. `setup-signing.sh` may create a local identity, but no key material belongs in the repository.
- Do not use private SkyLight or CGS APIs. They are fragile and incompatible with normal distribution expectations.
- Do not bypass or alter macOS privacy controls. The user must grant Accessibility access in System Settings.
- Preserve unrelated working-tree changes. Do not use destructive Git or filesystem commands to clean up user-owned work.

## UI conventions

- Use native AppKit controls, system colors, SF typography, and standard macOS shortcut symbols.
- Use Chrome profile avatars as the visual identifier; keep surrounding UI quiet and compact.
- Use plain, action-oriented labels such as `Keyboard Shortcuts…`, `Show Profile Icons`, and `Launch at Login`.
- Show actionable errors. A shortcut conflict should leave the previous assignment intact.
- When testing UI state, preserve the user's existing shortcuts and visibility preference. Temporary assignments must be removed and the prior state restored.

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
5. Review the diff for credentials, personal data, absolute user paths, and generated build artifacts.
6. Re-read the main workflow top-to-bottom for clarity and remove unnecessary state or indirection.
7. Confirm the installed app and repository build came from the same source revision.

The shell scripts already create disposable test binaries. In a restricted environment, point `CLANG_MODULE_CACHE_PATH` and `SWIFT_MODULECACHE_PATH` at a writable temporary directory rather than changing the scripts solely for the sandbox.

## Regression coverage

- Add focused cases to `Tests/ChromeWindowTitleMatcherTests.swift` for pure matching, validation, shortcut formatting, and preference behavior.
- Use an installed, signed build for Accessibility, status-item, global-hotkey, and cross-Space checks; an ad-hoc test binary does not share the app's TCC identity.
- For window-lifecycle bugs, exercise the real menu action repeatedly and assert the live window count. Include timing stress when the report is intermittent.
- After rebuilding the installed app, verify Accessibility trust. A changed signing identity may require the user to approve access again.
- Remove temporary probes and diagnostic logging before committing.

## Documentation and distribution

- Update `README.md` whenever user-visible behavior, permissions, settings, build steps, or limitations change.
- Keep local self-signed builds distinct from public distribution. Public binaries require an Apple Developer ID signature and notarization, or Mac App Store signing.
- Do not commit the built `.app`; `build/` remains generated output.
