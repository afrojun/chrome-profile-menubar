#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h}"
app_dir="$project_dir/build/Profile Switcher.app"
contents_dir="$app_dir/Contents"
signing_identity="${PROFILE_SWITCHER_SIGNING_IDENTITY:-"-"}"

mkdir -p "$contents_dir/MacOS" "$contents_dir/Resources"
swiftc -O -warnings-as-errors -framework AppKit -framework ApplicationServices \
  "$project_dir/Sources/ProfileSwitcher/ChromeProfile.swift" \
  "$project_dir/Sources/ProfileSwitcher/ChromeWindowTitleMatcher.swift" \
  "$project_dir/Sources/ProfileSwitcher/ProfileAvatarRenderer.swift" \
  "$project_dir/Sources/ProfileSwitcher/main.swift" \
  -o "$contents_dir/MacOS/ProfileSwitcher"
cp "$project_dir/Info.plist" "$contents_dir/Info.plist"
codesign --force --deep --sign "$signing_identity" \
  "$app_dir"
print "$app_dir"
