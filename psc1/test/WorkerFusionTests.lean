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

def module : PsVerifiedIrModule := .mk [] [] [] [
    worker,
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
  require "escaped call-only function stays available"
    (fused.raw.declarations.any (fun value => value.name == "hold"))
  let invalid := PsVerifiedIrModule.mk [] [] [] [
    .mk "bad" [] [] natT (.literal (.bool true))]
  let imported := PsVerifiedIrModule.mk
    [.mk "mark" "./probe.mjs" "mark" (.function [natT] natT)] [] [] module.declarations
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
  emit input "dist/worker-fusion/baseline.mjs" ["entry","escaped","capture","shadow"]
  emit fused "dist/worker-fusion/fused.mjs" ["entry","escaped","capture","shadow","ordered"]
  emit strictInput "dist/worker-fusion/strict-baseline.mjs" ["strict"]
  emit strictFused "dist/worker-fusion/strict-fused.mjs" ["strict"]
  IO.FS.writeFile "dist/worker-fusion/probe.mjs"
    "export const seen=[];export function mark(n){seen.push(String(n));return n;}\n"
  IO.println "PSC1_WORKER_FUSION_FIXTURES: typed source and transformed modules emitted"
