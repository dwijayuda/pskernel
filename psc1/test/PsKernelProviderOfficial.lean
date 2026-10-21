import Lean

/- Official Lean 4.35 reference for the exact semantic fixtures in
   scripts/pskernel-provider-smoke.mjs. This is a test-only oracle;
   neither native nor generated provider imports it. No declaration is
   installed without doCheck=true. Transport/resource cases are separate. -/

private def require (label : String) (value : Bool) : IO Unit := do
  unless value do
    throw (IO.userError ("PSC1_PROVIDER_OFFICIAL_FAILED " ++ label))

private def nm (value : String) : Lean.Name :=
  .str .anonymous value

private def s0 : Lean.Expr := .sort .zero
private def s1 : Lean.Expr := .sort (.succ .zero)

private def definition (name : String) (type value : Lean.Expr) : Lean.Declaration :=
  .defnDecl {
    name := nm name
    levelParams := []
    type := type
    value := value
    hints := .regular 0
    safety := .safe
  }

private def first : Lean.Declaration :=
  definition "SortAlias" s1 s0

private def dependent : Lean.Declaration :=
  definition "AliasAgain" s1 (.const (nm "SortAlias") [])

private def identityType : Lean.Expr :=
  .forallE (nm "P") s0
    (.forallE (nm "h") (.bvar 0) (.bvar 1) .default) .default

private def identityProof : Lean.Expr :=
  .lam (nm "P") s0
    (.lam (nm "h") (.bvar 0) (.bvar 0) .default) .default

private def proofDeclaration (value : Lean.Expr) : Lean.Declaration :=
  .thmDecl {
    name := nm "identityProof"
    levelParams := []
    type := identityType
    value := value
  }

private def unitDeclaration : Lean.Declaration :=
  .inductDecl [] 0 [{
    name := nm "UnitExample"
    type := s1
    ctors := [{
      name := .str (nm "UnitExample") "mk"
      type := .const (nm "UnitExample") []
    }]
  }] false

private def checkOfficial (environment : Lean.Environment) (label : String)
    (declaration : Lean.Declaration) : IO Lean.Environment := do
  match environment.addDeclCore 0 0 declaration none true with
  | .ok checked => return checked
  | .error _ =>
      throw (IO.userError ("PSC1_PROVIDER_OFFICIAL_UNEXPECTED_REJECTION " ++ label))

private def refuse (environment : Lean.Environment) (label : String)
    (declaration : Lean.Declaration) : IO Unit := do
  match environment.addDeclCore 0 0 declaration none true with
  | .ok _ =>
      throw (IO.userError ("PSC1_PROVIDER_OFFICIAL_UNEXPECTED_ACCEPTANCE " ++ label))
  | .error _ =>
      IO.println ("PSC1_PROVIDER_OFFICIAL_CASE " ++ label ++ " rejectedInvalid")

def main : IO Unit := do
  let empty ← Lean.mkEmptyEnvironment
  let afterFirst ← checkOfficial empty "SortAlias" first
  let afterSecond ← checkOfficial afterFirst "AliasAgain" dependent
  let afterProof ← checkOfficial afterSecond "identityProof" (proofDeclaration identityProof)
  let complete ← checkOfficial afterProof "UnitExample" unitDeclaration
  for name in [nm "SortAlias", nm "AliasAgain", nm "identityProof", nm "UnitExample",
      Lean.Name.str (nm "UnitExample") "mk", Lean.Name.str (nm "UnitExample") "rec"] do
    require ("declared-" ++ toString name) (complete.contains name)
  require "original-environment-unchanged" (!(empty.contains (nm "SortAlias")))
  IO.println "PSC1_PROVIDER_OFFICIAL_CASE valid-batch accepted declarations=4"

  -- Same malformed semantic requests as the two provider executables.
  refuse empty "wrong-definition-type" (definition "Bad" s0 s0)
  refuse empty "invalid-proof" (proofDeclaration s0)
  refuse afterFirst "late-duplicate" first
  refuse empty "unknown-dependency" dependent

  -- Failed calls yield no replacement environment. A subsequent fresh call
  -- still accepts the original declaration and cannot see prior sessions.
  let fresh ← checkOfficial empty "fresh-after-failure" first
  require "fresh-after-failure-publishes-only-checked-name"
    (fresh.contains (nm "SortAlias") && !(fresh.contains (nm "AliasAgain")))
  require "empty-remains-empty" (!(empty.contains (nm "SortAlias")))
  IO.println "PSC1_CANONICAL_PROVIDER_OFFICIAL: PASS cases=5 batchDeclarations=4 doCheck=true"
