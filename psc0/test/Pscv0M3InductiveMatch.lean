import Ps.Host.NativeV7
import PsKernelLean.Admission

-- Independent pinned Lean source. Native mutual headers share their parameter
-- spellings; the portable AST below deliberately uses A/a versus B/b.
universe u v
mutual
  inductive M3MatchLeft (A : Type u) (a : A) : Type u where
    | leaf (value : A)
    | link (n : Nat) (next : M3MatchRight A a n)
  inductive M3MatchRight (A : Type u) (a : A) : Nat → Type u where
    | zero (previous : M3MatchLeft A a) : M3MatchRight A a 0
    | step (n : Nat) (previous : M3MatchLeft A a) : M3MatchRight A a (Nat.succ n)
end

mutual
  inductive M3MatchPropLeft : Prop where
    | fromRight (right : M3MatchPropRight)
  inductive M3MatchPropRight : Prop where
    | intro
end

namespace M3InductiveMatchOracle

-- Native K computation uses the unique proof constructor even when the
-- supplied proof is a variable. It does not unfold or inspect that proof.
example (h : (0 : Nat) = 0) :
    Eq.rec (motive := fun _ _ => Nat) 7 h = 7 := rfl
example (h : True) : True.rec (motive := fun _ => Nat) 7 h = 7 := rfl

def leftTag (A : Type u) (a : A) (x : M3MatchLeft A a) : Nat :=
  match x with
  | .leaf _ => 3
  | .link n _ => Nat.add n 7

def rightTag (A : Type u) (a : A) (n : Nat) (x : M3MatchRight A a n) : Nat :=
  match x with
  | .zero previous => Nat.add 11 (leftTag A a previous)
  | .step k previous => Nat.add (Nat.add k 19) (leftTag A a previous)

def copy (A : Type u) (a : A) (n : Nat)
    (x other : M3MatchRight A a n) : M3MatchRight A a n :=
  match x with
  | .zero _ => other
  | .step _ _ => other

def choose (A : Type u) (a : A) (R : Sort v) (fallback : R)
    (x : M3MatchLeft A a) : R :=
  match x with
  | .leaf _ => fallback
  | .link _ _ => fallback

theorem dependent (A : Type u) (a : A) (n : Nat)
    (x : M3MatchRight A a n) (h : n = n) : n = n := by
  cases x with
  | zero previous => exact h
  | step k previous => exact h

theorem major (A : Type u) (a : A) (n : Nat) (x : M3MatchRight A a n) : x = x := by
  cases x <;> rfl

theorem fixedMajor (x : M3MatchRight Nat 0 0) : x = x := by
  cases x <;> rfl


theorem fixedContextProof (x : M3MatchRight Nat 0 0) (h : x = x) : x = x := by
  cases x
  exact h

theorem compoundMajor (n : Nat) (x : M3MatchRight Nat 0 (Nat.succ n)) : x = x := by
  cases x <;> rfl

inductive RepeatedMajor : Nat → Nat → Type where
  | diagonal (n : Nat) : RepeatedMajor n n

theorem repeatedMajor (n : Nat) (x : RepeatedMajor n n) : x = x := by
  cases x <;> rfl

def fixedContext (x : M3MatchRight Nat 0 0) (k : x = x → Nat) : Nat := by
  cases x
  exact k rfl

def fixedContextOutput (flag : Bool) : UInt64 :=
  let x : M3MatchRight Nat 0 0 := .zero (.leaf 0)
  UInt64.ofNat (fixedContext x (fun _ => if flag then 17 else 13))

example : fixedContextOutput false = 13 := rfl
example : fixedContextOutput true = 17 := rfl
theorem prop (h : M3MatchPropLeft) : h = h := by
  cases h <;> rfl

def zeroOnly (x : M3MatchRight Nat 0 0) : Nat :=
  match x with
  | .zero _ => 23

-- The inner group cases retain the outer Nat recursion's actual hypothesis.
def nested (n : Nat) : Nat :=
  match n with
  | 0 => 0
  | k + 1 =>
    match (M3MatchLeft.leaf k : M3MatchLeft Nat 0) with
    | .leaf value => Nat.add value (nested k)
    | .link index _ => Nat.add index (nested k)

def leftOutput (flag : Bool) : UInt64 :=
  let x : M3MatchLeft Nat 0 :=
    if flag then .link 5 (.step 4 (.leaf 17)) else .leaf 13
  UInt64.ofNat (leftTag Nat 0 x)

def rightOutput (flag : Bool) : UInt64 :=
  if flag then
    let first : M3MatchRight Nat 0 5 := .step 4 (.leaf 1)
    let second : M3MatchRight Nat 0 5 := .step 4 (.link 3 (.step 2 (.leaf 17)))
    UInt64.ofNat (rightTag Nat 0 5 (copy Nat 0 5 first second))
  else
    let first : M3MatchRight Nat 0 0 := .zero (.leaf 1)
    let second : M3MatchRight Nat 0 0 := .zero (.link 1 (.step 0 (.leaf 13)))
    UInt64.ofNat (rightTag Nat 0 0 (copy Nat 0 0 first second))

def nestedOutput (flag : Bool) : UInt64 :=
  UInt64.ofNat (nested (if flag then 5 else 4))

def zeroOutput (flag : Bool) : UInt64 :=
  UInt64.ofNat (zeroOnly (.zero (.leaf (if flag then 17 else 13))))

example : leftOutput false = 3 := rfl
example : leftOutput true = 12 := rfl
example : rightOutput false = 19 := rfl
example : rightOutput true = 33 := rfl
example : nestedOutput false = 6 := rfl
example : nestedOutput true = 10 := rfl
example : zeroOutput false = 23 := rfl
example : zeroOutput true = 23 := rfl

end M3InductiveMatchOracle

namespace M3InductiveMatch

private def ensure (condition : Bool) (message : String) : IO Unit :=
  unless condition do throw (IO.userError message)

private def fromExcept (result : Except String α) : IO α :=
  match result with
  | .ok value => pure value
  | .error error => throw (IO.userError error)

private def groupSource : String :=
  "universe u\n" ++
  "inductive M3MatchLeft(A: Type u, a: A): Type u where { | leaf(value: A) | link(n: Nat, next: M3MatchRight(A, a, n)) }\n" ++
  "inductive M3MatchRight(B: Type u, b: B): Nat -> Type u where { | zero(previous: M3MatchLeft(B, b)): M3MatchRight(B, b, 0) | step(n: Nat, previous: M3MatchLeft(B, b)): M3MatchRight(B, b, Nat.succ(n)) }\n"

private def propSource : String :=
  "inductive M3MatchPropLeft: Prop where { | fromRight(right: M3MatchPropRight) }\n" ++
  "inductive M3MatchPropRight: Prop where { | intro }\n"

private def logicalSource : String :=
  "universe u v\n" ++
  "function m3MatchChoose(A: Type u, a: A, R: Sort v, fallback: R, x: M3MatchLeft(A, a)): R := match x with { | .leaf value => fallback | .link n next => fallback }\n" ++
  "theorem m3MatchFixedMajor(x: M3MatchRight(Nat, 0, 0)): x = x := match x with { | .zero previous => by { rfl } }\n" ++
  "theorem m3MatchFixedContext(x: M3MatchRight(Nat, 0, 0), h: x = x): x = x := match x with { | .zero previous => h }\n" ++
  "theorem m3MatchCompoundMajor(n: Nat, x: M3MatchRight(Nat, 0, Nat.succ(n))): x = x := match x with { | .step k previous => by { rfl } }\n" ++
  "inductive M3RepeatedMajor: Nat -> Nat -> Type where { | diagonal(n: Nat): M3RepeatedMajor(n, n) }\n" ++
  "theorem m3MatchRepeatedMajor(n: Nat, x: M3RepeatedMajor(n, n)): x = x := match x with { | .diagonal k => by { rfl } }\n" ++
  "theorem m3MatchMajor(A: Type u, a: A, n: Nat, x: M3MatchRight(A, a, n)): x = x := match x with { | .zero previous => by { rfl } | .step k previous => by { rfl } }\n" ++
  "theorem m3MatchDependent(A: Type u, a: A, n: Nat, x: M3MatchRight(A, a, n), h: n = n): n = n := match x with { | .zero previous => h | .step k previous => h }\n" ++
  "theorem m3MatchCases(A: Type u, a: A, n: Nat, x: M3MatchRight(A, a, n), h: n = n): n = n := by {\n" ++
  "  cases x\n  case zero previous => exact h\n  case step k previous => exact h\n}\n" ++
  "theorem m3MatchProp(h: M3MatchPropLeft): h = h := by {\n" ++
  "  cases h\n  case fromRight right => rfl\n}\n"

private def runtimeSource : String :=
  "universe u\n" ++
  "function m3MatchFixedContext(x: M3MatchRight(Nat, 0, 0), k: (p: x = x) -> Nat): Nat := match x with { | .zero previous => k(by { rfl }) }\n" ++
  "function m3matchfixedcontext(flag: Bool): UInt64 := {\n  let x: M3MatchRight(Nat, 0, 0) := M3MatchRight.zero(M3MatchLeft.leaf(0))\n  UInt64.ofNat(m3MatchFixedContext(x, fun (p: x = x) => if (flag) { 17 } else { 13 }))\n}\n" ++
  "function m3MatchLeftTag(A: Type u, a: A, x: M3MatchLeft(A, a)): Nat := match x with { | .leaf value => 3 | .link n next => Nat.add(n, 7) }\n" ++
  "function m3MatchRightTag(A: Type u, a: A, n: Nat, x: M3MatchRight(A, a, n)): Nat := match x with { | .zero previous => Nat.add(11, m3MatchLeftTag(A, a, previous)) | .step k previous => Nat.add(Nat.add(k, 19), m3MatchLeftTag(A, a, previous)) }\n" ++
  "function m3MatchCopy(A: Type u, a: A, n: Nat, x: M3MatchRight(A, a, n), other: M3MatchRight(A, a, n)): M3MatchRight(A, a, n) := match x with { | .zero previous => other | .step k previous => other }\n" ++
  "function m3MatchZero(x: M3MatchRight(Nat, 0, 0)): Nat := match x with { | .zero previous => 23 }\n" ++
  "function m3MatchNested(n: Nat): Nat := match n with { | 0 => 0 | k + 1 => match (M3MatchLeft.leaf(k) : M3MatchLeft(Nat, 0)) with { | .leaf value => Nat.add(value, m3MatchNested(k)) | .link index next => Nat.add(index, m3MatchNested(k)) } }\n" ++
  "function m3matchleft(flag: Bool): UInt64 := {\n" ++
  "  let x: M3MatchLeft(Nat, 0) := if (flag) { M3MatchLeft.link(5, M3MatchRight.step(4, M3MatchLeft.leaf(17))) } else { M3MatchLeft.leaf(13) }\n" ++
  "  UInt64.ofNat(m3MatchLeftTag(Nat, 0, x))\n}\n" ++
  "function m3matchright(flag: Bool): UInt64 := if (flag) {\n" ++
  "  let first: M3MatchRight(Nat, 0, 5) := M3MatchRight.step(4, M3MatchLeft.leaf(1))\n" ++
  "  let second: M3MatchRight(Nat, 0, 5) := M3MatchRight.step(4, M3MatchLeft.link(3, M3MatchRight.step(2, M3MatchLeft.leaf(17))))\n" ++
  "  UInt64.ofNat(m3MatchRightTag(Nat, 0, 5, m3MatchCopy(Nat, 0, 5, first, second)))\n" ++
  "} else {\n" ++
  "  let first: M3MatchRight(Nat, 0, 0) := M3MatchRight.zero(M3MatchLeft.leaf(1))\n" ++
  "  let second: M3MatchRight(Nat, 0, 0) := M3MatchRight.zero(M3MatchLeft.link(1, M3MatchRight.step(0, M3MatchLeft.leaf(13))))\n" ++
  "  UInt64.ofNat(m3MatchRightTag(Nat, 0, 0, m3MatchCopy(Nat, 0, 0, first, second)))\n}\n" ++
  "function m3matchnested(flag: Bool): UInt64 := UInt64.ofNat(m3MatchNested(if (flag) { 5 } else { 4 }))\n" ++
  "function m3matchzero(flag: Bool): UInt64 := UInt64.ofNat(m3MatchZero(M3MatchRight.zero(M3MatchLeft.leaf(if (flag) { 17 } else { 13 }))))\n"

private def elaborateGroup (text : String) (levels : List PsName) :
    Except String PsElabDeclarationBatchResult := do
  let parsed ← psPscv0ParseProgram text
  let chunks ← parsed.commands.mapM fun command =>
    match command with
    | .universeCmd _ _ => pure []
    | .declaration (.inductiveDecl name params resultType constructors _) =>
      pure [{ name, params, resultType, constructors : PsElabInductiveSource }]
    | _ => throw "group fixture expected native inductive members"
  (psElabInductiveGroup psSelfHostProdPreludeEnvironment chunks.flatten levels).mapError
    psCompilerPscv0ElabError

private def sourceDeclarations (environment : PsEnvironment) (text : String) :
    IO (List PsDeclaration) := do
  let parsed ← fromExcept (psPscv0ParseProgram text)
  let result ← fromExcept
    ((psElabProgramWithOrigins environment parsed).mapError psCompilerPscv0ElabError)
  return result.result.declarations

private def checked (prelude : Lean.Kernel.Environment) (declarations : List PsDeclaration) :
    IO Lean.Kernel.Environment := do
  let encoded ← fromExcept ((psEncodeCheckedAdmissionsCanonical declarations).mapError
    (fun _ => "canonical group match admission refused"))
  let decoded ← fromExcept ((PsKernelLean.decodeCanonicalAdmissions encoded).mapError
    (fun error => error.kind.code ++ ": " ++ error.message))
  let result ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
    PsKernelLean.admitDeclarations prelude decoded
  fromExcept (result.mapError (fun error => error.kind.code ++ ": " ++ error.message))

private def refusal : PsElabError → String
  | .atDeclaration _ error => refusal error
  | .typeMismatch => "type"
  | .matchNonExhaustive => "coverage"
  | .matchConstructorUnknown _ => "constructor"
  | .matchRecursorUnsupported => "group"
  | .structuralRecursionNotDecreasing => "structural"
  | .proof message => "proof:" ++ message
  | .refinement message => "refinement:" ++ message
  | .infer .applicationTypeMismatch => "infer:application"
  | .infer (.unknownConstant name) => "missing:" ++ psNameToString name
  | error => psCompilerPscv0ElabError error

private def expectRefused (environment : PsEnvironment)
    (label text expected : String) : IO Unit := do
  -- Parsing must succeed: an earlier grammar error does not qualify a refusal.
  let parsed ← fromExcept (psPscv0ParseProgram text)
  match psElabProgramWithOrigins environment parsed with
  | .ok _ => throw (IO.userError ("unexpected group match acceptance: " ++ label))
  | .error error =>
    ensure (refusal error == expected)
      (label ++ " refused at the wrong rule: " ++ refusal error)

private def simpleMatch : String :=
  "function probe(x: M3MatchLeft(Nat, 0)): Nat := match x with { | .leaf value => 0 | .link n next => 1 }\n"

private def remove (environment : PsEnvironment) (name : PsName) : PsEnvironment :=
  let hash := psEnvironmentNameHash name
  let bucket := psEnvironmentIndexFindWorker 16 environment.index hash
  {
    environment with
    declarations := psEnvironmentRemoveName name environment.declarations
    index := psEnvironmentIndexSetWorker 16 environment.index hash
      (psEnvironmentRemoveName name bucket) }

private def checkRefusals (environment : PsEnvironment) : IO Unit := do
  expectRefused environment "nonexhaustive"
    "function bad(x: M3MatchLeft(Nat, 0)): Nat := match x with { | .leaf value => 0 }\n"
    "coverage"
  expectRefused environment "wrong family constructor"
    "function bad(x: M3MatchLeft(Nat, 0)): Nat := match x with { | M3MatchRight.zero previous => 0 }\n"
    "constructor"
  expectRefused environment "Prop large elimination"
    "function bad(h: M3MatchPropLeft): Nat := match h with { | .fromRight right => 0 }\n"
    "infer:application"
  expectRefused environment "singleton Prop large elimination"
    "function bad(h: Or True True): Nat := match h with { | .inl proof => 0 | .inr proof => 1 }\n"
    "infer:application"
  expectRefused environment "group induction"
    "theorem bad(x: M3MatchLeft(Nat, 0)): x = x := by { induction x }\n"
    "proof:group induction requires a complete motive family"
  expectRefused environment "group structural recursion"
    ("function bad(x: M3MatchLeft(Nat, 0)): Nat := match x with { | .leaf value => 0 | .link n next => " ++
      "match next with { | .zero previous => bad(previous) | .step k previous => bad(previous) } }\n")
    "structural"
  expectRefused (remove environment (psRootName "HEq")) "missing heterogeneous equality"
    "theorem bad(x: M3MatchRight(Nat, 0, 0)): x = x := match x with { | .zero previous => by { rfl } }\n"
    "missing:HEq"
  let rightRec := psNameAppendStr (psRootName "M3MatchRight") "rec"
  expectRefused (remove environment rightRec) "missing group member recursor" simpleMatch "group"
  let some recursor := psEnvironmentFindRecursor environment rightRec
    | throw (IO.userError "fixture group recursor is absent")
  let reordered := psEnvironmentInsert environment
    (.recursorDecl { recursor with inductiveNames := recursor.inductiveNames.reverse })
  expectRefused reordered "reordered motive family" simpleMatch "group"
  let zero := psNameAppendStr (psRootName "M3MatchRight") "zero"
  let some constructor := psEnvironmentFindConstructor environment zero
    | throw (IO.userError "fixture group constructor is absent")
  let wrongSlot := psEnvironmentInsert environment
    (.constructorDecl { constructor with constructorIndex := 1 })
  expectRefused wrongSlot "wrong companion constructor ordinal" simpleMatch "group"
  let unit := psRootName "PUnit"
  expectRefused (remove environment unit) "missing checked PUnit" simpleMatch "missing:PUnit"
  let some constructor := psEnvironmentFindConstructor environment (psNameAppendStr unit "unit")
    | throw (IO.userError "selected Standard has no PUnit constructor")
  let wrongUnit := psEnvironmentInsert environment
    (.constructorDecl { constructor with type := .constE psNatName [] })
  expectRefused wrongUnit "wrong PUnit inhabitant type" simpleMatch "group"
  IO.println "PSCV0_M3_INDUCTIVE_MATCH_REFUSALS: PASS source coverage, group ownership, actual PUnit typing, Prop elimination and explicit induction/recursion limits and actual HEq foundation"

private def outputCases : List (String × (Bool → UInt64)) :=
  [("m3matchleft", M3InductiveMatchOracle.leftOutput),
   ("m3matchright", M3InductiveMatchOracle.rightOutput),
   ("m3matchnested", M3InductiveMatchOracle.nestedOutput),
   ("m3matchzero", M3InductiveMatchOracle.zeroOutput),
   ("m3matchfixedcontext", M3InductiveMatchOracle.fixedContextOutput)]

private def witness (name : String) (flag : Bool) (expected : UInt64) : PsDeclaration :=
  let uint64 := PsExpr.constE (psRootName "UInt64") []
  let argument := PsExpr.constE (psNameAppendStr psBoolName (if flag then "true" else "false")) []
  let value := PsExpr.app (.constE (psRootName name) []) argument
  let expected := PsExpr.app (.constE (psNameAppendStr (psRootName "UInt64") "ofNat") [])
    (.lit (.natural expected.toNat))
  let proposition := psExprApplyMany (.constE psEqName [.succ .zero]) [uint64, value, expected]
  let proof := psExprApplyMany (.constE (psNameAppendStr psEqName "refl") [.succ .zero])
    [uint64, expected]
  .theoremDecl (psRootName (name ++ (if flag then "TrueEquation" else "FalseEquation")))
    [] proposition proof

private def checkPortableReduction (environment : PsEnvironment) : IO Unit := do
  let nat := PsExpr.constE psNatName []
  let number := fun n => PsExpr.lit (.natural n)
  let member := fun name args =>
    psExprApplyMany (.constE (psNameAppendStr (psRootName "M3MatchLeft") name) [.zero])
      ([nat, number 0] ++ args)
  let right := fun name args =>
    psExprApplyMany (.constE (psNameAppendStr (psRootName "M3MatchRight") name) [.zero])
      ([nat, number 0] ++ args)
  let leaf := member "leaf" [number 13]
  let link := member "link" [number 5, right "step" [number 4, leaf]]
  let first := right "step" [number 4, leaf]
  let second := right "step" [number 4,
    member "link" [number 3, right "step" [number 2, leaf]]]
  let copied := psExprApplyMany (.constE (psRootName "m3MatchCopy") [.zero])
    [nat, number 0, number 5, first, second]
  let cases := [
    (psExprApplyMany (.constE (psRootName "m3MatchLeftTag") [.zero]) [nat, number 0, leaf], 3),
    (psExprApplyMany (.constE (psRootName "m3MatchLeftTag") [.zero]) [nat, number 0, link], 12),
    (psExprApplyMany (.constE (psRootName "m3MatchRightTag") [.zero])
      [nat, number 0, number 5, copied], 33),
    (PsExpr.app (.constE (psRootName "m3MatchNested") []) (number 5), 10),
    (PsExpr.app (.constE (psRootName "m3MatchZero") []) (right "zero" [leaf]), 23)]
  for (probe, expected) in cases do
    ensure (psExprAlphaEq (psWhnf environment psMetaEmpty psLocalEmpty probe) (number expected))
      "portable group cases reduction differs from the independent native equation"

private def checkKReduction (environment : PsEnvironment) :
    IO (List PsDeclaration) := do
  let nat := PsExpr.constE psNatName []
  let zero := PsExpr.lit (.natural 0)
  let seven := PsExpr.lit (.natural 7)
  let level := PsLevel.succ .zero
  let eqType := psLogicEq level nat zero zero
  let eqMotive := psLogicLam 1 "n" nat
    (psLogicLam 2 "h" (psLogicEq level nat zero (.fvar 1)) nat)
  let eqValue := psExprApplyMany (.constE (psNameAppendStr psEqName "rec") [level, level])
    [nat, zero, eqMotive, seven, zero, .fvar 0]
  let trueType := PsExpr.constE (psRootName "True") []
  let trueMotive := psLogicLam 1 "h" trueType nat
  let trueValue := psExprApplyMany (.constE (psNameAppendStr (psRootName "True") "rec") [level])
    [trueMotive, seven, .fvar 0]
  let mut equations := []
  for (name, proofType, value) in
      [("m3KEq", eqType, eqValue), ("m3KTrue", trueType, trueValue)] do
    let proof := psLocalPushBinding psLocalEmpty (psRootName "h") proofType .explicit
    ensure (proof.id == 0) "K probe has unexpected initial local identity"
    let _ ← fromExcept ((psInferType environment psMetaEmpty proof.context value).mapError
      (fun _ => "K probe is not a well-typed recursor application"))
    ensure (psExprAlphaEq (psWhnf environment psMetaEmpty proof.context value) seven)
      "nullary predicate recursor did not compute through a proof variable"
    equations := equations ++ [PsDeclaration.theoremDecl (psRootName name) []
      (psLogicPi 0 "h" proofType (psLogicEq level nat value seven))
      (psLogicLam 0 "h" proofType (psLogicRefl level nat seven))]
  let one := PsExpr.lit (.natural 1)
  let unequal := psLocalPushBinding psLocalEmpty (psRootName "h")
    (psLogicEq level nat zero one) .explicit
  let stuck := psExprApplyMany (.constE (psNameAppendStr psEqName "rec") [level, level])
    [nat, zero, eqMotive, seven, one, .fvar unequal.id]
  let _ ← fromExcept ((psInferType environment psMetaEmpty unequal.context stuck).mapError
    (fun _ => "unequal-index K refusal probe is not well typed"))
  ensure (!psExprAlphaEq (psWhnf environment psMetaEmpty unequal.context stuck) seven)
    "K reduction identified different equality endpoints"
  let fresh := psMetaFresh psMetaEmpty psLocalEmpty nat .natural
  let unresolved := psLocalPushBinding psLocalEmpty (psRootName "h")
    (psLogicEq level nat zero fresh.expr) .explicit
  let stuck := psExprApplyMany (.constE (psNameAppendStr psEqName "rec") [level, level])
    [nat, zero, eqMotive, seven, fresh.expr, .fvar unresolved.id]
  ensure (!psExprAlphaEq (psWhnf environment fresh.context unresolved.context stuck) seven)
    "K reduction solved an unresolved index"
  IO.println "PSCV0_M3_K_REDUCTION: PASS Eq/True proof-variable computation, unequal and unresolved index refusals; exact equations follow through the official kernel"
  return equations

private def emit (ir : PsVerifiedIrModule) : Except String (List PsEmissionArtifact) := do
  let context : PsEmissionContext := {
    sourceName := "m3-group-match.ps", sourceText := runtimeSource, outputStem := "groupmatch" }
  let (_, artifacts) ← psWithCheckedIr psIrCheckDefaultOptions ir fun checked => do
    let ecma ← PsEcma.plan checked
    let js ← PsEcma.emitProgram ecma .javascript context
    let ts ← PsEcma.emitProgram ecma .typescript context
    let rust ← psRustEmitReadable checked "groupmatch" []
    let exports := PsApiExposure.selected (outputCases.map Prod.fst)
    let core ← PsWasm.emit checked context false exports
    let component ← PsWasm.emit checked context true exports
    return [js, ts, rust, core, component]
  return artifacts

end M3InductiveMatch

open M3InductiveMatch in
def main (args : List String) : IO Unit := do
  let [directory] := args | throw (IO.userError "expected output directory")
  ensure (Lean.versionString == PsV7Native.leanVersion && Lean.githash == PsV7Native.leanCommit)
    "group match qualification requires the pinned Lean"
  let group ← fromExcept (elaborateGroup groupSource [psRootName "u"])
  let prop ← fromExcept (elaborateGroup propSource [])
  let groups := group.declarations ++ prop.declarations
  let environment ← fromExcept
    ((psAddDeclarationList psSelfHostProdPreludeEnvironment groups).mapError psCompilerPscv0ElabError)
  let logical ← sourceDeclarations environment logicalSource
  let runtime ← sourceDeclarations environment runtimeSource
  let initial ← PsKernelLean.buildLeanPreludeEnvironment
  let prelude ← fromExcept (initial.mapError (fun error => error.message))
  let kEquations ← checkKReduction environment
  let _ ← checked prelude (groups ++ logical ++ kEquations)
  checkRefusals environment
  let declarations := group.declarations ++ runtime
  let environment ← fromExcept
    ((psAddDeclarationList psSelfHostProdPreludeEnvironment declarations).mapError psCompilerPscv0ElabError)
  checkPortableReduction environment
  let prepared ← fromExcept
    ((psCompilerPrepareElaboratedWithOutput { environment, declarations }).mapError psCompilerPscv0Error)
  ensure prepared.prepared.recursorWorkerGroups.isEmpty
    "ordinary group cases unexpectedly consumed induction hypotheses or generated companions"
  let admitted ← checked prelude prepared.prepared.declarations
  let equations := [false, true].flatMap fun flag =>
    outputCases.map fun (name, oracle) => witness name flag (oracle flag)
  let _ ← checked admitted equations
  let ir ← fromExcept ((psCompilerVerifiedIrFromPrepared prepared.prepared).mapError psCompilerPscv0Error)
  let artifacts ← fromExcept (emit ir)
  ensure (artifacts.length == 5) "group match did not emit all five targets"
  let directory := System.FilePath.mk directory
  IO.FS.createDirAll directory
  IO.FS.writeFile (directory / "match.ps") runtimeSource
  for artifact in artifacts do
    for file in artifact.files do
      match file.payload with
      | .text value => IO.FS.writeFile (directory / file.path) value
      | .binary value => IO.FS.writeBinFile (directory / file.path) value
  let rows := [false, true].map fun flag =>
    Lean.Json.mkObj (("flag", Lean.toJson flag) ::
      outputCases.map (fun (name, oracle) => (name, Lean.toJson (toString (oracle flag)))))
  IO.FS.writeFile (directory / "expected.json") (Lean.Json.arr rows.toArray).pretty
  IO.println "PSCV0_M3_INDUCTIVE_MATCH: PASS native and fresh-kernel source cases, dependent shared parameters, indexed motive/context and heterogeneous major transport, polymorphic PUnit, Prop proofs, preserved outer recursion and five-target emission; runtime parity follows"
