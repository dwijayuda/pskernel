import Ps.Elab.Basic

-- Lean 4.35.0 Elab/Tactic/Classical: the existing checked proposition
-- decision dictionary enters only this lexical instance scope, at priority 10.
def psElabClassicalContext (context : PsElabContext) :
    Except PsElabError PsElabContext := do
  let name := psNameAppendStr (psRootName "Classical") "propDecidable"
  let some (.definitionDecl _ levels type _) := psEnvironmentFind context.environment name
    | throw (.data "PSCV0-PROOF-PROFILE: classical requires checked Classical.propDecidable")
  if !levels.isEmpty || !context.environment.classes.any (psNameEq psDecidableName) then
    throw (.data "PSCV0-PROOF-PROFILE: invalid classical decision declaration or class")
  let expected := PsExpr.forallE (psRootName "p") (.sortE .zero)
    (.app (.constE psDecidableName []) (.bvar 0)) .explicit
  let checked ← psElabResolvedTerm context (.constE name []) (some expected)
  return { checked.context with instances := psInstanceIndexAdd context.instances {
    value := checked.term
    type := type
    className := some psDecidableName
    priority := 10 } }
