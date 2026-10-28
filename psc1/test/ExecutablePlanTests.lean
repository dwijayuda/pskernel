import Ps.Host.ExecutablePlan

open Ps.Host.ExecutablePlan

def require (condition : Bool) (label : String) : IO Unit :=
  if condition then pure () else throw (IO.userError label)

def nat : PsVerifiedIrType := .primitive .nat

def answer : PsVerifiedIrDeclaration :=
  { name := "answer", typeParameters := [], parameters := [], resultType := nat,
    body := .literal (.natural 42) }

def aliasValue : PsVerifiedIrDeclaration :=
  { answer with name := "aliasValue", body := .var "answer" }

def reader : PsVerifiedIrDeclaration :=
  { answer with name := "reader", parameters := [{ name := "x", type := nat }],
    body := .var "aliasValue" }

def computed : PsVerifiedIrDeclaration :=
  { answer with name := "computed", body := .call (.var "reader") [] [.literal (.natural 0)] }

def raw : PsVerifiedIrModule :=
  { imports := [], structures := [], inductives := [],
    declarations := [computed, reader, aliasValue, answer] }

def specs : Array String :=
  #["@proofscript/foundation/generated/runtime", "@proofscript/core/generated/Test"]

def owners (input : PsVerifiedIrModule) : List PsModuleOwner :=
  input.declarations.map (fun d => { name := d.name, unit := 1 })

def rejects (result : Except String α) (label : String) : IO Unit :=
  match result with
  | .ok _ => throw (IO.userError ("accepted:" ++ label))
  | .error _ => pure ()

def main : IO Unit := do
  let planned ← match plan raw (owners raw) specs with
    | .ok value => pure value.1
    | .error code => throw (IO.userError code)
  require ((planned.units[1]?.map (fun unit => unit.declarations.map (fun d => d.name))) ==
    some ["reader", "answer", "aliasValue", "computed"]) "computed-initializer-order"
  rejects (plan raw ((owners raw).drop 1) specs) "missing-owner"
  rejects (plan raw ({ name := "computed", unit := 1 } :: (owners raw).dropLast) specs) "duplicate-owner"
  rejects (plan raw (owners raw) #["@proofscript/foundation/generated/runtime",
    "@proofscript/core/generated/../bad"]) "unsafe-specifier"
  rejects (plan raw (owners raw) #["@proofscript/core/generated/runtime",
    "@proofscript/core/generated/Test"]) "runtime-owner"
  let bad := { raw with declarations := [{ answer with body := .literal (.bool true) }] }
  rejects (plan bad (owners bad) specs) "strict-negative"
  let circular := { raw with declarations := [
    { aliasValue with body := .var "computed" }, computed, reader, answer] }
  let circularRefs : Std.HashMap String (List String) :=
    ({} : Std.HashMap String (List String)).insert "aliasValue" ["computed"] |>
      fun refs => refs.insert "computed" ["reader"] |>
      fun refs => refs.insert "reader" ["aliasValue"] |>
      fun refs => refs.insert "answer" []
  rejects (initialize circular.declarations circularRefs) "transitive-initializer-cycle"
  let dependenciesAcross := { raw with declarations := [computed, reader, aliasValue, answer] }
  let acrossOwners := [{ name := "computed", unit := 1 }, { name := "reader", unit := 2 },
    { name := "aliasValue", unit := 1 }, { name := "answer", unit := 1 }]
  rejects (plan dependenciesAcross acrossOwners
    (specs.push "@proofscript/elab/generated/Other")) "cross-source-cycle"
  IO.println "PSC1_EXECUTABLE_PLAN_PASS computed-order missing-owner duplicate-owner unsafe-path runtime-owner strict-negative transitive-cycle cross-source-cycle"
