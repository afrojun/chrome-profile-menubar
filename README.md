# Chrome Profile Switcher for the macOS menu bar

This menu-bar app shows one icon for each Chrome profile. Clicking a profile avatar immediately raises an existing window for that profile. If the profile has no open window, it opens the profile normally. It never opens Chrome's **Profiles** menu, copies the current URL, or handles profile data itself.

## Run

```zsh
./run.sh
```

The first switch asks for Accessibility access. Enable **Profile Switcher** in **System Settings → Privacy & Security → Accessibility**, then select the profile again. Accessibility access lets the app find and raise the matching Chrome window without showing Chrome's Profiles menu.

By default, the build uses an ad-hoc signature. macOS may treat each rebuild as a new app and ask you to enable Accessibility again. Use a local signing certificate to give rebuilds a stable, cryptographic identity.

Each profile appears as a circular, center-cropped version of its saved Google avatar in the macOS menu bar. If Chrome has no image for a profile, the app shows a colored circular initial. Hover to see the profile name; click once to switch or open it as appropriate. The ellipsis icon contains only Refresh, Accessibility Settings, and Quit.

If Chrome or the target profile is not open, the app launches that profile without passing a page URL. Chrome decides whether to restore or create its normal profile window.

## Install permanently

Build the app, then drag `build/Profile Switcher.app` to `/Applications`. Add it under **System Settings → General → Login Items** if you want it to start when you sign in.

## Keep Accessibility permission across builds

For local use, [create a self-signed certificate](https://support.apple.com/guide/keychain-access/kyca8916/mac) in **Keychain Access → Certificate Assistant → Create a Certificate**:

1. Name it `Profile Switcher Local Signing`.
2. Choose **Self Signed Root** as the identity type.
3. Choose **Code Signing** as the certificate type.
4. Keep the certificate and its private key in your login keychain. Never add or export the private key to this repository.

Pass that identity to the build:

```zsh
PROFILE_SWITCHER_SIGNING_IDENTITY="Profile Switcher Local Signing" ./run.sh
```

The build script deliberately has no shared signing identity. Each developer supplies an identity from their own keychain. Without the environment variable, it falls back to ad-hoc signing.

If you ran an older build that used the identifier-only signing requirement, remove its existing Accessibility entry before enabling the newly signed app. This clears the grant tied to the weaker identity.

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
