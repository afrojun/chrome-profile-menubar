#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h}"
app_dir="$project_dir/build/ProfileBar.app"
contents_dir="$app_dir/Contents"
local_identity="ProfileBar Local Signing"

if [[ -n "${PROFILEBAR_SIGNING_IDENTITY:-}" ]]; then
  signing_identity="$PROFILEBAR_SIGNING_IDENTITY"
elif security find-identity -v -p codesigning 2>/dev/null | grep -F "\"$local_identity\"" >/dev/null; then
  signing_identity="$local_identity"
else
  signing_identity="-"
fi

if [[ "$signing_identity" == "-" ]]; then
  print -u2 "Warning: signing ad hoc; installing this build may reset Accessibility access."
fi

mkdir -p "$contents_dir/MacOS" "$contents_dir/Resources"
swiftc -O -warnings-as-errors -framework AppKit -framework ApplicationServices -framework Carbon -framework ServiceManagement \
  "$project_dir/Sources/ProfileBar/ChromeProfile.swift" \
  "$project_dir/Sources/ProfileBar/GlobalHotKeyRegistrar.swift" \
  "$project_dir/Sources/ProfileBar/ChromeWindowTitleMatcher.swift" \
  "$project_dir/Sources/ProfileBar/ProfileAvatarRenderer.swift" \
  "$project_dir/Sources/ProfileBar/ProfileShortcut.swift" \
  "$project_dir/Sources/ProfileBar/ShortcutRecorderButton.swift" \
  "$project_dir/Sources/ProfileBar/SettingsWindowController.swift" \
  "$project_dir/Sources/ProfileBar/main.swift" \
  -o "$contents_dir/MacOS/ProfileBar"
cp "$project_dir/Info.plist" "$contents_dir/Info.plist"
codesign --force --deep --sign "$signing_identity" \
  "$app_dir"
print "$app_dir"
