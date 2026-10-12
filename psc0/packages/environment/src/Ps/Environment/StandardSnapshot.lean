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
  "fnv1a64:3890664716772208725"

def psStandardSnapshotValidate (environment : PsEnvironment)
    (expected : String) : Except String Unit := do
  psStandardExceptAudit environment
  let observed := psStandardSnapshotFingerprint environment
  if observed != expected then
    throw ("PSCV0-STANDARD: registry snapshot drift; expected " ++ expected ++
      ", got " ++ observed)
