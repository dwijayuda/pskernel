import Ps.Host.NativeV7
import PsKernelLean.Admission

-- Independent pinned Lean equations. The native API below constructs and checks
-- its own group; .ps mutual-inductive grammar is intentionally unchanged.
mutual
  inductive M3RuntimeLeft (A : Type) : Type where
    | leaf (value : A)
    | link (n : Nat) (next : M3RuntimeRight A n)
  inductive M3RuntimeRight (A : Type) : Nat → Type where
    | join (n : Nat) (previous : M3RuntimeLeft A) : M3RuntimeRight A n
end

-- Lean's ordinary code generator refuses direct mutual recursor execution.
-- These are kernel-checked logical equations, never executed by test main.
noncomputable def m3RuntimeLeftOracle (A : Type) (seed : Nat) : M3RuntimeLeft A → Nat :=
  @M3RuntimeLeft.rec A (fun _ => Nat) (fun _ _ => Bool)
    (fun _ => seed)
    (fun n _ ih => Nat.add (Nat.add seed n) (if ih then 3 else 11))
    (fun n _ ih => Nat.beq (Nat.add ih n) seed)

noncomputable def m3RuntimeRightOracle (A : Type) (seed : Nat) :
    (n : Nat) → M3RuntimeRight A n → Bool :=
  @M3RuntimeRight.rec A (fun _ => Nat) (fun _ _ => Bool)
    (fun _ => seed)
    (fun n _ ih => Nat.add (Nat.add seed n) (if ih then 3 else 11))
    (fun n _ ih => Nat.beq (Nat.add ih n) seed)

example : m3RuntimeLeftOracle Bool 13
    (.link 0 (.join 0 (.link 0 (.join 0 (.leaf true))))) = 24 := rfl
example : m3RuntimeLeftOracle Bool 7
    (.link 5 (.join 5 (.link 0 (.join 0 (.leaf true))))) = 23 := rfl
example : m3RuntimeRightOracle Bool 13 0 (.join 0 (.leaf true)) = true := rfl
example : m3RuntimeRightOracle Bool 7 5 (.join 5 (.leaf true)) = false := rfl

namespace M3InductiveRuntime

private def ensure (condition : Bool) (message : String) : IO Unit :=
  unless condition do throw (IO.userError message)

private def fromExcept (result : Except String α) : IO α :=
  match result with
  | .ok value => pure value
  | .error error => throw (IO.userError error)

private def elabMessage : PsElabError → String
  | .data message | .scope message => message
  | .unknownName name => "unknown name: " ++ psNameToString name
  | .atDeclaration name error => psNameToString name ++ ": " ++ elabMessage error
  | .typeMismatch => "type mismatch"
  | _ => "group runtime elaboration failed"

private def groupSource : String :=
  "inductive M3RuntimeLeft(A: Type): Type where { | leaf(value: A) | link(n: Nat, next: M3RuntimeRight(A, n)) }\n" ++
  "inductive M3RuntimeRight(B: Type): Nat -> Type where { | join(n: Nat, previous: M3RuntimeLeft(B)): M3RuntimeRight(B, n) }\n"

private def elaborateGroup : Except String PsElabDeclarationBatchResult := do
  let program ← psPscv0ParseProgram groupSource
  let members ← program.commands.mapM fun command =>
    match command with
    | .declaration (.inductiveDecl name params resultType constructors _) =>
      pure { name, params, resultType, constructors : PsElabInductiveSource }
    | _ => throw "group runtime fixture expected an inductive member"
  (psElabInductiveGroup psSelfHostProdPreludeEnvironment members []).mapError elabMessage

private def constant (name : PsName) : PsExpr := .constE name []
private def call (name : PsName) (arguments : List PsExpr) : PsExpr :=
  psExprApplyMany (constant name) arguments
private def number (n : Nat) : PsExpr := .lit (.natural n)
private def nat : PsExpr := constant psNatName
private def boolean : PsExpr := constant psBoolName
private def leftName : PsName := psRootName "M3RuntimeLeft"
private def rightName : PsName := psRootName "M3RuntimeRight"
private def leftType (type : PsExpr) : PsExpr := call leftName [type]
private def rightType (type index : PsExpr) : PsExpr := call rightName [type, index]
private def add (a b : PsExpr) : PsExpr := call psNatAddName [a, b]

private def lambda (id : Nat) (name : String) (type body : PsExpr) : PsExpr :=
  .lam (psRootName name) type (psExprAbstractFVar id body) .explicit

private def definition (name : String) (binders : List (Nat × String × PsExpr))
    (type value : PsExpr) : PsDeclaration :=
  .definitionDecl (psRootName name) []
    (binders.foldr (fun (id, name, domain) body =>
      .forallE (psRootName name) domain (psExprAbstractFVar id body) .explicit) type)
    (binders.foldr (fun (id, name, domain) body => lambda id name domain body) value)

private def boolSelect (condition onFalse onTrue : PsExpr) : PsExpr :=
  psExprApplyMany (.constE (psNameAppendStr psBoolName "rec") [.succ .zero])
    [lambda 300 "flag" boolean nat, onFalse, onTrue, condition]

private def fixedArguments (type seed : PsExpr) : List PsExpr :=
  let n := PsExpr.fvar 301
  let ih := PsExpr.fvar 302
  let leftMotive := lambda 303 "left" (leftType type) nat
  let rightMotive := lambda 301 "n" nat
    (lambda 303 "right" (rightType type n) boolean)
  let leaf := lambda 303 "value" type seed
  let link := lambda 301 "n" nat (lambda 303 "next" (rightType type n)
    (lambda 302 "ih" boolean (add (add seed n) (boolSelect ih (number 11) (number 3)))))
  let join := lambda 301 "n" nat (lambda 303 "previous" (leftType type)
    (lambda 302 "ih" nat (call (psNameAppendStr psNatName "beq") [add ih n, seed])))
  [type, leftMotive, rightMotive, leaf, link, join]

private def foldDeclarations : List PsDeclaration :=
  let type := PsExpr.fvar 0
  let seed := PsExpr.fvar 1
  let index := PsExpr.fvar 2
  let left := PsExpr.fvar 2
  let right := PsExpr.fvar 3
  let parameters := [(0, "A", PsExpr.sortE (.succ .zero)), (1, "seed", nat)]
  [definition "m3foldleft" (parameters ++ [(2, "tree", leftType type)]) nat
    (psExprApplyMany (.constE (psNameAppendStr leftName "rec") [.succ .zero])
      (fixedArguments type seed ++ [left])),
   definition "m3foldright" (parameters ++ [(2, "n", nat), (3, "tree", rightType type index)]) boolean
    (psExprApplyMany (.constE (psNameAppendStr rightName "rec") [.succ .zero])
      (fixedArguments type seed ++ [index, right]))]

private def leaf : PsExpr :=
  call (psNameAppendStr leftName "leaf") [boolean, constant (psNameAppendStr psBoolName "true")]
private def link (index next : PsExpr) : PsExpr :=
  call (psNameAppendStr leftName "link") [boolean, index, next]
private def join (index previous : PsExpr) : PsExpr :=
  call (psNameAppendStr rightName "join") [boolean, index, previous]
private def uint64 : PsExpr := constant (psRootName "UInt64")
private def uint64OfNat (value : PsExpr) : PsExpr :=
  call (psNameAppendStr (psRootName "UInt64") "ofNat") [value]

private def outputs : List PsDeclaration :=
  let flag := PsExpr.fvar 0
  let seed := boolSelect flag (number 13) (number 7)
  let index := boolSelect flag (number 0) (number 5)
  let inner := link (number 0) (join (number 0) leaf)
  let deep := link index (join index inner)
  let left := call (psRootName "m3foldleft") [boolean, seed, deep]
  let right := call (psRootName "m3foldright") [boolean, seed, index, join index leaf]
  [definition "m3groupleft" [(0, "flag", boolean)] uint64 (uint64OfNat left),
   definition "m3groupright" [(0, "flag", boolean)] uint64
     (uint64OfNat (boolSelect right (number 2) (number 9)))]

private def witness (name : String) (flag : Bool) (expected : Nat) : PsDeclaration :=
  let input := constant (psNameAppendStr psBoolName (if flag then "true" else "false"))
  let value := call (psRootName name) [input]
  let expected := uint64OfNat (number expected)
  let proposition := psExprApplyMany (.constE psEqName [.succ .zero]) [uint64, value, expected]
  let proof := psExprApplyMany (.constE (psNameAppendStr psEqName "refl") [.succ .zero])
    [uint64, expected]
  .theoremDecl (psRootName (name ++ (if flag then "TrueEquation" else "FalseEquation")))
    [] proposition proof

private def checked (prelude : Lean.Kernel.Environment) (declarations : List PsDeclaration) :
    IO Lean.Kernel.Environment := do
  let encoded ← fromExcept ((psEncodeCheckedAdmissionsCanonical declarations).mapError
    (fun _ => "canonical group runtime admission refused"))
  let decoded ← fromExcept ((PsKernelLean.decodeCanonicalAdmissions encoded).mapError
    (fun error => error.kind.code ++ ": " ++ error.message))
  let result ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
    PsKernelLean.admitDeclarations prelude decoded
  fromExcept (result.mapError (fun error => error.kind.code ++ ": " ++ error.message))

private def expectRefused (prepared : PsCompilerAdmissionReadyModule) (label : String) : IO Unit :=
  match psCompilerVerifiedIrFromPrepared prepared with
  | .error (.erasure _) => pure ()
  | .error error => throw (IO.userError (label ++ " failed before worker validation: " ++ psCompilerPscv0Error error))
  | .ok _ => throw (IO.userError (label ++ " produced executable IR"))

-- A well-typed change to one minor is accepted by the official kernel but no
-- longer agrees with its retained companions. This must fail before emission.
private def changeMinor : PsExpr → PsExpr
  | .lit (.natural 3) => number 4
  | .app fn arg => .app (changeMinor fn) (changeMinor arg)
  | .lam name type body binder => .lam name (changeMinor type) (changeMinor body) binder
  | .forallE name type body binder => .forallE name (changeMinor type) (changeMinor body) binder
  | .letE name type value body => .letE name (changeMinor type) (changeMinor value) (changeMinor body)
  | .proj name index value => .proj name index (changeMinor value)
  | expr => expr

private def changedWorker (declarations : List PsDeclaration) (target : PsName) : List PsDeclaration :=
  declarations.map fun declaration =>
    match declaration with
    | .definitionDecl name levels type value =>
      if psNameEq name target then .definitionDecl name levels type (changeMinor value) else declaration
    | _ => declaration

private def checkRefusals (prelude : Lean.Kernel.Environment)
    (prepared : PsCompilerAdmissionReadyModule) : IO Unit := do
  let first :: rest := prepared.recursorWorkerGroups
    | throw (IO.userError "runtime fixture produced no companion workers")
  let firstWorker :: _ := first.workers | throw (IO.userError "runtime fixture has an empty worker group")
  expectRefused { prepared with recursorWorkerGroups := [] } "missing companion plan"
  expectRefused { prepared with
    recursorWorkerGroups :=
      { first with workers := first.workers.take 1 } :: rest } "incomplete companion plan"
  expectRefused { prepared with
    recursorWorkerGroups :=
      { first with workers := first.workers.reverse } :: rest } "reordered companion plan"
  expectRefused { prepared with
    recursorWorkerGroups :=
      { first with captureCount := first.captureCount + 1 } :: rest } "stale capture telescope"
  let altered := changedWorker prepared.declarations firstWorker.name
  let _ ← checked prelude altered
  expectRefused { prepared with declarations := altered } "kernel-accepted stale companion minor"
  match psCompilerErasePreparedRuntimeView prepared altered with
  | .error (.erasure _) => pure ()
  | _ => throw (IO.userError "runtime view replaced a retained checked companion body")
  IO.println "PSCV0_M3_INDUCTIVE_RUNTIME_REFUSALS: PASS complete ordered worker ownership, capture telescope and kernel-accepted stale equation"

private def emit (ir : PsVerifiedIrModule) : Except String (List PsEmissionArtifact) := do
  let context : PsEmissionContext := {
    sourceName := "m3-group-runtime.ps", sourceText := groupSource, outputStem := "groupfold" }
  let (_, artifacts) ← psWithCheckedIr psIrCheckDefaultOptions ir fun checked => do
    let ecma ← PsEcma.plan checked
    let js ← PsEcma.emitProgram ecma .javascript context
    let ts ← PsEcma.emitProgram ecma .typescript context
    let rust ← psRustEmitReadable checked "groupfold" []
    let exports := PsApiExposure.selected ["m3groupleft", "m3groupright"]
    let core ← PsWasm.emit checked context false exports
    let component ← PsWasm.emit checked context true exports
    return [js, ts, rust, core, component]
  return artifacts

end M3InductiveRuntime

open M3InductiveRuntime in
def main (args : List String) : IO Unit := do
  let [directory] := args | throw (IO.userError "expected output directory")
  ensure (Lean.versionString == PsV7Native.leanVersion && Lean.githash == PsV7Native.leanCommit)
    "group runtime qualification requires the pinned Lean"
  let group ← fromExcept elaborateGroup
  let declarations := group.declarations ++ foldDeclarations ++ outputs
  let environment ← fromExcept
    ((psAddDeclarationList psSelfHostProdPreludeEnvironment declarations).mapError elabMessage)
  let prepared ← fromExcept
    ((psCompilerPrepareElaboratedWithOutput { environment, declarations }).mapError psCompilerPscv0Error)
  ensure (prepared.prepared.recursorWorkerGroups.length == 2 &&
    prepared.prepared.recursorWorkerGroups.all (fun group =>
      group.workers.length == 2 && group.captureCount == 2))
    "generic two-family folds did not retain A and seed in every companion"
  let initial ← PsKernelLean.buildLeanPreludeEnvironment
  let prelude ← fromExcept (initial.mapError (fun error => error.message))
  let admitted ← checked prelude prepared.prepared.declarations
  let _ ← checked admitted
    [witness "m3groupleft" false 24, witness "m3groupleft" true 23,
     witness "m3groupright" false 9, witness "m3groupright" true 2]
  checkRefusals prelude prepared.prepared
  let ir ← fromExcept ((psCompilerVerifiedIrFromPrepared prepared.prepared).mapError psCompilerPscv0Error)
  let artifacts ← fromExcept (emit ir)
  ensure (artifacts.length == 5) "group runtime did not emit all five targets"
  let directory := System.FilePath.mk directory
  IO.FS.createDirAll directory
  IO.FS.writeFile (directory / "group.ps") groupSource
  for artifact in artifacts do
    for file in artifact.files do
      match file.payload with
      | .text value => IO.FS.writeFile (directory / file.path) value
      | .binary value => IO.FS.writeBinFile (directory / file.path) value
  IO.FS.writeFile (directory / "expected.json")
    "[{\"flag\":false,\"m3groupleft\":\"24\",\"m3groupright\":\"9\"},{\"flag\":true,\"m3groupleft\":\"23\",\"m3groupright\":\"2\"}]\n"
  IO.println "PSCV0_M3_INDUCTIVE_RUNTIME: PASS fresh official-kernel equations, generic captured companions, distinct Nat/Bool motives, unequal family index counts and five-target emission; target VMs follow"

