import Ps.Host.NativeV7
import Ps.Syntax.PrintLean
import Ps.Syntax.PrintProofScript

-- Independent official Lean source at the required pin. Main explicit headers
-- and local let-rec headers intentionally have different inference boundaries.
namespace M3ResultInferenceOracle

def value := 11
def identity (n : Nat) := n
def closure (n : Nat) := fun (delta : Nat) => n + delta
def defaulted (n : Nat := 2) := n + 3
def headerSolved (n : _) (_h : n = (0 : Nat)) : Nat := n

def localHole (n : Nat) := helper n
where
  helper (k : Nat) : _ := k + 1

-- These result families depend on each declaration's own parameter.
def dependent (n : Nat) := Fin.mk n (Nat.lt_succ_self n)

def dependentForward (n : Nat) := helper (n + 1)
where
  helper (k : Nat) := Fin.mk k (Nat.lt_succ_self k)

def dependentValue (n : Nat) : Nat := Fin.val (helper n)
where
  helper (k : Nat) := Fin.mk k (Nat.lt_succ_self k)

-- Caller constraints must still reach an omitted/local-hole result before
-- numeral defaulting or a saved tactic continuation is resumed.
def callerProof (n : Nat) : Nat := helper n
where
  helper (k : Nat) : _ := by exact k

structure CallerToken where
  value : Nat

instance callerTokenZero : OfNat CallerToken 0 where
  ofNat := CallerToken.mk 23

mutual
  def caller (n : Nat) : CallerToken := callee 1
  def callee (n : Nat) := 0
end

-- Match and record bodies retain their existing expected-type inference.
inductive ZeroIndex : Nat → Type where
  | zero : ZeroIndex 0

def fixedIndex (x : ZeroIndex 0) :=
  match x with
  | .zero => 0

def recordCaller (n : Nat) : CallerToken := helper n
where
  helper (k : Nat) := { value := k }

mutual
  def even (n : Nat) :=
    match n with
    | 0 => true
    | k + 1 => odd k
  def odd (n : Nat) :=
    match n with
    | 0 => false
    | k + 1 => even k
end

partial def partialCount (n : Nat) :=
  match n with
  | 0 => 0
  | k + 1 => partialCount k + 1

mutual
  partial def partialLeft (n : Nat) :=
    match n with
    | 0 => 0
    | k + 1 => partialRight k + 1
  partial def partialRight (n : Nat) :=
    match n with
    | 0 => 2
    | k + 1 => partialLeft k + 1
end

universe u
section
variable (A : Type u) (a : A)
def pick (n : Nat) := if n == 0 then a else a
end

-- The result and the later binder domain both depend on the first own binder.
def ownIdentity (A : Type u) (a : A) := a

example : value = 11 := rfl
example : identity 8 = 8 := rfl
example : closure 3 4 = 7 := rfl
example : (defaulted : Nat) = 5 := rfl
example : headerSolved 0 rfl = 0 := rfl
example : localHole 4 = 5 := rfl
example (n : Nat) :
    dependent n = (Fin.mk n (Nat.lt_succ_self n) : Fin (n + 1)) := rfl
example (n : Nat) :
    dependentForward n =
      (Fin.mk (n + 1) (Nat.lt_succ_self (n + 1)) : Fin ((n + 1) + 1)) := rfl
example (k : Nat) :
    dependentForward.helper k = (Fin.mk k (Nat.lt_succ_self k) : Fin (k + 1)) := rfl
example (n : Nat) : dependentValue n = n := rfl
example (n : Nat) : callerProof n = n := rfl
example (n : Nat) : caller n = CallerToken.mk 23 := rfl
example (n : Nat) : callee n = CallerToken.mk 23 := rfl
example : (fixedIndex ZeroIndex.zero : Nat) = 0 := rfl
example (n : Nat) : recordCaller n = CallerToken.mk n := rfl
example : even 4 = true := rfl
example : odd 4 = false := rfl
example (A : Type u) (a : A) : ownIdentity A a = a := rfl
example : @pick Nat 17 1 = 17 := rfl

-- This guard must pass in cloud CI before the corresponding source-oracle
-- correction in Pscv0NativeTests can be regarded as native-qualified.
/-- error: Failed to infer type of definition `explicitHole` -/
#guard_msgs (error, drop warning, substring := true) in
def explicitHole : _ := 12

end M3ResultInferenceOracle

namespace M3ResultInference

private def ensure (condition : Bool) (message : String) : IO Unit :=
  unless condition do throw (IO.userError message)

private def fromExcept (result : Except String α) : IO α :=
  match result with
  | .ok value => pure value
  | .error message => throw (IO.userError message)

private def source : String :=
  "const riValue := 11\n" ++
  "function riIdentity(n: Nat) := n\n" ++
  "function riClosure(n: Nat) := fun (delta: Nat) => n + delta\n" ++
  "function riDefaulted(n: Nat := 2) := n + 3\n" ++
  "function riHeaderSolved(n: _, h: n = (0: Nat)): Nat := n\n" ++
  "function riLocalHole(n: Nat) := helper(n)\n" ++
  "where { def helper(k: Nat): _ := k + 1 }\n" ++
  "function riDependent(n: Nat) := Fin.mk(n, Nat.lt_succ_self(n))\n" ++
  "function riDependentForward(n: Nat) := helper(n + 1)\n" ++
  "where { def helper(k: Nat) := Fin.mk(k, Nat.lt_succ_self(k)) }\n" ++
  "function riDependentValue(n: Nat): Nat := Fin.val(helper(n))\n" ++
  "where { def helper(k: Nat) := Fin.mk(k, Nat.lt_succ_self(k)) }\n" ++
  "function riCallerProof(n: Nat): Nat := helper(n)\n" ++
  "where { def helper(k: Nat): _ := by { exact k } }\n" ++
  "structure RICallerToken where { value: Nat }\n" ++
  "instance riCallerTokenZero: OfNat(RICallerToken, 0) where { ofNat := RICallerToken.mk(23) }\n" ++
  "mutual\n" ++
  "function riCaller(n: Nat): RICallerToken := riCallee(1)\n" ++
  "function riCallee(n: Nat) := 0\n" ++
  "end\n" ++
  "inductive RIZeroIndex: Nat -> Type where { | zero: RIZeroIndex(0) }\n" ++
  "function riFixedIndex(x: RIZeroIndex(0)) := match x with { | RIZeroIndex.zero => 0 }\n" ++
  "function riRecordCaller(n: Nat): RICallerToken := helper(n)\n" ++
  "where { def helper(k: Nat) := { value := k } }\n" ++
  "mutual\n" ++
  "function riEven(n: Nat) := match n with { | 0 => true | k + 1 => riOdd(k) }\n" ++
  "function riOdd(n: Nat) := match n with { | 0 => false | k + 1 => riEven(k) }\n" ++
  "end\n" ++
  "partial function riPartialCount(n: Nat) := match n with { | 0 => 0 | k + 1 => riPartialCount(k) + 1 }\n" ++
  "mutual\n" ++
  "partial function riPartialLeft(n: Nat) := match n with { | 0 => 0 | k + 1 => riPartialRight(k) + 1 }\n" ++
  "partial function riPartialRight(n: Nat) := match n with { | 0 => 2 | k + 1 => riPartialLeft(k) + 1 }\n" ++
  "end\n" ++
  "universe u\nsection\nvariable (A: Type u) (a: A)\n" ++
  "function riPick(n: Nat) := if (n == 0) { a } else { a }\n" ++
  "end\n" ++
  "function riOwnIdentity(A: Type u, a: A) := a\n" ++
  "theorem riValueEq: riValue = 11 := by { rfl }\n" ++
  "theorem riIdentityEq: riIdentity(8) = 8 := by { rfl }\n" ++
  "theorem riClosureEq: riClosure(3)(4) = 7 := by { rfl }\n" ++
  "theorem riDefaultedEq: riDefaulted() = 5 := by { rfl }\n" ++
  "theorem riHeaderSolvedEq: riHeaderSolved(0, Eq.refl(0)) = 0 := by { rfl }\n" ++
  "theorem riLocalHoleEq: riLocalHole(4) = 5 := by { rfl }\n" ++
  "theorem riDependentEq(n: Nat): riDependent(n) = (Fin.mk(n, Nat.lt_succ_self(n)): Fin(n + 1)) := by { rfl }\n" ++
  "theorem riDependentForwardEq(n: Nat): riDependentForward(n) = (Fin.mk(n + 1, Nat.lt_succ_self(n + 1)): Fin((n + 1) + 1)) := by { rfl }\n" ++
  "theorem riDependentHelperEq(k: Nat): riDependentForward.helper(k) = (Fin.mk(k, Nat.lt_succ_self(k)): Fin(k + 1)) := by { rfl }\n" ++
  "theorem riDependentValueEq(n: Nat): riDependentValue(n) = n := by { rfl }\n" ++
  "theorem riCallerProofEq(n: Nat): riCallerProof(n) = n := by { rfl }\n" ++
  "theorem riCallerEq(n: Nat): riCaller(n) = RICallerToken.mk(23) := by { rfl }\n" ++
  "theorem riCalleeType(n: Nat): riCallee(n) = RICallerToken.mk(23) := by { rfl }\n" ++
  "theorem riFixedIndexEq: (riFixedIndex(RIZeroIndex.zero): Nat) = 0 := by { rfl }\n" ++
  "theorem riRecordCallerEq(n: Nat): riRecordCaller(n) = RICallerToken.mk(n) := by { rfl }\n" ++
  "theorem riEvenEq: riEven(4) = true := by { rfl }\n" ++
  "theorem riOddEq: riOdd(4) = false := by { rfl }\n" ++
  "theorem riOwnIdentityEq(A: Type u, a: A): riOwnIdentity(A, a) = a := by { rfl }\n" ++
  "theorem riPickEq: riPick(Nat, 17, 1) = 17 := by { rfl }\n"

private def checkRepresentation : IO Unit := do
  let parsed ← fromExcept (psPscv0ParseProgram
    "function omitted(n: Nat) := n\nfunction explicit(n: Nat): _ := n\n")
  let [.declaration omitted, .declaration explicit] := parsed.commands
    | throw (IO.userError "result-annotation fixture lost its two declaration heads")
  match omitted, explicit with
  | .definition _ _ (.omittedType span) _ _, .definition _ _ (.hole _) _ _ =>
    ensure (span.start.byteOffset == span.stop.byteOffset)
      "the omitted annotation acquired a fabricated source extent"
  | _, _ => throw (IO.userError "an omitted result and explicit header hole were conflated")
  for proofScript in [false, true] do
    let printed ← fromExcept ((if proofScript then psPrintProofScriptDeclaration omitted
      else psPrintLeanDeclaration omitted).mapError (fun _ => "omitted result did not print"))
    ensure ((printed.splitOn " : _").length == 1)
      "the printer manufactured an explicit result hole"
    let explicitText ← fromExcept ((if proofScript then psPrintProofScriptDeclaration explicit
      else psPrintLeanDeclaration explicit).mapError (fun _ => "explicit result hole did not print"))
    ensure ((explicitText.splitOn " : _").length > 1)
      "the printer discarded an explicit result annotation"
    let replay ← fromExcept (psPscv0ParseSource proofScript (printed ++ "\n"))
    let replayDeclarations : List PsSyntaxDeclaration :=
      replay.declarations.map PsPscv0SurfaceDeclaration.declaration
    match replayDeclarations with
    | [PsSyntaxDeclaration.definition _ _ (.omittedType _) _ _] => pure ()
    | _ => throw (IO.userError "source printing changed omitted-result ownership")
  let surface ← fromExcept (psPscv0ParseSource true "const surfaceValue := 11\n")
  for proofScript in [false, true] do
    let printed ← fromExcept (psPscv0PrintSurfaceModule proofScript surface)
    ensure ((printed.splitOn " : _").length == 1 && (printed.splitOn " := ").length > 1)
      "the surface printer changed declaration-result inference into an explicit hole"
  for text in ["theorem missing := True.intro\n", "opaque missing := 11\n"] do
    match psPscv0ParseProgram text with
    | .error _ => pure ()
    | .ok _ => throw (IO.userError "result inference escaped its selected value-declaration owner")

private def checkCore : IO Unit := do
  let parsed ← fromExcept (psPscv0ParseProgram source)
  let compiled ← fromExcept ((psElabProgramWithOrigins psSelfHostProdPreludeEnvironment parsed).mapError
    psCompilerPscv0ElabError)
  let environment := compiled.result.environment
  for name in ["riValue", "riIdentity", "riClosure", "riDefaulted", "riHeaderSolved", "riLocalHole",
      "riDependent", "riDependentForward", "riDependentValue", "riCallerProof", "riCaller", "riCallee",
      "riFixedIndex", "riRecordCaller", "riOwnIdentity",
      "riEven", "riOdd", "riPick"] do
    let some (.definitionDecl _ _ type value) := psEnvironmentFind environment (psRootName name)
      | throw (IO.userError ("inferred main did not produce a checked total definition: " ++ name))
    ensure (!psExprHasUnresolvedMeta type && !psExprHasUnresolvedMeta value &&
      (psExprFVarIds type).isEmpty && (psExprFVarIds value).isEmpty)
      ("inferred main retained a term/universe metavariable or an unowned local: " ++ name)
  for name in ["riPartialCount", "riPartialLeft", "riPartialRight"] do
    let partialName := psRootName name
    match psEnvironmentFind environment partialName,
        psEnvironmentFind environment (PsName.num partialName 0) with
    | some (.opaqueDecl _ levels type _), some (.partialDecl _ bodyLevels bodyType body) =>
      ensure (psElabMutualLevelNamesEqual levels bodyLevels && psExprAlphaEq type bodyType &&
        !psExprHasUnresolvedMeta type && !psExprHasUnresolvedMeta body &&
        (psExprFVarIds type).isEmpty && (psExprFVarIds body).isEmpty)
        ("inferred partial lost its common closed logical/body type: " ++ name)
    | _, _ => throw (IO.userError ("inferred partial lost its actual logical/body identities: " ++ name))
    ensure ((psEnvironmentFind environment (psNameAppendStr partialName "eq_def")).isNone)
      "inferred partial acquired an unapproved logical equation"

private def refusals : List (String × String × String) := [
  ("explicit-main-hole", "const riBad: _ := 12\n", "PSCV0-DECLARATION-HEADER"),
  ("explicit-mutual-main-hole",
    "mutual\nfunction riBad(n: Nat): _ := n\nend\n", "PSCV0-WHERE-HEADER"),
  ("unresolved-omitted-result", "const riBad := _\n", "PSCV0-WHERE-INFER-TYPE"),
  ("body-only-binder-inference",
    "function riBad(n: _) := Nat.succ(n)\n", "PSCV0-WHERE-HEADER"),
  ("illtyped-omitted-result",
    "function riBad(n: Nat) := Fin.mk(true, Nat.lt_succ_self(n))\n", "PSCV0-TYPE-MISMATCH")]
-- The exact former inferred-fixedpoint-policy program is now a logical-only
-- positive in Pscv0M3PartialFixpoint; its divergent branch is never executed.

def check : IO Unit := do
  ensure (Lean.versionString == PsV7Native.leanVersion && Lean.githash == PsV7Native.leanCommit)
    "result inference qualification requires pinned Lean"
  ensure (M3ResultInferenceOracle.partialCount 4 == 4 &&
    M3ResultInferenceOracle.partialLeft 4 == 4 && M3ResultInferenceOracle.partialRight 4 == 6)
    "independent native omitted partial bodies did not return the expected values"
  checkRepresentation
  checkCore
  let requests := #[({ source, sourceName := "m3-result-inference.ps" } : PsV7Native.Request)] ++
    (refusals.map fun (_, text, _) => ({ source := text } : PsV7Native.Request)).toArray
  let batch : PsV7Native.Batch ← match ← PsV7Native.runBatch requests with
    | .ok value => pure value
    | .error error => throw (IO.userError (error.phase ++ ": " ++ error.message))
  match (batch.results[0]? : Option (Except PsV7Native.Diagnostic PsV7Native.Result)) with
  | some (Except.ok result) =>
    ensure (result.declarationCount > 0 && result.artifacts.isEmpty)
      "source-only inference qualification returned an empty or executable result"
  | some (Except.error error) => throw (IO.userError (error.phase ++ ": " ++ error.message))
  | none => throw (IO.userError "missing inference qualification result")
  for ((label, _, rule), index) in refusals.zipIdx do
    match batch.results[index + 1]? with
    | some (.error error) =>
      ensure (error.phase == "elaborate" && (error.message.splitOn rule).length > 1)
        (label ++ " refused at wrong owner: " ++ error.phase ++ ": " ++ error.message)
    | _ => throw (IO.userError ("unexpected result-inference acceptance: " ++ label))
  IO.println "PSCV0_M3_RESULT_INFERENCE: PASS independent native dependent result families, caller-guided inference and main-hole/local-hole boundaries, preserved source printing, checked total and partial headers, recursive predefinitions, scoped captures and exact refusals"

end M3ResultInference

