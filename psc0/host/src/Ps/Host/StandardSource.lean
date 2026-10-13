/-
Native authoring source renderer. Structural sharing follows the map/set
interning design studied in Lean 4.35.0 Lean/Util/ShareCommon.lean and
Init/ShareCommon.lean. This uses safe exact node keys rather than upstream's
unsafe object/pointer primitives. Generated data stays ordinary portable Core.
-/
import Lean
import Ps.Environment.Basic

namespace PsV7Native.StandardSource

def sourceList (items : List String) : String :=
  "[" ++ String.intercalate ", " items ++ "]"

def sourceName : PsName → String
  | .anonymous => ".anonymous"
  | .str parent value => "(.str " ++ sourceName parent ++ " " ++ reprStr value ++ ")"
  | .num parent value => "(.num " ++ sourceName parent ++ " " ++ toString value ++ ")"

def sourceLevel : PsLevel → String
  | .zero => ".zero"
  | .succ value => "(.succ " ++ sourceLevel value ++ ")"
  | .max a b => "(.max " ++ sourceLevel a ++ " " ++ sourceLevel b ++ ")"
  | .imax a b => "(.imax " ++ sourceLevel a ++ " " ++ sourceLevel b ++ ")"
  | .param name => "(.param " ++ sourceName name ++ ")"
  | .mvar index => "(.mvar " ++ toString index ++ ")"

def sourceBinder : PsBinderInfo → String
  | .explicit => ".explicit"
  | .implicit => ".implicit"
  | .strictImplicit => ".strictImplicit"
  | .instanceImplicit => ".instanceImplicit"

def sourceExpr : PsExpr → String
  | .bvar index => "(.bvar " ++ toString index ++ ")"
  | .fvar index => "(.fvar " ++ toString index ++ ")"
  | .mvar index => "(.mvar " ++ toString index ++ ")"
  | .sortE level => "(.sortE " ++ sourceLevel level ++ ")"
  | .constE name levels => "(.constE " ++ sourceName name ++ " " ++ sourceList (levels.map sourceLevel) ++ ")"
  | .app fn arg => "(.app " ++ sourceExpr fn ++ " " ++ sourceExpr arg ++ ")"
  | .lam name type body binder =>
    "(.lam " ++ sourceName name ++ " " ++ sourceExpr type ++ " " ++ sourceExpr body ++ " " ++ sourceBinder binder ++ ")"
  | .forallE name type body binder =>
    "(.forallE " ++ sourceName name ++ " " ++ sourceExpr type ++ " " ++ sourceExpr body ++ " " ++ sourceBinder binder ++ ")"
  | .letE name type value body =>
    "(.letE " ++ sourceName name ++ " " ++ sourceExpr type ++ " " ++ sourceExpr value ++ " " ++ sourceExpr body ++ ")"
  | .lit (.natural value) => "(.lit (.natural " ++ toString value ++ "))"
  | .lit (.string value) => "(.lit (.string " ++ reprStr value ++ "))"
  | .proj name index value => "(.proj " ++ sourceName name ++ " " ++ toString index ++ " " ++ sourceExpr value ++ ")"


-- Source-only structural sharing. Keys include the node type, constructor,
-- exact names and child identifiers: no alpha quotient, pointer hash or unsafe
-- runtime primitive enters generated portable Core.
structure Pool where
  enabled : Bool := false
  prefix : String := "standardNode"
  nodes : Std.HashMap String String := {}
  definitions : Array String := #[]

private def intern (type body : String) : StateM Pool String := do
  let state ← get
  let key := type ++ ":" ++ body
  if let some name := state.nodes[key]? then return name
  let name := state.prefix ++ toString state.definitions.size
  set { state with
    nodes := state.nodes.insert key name
    definitions := state.definitions.push
      ("private def " ++ name ++ " : " ++ type ++ " := " ++ body ++ "\n") }
  return name

private def sharedName : PsName → StateM Pool String
  | .anonymous => pure ".anonymous"
  | .str parent value => do
    intern "PsName" ("(.str " ++ (← sharedName parent) ++ " " ++ reprStr value ++ ")")
  | .num parent value => do
    intern "PsName" ("(.num " ++ (← sharedName parent) ++ " " ++ toString value ++ ")")

private def sharedLevel : PsLevel → StateM Pool String
  | .zero => pure ".zero"
  | .succ value => do intern "PsLevel" ("(.succ " ++ (← sharedLevel value) ++ ")")
  | .max a b => do intern "PsLevel" ("(.max " ++ (← sharedLevel a) ++ " " ++ (← sharedLevel b) ++ ")")
  | .imax a b => do intern "PsLevel" ("(.imax " ++ (← sharedLevel a) ++ " " ++ (← sharedLevel b) ++ ")")
  | .param name => do intern "PsLevel" ("(.param " ++ (← sharedName name) ++ ")")
  | .mvar index => pure ("(.mvar " ++ toString index ++ ")")

private def sharedExpr : PsExpr → StateM Pool String
  | .bvar index => pure ("(.bvar " ++ toString index ++ ")")
  | .fvar index => pure ("(.fvar " ++ toString index ++ ")")
  | .mvar index => pure ("(.mvar " ++ toString index ++ ")")
  | .sortE level => do intern "PsExpr" ("(.sortE " ++ (← sharedLevel level) ++ ")")
  | .constE name levels => do
    let name ← sharedName name
    let levels ← levels.mapM sharedLevel
    intern "PsExpr" ("(.constE " ++ name ++ " " ++ sourceList levels ++ ")")
  | .app fn arg => do intern "PsExpr" ("(.app " ++ (← sharedExpr fn) ++ " " ++ (← sharedExpr arg) ++ ")")
  | .lam name type body binder => do
    intern "PsExpr" ("(.lam " ++ (← sharedName name) ++ " " ++ (← sharedExpr type) ++
      " " ++ (← sharedExpr body) ++ " " ++ sourceBinder binder ++ ")")
  | .forallE name type body binder => do
    intern "PsExpr" ("(.forallE " ++ (← sharedName name) ++ " " ++ (← sharedExpr type) ++
      " " ++ (← sharedExpr body) ++ " " ++ sourceBinder binder ++ ")")
  | .letE name type value body => do
    intern "PsExpr" ("(.letE " ++ (← sharedName name) ++ " " ++ (← sharedExpr type) ++
      " " ++ (← sharedExpr value) ++ " " ++ (← sharedExpr body) ++ ")")
  | .lit (.natural value) => pure ("(.lit (.natural " ++ toString value ++ "))")
  | .lit (.string value) => pure ("(.lit (.string " ++ reprStr value ++ "))")
  | .proj name index value => do
    intern "PsExpr" ("(.proj " ++ (← sharedName name) ++ " " ++ toString index ++
      " " ++ (← sharedExpr value) ++ ")")

def renderName (name : PsName) : StateM Pool String := do
  if (← get).enabled then sharedName name else pure (sourceName name)

def renderExpr (expr : PsExpr) : StateM Pool String := do
  if (← get).enabled then sharedExpr expr else pure (sourceExpr expr)

def renderDeclaration (declaration : PsDeclaration) : StateM Pool String := do
  let name ← renderName (psDeclarationName declaration)
  let levels ← (psDeclarationLevelParams declaration).mapM renderName
  let type ← renderExpr (psDeclarationType declaration)
  let common := name ++ " " ++ sourceList levels ++ " " ++ type
  match declaration with
  | .definitionDecl _ _ _ value => return ".definitionDecl " ++ common ++ "\n    " ++ (← renderExpr value)
  | .theoremDecl _ _ _ value => return ".theoremDecl " ++ common ++ "\n    " ++ (← renderExpr value)
  | .opaqueDecl _ _ _ value => return ".opaqueDecl " ++ common ++ "\n    " ++ (← renderExpr value)
  | .inductiveDecl value =>
    let ctors ← value.constructors.mapM renderName
    return ".inductiveDecl (PsInductiveInfo.mk " ++ common ++ " " ++
      toString value.numParams ++ " " ++ toString value.numIndices ++ " " ++
      sourceList ctors ++ " " ++ toString value.isStructure ++ ")"
  | .constructorDecl value =>
    let owner ← renderName value.inductiveName
    return ".constructorDecl (PsConstructorInfo.mk " ++ common ++ " " ++ owner ++ " " ++
      toString value.constructorIndex ++ " " ++ toString value.numParams ++ " " ++
      toString value.numFields ++ " " ++ sourceList (value.recursiveFields.map toString) ++ ")"
  | .recursorDecl value =>
    let owners ← value.inductiveNames.mapM renderName
    return ".recursorDecl (PsRecursorInfo.mk " ++ common ++ " " ++
      sourceList owners ++ " " ++ toString value.numParams ++ " " ++ toString value.numIndices ++
      " " ++ toString value.numMotives ++ " " ++ toString value.numMinors ++ ")"
  | .quotientDecl _ _ _ kind => return ".quotientDecl " ++ common ++ " ." ++ psQuotientKindTag kind
  | .axiomDecl .. => return ".axiomDecl " ++ common
  | .partialDecl .. => return "" -- Refused before rendering.

end PsV7Native.StandardSource
