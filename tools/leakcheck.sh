#!/bin/bash
# Usage: leakcheck.sh <MobileVLCKit.xcframework | .zip | MobileVLCKit.framework>...
# Counts build-machine strings (home directory, user name, host name) in each MobileVLCKit binary
# and dSYM (strings and DWARF). Prints "leaks: N <file>" per file and one verdict line;
# exits 1 when any count is above 0, 2 when no binary is found.
set -euo pipefail

user=$(whoami)
pattern="$HOME|/Users/$user|$user|$(hostname -s)|$(hostname -f 2>/dev/null || hostname)"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

files=()
for arg in "$@"; do
  if [[ "$arg" == *.zip ]]; then
    dir="$work/$(basename "$arg" .zip)"
    mkdir -p "$dir" && ditto -x -k "$arg" "$dir"
    arg="$dir"
  fi
  while IFS= read -r f; do files+=("$f"); done < <(
    find "$arg" -type f \( -path '*MobileVLCKit.framework/MobileVLCKit' -o -path '*.dSYM/Contents/Resources/DWARF/*' \))
done
[ ${#files[@]} -gt 0 ] || { echo "ABORTED: no MobileVLCKit binary or dSYM under $*"; exit 2; }

failed=0
for f in "${files[@]}"; do
  n=$(strings -a "$f" | grep -cE "$pattern" || true)
  if [[ "$f" == *DWARF* ]]; then
    d=$(xcrun dwarfdump --debug-info --debug-line "$f" 2>/dev/null | grep -v ": *file format " | grep -cE "$pattern" || true)
    n=$((n + d))
  fi
  echo "leaks: $n $f"
  [ "$n" -eq 0 ] || failed=$((failed + 1))
done
echo "passed: $(( ${#files[@]} - failed )) failed: $failed"
[ "$failed" -eq 0 ]
