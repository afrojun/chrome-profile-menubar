#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h}"
app_dir="$project_dir/build/ProfileBar.app"
contents_dir="$app_dir/Contents"
local_identity="ProfileBar Local Signing"
icon_source="$project_dir/Resources/ProfileBarIcon.png"
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

if ! sips -g hasAlpha "$icon_source" | grep -F "hasAlpha: no" >/dev/null; then
  print -u2 "The app icon must be opaque and full bleed so macOS applies a single icon mask."
  exit 1
fi

rm -rf -- "$app_dir"
mkdir -p "$contents_dir/MacOS" "$contents_dir/Resources"
swiftc -O -warnings-as-errors -framework AppKit -framework ApplicationServices -framework Carbon -framework ServiceManagement \
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

icon_work_dir="$(mktemp -d /private/tmp/profilebar-icon.XXXXXX)"
trap 'rm -rf -- "$icon_work_dir"' EXIT
iconset="$icon_work_dir/AppIcon.iconset"
mkdir "$iconset"

render_icon() {
  sips -z "$1" "$1" "$icon_source" --out "$iconset/$2" >/dev/null
}

render_icon 16 icon_16x16.png
render_icon 32 icon_16x16@2x.png
render_icon 32 icon_32x32.png
render_icon 64 icon_32x32@2x.png
render_icon 128 icon_128x128.png
render_icon 256 icon_128x128@2x.png
render_icon 256 icon_256x256.png
render_icon 512 icon_256x256@2x.png
render_icon 512 icon_512x512.png
render_icon 1024 icon_512x512@2x.png
iconutil -c icns "$iconset" -o "$contents_dir/Resources/AppIcon.icns"

cp "$project_dir/Info.plist" "$contents_dir/Info.plist"
signing_options=(--force --sign "$signing_identity")
if [[ "$signing_identity" == "Developer ID Application:"* ]]; then
  signing_options+=(--options runtime --timestamp)
fi
codesign "${signing_options[@]}" "$app_dir"
print "$app_dir"
