import Ps.Environment.Basic
import Ps.Core.Abstract
import Ps.Core.Builtin

-- Logical primitives are genuine inductives/definitions in the checked
-- prelude. No proof automation axiom or host elaborator service is introduced.
def psLogicPi (id : Nat) (name : String) (type body : PsExpr)
    (binder : PsBinderInfo := .explicit) : PsExpr :=
  .forallE (psRootName name) type (psExprAbstractFVar id body) binder

def psLogicLam (id : Nat) (name : String) (type body : PsExpr)
    (binder : PsBinderInfo := .explicit) : PsExpr :=
  .lam (psRootName name) type (psExprAbstractFVar id body) binder

def psLogicApply (head : PsExpr) (arguments : List PsExpr) : PsExpr :=
  arguments.foldl PsExpr.app head

def psLogicEq (level : PsLevel) (type left right : PsExpr) : PsExpr :=
  psLogicApply (.constE psEqName [level]) [type, left, right]

def psLogicRefl (level : PsLevel) (type value : PsExpr) : PsExpr :=
  psLogicApply (.constE (psNameAppendStr psEqName "refl") [level]) [type, value]

-- RC4 Init.Prelude declares Empty : Type with no constructors. It is a
-- runtime type (unlike False : Prop), so its declarations also belong to the
-- runtime prelude catalogue.
def psEmptyDeclarations : List PsDeclaration :=
  let name := psRootName "Empty"
  let u := psRootName "u"
  let type := PsExpr.constE name []
  let motiveType := psLogicPi 1 "value" type (.sortE (.param u))
  let recursorType := psLogicPi 0 "motive" motiveType
    (psLogicPi 1 "value" type (.app (.fvar 0) (.fvar 1))) .implicit
  [ .inductiveDecl (.mk name [] (.sortE (.succ .zero)) 0 0 [] false),
    .recursorDecl (.mk (psNameAppendStr name "rec") [u] recursorType [name] 0 0 1 0) ]

-- Lean 4.35.0-rc4, Init/Prelude.lean: proposition-valued natural order.
-- This is the actual inductive Nat.le, not an axiom, Nat.blt Boolean, or an
-- asserted conversion from a runtime comparison into erased proof evidence.
-- The Nat.lt definition is exactly Nat.le (Nat.succ n) m. General decidability,
-- automation and proof-bearing collection workers are separate dependencies.
def psNatOrderDeclarations : List PsDeclaration :=
  let nat := PsExpr.constE psNatName []
  let prop := PsExpr.sortE .zero
  let leName := psNameAppendStr psNatName "le"
  let reflName := psNameAppendStr leName "refl"
  let stepName := psNameAppendStr leName "step"
  let ltName := psNameAppendStr psNatName "lt"
  let n := PsExpr.fvar 0
  let m := PsExpr.fvar 1
  let h := PsExpr.fvar 2
  let le := fun (a b : PsExpr) =>
    psLogicApply (.constE leName []) [a, b]
  let succ := fun (a : PsExpr) => .app (.constE psNatSuccName []) a
  let inductiveType := psLogicPi 0 "n" nat (psLogicPi 1 "m" nat prop)
  let reflType := psLogicPi 0 "n" nat (le n n) .implicit
  let stepType := psLogicPi 0 "n" nat
    (psLogicPi 1 "m" nat
      (psLogicPi 2 "h" (le n m) (le n (succ m)))
      .implicit) .implicit
  let ltType := psLogicPi 0 "n" nat (psLogicPi 1 "m" nat prop)
  let ltValue := psLogicLam 0 "n" nat
    (psLogicLam 1 "m" nat (le (succ n) m))
  [ .inductiveDecl (.mk leName [] inductiveType 1 1
        [reflName, stepName] false),
    .constructorDecl (.mk reflName [] reflType leName 0 1 0 []),
    .constructorDecl (.mk stepName [] stepType leName 1 1 2 [1]),
    .definitionDecl ltName [] ltType ltValue ]

def psLogicDeclarations : List PsDeclaration :=
  let u := psRootName "u"
  let v := psRootName "v"
  let alpha := PsExpr.fvar 0
  let a := PsExpr.fvar 1
  let motive := PsExpr.fvar 2
  let minor := PsExpr.fvar 3
  let b := PsExpr.fvar 4
  let h := PsExpr.fvar 5
  let sort := PsExpr.sortE (.param u)
  let resultSort := PsExpr.sortE (.param v)
  let prop := PsExpr.sortE .zero
  let eq := psLogicEq (.param u) alpha
  let refl := psLogicRefl (.param u) alpha a
  let motiveType := psLogicPi 4 "b" alpha (psLogicPi 5 "h" (eq a b) resultSort)
  let eqType := psLogicPi 0 "α" sort
    (psLogicPi 1 "a" alpha (psLogicPi 4 "b" alpha prop)) .implicit
  let reflType := psLogicPi 0 "α" sort (psLogicPi 1 "a" alpha (eq a a)) .implicit
  let recType := psLogicPi 0 "α" sort
    (psLogicPi 1 "a" alpha
      (psLogicPi 2 "motive" motiveType
        (psLogicPi 3 "refl" (psLogicApply motive [a, refl])
          (psLogicPi 4 "b" alpha
            (psLogicPi 5 "h" (eq a b) (psLogicApply motive [b, h])) .implicit)) .implicit) .implicit) .implicit
  let falseName := psRootName "False"
  let falseType := PsExpr.constE falseName []
  let trueName := psRootName "True"
  let trueType := PsExpr.constE trueName []
  let introName := psNameAppendStr trueName "intro"
  let falseMotive := psLogicPi 5 "h" falseType sort
  let falseRecType := psLogicPi 2 "motive" falseMotive
    (psLogicPi 5 "h" falseType (.app motive h)) .implicit
  let elimType := psLogicPi 0 "α" sort (psLogicPi 5 "h" falseType alpha) .implicit
  let elimValue := psLogicLam 0 "α" sort
    (psLogicLam 5 "h" falseType
      (psLogicApply (.constE (psNameAppendStr falseName "rec") [.param u])
        [psLogicLam 6 "_" falseType alpha, h])) .implicit
  let boolType := PsExpr.constE psBoolName []
  let boolMotive := psLogicPi 5 "value" boolType sort
  let boolRecType := psLogicPi 2 "motive" boolMotive
    (psLogicPi 3 "false" (.app motive (.constE psBoolFalseName []))
      (psLogicPi 4 "true" (.app motive (.constE psBoolTrueName []))
        (psLogicPi 5 "value" boolType (.app motive h)))) .implicit
  let trueRecType := psLogicPi 2 "motive" (psLogicPi 5 "h" trueType sort)
    (psLogicPi 3 "intro" (.app motive (.constE introName []))
      (psLogicPi 5 "h" trueType (.app motive h))) .implicit
  psEmptyDeclarations ++ [
    .inductiveDecl (.mk psEqName [u] eqType 2 1 [psNameAppendStr psEqName "refl"] false),
    .constructorDecl (.mk (psNameAppendStr psEqName "refl") [u] reflType psEqName 0 2 0 []),
    .recursorDecl (.mk (psNameAppendStr psEqName "rec") [v, u] recType [psEqName] 2 1 1 1),
    .inductiveDecl (.mk falseName [] prop 0 0 [] false),
    .recursorDecl (.mk (psNameAppendStr falseName "rec") [u] falseRecType [falseName] 0 0 1 0),
    .definitionDecl (psNameAppendStr falseName "elim") [u] elimType elimValue,
    .inductiveDecl (.mk trueName [] prop 0 0 [introName] false),
    .constructorDecl (.mk introName [] trueType trueName 0 0 0 []),
    .recursorDecl (.mk (psNameAppendStr trueName "rec") [u] trueRecType [trueName] 0 0 1 1),
    .inductiveDecl (.mk psBoolName [] (.sortE (.succ .zero)) 0 0 [psBoolFalseName, psBoolTrueName] false),
    .constructorDecl (.mk psBoolFalseName [] boolType psBoolName 0 0 0 []),
    .constructorDecl (.mk psBoolTrueName [] boolType psBoolName 1 0 0 []),
    .recursorDecl (.mk (psNameAppendStr psBoolName "rec") [u] boolRecType [psBoolName] 0 0 1 2)
  ] ++ psNatOrderDeclarations

def psLogicPrelude (environment : PsEnvironment) : PsEnvironment :=
  psLogicDeclarations.foldl (fun current declaration =>
    (psEnvironmentAddReplacingAxiom current declaration).getD current) environment
