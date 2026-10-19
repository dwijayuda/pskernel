import Ps.Host.NativeV7
import Ps.Environment.CompilerSourceCandidate
import Ps.Environment.Fingerprint
import Ps.Syntax.PrintLean
import Ps.Syntax.PrintProofScript
import PsKernelLean.Replay
import PsKernelLean.Protocol
import PsKernelLean.Admission

-- Native sources are elaborated by the pinned Lean compiler independently of both selected readers.
namespace CoreRCasesOracle
set_option linter.unusedRCasesPattern false

theorem rcAnd (A B C : Prop) (h : And A (And B C)) : And C A := by
  rcases h with ⟨ha, hb, hc⟩
  exact And.intro hc ha
theorem rcOr (A B C : Prop) (h : Or A (Or B C)) : Or C (Or B A) := by
  rcases h with ha | hb | hc
  · exact Or.inr (Or.inr ha)
  · exact Or.inr (Or.inl hb)
  · exact Or.inl hc
theorem rcExists (P : Nat -> Prop) (h : Exists (fun n => And (P n) (n = n))) : Exists P := by
  rcases h with ⟨n, hp, _⟩
  exact Exists.intro n hp
theorem rcMissing (A B : Prop) (h : And A B) : A := by
  rcases h with ⟨ha⟩
  exact ha
theorem rcDuplicate (h : And True (0 = 0)) : 0 = 0 := by
  rcases h with ⟨same, same⟩
  exact same

inductive RCPack : Type where
  | mk {index : Nat} (value : Nat) : RCPack
def rcImplicit (p : RCPack) : Nat := by
  rcases p with ⟨value⟩
  exact value
def rcExplicit (p : RCPack) : Nat := by
  rcases p with @⟨index, value⟩
  exact index
def rcZeroFields (p : Unit) : Nat := by
  rcases p with ⟨unused, remainder⟩
  exact 4
theorem rcGrouped (A B C : Prop) (h : And A (Or B C)) : Or (And A B) (And A C) := by
  rcases h with ⟨ha, (hb | hc)⟩
  · exact Or.inl (And.intro ha hb)
  · exact Or.inr (And.intro ha hc)

def rcComputed (n : Nat) : Nat := by
  rcases (Prod.mk n (Nat.succ n)) with ⟨a, b⟩
  exact b
def rcComputedName (n : Nat) : Nat := by
  rcases Nat.succ n with value
  exact value
def rcMultiple (left right : Prod Nat Nat) : Nat := by
  rcases left, right with ⟨⟨a, b⟩, ⟨c, d⟩⟩
  exact d
theorem rcNamed (n : Nat) : True := by
  rcases equation : Prod.mk n (Nat.succ n) with ⟨a, b⟩
  have retained : Prod.mk n (Nat.succ n) = Prod.mk a b := equation
  exact True.intro

theorem rcRetained (h : True) : True := by
  rcases h with ignored
  exact h
def rcRetainedLet (n : Nat) : Nat := by
  let value : Nat := n
  rcases value with ignored
  exact value
theorem rcNoTargets : True := by
  rcases
  exact True.intro
theorem rcDefault (h : False) : True := by
  rcases h
def rcTypedRoot (A : Type) (x : A) : A := by
  rcases x with (ignored : A)
  exact x

def rcRIntro : Prod Nat Nat -> Nat := by
  rintro ⟨a, b⟩
  exact b
theorem rcIntroAlternatives (A B C : Prop) : Or A B -> (A -> C) -> (B -> C) -> C := by
  rintro (ha | hb) left right
  · exact left ha
  · exact right hb
def rcIntroGrouped : Nat -> Nat -> Nat := by
  rintro (x y : Nat)
  exact x
def rcIntroNested : Nat -> Bool -> Nat := by
  rintro ((x : Nat) (flag : Bool))
  exact x

theorem rcObtainValue (A B : Prop) (h : And A B) : B := by
  obtain ⟨ha, hb⟩ := h
  exact hb
theorem rcObtainAntecedent (A : Prop) (h : A) : A := by
  obtain witness : A
  · exact h
  · exact witness
theorem rcObtainDefault (A : Prop) (h : A) : A := by
  obtain : A
  · exact h
  · exact this
theorem rcObtainDestruct : True := by
  obtain ⟨left, right⟩ : And True True
  · exact And.intro True.intro True.intro
  · exact right
def rcObtainComputed (n : Nat) : Nat := by
  obtain value : Nat := Nat.succ n
  exact value
def rcObtainMultiple (n : Nat) : Nat := by
  obtain ⟨a, b⟩ := Nat.succ n, Nat.succ (Nat.succ n)
  exact b

theorem rcRflRight (n m : Nat) (h : n = m) (P : Nat -> Prop) (hn : P n) : P m := by
  rcases h with rfl
  exact hn
theorem rcRflLeft (n m : Nat) (h : n = Nat.succ m) (P : Nat -> Prop) (hm : P (Nat.succ m)) : P n := by
  rcases h with rfl
  exact hm
theorem rcRflLet (n m : Nat) (h : n = m) : m = n := by
  let value : Nat := m
  have retained : value = m := by rfl
  rcases h with rfl
  exact retained
theorem rcRflProof (n m : Nat) (h : n = m) (p : h = h) : h = h := by
  rcases h with rfl
  exact p
theorem rcRflReduced (n m : Nat) (h : n = (fun x : Nat => x) m) : n = m := by
  rcases h with rfl
  rfl

theorem rcClearField (A : Prop) (h : And A A) : A := by
  rcases h with ⟨-, kept⟩
  exact kept
theorem rcClearDependent (h : Exists (fun n : Nat => n = n)) : True := by
  rcases h with ⟨-, proof⟩
  exact True.intro
theorem rcClearTarget (h : True) : h = h := by
  rcases h with -
  exact Eq.refl h
theorem rcQuotedRfl (n m : Nat) (h : n = m) : n = m := by
  rcases h with «rfl»
  rfl
def rcQuotedWildcard (p : Prod Nat Nat) : Nat := by
  rcases p with ⟨«_», value⟩
  exact value

def rcGroupedTarget (p : Prod Nat Nat) : Nat := by
  rcases (p) with ⟨left, right⟩
  exact (right)
def rcCommentArgument (n : Nat) : Nat := by
  obtain value := Nat.succ (/- inside -/ n)
  exact value
theorem rcIntroTyped (n : Nat) : n = n -> n = n := by
  rintro (h : Eq n n)
  exact h
def rcBareApplication (n : Nat) : Nat := by
  rcases Nat.succ n with value
  exact value

theorem rcHEq (n m : Nat) (h : HEq n m) : n = m := by
  rcases h with rfl
  rfl
theorem rcHEqDependent (n m : Nat) (h : HEq n m) (p : h = h) : h = h := by
  rcases h with rfl
  exact p

theorem rcQuot (A : Type) (r : A -> A -> Prop) (q : Quot r) : q = q := by
  rcases q with ⟨representative⟩
  rfl
theorem rcQuotDependent (A : Type) (r : A -> A -> Prop) (q : Quot r) (P : Quot r -> Prop) (h : P q) : P q := by
  rcases q with ⟨representative⟩
  exact h

section
variable (n : Nat) (unused : Bool)
def rcSection (value : Sum Nat Nat) : Nat := by
  rcases value with n | other
  · exact n
  · exact n
partial def rcPartialSection (value : Sum Nat Nat) : Nat := by
  rcases value with n | other
  · exact n
  · exact n
mutual
  partial def rcPartialLeft (value : Sum Nat Nat) : Nat := by
    rcases value with n | other
    · exact n
    · exact n
  partial def rcPartialRight (value : Sum Nat Nat) : Nat :=
    rcPartialLeft value
end
end

def rcGapRCases (n : Nat) : Nat := by
  rcases Nat.succ /- gap -/ (n) with value
  exact value

theorem rcGapRIntro (n : Nat) : n = n -> n = n := by
  rintro (h : Eq /- gap -/ (n) n)
  exact h

def rcGapObtain (n : Nat) : Nat := by
  obtain value := Nat.succ /- gap -/ (n)
  exact value

#guard rcImplicit (RCPack.mk (index := 7) 11) = 11
#guard rcExplicit (RCPack.mk (index := 7) 11) = 7
#guard rcZeroFields Unit.unit = 4
#guard rcComputed 3 = 4
#guard rcComputedName 7 = 8
#guard rcMultiple (3, 5) (7, 11) = 11
#guard rcRetainedLet 13 = 13
#guard rcRIntro (3, 17) = 17
#guard rcIntroGrouped 3 7 = 3
#guard rcIntroNested 5 true = 5
#guard rcObtainComputed 11 = 12
#guard rcObtainMultiple 11 = 13
#guard rcQuotedWildcard (3, 19) = 19
#guard rcGroupedTarget (3, 23) = 23
#guard rcCommentArgument 17 = 18
#guard rcBareApplication 19 = 20
#guard rcSection 11 (Sum.inl 3) = 3
#guard rcSection 11 (Sum.inr 3) = 11
#guard rcPartialSection 11 (Sum.inl 3) = 3
#guard rcPartialSection 11 (Sum.inr 3) = 11
#guard rcPartialRight 11 (Sum.inl 3) = 3
#guard rcPartialRight 11 (Sum.inr 3) = 11

end CoreRCasesOracle

private def requireRCases (condition : Bool) (message : String) : IO Unit :=
  if condition then pure () else throw (IO.userError ("CORE-RCASES: " ++ message))

private def rcasesReplay (declarations : List PsDeclaration) :
    IO Lean.Kernel.Environment := do
  let mut checked := (← Lean.mkEmptyEnvironment 0).toKernelEnv
  requireRCases checked.constants.toList.isEmpty "initial kernel is not empty"
  let mut pending := declarations.reverse
  while !pending.isEmpty do
    let before := pending.length
    let mut deferred : List PsDeclaration := []
    for declaration in pending do
      let attempt ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
        PsKernelLean.tryPreludeDeclaration declarations checked declaration 2000000 20000
      match attempt with
      | .ok (.admitted next) => checked := next
      | .ok .deferred => deferred := declaration :: deferred
      | .error error => throw (IO.userError error.message)
    pending := deferred.reverse
    requireRCases (decide (pending.length < before))
      ("unresolved base dependencies: " ++ String.intercalate ", "
        (pending.map (psNameToString ∘ psDeclarationName)))
  let names := declarations.map (PsKernelLean.toLeanName ∘ psDeclarationName)
  let actual := checked.constants.toList.map Prod.fst
  requireRCases (names.length == names.eraseDups.length &&
      actual.length == names.length && actual.all names.contains)
    "independent base replay has a missing or extra declaration"
  return checked

private def rcasesAdmit (base : Lean.Kernel.Environment) (admissions : String) :
    IO Lean.Kernel.Environment := do
  let declarations ← match PsKernelLean.decodeCanonicalAdmissions admissions with
    | .ok value => pure value
    | .error error => throw (IO.userError error.message)
  let mut checked := base
  for declaration in declarations.toList do
    let attempt ← PsKernelLean.withFreshKernelHeartbeatScope fun _ =>
      checked.addDeclCore 2000000 20000
        (PsKernelLean.psKernelWithDefinitionHeight checked declaration) none
    match attempt with
    | .ok next => checked := next
    | .error error =>
        throw (IO.userError ("CORE-RCASES: kernel rejection: " ++
          PsKernelLean.kernelExceptionSummary error))
  return checked

private structure RCasesFixture where
  label : String
  leanSource : String
  psSource : String
  names : List String
  rich : Bool := false

private structure RCasesRefusal where
  label : String
  leanSource : String
  psSource : String
  expected : String
  rich : Bool := false

private structure RCasesGrammar where
  label : String
  leanSource : String
  psSource : String

private structure RCasesObservation where
  owner : String
  arguments : List PsExpr
  expected : Nat

private def rcNat (value : Nat) : PsExpr := .lit (.natural value)

private def rcPair (left right : Nat) : PsExpr :=
  psExprApplyMany (.constE (psNameAppendStr psProdName "mk") [.zero, .zero])
    [.constE psNatName [], .constE psNatName [], rcNat left, rcNat right]

private def rcPairPack (index value : Nat) : PsExpr :=
  psExprApplyMany (.constE (psNameAppendStr (psRootName "RCPack") "mk") [])
    [rcNat index, rcNat value]

private def rcSum (right : Bool) (value : Nat) : PsExpr :=
  psExprApplyMany (.constE (psNameAppendStr (psRootName "Sum")
    (if right then "inr" else "inl")) [.zero, .zero])
    [.constE psNatName [], .constE psNatName [], rcNat value]

private def observations : List RCasesObservation := [
  { owner := "rcImplicit", arguments := [rcPairPack 7 11], expected := 11 },
  { owner := "rcExplicit", arguments := [rcPairPack 7 11], expected := 7 },
  { owner := "rcZeroFields", arguments := [.constE (psNameAppendStr (psRootName "Unit") "unit") []], expected := 4 },
  { owner := "rcComputed", arguments := [rcNat 3], expected := 4 },
  { owner := "rcComputedName", arguments := [rcNat 7], expected := 8 },
  { owner := "rcMultiple", arguments := [rcPair 3 5, rcPair 7 11], expected := 11 },
  { owner := "rcRetainedLet", arguments := [rcNat 13], expected := 13 },
  { owner := "rcRIntro", arguments := [rcPair 3 17], expected := 17 },
  { owner := "rcIntroGrouped", arguments := [rcNat 3, rcNat 7], expected := 3 },
  { owner := "rcIntroNested", arguments := [rcNat 5, .constE psBoolTrueName []], expected := 5 },
  { owner := "rcObtainComputed", arguments := [rcNat 11], expected := 12 },
  { owner := "rcObtainMultiple", arguments := [rcNat 11], expected := 13 },
  { owner := "rcQuotedWildcard", arguments := [rcPair 3 19], expected := 19 },
  { owner := "rcGroupedTarget", arguments := [rcPair 3 23], expected := 23 },
  { owner := "rcCommentArgument", arguments := [rcNat 17], expected := 18 },
  { owner := "rcBareApplication", arguments := [rcNat 19], expected := 20 },
  { owner := "rcSection", arguments := [rcNat 11, rcSum false 3], expected := 3 },
  { owner := "rcSection", arguments := [rcNat 11, rcSum true 3], expected := 11 } ]

private def rcasesObservationWitness (observation : RCasesObservation) (index : Nat) :
    PsDeclaration :=
  let nat := PsExpr.constE psNatName []
  let value := psExprApplyMany (.constE (psRootName observation.owner) []) observation.arguments
  let expected := rcNat observation.expected
  let type := psExprApplyMany (.constE psEqName [.succ .zero]) [nat, value, expected]
  let proof := psExprApplyMany (.constE (psNameAppendStr psEqName "refl") [.succ .zero])
    [nat, expected]
  .theoremDecl (PsName.num (psNameAppendStr (psRootName observation.owner) "rcasesValue") index)
    [] type proof

private def refusalKind : PsElabError → String
  | .atDeclaration _ error | .atContext _ error => refusalKind error
  | .typeMismatch => "type"
  | .infer .expectedFunction => "infer:function"
  | .infer .applicationTypeMismatch => "infer:application"
  | .scope message => "scope:" ++ message
  | .proof message => "proof:" ++ message
  | .refinement message => "refinement:" ++ message
  | .data message => "data:" ++ message
  | error => psCompilerPscv0ElabError error

private def rcasesFromExcept (result : Except String α) : IO α :=
  match result with
  | .ok value => pure value
  | .error error => throw (IO.userError ("CORE-RCASES: " ++ error))

private def prepareRCases (profile : PsCompilerProfileContext)
    (kind : PsCompilerSourceKind) (source : String) : IO PsCompilerEnginePreparationOutput := do
  let _ ← rcasesFromExcept (psCompilerParsePscv0 source kind)
  rcasesFromExcept ((psCompilerEnginePreparePscv0WithOutput profile kind source).mapError
    psCompilerPscv0Error)

private def checkRCasesRefusal (profile : PsCompilerProfileContext)
    (fixture : RCasesRefusal) (kind : PsCompilerSourceKind) (source : String) : IO Unit := do
  let _ ← rcasesFromExcept ((psCompilerParsePscv0 source kind).mapError
    (fun error => fixture.label ++ " did not parse: " ++ error))
  match psCompilerEnginePreparePscv0WithOutput profile kind source with
  | .error (.elaboration error) =>
    requireRCases (refusalKind error == fixture.expected)
      (fixture.label ++ " refused at wrong owner: " ++ refusalKind error)
  | .error error =>
    throw (IO.userError (fixture.label ++ " refused at wrong phase: " ++ psCompilerPscv0Error error))
  | .ok _ => throw (IO.userError (fixture.label ++ " was incorrectly accepted"))

private def checkRCasesCapture (environment : PsEnvironment) : IO Unit := do
  let nat := PsExpr.constE psNatName []
  let sum := psExprApplyMany (.constE (psRootName "Sum") [.zero, .zero]) [nat, nat]
  let expected := PsExpr.forallE (psRootName "n") nat
    (.forallE (psRootName "value") sum nat .explicit) .explicit
  let owners := ["rcPartialSection", "rcPartialLeft", "rcPartialRight"].map psRootName
  for name in owners do
    let some (.opaqueDecl _ _ type witness) := psEnvironmentFind environment name
      | throw (IO.userError ("CORE-RCASES: partial logical identity is not opaque: " ++ psNameToString name))
    requireRCases (psExprAlphaEq type expected)
      "partial capture dropped the outer branch variable or retained the unused Bool"
    requireRCases (!(owners.any fun owner => psExprHasConst owner witness))
      "partial logical inhabitant depends on a source peer"
    requireRCases (psEnvironmentFind environment (psNameAppendStr name "eq_def")).isNone
      "explicit partial source acquired an equation"
    let some (.partialDecl _ _ bodyType body) := psEnvironmentFind environment (PsName.num name 0)
      | throw (IO.userError "CORE-RCASES: checked partial implementation marker is missing")
    requireRCases (psExprAlphaEq bodyType expected &&
      !psExprHasUnresolvedMeta body && psExprFVarsInContext psLocalEmpty body)
      "partial implementation lost its actual closed section telescope"
  let some (.definitionDecl _ _ type _) := psEnvironmentFind environment (psRootName "rcSection")
    | throw (IO.userError "CORE-RCASES: total section declaration is missing")
  requireRCases (psExprAlphaEq type expected)
    "total section capture differs from the checked partial capture"

private def checkRCasesSourceNames (profile : PsCompilerProfileContext) : IO Nat := do
  let template ← rcasesFromExcept (psCompilerParsePscv0
    "theorem rcNameTemplate : True := by exact True.intro\n" .lean)
  let some (.declaration source) := template.commands.head?
    | throw (IO.userError "CORE-RCASES: source-name template changed")
  let span := (psElabOriginSource source).snd
  let ordinary := PsSyntaxName.mk ["h"] span
  let truth := PsSyntaxTerm.reference (PsSyntaxName.mk ["True"] span)
  let mut controls := 0
  for text in ["_", "rfl", "ordinary"] do
    let forged : PsSyntaxName := { PsSyntaxName.mk [text] span with
      resolvedName := some psNatName }
    let reference := PsSyntaxTerm.reference forged
    let pattern := PsSyntaxRCasesPattern.one forged
    let tactics : List PsSyntaxTactic := [
      .rcasesE [{ term := .reference ordinary, equationName? := some forged }] none span,
      .rcasesE [{ term := reference }] none span,
      .rcasesE [] (some (.tuple [pattern] span)) span,
      .rcasesE [] (some (.typed (.one ordinary) reference span)) span,
      .rintroE [.group [.pattern pattern] none span] none span,
      .rintroE [.pattern (.one ordinary)] (some reference) span,
      .obtainE (some pattern) (some truth) none span,
      .obtainE none (some reference) none span,
      .obtainE none none (some [reference]) span ]
    for tactic in tactics do
      let declaration : PsSyntaxDeclaration := .theoremDecl
        (PsSyntaxName.mk ["rcNameForgery"] span) [] truth (.byE [tactic] {} span) span
      let program := { template with commands := [.declaration declaration] }
      match psCompilerEngineElaboratePscv0 profile program with
      | .error (.elaboration error) =>
        requireRCases (refusalKind error == "scope:source syntax contains an internal resolved name")
          ("source name was refused after its admission boundary: " ++ refusalKind error)
      | .error error =>
        throw (IO.userError ("CORE-RCASES: forged source reached wrong phase: " ++ psCompilerPscv0Error error))
      | .ok _ => throw (IO.userError "CORE-RCASES: forged source name was admitted")
      controls := controls + 1
  return controls

private def printRCasesDeclarations (kind : PsCompilerSourceKind) (program : PsSyntaxProgram) :
    IO String := do
  requireRCases program.imports.isEmpty "declaration printer fixture unexpectedly imports a module"
  let parts ← program.commands.mapM fun command => do
    let .declaration declaration := command
      | throw (IO.userError "CORE-RCASES: declaration printer cannot discard a command")
    let printed := match kind with
      | .lean => psPrintLeanDeclaration declaration
      | .proofScript => psPrintProofScriptDeclaration declaration
    match printed with
    | .ok text => pure text
    | .error _ => throw (IO.userError "CORE-RCASES: recursive elimination declaration printer refused")
  return String.intercalate "\n\n" parts ++ "\n"

private def fixtures : List RCasesFixture := [
  { label := "nested tuples, alternatives, missing fields and duplicate names",
    leanSource := "theorem rcAnd (A B C : Prop) (h : And A (And B C)) : And C A := by\n  rcases h with ⟨ha, hb, hc⟩\n  exact And.intro hc ha\ntheorem rcOr (A B C : Prop) (h : Or A (Or B C)) : Or C (Or B A) := by\n  rcases h with ha | hb | hc\n  · exact Or.inr (Or.inr ha)\n  · exact Or.inr (Or.inl hb)\n  · exact Or.inl hc\ntheorem rcExists (P : Nat -> Prop) (h : Exists (fun n => And (P n) (n = n))) : Exists P := by\n  rcases h with ⟨n, hp, _⟩\n  exact Exists.intro n hp\ntheorem rcMissing (A B : Prop) (h : And A B) : A := by\n  rcases h with ⟨ha⟩\n  exact ha\ntheorem rcDuplicate (h : And True (0 = 0)) : 0 = 0 := by\n  rcases h with ⟨same, same⟩\n  exact same\n",
    psSource := "theorem rcAnd(A: Prop, B: Prop, C: Prop, h: And(A, And(B, C))): And(C, A) := by {\n  rcases h with ⟨ha, hb, hc⟩\n  exact And.intro(hc, ha)\n}\ntheorem rcOr(A: Prop, B: Prop, C: Prop, h: Or(A, Or(B, C))): Or(C, Or(B, A)) := by {\n  rcases h with ha | hb | hc\n  · exact Or.inr(Or.inr(ha))\n  · exact Or.inr(Or.inl(hb))\n  · exact Or.inl(hc)\n}\ntheorem rcExists(P: Nat -> Prop, h: Exists(fun (n: Nat) => And(P(n), n = n))): Exists(P) := by {\n  rcases h with ⟨n, hp, _⟩\n  exact Exists.intro(n, hp)\n}\ntheorem rcMissing(A: Prop, B: Prop, h: And(A, B)): A := by {\n  rcases h with ⟨ha⟩\n  exact ha\n}\ntheorem rcDuplicate(h: And(True, 0 = 0)): 0 = 0 := by {\n  rcases h with ⟨same, same⟩\n  exact same\n}\n",
    names := ["rcAnd", "rcOr", "rcExists", "rcMissing", "rcDuplicate"], rich := false },
  { label := "actual implicit fields, explicit fields and grouped alternatives",
    leanSource := "inductive RCPack : Type where\n  | mk {index : Nat} (value : Nat) : RCPack\ndef rcImplicit (p : RCPack) : Nat := by\n  rcases p with ⟨value⟩\n  exact value\ndef rcExplicit (p : RCPack) : Nat := by\n  rcases p with @⟨index, value⟩\n  exact index\ndef rcZeroFields (p : Unit) : Nat := by\n  rcases p with ⟨unused, remainder⟩\n  exact 4\ntheorem rcGrouped (A B C : Prop) (h : And A (Or B C)) : Or (And A B) (And A C) := by\n  rcases h with ⟨ha, (hb | hc)⟩\n  · exact Or.inl (And.intro ha hb)\n  · exact Or.inr (And.intro ha hc)\n",
    psSource := "inductive RCPack: Type where { | mk{index: Nat}(value: Nat): RCPack }\nfunction rcImplicit(p: RCPack): Nat := by {\n  rcases p with ⟨value⟩\n  exact value\n}\nfunction rcExplicit(p: RCPack): Nat := by {\n  rcases p with @⟨index, value⟩\n  exact index\n}\nfunction rcZeroFields(p: Unit): Nat := by {\n  rcases p with ⟨unused, remainder⟩\n  exact 4\n}\ntheorem rcGrouped(A: Prop, B: Prop, C: Prop, h: And(A, Or(B, C))): Or(And(A, B), And(A, C)) := by {\n  rcases h with ⟨ha, (hb | hc)⟩\n  · exact Or.inl(And.intro(ha, hb))\n  · exact Or.inr(And.intro(ha, hc))\n}\n",
    names := ["RCPack", "rcImplicit", "rcExplicit", "rcZeroFields", "rcGrouped"], rich := false },
  { label := "computed and simultaneous targets with actual equations",
    leanSource := "def rcComputed (n : Nat) : Nat := by\n  rcases (Prod.mk n (Nat.succ n)) with ⟨a, b⟩\n  exact b\ndef rcComputedName (n : Nat) : Nat := by\n  rcases Nat.succ n with value\n  exact value\ndef rcMultiple (left right : Prod Nat Nat) : Nat := by\n  rcases left, right with ⟨⟨a, b⟩, ⟨c, d⟩⟩\n  exact d\ntheorem rcNamed (n : Nat) : True := by\n  rcases equation : Prod.mk n (Nat.succ n) with ⟨a, b⟩\n  have retained : Prod.mk n (Nat.succ n) = Prod.mk a b := equation\n  exact True.intro\n",
    psSource := "function rcComputed(n: Nat): Nat := by {\n  rcases (Prod.mk(n, Nat.succ(n))) with ⟨a, b⟩\n  exact b\n}\nfunction rcComputedName(n: Nat): Nat := by {\n  rcases Nat.succ(n) with value\n  exact value\n}\nfunction rcMultiple(left: Prod(Nat, Nat), right: Prod(Nat, Nat)): Nat := by {\n  rcases left, right with ⟨⟨a, b⟩, ⟨c, d⟩⟩\n  exact d\n}\ntheorem rcNamed(n: Nat): True := by {\n  rcases equation : Prod.mk(n, Nat.succ(n)) with ⟨a, b⟩\n  have retained: Prod.mk(n, Nat.succ(n)) = Prod.mk(a, b) := equation\n  exact True.intro\n}\n",
    names := ["rcComputed", "rcComputedName", "rcMultiple", "rcNamed"], rich := false },
  { label := "retained roots, let roots, no-target and default patterns",
    leanSource := "theorem rcRetained (h : True) : True := by\n  rcases h with ignored\n  exact h\ndef rcRetainedLet (n : Nat) : Nat := by\n  let value : Nat := n\n  rcases value with ignored\n  exact value\ntheorem rcNoTargets : True := by\n  rcases\n  exact True.intro\ntheorem rcDefault (h : False) : True := by\n  rcases h\ndef rcTypedRoot (A : Type) (x : A) : A := by\n  rcases x with (ignored : A)\n  exact x\n",
    psSource := "theorem rcRetained(h: True): True := by {\n  rcases h with ignored\n  exact h\n}\nfunction rcRetainedLet(n: Nat): Nat := by {\n  let value: Nat := n\n  rcases value with ignored\n  exact value\n}\ntheorem rcNoTargets: True := by {\n  rcases\n  exact True.intro\n}\ntheorem rcDefault(h: False): True := by {\n  rcases h\n}\nfunction rcTypedRoot(A: Type, x: A): A := by {\n  rcases x with (ignored : A)\n  exact x\n}\n",
    names := ["rcRetained", "rcRetainedLet", "rcNoTargets", "rcDefault", "rcTypedRoot"], rich := false },
  { label := "rintro continuation, grouped types and nested annotation scope",
    leanSource := "def rcRIntro : Prod Nat Nat -> Nat := by\n  rintro ⟨a, b⟩\n  exact b\ntheorem rcIntroAlternatives (A B C : Prop) : Or A B -> (A -> C) -> (B -> C) -> C := by\n  rintro (ha | hb) left right\n  · exact left ha\n  · exact right hb\ndef rcIntroGrouped : Nat -> Nat -> Nat := by\n  rintro (x y : Nat)\n  exact x\ndef rcIntroNested : Nat -> Bool -> Nat := by\n  rintro ((x : Nat) (flag : Bool))\n  exact x\n",
    psSource := "function rcRIntro: Prod(Nat, Nat) -> Nat := by {\n  rintro ⟨a, b⟩\n  exact b\n}\ntheorem rcIntroAlternatives(A: Prop, B: Prop, C: Prop): Or(A, B) -> (A -> C) -> (B -> C) -> C := by {\n  rintro (ha | hb) left right\n  · exact left(ha)\n  · exact right(hb)\n}\nfunction rcIntroGrouped: Nat -> Nat -> Nat := by {\n  rintro (x y : Nat)\n  exact x\n}\nfunction rcIntroNested: Nat -> Bool -> Nat := by {\n  rintro ((x : Nat) (flag : Bool))\n  exact x\n}\n",
    names := ["rcRIntro", "rcIntroAlternatives", "rcIntroGrouped", "rcIntroNested"], rich := false },
  { label := "obtain values, types, antecedent ordering and simultaneous targets",
    leanSource := "theorem rcObtainValue (A B : Prop) (h : And A B) : B := by\n  obtain ⟨ha, hb⟩ := h\n  exact hb\ntheorem rcObtainAntecedent (A : Prop) (h : A) : A := by\n  obtain witness : A\n  · exact h\n  · exact witness\ntheorem rcObtainDefault (A : Prop) (h : A) : A := by\n  obtain : A\n  · exact h\n  · exact this\ntheorem rcObtainDestruct : True := by\n  obtain ⟨left, right⟩ : And True True\n  · exact And.intro True.intro True.intro\n  · exact right\ndef rcObtainComputed (n : Nat) : Nat := by\n  obtain value : Nat := Nat.succ n\n  exact value\ndef rcObtainMultiple (n : Nat) : Nat := by\n  obtain ⟨a, b⟩ := Nat.succ n, Nat.succ (Nat.succ n)\n  exact b\n",
    psSource := "theorem rcObtainValue(A: Prop, B: Prop, h: And(A, B)): B := by {\n  obtain ⟨ha, hb⟩ := h\n  exact hb\n}\ntheorem rcObtainAntecedent(A: Prop, h: A): A := by {\n  obtain witness: A\n  · exact h\n  · exact witness\n}\ntheorem rcObtainDefault(A: Prop, h: A): A := by {\n  obtain : A\n  · exact h\n  · exact this\n}\ntheorem rcObtainDestruct: True := by {\n  obtain ⟨left, right⟩: And(True, True)\n  · exact And.intro(True.intro, True.intro)\n  · exact right\n}\nfunction rcObtainComputed(n: Nat): Nat := by {\n  obtain value: Nat := Nat.succ(n)\n  exact value\n}\nfunction rcObtainMultiple(n: Nat): Nat := by {\n  obtain ⟨a, b⟩ := Nat.succ(n), Nat.succ(Nat.succ(n))\n  exact b\n}\n",
    names := ["rcObtainValue", "rcObtainAntecedent", "rcObtainDefault", "rcObtainDestruct", "rcObtainComputed", "rcObtainMultiple"], rich := false },
  { label := "checked Eq substitution with dependent proofs and let values",
    leanSource := "theorem rcRflRight (n m : Nat) (h : n = m) (P : Nat -> Prop) (hn : P n) : P m := by\n  rcases h with rfl\n  exact hn\ntheorem rcRflLeft (n m : Nat) (h : n = Nat.succ m) (P : Nat -> Prop) (hm : P (Nat.succ m)) : P n := by\n  rcases h with rfl\n  exact hm\ntheorem rcRflLet (n m : Nat) (h : n = m) : m = n := by\n  let value : Nat := m\n  have retained : value = m := by rfl\n  rcases h with rfl\n  exact retained\ntheorem rcRflProof (n m : Nat) (h : n = m) (p : h = h) : h = h := by\n  rcases h with rfl\n  exact p\ntheorem rcRflReduced (n m : Nat) (h : n = (fun x : Nat => x) m) : n = m := by\n  rcases h with rfl\n  rfl\n",
    psSource := "theorem rcRflRight(n: Nat, m: Nat, h: n = m, P: Nat -> Prop, hn: P(n)): P(m) := by {\n  rcases h with rfl\n  exact hn\n}\ntheorem rcRflLeft(n: Nat, m: Nat, h: n = Nat.succ(m), P: Nat -> Prop, hm: P(Nat.succ(m))): P(n) := by {\n  rcases h with rfl\n  exact hm\n}\ntheorem rcRflLet(n: Nat, m: Nat, h: n = m): m = n := by {\n  let value: Nat := m\n  have retained: value = m := by { rfl }\n  rcases h with rfl\n  exact retained\n}\ntheorem rcRflProof(n: Nat, m: Nat, h: n = m, p: h = h): h = h := by {\n  rcases h with rfl\n  exact p\n}\ntheorem rcRflReduced(n: Nat, m: Nat, h: n = (fun (x: Nat) => x)(m)): n = m := by {\n  rcases h with rfl\n  rfl\n}\n",
    names := ["rcRflRight", "rcRflLeft", "rcRflLet", "rcRflProof", "rcRflReduced"], rich := false },
  { label := "deferred clears and escaped special-name identity",
    leanSource := "theorem rcClearField (A : Prop) (h : And A A) : A := by\n  rcases h with ⟨-, kept⟩\n  exact kept\ntheorem rcClearDependent (h : Exists (fun n : Nat => n = n)) : True := by\n  rcases h with ⟨-, proof⟩\n  exact True.intro\ntheorem rcClearTarget (h : True) : h = h := by\n  rcases h with -\n  exact Eq.refl h\ntheorem rcQuotedRfl (n m : Nat) (h : n = m) : n = m := by\n  rcases h with «rfl»\n  rfl\ndef rcQuotedWildcard (p : Prod Nat Nat) : Nat := by\n  rcases p with ⟨«_», value⟩\n  exact value\n",
    psSource := "theorem rcClearField(A: Prop, h: And(A, A)): A := by {\n  rcases h with ⟨-, kept⟩\n  exact kept\n}\ntheorem rcClearDependent(h: Exists(fun (n: Nat) => n = n)): True := by {\n  rcases h with ⟨-, proof⟩\n  exact True.intro\n}\ntheorem rcClearTarget(h: True): h = h := by {\n  rcases h with -\n  exact Eq.refl(h)\n}\ntheorem rcQuotedRfl(n: Nat, m: Nat, h: n = m): n = m := by {\n  rcases h with «rfl»\n  rfl\n}\nfunction rcQuotedWildcard(p: Prod(Nat, Nat)): Nat := by {\n  rcases p with ⟨«_», value⟩\n  exact value\n}\n",
    names := ["rcClearField", "rcClearDependent", "rcClearTarget", "rcQuotedRfl", "rcQuotedWildcard"], rich := false },
  { label := "shared fresh-term, binder and adjacent-call categories",
    leanSource := "def rcGroupedTarget (p : Prod Nat Nat) : Nat := by\n  rcases (p) with ⟨left, right⟩\n  exact (right)\ndef rcCommentArgument (n : Nat) : Nat := by\n  obtain value := Nat.succ (/- inside -/ n)\n  exact value\ntheorem rcIntroTyped (n : Nat) : n = n -> n = n := by\n  rintro (h : Eq n n)\n  exact h\ndef rcBareApplication (n : Nat) : Nat := by\n  rcases Nat.succ n with value\n  exact value\n",
    psSource := "function rcGroupedTarget(p: Prod(Nat, Nat)): Nat := by {\n  rcases (p) with ⟨left, right⟩\n  exact (right)\n}\nfunction rcCommentArgument(n: Nat): Nat := by {\n  obtain value := Nat.succ(/- inside -/ n)\n  exact value\n}\ntheorem rcIntroTyped(n: Nat): n = n -> n = n := by {\n  rintro (h : Eq(n, n))\n  exact h\n}\nfunction rcBareApplication(n: Nat): Nat := by {\n  rcases Nat.succ n with value\n  exact value\n}\n",
    names := ["rcGroupedTarget", "rcCommentArgument", "rcIntroTyped", "rcBareApplication"], rich := false },
  { label := "full checked proof context: homogeneous HEq and proof-dependent preservation",
    leanSource := "theorem rcHEq (n m : Nat) (h : HEq n m) : n = m := by\n  rcases h with rfl\n  rfl\ntheorem rcHEqDependent (n m : Nat) (h : HEq n m) (p : h = h) : h = h := by\n  rcases h with rfl\n  exact p\n",
    psSource := "theorem rcHEq(n: Nat, m: Nat, h: HEq(n, m)): n = m := by {\n  rcases h with rfl\n  rfl\n}\ntheorem rcHEqDependent(n: Nat, m: Nat, h: HEq(n, m), p: h = h): h = h := by {\n  rcases h with rfl\n  exact p\n}\n",
    names := ["rcHEq", "rcHEqDependent"], rich := true },
  { label := "full checked proof context: actual quotient induction and dependent hypotheses",
    leanSource := "theorem rcQuot (A : Type) (r : A -> A -> Prop) (q : Quot r) : q = q := by\n  rcases q with ⟨representative⟩\n  rfl\ntheorem rcQuotDependent (A : Type) (r : A -> A -> Prop) (q : Quot r) (P : Quot r -> Prop) (h : P q) : P q := by\n  rcases q with ⟨representative⟩\n  exact h\n",
    psSource := "theorem rcQuot(A: Type, r: A -> A -> Prop, q: Quot(r)): q = q := by {\n  rcases q with ⟨representative⟩\n  rfl\n}\ntheorem rcQuotDependent(A: Type, r: A -> A -> Prop, q: Quot(r), P: Quot(r) -> Prop, h: P(q)): P(q) := by {\n  rcases q with ⟨representative⟩\n  exact h\n}\n",
    names := ["rcQuot", "rcQuotDependent"], rich := true },
  { label := "full checked P0 context: section capture survives branch shadowing",
    leanSource := "section\nvariable (n : Nat) (unused : Bool)\ndef rcSection (value : Sum Nat Nat) : Nat := by\n  rcases value with n | other\n  · exact n\n  · exact n\npartial def rcPartialSection (value : Sum Nat Nat) : Nat := by\n  rcases value with n | other\n  · exact n\n  · exact n\nmutual\n  partial def rcPartialLeft (value : Sum Nat Nat) : Nat := by\n    rcases value with n | other\n    · exact n\n    · exact n\n  partial def rcPartialRight (value : Sum Nat Nat) : Nat :=\n    rcPartialLeft value\nend\nend\n",
    psSource := "section\nvariable(n: Nat, unused: Bool)\nfunction rcSection(value: Sum(Nat, Nat)): Nat := by {\n  rcases value with n | other\n  · exact n\n  · exact n\n}\npartial function rcPartialSection(value: Sum(Nat, Nat)): Nat := by {\n  rcases value with n | other\n  · exact n\n  · exact n\n}\nmutual {\n  partial function rcPartialLeft(value: Sum(Nat, Nat)): Nat := by {\n    rcases value with n | other\n    · exact n\n    · exact n\n  }\n  partial function rcPartialRight(value: Sum(Nat, Nat)): Nat := rcPartialLeft(value)\n}\nend\n",
    names := ["rcSection", "rcPartialSection", "rcPartialLeft", "rcPartialRight"], rich := true } ]

private def refusals : List RCasesRefusal := [
  { label := "retained root is not renamed",
    leanSource := "theorem bad (h : True) : True := by\n  rcases h with ignored\n  exact ignored\n",
    psSource := "theorem bad(h: True): True := by {\n  rcases h with ignored\n  exact ignored\n}\n",
    expected := "scope:unknown name ignored", rich := false },
  { label := "obtain retained root is not renamed",
    leanSource := "theorem bad (h : True) : True := by\n  obtain ignored := h\n  exact ignored\n",
    psSource := "theorem bad(h: True): True := by {\n  obtain ignored := h\n  exact ignored\n}\n",
    expected := "scope:unknown name ignored", rich := false },
  { label := "anonymous quoted field is inaccessible",
    leanSource := "def bad (p : Prod Nat Nat) : Nat := by\n  rcases p with ⟨«_», value⟩\n  exact «_»\n",
    psSource := "function bad(p: Prod(Nat, Nat)): Nat := by {\n  rcases p with ⟨«_», value⟩\n  exact «_»\n}\n",
    expected := "scope:unknown name _", rich := false },
  { label := "alternative names remain branch-local",
    leanSource := "theorem bad (h : Or True True) : True := by\n  rcases h with left | right\n  · exact left\n  · exact left\n",
    psSource := "theorem bad(h: Or(True, True)): True := by {\n  rcases h with left | right\n  · exact left\n  · exact left\n}\n",
    expected := "scope:unknown name left", rich := false },
  { label := "cleared independent proof is unavailable",
    leanSource := "theorem bad (h : True) : True := by\n  rcases h with -\n  exact h\n",
    psSource := "theorem bad(h: True): True := by {\n  rcases h with -\n  exact h\n}\n",
    expected := "scope:unknown name h", rich := false },
  { label := "typed pattern checks actual type",
    leanSource := "theorem bad (h : True) : True := by\n  rcases h with (ignored : False)\n  exact True.intro\n",
    psSource := "theorem bad(h: True): True := by {\n  rcases h with (ignored : False)\n  exact True.intro\n}\n",
    expected := "type", rich := false },
  { label := "noninductive scrutinee cannot be destructured",
    leanSource := "theorem bad (f : Nat -> Nat) : True := by\n  rcases f with ⟨value⟩\n  exact True.intro\n",
    psSource := "theorem bad(f: Nat -> Nat): True := by {\n  rcases f with ⟨value⟩\n  exact True.intro\n}\n",
    expected := "proof:rcases pattern requires an inductive datatype", rich := false },
  { label := "rfl needs an equality",
    leanSource := "theorem bad (h : True) : True := by\n  rcases h with rfl\n  exact True.intro\n",
    psSource := "theorem bad(h: True): True := by {\n  rcases h with rfl\n  exact True.intro\n}\n",
    expected := "refinement:expected an index equality", rich := false },
  { label := "rfl needs a variable side",
    leanSource := "theorem bad (h : (0 : Nat) = 1) : True := by\n  rcases h with rfl\n  exact True.intro\n",
    psSource := "theorem bad(h: (0: Nat) = 1): True := by {\n  rcases h with rfl\n  exact True.intro\n}\n",
    expected := "proof:rfl pattern requires an equality with a variable side", rich := false },
  { label := "rfl cyclic substitution",
    leanSource := "theorem bad (n : Nat) (h : n = n) : True := by\n  rcases h with rfl\n  exact True.intro\n",
    psSource := "theorem bad(n: Nat, h: n = n): True := by {\n  rcases h with rfl\n  exact True.intro\n}\n",
    expected := "proof:rfl pattern substitution would be cyclic", rich := false },
  { label := "rfl reduced proof with dependents",
    leanSource := "theorem bad (n m : Nat) (h : n = (fun x : Nat => x) m) (p : h = h) : True := by\n  rcases h with rfl\n  exact True.intro\n",
    psSource := "theorem bad(n: Nat, m: Nat, h: n = (fun (x: Nat) => x)(m), p: h = h): True := by {\n  rcases h with rfl\n  exact True.intro\n}\n",
    expected := "proof:rfl pattern cannot clear a reduced equality with dependents", rich := false },
  { label := "rintro needs an actual binder",
    leanSource := "theorem bad : True := by\n  rintro value\n  exact True.intro\n",
    psSource := "theorem bad: True := by {\n  rintro value\n  exact True.intro\n}\n",
    expected := "infer:function", rich := false },
  { label := "obtain needs a type or value",
    leanSource := "theorem bad : True := by\n  obtain\n  exact True.intro\n",
    psSource := "theorem bad: True := by {\n  obtain\n  exact True.intro\n}\n",
    expected := "proof:obtain requires an expected type or a value", rich := false },
  { label := "homogeneous conversion cannot erase a type mismatch",
    leanSource := "theorem bad (A B : Type) (a : A) (b : B) (h : HEq a b) : True := by\n  rcases h with rfl\n  exact True.intro\n",
    psSource := "theorem bad(A: Type, B: Type, a: A, b: B, h: HEq(a, b)): True := by {\n  rcases h with rfl\n  exact True.intro\n}\n",
    expected := "refinement:preceding index constraints did not align heterogeneous types", rich := true },
  { label := "quotient representative cannot escape to data",
    leanSource := "def bad (A : Type) (r : A -> A -> Prop) (q : Quot r) : A := by\n  rcases q with ⟨value⟩\n  exact value\n",
    psSource := "function bad(A: Type, r: A -> A -> Prop, q: Quot(r)): A := by {\n  rcases q with ⟨value⟩\n  exact value\n}\n",
    expected := "proof:rcases quotient elimination requires a proposition", rich := true } ]

private def grammarRefusals : List RCasesGrammar := [
  { label := "empty rintro",
    leanSource := "theorem bad : True := by\n  rintro\n",
    psSource := "theorem bad: True := by { rintro }\n" },
  { label := "space after explicit marker",
    leanSource := "theorem bad (h : And True True) : True := by\n  rcases h with @ ⟨left, right⟩\n",
    psSource := "theorem bad(h: And(True, True)): True := by { rcases h with @ ⟨left, right⟩ }\n" },
  { label := "empty alternative",
    leanSource := "theorem bad (h : Or True True) : True := by\n  rcases h with left |\n",
    psSource := "theorem bad(h: Or(True, True)): True := by { rcases h with left | }\n" },
  { label := "unclosed tuple",
    leanSource := "theorem bad (h : And True True) : True := by\n  rcases h with ⟨left, right\n",
    psSource := "theorem bad(h: And(True, True)): True := by { rcases h with ⟨left, right }\n" },
  { label := "obtain assignment without value",
    leanSource := "theorem bad : True := by\n  obtain :=\n",
    psSource := "theorem bad: True := by { obtain := }\n" } ]

private def applicationGaps : List RCasesGrammar := [
  { label := "rcases target",
    leanSource := "def rcGapRCases (n : Nat) : Nat := by\n  rcases Nat.succ /- gap -/ (n) with value\n  exact value\n",
    psSource := "function rcGapRCases(n: Nat): Nat := by {\n  rcases Nat.succ /- gap -/ (n) with value\n  exact value\n}\n" },
  { label := "rintro annotation",
    leanSource := "theorem rcGapRIntro (n : Nat) : n = n -> n = n := by\n  rintro (h : Eq /- gap -/ (n) n)\n  exact h\n",
    psSource := "theorem rcGapRIntro(n: Nat): n = n -> n = n := by {\n  rintro (h : Eq /- gap -/ (n) n)\n  exact h\n}\n" },
  { label := "obtain value",
    leanSource := "def rcGapObtain (n : Nat) : Nat := by\n  obtain value := Nat.succ /- gap -/ (n)\n  exact value\n",
    psSource := "function rcGapObtain(n: Nat): Nat := by {\n  obtain value := Nat.succ /- gap -/ (n)\n  exact value\n}\n" } ]

private def expectNativeRCasesRefusal (label source : String) :
    Lean.Elab.Command.CommandElabM Unit := do
  let command ← match Lean.Parser.runParserCategory (← Lean.getEnv) (Lean.Name.mkSimple "command") source with
    | .ok command => pure command
    | .error message => throwError "native rcases semantic control did not parse ({label}): {message}"
  let saved ← get
  let refused ← try
    modify fun (state : Lean.Elab.Command.State) =>
      { state with messages := Lean.MessageLog.empty, snapshotTasks := #[] }
    let messages ← Lean.Elab.Tactic.GuardMsgs.runAndCollectMessages command
    let errors := messages.toList.filter fun message => message.severity == .error
    for message in errors do
      let content ← message.data.toString
      if ["heartbeat", "recursion depth", "maximum recursion", "timeout"].any
          (fun word => (content.splitOn word).length > 1) then
        throwError "native rcases refusal exhausted resources ({label}): {content}"
    pure (!errors.isEmpty)
  finally
    set saved
  unless refused do throwError "native rcases semantic refusal was accepted: {label}"

private def expectNativeRCasesGrammar (label source : String) :
    Lean.Elab.Command.CommandElabM Unit := do
  match Lean.Parser.runParserCategory (← Lean.getEnv) (Lean.Name.mkSimple "command") source with
  | .error message =>
    if ["heartbeat", "recursion depth", "maximum recursion", "timeout"].any
        (fun word => (message.splitOn word).length > 1) then
      throwError "native rcases parser control exhausted resources ({label}): {message}"
  | .ok _ => throwError "native rcases grammar refusal parsed: {label}"

run_cmd do
  for fixture in refusals do
    expectNativeRCasesRefusal fixture.label fixture.leanSource
  for fixture in grammarRefusals do
    expectNativeRCasesGrammar fixture.label fixture.leanSource

private def checkRCasesParserRefusal (kind : PsCompilerSourceKind)
    (label source : String) (expected : Option String := none) : IO Unit := do
  match psCompilerParsePscv0 source kind with
  | .error error =>
    requireRCases (!( ["resource", "budget", "heartbeat", "recursion depth", "timeout"].any
      fun word => (error.splitOn word).length > 1))
      (label ++ " exhausted parser resources")
    for expected in expected.toList do
      requireRCases ((error.splitOn expected).length > 1)
        (label ++ " refused at wrong parser boundary: " ++ error)
  | .ok _ => throw (IO.userError ("CORE-RCASES: grammar refusal parsed: " ++ label))

private def checkRCasesPrinterBoundary (profile : PsCompilerProfileContext) : IO Nat := do
  let sources : List (Bool × String) := [
    (false, "namespace RCPrint\ntheorem keep (h : True) : True := by\n  rcases h with ignored\n  exact h\nend RCPrint\n"),
    (true, "namespace RCPrint\ntheorem keep(h: True): True := by {\n  rcases h with ignored\n  exact h\n}\nend RCPrint\n"),
    (false, "#check Nat\ntheorem rcPrintKeep (h : True) : True := by\n  rcases h with ignored\n  exact h\n"),
    (true, "#check Nat\ntheorem rcPrintKeep(h: True): True := by {\n  rcases h with ignored\n  exact h\n}\n") ]
  let mut controls := 0
  for (sourceIsPs, source) in sources do
    let kind := if sourceIsPs then PsCompilerSourceKind.proofScript else .lean
    let _ ← prepareRCases profile kind source
    for targetIsPs in [false, true] do
      match psPscv0TranslateReadable sourceIsPs targetIsPs source with
      | .error error =>
        requireRCases (!( ["resource", "budget", "heartbeat", "recursion depth", "timeout"].any
          fun word => (error.splitOn word).length > 1))
          "declaration-only printer exhausted resources"
      | .ok _ =>
        throw (IO.userError "CORE-RCASES: declaration-only printer discarded a scope/inspection command")
      controls := controls + 1
  return controls

def main : IO Unit := do
  requireRCases (Lean.versionString == "4.35.0" &&
    Lean.githash == "eb6cafb7290e8bd5f2937522d8d804f58f02bafc") "native pin changed"
  let foundation ← rcasesFromExcept psCompilerSourceCandidateEnvironment
  let declarations := psCoreFoundationCandidateDeclarations
  requireRCases (declarations.length == 92 && foundation.declarations.length == 92)
    "Foundation context roster changed"
  requireRCases (!(declarations.any fun declaration =>
    match declaration with | .axiomDecl .. | .partialDecl .. => true | _ => false))
    "Foundation context acquired an assumption or partial body"
  let checkedFoundation ← rcasesReplay declarations
  let foundationProfile : PsCompilerProfileContext := {
    baseEnvironment := foundation, runtimePrelude := fun _ _ => [] }
  -- The three explicit rich-context groups exercise HEq conversion, quotient
  -- primitives and the existing P0 Inhabited policy. They do not qualify the
  -- pending complete Core library profile. Source admission remains 2M/20k.
  let checkedRich ← rcasesFromExcept ((← PsKernelLean.buildLeanPreludeEnvironment).mapError
    (fun error => error.kind.code ++ ": " ++ error.message))
  let mut records : List Lean.Json := []
  let mut witnessedValues := 0
  let mut printedPairs := 0
  for fixture in fixtures do
    let profile := if fixture.rich then psCompilerFullProfileContext else foundationProfile
    let checkedBase := if fixture.rich then checkedRich else checkedFoundation
    let partialFixture := fixture.names.contains "rcPartialSection"
    let mut outputs : List PsCompilerEnginePreparationOutput := []
    IO.println ("CORE-RCASES: checking " ++ fixture.label)
    for (kind, source) in [(PsCompilerSourceKind.lean, fixture.leanSource),
        (.proofScript, fixture.psSource)] do
      let program ← rcasesFromExcept ((psCompilerParsePscv0 source kind).mapError
        (fun error => fixture.label ++ ": " ++ error))
      let elaborated ← rcasesFromExcept ((psCompilerEngineElaboratePscv0 profile program).mapError
        (fun error => fixture.label ++ ": " ++ psCompilerPscv0Error error))
      if partialFixture then checkRCasesCapture elaborated.environment
      let output ← rcasesFromExcept ((psCompilerEnginePrepareElaboratedWithOutput elaborated).mapError
        (fun error => fixture.label ++ ": " ++ psCompilerPscv0Error error))
      requireRCases (psStandardSnapshotPayload output.prepared.profile.baseEnvironment ==
        psStandardSnapshotPayload profile.baseEnvironment) "caller context changed"
      requireRCases (!(output.prepared.declarations.any fun declaration =>
        match declaration with | .axiomDecl .. => true | _ => false))
        (fixture.label ++ " introduced an axiom")
      let partials := output.prepared.declarations.filter fun declaration =>
        match declaration with | .partialDecl .. => true | _ => false
      requireRCases (partials.length == (if partialFixture then 3 else 0))
        (fixture.label ++ " changed the explicit source partial roster")
      requireRCases output.prepared.noncomputableNames.isEmpty
        (fixture.label ++ " introduced noncomputable execution")
      let canonical ← rcasesFromExcept
        ((psCompilerEngineAdmissionsFromPrepared output.prepared).mapError psCompilerPscv0Error)
      requireRCases (canonical == output.admissions) "canonical admissions changed"
      let admitted ← rcasesAdmit checkedBase output.admissions
      for name in fixture.names do
        requireRCases (output.prepared.declarations.any fun declaration =>
          psNameEq (psDeclarationName declaration) (psRootName name))
          (fixture.label ++ " missing prepared declaration " ++ name)
        requireRCases (admitted.find? (PsKernelLean.toLeanName (psRootName name))).isSome
          (fixture.label ++ " missing independently admitted declaration " ++ name)
      let selectedObservations := observations.filter fun observation =>
        fixture.names.contains observation.owner
      let mut witnesses : List PsDeclaration := []
      for (observation, index) in selectedObservations.zipIdx do
        let value := psExprApplyMany (.constE (psRootName observation.owner) []) observation.arguments
        requireRCases (psDefEqReadOnlyWithEnv output.environment psMetaEmpty psLocalEmpty
          value (rcNat observation.expected))
          (fixture.label ++ " portable value differs: " ++ observation.owner)
        witnesses := witnesses ++ [rcasesObservationWitness observation index]
      if !witnesses.isEmpty then
        let witnessAdmissions ← rcasesFromExcept
          ((psEncodeCheckedAdmissionsCanonicalIn output.environment witnesses).mapError
            (fun _ => fixture.label ++ " value witness codec refused"))
        let checkedValues ← rcasesAdmit admitted witnessAdmissions
        for witness in witnesses do
          requireRCases (checkedValues.find?
            (PsKernelLean.toLeanName (psDeclarationName witness))).isSome
            "independent value witness is missing"
        witnessedValues := witnessedValues + witnesses.length
      if !fixture.rich then
        for printedKind in [PsCompilerSourceKind.lean, .proofScript] do
          let printed ← printRCasesDeclarations printedKind program
          let roundtrip ← prepareRCases profile printedKind printed
          requireRCases (roundtrip.admissions == output.admissions)
            (fixture.label ++ " declaration printer changed canonical semantics")
          printedPairs := printedPairs + 1
      outputs := outputs ++ [output]
    let [leanOutput, psOutput] := outputs
      | throw (IO.userError "CORE-RCASES: paired result count changed")
    requireRCases (leanOutput.admissions == psOutput.admissions)
      (fixture.label ++ " selected canonical pair differs")
    records := records ++ [Lean.Json.mkObj [
      ("label", Lean.toJson fixture.label),
      ("context", Lean.toJson (if fixture.rich then "explicit-full" else "foundation-92")),
      ("leanSourceSHA256", Lean.toJson (psStandardSnapshotSHA256 fixture.leanSource)),
      ("proofScriptSourceSHA256", Lean.toJson (psStandardSnapshotSHA256 fixture.psSource)),
      ("preparedDeclarations", Lean.toJson leanOutput.prepared.declarations.length),
      ("canonicalBytes", Lean.toJson leanOutput.admissions.utf8ByteSize),
      ("canonicalSHA256", Lean.toJson (psStandardSnapshotSHA256 leanOutput.admissions)),
      ("canonicalPairEqual", Lean.toJson true),
      ("independentlyAdmitted", Lean.toJson true)]]
  for fixture in refusals do
    let profile := if fixture.rich then psCompilerFullProfileContext else foundationProfile
    checkRCasesRefusal profile fixture .lean fixture.leanSource
    checkRCasesRefusal profile fixture .proofScript fixture.psSource
  for fixture in grammarRefusals do
    checkRCasesParserRefusal .lean fixture.label fixture.leanSource
    checkRCasesParserRefusal .proofScript fixture.label fixture.psSource
  for fixture in applicationGaps do
    let output ← prepareRCases foundationProfile .lean fixture.leanSource
    let _ ← rcasesAdmit checkedFoundation output.admissions
    checkRCasesParserRefusal .proofScript fixture.label fixture.psSource (some "PSCV0-APP-02")
  let sourceNameRefusals ← checkRCasesSourceNames foundationProfile
  let printerBoundaryRefusals ← checkRCasesPrinterBoundary foundationProfile
  requireRCases (fixtures.length == 12 && refusals.length == 15 && grammarRefusals.length == 5 &&
    applicationGaps.length == 3 && observations.length == 18 && witnessedValues == 36 &&
    printedPairs == 36 && sourceNameRefusals == 27 && printerBoundaryRefusals == 8)
    "qualification roster changed"
  IO.println (Lean.Json.mkObj [
    ("schema", Lean.toJson ("pscv0-core-rcases-qualification/1" : String)),
    ("nativeVersion", Lean.toJson Lean.versionString),
    ("nativeCommit", Lean.toJson Lean.githash),
    ("foundationDeclarations", Lean.toJson declarations.length),
    ("foundationPayloadSHA256", Lean.toJson (psStandardSnapshotSHA256 (psStandardSnapshotPayload foundation))),
    ("foundationAxioms", Lean.toJson ([] : List String)),
    ("kernelTrustLevel", Lean.toJson (0 : Nat)),
    ("maxHeartbeatsPerSourceDeclaration", Lean.toJson (2000000 : Nat)),
    ("maxRecDepthPerSourceDeclaration", Lean.toJson (20000 : Nat)),
    ("foundationSourceProjects", Lean.toJson (18 : Nat)),
    ("explicitFullContextSourceProjects", Lean.toJson (6 : Nat)),
    ("ownedSemanticRefusals", Lean.toJson (2 * refusals.length)),
    ("pairedGrammarRefusals", Lean.toJson (2 * grammarRefusals.length)),
    ("nativeSemanticRefusals", Lean.toJson refusals.length),
    ("nativeGrammarRefusals", Lean.toJson grammarRefusals.length),
    ("application02Refusals", Lean.toJson applicationGaps.length),
    ("nativeValueObservations", Lean.toJson (22 : Nat)),
    ("portableValueObservations", Lean.toJson witnessedValues),
    ("independentValueWitnesses", Lean.toJson witnessedValues),
    ("declarationPrinterRoundtrips", Lean.toJson printedPairs),
    ("declarationOnlyPrinterBoundaryRefusals", Lean.toJson printerBoundaryRefusals),
    ("forgedSourceNameRefusals", Lean.toJson sourceNameRefusals),
    ("cases", Lean.Json.arr records.toArray),
    ("completeCoreProfileQualified", Lean.toJson false),
    ("backendExecutionQualified", Lean.toJson false),
    ("compilerSelfhostQualified", Lean.toJson false)]).compress
  IO.println "PSCV0_CORE_RCASES: PASS 12 source pairs, finite fresh kernel admissions, 30 owned semantic refusals, 10 grammar refusals, 3 APP02 refusals, 22 native values, 36 independently checked value witnesses, both declaration printers, and 27 source-name boundary controls"
