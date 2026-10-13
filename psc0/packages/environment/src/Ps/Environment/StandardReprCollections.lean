/-
Collection display follows Lean 4.35.0 Init/Data/Repr.lean,
Init/Data/Format/Instances.lean and Init/Data/Array/Basic.lean.
Copyright (c) Microsoft Corporation. Author: Leonardo de Moura.
Apache-2.0; see THIRD_PARTY_NOTICES.md.
Modified: checked Core builders; Prod/Array retain the selected Type-0 model.
-/
import Ps.Environment.StandardRepr
import Ps.Environment.StandardArray
import Ps.Environment.StandardFormatString

def psReprTupleClassDeclarations : List PsDeclaration :=
  let list := psSelfHostListOf psFormatType
  psStandardMethodClass (psRootName "ReprTuple") "reprTuple"
    (psLogicPi 2 "value" (.fvar 0) (psLogicPi 3 "tail" list list))

def psReprTupleDefault : PsDeclaration :=
  let u := psRootName "u"
  let level := PsLevel.param u
  let alpha := PsExpr.fvar 0
  let list := psSelfHostListOf psFormatType
  let method := psLogicLam 2 "value" alpha (psLogicLam 3 "tail" list
    (psSelfHostListConsOf psFormatType
      (psReprPrec alpha (.fvar 1) (.fvar 2) (psFormatNat 0) level) (.fvar 3)))
  let dictionary := psFormatClassType "Repr" alpha level
  .definitionDecl (psDecisionName "PsStandard.instReprTupleOfRepr") [u]
    (psLogicPi 0 "α" (.sortE (.succ level))
      (psLogicPi 1 "self" dictionary (psFormatClassType "ReprTuple" alpha level) .instanceImplicit) .implicit)
    (psLogicLam 0 "α" (.sortE (.succ level))
      (psLogicLam 1 "self" dictionary
        (psFormatClassValue "ReprTuple" alpha method level) .instanceImplicit) .implicit)

def psFormatProductDefinition (name leftClass rightClass : String)
    (result value : PsExpr) : PsDeclaration :=
  let left := psFormatClassType leftClass (.fvar 0)
  let right := psFormatClassType rightClass (.fvar 1)
  let close := fun body lambda =>
    let bind := fun id name type body binder =>
      if lambda then psLogicLam id name type body binder else psLogicPi id name type body binder
    bind 0 "α" psPreludeTypeType (bind 1 "β" psPreludeTypeType
      (bind 2 "left" left (bind 3 "right" right body .instanceImplicit) .instanceImplicit)
      .implicit) .implicit
  .definitionDecl (psDecisionName name) [] (close result false) (close value true)

def psReprProductDeclarations : List PsDeclaration :=
  let alpha := PsExpr.fvar 0
  let beta := PsExpr.fvar 1
  let prod := psStandardProductOf alpha beta
  let list := psSelfHostListOf psFormatType
  let first := psReprPrec alpha (.fvar 2) (.proj psProdName 0 (.fvar 4)) (psFormatNat 0)
  let second := psFormatClassMethod "ReprTuple" "reprTuple" beta (.fvar 3)
  let gather := fun tail => psLogicApply second
    [.proj psProdName 1 (.fvar 4), psSelfHostListConsOf psFormatType first tail]
  let tupleType := psLogicPi 4 "value" prod (psLogicPi 5 "tail" list list)
  let tupleMethod := psLogicLam 4 "value" prod (psLogicLam 5 "tail" list (gather (.fvar 5)))
  let reversed := psStandardListCall "reverse"
    [psFormatType, gather (psSelfHostListNilOf psFormatType)]
  let identity := psFormatClassValue "Std.ToFormat" psFormatType
    (psLogicLam 7 "f" psFormatType (.fvar 7))
  let joined := psLogicApply (.constE (psDecisionName "Std.Format.joinSep") [.zero])
    [psFormatType, identity, reversed,
     psFormatCall "append" [psReprText ",", psFormatCall "line"]]
  let reprType := psLogicPi 4 "value" prod (psLogicPi 5 "prec" psOrderNat psFormatType)
  let reprMethod := psLogicLam 4 "value" prod (psLogicLam 5 "prec" psOrderNat
    (psFormatCall "bracket" [.lit (.string "("), joined, .lit (.string ")")]))
  let make := fun name result value => psFormatProductDefinition name "Repr" "ReprTuple" result value
  [ make "Prod.reprTuple" tupleType tupleMethod,
    make "Prod.repr" reprType reprMethod,
    make "PsStandard.instReprTupleProd" (psFormatClassType "ReprTuple" prod)
      (psFormatClassValue "ReprTuple" prod (psOrderCall "Prod.reprTuple" [alpha, beta, .fvar 2, .fvar 3])),
    make "PsStandard.instReprProd" (psFormatClassType "Repr" prod)
      (psFormatClassValue "Repr" prod (psOrderCall "Prod.repr" [alpha, beta, .fvar 2, .fvar 3])) ]

def psToFormatProductInstance : PsDeclaration :=
  let alpha := PsExpr.fvar 0
  let beta := PsExpr.fvar 1
  let prod := psStandardProductOf alpha beta
  let left := PsExpr.app (psFormatClassMethod "Std.ToFormat" "format" alpha (.fvar 2))
    (.proj psProdName 0 (.fvar 4))
  let right := PsExpr.app (psFormatClassMethod "Std.ToFormat" "format" beta (.fvar 3))
    (.proj psProdName 1 (.fvar 4))
  let append := fun a b => psFormatCall "append" [a, b]
  let method := psLogicLam 4 "value" prod
    (psFormatCall "paren" [append (append (append left (psReprText ",")) (psFormatCall "line")) right])
  psFormatProductDefinition "PsStandard.instToFormatProd" "Std.ToFormat" "Std.ToFormat"
    (psFormatClassType "Std.ToFormat" prod) (psFormatClassValue "Std.ToFormat" prod method)

def psDisplayArrayDeclarations : List PsDeclaration :=
  let alpha := PsExpr.fvar 0
  let array := psPreludeArrayOf alpha
  let list := psStandardArrayToList alpha (.fvar 2)
  let asFormat := psFormatClassValue "Std.ToFormat" alpha
    (psLogicLam 4 "value" alpha (psReprPrec alpha (.fvar 1) (.fvar 4) (psFormatNat 0)))
  let joined := psLogicApply (.constE (psDecisionName "Std.Format.joinSep") [.zero])
    [alpha, asFormat, list, psFormatCall "append" [psReprText ",", psFormatCall "line"]]
  let body := psFormatIf psFormatType
    (psOrderCall "Nat.beq" [psStandardArraySize alpha (.fvar 2), psFormatNat 0])
    (psReprText "#[]")
    (psFormatCall "bracketFill" [.lit (.string "#["), joined, .lit (.string "]")])
  let reprMethod := psLogicLam 2 "value" array body
  let reprDecl := psFormatContainerMethodDeclaration "Array.repr" "Repr"
    (psLogicPi 2 "value" array psFormatType) reprMethod .zero []
  let repr := psFormatContainerDeclaration "PsStandard.instReprArray" "Repr" array
    (psLogicLam 2 "value" array (psLogicLam 3 "prec" psOrderNat
      (psOrderCall "Array.repr" [alpha, .fvar 1, .fvar 2]))) .zero []
  let formatMethod := psLogicLam 2 "value" array
    (psFormatCall "append" [psReprText "#",
      psLogicApply (.constE (psDecisionName "List.format") [.zero]) [alpha, .fvar 1, list]])
  let format := psFormatContainerDeclaration "PsStandard.instToFormatArray" "Std.ToFormat"
    array formatMethod .zero []
  [reprDecl, repr, format]

def psReprFinInstance : PsDeclaration :=
  let fin := psStandardFinOf (.fvar 0)
  let method := psLogicLam 1 "value" fin (psLogicLam 2 "prec" psOrderNat
    (psFormatCall "text" [.app (.constE psIntReprName [])
      (psFormatInt (psStandardFinVal (.fvar 0) (.fvar 1)))]))
  .definitionDecl (psDecisionName "PsStandard.instReprFin") []
    (psLogicPi 0 "n" psOrderNat (psFormatClassType "Repr" fin))
    (psLogicLam 0 "n" psOrderNat (psFormatClassValue "Repr" fin method))

-- The explicit Id instance follows upstream's instance-transparency boundary.
def psReprIdInstance : PsDeclaration :=
  let u := psRootName "u"
  let level := PsLevel.param u
  let alpha := PsExpr.fvar 0
  let id := PsExpr.app (.constE (psRootName "Id") [level]) alpha
  let dictionary := psFormatClassType "Repr" alpha level
  .definitionDecl (psDecisionName "PsStandard.instReprId") [u]
    (psLogicPi 0 "α" (.sortE (.succ level))
      (psLogicPi 1 "self" dictionary (psFormatClassType "Repr" id level) .instanceImplicit) .implicit)
    (psLogicLam 0 "α" (.sortE (.succ level))
      (psLogicLam 1 "self" dictionary (.fvar 1) .instanceImplicit) .implicit)

def psStandardReprCollectionDeclarations : List PsDeclaration :=
  psReprTupleClassDeclarations ++ [psReprTupleDefault] ++ psReprProductDeclarations ++
    [psToFormatProductInstance] ++ psDisplayArrayDeclarations ++ [psReprFinInstance, psReprIdInstance]

def psStandardReprCollectionsExtend (environment : PsEnvironment) : PsEnvironment :=
  let environment := psStandardReprCollectionDeclarations.foldl psPreludeAdd environment
  let environment := psFormatRegisterClass environment "ReprTuple"
  let pick := fun declarations suffix => declarations.filter fun declaration =>
    psNameLastComponent (psDeclarationName declaration) == suffix
  let environment := psFormatRegister environment "ReprTuple"
    ([psReprTupleDefault] ++ pick psReprProductDeclarations "instReprTupleProd")
  let environment := psFormatRegister environment "Repr"
    (pick psReprProductDeclarations "instReprProd" ++ pick psDisplayArrayDeclarations "instReprArray" ++
     [psReprFinInstance, psReprIdInstance])
  let environment := psFormatRegister environment "Std.ToFormat"
    ([psToFormatProductInstance] ++ pick psDisplayArrayDeclarations "instToFormatArray")
  { environment with exportedAliases :=
      (psRootName "reprTuple", psDecisionName "ReprTuple.reprTuple") :: environment.exportedAliases }
