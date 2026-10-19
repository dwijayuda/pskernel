/-
Selected Fin equality evidence, following Lean 4.35.0 Init/Prelude.lean
at eb6cafb7290e8bd5f2937522d8d804f58f02bafc (Fin.eq_of_val_eq,
Fin.val_eq_of_eq and instDecidableEqFin), and Init/Core.lean LawfulBEq.
Copyright (c) Microsoft Corporation. Apache-2.0; see THIRD_PARTY_NOTICES.md.
The decision retains the actual Nat decision Bool; bounds proofs are erased.
All equality evidence is constructed with the checked Fin and Eq recursors.
-/
import Ps.Environment.StandardFin
import Ps.Environment.StandardRepr

def psStandardFinEqualityDeclarations : List PsDeclaration :=
  let nat := psOrderNat
  let level := PsLevel.succ .zero
  let n := PsExpr.fvar 0
  let left := PsExpr.fvar 1
  let right := PsExpr.fvar 2
  let proof := PsExpr.fvar 3
  let fin := psStandardFinOf n
  let val := fun value => PsExpr.proj (psRootName "Fin") 0 value
  let bound := fun value => psOrderCall "Nat.lt" [value, n]
  let made := fun value evidence => psOrderCall "Fin.mk" [n, value, evidence]
  let eqNat := psLogicEq level nat
  let eqFin := psLogicEq level fin
  let natEquality := eqNat (val left) (val right)
  let finEquality := eqFin left right
  let parameters := fun body =>
    psLogicPi 0 "n" nat (psLogicPi 1 "left" fin
      (psLogicPi 2 "right" fin body .implicit) .implicit) .implicit
  let lambdas := fun body =>
    psLogicLam 0 "n" nat (psLogicLam 1 "left" fin
      (psLogicLam 2 "right" fin body .implicit) .implicit) .implicit
  let leftVal := PsExpr.fvar 4
  let leftBound := PsExpr.fvar 5
  let rightVal := PsExpr.fvar 6
  let rightBound := PsExpr.fvar 7
  let newVal := PsExpr.fvar 8
  let newBound := PsExpr.fvar 10
  let madeLeft := made leftVal leftBound
  let transportMotive := psLogicLam 8 "value" nat
    (psLogicLam 9 "equal" (eqNat leftVal newVal)
      (psLogicPi 10 "bound" (bound newVal)
        (eqFin madeLeft (made newVal newBound))))
  let transportBase := psLogicLam 10 "bound" (bound leftVal)
    (psLogicRefl level fin madeLeft)
  let transported := psLogicApply (.constE (psDecisionName "Eq.rec") [.zero, level])
    [nat, leftVal, transportMotive, transportBase, rightVal, proof, rightBound]
  let rightMotive := psLogicLam 2 "right" fin
    (psLogicPi 3 "equal" (eqNat leftVal (val right)) (eqFin madeLeft right))
  let rightMinor := psLogicLam 6 "value" nat
    (psLogicLam 7 "bound" (bound rightVal)
      (psLogicLam 3 "equal" (eqNat leftVal rightVal) transported))
  let rightCases := psLogicApply (.constE (psDecisionName "Fin.rec") [.zero])
    [n, rightMotive, rightMinor, right]
  let leftMotive := psLogicLam 1 "left" fin
    (psLogicPi 2 "right" fin
      (psLogicPi 3 "equal" natEquality finEquality) .implicit)
  let leftMinor := psLogicLam 4 "value" nat
    (psLogicLam 5 "bound" (bound leftVal)
      (psLogicLam 2 "right" fin rightCases .implicit))
  let fromValues := psLogicApply (.constE (psDecisionName "Fin.rec") [.zero])
    [n, leftMotive, leftMinor, left]
  let equalityMotive := psLogicLam 8 "right" fin
    (psLogicLam 9 "equal" (eqFin left (.fvar 8))
      (eqNat (val left) (val (.fvar 8))))
  let toValues := psLogicApply (.constE (psDecisionName "Eq.rec") [.zero, level])
    [fin, left, equalityMotive, psLogicRefl level nat (val left), right, proof]
  [ .definitionDecl (psDecisionName "PsStandard.finEqOfValEq") []
      (parameters (psLogicPi 3 "equal" natEquality finEquality))
      (psLogicLam 0 "n" nat
        (psLogicLam 1 "left" fin fromValues .implicit) .implicit),
    .definitionDecl (psDecisionName "PsStandard.finValEqOfEq") []
      (parameters (psLogicPi 3 "equal" finEquality natEquality))
      (lambdas (psLogicLam 3 "equal" finEquality toValues)) ]

def psStandardFinDecEqDeclarations : List PsDeclaration :=
  let nat := psOrderNat
  let bool := PsExpr.constE psBoolName []
  let level := PsLevel.succ .zero
  let n := PsExpr.fvar 0
  let left := PsExpr.fvar 1
  let right := PsExpr.fvar 2
  let fin := psStandardFinOf n
  let val := fun value => PsExpr.proj (psRootName "Fin") 0 value
  let oldProp := psLogicEq level nat (val left) (val right)
  let newProp := psLogicEq level fin left right
  let decision := psOrderCall "Nat.decEq" [val left, val right]
  let flag := PsExpr.proj psDecidableName 0 decision
  let evidence := PsExpr.proj psDecidableName 1 decision
  let motive := psLogicLam 4 "flag" bool
    (psLogicPi 5 "evidence" (psDecisionReflects (.fvar 4) oldProp)
      (psDecisionReflects (.fvar 4) newProp))
  let positive := psLogicLam 5 "equal" oldProp
    (psOrderCall "PsStandard.finEqOfValEq" [n, left, right, .fvar 5])
  let negative := psLogicLam 5 "different" (psDecisionNot oldProp)
    (psLogicLam 6 "equal" newProp
      (.app (.fvar 5) (psOrderCall "PsStandard.finValEqOfEq"
        [n, left, right, .fvar 6])))
  let reflection := psLogicApply (.constE (psDecisionName "Bool.rec") [.zero])
    [motive, negative, positive, flag, evidence]
  let value := psOrderCall "Decidable.intro" [newProp, flag, reflection]
  [ .definitionDecl (psDecisionName "PsStandard.instDecidableEqFin") []
      (psLogicPi 0 "n" nat
        (.app (.constE (psRootName "DecidableEq") [level]) fin))
      (psLogicLam 0 "n" nat
        (psLogicLam 1 "left" fin (psLogicLam 2 "right" fin value))) ]

def psStandardFinLawfulBEqDeclarations : List PsDeclaration :=
  let nat := psOrderNat
  let level := PsLevel.succ .zero
  let n := PsExpr.fvar 0
  let left := PsExpr.fvar 1
  let right := PsExpr.fvar 2
  let fin := psStandardFinOf n
  let dictionary := psOrderCall "PsStandard.instBEqFin" [n]
  let val := fun value => PsExpr.proj (psRootName "Fin") 0 value
  let comparison := psOrderCall "Nat.beq" [val left, val right]
  let evidenceType := psLogicEq level (.constE psBoolName []) comparison
    (.constE psBoolTrueName [])
  let reflexivity := psLogicLam 1 "value" fin
    (psOrderCall "Nat.beq_refl" [val left]) .implicit
  let parent := psLogicApply (.constE (psDecisionName "ReflBEq.mk") [.zero])
    [fin, dictionary, reflexivity]
  let equality := psLogicLam 1 "left" fin
    (psLogicLam 2 "right" fin
      (psLogicLam 3 "equal" evidenceType
        (psOrderCall "PsStandard.finEqOfValEq" [n, left, right,
          psOrderCall "Nat.eq_of_beq_eq_true" [val left, val right, .fvar 3]]))
      .implicit) .implicit
  let type := psLogicApply (.constE (psRootName "LawfulBEq") [.zero]) [fin, dictionary]
  let value := psLogicApply (.constE (psDecisionName "LawfulBEq.mk") [.zero])
    [fin, dictionary, parent, equality]
  [ .definitionDecl (psDecisionName "PsStandard.instLawfulBEqFin") []
      (psLogicPi 0 "n" nat type) (psLogicLam 0 "n" nat value) ]

def psStandardFinEvidenceDeclarations : List PsDeclaration :=
  psStandardFinEqualityDeclarations ++ psStandardFinDecEqDeclarations ++
    psStandardFinLawfulBEqDeclarations

def psStandardFinEvidenceExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardFinEvidenceDeclarations.foldl psPreludeAdd environment
  let environment := psStandardRegisterInstances environment "Decidable" psStandardFinDecEqDeclarations
  psStandardRegisterInstances environment "LawfulBEq" psStandardFinLawfulBEqDeclarations

def psStandardFinEvidenceAudit (environment : PsEnvironment) : Except String Unit := do
  for name in ["Nat.beq_refl", "Nat.eq_of_beq_eq_true"] do
    let some declaration := psEnvironmentFind environment (psDecisionName name)
      | throw ("PSCV0-STANDARD: missing checked Fin equality dependency " ++ name)
    if (psDeclarationValue declaration).isNone then
      throw ("PSCV0-STANDARD: Fin equality dependency has no checked value " ++ name)
  for expected in psStandardFinEvidenceDeclarations do
    let name := psDeclarationName expected
    let some (.definitionDecl _ levels type value) := psEnvironmentFind environment name
      | throw ("PSCV0-STANDARD: missing checked Fin equality declaration " ++ psNameToString name)
    let sameValue := match psDeclarationValue expected with
      | some expected => psExprAlphaEq value expected
      | none => false
    if !levels.isEmpty || !psExprAlphaEq type (psDeclarationType expected) ||
        !sameValue then
      throw ("PSCV0-STANDARD: Fin equality declaration drift " ++ psNameToString name)
  for className in ["Decidable", "LawfulBEq"] do
    if !environment.classes.any (psNameEq (psRootName className)) then
      throw ("PSCV0-STANDARD: missing Fin evidence class " ++ className)
  for declaration in psStandardFinDecEqDeclarations ++ psStandardFinLawfulBEqDeclarations do
    psStandardAuditInstance environment declaration
