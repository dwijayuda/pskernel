#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

LEAN_BIN="${LEAN434_BIN:-}"
if [[ -n "$LEAN_BIN" ]]; then
  export PATH="$LEAN_BIN:$PATH"
fi

if ! command -v lean >/dev/null 2>&1; then
  echo "generate-text-foundation-fixture: lean not found; install leanprover/lean4:v4.34.0 or set LEAN434_BIN" >&2
  exit 2
fi

version="$(lean --version | head -n1)"
if [[ "$version" != Lean\ \(version\ 4.34.0,*Release* ]]; then
  echo "generate-text-foundation-fixture: expected Lean 4.34.0 Release, got: $version" >&2
  exit 1
fi

mkdir -p oracle/fixtures
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

lean --run oracle/replay-probe/DependencyExport.lean Init.Data.String.Length \
  Char.ofNat Char.toNat Char.isWhitespace Char.isUpper Char.isLower Char.isAlpha Char.isDigit Char.isAlphanum \
  String.push String.singleton String.append String.length String.utf8ByteSize String.rawStartPos String.rawEndPos \
  String.Pos.Raw.get 'String.Pos.Raw.get?' String.Pos.Raw.next "String.Pos.Raw.next'" String.Pos.Raw.atEnd \
  String.Pos.Raw.extract String.Pos.Raw.prev \
  > "$tmp"

mv "$tmp" oracle/fixtures/lean434-proofscript-text-foundation.ndjson
trap - EXIT
printf 'generate-text-foundation-fixture: PASS (%s)\n' "$version"
