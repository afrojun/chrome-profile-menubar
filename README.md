# ProfileBar

One-click Chrome profiles for macOS. ProfileBar switches directly to any profile when you click its menu-bar avatar or press a global shortcut. Switching works even when the profile's window is on another desktop Space. If the profile has no open window, Chrome opens it normally. ProfileBar never displays Chrome's **Profiles** menu, copies the current URL, or handles profile data itself.

## Run

```zsh
./run.sh
```

The first switch explains why Accessibility access is needed and offers to open **System Settings → Privacy & Security → Accessibility**. Grant access, then select the profile again. Accessibility access lets ProfileBar invoke Chrome's profile command without showing the Profiles menu.

The build uses an installed `Developer ID Application` certificate when available, then falls back to the local `ProfileBar Local Signing` identity. Without either identity, it uses an ad-hoc signature, which may cause macOS to ask for Accessibility permission after each rebuild.

Each profile appears as a circular, center-cropped version of its saved Google avatar in the macOS menu bar. If Chrome has no image for a profile, the app shows a colored circular initial. Hover to see the profile name; click once to switch or open it as appropriate.

Open **Settings…** from the ProfileBar menu to assign or clear a global shortcut for each profile. Shortcuts are stored against Chrome's stable profile directory and call the same switch-or-open behavior as the avatars. Outside the visible shortcut recorder, ProfileBar registers only the combinations you assign and does not monitor keyboard input.

Each profile has its own **Menu bar** switch, so a keyboard-first setup can hide any or all profile avatars. The ProfileBar icon remains available for Settings, profile refresh, and quitting.

If Chrome or the target profile is not open, the app launches that profile without passing a page URL. Chrome decides whether to restore or create its normal profile window.

## Install permanently

Build the app, then drag `build/ProfileBar.app` to `/Applications`. Use **Start at login** in Settings to control whether it starts when you sign in. If macOS needs approval, the setting links to **System Settings → General → Login Items** and shows that state in plain text.

## Keep Accessibility permission across builds

Run the one-time setup:

```sh
./setup-signing.sh
```

The script creates a self-signed Code Signing identity in your login keychain. The private key stays in Keychain and temporary files are removed. Each developer creates their own identity; never export or commit the private key. Subsequent builds find the identity automatically. To use another identity, set `PROFILEBAR_SIGNING_IDENTITY` when building.

The setup changes the app's signing identity, so macOS may ask for Accessibility permission one final time. A self-signed identity is only for local builds. It does not satisfy Gatekeeper or notarization and must not be used to distribute compiled builds.

To distribute compiled builds outside the Mac App Store, use an Apple [**Developer ID Application** certificate](https://developer.apple.com/help/account/certificates/create-developer-id-certificates) and notarize the app. The build enables hardened runtime and a secure timestamp when it finds that certificate. If the keychain contains more than one, set `PROFILEBAR_SIGNING_IDENTITY` to the full certificate name shown by `security find-identity -v -p codesigning`.

## Publish a release

Pushing a version tag runs `.github/workflows/release.yml` on an Apple silicon macOS runner. The workflow tests, signs, builds a drag-to-Applications DMG, notarizes, staples, verifies, and publishes it with its SHA-256 checksum. The tag must match `CFBundleShortVersionString` in `Info.plist`; version `0.3.1` uses tag `v0.3.1`.

The release waits for Apple to finish notarization before it publishes anything. The job allows three hours, with up to 150 minutes for Apple, so a slow submission does not produce an unsigned or incomplete release. Standard GitHub-hosted runners are free for this public repository.

Set up the release secrets once:

1. Open **Keychain Access**, select the **login** keychain, then select **My Certificates**.
2. Find and expand **Developer ID Application**. It must show a private key beneath it.
3. Right-click the certificate, choose **Export**, select **Personal Information Exchange (`.p12`)**, and protect it with a new export password. Save it outside this repository.
4. From this repository, run:

```zsh
base64 -i /path/to/developer-id.p12 | gh secret set BUILD_CERTIFICATE_BASE64
gh secret set P12_PASSWORD
gh secret set APPLE_ID
gh secret set APPLE_TEAM_ID
gh secret set APPLE_APP_SPECIFIC_PASSWORD
```

The first command uploads the encrypted certificate. The remaining commands prompt without putting their values in shell history:

- `P12_PASSWORD`: the export password chosen in Keychain Access.
- `APPLE_ID`: the email address used for the Apple Developer account.
- `APPLE_TEAM_ID`: the Team Identifier shown by `codesign -d --verbose=4 /Applications/ProfileBar.app 2>&1 | sed -n 's/^TeamIdentifier=//p'`.
- `APPLE_APP_SPECIFIC_PASSWORD`: the dedicated ProfileBar password generated at [account.apple.com](https://account.apple.com/) under **Sign-In and Security → App-Specific Passwords**.

When the secrets are ready, publish a release from a committed `main` branch:

```zsh
git tag -a v0.3.1 -m "ProfileBar 0.3.1"
git push origin v0.3.1
```

GitHub Actions does not expose repository secrets to workflows from forks. The release workflow runs only for tags pushed to this repository and grants its built-in token only permission to publish repository contents. The current release contains an Apple silicon (`arm64`) app. Users open the DMG and drag ProfileBar onto the Applications shortcut.

## Limitations

- Profile switching depends on Chrome's English **Profiles** menu. The app falls back to matching Chrome's window-title label if that command is unavailable.
- The app does not—and cannot—turn the current window into another profile.
- Profiles refresh whenever Settings or the ProfileBar menu opens. **Refresh Profiles** remains available for a manual retry.

## Verify

Run `./test.sh` to exercise Chrome's profile labels, shortcut preferences, and unsafe profile-directory rejection.

To check the permission without opening the app UI, run:

```zsh
./build/ProfileBar.app/Contents/MacOS/ProfileBar --check-accessibility
```

## License

This project is available under the [MIT License](LICENSE).

Created by [Arjun Radhakrishnan](https://afrojun.dev/).
