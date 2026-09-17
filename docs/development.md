# Development and releases

ProfileBar is a small native AppKit app with no third-party dependencies. You need macOS 14 or later, Google Chrome, and the Xcode command-line tools to build it.

## Run locally

```zsh
./run.sh
```

The first switch explains why Accessibility access is needed and links to **System Settings → Privacy & Security → Accessibility**. Grant access, then select the profile again.

## Build and test

```zsh
./test.sh
./build.sh
```

The app is written to `build/ProfileBar.app`. The build uses an installed `Developer ID Application` certificate when available, then falls back to the local `ProfileBar Local Signing` identity. Without either identity, it uses an ad-hoc signature, which may cause macOS to ask for Accessibility permission after each rebuild.

GitHub Actions runs the same formatting, test, build, deployment-target, signature, and DMG checks for pull requests and pushes to `main`.

Format the Swift sources with the same rules enforced by the test script:

```zsh
xcrun swift-format format --in-place --configuration .swift-format --recursive Sources Tests
```

To inspect the permission without opening the app UI:

```zsh
./build/ProfileBar.app/Contents/MacOS/ProfileBar --check-accessibility
```

## Keep Accessibility permission across local builds

Run the one-time setup:

```zsh
./setup-signing.sh
```

The script creates a self-signed code-signing identity in your login keychain. Its private key stays in Keychain, and the script removes its temporary files. Each developer creates their own identity; never export or commit the private key.

The new identity may make macOS ask for Accessibility permission one final time. It is only for local builds and does not satisfy Gatekeeper or notarization.

To choose another identity, set `PROFILEBAR_SIGNING_IDENTITY` to the full name shown by:

```zsh
security find-identity -v -p codesigning
```

## Publish a release

Pushing a version tag runs [the release workflow](../.github/workflows/release.yml) on an Apple silicon macOS runner. It tests, signs, builds a drag-to-Applications DMG, notarizes, staples, verifies, and publishes the DMG with its SHA-256 checksum.

The reasons for using direct GitHub distribution are recorded in the [distribution decision](distribution-decision.md).

The tag must match `CFBundleShortVersionString` in `Info.plist`. Version `1.0.0`, for example, uses tag `v1.0.0`.

### Set up GitHub secrets

1. Open **Keychain Access**, select the **login** keychain, then select **My Certificates**.
2. Find and expand **Developer ID Application**. It must show a private key beneath it.
3. Right-click the certificate, choose **Export**, select **Personal Information Exchange (`.p12`)**, and protect it with a new export password. Save it outside this repository.
4. From this repository, run:

```zsh
/usr/bin/base64 -i /path/to/developer-id.p12 | gh secret set BUILD_CERTIFICATE_BASE64
gh secret set P12_PASSWORD
gh secret set APPLE_ID
gh secret set APPLE_TEAM_ID
gh secret set APPLE_APP_SPECIFIC_PASSWORD
```

The first command uploads the encoded certificate. The other commands prompt for their values without putting them in shell history:

- `P12_PASSWORD`: the export password chosen in Keychain Access.
- `APPLE_ID`: the email address used for the Apple Developer account.
- `APPLE_TEAM_ID`: the Team Identifier printed by `codesign -d --verbose=4 /Applications/ProfileBar.app`.
- `APPLE_APP_SPECIFIC_PASSWORD`: the dedicated ProfileBar password created at [account.apple.com](https://account.apple.com/) under **Sign-In and Security → App-Specific Passwords**.

### Create the release

From a committed `main` branch:

1. Install the Developer ID-signed build in Applications.
2. Confirm an avatar click focuses a profile in the current Space and another Space.
3. Confirm selecting a closed profile opens it without copying the current URL.
4. Confirm each assigned shortcut performs the same switch-or-open action.
5. Confirm Settings reuses one window and **Start at login** reports its state correctly.
6. Run the automated checks with `./test.sh` and `./build.sh`.

Then create and push the version tag:

```zsh
git tag -a v1.0.0 -m "ProfileBar 1.0.0"
git push origin v1.0.0
```

The workflow allows three hours for the job and up to 150 minutes for Apple's notarization service. It publishes nothing until notarization and verification succeed.

GitHub does not expose repository secrets to workflows from forks. The workflow runs only for tags pushed to this repository, and its built-in token can only publish repository contents.
