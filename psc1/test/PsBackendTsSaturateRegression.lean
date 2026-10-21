import Ps.BackendTs.Saturate
import Ps.Host.TypeScriptCompiler
import PsBackendTsSaturateFixture

namespace PsBackendTsSaturateRegression

private def require (label : String) (condition : Bool) : IO Unit := do
  unless condition do throw (IO.userError ("PSC1_SATURATION_NATIVE: " ++ label))

private def expect {α ε : Type} (label : String) (value : Except ε α) : IO α := do
  match value with
  | .ok result => pure result
  | .error _ => throw (IO.userError ("PSC1_SATURATION_NATIVE: " ++ label))

private def someValue {α : Type} (label : String) (value : Option α) : IO α := do
  match value with
  | .some result => pure result
  | .none => throw (IO.userError ("PSC1_SATURATION_NATIVE: " ++ label))

private def nat : PsVerifiedIrType := .primitive .nat
private def bool : PsVerifiedIrType := .primitive .bool
private def fn : PsVerifiedIrType := .function [nat] nat
private def fn2 : PsVerifiedIrType := .function [nat] fn
private def p (name : String) (type : PsVerifiedIrType := nat) : PsVerifiedIrParameter :=
  .mk name type
private def n (value : Nat) : PsVerifiedIrExpr := .literal (.natural value)
private def v (name : String) : PsVerifiedIrExpr := .var name
private def op (name : PsVerifiedIrIntrinsic) (arguments : List PsVerifiedIrExpr) :
    PsVerifiedIrExpr := .intrinsic name [] arguments
private def call (name : String) (arguments : List PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  .call (v name) [] arguments
private def applyStage (target argument : PsVerifiedIrExpr) : PsVerifiedIrExpr :=
  .call target [] [argument]
private def zeroTest := op .natEq [v "fuel",n 0]
private def predecessor := op .natSub [v "fuel",n 1]

private def stage : PsVerifiedIrDeclaration :=
  .mk "stage" [] [p "fuel"] fn
    (.ifE zeroTest
      (.lambda [p "state"] nat (v "state"))
      (.lambda [p "state"] nat
        (applyStage (call "stage" [predecessor]) (op .natAdd [v "state",n 1]))))

private def stageTwo : PsVerifiedIrDeclaration :=
  let inner := fun (last : PsVerifiedIrExpr) =>
    PsVerifiedIrExpr.lambda [p "first"] fn
      (.letE "captured" nat (op .natAdd [v "base",v "first"])
        (.lambda [p "second"] nat last))
  .mk "stageTwo" [] [p "fuel",p "base"] fn2
    (.ifE zeroTest
      (inner (op .natAdd [v "captured",v "second"]))
      (inner (applyStage (applyStage (call "stageTwo" [predecessor,v "base"])
        (v "captured")) (op .natAdd [v "second",n 1]))))

private def effectBefore : PsVerifiedIrDeclaration :=
  .mk "effectBefore" [] [p "fuel",p "effect" fn] fn
    (.letE "seen" nat (call "effect" [v "fuel"])
      (.ifE zeroTest
        (.lambda [p "state"] nat (op .natAdd [v "seen",v "state"]))
        (.lambda [p "state"] nat
          (applyStage (call "effectBefore" [predecessor,v "effect"])
            (op .natAdd [v "state",v "seen"])))))

private def effectBetween : PsVerifiedIrDeclaration :=
  let inner := fun (last : PsVerifiedIrExpr) =>
    PsVerifiedIrExpr.lambda [p "first"] fn
      (.letE "seen" nat (call "effect" [v "first"])
        (.lambda [p "second"] nat last))
  .mk "effectBetween" [] [p "fuel",p "effect" fn] fn2
    (.ifE zeroTest
      (inner (op .natAdd [v "seen",v "second"]))
      (inner (applyStage (applyStage (call "effectBetween" [predecessor,v "effect"])
        (v "seen")) (v "second"))))

private def effectArgument : PsVerifiedIrDeclaration :=
  .mk "effectArgument" [] [p "fuel",p "effect" fn,p "state"] nat
    (applyStage (call "stage" [v "fuel"]) (call "effect" [v "state"]))

private def fixedOrder : PsVerifiedIrDeclaration :=
  .mk "fixedOrder" [] [p "effect" fn,p "fuel",p "first",p "second"] nat
    (applyStage (applyStage
      (call "stageTwo" [call "effect" [v "fuel"],call "effect" [v "first"]])
      (v "first")) (v "second"))

private def shadowLambda : PsVerifiedIrDeclaration :=
  .mk "shadowLambda" [] [p "stage" fn2,p "fuel",p "state"] nat
    (applyStage (call "stage" [v "fuel"]) (v "state"))

private def shadowLet : PsVerifiedIrDeclaration :=
  .mk "shadowLet" [] [p "replacement" fn2,p "fuel",p "state"] nat
    (.letE "stage" fn2 (v "replacement")
      (applyStage (call "stage" [v "fuel"]) (v "state")))

private def reserved : PsVerifiedIrDeclaration :=
  .mk "__ps$stage$0" [] [p "value"] nat (v "value")

private def partialStageDeclaration : PsVerifiedIrDeclaration :=
  .mk "partialStage" [] [p "fuel"] fn (call "stage" [v "fuel"])

private def saturated : PsVerifiedIrDeclaration :=
  .mk "saturated" [] [p "fuel",p "state"] nat
    (applyStage (call "stage" [v "fuel"]) (v "state"))

private def pureDiv : PsVerifiedIrDeclaration :=
  .mk "pureDiv" [] [p "fuel",p "value"] nat
    (applyStage (call "stage" [v "fuel"])
      (op .natAdd [op .natDiv [v "value",n 0],op .natMod [v "value",n 0]]))

private def helperShadow : PsVerifiedIrDeclaration :=
  .mk "helperShadow" [] [p "__ps$stage$1" fn2,p "fuel",p "state"] nat
    (applyStage (call "stage" [v "fuel"]) (v "state"))

def model : PsVerifiedIrModule :=
  .mk [] [] []
    [reserved,stage,stageTwo,effectBefore,effectBetween,effectArgument,fixedOrder,
     shadowLambda,shadowLet,partialStageDeclaration,saturated,pureDiv,helperShadow]

private def singletonMap (candidate : PsTsSatCandidate) : PsErasureNameIndex PsTsSatCandidate :=
  psTsSatInsertCandidate PsErasureNameIndex.empty candidate

private def sameExpr (left right : PsVerifiedIrExpr) : Bool :=
  match psTsEmitExpr [] [] left,psTsEmitExpr [] [] right with
  | .ok first,.ok second => first == second
  | _,_ => false

private def requireUnchanged (label : String) (candidates : PsErasureNameIndex PsTsSatCandidate)
    (locals : List String) (expr : PsVerifiedIrExpr) : IO Unit := do
  let result ← someValue label (psTsSatRewrite 4096 candidates locals expr)
  require (label ++ "-no-rewrite") (result.calls == 0 && sameExpr result.expr expr)

private def recognition : IO Unit := do
  let candidate ← someValue "eligible-stage"
    (psTsSatMakeCandidate ["__ps$stage$0"] stage 0)
  require "fresh-global-name" (candidate.candidate.helper.name == "__ps$stage$1")
  require "self-call-recognized" (psTsSatSelfEligible candidate.candidate)
  let candidates := singletonMap candidate.candidate
  let complete := applyStage (call "stage" [n 5]) (n 7)
  let rewritten ← someValue "complete" (psTsSatRewrite 4096 candidates [] complete)
  require "complete-rewrite" (rewritten.calls == 1)
  require "exact-flat-call"
    (match rewritten.expr with
     | .call (.var name) [] [(.literal (.natural 5)),(.literal (.natural 7))] =>
         name == candidate.candidate.helper.name
     | _ => false)
  requireUnchanged "partial-call" candidates [] (call "stage" [n 5])
  requireUnchanged "effectful-extra-argument" candidates []
    (applyStage (call "stage" [n 5]) (call "effect" [n 7]))
  requireUnchanged "lambda-shadow" candidates []
    (.lambda [p "stage" fn2] nat complete)
  requireUnchanged "let-shadow" candidates ["replacement"]
    (.letE "stage" fn2 (v "replacement") complete)
  requireUnchanged "helper-shadow" candidates [candidate.candidate.helper.name] complete
  requireUnchanged "computed-callee" candidates []
    (applyStage (.call (.ifE (.literal (.bool true)) (v "stage") (v "stage")) [] [n 5]) (n 7))
  requireUnchanged "polymorphic-call" candidates []
    (applyStage (.call (v "stage") [nat] [n 5]) (n 7))
  requireUnchanged "wrong-entry-arity" candidates []
    (applyStage (call "stage" []) (n 7))
  let matched := PsVerifiedIrExpr.matchE "Box" [] (v "box")
    [("box",([PsVerifiedIrMatchBinding.mk "callback" "stage" fn2],complete))]
  let result ← someValue "match-scope" (psTsSatRewrite 4096 candidates ["box"] matched)
  require "match-binder-shadow" (result.calls == 0)
  let freshProbe := { stage with body := .letE "__ps$stageArg$2" nat (n 9) stage.body }
  let fresh ← someValue "fresh-capture" (psTsSatMakeCandidate ["__ps$stage$0"] freshProbe 0)
  require "fresh-argument-avoids-inner-binder"
    (fresh.candidate.helper.parameters.all (fun parameter =>
      parameter.name != "__ps$stageArg$2"))
  require "effect-before-first-stage-declines"
    (psTsSatMakeCandidate [] effectBefore 0).isNone
  require "effect-between-stages-declines"
    (psTsSatMakeCandidate [] effectBetween 0).isNone
  let generic := { stage with typeParameters := [PsVerifiedIrTypeParameter.mk "A"] }
  require "generic-candidate-declines" (psTsSatMakeCandidate [] generic 0).isNone
  require "three-stages-decline"
    (psTsSatResultShape (.function [nat] fn2)).isNone
  require "multiargument-return-declines"
    (psTsSatResultShape (.function [nat,nat] nat)).isNone
  require "fuel-zero-rewrite-declines" (psTsSatRewrite 0 candidates [] complete).isNone
  require "fuel-zero-fresh-declines" (psTsSatFresh 0 [] stage "new" 0).isNone
  require "fuel-zero-applyStage-declines"
    (psTsSatApplyOne 0 (p "new") nat (.lambda [p "x"] nat (v "x"))).isNone
  require "purity-zero-declines" (!(psTsSatPureWithFuel 0 (n 0)))
  require "array-primitive-declines"
    (!(psTsSatPureWithFuel 4096 (.intrinsic .arrayGetD [nat] [v "a",n 0,n 0])))
  require "arbitrary-call-declines" (!(psTsSatPureWithFuel 4096 (call "f" [n 0])))
  require "total-zero-div-mod-qualified"
    (psTsSatPureWithFuel 4096 (op .natAdd [op .natDiv [n 1,n 0],op .natMod [n 1,n 0]]))
  let partialSelf := { stage with
    body := .ifE zeroTest (.lambda [p "state"] nat (v "state"))
      (.lambda [p "state"] nat
        (.letE "escape" fn (call "stage" [predecessor])
          (applyStage (call "stage" [predecessor]) (v "state")))) }
  let partialCandidate ← someValue "partial-self-shaped"
    (psTsSatMakeCandidate [] partialSelf 0)
  require "partial-self-reference-declines" (!(psTsSatSelfEligible partialCandidate.candidate))
  IO.println "PSC1_SATURATION_RECOGNITION: PASS staging=2 shadows=4 purity=bounded partialSelf=refused"

private def checking : IO Unit := do
  let baseline ← expect "original-emission" (psTsEmitCheckedModule psIrCheckDefaultOptions model)
  let optimized ← expect "checked-saturation" (psTsEmitSaturatedCheckedModule psIrCheckDefaultOptions model)
  require "original-runtime-IR-checked" (optimized.originalReport.accepted &&
    optimized.originalReport.traversalComplete)
  require "two-private-helpers" (optimized.optimized && optimized.helperCount == 2 &&
    optimized.rewrittenCalls > 0)
  require "candidate-runtime-IR-checked"
    (match optimized.candidateReport with
     | some report => report.accepted && report.traversalComplete | none => false)
  require "candidate-target-checked"
    (match optimized.candidateTarget with
     | some report => report.accepted && report.traversalComplete | none => false)
  require "different-executable-source" (baseline != optimized.typeScript)
  require "private-helper-not-exported"
    (!(optimized.typeScript.contains "export function __ps$stage$1(") &&
     optimized.typeScript.contains "const __ps$stage$1 = __ps$wrap(")
  let plan ← someValue "plan" (psTsSatBuildPlan model)
  let originals := plan.module.declarations.filter
    (fun declaration => !(plan.privateNames.contains declaration.name))
  require "original-order-and-signatures"
    (originals.length == model.declarations.length &&
      (originals.zip model.declarations).all (fun (left,right) =>
        left.name == right.name &&
        psTsSatTypeEqual left.resultType right.resultType &&
        left.parameters.length == right.parameters.length &&
        (left.parameters.zip right.parameters).all (fun (first,second) =>
          first.name == second.name && psTsSatTypeEqual first.type second.type)))
  let noPlan := PsVerifiedIrModule.mk [] [] [] [reserved]
  let noPlanOriginal ← expect "no-plan-original" (psTsEmitCheckedModule psIrCheckDefaultOptions noPlan)
  let noPlanResult ← expect "no-plan" (psTsEmitSaturatedCheckedModule psIrCheckDefaultOptions noPlan)
  require "no-plan-exact-original" (!noPlanResult.optimized &&
    noPlanResult.typeScript == noPlanOriginal && noPlanResult.reason == "no-eligible-plan")
  let badTarget := PsVerifiedIrModule.mk [] [] []
    [PsVerifiedIrDeclaration.mk "bad-name" [] [p "value"] nat (v "value")]
  let badTargetOriginal ← expect "bad-target-original"
    (psTsEmitCheckedModule psIrCheckDefaultOptions badTarget)
  let badTargetResult ← expect "bad-target-fallback"
    (psTsEmitSaturatedCheckedModule psIrCheckDefaultOptions badTarget)
  require "original-target-refusal-emits-only-original" (!badTargetResult.optimized &&
    badTargetResult.typeScript == badTargetOriginal &&
    badTargetResult.reason.startsWith "original-target:")
  let collision := PsVerifiedIrDeclaration.mk "__ps$impl$__ps$stage$1"
    [] [p "value"] nat (v "value")
  let collisionModule := { model with declarations := collision :: model.declarations }
  let collisionOriginal ← expect "target-collision-original"
    (psTsEmitCheckedModule psIrCheckDefaultOptions collisionModule)
  let collisionResult ← expect "target-collision-fallback"
    (psTsEmitSaturatedCheckedModule psIrCheckDefaultOptions collisionModule)
  require "candidate-target-refusal-emits-only-original" (!collisionResult.optimized &&
    collisionResult.typeScript == collisionOriginal &&
    collisionResult.reason.startsWith "candidate-target:")
  let bad := PsVerifiedIrModule.mk [] [] []
    [PsVerifiedIrDeclaration.mk "bad" [] [] nat (.literal (.bool true))]
  require "invalid-original-is-never-emitted"
    (match psTsEmitSaturatedCheckedModule psIrCheckDefaultOptions bad with
     | .error (.check report) => !report.accepted | _ => false)
  let over := PsVerifiedIrModule.mk [] [] []
    [stage,PsVerifiedIrDeclaration.mk "over" [] [] nat
      (applyStage (applyStage (call "stage" [n 1]) (n 2)) (n 3))]
  require "overapplication-is-original-check-error"
    (match psTsEmitSaturatedCheckedModule psIrCheckDefaultOptions over with
     | .error (.check report) => !report.accepted | _ => false)
  let zeroOptions := { psIrCheckDefaultOptions with maxSteps := 0 }
  require "original-check-budget-is-not-acceptance"
    (match psTsEmitSaturatedCheckedModule zeroOptions model with
     | .error (.check report) => !report.accepted && !report.traversalComplete | _ => false)
  IO.println "PSC1_SATURATION_CHECKED: PASS original+candidate=checked helpers=2 ABI=unchanged refusal=original"

private def sameIndex : SatIndex → SatIndex → Bool
  | .empty,.empty => true
  | .bucket left,.bucket right => left == right
  | .branch left right,.branch otherLeft otherRight =>
      sameIndex left otherLeft && sameIndex right otherRight
  | _,_ => false

private def referenceLookup (levels : Nat) (index : SatIndex) (hash : Nat) : List Nat :=
  match levels,index with
  | 0,.bucket values => values
  | Nat.succ remaining,.branch left right =>
      referenceLookup remaining (if hash % 2 == 0 then left else right) (hash / 2)
  | _,_ => []

private def referenceSet (levels : Nat) (index : SatIndex) (hash : Nat)
    (entries : List Nat) : SatIndex :=
  match levels with
  | 0 => .bucket entries
  | Nat.succ remaining =>
      let (left,right) := match index with
        | .branch left right => (left,right) | _ => (.empty,.empty)
      if hash % 2 == 0 then .branch (referenceSet remaining left (hash/2) entries) right
      else .branch left (referenceSet remaining right (hash/2) entries)

private def nativeFixture : IO Unit := do
  let malformed := [SatIndex.empty,.bucket [9,9],
    .branch (.bucket [4]) .empty,.branch .empty (.branch (.bucket [3]) (.bucket [5]))]
  let hashes := [0,1,2,17,18446744073709551629,1180591620717411303455]
  let mut count := 0
  for levels in [0,1,2,8,16] do
    for initial in malformed do
      for hash in hashes do
        require "native-raw-lookup" (satLookupWorker levels initial hash ==
          referenceLookup levels initial hash)
        let values := [hash,levels,hash]
        let updated := satSetWorker levels initial hash values
        require "native-setter" (sameIndex updated (referenceSet levels initial hash values))
        require "native-read-after-write" (satLookup levels updated hash == values)
        require "native-public-setter" (sameIndex (satSet levels initial hash values) updated)
        require "native-lookup-collision-bucket"
          (satLookupWorker levels updated (hash + 2^levels) == values)
        count := count + 1
  for fuel in [0,1,2,16,128,4096] do
    for state in [0,1,18446744073709551629] do
      require "native-stage" (satStage fuel state == fuel + state)
      require "native-capture" (satCaptured fuel 11 state == fuel + 11 + state)
      require "native-zero-division" (satZeroDiv fuel state == fuel + state)
      require "native-effect-argument" (satApplyEffect fuel (fun n => n+3) state == fuel+state+3)
  require "native-effect-before-stage" (satEffectful 4 (fun n => n+1) 7 == 22)
  require "native-effect-between-stages" (satBetweenStages 3 (fun n => n+2) 5 7 == 20)
  require "native-local-shadow" (satShadow (fun x => fun y => x*10+y) 3 8 == 38)
  require "native-fixed-argument-order-value"
    (satFixedOrder (fun n => n+1) (fun n => n+2) 3 5 7 == 18)
  require "native-matrix-count" (count == 120)
  IO.println "PSC1_SATURATION_NATIVE_FIXTURE: PASS radix=120 fuel=0,1,2,16,128,4096 largeNat=above2^70"

def run (arguments : List String) : IO Unit := do
  recognition
  checking
  nativeFixture
  match arguments with
  | [] => pure ()
  | [directory] =>
      let baseline ← expect "baseline-model" (psTsEmitCheckedModule psIrCheckDefaultOptions model)
      let candidate ← expect "candidate-model" (psTsEmitSaturatedCheckedModule psIrCheckDefaultOptions model)
      let original ← psWriteAndCompileTypeScript baseline (directory ++ "/model-original.ts")
      let optimized ← psWriteAndCompileTypeScript candidate.typeScript (directory ++ "/model-optimized.ts")
      require "model-declaration-identical"
        ((← IO.FS.readFile original.declarationPath) == (← IO.FS.readFile optimized.declarationPath))
      IO.println "PSC1_SATURATION_MODEL_BUILD: PASS TypeScript=7.0.2 declarations=identical maps=present"
  | _ => throw (IO.userError "usage: psc1_backend_ts_saturate_tests [output-directory]")
  IO.println "PSC1_SATURATION_NATIVE: PASS"

end PsBackendTsSaturateRegression

def main (arguments : List String) : IO Unit :=
  PsBackendTsSaturateRegression.run arguments
