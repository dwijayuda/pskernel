import Ps.Environment.SelfHostProd

-- A portable, length-delimited canonical serialization of the checked
-- environment's declaration and instance inputs. This is a reproducible
-- drift fingerprint, NOT a cryptographic proof certificate. In particular
-- kernel admission, audited primitive models and the full v7 assumption/
-- effect closure remain separate gates.
--
-- Scope: Lean 4.35.0-rc4 native selected prelude, including all installed
-- Core declarations, class parameters, priority-ordered instances and
-- exported source aliases. Never hash the cached environment lookup index.
def psStandardSnapshotField (value : String) : String :=
  toString value.utf8ByteSize ++ ":" ++ value

def psStandardSnapshotNode (tag : String) (fields : List String) : String :=
  tag ++ "{" ++ String.join (fields.map psStandardSnapshotField) ++ "}"

def psStandardSnapshotList (f : α → String) (values : List α) : String :=
  psStandardSnapshotNode "list" (values.map f)

def psStandardSnapshotName : PsName → String
  | .anonymous => "n0"
  | .str parent component =>
      psStandardSnapshotNode "name" [
        psStandardSnapshotName parent, component]
  | .num parent index =>
      psStandardSnapshotNode "numericName" [
        psStandardSnapshotName parent, toString index]

def psStandardSnapshotLevel : PsLevel → String
  | .zero => "z"
  | .succ level => psStandardSnapshotNode "succ" [psStandardSnapshotLevel level]
  | .max left right => psStandardSnapshotNode "max"
      [psStandardSnapshotLevel left, psStandardSnapshotLevel right]
  | .imax left right => psStandardSnapshotNode "imax"
      [psStandardSnapshotLevel left, psStandardSnapshotLevel right]
  | .param name => psStandardSnapshotNode "param" [psStandardSnapshotName name]
  | .mvar id => psStandardSnapshotNode "levelMeta" [toString id]

def psStandardSnapshotBinder : PsBinderInfo → String
  | .explicit => "explicit"
  | .implicit => "implicit"
  | .strictImplicit => "strict"
  | .instanceImplicit => "instance"

def psStandardSnapshotLiteral : PsLiteral → String
  | .natural value => psStandardSnapshotNode "nat" [toString value]
  | .string value => psStandardSnapshotNode "string" [value]

def psStandardSnapshotExpr : PsExpr → String
  | .bvar id => psStandardSnapshotNode "bound" [toString id]
  | .fvar id => psStandardSnapshotNode "free" [toString id]
  | .mvar id => psStandardSnapshotNode "meta" [toString id]
  | .sortE level =>
      psStandardSnapshotNode "sort" [psStandardSnapshotLevel level]
  | .constE name levels =>
      psStandardSnapshotNode "const" [
        psStandardSnapshotName name,
        psStandardSnapshotList psStandardSnapshotLevel levels]
  | .app fn arg => psStandardSnapshotNode "apply"
      [psStandardSnapshotExpr fn, psStandardSnapshotExpr arg]
  | .lam name type body binder => psStandardSnapshotNode "lambda" [
      psStandardSnapshotName name, psStandardSnapshotExpr type,
      psStandardSnapshotExpr body, psStandardSnapshotBinder binder]
  | .forallE name type body binder => psStandardSnapshotNode "forall" [
      psStandardSnapshotName name, psStandardSnapshotExpr type,
      psStandardSnapshotExpr body, psStandardSnapshotBinder binder]
  | .letE name type value body => psStandardSnapshotNode "let" [
      psStandardSnapshotName name, psStandardSnapshotExpr type,
      psStandardSnapshotExpr value, psStandardSnapshotExpr body]
  | .lit value =>
      psStandardSnapshotNode "literal" [psStandardSnapshotLiteral value]
  | .proj owner index value => psStandardSnapshotNode "projection" [
      psStandardSnapshotName owner, toString index, psStandardSnapshotExpr value]

def psStandardSnapshotBool (value : Bool) : String :=
  if value then "1" else "0"

def psStandardSnapshotDeclaration : PsDeclaration → String
  | .axiomDecl name levels type => psStandardSnapshotNode "axiom" [
      psStandardSnapshotName name,
      psStandardSnapshotList psStandardSnapshotName levels,
      psStandardSnapshotExpr type]
  | .definitionDecl name levels type value =>
      psStandardSnapshotNode "definition" [
        psStandardSnapshotName name,
        psStandardSnapshotList psStandardSnapshotName levels,
        psStandardSnapshotExpr type, psStandardSnapshotExpr value]
  | .theoremDecl name levels type value =>
      psStandardSnapshotNode "theorem" [
        psStandardSnapshotName name,
        psStandardSnapshotList psStandardSnapshotName levels,
        psStandardSnapshotExpr type, psStandardSnapshotExpr value]
  | .partialDecl name levels type value =>
      psStandardSnapshotNode "partial" [
        psStandardSnapshotName name,
        psStandardSnapshotList psStandardSnapshotName levels,
        psStandardSnapshotExpr type, psStandardSnapshotExpr value]
  | .opaqueDecl name levels type value =>
      psStandardSnapshotNode "opaque" [
        psStandardSnapshotName name,
        psStandardSnapshotList psStandardSnapshotName levels,
        psStandardSnapshotExpr type, psStandardSnapshotExpr value]
  | .inductiveDecl info => psStandardSnapshotNode "inductive" [
      psStandardSnapshotName info.name,
      psStandardSnapshotList psStandardSnapshotName info.levelParams,
      psStandardSnapshotExpr info.type, toString info.numParams,
      toString info.numIndices,
      psStandardSnapshotList psStandardSnapshotName info.constructors,
      psStandardSnapshotBool info.isStructure]
  | .constructorDecl info => psStandardSnapshotNode "constructor" [
      psStandardSnapshotName info.name,
      psStandardSnapshotList psStandardSnapshotName info.levelParams,
      psStandardSnapshotExpr info.type,
      psStandardSnapshotName info.inductiveName,
      toString info.constructorIndex, toString info.numParams,
      toString info.numFields,
      psStandardSnapshotList toString info.recursiveFields]
  | .recursorDecl info => psStandardSnapshotNode "recursor" [
      psStandardSnapshotName info.name,
      psStandardSnapshotList psStandardSnapshotName info.levelParams,
      psStandardSnapshotExpr info.type,
      psStandardSnapshotList psStandardSnapshotName info.inductiveNames,
      toString info.numParams, toString info.numIndices,
      toString info.numMotives, toString info.numMinors]

def psStandardSnapshotOptionalName : Option PsName → String
  | none => "none"
  | some name => psStandardSnapshotNode "some" [psStandardSnapshotName name]

def psStandardSnapshotInstance (value : PsInstanceEntry) : String :=
  psStandardSnapshotNode "instance" [
    psStandardSnapshotExpr value.value,
    psStandardSnapshotExpr value.type,
    toString value.priority,
    psStandardSnapshotOptionalName value.className,
    psStandardSnapshotList psStandardSnapshotName value.levelParams]

def psStandardSnapshotClassParameters (value : PsName × PsClassParameters) :
    String :=
  psStandardSnapshotNode "classParameters" [
    psStandardSnapshotName value.fst,
    psStandardSnapshotList toString value.snd.outputs,
    psStandardSnapshotList toString value.snd.outputLevels]

def psStandardSnapshotAlias (value : PsName × PsName) : String :=
  psStandardSnapshotNode "alias" [
    psStandardSnapshotName value.fst, psStandardSnapshotName value.snd]

def psStandardSnapshotPayload (environment : PsEnvironment) : String :=
  psStandardSnapshotNode "PSCV0-STDENV-FNV64-v1" [
    "Lean-4.35.0-rc4@c29b6dda4f7c20e3eeaa717c4e565663c5cfa364",
    psStandardSnapshotList psStandardSnapshotDeclaration environment.declarations,
    psStandardSnapshotList psStandardSnapshotName environment.classes,
    psStandardSnapshotList psStandardSnapshotClassParameters
      environment.classParameters,
    psStandardSnapshotList psStandardSnapshotInstance environment.instances.entries,
    psStandardSnapshotList psStandardSnapshotAlias environment.exportedAliases]

-- FNV-1a (64-bit) over UTF-8 bytes, computed with arbitrary-precision Nat
-- and an explicit modulus. The result is independent of host pointer width,
-- locale, JavaScript numeric precision and filesystem order.
def psStandardSnapshotFNV64 (text : String) : Nat :=
  let modulus : Nat := 18446744073709551616
  let prime : Nat := 1099511628211
  text.toUTF8.data.foldl (fun acc b =>
    ((Nat.xor acc b.toNat) * prime) % modulus)
    14695981039346656037

def psStandardSnapshotFingerprint (environment : PsEnvironment) : String :=
  "fnv1a64:" ++ toString (psStandardSnapshotFNV64
    (psStandardSnapshotPayload environment))

-- This expected value is generated only from the qualified selected prelude
-- and deliberately changes with every intentional registered semantic update.
-- The official kernel is still the authority for checking its declarations.
def psStandardSnapshotExpected : String :=
  "fnv1a64:403111548970955669"


-- Portable SHA-256 of the *same* canonical UTF-8 payload used by the existing
-- FNV drift detector. Every intermediate word is explicitly reduced to 32 bits.
-- This implementation uses Lean Nat arithmetic only; no shell, OpenSSL, FFI,
-- host-dependent HashMap iteration or unchecked compiler backend is involved.
-- A digest is integrity evidence, not a proof of the serialized environment's
-- completeness, runtime semantics, or logical consistency.
private def psStandardSHA256Mod : Nat := 4294967296

private def psStandardSHA256Word (n : Nat) : Nat :=
  n % psStandardSHA256Mod

private def psStandardSHA256ROR (word shift : Nat) : Nat :=
  (word / (2 ^ shift) + (word % (2 ^ shift)) * (2 ^ (32 - shift))) %
    psStandardSHA256Mod

private def psStandardSHA256Small0 (word : Nat) : Nat :=
  Nat.xor (Nat.xor (psStandardSHA256ROR word 7) (psStandardSHA256ROR word 18))
    (word / (2 ^ 3))

private def psStandardSHA256Small1 (word : Nat) : Nat :=
  Nat.xor (Nat.xor (psStandardSHA256ROR word 17) (psStandardSHA256ROR word 19))
    (word / (2 ^ 10))

private def psStandardSHA256Big0 (word : Nat) : Nat :=
  Nat.xor (Nat.xor (psStandardSHA256ROR word 2) (psStandardSHA256ROR word 13))
    (psStandardSHA256ROR word 22)

private def psStandardSHA256Big1 (word : Nat) : Nat :=
  Nat.xor (Nat.xor (psStandardSHA256ROR word 6) (psStandardSHA256ROR word 11))
    (psStandardSHA256ROR word 25)

private def psStandardSHA256Choice (a b c : Nat) : Nat :=
  Nat.xor (Nat.land a b) (Nat.land (Nat.xor 4294967295 a) c)

private def psStandardSHA256Majority (a b c : Nat) : Nat :=
  Nat.xor (Nat.xor (Nat.land a b) (Nat.land a c)) (Nat.land b c)

private def psStandardSHA256RoundConstants : Array Nat := #[
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
  0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
  0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
  0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
  0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
  0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
  0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
  0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
  0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
  0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
  0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
  0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
  0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
  0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2]

private def psStandardSHA256Initial : Array Nat := #[
  0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
  0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19]

private def psStandardSHA256HexDigit (n : Nat) : Char :=
  Char.ofNat (if n < 10 then 48 + n else 87 + n)

private def psStandardSHA256HexByte (n : Nat) : String :=
  String.ofList [psStandardSHA256HexDigit (n / 16),
    psStandardSHA256HexDigit (n % 16)]

private def psStandardSHA256HexWord (n : Nat) : String :=
  String.join ((List.range 4).map fun i =>
    psStandardSHA256HexByte ((n / 256 ^ (3 - i)) % 256))

-- FIPS 180-4 padding: 1-bit, zeros through byte 56 modulo 64, then the
-- original bit length in eight network-order bytes (modulo 2^64).
def psStandardSnapshotSHA256 (text : String) : String := Id.run do
  let mut bytes := text.toUTF8.data.map (fun b => b.toNat)
  let bitLength := (bytes.size * 8) % 18446744073709551616
  bytes := bytes.push 128
  while bytes.size % 64 != 56 do
    bytes := bytes.push 0
  for i in [:8] do
    bytes := bytes.push ((bitLength / 256 ^ (7 - i)) % 256)
  let mut state := psStandardSHA256Initial
  for block in [:(bytes.size / 64)] do
    let mut words : Array Nat := #[]
    for i in [:16] do
      let pos := block * 64 + i * 4
      let word := bytes[pos]! * 16777216 +
        bytes[pos + 1]! * 65536 +
        bytes[pos + 2]! * 256 + bytes[pos + 3]!
      words := words.push word
    for i in [16:64] do
      words := words.push (psStandardSHA256Word
        (psStandardSHA256Small1 (words[i - 2]!) + words[i - 7]! +
         psStandardSHA256Small0 (words[i - 15]!) + words[i - 16]!))
    let mut a := state[0]!
    let mut b := state[1]!
    let mut c := state[2]!
    let mut d := state[3]!
    let mut e := state[4]!
    let mut f := state[5]!
    let mut g := state[6]!
    let mut h := state[7]!
    for i in [:64] do
      let t1 := psStandardSHA256Word
        (h + psStandardSHA256Big1 e + psStandardSHA256Choice e f g +
         psStandardSHA256RoundConstants[i]! + words[i]!)
      let t2 := psStandardSHA256Word
        (psStandardSHA256Big0 a + psStandardSHA256Majority a b c)
      h := g
      g := f
      f := e
      e := psStandardSHA256Word (d + t1)
      d := c
      c := b
      b := a
      a := psStandardSHA256Word (t1 + t2)
    state := #[
      psStandardSHA256Word (state[0]! + a),
      psStandardSHA256Word (state[1]! + b),
      psStandardSHA256Word (state[2]! + c),
      psStandardSHA256Word (state[3]! + d),
      psStandardSHA256Word (state[4]! + e),
      psStandardSHA256Word (state[5]! + f),
      psStandardSHA256Word (state[6]! + g),
      psStandardSHA256Word (state[7]! + h)]
  return String.join (state.toList.map psStandardSHA256HexWord)

def psStandardSnapshotSHA256Fingerprint (environment : PsEnvironment) : String :=
  "sha256:" ++ psStandardSnapshotSHA256 (psStandardSnapshotPayload environment)

-- SHA-256 was initially qualified at 2a75d31c; this reviewed selected-roster
-- digest covers 212 declarations after the checked List.take/drop expansion
-- qualified at 03ea9ac5 (Linux 38296669991).
-- It covers *only* the encoded closed prelude/declaration/class/instance/
-- alias roster, not source notation, deriving handlers, imported Lean
-- extensions, effects or the whole trusted execution base.
def psStandardSnapshotExpectedSHA256 : String :=
  "sha256:6e6f1fad15d4f0cb401a09c1ebc219c3f60dd50acb21061ca9eee4ab782bd85e"

def psStandardSnapshotValidateCrypto (environment : PsEnvironment)
    (expected : String) : Except String Unit := do
  let observed := psStandardSnapshotSHA256Fingerprint environment
  if observed != expected then
    throw ("PSCV0-STANDARD: SHA-256 registry digest drift; expected " ++
      expected ++ ", got " ++ observed)

-- Compare both snapshots of the *same* canonical payload before refusing.
-- When reviewing an intentional Standard expansion, expose both observed
-- values in one trusted Linux run; never silently pin either observed value.
def psStandardSnapshotValidate (environment : PsEnvironment)
    (expected : String) : Except String Unit := do
  psStandardExceptAudit environment
  let observedFNV := psStandardSnapshotFingerprint environment
  let observedSHA := psStandardSnapshotSHA256Fingerprint environment
  if observedFNV != expected ||
      observedSHA != psStandardSnapshotExpectedSHA256 then
    throw ("PSCV0-STANDARD: selected registry drift; expected FNV " ++ expected ++
      " and SHA-256 " ++ psStandardSnapshotExpectedSHA256 ++
      "; got FNV " ++ observedFNV ++ " and SHA-256 " ++ observedSHA)
