import Ps.Environment.StandardBoolWord
import Ps.Environment.StandardClass

/-
Pinned Lean 4.35.0, commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
Primary references: Init/Prelude.lean (UInt8) and
Init/Data/UInt/Basic.lean (UInt16/32/64).
Copyright Microsoft Corporation / Lean FRO, LLC, Apache-2.0;
see psc0/THIRD_PARTY_NOTICES.md.

The native UIntN.lt/le relations compare the underlying BitVec values
as unsigned integers. The canonical UIntN.toNat carrier has the same
order, and Nat.decLt/Nat.decLe provide checked constructive decisions.
This module does not import source proof axioms or invent a primitive.
Class registration is explicit and uses the same generic LT/LE and
Decidable instance index as the signed-width implementation.
-/

def psStandardUnsignedOrderWidths : List String :=
  ["UInt8", "UInt16", "UInt32", "UInt64"]

def psStandardUnsignedOrderValue (owner : String) (value : PsExpr) : PsExpr :=
  psOrderCall (owner ++ ".toNat") [value]

def psStandardUnsignedOrderRelations : List PsDeclaration :=
  psStandardUnsignedOrderWidths.flatMap fun owner =>
    let ty : PsExpr := .constE (psRootName owner) []
    let a := psStandardUnsignedOrderValue owner (.fvar 0)
    let b := psStandardUnsignedOrderValue owner (.fvar 1)
    let signature := psLogicPi 0 "a" ty
      (psLogicPi 1 "b" ty (.sortE .zero))
    let mk := fun method relation =>
      .definitionDecl (psNameAppendStr (psRootName owner) method) []
        signature (psLogicLam 0 "a" ty (psLogicLam 1 "b" ty
          (psOrderCall relation [a, b])))
    [mk "lt" "Nat.lt", mk "le" "Nat.le"]

def psStandardUnsignedOrderDeciders : List PsDeclaration :=
  psStandardUnsignedOrderWidths.flatMap fun owner =>
    let ty : PsExpr := .constE (psRootName owner) []
    let left := psStandardUnsignedOrderValue owner (.fvar 0)
    let right := psStandardUnsignedOrderValue owner (.fvar 1)
    let mk := fun method procedure relation =>
      let proposition := psOrderCall (owner ++ "." ++ relation)
        [.fvar 0, .fvar 1]
      .definitionDecl (psNameAppendStr (psRootName owner) method) []
        (psLogicPi 0 "a" ty
          (psLogicPi 1 "b" ty (psDecisionType proposition)))
        (psLogicLam 0 "a" ty (psLogicLam 1 "b" ty
          (psOrderCall procedure [left, right])))
    [mk "decLt" "Nat.decLt" "lt",
     mk "decLe" "Nat.decLe" "le"]

def psStandardUnsignedOrderInstances : List (String × PsDeclaration) :=
  psStandardUnsignedOrderWidths.flatMap fun owner =>
    let ty : PsExpr := .constE (psRootName owner) []
    ["LT", "LE"].map fun className =>
      let method := if className == "LT" then "lt" else "le"
      let instanceName := psDecisionName ("PsStandard.inst" ++ className ++ owner)
      let classType : PsExpr := .app
        (.constE (psRootName className) [.zero]) ty
      let constructor := psLogicApply
        (.constE (psDecisionName (className ++ ".mk")) [.zero])
        [ty, .constE (psNameAppendStr (psRootName owner) method) []]
      (className, .definitionDecl instanceName [] classType constructor)

def psStandardUnsignedOrderExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := (psStandardUnsignedOrderRelations ++
    psStandardUnsignedOrderDeciders ++
    psStandardUnsignedOrderInstances.map Prod.snd).foldl
      psEnvironmentInsert environment
  -- Both upstream native deciders are @[instance_reducible] for each width.
  let environment := psStandardUnsignedOrderDeciders.foldl (fun env d =>
    psEnvironmentSetReducibility env (psDeclarationName d)
      .instanceReducible) environment
  let environment := ["LT", "LE"].foldl (fun env className =>
    if env.classes.any (fun name => psNameToString name == className) then
      env
    else psStandardRegisterClass env className) environment
  let environment := psStandardUnsignedOrderInstances.foldl
    (fun env (className, declaration) =>
      psStandardRegisterInstances env className [declaration]) environment
  psStandardRegisterInstances environment "Decidable"
    psStandardUnsignedOrderDeciders

def psStandardUnsignedOrderRuntimeDeclarations : List PsDeclaration :=
  psStandardUnsignedOrderRelations ++ psStandardUnsignedOrderDeciders ++
    psStandardUnsignedOrderInstances.map Prod.snd
