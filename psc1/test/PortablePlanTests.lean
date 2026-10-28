import Lean.Data.Json
import Ps.Host.ExecutablePlan
import Ps.BackendCommon.ExecutablePlan

def require (condition : Bool) (label : String) : IO Unit :=
  unless condition do throw (IO.userError label)

def planIdentity (plan : PsModulePlan) : Lean.Json :=
  Lean.Json.mkObj [
    ("packages", Lean.toJson plan.packages),
    ("owners", Lean.toJson (plan.owners.map fun owner => (owner.name, owner.unit))),
    ("units", Lean.toJson (plan.units.map fun unit =>
      (unit.index, unit.declarations.map (fun d => d.name),
        unit.imports.map (fun owner => (owner.name, owner.unit)))))]

def compare (raw : PsVerifiedIrModule) (owners : List PsModuleOwner)
    (specifiers : List String) : IO Unit := do
  let native := Ps.Host.ExecutablePlan.plan raw owners specifiers.toArray
  let portable := Ps.Internal.ExecutablePlan.plan raw owners specifiers
  match native, portable with
  | .ok (left, leftMapping), .ok (right, rightMapping) =>
    require (planIdentity left == planIdentity right) "portable-plan-body-order"
    require (leftMapping == rightMapping) "portable-plan-source-mapping"
  | .error left, .error right => require (left == right) ("portable-refusal:" ++ left ++ ":" ++ right)
  | _, _ => throw (IO.userError "native-portable-acceptance-differs")

def nat : PsVerifiedIrType := .primitive .nat
def value (name : String) (body : PsVerifiedIrExpr) : PsVerifiedIrDeclaration :=
  { name, typeParameters := [], parameters := [], resultType := nat, body }
def sources : List String := ["@proofscript/foundation/generated/runtime",
  "@proofscript/core/generated/Test", "@proofscript/elab/generated/Other"]
def original : PsVerifiedIrModule :=
  { imports := [], structures := [], inductives := [],
    declarations := [
      value "computed" (.call (.var "reader") [] [.literal (.natural 0)]),
      { value "reader" (.var "alias") with parameters := [{name := "x", type := nat}] },
      value "alias" (.var "answer"), value "answer" (.literal (.natural 42))] }
def own (raw : PsVerifiedIrModule) : List PsModuleOwner :=
  raw.declarations.map (fun d => {name := d.name, unit := 1})

def main : IO Unit := do
  let empty : PsStringMap Nat := .empty
  let first := psStringMapPut empty "aȀ" 7
  let second := psStringMapPut first "bÿ" 9
  let replaced := psStringMapPut second "aȀ" 11
  require (psStringSetHash "aȀ" == psStringSetHash "bÿ") "actual-hash-collision"
  require (psStringMapGet second "aȀ" == some 7 && psStringMapGet second "bÿ" == some 9)
    "collision-full-key-lookup"
  require (psStringMapGet first "bÿ" == none && psStringMapGet empty "aȀ" == none)
    "persistent-snapshots"
  require (psStringMapGet replaced "aȀ" == some 11 && psStringMapGet replaced "bÿ" == some 9)
    "exact-key-replacement"
  for name in ["", "x", "é", "🙂", "__ps", "__ps$", "__ps$hidden", "eval", "then", "evaluation"] do
    let actual := match Ps.Internal.ModuleGraph.safeName name with
      | .ok _ => true
      | .error _ => false
    let native := !(name.startsWith "__ps$" ||
      ["eval", "Function", "require", "process", "globalThis", "then"].contains name)
    require (actual == native) "portable-reserved-name-prefix"
  compare original (own original) sources
  for count in List.range 48 do
    let declarations := (List.range (count + 1)).map fun n =>
      value ("v" ++ toString n)
        (if n == 0 then .literal (.natural 1) else .var ("v" ++ toString (n - 1)))
    let raw := { original with declarations := declarations.reverse }
    compare raw (own raw) sources
  compare original ((own original).drop 1) sources
  compare original ({ name := "computed", unit := 1 } :: (own original).dropLast) sources
  compare original (own original) ["@proofscript/core/generated/runtime", sources[1]!]
  compare original (own original) [sources[0]!, "@proofscript/core/generated/../bad"]
  compare original (own original) [sources[0]!, sources[1]!, sources[1]!]
  let illTyped := {original with declarations := [value "wrong" (.literal (.bool true))]}
  compare illTyped (own illTyped) sources
  let cyclic := {original with declarations := [
    value "alias" (.var "computed"),
    value "computed" (.call (.var "reader") [] [.literal (.natural 0)]),
    { value "reader" (.var "alias") with parameters := [{name := "x", type := nat}] },
    value "answer" (.literal (.natural 42))] }
  compare cyclic (own cyclic) sources
  compare original [{name := "computed", unit := 1}, {name := "reader", unit := 2},
    {name := "alias", unit := 1}, {name := "answer", unit := 1}] sources
  IO.println "PSC1_PORTABLE_PLAN_PASS 49 native/portable plans; 8 refusal classes; real hash collision, replacement and immutable snapshots"

