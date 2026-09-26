#!/usr/bin/env bash
# The Windows validation lane for promptite: builds the native binary from a
# clean tree with exactly the commands README.md documents, then tests the
# artifact a Windows user actually runs (not `dart run`). CI runs this from
# .github/workflows/ci.yml; run it by hand from the repo root with:
#
#   bash tool/windows_smoke.sh
#
# A non-zero exit is a failure.
set -uo pipefail

EXE=./build/promptite.exe
fails=0
ok()  { echo "PASS  $1"; }
bad() { echo "FAIL  $1"; fails=$((fails+1)); }

if ! command -v dart >/dev/null 2>&1; then
  echo "FAIL  dart is not on PATH (export the SDK first, e.g. export PATH=\"\$HOME/fvm/default/bin:\$PATH\")"
  exit 1
fi

echo "--- build from a clean tree (README 'Building on Windows') ---"
# `build/` is gitignored, so a checkout has no such directory and `dart compile
# exe` will NOT create one: it fails with PathNotFoundException on the output
# path. That is how the windows CI lane went red at 5b7abf1 while passing on any
# machine that already had a stale build/. Removing the directory here keeps
# this lane measuring the clean-checkout case.
rm -rf build
mkdir -p build
dart pub get >/dev/null 2>&1
if dart compile exe bin/promptite.dart -o build/promptite.exe; then
  ok "dart compile exe from a tree with no build/"
else
  bad "dart compile exe from a tree with no build/"
fi
if [ -f "$EXE" ]; then ok "artifact exists at $EXE"; else bad "artifact exists at $EXE"; fi
[ "$fails" -eq 0 ] || { echo "--- $fails failure(s) (no artifact to test) ---"; exit "$fails"; }

echo "--- the three README invocations, against the binary ---"
out=$("$EXE" -t "Refactor auth" -f "lib/auth.dart,lib/util.dart")
grep -q '<task>Refactor auth</task>' <<<"$out" && ok "invocation 1: task tag" || bad "invocation 1: task tag"
grep -q '<files>@lib/auth.dart, @lib/util.dart</files>' <<<"$out" && ok "invocation 1: files tag" || bad "invocation 1: files tag"
grep -q '<constraints>' <<<"$out" && ok "invocation 1: constraints tag" || bad "invocation 1: constraints tag"
grep -q 'Token estimate' <<<"$out" && ok "invocation 1: token estimate" || bad "invocation 1: token estimate"

out=$("$EXE" -t "Add tests" -c "Focus on login flow" --strict)
grep -q '<task>Add tests</task>' <<<"$out" && ok "invocation 2: task tag" || bad "invocation 2: task tag"
grep -q '<context>Focus on login flow</context>' <<<"$out" && ok "invocation 2: context tag" || bad "invocation 2: context tag"

if "$EXE" -h >/dev/null 2>&1; then ok "-h exits 0"; else bad "-h exits 0"; fi
if "$EXE" >/dev/null 2>&1; then ok "no args exits 0"; else bad "no args exits 0"; fi

if "$EXE" -f "a.dart" 2>/dev/null; then
  bad "missing --task exits non-zero"
else
  ok "missing --task exits $? (non-zero)"
fi

echo "--- stdout / stderr split ---"
h_out=$("$EXE" -h 2>/dev/null)
h_err=$("$EXE" -h 2>&1 >/dev/null)
[ -n "$h_out" ] && ok "-h writes usage to stdout" || bad "-h writes usage to stdout"
[ -z "$h_err" ] && ok "-h writes nothing to stderr" || bad "-h writes nothing to stderr"

run_out=$("$EXE" -t "probe" 2>/dev/null)
run_err=$("$EXE" -t "probe" 2>&1 >/dev/null)
[ -n "$run_out" ] && ok "prompt goes to stdout (clean pipe)" || bad "prompt goes to stdout (clean pipe)"
[ -z "$run_err" ] && ok "prompt run writes nothing to stderr" || bad "prompt run writes nothing to stderr"

echo "--- the banner names the binary, not 'dart run' ---"
usage=$("$EXE" -h 2>/dev/null)
grep -q 'Usage: promptite.exe <flags>' <<<"$usage" \
  && ok "usage line names promptite.exe" || bad "usage line names promptite.exe"
grep -q 'promptite.exe -t "Refactor auth"' <<<"$usage" \
  && ok "examples name promptite.exe" || bad "examples name promptite.exe"
if grep -q 'dart run' <<<"$usage"; then
  bad "banner tells a binary user to run 'dart run'"
else
  ok "banner never says 'dart run'"
fi

echo "--- the error line carries one prefix, not two ---"
err=$("$EXE" -t "t" -f "a<b>.dart" 2>&1 >/dev/null)
echo "  stderr was: $err"
grep -q '^Error: Failed to generate prompt: Invalid characters in file names$' <<<"$err" \
  && ok "clean one-line failure report" || bad "clean one-line failure report"
if grep -q 'Exception:' <<<"$err"; then
  bad "failure report leaks a dart type prefix"
else
  ok "failure report leaks no dart type prefix"
fi

echo "--- line endings and encoding ---"
"$EXE" -t "Refactor auth" -f "lib/auth.dart" > ./build/smoke_stdout.txt 2>/dev/null
if grep -q $'\r' ./build/smoke_stdout.txt; then
  bad "stdout is LF-only (found CR bytes)"
else
  ok "stdout is LF-only (no CR bytes)"
fi
"$EXE" -t "café naïve" > ./build/smoke_utf8.txt 2>/dev/null
grep -q '<task>café naïve</task>' ./build/smoke_utf8.txt \
  && ok "non-ASCII arguments round-trip as UTF-8" || bad "non-ASCII arguments round-trip as UTF-8"
rm -f ./build/smoke_stdout.txt ./build/smoke_utf8.txt

echo "--- extra Windows validation ---"
# 1. PE header: must be a native console exe, not a script wrapper.
head -c 2 "$EXE" | od -An -tx1 | grep -q '4d 5a' && ok "PE magic MZ present" || bad "PE magic MZ present"
# 2. Exit codes measured explicitly.
"$EXE" -t "Refactor auth" >/dev/null 2>&1; echo "  exit(-t) = $?"
"$EXE" -t "" >/dev/null 2>&1; echo "  exit(-t empty) = $?"
"$EXE" --bogus >/dev/null 2>&1; echo "  exit(--bogus) = $?"
# 3. `--script` typo repair must warn on stderr and apply strict truncation.
err=$("$EXE" -t "one two three four five six seven" --script 2>&1 >/dev/null)
echo "$err" | grep -q "looks like a typo" && ok "--script warns on stderr" || bad "--script warns on stderr"
out=$("$EXE" -t "one two three four five six seven" --script 2>/dev/null)
grep -q '<task>one two three four five</task>' <<<"$out" && ok "--script applies strict truncation" || bad "--script applies strict truncation"
# 4. Runs with the Dart SDK off PATH and from a foreign cwd (no runtime needed).
runs_dir=$(mktemp -d)
cp "$EXE" "$runs_dir/promptite.exe"
( cd /c/Windows/System32 && env -i PATH='/c/Windows/System32:/c/Windows' "$runs_dir/promptite.exe" -t "foreign cwd" | grep -q '<task>foreign cwd</task>' ) \
  && ok "runs from foreign cwd with SDK off PATH" || bad "runs from foreign cwd with SDK off PATH"
rm -rf "$runs_dir"

echo "--- $fails failure(s) ---"
exit $fails
