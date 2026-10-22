import Ps.CompilerIr.WorkerFusion
import Ps.BackendJs.Print
import Lean.Data.Json

def natT : PsVerifiedIrType := .primitive .nat
def fnT : PsVerifiedIrType := .function [natT] natT
def n (value : Nat) : PsVerifiedIrExpr := .literal (.natural value)
def v (name : String) : PsVerifiedIrExpr := .var name
def call (name : String) (args : List PsVerifiedIrExpr) : PsVerifiedIrExpr := .call (v name) [] args
def app (fn arg : PsVerifiedIrExpr) : PsVerifiedIrExpr := .call fn [] [arg]
def sub (left right : PsVerifiedIrExpr) : PsVerifiedIrExpr := .intrinsic .natSub [] [left,right]
def eq (left right : PsVerifiedIrExpr) : PsVerifiedIrExpr := .intrinsic .natEq [] [left,right]
def add (left right : PsVerifiedIrExpr) : PsVerifiedIrExpr := .intrinsic .natAdd [] [left,right]
def param (name : String) : PsVerifiedIrParameter := .mk name natT
def lam (name : String) (body : PsVerifiedIrExpr) : PsVerifiedIrExpr := .lambda [param name] natT body

def worker : PsVerifiedIrDeclaration :=
  .mk "scan" [] [param "fuel"] fnT
    (.ifE (eq (v "fuel") (n 0)) (lam "state" (v "state"))
      (.letE "remaining" natT (sub (v "fuel") (n 1))
        (lam "state" (.letE "smaller" fnT (call "scan" [v "remaining"])
          (.ifE (eq (v "state") (n 0)) (v "state") (app (v "smaller") (sub (v "state") (n 1))))))))

def arithmeticWorker : PsVerifiedIrDeclaration :=
  .mk "arithmeticScan" [] [param "fuel"] fnT
    (.ifE (eq (v "fuel") (n 0)) (lam "state" (v "state"))
      (.letE "remaining" natT (sub (v "fuel") (add (n 0) (n 1)))
        (lam "state" (app (call "arithmeticScan" [v "remaining"]) (add (v "state") (n 1))))))

-- Erasure can eta-contract the base branch to its evaluated continuation.
-- Cover both curried layers so a flat overapplication cannot pass this test.
def continuationT : PsVerifiedIrType := .function [natT] fnT
def continuationWorker : PsVerifiedIrDeclaration :=
  .mk "continuationScan" [] [.mk "done" continuationT, param "fuel"] continuationT
    (.ifE (eq (v "fuel") (n 0)) (v "done")
      (.letE "remaining" natT (sub (v "fuel") (n 1))
        (.lambda [param "state"] fnT
          (lam "sentinel" (app (app (call "continuationScan" [v "done",v "remaining"])
            (add (v "state") (n 1))) (v "sentinel"))))))

def evaluatedWorker : PsVerifiedIrDeclaration :=
  .mk "evaluatedScan" [] [.mk "done" fnT, param "fuel"] fnT
    (.ifE (eq (v "fuel") (n 0)) (v "done")
      (.letE "remaining" natT (sub (v "fuel") (n 1))
        (lam "state" (app (call "evaluatedScan" [v "done",v "remaining"])
          (add (v "state") (n 1))))))

def captureBox : PsVerifiedIrInductive :=
  .mk "CaptureBox" [] [.mk "box" [.mk "value" natT]]

def module : PsVerifiedIrModule := .mk [] [] [captureBox] [
    .mk "stableAlias" [] [param "fuel",param "state"] natT
      (.letE "saved" fnT (call "scan" [v "fuel"]) (app (v "saved") (v "state"))),
    .mk "literalAlias" [] [param "state"] natT
      (.letE "saved" fnT (call "scan" [n 5]) (app (v "saved") (v "state"))),
    .mk "captureSelf" [] [param "fuel"] natT
      (.letE "fuel" fnT (call "scan" [v "fuel"]) (app (v "fuel") (n 2))),
    .mk "captureLambda" [] [param "fuel"] natT
      (.letE "saved" fnT (call "scan" [v "fuel"])
        (app (lam "fuel" (app (v "saved") (n 2))) (n 0))),
    .mk "captureMatch" [] [param "fuel"] natT
      (.letE "saved" fnT (call "scan" [v "fuel"])
        (.matchE "CaptureBox" [] (.constructor "CaptureBox" "box" [] [("value",n 0)])
          [("box", [.mk "value" "fuel" natT], app (v "saved") (n 2))])),

    worker,
    arithmeticWorker,
    continuationWorker,
    evaluatedWorker,
    .mk "evaluatedEntry" [] [param "fuel",param "state"] natT
      (app (call "evaluatedScan" [lam "x" (v "x"),v "fuel"]) (v "state")),
    .mk "continuationEntry" [] [param "fuel",param "state",param "sentinel"] natT
      (app (app (call "continuationScan" [
        .lambda [param "x"] fnT (lam "y" (add (v "x") (v "y"))), v "fuel"])
        (v "state")) (v "sentinel")),
    .mk "arithmeticEntry" [] [param "fuel",param "state"] natT
      (app (call "arithmeticScan" [v "fuel"]) (v "state")),
    .mk "scan$worker" [] [] natT (n 13),
    .mk "entry" [] [param "fuel",param "state"] natT
      (app (call "scan" [v "fuel"]) (v "state")),
    .mk "hold" [] [param "fuel"] fnT (call "scan" [v "fuel"]),
    .mk "escaped" [] [param "fuel",param "state"] natT
      (app (call "hold" [v "fuel"]) (v "state")),
    .mk "capture" [] [param "fuel"] natT
      (.letE "saved" fnT (call "scan" [v "fuel"])
        (.letE "fuel" natT (n 0) (app (v "saved") (n 2)))),
    .mk "shadow" [] [param "value"] natT
      (.letE "scan" (.function [natT] fnT)
        (.lambda [param "a"] fnT (lam "b" (add (v "a") (v "b"))))
        (app (app (v "scan") (v "value")) (n 7))),
    .mk "ordered" [] [.mk "left" fnT,.mk "right" fnT] natT
      (app (call "scan" [call "left" [n 2]]) (call "right" [n 5]))
  ]

def strictModule : PsVerifiedIrModule := .mk [] [] [] [
  continuationWorker,
  .mk "curriedProbe" [] [.mk "first" continuationT,.mk "later" fnT] natT
    (app (app (call "continuationScan" [v "first",n 0]) (n 0)) (call "later" [n 0])),

  .mk "spin" [] [param "n"] natT (call "spin" [v "n"]),
  .mk "unsafe" [] [param "n"] fnT
    (.letE "computed" natT (call "spin" [v "n"]) (lam "x" (v "computed"))),
  .mk "strict" [] [param "unused"] natT
    (.letE "ignored" fnT (call "unsafe" [n 0]) (n 1))
]

def require (label : String) (condition : Bool) : IO Unit := do
  unless condition do throw (IO.userError ("PSC1_WORKER_FUSION_FAIL: " ++ label))
  IO.println ("PSC1_WORKER_FUSION_PASS: " ++ label)

def validate (raw : PsVerifiedIrModule) : IO PsValidatedIrModule := do
  match psStrictValidateModule raw with
  | .error _ =>
      let report := psCheckVerifiedIrModule psIrCheckDefaultOptions raw
      for finding in report.findings do
        IO.println ("PSC1_WORKER_INPUT_FINDING: " ++ finding.code ++ " owner=" ++ finding.owner ++
          " path=" ++ finding.path ++ " detail=" ++ finding.detail)
      throw (IO.userError "test input strict validation refused")
  | .ok value => pure value

def emit (raw : PsValidatedIrModule) (file : String) (publicNames : List String) : IO Unit := do
  let lowered <- match psJsLowerValidatedModuleWithTargetProfile (.mk .bits64) raw with
    | .error _ => throw (IO.userError "worker test lowering refused")
    | .ok value => pure value
  match psJsValidateModule lowered with
  | .error _ => throw (IO.userError "worker test JsIR validation refused")
  | .ok _ => pure ()
  let declarations <- match psJsPrintDeclarationsWith
      (fun declaration => psJsPrintDeclarationStackSafeWithVisibility
        (publicNames.contains declaration.name) declaration) lowered.declarations psTextBuilderEmpty with
    | .error _ => throw (IO.userError "worker test printing refused")
    | .ok value => pure value
  let harness :=
    if publicNames.contains "entry" then
      "import {seen as __testMarks} from './probe.mjs';\n" ++
      "export function orderedWitness(){return ordered(n=>{__testMarks.push(String(n));return n;},n=>{__testMarks.push(String(n));return n;});}\n"
    else ""
  IO.FS.writeFile file (psJsPrintStackSafePrelude lowered ++ declarations ++ harness)

def main : IO Unit := do
  IO.FS.createDirAll "dist/worker-fusion"
  let input <- validate module
  let fused <- match psFuseClosedWorkers input with
    | .error error => throw (IO.userError error)
    | .ok value => pure value
  require "every original declaration retained" (module.declarations.all
    (fun original => fused.raw.declarations.any (fun value => value.name == original.name)))
  require "fresh companion avoids existing global"
    (fused.raw.declarations.any (fun value => value.name == "scan$worker_" && value.parameters.length == 2))
  require "total Nat arithmetic prefix obtains a checked companion"
    (fused.raw.declarations.any (fun value => value.name == "arithmeticScan$worker" && value.parameters.length == 2))
  require "unknown curried continuation retains intermediate application order"
    (!fused.raw.declarations.any (fun value => value.name == "continuationScan$worker"))
  require "evaluated single-layer continuation obtains a checked companion"
    (fused.raw.declarations.any (fun value => value.name == "evaluatedScan$worker" && value.parameters.length == 3))
  require "stable variable alias needs no administrative capture"
    (match fused.raw.declarations.find? (fun declaration => declaration.name == "stableAlias") with
     | some declaration =>
         match declaration.body with
         | .call (.var name) [] [.var "fuel", .var "state"] => name == "scan$worker_"
         | _ => false
     | none => false)
  require "literal alias needs no administrative capture"
    (match fused.raw.declarations.find? (fun declaration => declaration.name == "literalAlias") with
     | some declaration =>
         match declaration.body with
         | .call (.var name) [] [.literal (.natural 5), .var "state"] => name == "scan$worker_"
         | _ => false
     | none => false)
  require "exhausted binder scan cannot certify stability"
    (!Ps.Internal.WorkerFusion.stableCapture "saved" (n 0) (.call (v "scan") [] []) &&
      Ps.Internal.WorkerFusion.bindsName 0 "fuel" (n 0))
  require "escaped call-only function stays available"
    (fused.raw.declarations.any (fun value => value.name == "hold"))
  let invalid := PsVerifiedIrModule.mk [] [] [] [
    .mk "bad" [] [] natT (.literal (.bool true))]
  let imported := PsVerifiedIrModule.mk
    [.mk "mark" "./probe.mjs" "mark" (.function [natT] natT)]
    module.structures module.inductives module.declarations
  require "unqualified external imports still refuse"
    (match psFuseClosedWorkers (.mk imported) with | .error _ => true | _ => false)
  require "forged validated wrapper refuses"
    (match psFuseClosedWorkers (.mk invalid) with | .error _ => true | _ => false)
  let strictInput <- validate strictModule
  let strictFused <- match psFuseClosedWorkers strictInput with
    | .error error => throw (IO.userError error)
    | .ok value => pure value
  require "effectful/divergent prefix is never delayed"
    (!strictFused.raw.declarations.any (fun value => value.name == "unsafe$worker"))
  emit input "dist/worker-fusion/baseline.mjs" ["entry","escaped","capture","shadow","arithmeticEntry","continuationEntry","evaluatedEntry","stableAlias","literalAlias","captureSelf","captureLambda","captureMatch"]
  emit fused "dist/worker-fusion/fused.mjs" ["entry","escaped","capture","shadow","ordered","arithmeticEntry","continuationEntry","evaluatedEntry","stableAlias","literalAlias","captureSelf","captureLambda","captureMatch"]
  emit strictInput "dist/worker-fusion/strict-baseline.mjs" ["strict","curriedProbe"]
  emit strictFused "dist/worker-fusion/strict-fused.mjs" ["strict","curriedProbe"]
  IO.FS.writeFile "dist/worker-fusion/probe.mjs"
    "export const seen=[];export function mark(n){seen.push(String(n));return n;}\n"
  IO.println "PSC1_WORKER_FUSION_FIXTURES: typed source and transformed modules emitted"
