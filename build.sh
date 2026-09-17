#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h}"
app_dir="$project_dir/build/ProfileBar.app"
contents_dir="$app_dir/Contents"
local_identity="ProfileBar Local Signing"
minimum_macos_version="$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "$project_dir/Info.plist")"
signing_identities="$(security find-identity -v -p codesigning 2>/dev/null || true)"
developer_id_identity="$(
  print -r -- "$signing_identities" |
    sed -n 's/.*"\(Developer ID Application:[^"]*\)".*/\1/p' |
    sed -n '1p'
)"

if [[ -n "${PROFILEBAR_SIGNING_IDENTITY:-}" ]]; then
  signing_identity="$PROFILEBAR_SIGNING_IDENTITY"
elif [[ -n "$developer_id_identity" ]]; then
  signing_identity="$developer_id_identity"
elif [[ "$signing_identities" == *"\"$local_identity\""* ]]; then
  signing_identity="$local_identity"
else
  signing_identity="-"
fi

if [[ "$signing_identity" == "-" ]]; then
  print -u2 "Warning: signing ad hoc; installing this build may reset Accessibility access."
fi

rm -rf -- "$app_dir"
mkdir -p "$contents_dir/MacOS" "$contents_dir/Resources"
swiftc -target "arm64-apple-macos${minimum_macos_version}" -O -warnings-as-errors \
  -framework AppKit -framework ApplicationServices -framework Carbon -framework ServiceManagement \
  "$project_dir/Sources/ProfileBar/ChromeProfile.swift" \
  "$project_dir/Sources/ProfileBar/GlobalHotKeyRegistrar.swift" \
  "$project_dir/Sources/ProfileBar/ChromeWindowTitleMatcher.swift" \
  "$project_dir/Sources/ProfileBar/ProfileBarSymbol.swift" \
  "$project_dir/Sources/ProfileBar/ProfileAvatarRenderer.swift" \
  "$project_dir/Sources/ProfileBar/ProfileShortcut.swift" \
  "$project_dir/Sources/ProfileBar/ShortcutRecorderButton.swift" \
  "$project_dir/Sources/ProfileBar/SettingsWindowController.swift" \
  "$project_dir/Sources/ProfileBar/main.swift" \
  -o "$contents_dir/MacOS/ProfileBar"

cp "$project_dir/Info.plist" "$contents_dir/Info.plist"
cp "$project_dir/Resources/AppIcon.icns" "$contents_dir/Resources/AppIcon.icns"
signing_options=(--force --sign "$signing_identity")
if [[ "$signing_identity" == "Developer ID Application:"* ]]; then
  signing_options+=(--options runtime --timestamp)
fi
codesign "${signing_options[@]}" "$app_dir"
print "$app_dir"
