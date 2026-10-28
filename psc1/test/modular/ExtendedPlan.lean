import Ps.BackendCommon.Modules

namespace ExtendedModulePlanTest

def nat : PsVerifiedIrType := .primitive .nat
def declaration (name : String) (parent : Option String) : PsVerifiedIrDeclaration := {
  name
  typeParameters := []
  parameters := [{ name := "value", type := nat }]
  resultType := nat
  body := match parent with
    | none => .var "value"
    | some fn => .call (.var fn) [] [.var "value"]
}
def raw : PsVerifiedIrModule := {
  psVerifiedIrModuleEmpty with declarations := [
    declaration "first" none, declaration "second" (some "first"),
    declaration "third" (some "second")]
}
def owners : List PsModuleOwner := [
  { name := "first", unit := 1 }, { name := "second", unit := 2 },
  { name := "third", unit := 3 }]
def packages : List String := ["@proofscript/modular-pilot-runtime",
  "@proofscript/modular-pilot-a", "@proofscript/modular-pilot-b",
  "@proofscript/modular-pilot-c"]

def refuse (label : String) (result : Except String PsModulePlan) : IO Unit :=
  match result with
  | .ok _ => throw (IO.userError ("unexpected extended acceptance: " ++ label))
  | .error code => IO.println ("PSC1_EXTENDED_PLAN_REFUSAL " ++ label ++ ":" ++ code)

def run : IO Unit := do
  match psPlanModulesWithPackages raw owners packages "psc1-modular-pilot/2" with
  | .ok plan => if plan.units.length != 4 then throw (IO.userError "unit coverage")
  | .error error => throw (IO.userError error)
  refuse "legacy-source-bound-preserved" (psPlanModulesWithPackages raw owners packages "psc1-modular-pilot/1")
  refuse "unknown-profile" (psPlanModulesWithPackages raw owners packages "psc1-modular-pilot/99")
  refuse "duplicate-package" (psPlanModulesWithPackages raw owners
    ["@proofscript/modular-pilot-runtime", "@proofscript/modular-pilot-a",
      "@proofscript/modular-pilot-a", "@proofscript/modular-pilot-c"] "psc1-modular-pilot/2")
  refuse "escaping-package" (psPlanModulesWithPackages raw owners
    ["@proofscript/modular-pilot-runtime", "../outside",
      "@proofscript/modular-pilot-b", "@proofscript/modular-pilot-c"] "psc1-modular-pilot/2")
  refuse "wrong-runtime" (psPlanModulesWithPackages raw owners
    ["@proofscript/modular-pilot-other", "@proofscript/modular-pilot-a",
      "@proofscript/modular-pilot-b", "@proofscript/modular-pilot-c"] "psc1-modular-pilot/2")
  refuse "case-variant-package" (psPlanModulesWithPackages raw owners
    ["@proofscript/modular-pilot-runtime", "@proofscript/modular-pilot-A",
      "@proofscript/modular-pilot-b", "@proofscript/modular-pilot-c"] "psc1-modular-pilot/2")
  refuse "extended-unit-bound" (psPlanModulesWithPackages raw owners
    (packages ++ List.replicate 6 "@proofscript/modular-pilot-extra") "psc1-modular-pilot/2")
  refuse "backward-global-dependency" (psPlanModulesWithPackages raw
    [{ name := "first", unit := 3 }, { name := "second", unit := 2 },
      { name := "third", unit := 1 }] packages "psc1-modular-pilot/2")
  IO.println "PSC1_EXTENDED_PLAN_PASSED four-unit-DAG 8-refusals"

end ExtendedModulePlanTest

def main : IO Unit := ExtendedModulePlanTest.run
