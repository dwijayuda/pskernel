#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

LEAN_BIN="${LEAN434_BIN:-}"
if [[ -n "$LEAN_BIN" ]]; then
  export PATH="$LEAN_BIN:$PATH"
fi

if ! command -v lean >/dev/null 2>&1; then
  echo "generate-oracle-fixtures: lean not found; install leanprover/lean4:v4.34.0 or set LEAN434_BIN" >&2
  exit 2
fi

version="$(lean --version | head -n1)"
if [[ "$version" != Lean\ \(version\ 4.34.0,*Release* ]]; then
  echo "generate-oracle-fixtures: expected Lean 4.34.0 Release, got: $version" >&2
  exit 1
fi

mkdir -p oracle/fixtures
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

run_export() {
  local out="$1"; shift
  echo "[fixture] $out"
  lean --run "$@" > "$TMP/$out"
  mv "$TMP/$out" "oracle/fixtures/$out"
}

run_export lean434-init-prelude.ndjson oracle/replay-probe/FullExport.lean
run_export lean434-primitive-closure.ndjson oracle/replay-probe/DependencyExport.lean Init Nat.mod Nat.div Nat.gcd Nat.bitwise Nat.land Nat.lor Nat.xor Nat.shiftLeft Nat.shiftRight

run_export lean434-proofscript-text-foundation.ndjson oracle/replay-probe/DependencyExport.lean Init.Data.String.Length \
  Char.ofNat Char.toNat Char.isWhitespace Char.isUpper Char.isLower Char.isAlpha Char.isDigit Char.isAlphanum \
  String.push String.singleton String.append String.length String.utf8ByteSize String.rawStartPos String.rawEndPos \
  String.Pos.Raw.get 'String.Pos.Raw.get?' String.Pos.Raw.next String.Pos.Raw.next' String.Pos.Raw.atEnd \
  String.Pos.Raw.extract String.Pos.Raw.prev
run_export lean434-std-parsec-roots.ndjson oracle/replay-probe/StdParsecRootsExport.lean
run_export lean434-std-sat-cnf-roots.ndjson oracle/replay-probe/StdSatCNFRootsExport.lean
run_export lean434-std-byteslice-roots.ndjson oracle/replay-probe/StdByteSliceRootsExport.lean

run_export lean434-lean-rbmap-roots.ndjson oracle/replay-probe/DependencyExport.lean Lean.Data.RBMap \
  Lean.RBColor Lean.RBNode Lean.RBNode.depth Lean.RBNode.singleton Lean.RBNode.fold \
  Lean.RBNode.balance1 Lean.RBNode.balance2 Lean.RBNode.insert Lean.RBNode.appendTrees

run_export lean434-lean-persistentarray-roots.ndjson oracle/replay-probe/DependencyExport.lean Lean.Data.PersistentArray \
  Lean.PersistentArrayNode Lean.PersistentArray Lean.PersistentArray.empty Lean.PersistentArray.isEmpty \
  'Lean.PersistentArray.get!' Lean.PersistentArray.set Lean.PersistentArray.push Lean.PersistentArray.pop \
  Lean.PersistentArray.toArray Lean.PersistentArray.append Lean.PersistentArray.toList Lean.PersistentArray.stats

run_export lean434-lean-persistenthashmap-roots.ndjson oracle/replay-probe/DependencyExport.lean Lean.Data.PersistentHashMap \
  Lean.PersistentHashMap.Entry Lean.PersistentHashMap.Node Lean.PersistentHashMap \
  Lean.PersistentHashMap.empty Lean.PersistentHashMap.isEmpty Lean.PersistentHashMap.insert \
  'Lean.PersistentHashMap.find?' 'Lean.PersistentHashMap.findEntry?' Lean.PersistentHashMap.contains \
  Lean.PersistentHashMap.isUnaryNode

echo "[fixture] lean434-lean-rbmap-all.ndjson.gz"
lean --run oracle/replay-probe/DependencyExport.lean Lean.Data.RBMap --all > "$TMP/lean434-lean-rbmap-all.ndjson"
gzip -n -9 -c "$TMP/lean434-lean-rbmap-all.ndjson" > oracle/fixtures/lean434-lean-rbmap-all.ndjson.gz

printf 'generate-oracle-fixtures: PASS (%s)\n' "$version"
