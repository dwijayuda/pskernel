/-
Runtime hashing adapted from Lean 4.35.0 src/runtime/hash.{h,cpp}.
Copyright (c) 2013 Microsoft Corporation. Author: Leonardo de Moura.
Apache-2.0; see THIRD_PARTY_NOTICES.md. MurmurHash2 by Austin Appleby.
Modified: explicit modulo-2^64 arithmetic and canonical little-endian UTF-8.
-/
import Ps.BackendEcma.Syntax
namespace PsEcma
private def hashWord (value : Expr) : Expr := call "BigInt.asUintN" [num 64, value]
private def hashMultiplier : Expr := id "0xc6a4a7935bd1e995n"
private def hashMultiply (value : Expr) : Expr := hashWord (bin "*" value hashMultiplier)
private def hashScramble (value : Expr) : Expr := bin "^" value (bin ">>" value (id "47n"))

def hashMixBody : List Stmt := [
  set (id "key") (hashMultiply (id "key")),
  set (id "key") (hashScramble (id "key")),
  -- Lean's pair mixer XORs the multiplier here; the string block mixer multiplies.
  set (id "key") (bin "^" (id "key") hashMultiplier),
  ret (hashMultiply (bin "^" (id "seed") (id "key")))
]

-- Produce UTF-8 locally; the runtime has no dependency on a browser/Node encoder.
def stringHashBody : List Stmt := [
  .binding false "bytes" "number[]" (some (.array [])),
  .forOf "char" (id "text") [
    const "code" (bin "??" (method (id "char") "codePointAt" [num 0]) (num 0)),
    .ifE (bin "<" (id "code") (num 128))
      [.expression (method (id "bytes") "push" [id "code"])] [
    .ifE (bin "<" (id "code") (num 2048))
      [.expression (method (id "bytes") "push" [
        bin "|" (num 192) (bin ">>" (id "code") (num 6)),
        bin "|" (num 128) (bin "&" (id "code") (num 63))])] [
    .ifE (bin "<" (id "code") (num 65536))
      [.expression (method (id "bytes") "push" [
        bin "|" (num 224) (bin ">>" (id "code") (num 12)),
        bin "|" (num 128) (bin "&" (bin ">>" (id "code") (num 6)) (num 63)),
        bin "|" (num 128) (bin "&" (id "code") (num 63))])] [
      .expression (method (id "bytes") "push" [
        bin "|" (num 240) (bin ">>" (id "code") (num 18)),
        bin "|" (num 128) (bin "&" (bin ">>" (id "code") (num 12)) (num 63)),
        bin "|" (num 128) (bin "&" (bin ">>" (id "code") (num 6)) (num 63)),
        bin "|" (num 128) (bin "&" (id "code") (num 63))])]]]
  ],
  letE "hash" (bin "^" (id "11n") (hashMultiply (call "BigInt" [field (id "bytes") "length"]))),
  letE "index" (num 0),
  .whileE (bin "<=" (bin "+" (id "index") (num 8)) (field (id "bytes") "length")) [
    letE "key" (id "0n"), letE "offset" (num 0),
    .whileE (bin "<" (id "offset") (num 8)) [
      set (id "key") (bin "|" (id "key") (bin "<<" (call "BigInt" [
        .nonnull (.index (id "bytes") (bin "+" (id "index") (id "offset")))])
        (call "BigInt" [bin "*" (id "offset") (num 8)]))),
      inc "offset" (num 1)],
    set (id "key") (hashMultiply (id "key")),
    set (id "key") (hashScramble (id "key")),
    set (id "key") (hashMultiply (id "key")),
    set (id "hash") (hashMultiply (bin "^" (id "hash") (id "key"))),
    inc "index" (num 8)
  ],
  letE "shift" (id "0n"),
  .whileE (bin "<" (id "index") (field (id "bytes") "length")) [
    set (id "hash") (bin "^" (id "hash")
      (bin "<<" (call "BigInt" [.nonnull (.index (id "bytes") (id "index"))]) (id "shift"))),
    inc "index" (num 1), inc "shift" (id "8n")],
  .ifE (bin "!==" (id "shift") (id "0n")) [set (id "hash") (hashMultiply (id "hash"))] [],
  set (id "hash") (hashScramble (id "hash")),
  set (id "hash") (hashMultiply (id "hash")),
  ret (hashScramble (id "hash"))
]

def hashMixParameters : List Parameter :=
  [{ name := "seed", type := "bigint" }, { name := "key", type := "bigint" }]

def hashRuntime : List Stmt := [
  .functionD false false "__ps$hashMix" "" hashMixParameters "bigint" hashMixBody,
  .functionD false false "__ps$stringHash" "" [{ name := "text", type := "string" }]
    "bigint" stringHashBody
]
end PsEcma
