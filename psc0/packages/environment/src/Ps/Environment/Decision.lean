import Ps.Environment.Connectives

-- Lean 4.35.0-rc4 Init/Prelude.lean: Decidable is a checked structure
-- containing a computational Bool and a proof of Bool.Reflects that value.
-- The old opaque Decidable/constructor/dite declarations prevented genuine
-- propositional reasoning about two independently provided decisions.
-- Do not add a coherence axiom: the reflection proof is a checked field.
def psDecisionName (text : String) : PsName :=
  (text.splitOn ".").foldl psNameAppendStr .anonymous

def psDecisionType (proposition : PsExpr) : PsExpr :=
  .app (.constE psDecidableName []) proposition

def psDecisionReflects (boolean proposition : PsExpr) : PsExpr :=
  psLogicApply (.constE (psDecisionName "Bool.Reflects") [])
    [boolean, proposition]

def psDecisionNot (proposition : PsExpr) : PsExpr :=
  PsExpr.app (.constE (psRootName "Not") []) proposition

-- The fully checked motive reduces Bool.Reflects false p to Not p and
-- Bool.Reflects true p to p; there is no Bool-as-Prop coercion.
def psDecisionReflectsDeclaration : PsDeclaration :=
  let bool := PsExpr.constE psBoolName []
  let proposition := PsExpr.fvar 1
  let boolean := PsExpr.fvar 0
  let motive := psLogicLam 2 "_value" bool (.sortE .zero)
  let result := psLogicApply
    (.constE (psNameAppendStr psBoolName "rec") [.succ .zero])
    [motive, psDecisionNot proposition, proposition, boolean]
  .definitionDecl (psDecisionName "Bool.Reflects") []
    (psLogicPi 0 "value" bool
      (psLogicPi 1 "p" (.sortE .zero) (.sortE .zero)))
    (psLogicLam 0 "value" bool
      (psLogicLam 1 "p" (.sortE .zero) result))

-- Reconstruct the actual RC4 class/constructor, including the dependent
-- proof field. The proof eraser must discard only reflects_decide, retaining
-- the computational Bool field on every backend.
def psDecisionCheckedClass : List PsDeclaration :=
  let prop := PsExpr.sortE .zero
  let bool := PsExpr.constE psBoolName []
  let p := PsExpr.fvar 0
  let b := PsExpr.fvar 1
  let h := PsExpr.fvar 2
  let self := PsExpr.fvar 3
  let family := psDecisionType p
  let introName := psDecisionName "Decidable.intro"
  let type := psLogicPi 0 "p" prop (.sortE (.succ .zero))
  let fields := psLogicPi 1 "decide" bool
    (psLogicPi 2 "reflects_decide" (psDecisionReflects b p) family)
  let ctorType := psLogicPi 0 "p" prop fields .implicit
  let params := fun body => psLogicPi 0 "p" prop body .implicit
  let paramLams := fun body => psLogicLam 0 "p" prop body .implicit
  let decide := .proj psDecidableName 0 self
  let reflection := .proj psDecidableName 1 self
  let motive := psLogicPi 3 "d" family (.sortE (.param (psRootName "u")))
  let intro := psLogicApply (.constE introName []) [p, b, h]
  let minor := psLogicPi 1 "decide" bool
    (psLogicPi 2 "reflects_decide" (psDecisionReflects b p)
      (.app (.fvar 4) intro))
  let recursorType := params
    (psLogicPi 4 "motive" motive
      (psLogicPi 5 "intro" minor
        (psLogicPi 3 "d" family (.app (.fvar 4) self))) .implicit)
  [ .inductiveDecl (.mk psDecidableName [] type 1 0 [introName] true),
    .constructorDecl (.mk introName [] ctorType psDecidableName 0 1 2 []),
    .recursorDecl (.mk (psDecisionName "Decidable.rec") [psRootName "u"]
       recursorType [psDecidableName] 1 0 1 1),
    .definitionDecl (psDecisionName "Decidable.decide") []
      (params (psLogicPi 3 "self" family bool .instanceImplicit))
      (paramLams (psLogicLam 3 "self" family decide .instanceImplicit)),
    .definitionDecl (psDecisionName "Decidable.reflects_decide") []
      (params (psLogicPi 3 "self" family
        (psDecisionReflects decide p) .instanceImplicit))
      (paramLams (psLogicLam 3 "self" family reflection .instanceImplicit)) ]

-- RC4 isTrue/isFalse are definitions, not separate trusted constructors.
def psDecisionCheckedConstructors : List PsDeclaration :=
  let prop := PsExpr.sortE .zero
  let p := PsExpr.fvar 0
  let h := PsExpr.fvar 1
  let value := fun (positive : Bool) =>
    psLogicApply (.constE (psDecisionName "Decidable.intro") [])
      [p, .constE (if positive then psBoolTrueName else psBoolFalseName) [], h]
  [ .definitionDecl (psDecisionName "Decidable.isTrue") []
      (psLogicPi 0 "p" prop
        (psLogicPi 1 "h" p (psDecisionType p)) .implicit)
      (psLogicLam 0 "p" prop
        (psLogicLam 1 "h" p (value true)) .implicit),
    .definitionDecl (psDecisionName "Decidable.isFalse") []
      (psLogicPi 0 "p" prop
        (psLogicPi 1 "h" (psDecisionNot p) (psDecisionType p)) .implicit)
      (psLogicLam 0 "p" prop
        (psLogicLam 1 "h" (psDecisionNot p) (value false)) .implicit) ]

-- A checked implementation of Lean's dependent if: eliminate on the
-- decision's Bool and apply the attached reflection proof. In particular,
-- equal propositions cannot select different branches merely because two
-- dictionaries were synthesized independently.
def psDecisionDiteDeclaration : PsDeclaration :=
  let u := psRootName "u"
  let alpha := PsExpr.fvar 4
  let p := PsExpr.fvar 0
  let decision := PsExpr.fvar 1
  let positive := PsExpr.fvar 2
  let negative := PsExpr.fvar 3
  let branch := psLogicLam 5 "decision" (.constE psBoolName [])
    (psLogicPi 6 "reflection" (psDecisionReflects (.fvar 5) p) alpha)
  let isFalse := psLogicLam 7 "notP" (psDecisionNot p)
    (.app negative (.fvar 7))
  let isTrue := psLogicLam 8 "h" p (.app positive (.fvar 8))
  let boolValue := psLogicApply
    (.constE (psDecisionName "Decidable.decide") [])
    [p, decision]
  let boolProof := psLogicApply
    (.constE (psDecisionName "Decidable.reflects_decide") [])
    [p, decision]
  let selected := psLogicApply
    (.constE (psNameAppendStr psBoolName "rec") [.param u])
    [branch, isFalse, isTrue, boolValue]
  let body := .app selected boolProof
  let dtype := psLogicPi 4 "α" (.sortE (.param u))
    (psLogicPi 0 "c" (.sortE .zero)
      (psLogicPi 1 "h" (psDecisionType p)
        (psLogicPi 2 "t" (psLogicPi 5 "_" p alpha)
          (psLogicPi 3 "e" (psLogicPi 5 "_" (psDecisionNot p) alpha)
            alpha)) .instanceImplicit)) .implicit
  let value := psLogicLam 4 "α" (.sortE (.param u))
    (psLogicLam 0 "c" (.sortE .zero)
      (psLogicLam 1 "h" (psDecisionType p)
        (psLogicLam 2 "t" (psLogicPi 5 "_" p alpha)
          (psLogicLam 3 "e" (psLogicPi 5 "_" (psDecisionNot p) alpha)
            body)) .instanceImplicit)) .implicit
  .definitionDecl (psRootName "dite") [u] dtype value

-- Lean 4.35.0 ite is the nondependent wrapper over checked dite.
-- Keeping ite opaque blocks ordinary open-term conditional proofs (including
-- Nat.mod_lt), even when the runtime's conditional behavior is correct.
def psDecisionIteDeclaration : PsDeclaration :=
  let u := psRootName "u"
  let alpha := PsExpr.fvar 0
  let p := PsExpr.fvar 1
  let decision := PsExpr.fvar 2
  let positive := PsExpr.fvar 3
  let negative := PsExpr.fvar 4
  let body := psLogicApply (.constE (psRootName "dite") [.param u])
    [alpha, p, decision, psLogicLam 5 "_" p positive,
      psLogicLam 5 "_" (psDecisionNot p) negative]
  let type := psLogicPi 0 "α" (.sortE (.param u))
    (psLogicPi 1 "c" (.sortE .zero)
      (psLogicPi 2 "h" (psDecisionType p)
        (psLogicPi 3 "t" alpha (psLogicPi 4 "e" alpha alpha))
        .instanceImplicit)) .implicit
  let value := psLogicLam 0 "α" (.sortE (.param u))
    (psLogicLam 1 "c" (.sortE .zero)
      (psLogicLam 2 "h" (psDecisionType p)
        (psLogicLam 3 "t" alpha (psLogicLam 4 "e" alpha body))
        .instanceImplicit)) .implicit
  .definitionDecl psIteName [u] type value

-- Proof-theoretic coherence of two independent Decidable dictionaries.
-- This is ordinary checked Core, NOT an axiom or a trusted host rewrite.
-- Eliminate both Decidable structures, then case split on their Boolean
-- choices: matching choices are equal by proof irrelevance of reflection
-- evidence; disagreeing choices imply False by the two reflection fields.
-- The helper returns a Prop proof and is erased before executable IR.
def psDecisionUniqueDeclaration : PsDeclaration :=
  let p := PsExpr.fvar 0
  let a := PsExpr.fvar 1
  let b := PsExpr.fvar 2
  let bool := PsExpr.constE psBoolName []
  let tt := PsExpr.constE psBoolTrueName []
  let ff := PsExpr.constE psBoolFalseName []
  let family := psDecisionType p
  let intro := fun (flag proof : PsExpr) =>
    psLogicApply (.constE (psDecisionName "Decidable.intro") [])
      [p, flag, proof]
  let eq := fun (lhs rhs : PsExpr) =>
    psLogicEq (.succ .zero) family lhs rhs
  let reflect := fun (flag : PsExpr) => psDecisionReflects flag p
  let boolRec := fun (motive onFalse onTrue major : PsExpr) =>
    psLogicApply (.constE (psDecisionName "Bool.rec") [.zero])
      [motive, onFalse, onTrue, major]
  let decRec := fun (motive minor major : PsExpr) =>
    psLogicApply (.constE (psDecisionName "Decidable.rec") [.zero])
      [p, motive, minor, major]
  let branch := fun (positive : Bool) =>
    let flagA := if positive then tt else ff
    let reflectionA := PsExpr.fvar 7
    let innerB := PsExpr.fvar 8
    let flagB := PsExpr.fvar 9
    let reflectionB := PsExpr.fvar 10
    let left := intro flagA reflectionA
    let right := intro flagB reflectionB
    let motiveBoolB := psLogicLam 9 "flagB" bool
      (psLogicPi 10 "reflectionB" (reflect flagB) (eq left right))
    let same := psLogicLam 10 "reflectionB" (reflect flagA)
      (psLogicRefl (.succ .zero) family left)
    let opposite := if positive then ff else tt
    let contradiction := if positive
      then PsExpr.app reflectionB reflectionA
      else PsExpr.app reflectionA reflectionB
    let impossible := psLogicLam 10 "reflectionB" (reflect opposite)
      (psLogicApply (.constE (psDecisionName "False.elim") [.zero])
        [eq left (intro opposite reflectionB), contradiction])
    let minorFalse := if positive then impossible else same
    let minorTrue := if positive then same else impossible
    let innerDecision := boolRec motiveBoolB minorFalse minorTrue flagB
    let minorDecB := psLogicLam 9 "flagB" bool
      (psLogicLam 10 "reflectionB" (reflect flagB)
        (.app innerDecision reflectionB))
    let motiveDecB := psLogicLam 8 "right" family (eq left innerB)
    let fromDecB := decRec motiveDecB minorDecB innerB
    psLogicLam 7 "reflectionA" (reflect flagA)
      (psLogicLam 8 "right" family fromDecB)
  let flagA := PsExpr.fvar 3
  let reflectionA := PsExpr.fvar 4
  let innerB := PsExpr.fvar 8
  let motiveBoolA := psLogicLam 3 "flagA" bool
    (psLogicPi 4 "reflectionA" (reflect flagA)
      (psLogicPi 8 "right" family (eq (intro flagA reflectionA) innerB)))
  let fromBoolA := boolRec motiveBoolA (branch false) (branch true) flagA
  let minorDecA := psLogicLam 3 "flagA" bool
    (psLogicLam 4 "reflectionA" (reflect flagA)
      (.app fromBoolA reflectionA))
  let motiveDecA := psLogicLam 1 "left" family
    (psLogicPi 2 "right" family (eq a b))
  let body := .app (decRec motiveDecA minorDecA a) b
  let type := psLogicPi 0 "p" (.sortE .zero)
    (psLogicPi 1 "left" family
      (psLogicPi 2 "right" family (eq a b)))
  let value := psLogicLam 0 "p" (.sortE .zero)
    (psLogicLam 1 "left" family
      (psLogicLam 2 "right" family body))
  .definitionDecl (psDecisionName "PsStandard.decidableUnique") [] type value

-- DecidableEq is a reducible function alias in RC4, not a new structure
-- class. Search introduces its two arguments and solves the ordinary Decidable
-- goal; deriving instances therefore use the existing Pi-aware instance graph.
def psDecisionEqualityDeclarations : List PsDeclaration :=
  let u := psRootName "u"
  let alpha := PsExpr.fvar 0
  let sort := PsExpr.sortE (.param u)
  let decision := psDecisionType (psLogicEq (.param u) alpha (.fvar 2) (.fvar 3))
  let method := psLogicPi 2 "a" alpha (psLogicPi 3 "b" alpha decision)
  let alias := PsExpr.app (.constE (psRootName "DecidableEq") [.param u]) alpha
  [ .definitionDecl (psRootName "DecidableEq") [u]
      (psLogicPi 0 "α" sort (.sortE (.max (.succ .zero) (.param u))))
      (psLogicLam 0 "α" sort method),
    .definitionDecl (psRootName "decEq") [u]
      (psLogicPi 0 "α" sort (psLogicPi 1 "inst" alias method .instanceImplicit) .implicit)
      (psLogicLam 0 "α" sort
        (psLogicLam 1 "inst" alias (.fvar 1) .instanceImplicit) .implicit) ]

def psDecisionDeclarations : List PsDeclaration :=
  let decEq := fun (name : String) (type : PsExpr) =>
    PsDeclaration.axiomDecl (psDecisionName name) []
      (psLogicPi 0 "a" type (psLogicPi 1 "b" type
        (psDecisionType (psLogicEq (.succ .zero) type (.fvar 0) (.fvar 1)))))
  [ .definitionDecl (psRootName "outParam") [psRootName "u"]
      (psLogicPi 0 "α" (.sortE (.param (psRootName "u")))
        (.sortE (.param (psRootName "u"))))
      (psLogicLam 0 "α" (.sortE (.param (psRootName "u"))) (.fvar 0)),
    psDecisionReflectsDeclaration ] ++
  psDecisionCheckedClass ++ psDecisionCheckedConstructors ++
  [psDecisionUniqueDeclaration] ++ psDecisionEqualityDeclarations ++
  [decEq "Nat.decEq" (.constE psNatName []),
   decEq "String.decEq" (.constE psStringName []),
   psDecisionDiteDeclaration, psDecisionIteDeclaration]

def psDecisionPrelude (environment : PsEnvironment) : PsEnvironment :=
  let environment := psDecisionDeclarations.foldl (fun current declaration =>
    (psEnvironmentAddReplacingAxiom current declaration).getD current) environment
  let instances := ["Bool.decEq", "Nat.decEq", "String.decEq"].foldl (fun index name =>
    let name := psDecisionName name
    match psEnvironmentFind environment name with
    | none => index
    | some declaration => psInstanceIndexAdd index {
        value := .constE name []
        type := psDeclarationType declaration
        className := some psDecidableName }) environment.instances
  { environment with instances, classes := psDecidableName :: environment.classes }
