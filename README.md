# Chrome Profile Switcher for the macOS menu bar

This menu-bar app switches directly to any Chrome profile by clicking its avatar or pressing a global shortcut. Switching works even when the profile's window is on another desktop Space. If the profile has no open window, Chrome opens it normally. The app never displays Chrome's **Profiles** menu, copies the current URL, or handles profile data itself.

## Run

```zsh
./run.sh
```

The first switch explains why Accessibility access is needed and offers to open **System Settings → Privacy & Security → Accessibility**. Grant access, then select the profile again. Accessibility access lets the app invoke Chrome's profile command without showing the Profiles menu.

The build uses the local `Profile Switcher Local Signing` identity when it is available. Otherwise, it uses an ad-hoc signature, which may cause macOS to ask for Accessibility permission after each rebuild.

Each profile appears as a circular, center-cropped version of its saved Google avatar in the macOS menu bar. If Chrome has no image for a profile, the app shows a colored circular initial. Hover to see the profile name; click once to switch or open it as appropriate.

Open **Settings…** from the gear menu to assign or clear a global shortcut for each profile. Shortcuts are stored against Chrome's stable profile directory and call the same switch-or-open behavior as the avatars. Outside the visible shortcut recorder, Profile Switcher registers only the combinations you assign and does not monitor keyboard input.

Each profile has its own **Menu bar** switch, so a keyboard-first setup can hide any or all profile avatars. The gear remains available for Settings, profile refresh, and quitting.

If Chrome or the target profile is not open, the app launches that profile without passing a page URL. Chrome decides whether to restore or create its normal profile window.

## Install permanently

Build the app, then drag `build/Profile Switcher.app` to `/Applications`. Use **Start at login** in Settings to control whether it starts when you sign in. If macOS needs approval, the setting links to **System Settings → General → Login Items** and shows that state in plain text.

## Keep Accessibility permission across builds

Run the one-time setup:

```sh
./setup-signing.sh
```

The script creates a self-signed Code Signing identity in your login keychain. The private key stays in Keychain and temporary files are removed. Each developer creates their own identity; never export or commit the private key. Subsequent builds find the identity automatically. To use another identity, set `PROFILE_SWITCHER_SIGNING_IDENTITY` when building.

The setup changes the app's signing identity, so macOS may ask for Accessibility permission one final time. A self-signed identity is only for local builds. It does not satisfy Gatekeeper or notarization and must not be used to distribute compiled builds.

To distribute compiled builds outside the Mac App Store, use an Apple [**Developer ID Application** certificate](https://developer.apple.com/help/account/certificates/create-developer-id-certificates) and notarize the app. Set `PROFILE_SWITCHER_SIGNING_IDENTITY` to the full certificate name shown by `security find-identity -v -p codesigning`.

## Limitations

- Profile switching depends on Chrome's English **Profiles** menu. The app falls back to matching Chrome's window-title label if that command is unavailable.
- The app does not—and cannot—turn the current window into another profile.
- Profiles refresh whenever Settings or the gear menu opens. **Refresh Profiles** remains available for a manual retry.

## Verify

Run `./test.sh` to exercise Chrome's profile labels, shortcut preferences, and unsafe profile-directory rejection.

To check the permission without opening the app UI, run:

```zsh
./build/Profile\ Switcher.app/Contents/MacOS/ProfileSwitcher --check-accessibility
```

## License

This project is available under the [MIT License](LICENSE).
