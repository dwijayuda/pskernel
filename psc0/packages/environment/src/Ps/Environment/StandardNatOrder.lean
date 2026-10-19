import Ps.Environment.StandardGetElem
import Ps.Environment.ReprExpr

-- Checked natural-order closure for M1. All proof-bearing definitions are
-- ordinary Core terms. Nat.ble keeps its audited efficient runtime intrinsic,
-- but its formerly opaque logical model is now a checked structural definition.
-- Proof reflection is separate from the computational comparison and erased.
def psOrderSucc (n : PsExpr) : PsExpr := .app (.constE psNatSuccName []) n
def psOrderLe (n m : PsExpr) : PsExpr :=
  psLogicApply (.constE (psDecisionName "Nat.le") []) [n, m]
def psOrderRefl (n : PsExpr) : PsExpr := psOrderCall "Nat.le.refl" [n]
def psOrderStep (n m h : PsExpr) : PsExpr := psOrderCall "Nat.le.step" [n, m, h]
def psOrderNatRec (level : PsLevel) (motive zero step major : PsExpr) : PsExpr :=
  psLogicApply (.constE psNatRecName [level]) [motive, zero, step, major]
def psOrderLeRec (n motive refl step m h : PsExpr) : PsExpr :=
  psOrderCall "Nat.le.rec" [n, motive, refl, step, m, h]
def psOrderDecl (name : String) (type value : PsExpr) : PsDeclaration :=
  .definitionDecl (psDecisionName name) [] type value

-- Pinned Prelude.lean defines arithmetic by recursion on the right operand.
-- Retain those open-term equations while native/runtime primitive reductions
-- still handle closed numerals efficiently. Locals 0/1 are operands, 2/3 the
-- predecessor/inductive result, and 4 the unused motive argument.
def psStandardNatBinaryRec (name : String) (zero step : PsExpr) : PsDeclaration :=
  let nat := psOrderNat
  psOrderDecl name (psLogicPi 0 "n" nat (psLogicPi 1 "m" nat nat))
    (psLogicLam 0 "n" nat (psLogicLam 1 "m" nat
      (psOrderNatRec (.succ .zero) (psLogicLam 4 "_" nat nat) zero
        (psLogicLam 2 "previous" nat (psLogicLam 3 "ih" nat step)) (.fvar 1))))

def psStandardNatArithmeticDeclarations : List PsDeclaration :=
  [ psStandardNatBinaryRec "Nat.add" (.fvar 0) (psOrderSucc (.fvar 3)),
    psStandardNatBinaryRec "Nat.sub" (.fvar 0) (psOrderCall "Nat.pred" [.fvar 3]),
    psStandardNatBinaryRec "Nat.mul" (.lit (.natural 0))
      (psOrderCall "Nat.add" [.fvar 3, .fvar 0]) ]

-- Equality's logical model follows the same two-operand constructor equations
-- as the existing comparison model. No Bool-to-proof assumption is introduced.
def psStandardNatBeqDeclaration : PsDeclaration :=
  let nat := psOrderNat
  let bool := PsExpr.constE psBoolName []
  let result := psLogicPi 1 "m" nat bool
  let motive := psLogicLam 4 "_" nat bool
  let yes := PsExpr.constE psBoolTrueName []
  let no := PsExpr.constE psBoolFalseName []
  let zero := psLogicLam 1 "m" nat
    (psOrderNatRec (.succ .zero) motive yes
      (psLogicLam 2 "_" nat (psLogicLam 3 "_" bool no)) (.fvar 1))
  let step := psLogicLam 2 "previous" nat (psLogicLam 3 "ih" result
    (psLogicLam 1 "m" nat (psOrderNatRec (.succ .zero) motive no
      (psLogicLam 5 "previousM" nat (psLogicLam 6 "_" bool
        (.app (.fvar 3) (.fvar 5)))) (.fvar 1))))
  psOrderDecl "Nat.beq" (psLogicPi 0 "n" nat result)
    (psLogicLam 0 "n" nat
      (psOrderNatRec (.succ .zero) (psLogicLam 4 "_" nat result) zero step (.fvar 0)))

def psStandardNatOrderProofDeclarations : List PsDeclaration :=
  let nat := psOrderNat
  let n := PsExpr.fvar 0
  let m := PsExpr.fvar 1
  let h := PsExpr.fvar 2
  let k := PsExpr.fvar 3
  let ih := PsExpr.fvar 4
  let zero := PsExpr.lit (.natural 0)
  let falseType := PsExpr.constE (psRootName "False") []
  let trueType := PsExpr.constE (psRootName "True") []
  let trueIntro := PsExpr.constE (psDecisionName "True.intro") []
  let leMotive := fun body => psLogicLam 1 "m" nat
    (psLogicLam 2 "h" (psOrderLe n m) body)
  let leStep := fun body => psLogicLam 1 "m" nat
    (psLogicLam 2 "h" (psOrderLe n m) body) .implicit
  let twoParams := fun body => psLogicPi 0 "n" nat
    (psLogicPi 1 "m" nat body .implicit) .implicit
  let twoLams := fun body => psLogicLam 0 "n" nat
    (psLogicLam 1 "m" nat body .implicit) .implicit
  let zeroLe := psOrderDecl "Nat.zero_le"
    (psLogicPi 0 "n" nat (psOrderLe zero n))
    (psLogicLam 0 "n" nat
      (psOrderNatRec .zero (psLogicLam 1 "m" nat (psOrderLe zero m))
        (psOrderRefl zero)
        (psLogicLam 1 "m" nat (psLogicLam 4 "ih" (psOrderLe zero m)
          (psOrderStep zero m ih))) n))
  let succLe := psOrderDecl "Nat.succ_le_succ"
    (twoParams (psLogicPi 2 "h" (psOrderLe n m)
      (psOrderLe (psOrderSucc n) (psOrderSucc m))))
    (twoLams (psLogicLam 2 "h" (psOrderLe n m)
      (psOrderLeRec n
        (leMotive (psOrderLe (psOrderSucc n) (psOrderSucc m)))
        (psOrderRefl (psOrderSucc n))
        (leStep (psLogicLam 4 "ih"
          (psOrderLe (psOrderSucc n) (psOrderSucc m))
          (psOrderStep (psOrderSucc n) (psOrderSucc m) ih)))
        m h)))
  let trans := psOrderDecl "Nat.le_trans"
    (twoParams (psLogicPi 3 "k" nat
      (psLogicPi 4 "left" (psOrderLe n m)
        (psLogicPi 5 "right" (psOrderLe m k) (psOrderLe n k))) .implicit))
    (twoLams (psLogicLam 3 "k" nat
      (psLogicLam 4 "left" (psOrderLe n m)
        (psLogicLam 5 "right" (psOrderLe m k)
          (psOrderLeRec m
            (psLogicLam 6 "last" nat
              (psLogicLam 7 "h" (psOrderLe m (.fvar 6))
                (psOrderLe n (.fvar 6))))
            ih
            (psLogicLam 6 "last" nat
              (psLogicLam 7 "h" (psOrderLe m (.fvar 6))
                (psLogicLam 8 "ih" (psOrderLe n (.fvar 6))
                  (psOrderStep n (.fvar 6) (.fvar 8)))) .implicit)
            k (.fvar 5)))) .implicit))
  let pred := fun x => psOrderCall "Nat.pred" [x]
  let predDecl := psOrderDecl "Nat.pred" (psLogicPi 0 "n" nat nat)
    (psLogicLam 0 "n" nat
      (psOrderNatRec (.succ .zero) (psLogicLam 1 "m" nat nat) zero
        (psLogicLam 1 "m" nat (psLogicLam 4 "ih" nat m)) n))
  let predLe := psOrderDecl "Nat.pred_le"
    (psLogicPi 0 "n" nat (psOrderLe (pred n) n))
    (psLogicLam 0 "n" nat
      (psOrderNatRec .zero (psLogicLam 1 "m" nat (psOrderLe (pred m) m))
        (psOrderRefl zero)
        (psLogicLam 1 "m" nat
          (psLogicLam 4 "ih" (psOrderLe (pred m) m)
            (psOrderStep m m (psOrderRefl m)))) n))
  let predMono := psOrderDecl "Nat.pred_le_pred"
    (twoParams (psLogicPi 2 "h" (psOrderLe n m) (psOrderLe (pred n) (pred m))))
    (twoLams (psLogicLam 2 "h" (psOrderLe n m)
      (psOrderLeRec n (leMotive (psOrderLe (pred n) (pred m)))
        (psOrderRefl (pred n))
        (leStep (psLogicLam 4 "ih" (psOrderLe (pred n) (pred m))
          (psOrderCall "Nat.le_trans"
            [pred n, pred m, m, ih, psOrderCall "Nat.pred_le" [m]])))
        m h)))
  let lower := psOrderDecl "Nat.le_of_succ_le_succ"
    (twoParams (psLogicPi 2 "h" (psOrderLe (psOrderSucc n) (psOrderSucc m))
      (psOrderLe n m)))
    (twoLams (psLogicLam 2 "h" (psOrderLe (psOrderSucc n) (psOrderSucc m))
      (psOrderCall "Nat.pred_le_pred" [psOrderSucc n, psOrderSucc m, h])))
  -- A positive upper endpoint has the logical shape True; zero has False.
  -- Eliminating Nat.le into this Prop exposes the impossible zero endpoint
  -- without assuming constructor injectivity, a cast, or a noConfusion axiom.
  let positive := fun x => psOrderNatRec (.succ .zero)
    (psLogicLam 6 "_" nat (.sortE .zero)) falseType
    (psLogicLam 6 "_" nat (psLogicLam 7 "_" (.sortE .zero) trueType)) x
  let impossible := psOrderDecl "Nat.not_succ_le_zero"
    (psLogicPi 0 "n" nat
      (psLogicPi 2 "h" (psOrderLe (psOrderSucc n) zero) falseType))
    (psLogicLam 0 "n" nat
      (psLogicLam 2 "h" (psOrderLe (psOrderSucc n) zero)
        (psOrderLeRec (psOrderSucc n)
          (psLogicLam 1 "m" nat
            (psLogicLam 3 "h" (psOrderLe (psOrderSucc n) m) (positive m)))
          trueIntro
          (psLogicLam 1 "m" nat
            (psLogicLam 3 "h" (psOrderLe (psOrderSucc n) m)
              (psLogicLam 4 "ih" (positive m) trueIntro)) .implicit)
          zero h)))
  let lowerLt := psOrderDecl "Nat.lt_of_succ_lt_succ"
    (twoParams (psLogicPi 2 "h"
      (psOrderLe (psOrderSucc (psOrderSucc n)) (psOrderSucc m))
      (psOrderLe (psOrderSucc n) m)))
    (twoLams (psLogicLam 2 "h"
      (psOrderLe (psOrderSucc (psOrderSucc n)) (psOrderSucc m))
      (psOrderCall "Nat.le_of_succ_le_succ" [psOrderSucc n, m, h])))
  let ltSelf := psOrderDecl "Nat.lt_succ_self"
    (psLogicPi 0 "n" nat (psOrderLe (psOrderSucc n) (psOrderSucc n)))
    (psLogicLam 0 "n" nat (psOrderRefl (psOrderSucc n)))
  [zeroLe, succLe, trans, predDecl, predLe, predMono, lower, impossible,
   psOrderDecl "Nat.not_lt_zero"
     (psLogicPi 0 "n" nat (psDecisionNot (psOrderLe (psOrderSucc n) zero)))
     (.constE (psDecisionName "Nat.not_succ_le_zero") []),
   lowerLt, ltSelf]

def psStandardNatBleDeclaration : PsDeclaration :=
  let nat := psOrderNat
  let bool := PsExpr.constE psBoolName []
  let result := psLogicPi 20 "m" nat bool
  let n := PsExpr.fvar 0
  let m := PsExpr.fvar 1
  let body := psOrderNatRec (.succ .zero)
    (psLogicLam 20 "_" nat result)
    (psLogicLam 1 "m" nat (.constE psBoolTrueName []))
    (psLogicLam 2 "previous" nat
      (psLogicLam 3 "ih" result
        (psLogicLam 1 "m" nat
          (psOrderNatRec (.succ .zero) (psLogicLam 20 "_" nat bool)
            (.constE psBoolFalseName [])
            (psLogicLam 4 "previousM" nat
              (psLogicLam 5 "_" bool (.app (.fvar 3) (.fvar 4))))
            m)))) n
  psOrderDecl "Nat.ble" (psLogicPi 0 "n" nat result)
    (psLogicLam 0 "n" nat body)

def psStandardNatDecisionDeclarations : List PsDeclaration :=
  let nat := psOrderNat
  let bool := PsExpr.constE psBoolName []
  let n := PsExpr.fvar 0
  let m := PsExpr.fvar 1
  let reflected := fun a b =>
    psDecisionReflects (psOrderCall "Nat.ble" [a, b]) (psOrderLe a b)
  let result := fun a => psLogicPi 1 "m" nat (reflected a m)
  let previous := PsExpr.fvar 2
  let previousM := PsExpr.fvar 4
  let oldProp := psOrderLe previous previousM
  let newProp := psOrderLe (psOrderSucc previous) (psOrderSucc previousM)
  let flag := PsExpr.fvar 6
  let transportType := psLogicPi 7 "reflection" (psDecisionReflects flag oldProp)
    (psDecisionReflects flag newProp)
  let positive := psLogicLam 7 "proof" oldProp
    (psOrderCall "Nat.succ_le_succ" [previous, previousM, .fvar 7])
  let negative := psLogicLam 7 "refute" (psDecisionNot oldProp)
    (psLogicLam 8 "proof" newProp
      (.app (.fvar 7) (psOrderCall "Nat.le_of_succ_le_succ"
        [previous, previousM, .fvar 8])))
  let transport := psLogicApply (.constE (psDecisionName "Bool.rec") [.zero])
    [psLogicLam 6 "flag" bool transportType, negative, positive,
     psOrderCall "Nat.ble" [previous, previousM],
     .app (.fvar 3) previousM]
  let step := psLogicLam 2 "previous" nat
    (psLogicLam 3 "ih" (result previous)
      (psLogicLam 1 "m" nat
        (psOrderNatRec .zero
          (psLogicLam 1 "m" nat (reflected (psOrderSucc previous) m))
          (psOrderCall "Nat.not_succ_le_zero" [previous])
          (psLogicLam 4 "previousM" nat
            (psLogicLam 5 "_" (reflected (psOrderSucc previous) previousM)
              transport))
          m)))
  let reflection := psOrderDecl "PsStandard.natBleReflects"
    (psLogicPi 0 "n" nat (result n))
    (psLogicLam 0 "n" nat
      (psOrderNatRec .zero
        (psLogicLam 0 "n" nat (result n))
        (psLogicLam 1 "m" nat (psOrderCall "Nat.zero_le" [m]))
        step n))
  let decideLe := psOrderDecl "Nat.decLe"
    (psLogicPi 0 "n" nat (psLogicPi 1 "m" nat (psDecisionType (psOrderLe n m))))
    (psLogicLam 0 "n" nat (psLogicLam 1 "m" nat
      (psOrderCall "Decidable.intro"
        [psOrderLe n m, psOrderCall "Nat.ble" [n, m],
         psOrderCall "PsStandard.natBleReflects" [n, m]])))
  let decideLt := psOrderDecl "Nat.decLt"
    (psLogicPi 0 "n" nat (psLogicPi 1 "m" nat
      (psDecisionType (psOrderCall "Nat.lt" [n, m]))))
    (psLogicLam 0 "n" nat (psLogicLam 1 "m" nat
      (psOrderCall "Nat.decLe" [psOrderSucc n, m])))
  [reflection, decideLe, decideLt]

def psStandardNatOrderDeclarations : List PsDeclaration :=
  psStandardNatArithmeticDeclarations ++ psStandardNatOrderProofDeclarations ++
    [psStandardNatBeqDeclaration, psStandardNatBleDeclaration] ++
    psStandardNatDecisionDeclarations

def psStandardNatOrderExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardNatOrderDeclarations.foldl
    psSelfHostReplacePreludeAxiom environment
  let instances := ["Nat.decLe", "Nat.decLt"].foldl (fun index name =>
    let name := psDecisionName name
    match psEnvironmentFind environment name with
    | none => index
    | some declaration => psInstanceIndexAdd index {
        value := .constE name []
        type := psDeclarationType declaration
        className := some psDecidableName }) environment.instances
  { environment with instances }
