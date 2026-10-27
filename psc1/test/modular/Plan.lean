import Ps.BackendCommon.Modules

/-! Negative graph tests exercise the actual strict validator/planner on typed IR.
These are unit tests, not independent admission or backend correctness evidence. -/

namespace ModularPlanTest

def nat : PsVerifiedIrType := .primitive .nat

def leaf : PsVerifiedIrDeclaration := {
  name := "moduleLeaf"
  typeParameters := []
  parameters := [{ name := "value", type := nat }]
  resultType := nat
  body := .var "value"
}

def consumer : PsVerifiedIrDeclaration := {
  name := "moduleUse"
  typeParameters := []
  parameters := [{ name := "value", type := nat }]
  resultType := nat
  body := .call (.var "moduleLeaf") [] [.var "value"]
}

def raw : PsVerifiedIrModule :=
  { psVerifiedIrModuleEmpty with declarations := [leaf, consumer] }

def owners : List PsModuleOwner :=
  [{ name := "moduleLeaf", unit := 1 }, { name := "moduleUse", unit := 2 }]

def refuse {α : Type} (label expected : String) (value : Except String α) : IO Unit :=
  match value with
  | .ok _ => throw (IO.userError ("unexpected acceptance: " ++ label))
  | .error code =>
    if code == expected then IO.println ("PSC1_MODULE_PLAN_REFUSAL " ++ label ++ ":" ++ code)
    else throw (IO.userError (label ++ ": expected " ++ expected ++ ", got " ++ code))

def check : IO Unit := do
  match psPlanModules raw owners with
  | .error code => throw (IO.userError ("positive graph refused: " ++ code))
  | .ok plan =>
    if plan.units.length != 3 then throw (IO.userError "positive unit coverage")
  refuse "missing-owner" "PSC1_MODULE_OWNER_COVERAGE" (psPlanModules raw owners.tail)
  refuse "duplicate-owner" "PSC1_MODULE_OWNER_COVERAGE"
    (psPlanModules raw [{ name := "moduleLeaf", unit := 1 }, { name := "moduleLeaf", unit := 2 }])
  refuse "owner-range" "PSC1_MODULE_OWNER_COVERAGE"
    (psPlanModules raw [{ name := "moduleLeaf", unit := 3 }, { name := "moduleUse", unit := 2 }])
  refuse "backward-dependency" "PSC1_MODULE_CYCLE_OR_ORDER"
    (psPlanModules raw [{ name := "moduleLeaf", unit := 2 }, { name := "moduleUse", unit := 1 }])
  refuse "empty-source-owner" "PSC1_MODULE_EMPTY_SOURCE_OWNER"
    (psPlanModules raw [{ name := "moduleLeaf", unit := 1 }, { name := "moduleUse", unit := 1 }])
  let initializer : PsVerifiedIrDeclaration := {
    name := "moduleInit"
    typeParameters := []
    parameters := []
    resultType := nat
    body := .call (.var "moduleLeaf") [] [.literal (.natural 0)]
  }
  refuse "eager-initializer" "PSC1_MODULE_EAGER_INITIALIZER:moduleInit"
    (psPlanModules { raw with declarations := [leaf, consumer, initializer] }
      (owners ++ [{ name := "moduleInit", unit := 2 }]))
  refuse "reference-fuel" "PSC1_MODULE_REFERENCE_FUEL"
    (Ps.Internal.ModuleGraph.references 0 [] (.literal (.natural 0)))
  for name in ["__ps$private", "eval", "Function", "require", "process", "globalThis", "then"] do
    refuse ("reserved-" ++ name) "PSC1_MODULE_RESERVED_NAME" (Ps.Internal.ModuleGraph.safeName name)
  let bound ← match Ps.Internal.ModuleGraph.references 20 []
      (.lambda [{ name := "local", type := nat }] nat (.var "local")) with
    | .error code => throw (IO.userError code)
    | .ok names => pure names
  if !bound.isEmpty then throw (IO.userError "lexical binding became global")
  IO.println "PSC1_MODULE_PLAN_TESTS_PASSED positive-dag lexical-binding 14-refusals"

end ModularPlanTest

def main : IO Unit := ModularPlanTest.check
