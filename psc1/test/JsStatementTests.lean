import Ps.BackendJs.Print
import JsStatementReference

private def nat : PsVerifiedIrType := .primitive .nat
private def boolean : PsVerifiedIrType := .primitive .bool
private def callback : PsVerifiedIrType := .function [nat] nat
private def number (n : Nat) : PsVerifiedIrExpr := .literal (.natural n)
private def varExpr (name : String) : PsVerifiedIrExpr := .var name
private def invoke (name : String) (args : List PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  .call (.var name) [] args
private def add (a b : PsVerifiedIrExpr) : PsVerifiedIrExpr := .intrinsic .natAdd [] [a,b]
private def previous : PsVerifiedIrExpr := .intrinsic .natSub [] [varExpr "n",number 1]
private def zero : PsVerifiedIrExpr := .intrinsic .natEq [] [varExpr "n",number 0]
private def single (name : String) (body : PsVerifiedIrExpr) : PsVerifiedIrDeclaration :=
  .mk name [] [.mk "n" nat] nat body
private def alias (name : String) : PsVerifiedIrExpr :=
  .lambda [.mk "x" nat] nat (invoke name [varExpr "x"])

private def captureBody (name : String) (changeFunction : Bool) : PsVerifiedIrExpr :=
  .ifE zero (.call (varExpr "fn") [] [number 0])
    (.letE "next" callback
      (.lambda [.mk "x" nat] nat
        (if changeFunction then add (.call (varExpr "fn") [] [varExpr "x"]) (number 1)
         else add (varExpr "n") (varExpr "x")))
      (invoke name [previous,varExpr "next"]))

private def matchBody : PsVerifiedIrExpr :=
  .matchE "Maybe" [] (invoke "makeMaybe" [varExpr "n"]) [
    ("Maybe.none",[],number 0),
    ("Maybe.some",[.mk "value" "element" nat],
      .letE "answer" nat (invoke "identity" [varExpr "element"])
        (add (varExpr "answer") (number 3)))]

private def stringType : PsVerifiedIrType := .primitive .string
private def intrinsic (op : PsVerifiedIrIntrinsic) (args : List PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  .intrinsic op [] args

private def viewEqualBody : PsVerifiedIrExpr :=
  .ifE zero (.literal (.bool false))
    (.letE "left" stringType (varExpr "left0")
      (.letE "right" stringType (varExpr "right0")
        (.ifE (intrinsic .stringAtEnd [varExpr "left",varExpr "lp"])
          (intrinsic .stringAtEnd [varExpr "right",varExpr "rp"])
          (.ifE (intrinsic .stringAtEnd [varExpr "right",varExpr "rp"]) (.literal (.bool false))
            (.ifE (intrinsic .natEq [
                intrinsic .charToNat [intrinsic .stringGet [varExpr "left",varExpr "lp"]],
                intrinsic .charToNat [intrinsic .stringGet [varExpr "right",varExpr "rp"]]])
              (invoke "viewEqual" [previous,varExpr "left",varExpr "right",
                intrinsic .stringNext [varExpr "left",varExpr "lp"],
                intrinsic .stringNext [varExpr "right",varExpr "rp"]])
              (.literal (.bool false)))))))

private def viewChecksumBody (name : String) (extra : Bool) : PsVerifiedIrExpr :=
  .ifE zero (varExpr "acc")
    (.letE "text" stringType (varExpr "text0")
      (.ifE (intrinsic .stringAtEnd [varExpr "text",varExpr "pos"]) (varExpr "acc")
        (invoke name ([previous,varExpr "text",
          intrinsic .stringNext [varExpr "text",varExpr "pos"],
          add (varExpr "acc") (intrinsic .charToNat [intrinsic .stringGet [varExpr "text",varExpr "pos"]])] ++
          if extra then [varExpr "__ps$viewToken$0"] else []))))

private def viewDeclarations : List PsVerifiedIrDeclaration :=
  let checksumParameters : List PsVerifiedIrParameter :=
    [.mk "n" nat,.mk "text0" stringType,.mk "pos" nat,.mk "acc" nat];
  [
    .mk "viewEqual" [] [.mk "n" nat,.mk "left0" stringType,.mk "right0" stringType,.mk "lp" nat,.mk "rp" nat]
      boolean viewEqualBody,
    .mk "viewChecksum" [] checksumParameters nat (viewChecksumBody "viewChecksum" false),
    .mk "viewFresh" [] (checksumParameters ++ [.mk "__ps$viewToken$0" nat]) nat (viewChecksumBody "viewFresh" true),
    .mk "movingSource" [] [.mk "n" nat,.mk "text0" stringType,.mk "pos" nat] nat
      (.ifE zero (intrinsic .stringUtf8ByteSize [varExpr "text0"])
        (add (intrinsic .charToNat [intrinsic .stringGet [varExpr "text0",varExpr "pos"]])
          (invoke "movingSource" [previous,
            intrinsic .stringAppend [varExpr "text0",.literal (.string "x")],varExpr "pos"]))),
    .mk "shadowSource" [] [.mk "n" nat,.mk "text0" stringType,.mk "pos" nat] nat
      (.ifE zero (number 0)
        (.letE "text0" stringType (intrinsic .stringAppend [varExpr "text0",.literal (.string "x")])
          (add (intrinsic .charToNat [intrinsic .stringGet [varExpr "text0",varExpr "pos"]])
            (invoke "shadowSource" [previous,varExpr "text0",varExpr "pos"])))),
    .mk "viewSizeOnly" [] [.mk "n" nat,.mk "text0" stringType,.mk "acc" nat] nat
      (.ifE zero (varExpr "acc")
        (invoke "viewSizeOnly" [previous,varExpr "text0",
          add (varExpr "acc") (intrinsic .stringUtf8ByteSize [varExpr "text0"])]))
  ]

private def fixture : PsVerifiedIrModule :=
  let declarations : List PsVerifiedIrDeclaration := [
    single "identity" (varExpr "n"),
    single "helperLoop" (.letE "checked" nat (invoke "identity" [varExpr "n"])
      (.ifE (.intrinsic .natEq [] [varExpr "checked",number 0]) (number 0)
        (invoke "helperLoop" [previous]))),
    single "nonTail" (.ifE zero (number 0) (add (invoke "nonTail" [previous]) (number 1))),
    .mk "evenLoop" [] [.mk "n" nat] boolean
      (.ifE zero (.literal (.bool true)) (invoke "oddLoop" [previous])),
    .mk "oddLoop" [] [.mk "n" nat] boolean
      (.ifE zero (.literal (.bool false)) (invoke "evenLoop" [previous])),
    .mk "captureValue" [] [.mk "n" nat,.mk "fn" callback] nat (captureBody "captureValue" false),
    .mk "captureFunction" [] [.mk "n" nat,.mk "fn" callback] nat (captureBody "captureFunction" true),
    single "runCaptureValue" (invoke "captureValue" [varExpr "n",varExpr "identity"]),
    single "runCaptureFunction" (invoke "captureFunction" [varExpr "n",varExpr "identity"]),
    single "shadowHelper" (.letE "n" nat (invoke "identity" [add (varExpr "n") (number 1)])
      (invoke "identity" [varExpr "n"])),
    single "tailAlias" (.letE "forward" callback (alias "tailAlias")
      (.letE "checked" nat (invoke "identity" [varExpr "n"])
        (.ifE (.intrinsic .natEq [] [varExpr "checked",number 0]) (number 0)
          (.call (varExpr "forward") [] [previous])))),
    single "escapingAlias" (.letE "forward" callback (alias "escapingAlias")
      (.ifE zero (number 0)
        (.letE "result" nat (.call (varExpr "forward") [] [previous])
          (add (varExpr "result") (number 1))))),
    .mk "makeMaybe" [] [.mk "n" nat] (.named "Maybe" [])
      (.constructor "Maybe" "Maybe.some" [] [("value",varExpr "n")]),
    single "matchHelper" matchBody,
    .mk "stateCollision" [] [.mk "n" nat,.mk "__ps$tail$state" nat] nat
      (.letE "value" nat (invoke "identity" [varExpr "n"]) (varExpr "value")),
    .mk "letCollision" [] [.mk "n" nat,.mk "__ps$tail$value$4095" nat] nat
      (.letE "value" nat (invoke "identity" [varExpr "n"]) (varExpr "value")),
    .mk "matchCollision" [] [.mk "n" nat,.mk "__ps$tail$match$0" nat] nat matchBody,
    .mk "pureCount" [] [.mk "n" nat,.mk "acc" nat] nat
      (.ifE zero (varExpr "acc") (invoke "pureCount" [previous,add (varExpr "acc") (number 1)]))
  ];
  .mk [] [] [.mk "Maybe" [] [.mk "Maybe.none" [],.mk "Maybe.some" [.mk "value" nat]]] (declarations ++ viewDeclarations)

private def referenceValues (n : Nat) : List Nat :=
  [0,n,if n == 0 then 0 else 1,n,n+1,0,n,n+3,n,n,n+3,n]

def main : IO Unit := do
  let checked <- match psStrictValidateModule fixture with
    | .error _ => throw (IO.userError "statement fixture original strict IR refused")
    | .ok value => pure value
  let lowered <- match psJsLowerValidatedModuleWithTargetProfile (PsJsTargetProfile.mk .bits64) checked with
    | .error _ => throw (IO.userError "statement fixture target lowering refused")
    | .ok value => pure value
  match psJsValidateModule lowered with
  | .error _ => throw (IO.userError "statement fixture target IR refused")
  | .ok _ => pure ()
  for declaration in lowered.declarations do
    if ["stateCollision","letCollision","matchCollision","escapingAlias"].contains declaration.name then
      if (psJsPrintGeneratorTailLoopWithVisibility true declaration).isSome then
        throw (IO.userError ("unsafe/freshness fast path accepted: " ++ declaration.name))
    if ["identity","pureCount"].contains declaration.name then
      match psJsPrintDeclarationStackSafe declaration, JsStatementReference.psJsPrintDeclarationStackSafe declaration with
      | .ok a,.ok b => if a != b then throw (IO.userError "legacy pure output changed")
      | _,_ => throw (IO.userError "pure declaration refused")
  let empty := PsJsIrDeclaration.mk "empty" [] (.call (.var "empty") [])
  if (psJsGeneratorTailEmitWithFuel empty (fun _ => true) 0 0 empty.body).isSome then
    throw (IO.userError "zero fuel fast path accepted")
  if (psJsGeneratorTailEmitWithFuel empty (fun _ => true) 1 0 empty.body).isSome then
    throw (IO.userError "callee zero fuel fast path accepted")
  for declaration in lowered.declarations do
    if ["viewChecksum","viewEqual","viewFresh","movingSource","shadowSource","viewSizeOnly"].contains declaration.name then
      let available := fun name =>
        !(psStringEq declaration.name name) &&
        !(psListAny (fun (p : PsJsIrParameter) => psStringEq p.name name) declaration.parameters) &&
        !(psJsExprUsesNameWithFuel 4096 declaration.body name)
      let fast := psJsViewLoopBody declaration available declaration.body
      let expected := ["viewChecksum","viewEqual"].contains declaration.name
      if fast.isSome != expected then
        throw (IO.userError ("view path wrong acceptance: " ++ declaration.name))
  if (psJsViewInspect "f" "s" 0 0 [("s","getter")] (.var "s")).isSome then
    throw (IO.userError "zero view inspection fuel accepted")
  if (psJsViewRewrite 0 [("s","getter")] (.var "s")).isSome then
    throw (IO.userError "zero view rewrite fuel accepted")
  let current <- match psJsPrintModuleStackSafe lowered with
    | .error _ => throw (IO.userError "current statement emitter refused")
    | .ok value => pure value
  let legacy <- match JsStatementReference.psJsPrintModuleStackSafe lowered with
    | .error _ => throw (IO.userError "retained statement emitter refused")
    | .ok value => pure value
  IO.FS.createDirAll "dist/js-statement-tests"
  IO.FS.writeFile "dist/js-statement-tests/current.mjs" current
  IO.FS.writeFile "dist/js-statement-tests/legacy.mjs" legacy
  let rows := (List.range 65).map fun n =>
    psJsonArray (List.map (fun value => psNatToString value) (referenceValues n))
  IO.FS.writeFile "dist/js-statement-tests/native-values.json" (psJsonArray rows)
  let samples := ["","abc","λ🙂","A\0é𝄞Z","𝄞","equal λ🙂 end","different"]
  let pairs := samples.flatMap fun left => samples.map fun right =>
    psJsonArray [psJsonQuote left,psJsonQuote right,if psStringEq left right then "true" else "false"]
  IO.FS.writeFile "dist/js-statement-tests/native-strings.json" (psJsonArray pairs)
  IO.println "PSC1_JS_STATEMENT_NATIVE: original/target strict IR; immutable value/function captures; shadowing; aliases; helper/mutual/non-tail recursion; fuel/freshness refusals; unchanged pure output"

