import PSKernelFast.CoreSyntax

/-!
G4.1 candidate-declaration catalog, NOT a kernel checked environment.

The persistent index is suitable for strict preflight of untrusted proposed
declarations: duplicate names, universe parameter uniqueness and constant
arity, reference closure, and safe/partial/unsafe dependency policy.

Successful preflight NEVER means a body was typed, theorem proved or admitted.
This file has no accepted/checked proof result, kernel axiom insertion, or
public proof-checking API. It does not import old PSKernel source.
-/

namespace PSKernelFast.Core

inductive SafetyMode where
  | safe
  | partialCode
  | unsafeCode
  deriving Inhabited, Repr, BEq

inductive CandidateKind where
  | assumedAxiom
  | defined
  | theoremProof
  | opaqueDef
  deriving Inhabited, Repr, BEq

structure CandidateHeader where
  name : KName
  levelParams : List KName
  type : KExpr
  safety : SafetyMode
  kind : CandidateKind
  deriving Repr

structure CandidateRecord where
  header : CandidateHeader
  value? : Option KExpr
  deriving Repr

inductive CatalogError where
  | duplicateName (name : KName)
  | duplicateParameter (name : KName)
  | malformedType
  | malformedValue
  | missingValue
  | unexpectedValue
  | unknownConstant (name : KName)
  | universeArity (name : KName) (expected actual : Nat)
  | forbiddenReference (name : KName)
  deriving Inhabited, Repr, BEq

/-- Persistent catalog of UNCHECKED candidate headers; not admitted theorems. -/
structure CandidateCatalog where
  headers : Std.HashMap KName CandidateHeader := {}
  count : Nat := 0

def CandidateCatalog.lookup (catalog : CandidateCatalog) (name : KName) :
    Option CandidateHeader :=
  catalog.headers[name]?

/-- Safety relation follows official type_checker.cpp::infer_constant policy. -/
def safetyAllows (caller callee : SafetyMode) : Bool :=
  match caller, callee with
  | .safe, .safe => true
  | .safe, _ => false
  | .partialCode, .unsafeCode => false
  | .partialCode, _ => true
  | .unsafeCode, _ => true

/-- Find the first repeated universe parameter, using lawful exact names. -/
def firstDuplicateParameter : List KName → Option KName
  | [] => none
  | name :: rest =>
      if name ∈ rest then some name
      else firstDuplicateParameter rest

/-- Traverse every constant occurrence before registering a candidate. -/
def validateReferences (catalog : CandidateCatalog) (caller : SafetyMode) :
    KExpr → Except CatalogError Unit
  | .const name levels =>
      match catalog.lookup name with
      | none => .error (.unknownConstant name)
      | some header =>
          if header.levelParams.length != levels.length then
            .error (.universeArity name header.levelParams.length levels.length)
          else if !safetyAllows caller header.safety then
            .error (.forbiddenReference name)
          else
            .ok ()
  | .app fn arg => do
      validateReferences catalog caller fn
      validateReferences catalog caller arg
  | .lam _ domain body _ => do
      validateReferences catalog caller domain
      validateReferences catalog caller body
  | .forallE _ domain body _ => do
      validateReferences catalog caller domain
      validateReferences catalog caller body
  | .letE _ declaredType value body _ => do
      validateReferences catalog caller declaredType
      validateReferences catalog caller value
      validateReferences catalog caller body
  | .mdata _ inner => validateReferences catalog caller inner
  | .proj _ _ inner => validateReferences catalog caller inner
  | _ => .ok ()

/--
Only register syntactically valid *candidates*. No declaration is promoted to
a trusted/checked environment. Reference lookup occurs against the PREVIOUS
immutable catalog so a forward/self reference cannot silently be admitted.
-/
def CandidateCatalog.register (catalog : CandidateCatalog) (record : CandidateRecord) :
    Except CatalogError CandidateCatalog := do
  let header := record.header
  if (catalog.lookup header.name).isSome then
    throw (.duplicateName header.name)
  match firstDuplicateParameter header.levelParams with
  | some repeated => throw (.duplicateParameter repeated)
  | none => pure ()
  if !(header.type.closedInput header.levelParams) then
    throw .malformedType
  match header.kind, record.value? with
  | .assumedAxiom, none => pure ()
  | .assumedAxiom, some _ => throw .unexpectedValue
  | _, none => throw .missingValue
  | _, some _ => pure ()
  match record.value? with
  | some value =>
      if !(value.closedInput header.levelParams) then
        throw .malformedValue
  | none => pure ()
  validateReferences catalog header.safety header.type
  match record.value? with
  | some value => validateReferences catalog header.safety value
  | none => pure ()
  return {
    headers := catalog.headers.insert header.name header
    count := catalog.count + 1
  }

end PSKernelFast.Core
