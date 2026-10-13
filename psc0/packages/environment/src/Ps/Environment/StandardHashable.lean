/-
Hash instances adapted from Lean 4.35.0 Init/Data/Hashable.lean.
Copyright (c) 2016 Microsoft Corporation. Author: Leonardo de Moura.
Apache-2.0; see THIRD_PARTY_NOTICES.md.
Modified: portable checked Core builders and selected Type-0 Array.
-/
import Ps.Environment.StandardHashFoundationData
import Ps.Environment.StandardClass

def psHashUInt64 : PsExpr := .constE (psRootName "UInt64") []

def psHashOfNat (value : PsExpr) : PsExpr :=
  psOrderCall "UInt64.ofNat" [value]

def psHashSeed (value : Nat) : PsExpr := psHashOfNat (.lit (.natural value))

-- Hashable accepts Sort u, unlike the Type u formatting classes.
def psHashClass (type : PsExpr) (level : PsLevel := .succ .zero) : PsExpr :=
  .app (.constE (psRootName "Hashable") [level]) type

def psHashValue (type method : PsExpr) (level : PsLevel := .succ .zero) : PsExpr :=
  psLogicApply (.constE (psDecisionName "Hashable.mk") [level]) [type, method]

def psHashMethod (type dictionary value : PsExpr)
    (level : PsLevel := .succ .zero) : PsExpr :=
  psLogicApply (.constE (psDecisionName "Hashable.hash") [level]) [type, dictionary, value]

def psHashMix (left right : PsExpr) : PsExpr := psOrderCall "mixHash" [left, right]

def psHashGround (suffix : String) (type body : PsExpr) : PsDeclaration :=
  .definitionDecl (psDecisionName ("PsStandard.instHashable" ++ suffix)) []
    (psHashClass type) (psHashValue type (psLogicLam 0 "value" type body))

def psHashGroundInstances : List PsDeclaration :=
  let nat := psOrderNat
  let int := PsExpr.constE psIntName []
  let bool := PsExpr.constE psBoolName []
  let empty := PsExpr.constE (psRootName "Empty") []
  let twice := psOrderCall "Nat.mul" [.lit (.natural 2), .fvar 1]
  let intBody := psLogicApply (.constE (psDecisionName "Int.rec") [.succ .zero])
    [psLogicLam 2 "_" int psHashUInt64,
     psLogicLam 1 "n" nat (psHashOfNat twice),
     psLogicLam 1 "n" nat (psHashOfNat (psOrderCall "Nat.add" [twice, .lit (.natural 1)])), .fvar 0]
  [ psHashGround "Nat" nat (psHashOfNat (.fvar 0)),
    psHashGround "Int" int intBody,
    psHashGround "Bool" bool (psLogicApply (.constE (psDecisionName "Bool.rec") [.succ .zero])
      [psLogicLam 1 "_" bool psHashUInt64, psHashSeed 13, psHashSeed 11, .fvar 0]),
    psHashGround "String" (.constE psStringName []) (psOrderCall "String.hash" [.fvar 0]),
    psHashGround "Char" (.constE psCharName []) (psHashOfNat (psOrderCall "Char.toNat" [.fvar 0])),
    psHashGround "Unit" (.constE psUnitName []) (psHashSeed 11),
    psHashGround "Empty" empty (psLogicApply (.constE (psDecisionName "Empty.rec") [.succ .zero])
      [psLogicLam 1 "_" empty psHashUInt64, .fvar 0]) ] ++
  ["UInt8", "UInt16", "UInt32", "UInt64"].map (fun owner =>
    psHashGround owner (.constE (psRootName owner) [])
      (if owner == "UInt64" then .fvar 0
       else psHashOfNat (psOrderCall (owner ++ ".toNat") [.fvar 0])))

def psHashPropInstance : PsDeclaration :=
  let prop := PsExpr.fvar 0
  .definitionDecl (psDecisionName "PsStandard.instHashableProp") []
    (psLogicPi 0 "P" (.sortE .zero) (psHashClass prop .zero))
    (psLogicLam 0 "P" (.sortE .zero)
      (psHashValue prop (psLogicLam 1 "proof" prop (psHashSeed 0)) .zero))

-- Element and container sorts are explicit: Option/List use Type u while
-- Hashable's argument universe is u+1.
def psHashContainer (suffix : String) (type method : PsExpr)
    (level : PsLevel) (parameters : List PsName) : PsDeclaration :=
  let alpha := PsExpr.fvar 0
  let dictionary := psHashClass alpha (.succ level)
  .definitionDecl (psDecisionName ("PsStandard.instHashable" ++ suffix)) parameters
    (psLogicPi 0 "α" (.sortE (.succ level))
      (psLogicPi 1 "self" dictionary (psHashClass type (.succ level)) .instanceImplicit) .implicit)
    (psLogicLam 0 "α" (.sortE (.succ level))
      (psLogicLam 1 "self" dictionary (psHashValue type method (.succ level)) .instanceImplicit) .implicit)

def psHashContainerInstances : List PsDeclaration :=
  let u := psRootName "u"
  let level := PsLevel.param u
  let alpha := PsExpr.fvar 0
  let option := psSelfHostOptionOf alpha level
  let optionMethod := psLogicLam 2 "value" option
    (psLogicApply (.constE psSelfHostOptionRecName [.succ .zero, level])
      [alpha, psLogicLam 4 "_" option psHashUInt64, psHashSeed 11,
       psLogicLam 3 "value" alpha
         (psHashMix (psHashMethod alpha (.fvar 1) (.fvar 3) (.succ level)) (psHashSeed 13)), .fvar 2])
  let list := psSelfHostListOf alpha level
  let step := psLogicLam 3 "acc" psHashUInt64 (psLogicLam 4 "value" alpha
    (psHashMix (.fvar 3) (psHashMethod alpha (.fvar 1) (.fvar 4) (.succ level))))
  let listMethod := psLogicLam 2 "values" list
    (psStandardListCall "foldl" [psHashUInt64, alpha, step, psHashSeed 7, .fvar 2] [.zero, level])
  let array := psPreludeArrayOf alpha
  let arrayStep := psLogicLam 3 "acc" psHashUInt64 (psLogicLam 4 "value" alpha
    (psHashMix (.fvar 3) (psHashMethod alpha (.fvar 1) (.fvar 4))))
  let arrayMethod := psLogicLam 2 "values" array
    (psOrderCall "Array.foldl" [alpha, psHashUInt64, arrayStep, psHashSeed 7, .fvar 2,
      .lit (.natural 0), psStandardArraySize alpha (.fvar 2)])
  [ psHashContainer "Option" option optionMethod level [u],
    psHashContainer "List" list listMethod level [u],
    psHashContainer "Array" array arrayMethod .zero [] ]

def psHashProductInstance : PsDeclaration :=
  psStandardProductInstance "Prod" "Hashable"
    (fun type level => psHashClass type (.succ level))
    (fun type level method => psHashValue type method (.succ level))
    (fun alpha beta prod ul vl => psLogicLam 4 "value" prod
      (psHashMix
        (psHashMethod alpha (.fvar 2) (.proj psProdName 0 (.fvar 4)) (.succ ul))
        (psHashMethod beta (.fvar 3) (.proj psProdName 1 (.fvar 4)) (.succ vl))))

def psHashFinInstance : PsDeclaration :=
  let fin := psStandardFinOf (.fvar 0)
  .definitionDecl (psDecisionName "PsStandard.instHashableFin") []
    (psLogicPi 0 "n" psOrderNat (psHashClass fin))
    (psLogicLam 0 "n" psOrderNat (psHashValue fin
      (psLogicLam 1 "value" fin (psHashOfNat (psStandardFinVal (.fvar 0) (.fvar 1))))))

def psHashInstances : List PsDeclaration :=
  psHashGroundInstances ++ [psHashPropInstance, psHashProductInstance, psHashFinInstance] ++
    psHashContainerInstances

def psHash64Declaration : PsDeclaration :=
  .definitionDecl (psRootName "hash64") [] (psLogicPi 0 "value" psHashUInt64 psHashUInt64)
    (psLogicLam 0 "value" psHashUInt64 (psHashMix (.fvar 0) (psHashSeed 11)))

def psStandardHashableExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := (psStandardHashFoundationDeclarations ++ psHashInstances ++
    [psHash64Declaration]).foldl psEnvironmentInsert environment
  let environment := psStandardHashFoundationReducibility.foldl (fun env (name, status) =>
    psEnvironmentSetReducibility env name status) environment
  let environment := psStandardRegisterClass environment "Hashable"
  let environment := psStandardRegisterInstances environment "Hashable" psHashInstances
  { environment with exportedAliases :=
      (psRootName "hash", psDecisionName "Hashable.hash") :: environment.exportedAliases }

-- Proof/opaque inhabitant dependencies are logical-only. Runtime primitives
-- must go through the audited typed intrinsic boundary.
def psStandardHashRuntimeDeclarations : List PsDeclaration :=
  psStandardHashFoundationDeclarations.filter (fun d =>
    ["Hashable", "Hashable.mk", "Hashable.rec", "Hashable.hash"].contains
      (psNameToString (psDeclarationName d))) ++ psHashInstances ++ [psHash64Declaration]
