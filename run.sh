#!/bin/zsh
set -euo pipefail
project_dir="${0:A:h}"
app_dir="$project_dir/build/ProfileBar Dev.app"
executable="$app_dir/Contents/MacOS/ProfileBar"
"$project_dir/build.sh" --dev
pkill -f -x "$executable" 2>/dev/null || true
open "$app_dir"
