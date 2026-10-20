import Ps.BackendCommon.Script

def require (name : String) (condition : Bool) : IO Unit := do
  if !condition then throw (IO.userError ("PSC1_SCRIPT_PLAN_FAIL: " ++ name))
  IO.println ("PSC1_SCRIPT_PLAN_PASS: " ++ name)

def main : IO Unit := do
  let declaration : PsVerifiedIrDeclaration := {
    name := "negate", typeParameters := [], parameters := [{ name := "x", type := .primitive .bool }],
    resultType := .primitive .bool, body := .intrinsic .boolNot [] [.var "x"] }
  let raw := { psVerifiedIrModuleEmpty with declarations := [declaration] }
  let .ok plan := psBuildScriptPlan { raw := raw } ["negate"]
    | throw (IO.userError "valid scalar plan rejected")
  require "valid plan retains the exact public closure" (plan.publicNames == ["negate"] && plan.declarations.length == 1)
  require "unknown export rejected" (psBuildScriptPlan { raw := raw } ["absent"]).isError
  require "duplicate export rejected" (psBuildScriptPlan { raw := raw } ["negate", "negate"]).isError
  let forged := { raw with declarations := [{ declaration with resultType := .unknown }] }
  require "forged wrapper rechecked" (psBuildScriptPlan { raw := forged } ["negate"]).isError
  let wrong := { raw with declarations := [{ declaration with body := .literal (.natural 7) }] }
  require "ill-typed executable body rejected" (psBuildScriptPlan { raw := wrong } ["negate"]).isError
  let expression := PsVerifiedIrExpr.letE "x" (.primitive .nat) (.literal (.natural 1))
    (.letE "x" (.primitive .nat) (.var "x") (.var "x"))
  let .ok ((statements, result), _) := (psScriptLower [] expression).run {}
    | throw (IO.userError "lexical plan failed")
  let fresh := match statements with
    | [.literal a _, .copy b c, .copy d e] => a == c && b == e && b != d && result == d
    | _ => false
  require "shadowing initializer sees its previous binding" fresh
  require "lowering budget fails rather than truncates" ((psScriptLower [] expression).run { remainingNodes := 0 }).isError
  require "closure free names respect lexical shadowing"
    (psScriptFreeNames (.lambda [{ name := "x", type := .primitive .nat }] (.primitive .nat)
      (.letE "y" (.primitive .nat) (.var "z") (.intrinsic .natAdd [] [.var "x", .var "y"]))) == ["z"])
  let .ok ((body, _), _) := (psScriptLower [{ source := "f", emitted := "global_f", global := true }]
    (.call (.var "f") [] [.literal (.natural 3), .literal (.natural 4)])).run {}
    | throw (IO.userError "call normalization failed")
  let ordered := match body with
    | [.literal a (.natural 3), .literal b (.natural 4), .call _ "global_f" [x, y]] => a == x && b == y
    | _ => false
  require "call operands evaluate once in source order" ordered
  IO.println "PSC1_SCRIPT_PLAN_TESTS: 9 passed"
