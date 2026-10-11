import PSKernelFast.CandidateCatalog

namespace PSKernelFast.Core

private def require (condition : Bool) (message : String) : IO Unit :=
  if condition then pure () else throw <| IO.userError message

private def name (s : String) : KName := .str .anonymous s

private def candidate (n : KName) (params : List KName) (ty : KExpr)
    (mode : SafetyMode := .safe) (kind : CandidateKind := .assumedAxiom)
    (body : Option KExpr := none) : CandidateRecord :=
  { header := {
      name := n
      levelParams := params
      type := ty
      safety := mode
      kind := kind
    }
    value? := body
  }

private def expectError (expected : CatalogError)
    (result : Except CatalogError CandidateCatalog) : IO Unit := do
  match result with
  | .error actual =>
      require (actual == expected)
        s!"wrong candidate rejection: {repr actual} expected {repr expected}"
  | .ok _ => throw <| IO.userError s!"untrusted catalog accepted malformed candidate: {repr expected}"

private def expectOk (result : Except CatalogError CandidateCatalog) :
    IO CandidateCatalog :=
  match result with
  | .ok catalog => pure catalog
  | .error reason => throw <| IO.userError s!"catalog candidate rejected: {repr reason}"

/-- A regression corpus for header preflight, NOT for theorem/proof acceptance. -/
def candidateCatalogSmoke : IO Unit := do
  let u := name "u"
  let v := name "v"
  let a := name "A"
  let b := name "B"
  let c := name "C"
  let unsafeName := name "UnsafeValue"
  let partialName := name "PartialValue"
  let empty : CandidateCatalog := {}

  let catalogA ← expectOk <| empty.register
    (candidate a [] (.sort .zero))
  require (catalogA.count == 1 && (catalogA.lookup a).isSome)
    "catalog did not record first candidate"
  require (empty.lookup a |>.isNone)
    "persistent catalog mutated its old snapshot"

  expectError (.duplicateName a) <|
    catalogA.register (candidate a [] (.sort .zero))
  expectError (.duplicateParameter u) <|
    catalogA.register (candidate b [u,u] (.sort (.param u)))
  expectError .malformedType <|
    catalogA.register (candidate b [u] (.sort (.param v)))
  expectError .malformedType <|
    catalogA.register (candidate b [] (.fvar u))
  expectError (.unknownConstant b) <|
    catalogA.register (candidate c [] (.const b []))
  expectError (.universeArity a 0 1) <|
    catalogA.register (candidate c [u] (.const a [.param u]))

  let withB ← expectOk <|
    catalogA.register (candidate b [] (.const a []))
  require (withB.count == 2 && (withB.lookup b).isSome)
    "existing valid reference or count was lost"
  require (catalogA.count == 1 && (catalogA.lookup b).isNone)
    "persistent catalog changed after registration"

  expectError .missingValue <|
    withB.register (candidate c [] (.sort .zero) .safe .defined)
  expectError .unexpectedValue <|
    withB.register (candidate c [] (.sort .zero) .safe
      .assumedAxiom (some (.sort .zero)))
  expectError .malformedValue <|
    withB.register (candidate c [] (.sort .zero) .safe
      .defined (some (.bvar 0)))
  expectError (.unknownConstant c) <|
    withB.register (candidate c [] (.sort .zero) .safe
      .defined (some (.const c [])))

  let withUnsafe ← expectOk <|
    withB.register (candidate unsafeName [] (.sort .zero) .unsafeCode)
  expectError (.forbiddenReference unsafeName) <|
    withUnsafe.register (candidate c [] (.const unsafeName []))
  expectError (.forbiddenReference unsafeName) <|
    withUnsafe.register (candidate c [] (.const unsafeName []) .partialCode)
  let allowedUnsafe ← expectOk <|
    withUnsafe.register (candidate c [] (.const unsafeName []) .unsafeCode)
  require (allowedUnsafe.count == 4) "unsafe mode reference policy failed"

  let withPartial ← expectOk <|
    withUnsafe.register (candidate partialName [] (.sort .zero) .partialCode)
  expectError (.forbiddenReference partialName) <|
    withPartial.register (candidate c [] (.const partialName []) .safe)
  let allowedPartial ← expectOk <|
    withPartial.register (candidate c [] (.const partialName []) .partialCode)
  require (allowedPartial.count == 5) "partial mode reference policy failed"

  let poly ← expectOk <|
    catalogA.register (candidate c [u] (.sort (.param u)))
  let usePoly ← expectOk <|
    poly.register (candidate b [] (.const c [.zero]))
  require (usePoly.count == 3) "universe arity accepted valid instantiation incorrectly"
  expectError (.universeArity c 1 0) <|
    poly.register (candidate b [] (.const c []))

  require (catalogA.count == 1) "failed preflight mutated immutable snapshot"
  IO.println "PSKernel-Fast G4.1: persistent unchecked catalog and reference/safety preflight PASS"
  IO.println "G4.1 limit: candidate-only; zero checked declarations or theorem admission"
end PSKernelFast.Core

def main : IO Unit := PSKernelFast.Core.candidateCatalogSmoke
