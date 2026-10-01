#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

LEAN_BIN="${LEAN434_BIN:-}"
if [[ -n "$LEAN_BIN" ]]; then
  export PATH="$LEAN_BIN:$PATH"
fi

if ! command -v lean >/dev/null 2>&1; then
  echo "generate-selfhost-foundation-fixture: lean not found; install leanprover/lean4:v4.34.0 or set LEAN434_BIN" >&2
  exit 2
fi

version="$(lean --version | head -n1)"
githash="$(lean --githash)"
expected_githash="293d5d0c0c3f3dded4688b3ccd6a33939ac5102b"
if [[ "$version" != Lean\ \(version\ 4.34.0,*Release* ]]; then
  echo "generate-selfhost-foundation-fixture: expected Lean 4.34.0 Release, got: $version" >&2
  exit 1
fi
if [[ "$githash" != "$expected_githash" ]]; then
  echo "generate-selfhost-foundation-fixture: expected Lean commit $expected_githash, got: $githash" >&2
  exit 1
fi

mkdir -p oracle/fixtures
tmp="$(mktemp)"
err="$(mktemp)"
trap 'rm -f "$tmp" "$err"' EXIT

if ! lean --run oracle/replay-probe/DependencyExport.lean Lean \
  --selected-segmented-after Init.Prelude 1 \
  Char.toNat \
  String.push String.singleton \
  String.Internal.length String.Internal.append \
  String.Internal.next String.Internal.get String.Internal.atEnd String.Internal.extract \
  Array.set Array.setIfInBounds Array.map Array.foldl \
  > "$tmp" 2> "$err"; then
  echo "generate-selfhost-foundation-fixture: Lean export failed" >&2
  if [[ -s "$err" ]]; then
    echo "--- Lean stderr ---" >&2
    cat "$err" >&2
  fi
  echo "--- export tail ---" >&2
  tail -n 80 "$tmp" >&2
  exit 1
fi

mv "$tmp" oracle/fixtures/lean434-proofscript-selfhost-foundation.ndjson
rm -f "$err"
trap - EXIT
printf 'generate-selfhost-foundation-fixture: PASS (%s; commit %s)\n' "$version" "$githash"
