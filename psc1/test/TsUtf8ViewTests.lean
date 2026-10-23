import Ps.BackendTs.Module

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
    (String.Internal.append (psTsSelectedRuntimeSource extractModule) emitted)
  IO.println "PSC1_TS_UTF8_VIEW_GUARDS: invariant alias, changing argument, shadowing, collision pass"
