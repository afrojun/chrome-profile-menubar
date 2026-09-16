# Chrome Profile Switcher for the macOS menu bar

This menu-bar app shows one icon for each Chrome profile. Clicking a profile avatar immediately raises an existing window for that profile. If the profile has no open window, it opens the profile normally. It never opens Chrome's **Profiles** menu, copies the current URL, or handles profile data itself.

## Run

```zsh
./run.sh
```

The first switch asks for Accessibility access. Enable **Profile Switcher** in **System Settings → Privacy & Security → Accessibility**, then select the profile again. Accessibility access lets the app find and raise the matching Chrome window without showing Chrome's Profiles menu.

The build uses the local `Profile Switcher Local Signing` identity when it is available. Otherwise, it uses an ad-hoc signature, which may cause macOS to ask for Accessibility permission after each rebuild.

Each profile appears as a circular, center-cropped version of its saved Google avatar in the macOS menu bar. If Chrome has no image for a profile, the app shows a colored circular initial. Hover to see the profile name; click once to switch or open it as appropriate. The ellipsis icon contains only Refresh, Accessibility Settings, and Quit.

If Chrome or the target profile is not open, the app launches that profile without passing a page URL. Chrome decides whether to restore or create its normal profile window.

## Install permanently

Build the app, then drag `build/Profile Switcher.app` to `/Applications`. Add it under **System Settings → General → Login Items** if you want it to start when you sign in.

## Keep Accessibility permission across builds

Run the one-time setup:

```sh
./setup-signing.sh
```

The script creates a self-signed Code Signing identity in your login keychain. The private key stays in Keychain and temporary files are removed. Each developer creates their own identity; never export or commit the private key. Subsequent builds find the identity automatically. To use another identity, set `PROFILE_SWITCHER_SIGNING_IDENTITY` when building.

The setup changes the app's signing identity, so macOS may ask for Accessibility permission one final time. A self-signed identity is only for local builds. It does not satisfy Gatekeeper or notarization and must not be used to distribute compiled builds.

To distribute compiled builds outside the Mac App Store, use an Apple [**Developer ID Application** certificate](https://developer.apple.com/help/account/certificates/create-developer-id-certificates) and notarize the app. Set `PROFILE_SWITCHER_SIGNING_IDENTITY` to the full certificate name shown by `security find-identity -v -p codesigning`.

## Limitations

- Existing-window switching depends on the profile label Chrome adds to its window title.
- The app does not—and cannot—turn the current window into another profile.
- If profiles are added or renamed, select **Refresh Profiles**.

## Verify

Run `./test.sh` to exercise Chrome's window-title formats and reject unsafe profile-directory values.

To check the permission without opening the app UI, run:

```zsh
./build/Profile\ Switcher.app/Contents/MacOS/ProfileSwitcher --check-accessibility
```

## License

This project is available under the [MIT License](LICENSE).
