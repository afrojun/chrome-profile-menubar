#!/bin/zsh
set -euo pipefail
project_dir="${0:A:h}"
app_dir="$project_dir/build/ProfileBar.app"
executable="$app_dir/Contents/MacOS/ProfileBar"
"$project_dir/build.sh"
pkill -f -x "$executable" 2>/dev/null || true
open "$app_dir"
