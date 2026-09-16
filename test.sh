#!/bin/zsh
set -euo pipefail
project_dir="${0:A:h}"
test_binary="$(mktemp /private/tmp/profile-switcher-tests.XXXXXX)"
trap 'rm -f -- "$test_binary"' EXIT
swiftc -warnings-as-errors \
  -framework AppKit -framework ApplicationServices -framework Carbon \
  "$project_dir/Sources/ProfileSwitcher/ChromeProfile.swift" \
  "$project_dir/Sources/ProfileSwitcher/ChromeWindowTitleMatcher.swift" \
  "$project_dir/Sources/ProfileSwitcher/ProfileShortcut.swift" \
  "$project_dir/Tests/ChromeWindowTitleMatcherTests.swift" \
  -o "$test_binary"
"$test_binary"
