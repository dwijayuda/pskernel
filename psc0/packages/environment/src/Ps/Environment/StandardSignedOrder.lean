import Ps.Environment.StandardSignedAbs
import Ps.Environment.StandardClass

/-
Pinned Lean 4.35.0 Init/Data/SInt/Basic.lean and
Init/Data/BitVec/Basic.lean, commit
eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
Copyright Lean FRO, LLC; Apache-2.0; see THIRD_PARTY_NOTICES.md.

BitVec.slt/sle compare two's-complement Int values. For a raw width-w
unsigned carrier, rotating the sign bit (biasing by 2^(w-1)) maps
the signed integer order bijectively to ordinary Nat order.
This preserves the entire finite w-bit carrier, including the sign
transition and minimum negative value, and needs no new numeric primitive.
These are ordinary checked propositions/decisions, not assumed axioms.
Backend correspondence is qualified independently against the official
native Lean signed-comparison oracle; no unbounded semantic theorem
is claimed for generated targets.
-/

def psStandardSignedOrderWidths : List (String × String × Nat) :=
  [("Int8", "UInt8", 8), ("Int16", "UInt16", 16),
   ("Int32", "UInt32", 32), ("Int64", "UInt64", 64)]

-- Sign-bias a canonical carrier: negatives map to the lower Nat half.
-- The value is known to inhabit [0,2^width) by its checked unsigned model.
def psStandardSignedOrderKey (owner unsigned : String) (width : Nat)
    (value : PsExpr) : PsExpr :=
  let bits := psOrderCall (unsigned ++ ".toNat")
    [psOrderCall (owner ++ ".to" ++ unsigned) [value]]
  let half : PsExpr := .lit (.natural (2 ^ (width - 1)))
  let isPositive := psOrderCall "Nat.lt" [bits, half]
  let decision := psOrderCall "Nat.decLt" [bits, half]
  psLogicApply (.constE (psRootName "ite") [.succ .zero])
    [psOrderNat, isPositive, decision,
     psOrderCall "Nat.add" [bits, half],
     psOrderCall "Nat.sub" [bits, half]]

def psStandardSignedOrderRelations : List PsDeclaration :=
  psStandardSignedOrderWidths.flatMap fun (owner, unsigned, width) =>
    let signedType : PsExpr := .constE (psRootName owner) []
    let a : PsExpr := .fvar 0
    let b : PsExpr := .fvar 1
    let left := psStandardSignedOrderKey owner unsigned width a
    let right := psStandardSignedOrderKey owner unsigned width b
    let signature := psLogicPi 0 "a" signedType
      (psLogicPi 1 "b" signedType (.sortE .zero))
    let operation := fun method primitive =>
      PsDeclaration.definitionDecl
        (psNameAppendStr (psRootName owner) method) [] signature
        (psLogicLam 0 "a" signedType
          (psLogicLam 1 "b" signedType
            (psOrderCall primitive [left, right])))
    [operation "lt" "Nat.lt", operation "le" "Nat.le"]

def psStandardSignedOrderDeciders : List PsDeclaration :=
  psStandardSignedOrderWidths.flatMap fun (owner, unsigned, width) =>
    let signedType : PsExpr := .constE (psRootName owner) []
    let a : PsExpr := .fvar 0
    let b : PsExpr := .fvar 1
    let left := psStandardSignedOrderKey owner unsigned width a
    let right := psStandardSignedOrderKey owner unsigned width b
    let operation := fun method primitive relation =>
      let relation := psOrderCall (owner ++ "." ++ relation) [a, b]
      .definitionDecl (psNameAppendStr (psRootName owner) method) []
        (psLogicPi 0 "a" signedType
          (psLogicPi 1 "b" signedType (psDecisionType relation)))
        (psLogicLam 0 "a" signedType
          (psLogicLam 1 "b" signedType
            (psOrderCall primitive [left, right])))
    [operation "decLt" "Nat.decLt" "lt",
     operation "decLe" "Nat.decLe" "le"]

-- LT/LE are Lean's existing one-field structure classes. Do not reintroduce
-- a second class or alter the parser's relation operator ownership.
def psStandardSignedOrderInstances : List (String × PsDeclaration) :=
  psStandardSignedOrderWidths.flatMap fun (owner, _, _) =>
    let signedType : PsExpr := .constE (psRootName owner) []
    ["LT", "LE"].map fun className =>
      let method := if className == "LT" then "lt" else "le"
      let name := psDecisionName ("PsStandard.inst" ++ className ++ owner)
      let type := .app (.constE (psRootName className) [.zero]) signedType
      let body := psLogicApply
        (.constE (psDecisionName (className ++ ".mk")) [.zero])
        [signedType, .constE (psNameAppendStr (psRootName owner) method) []]
      (className, PsDeclaration.definitionDecl name [] type body)

def psStandardSignedOrderExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := (psStandardSignedOrderRelations ++
    psStandardSignedOrderDeciders ++
    psStandardSignedOrderInstances.map Prod.snd).foldl
      psEnvironmentInsert environment
  let environment := ["LT", "LE"].foldl (fun env className =>
    if env.classes.contains (psRootName className) then env
    else psStandardRegisterClass env className) environment
  let environment := psStandardSignedOrderInstances.foldl
    (fun env (className, decl) =>
      psStandardRegisterInstances env className [decl]) environment
  -- Nat.decLt/decLe use the same explicit Decidable search convention.
  psStandardRegisterInstances environment "Decidable"
    psStandardSignedOrderDeciders

def psStandardSignedOrderRuntimeDeclarations : List PsDeclaration :=
  psStandardSignedOrderRelations ++ psStandardSignedOrderDeciders ++
    psStandardSignedOrderInstances.map Prod.snd
