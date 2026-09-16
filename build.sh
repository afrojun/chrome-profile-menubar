#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h}"
app_dir="$project_dir/build/Profile Switcher.app"
contents_dir="$app_dir/Contents"
local_identity="Profile Switcher Local Signing"

if [[ -n "${PROFILE_SWITCHER_SIGNING_IDENTITY:-}" ]]; then
  signing_identity="$PROFILE_SWITCHER_SIGNING_IDENTITY"
elif security find-identity -v -p codesigning 2>/dev/null | grep -F "\"$local_identity\"" >/dev/null; then
  signing_identity="$local_identity"
else
  signing_identity="-"
fi

mkdir -p "$contents_dir/MacOS" "$contents_dir/Resources"
swiftc -O -warnings-as-errors -framework AppKit -framework ApplicationServices -framework ServiceManagement \
  "$project_dir/Sources/ProfileSwitcher/ChromeProfile.swift" \
  "$project_dir/Sources/ProfileSwitcher/ChromeWindowTitleMatcher.swift" \
  "$project_dir/Sources/ProfileSwitcher/ProfileAvatarRenderer.swift" \
  "$project_dir/Sources/ProfileSwitcher/main.swift" \
  -o "$contents_dir/MacOS/ProfileSwitcher"
cp "$project_dir/Info.plist" "$contents_dir/Info.plist"
codesign --force --deep --sign "$signing_identity" \
  "$app_dir"
print "$app_dir"
