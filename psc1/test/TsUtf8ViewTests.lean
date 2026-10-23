import Ps.BackendTs.Module
import Ps.CompilerIr.Check

private def natT : PsVerifiedIrType := .primitive .nat
private def strT : PsVerifiedIrType := .primitive .string
private def boolT : PsVerifiedIrType := .primitive .bool
private def v (name : String) : PsVerifiedIrExpr := .var name
private def n (value : Nat) : PsVerifiedIrExpr := .literal (.natural value)
private def op (kind : PsVerifiedIrIntrinsic) (args : List PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  .intrinsic kind [] args
private def worker (name : String) : PsVerifiedIrDeclaration :=
  let next := .call (v name) [] [
    op .natSub [v "fuel", n 1], v "left", v "right",
    op .stringNext [v "left",v "p"], op .stringNext [v "right",v "q"]];
  let chars := op .natEq [
    op .charToNat [op .stringGet [v "left",v "p"]],
    op .charToNat [op .stringGet [v "right",v "q"]]];
  let scan := PsVerifiedIrExpr.ifE (op .stringAtEnd [v "left",v "p"])
    (op .stringAtEnd [v "right",v "q"])
    (.ifE (op .stringAtEnd [v "right",v "q"]) (.literal (.bool false))
      (.ifE chars next (.literal (.bool false))));
  let body := PsVerifiedIrExpr.ifE (op .natEq [v "fuel", n 0]) (.literal (.bool false))
    (.letE "left" strT (v "left0")
      (.letE "right" strT (v "right0") scan));
  .mk name [] [.mk "fuel" natT,.mk "left0" strT,.mk "right0" strT,.mk "p" natT,.mk "q" natT] boolT body

private def requireSome (value : Option String) : IO String :=
  match value with
  | .some text => pure text
  | .none => throw (IO.userError "expected view loop")


-- A tail iteration must preserve the environment captured by functions created
-- before its next argument assignment, including unused-name collisions.
private def captureWorker (name : String) (captureCount : Bool) : PsVerifiedIrDeclaration :=
  let functionT := PsVerifiedIrType.function [natT] natT;
  let delta := if captureCount then v "count" else n 1;
  let callback := PsVerifiedIrExpr.lambda [.mk "value" natT] natT
    (.call (v "step") [] [op .natAdd [v "value",delta]]);
  .mk name [] [.mk "step" functionT,.mk "count" natT,.mk "__ps$loop$args$0" natT] natT
    (.ifE (op .natEq [v "count",n 0])
      (.call (v "step") [] [n 3])
      (.call (v name) [] [callback,op .natSub [v "count",n 1],n 99]))

private def captureReference (captureCount : Bool) (count : Nat) (step : Nat -> Nat) : Nat :=
  match count with
  | 0 => step 3
  | count + 1 =>
      captureReference captureCount count
        (fun value => step (value + if captureCount then count + 1 else 1))

private def emitCaptureTests : IO Unit := do
  let declarations := [captureWorker "captureStep" false,captureWorker "captureCount" true]
  let module : PsVerifiedIrModule := .mk [] [] [] declarations
  if (psCheckVerifiedIrModule psIrCheckDefaultOptions module).accepted != true then
    throw (IO.userError "capture fixture rejected by strict IR checker")
  let mut outputs : List String := []
  for declaration in declarations do
    if psTsGeneratorSlotNameWorker [] [] declaration 0 0 != .none then
      throw (IO.userError "slot freshness fuel exhaustion must refuse")
    if psTsGeneratorSlotName [] [] declaration != .some "__ps$loop$args$1" then
      throw (IO.userError "unused parameter slot collision")
    if psTsGeneratorSlotName [("unused","__ps$loop$args$1")] [] declaration !=
        .some "__ps$loop$args$2" then
      throw (IO.userError "brand slot collision")
    if psTsGeneratorSlotName [] [("__ps$loop$args$1","tag")] declaration !=
        .some "__ps$loop$args$2" then
      throw (IO.userError "tag slot collision")
    let output ← requireSome (psTsEmitGeneratorLoopWithVisibility true [] [] declaration)
    outputs := outputs ++ [output]
  IO.FS.writeFile "dist/ts-utf8-views/captures.ts"
    (psTsJoin "\n" (psTsStackRuntimeSupport :: outputs))
  let mut rows : List String := []
  for count in [0,1,2,10,30] do
    for capturesCount in [false,true] do
      let name := if capturesCount then "captureCount" else "captureStep"
      let result := captureReference capturesCount count (fun value => value * 2)
      rows := rows ++ [psTsJoin "" ["[",psJsonQuote name,",",toString count,",",psJsonQuote (toString result),"]"]]
  IO.FS.writeFile "dist/ts-utf8-views/capture-reference.json"
    (psTsJoin "" ["[",psTsJoin "," rows,"]\n"])
  IO.println "PSC1_TS_GENERATOR_CAPTURE_GUARDS: strict IR, immutable iteration scopes, function/primitive captures, unused/brand/tag collisions, bounded freshness"

def main : IO Unit := do
  let current ← requireSome (psTsEmitViewTailLoopWithVisibility true [] [] (worker "equalCurrent"))
  let legacy ← requireSome (psTsEmitTailLoopWithVisibility true [] [] (worker "equalLegacy"))
  let params := [.mk "text" strT]
  let changing : PsVerifiedIrDeclaration := .mk "changing" [] params boolT
    (.ifE (op .stringAtEnd [v "text",n 0]) (.literal (.bool true))
      (.call (v "changing") [] [op .stringAppend [v "text",.literal (.string "x")]]))
  if (psTsEmitViewTailLoopWithVisibility true [] [] changing).isSome then
    throw (IO.userError "changing string parameter must use legacy fallback")
  let collision := { changing with name := "__ps$view$0" }
  if (psTsEmitViewTailLoopWithVisibility true [] [] collision).isSome then
    throw (IO.userError "internal name collision")
  let views := [("left0","__ps$view$0"),("left","__ps$view$0")]
  if (psTsLookup (psTsViewAlias views "left" (.literal (.string "other"))) "left").isSome then
    throw (IO.userError "shadowed alias retained")
  if psTsViewInvariant views [.mk "left0" strT] [v "left"] != true then
    throw (IO.userError "safe alias refused")
  if psTsViewInvariant views [.mk "left0" strT] [.literal (.string "other")] then
    throw (IO.userError "changed argument admitted")
  IO.FS.createDirAll "dist/ts-utf8-views"
  let probe := "\nexport const probe = {view:__ps$utf8,known:__ps$utf8Known,get:__ps$stringGet,next:__ps$stringNext,size:__ps$stringUtf8Size,extract:__ps$stringExtract,getView:__ps$stringGetView,nextView:__ps$stringNextView,state:()=>[__ps$lastUtf8,__ps$previousUtf8].map(v=>v?({text:v.text,size:v.size,positions:Array.from(v.positions)}):null),clear:()=>{__ps$lastUtf8=undefined;__ps$previousUtf8=undefined;}};\n"
  IO.FS.writeFile "dist/ts-utf8-views/current.ts"
    (psTsJoin "\n" [psTsUtf8RuntimeSupport,current,legacy,probe])
  let extractOnly : PsVerifiedIrDeclaration := .mk "onlyExtract" []
    [.mk "text" strT,.mk "start" natT,.mk "stop" natT] strT
    (op .stringExtract [v "text",v "start",v "stop"])
  let extractModule : PsVerifiedIrModule := .mk [] [] [] [extractOnly]
  if psTsNeedsUtf8Runtime extractOnly.body != true then
    throw (IO.userError "extract-only runtime missing")
  let emitted ← match psTsEmitModule extractModule with
    | Except.ok text => pure text
    | Except.error _ => throw (IO.userError "extract-only emission")
  IO.FS.writeFile "dist/ts-utf8-views/extract-only.ts"
    emitted
  IO.println "PSC1_TS_UTF8_VIEW_GUARDS: invariant alias, changing argument, shadowing, collision pass"

  emitCaptureTests
