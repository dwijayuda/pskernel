-- Array universe-family digests independently measured by strict CI38734094047.
import Ps.Environment.SelfHostProd

-- A portable, length-delimited canonical serialization of the checked
-- environment's declaration and instance inputs. This is a reproducible
-- drift fingerprint, NOT a cryptographic proof certificate. In particular
-- kernel admission, audited primitive models and the full v7 assumption/
-- effect closure remain separate gates.
--
-- Scope: Lean 4.35.0 native selected prelude, including all installed
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
  | .quotientDecl name levels type kind => psStandardSnapshotNode "kernel-quotient" [
      psStandardSnapshotName name,
      psStandardSnapshotList psStandardSnapshotName levels,
      psStandardSnapshotExpr type, psQuotientKindTag kind]
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
  psStandardSnapshotNode "PSCV0-STDENV-FNV64-v3" [
    "Lean-4.35.0@eb6cafb7290e8bd5f2937522d8d804f58f02bafc",
    psStandardSnapshotList psStandardSnapshotDeclaration environment.declarations,
    psStandardSnapshotList psStandardSnapshotName environment.classes,
    psStandardSnapshotList psStandardSnapshotClassParameters
      environment.classParameters,
    psStandardSnapshotList psStandardSnapshotInstance environment.instances.entries,
    psStandardSnapshotList psStandardSnapshotInstance environment.instances.defaults,
    psStandardSnapshotList psStandardSnapshotAlias environment.exportedAliases,
    psStandardSnapshotList (fun declaration =>
      let name := psDeclarationName declaration
      psStandardSnapshotNode "reducibility" [psStandardSnapshotName name,
        psReducibilityName (psEnvironmentReducibility environment name)])
      environment.declarations]

-- Fixed-width FNV-1a over the canonical UTF-8 bytes. Lean 4.35.0 UInt64
-- arithmetic is exactly modulo 2^64 and uses native word operations. The
-- public result and serialized payload are unchanged and platform-independent.
def psStandardSnapshotFNV64 (text : String) : Nat :=
  (text.toUTF8.foldl (fun (acc : UInt64) byte =>
    (acc ^^^ byte.toUInt64) * 1099511628211) 14695981039346656037).toNat

def psStandardSnapshotFingerprint (environment : PsEnvironment) : String :=
  "fnv1a64:" ++ toString (psStandardSnapshotFNV64
    (psStandardSnapshotPayload environment))

-- This expected value is generated only from the qualified selected prelude
-- and deliberately changes with every intentional registered semantic update.
-- The official kernel is still the authority for checking its declarations.
-- Reviewed /60: 17 exported Hashable/opaque dependency declarations,
-- 17 checked instance definitions, hash64 and one hash alias/class registration.
-- No new axiom. Linux 38464681852 compiled the native compiler/oracle,
-- regenerated all assets exactly and passed the signature/status audit before
-- independently reporting both strict selected-registry digests.
-- Reviewed /61: native product/list equations, 16 unsigned display/default
-- dictionaries and the 803-declaration unsigned proof slice (six old axioms
-- replaced), plus 24 arithmetic dictionaries. Exactly the two user-approved
-- pinned assumptions. Linux38476108793 compiled both oracles, kernel-replayed
-- all assets and reproduced source byte-for-byte, then independently reported
-- both strict digests using the previous Nat-based checksum implementation.
-- The native-word implementation below must reproduce those exact digests.
-- F0 selected logical Float/Float32 identity; independently observed at
-- bdfdb6b CI 38534047864 before the old digest correctly refused drift.
-- The 51 checked candidate declarations replace 2 historical type axioms;
-- no new assumptions, classes or instances.
-- Reviewed checked Int8/Int16/Int32/Int64/ISize identity import:
-- 15 genuine native declarations replace exactly five legacy type axioms.
-- Independently observed during strict drift refusal at bdfdb6 successor
-- 8bee79d6 / Linux 38545886718. No classes, instances or new assumptions.
-- M2+A checked-only signed BitVec + Float read-model extension.
-- Exactly 62+6 declarations; full source/assets replayed by the official
-- kernel before the independent frozen-digest refusal in CI 38549762258.
-- No new classes, instances, assumptions, or executable primitive claims.
-- Added 36 checked generic Int8/Int16/Int32/Int64 dictionaries:
-- HAdd/HSub/HMul/HDiv/HMod/Neg/OfNat/BEq/Inhabited. Both hashes
-- were independently observed after genuine strict drift refusal at
-- a4fdce40, Linux Actions 38556955048; no new assumptions.
-- Four checked Float32/64 bit Bool-valued equality models,
-- distinct from source BEq/DecidableEq instance registration. IEEE beq
-- refuses NaN and equates signed zeros; canonical structural bit identity
-- normalizes NaNs and distinguishes signed zeros. Only selected UIntN.land,
-- UIntN.toNat, Nat.beq, Bool.rec and prior checked bit helpers are used.
-- No axiom, runtime intrinsic, new class or instance. Linux 38647562675
-- independently compiled, checked signatures and observed both strict
-- FNV/SHA before correctly refusing the prior selected snapshot.
-- These hashes alone do not qualify executable semantics.
-- Four additional checked Float32/64 bit classifiers: isInf and
-- isFinite. Exact IEEE exponent/fraction logic over admitted UInt32/64,
-- preserving both signed zeros, all subnormals, ±Inf, canonical NaN.
-- No Float constructor, external primitive, class/instance or new axiom.
-- Both digests independently observed after native build and strict
-- registry refusal in Linux 38646329990. Final source/typed-IR/runtime
-- qualification remains mandatory; this pin alone is not acceptance.
-- Four checked F1 Float32/Float64 *bit helper* declarations, each built
-- from existing UInt32/UInt64 bitwise, Nat.beq, and Bool.rec operations.
-- No Float constructor/unchecked valid proof, new axiom, instance or runtime
-- primitive. Linux 38644449354 rebuilt native source and checked pinned
-- asset signatures before independently reporting BOTH strict digests.
-- This frozen pin alone does NOT qualify emitted target semantics.
-- Independently observed and reviewed ByteArray.copySlice source/typed
-- signature and default optParam; extract now delegates to the same checked
-- slicing mechanism. Pinned Lean 4.35.0 references: Init/Data/ByteArray/
-- Basic.lean. Linux 38621774797 compiled native Lean, regenerated checked
-- assets, audited selected signature/status and refused both old digests.
-- No axiom/primitive/class/instance addition. Pinned values alone do not
-- qualify source elaboration, typed erasure or executable backends.
-- One checked ByteArray.append logical declaration, matching exactly the
-- pinned Lean 4.35.0 Bootstrap.lean list-concatenation expression. Native
-- Linux 38619901079 independently rebuilt source and audited admitted
-- declarations, reporting both strict digests before refusing old snapshot.
-- This is not yet executable qualification or a packed runtime optimization.
-- No new axiom, class, instance or primitive.
-- Reviewed two checked logical ByteArray/List conversion and extraction
-- declarations. Linux 38617904426 independently rebuilt the native source,
-- replayed pinned assets and signature/status audits and reported BOTH new
-- strict FNV/SHA digests before refusing the outdated registry snapshot.
-- No new axiom, primitive, instance or independent byte-storage model.
-- This pin alone is NOT executable qualification.
-- Reviewed selected logical ByteArray.toList over checked Array.toList:
-- one ordinary declaration; no new axiom, class, instance or runtime primitive.
-- Both strict digests were reported by Linux run 38608956405 after native
-- compiler build, asset regeneration and source signature/status audits.
-- This update is NOT executable qualification: all remaining target gates
-- and a full green run are still required before admission.
-- Independently observed strict v7 Standard FNV/SHA values at Linux
-- 38607411114, after adding checked ByteArray.get/set and actual
-- GetElem, GetElem? and LawfulGetElem dictionaries. This accepts no runtime
-- behavior: source/erasure/JS/TS/Rust/Wasm qualification must still pass.
-- Reviewed ByteArray equality with a checked Nat-index recursive worker
-- after the erased-local failure of earlier candidates. Linux 38600798961
-- built the native source and oracles, replayed the selected signature/status
-- audit and independently observed both strict digests. Erasure/backend
-- qualification remains mandatory: this pin alone confers no acceptance.
-- Four checked IntN.toInt conversions, exact native implicit_reducible
-- statuses. These precise FNV/SHA are from independent strict drift
-- refusal in Linux 38563557310 at 09965258; never infer expected hashes.
-- Research-only Lean 4.35.0 List.get universe-polymorphism repair.
-- Native compilation of the exact checked getter/worker and the 534-module
-- build passed, then the unchanged selected-registry guard independently
-- reported the following FNV/SHA-256 values at Linux run 38679310229.
-- This pin is NOT acceptance; unchanged native/backends/Wasmtime CI must pass.
-- Exact Int arithmetic asset: 28 checked declarations replace four axioms.
-- Both digests independently observed by strict refusal in Linux 38705958851
-- at 5cffe928 after native compilation; all assets regenerate byte-for-byte.
-- These pins alone do not qualify source execution or backend preservation.
-- Linux 38708373315 independently measured the complete polymorphic List
-- indexing family and instance level metadata; no declaration/assumption added.
-- Independently measured by strict drift refusal in native CI38712915969:
-- 21 checked constructor/validity declarations and two public typed wrappers.
-- No new assumptions, classes, instances or executable Float capability.
def psStandardSnapshotExpected : String :=
  "fnv1a64:14544844717468498892"


-- FIPS 180-4 sections 4.1.2 and 6.2 define SHA-256 over 32-bit words.
-- Use pinned Lean 4.35.0 UInt32 and packed ByteArray operations directly:
-- wraparound is the required modular arithmetic, without boxed Nat remainders.
-- The canonical payload, padding, digest text and trust boundary do not change.
-- Source references: Init/Data/UInt/{Basic,BasicAux}.lean and ByteArray/Basic.lean.
-- A digest is integrity evidence, not proof of consistency or semantic coverage.
@[inline] private def psStandardSHA256ROR (word shift : UInt32) : UInt32 :=
  (word >>> shift) ||| (word <<< (32 - shift))

@[inline] private def psStandardSHA256Small0 (word : UInt32) : UInt32 :=
  psStandardSHA256ROR word 7 ^^^ psStandardSHA256ROR word 18 ^^^ (word >>> 3)

@[inline] private def psStandardSHA256Small1 (word : UInt32) : UInt32 :=
  psStandardSHA256ROR word 17 ^^^ psStandardSHA256ROR word 19 ^^^ (word >>> 10)

@[inline] private def psStandardSHA256Big0 (word : UInt32) : UInt32 :=
  psStandardSHA256ROR word 2 ^^^ psStandardSHA256ROR word 13 ^^^ psStandardSHA256ROR word 22

@[inline] private def psStandardSHA256Big1 (word : UInt32) : UInt32 :=
  psStandardSHA256ROR word 6 ^^^ psStandardSHA256ROR word 11 ^^^ psStandardSHA256ROR word 25

@[inline] private def psStandardSHA256Choice (a b c : UInt32) : UInt32 :=
  (a &&& b) ^^^ (~~~a &&& c)

@[inline] private def psStandardSHA256Majority (a b c : UInt32) : UInt32 :=
  (a &&& b) ^^^ (a &&& c) ^^^ (b &&& c)

private def psStandardSHA256RoundConstants : Array UInt32 := #[
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

private def psStandardSHA256Initial : Array UInt32 := #[
  0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
  0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19]

private def psStandardSHA256HexDigit (n : Nat) : Char :=
  Char.ofNat (if n < 10 then 48 + n else 87 + n)

private def psStandardSHA256HexByte (n : Nat) : String :=
  String.ofList [psStandardSHA256HexDigit (n / 16),
    psStandardSHA256HexDigit (n % 16)]

private def psStandardSHA256HexWord (word : UInt32) : String :=
  let n := word.toNat
  String.join ((List.range 4).map fun i =>
    psStandardSHA256HexByte ((n / 256 ^ (3 - i)) % 256))

-- FIPS 180-4 padding: 1-bit, zeros through byte 56 modulo 64, then the
-- original bit length in eight network-order bytes (modulo 2^64).
def psStandardSnapshotSHA256 (text : String) : String := Id.run do
  let mut bytes := text.toUTF8
  let bitLength := UInt64.ofNat bytes.size * 8
  bytes := bytes.push 128
  while bytes.size % 64 != 56 do
    bytes := bytes.push 0
  for i in [:8] do
    bytes := bytes.push ((bitLength >>> UInt64.ofNat (8 * (7 - i))).toUInt8)
  let mut state := psStandardSHA256Initial
  for block in [:(bytes.size / 64)] do
    let mut words : Array UInt32 := Array.emptyWithCapacity 64
    for i in [:16] do
      let pos := block * 64 + i * 4
      let word := (bytes[pos]!.toUInt32 <<< 24) |||
        (bytes[pos + 1]!.toUInt32 <<< 16) |||
        (bytes[pos + 2]!.toUInt32 <<< 8) ||| bytes[pos + 3]!.toUInt32
      words := words.push word
    for i in [16:64] do
      words := words.push
        (psStandardSHA256Small1 (words[i - 2]!) + words[i - 7]! +
         psStandardSHA256Small0 (words[i - 15]!) + words[i - 16]!)
    let mut a := state[0]!
    let mut b := state[1]!
    let mut c := state[2]!
    let mut d := state[3]!
    let mut e := state[4]!
    let mut f := state[5]!
    let mut g := state[6]!
    let mut h := state[7]!
    for i in [:64] do
      let t1 := h + psStandardSHA256Big1 e + psStandardSHA256Choice e f g +
        psStandardSHA256RoundConstants[i]! + words[i]!
      let t2 := psStandardSHA256Big0 a + psStandardSHA256Majority a b c
      h := g
      g := f
      f := e
      e := d + t1
      d := c
      c := b
      b := a
      a := t1 + t2
    state := #[
      state[0]! + a,
      state[1]! + b,
      state[2]! + c,
      state[3]! + d,
      state[4]! + e,
      state[5]! + f,
      state[6]! + g,
      state[7]! + h]
  return String.join (state.toList.map psStandardSHA256HexWord)

def psStandardSnapshotSHA256Fingerprint (environment : PsEnvironment) : String :=
  "sha256:" ++ psStandardSnapshotSHA256 (psStandardSnapshotPayload environment)

-- SHA-256 was initially qualified at 2a75d31c; this reviewed selected-roster
-- digest covers 212 declarations after the checked List.take/drop expansion
-- qualified at 03ea9ac5 (Linux 38296669991).
-- It covers *only* the encoded closed prelude/declaration/class/instance/
-- alias roster, not source notation, deriving handlers, imported Lean
-- extensions, effects or the whole trusted execution base.
-- Reviewed direct coercion expansion: Coe/CoeFun/CoeSort structures,
-- constructors and projections. Nine declarations, three classes; no new
-- instance, axiom, primitive or alias. Independently observed on Linux at
-- 38426692213; both guards remain strict.
-- Reviewed quoting expansion: Char.quoteCore/quote/repr, String.quote and
-- its private total worker. Five checked definitions, unchanged assumptions,
-- classes and instances. Native oracle and signature/status audit passed at
-- Linux 38435566322, which independently reported both new strict digests.
-- Stable-pin review: only the payload's toolchain identity changed; the
-- 313-declaration roster is unchanged. Linux 38437265956 compiled with
-- eb6cafb7290e8bd5f2937522d8d804f58f02bafc and reported both values.
-- Checked Int review: replace Int/ofNat/negSucc assumptions, add rec/toNat;
-- no new axioms, classes or instances. Linux 38438411914 independently built
-- the native compiler/oracle and reported these exact payload digests.
-- Pure Format review: 79 declarations for the real document algebra,
-- checked pure measurement/worklist/rendering definitions and helper records.
-- No new axiom, primitive, class, instance or alias. Linux 38442009692 built
-- the native compiler/oracle and passed the signature/status audit before
-- independently reporting both strict payload digests.
-- Reviewed ToFormat/Repr expansion: 38 checked declarations, 3 classes,
-- 20 instances, two exported aliases. List and selected operations now carry
-- element/result universes; ground consumers instantiate them explicitly.
-- No new assumption/runtime primitive. Source, native oracle and reducibility
-- audit built successfully at Linux 38446055875 before both strict digests
-- were independently reported. Full kernel/runtime qualification follows.
-- Reviewed collection-display completion: 20 further checked declarations,
-- one class, 12 instances, one exported alias; polymorphic List.get?Internal
-- is a direct reference preserving its target telescope. No new assumption
-- or primitive. Linux 38447202674 compiled both oracles and passed the native
-- signature/status audit before independently reporting these strict digests.
-- Entry-prefix review: only the List.get?Internal checked alias body changed
-- to match the referenced definition's existing raw lambda entry. No new
-- declaration, registration, assumption or primitive. Linux 38448085898
-- independently compiled the source/oracles and reported both new values.
-- F2 exact logical operation/decision closure plus scalar dictionaries:
-- independently measured by strict refusal in native CI38730889997.
-- Candidate replay CI38729006492 confirms the byte-exact checked asset.
def psStandardSnapshotExpectedSHA256 : String :=
  "sha256:373b27a0b77083baa58810055d68b6639ec00c2038da7641d3dd5c042e8f4e0d"

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
  let payload := psStandardSnapshotPayload environment
  let observedFNV := "fnv1a64:" ++ toString (psStandardSnapshotFNV64 payload)
  let observedSHA := "sha256:" ++ psStandardSnapshotSHA256 payload
  if observedFNV != expected ||
      observedSHA != psStandardSnapshotExpectedSHA256 then
    throw ("PSCV0-STANDARD: selected registry drift; expected FNV " ++ expected ++
      " and SHA-256 " ++ psStandardSnapshotExpectedSHA256 ++
      "; got FNV " ++ observedFNV ++ " and SHA-256 " ++ observedSHA)
