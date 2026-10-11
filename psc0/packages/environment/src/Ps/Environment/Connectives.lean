import Ps.Environment.Logic

-- These are checked Core declarations, not additional logical axioms.
-- And and Iff permit singleton elimination; Or and Exists eliminate into Prop.
def psLogicBinaryStructure (text : String) (equivalence : Bool) : List PsDeclaration :=
  let name := psRootName text
  let ctor := psNameAppendStr name "intro"
  let u := psRootName "u"
  let prop := PsExpr.sortE .zero
  let p := PsExpr.fvar 0
  let q := PsExpr.fvar 1
  let left := if equivalence then psLogicPi 7 "_" p q else p
  let right := if equivalence then psLogicPi 7 "_" q p else q
  let target := psLogicApply (.constE name []) [p, q]
  let params := fun body => psLogicPi 0 "a" prop (psLogicPi 1 "b" prop body .implicit) .implicit
  let publicParams := fun body => psLogicPi 0 "a" prop (psLogicPi 1 "b" prop body)
  let intro := psLogicApply (.constE ctor []) [p, q, .fvar 3, .fvar 4]
  let motiveType := psLogicPi 5 "h" target (.sortE (.param u))
  let minorType := psLogicPi 3 (if equivalence then "mp" else "left") left
    (psLogicPi 4 (if equivalence then "mpr" else "right") right (.app (.fvar 2) intro))
  let recType := params (psLogicPi 2 "motive" motiveType
    (psLogicPi 6 "intro" minorType (psLogicPi 5 "h" target (.app (.fvar 2) (.fvar 5)))) .implicit)
  let projection := fun (field : String) (index : Nat) (type : PsExpr) =>
    PsDeclaration.definitionDecl (psNameAppendStr name field) []
      (params (psLogicPi 5 "self" target type))
      (psLogicLam 0 "a" prop (psLogicLam 1 "b" prop
        (psLogicLam 5 "self" target (.proj name index (.fvar 5))) .implicit) .implicit)
  [ .inductiveDecl (.mk name [] (publicParams prop) 2 0 [ctor] true),
    .constructorDecl (.mk ctor [] (params (psLogicPi 3 "left" left
      (psLogicPi 4 "right" right target))) name 0 2 2 []),
    .recursorDecl (.mk (psNameAppendStr name "rec") [u] recType [name] 2 0 1 1),
    projection (if equivalence then "mp" else "left") 0 left,
    projection (if equivalence then "mpr" else "right") 1 right ]

def psLogicOrDeclarations : List PsDeclaration :=
  let name := psRootName "Or"
  let inl := psNameAppendStr name "inl"
  let inr := psNameAppendStr name "inr"
  let prop := PsExpr.sortE .zero
  let p := PsExpr.fvar 0
  let q := PsExpr.fvar 1
  let target := psLogicApply (.constE name []) [p, q]
  let params := fun body => psLogicPi 0 "a" prop (psLogicPi 1 "b" prop body .implicit) .implicit
  let publicParams := fun body => psLogicPi 0 "a" prop (psLogicPi 1 "b" prop body)
  let minor := fun (ctor : PsName) (type : PsExpr) => psLogicPi 3 "h" type
    (.app (.fvar 2) (psLogicApply (.constE ctor []) [p, q, .fvar 3]))
  let recType := params (psLogicPi 2 "motive" (psLogicPi 3 "h" target prop)
    (psLogicPi 4 "inl" (minor inl p) (psLogicPi 5 "inr" (minor inr q)
      (psLogicPi 6 "h" target (.app (.fvar 2) (.fvar 6))))) .implicit)
  [ .inductiveDecl (.mk name [] (publicParams prop) 2 0 [inl, inr] false),
    .constructorDecl (.mk inl [] (params (psLogicPi 3 "h" p target)) name 0 2 1 []),
    .constructorDecl (.mk inr [] (params (psLogicPi 3 "h" q target)) name 1 2 1 []),
    .recursorDecl (.mk (psNameAppendStr name "rec") [] recType [name] 2 0 1 2) ]

def psLogicExistsDeclarations : List PsDeclaration :=
  let name := psRootName "Exists"
  let ctor := psNameAppendStr name "intro"
  let u := psRootName "u"
  let prop := PsExpr.sortE .zero
  let sort := PsExpr.sortE (.param u)
  let alpha := PsExpr.fvar 0
  let predicate := PsExpr.fvar 1
  let predicateType := psLogicPi 3 "a" alpha prop
  let target := psLogicApply (.constE name [.param u]) [alpha, predicate]
  let params := fun body => psLogicPi 0 "α" sort
    (psLogicPi 1 "p" predicateType body .implicit) .implicit
  let fields := fun body => psLogicPi 3 "w" alpha
    (psLogicPi 4 "h" (.app predicate (.fvar 3)) body)
  let intro := psLogicApply (.constE ctor [.param u]) [alpha, predicate, .fvar 3, .fvar 4]
  let recType := params (psLogicPi 2 "motive" (psLogicPi 5 "h" target prop)
    (psLogicPi 6 "intro" (fields (.app (.fvar 2) intro))
      (psLogicPi 5 "h" target (.app (.fvar 2) (.fvar 5)))) .implicit)
  [ .inductiveDecl (.mk name [u] (psLogicPi 0 "α" sort
      (psLogicPi 1 "p" predicateType prop) .implicit) 2 0 [ctor] false),
    .constructorDecl (.mk ctor [u] (params (fields target)) name 0 2 2 []),
    .recursorDecl (.mk (psNameAppendStr name "rec") [u] recType [name] 2 0 1 1) ]

def psConnectiveDeclarations : List PsDeclaration :=
  let prop := PsExpr.sortE .zero
  psLogicBinaryStructure "And" false ++ psLogicBinaryStructure "Iff" true ++
    psLogicOrDeclarations ++ psLogicExistsDeclarations ++ [
      .definitionDecl (psRootName "Not") [] (psLogicPi 0 "a" prop prop)
        (psLogicLam 0 "a" prop (psLogicPi 1 "_" (.fvar 0) (.constE (psRootName "False") []))) ]

def psConnectivePrelude (environment : PsEnvironment) : PsEnvironment :=
  psConnectiveDeclarations.foldl (fun current declaration =>
    (psEnvironmentAdd current declaration).getD current) environment
