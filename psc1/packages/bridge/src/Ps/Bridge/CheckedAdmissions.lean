import Ps.Bridge.Json
import Ps.Core.Declaration
import Ps.Core.Abstract
import Ps.Core.Subst
import Ps.Core.Equality
import Ps.Foundation.List
import Ps.Environment.Basic

inductive PsCheckedAdmissionCodecError where
  | universeMetavariable
  | freeVariable
  | expressionMetavariable
  | missingConstructor (name : PsName)
  | mismatchedConstructor (name : PsName)
  | unsupportedDeclaration

def psCheckedAdmissionBoolNot (value : Bool) : Bool :=
  if value then false else true

def psCheckedAdmissionJsonField
    (key value : String) : Prod String String :=
  Prod.mk key value

def psCheckedAdmissionIncrementDecimalDigits
    (digits : List Nat) : List Nat :=
  match digits with
  | List.nil =>
      List.cons 1 List.nil
  | List.cons digit rest =>
      if Nat.beq digit 9 then
        List.cons
          0
          (psCheckedAdmissionIncrementDecimalDigits rest)
      else
        List.cons (Nat.succ digit) rest

def psCheckedAdmissionDecimalDigits
    (value : Nat) : List Nat :=
  match value with
  | Nat.zero =>
      List.cons 0 List.nil
  | Nat.succ predecessor =>
      psCheckedAdmissionIncrementDecimalDigits
        (psCheckedAdmissionDecimalDigits predecessor)

def psCheckedAdmissionDecimalDigitsToString
    (digits : List Nat) : String :=
  match digits with
  | List.nil =>
      ""
  | List.cons digit rest =>
      String.Internal.append
        (psCheckedAdmissionDecimalDigitsToString rest)
        (String.singleton
          (Char.ofNat (Nat.add 48 digit)))

def psCheckedAdmissionNatToString
    (value : Nat) : String :=
  Int.repr (Int.ofNat value)

def psEncodeCodecName (name : PsName) : String :=
  match name with
  | .anonymous =>
      psJsonObject [
        Prod.mk "k" (psJsonQuote "a")
      ]
  | .str parent value =>
      let encodedParent : String :=
        psEncodeCodecName parent;
      psJsonObject [
        psCheckedAdmissionJsonField "k" (psJsonQuote "s"),
        psCheckedAdmissionJsonField "p" encodedParent,
        psCheckedAdmissionJsonField "v" (psJsonQuote value)
      ]
  | .num parent value =>
      let encodedParent : String :=
        psEncodeCodecName parent;
      psJsonObject [
        psCheckedAdmissionJsonField "k" (psJsonQuote "n"),
        psCheckedAdmissionJsonField "p" encodedParent,
        psCheckedAdmissionJsonField "v" (psJsonQuote (psCheckedAdmissionNatToString value))
      ]

def psEncodeCodecLevel
    (level : PsLevel) :
    Except PsCheckedAdmissionCodecError String :=
  match level with
  | .zero =>
      Except.ok
        (psJsonObject [
          psCheckedAdmissionJsonField "k" (psJsonQuote "z")
        ])
  | .succ inner =>
      match psEncodeCodecLevel inner with
      | Except.error error => Except.error error
      | Except.ok encoded =>
          Except.ok
            (psJsonObject [
              psCheckedAdmissionJsonField "k" (psJsonQuote "s"),
              psCheckedAdmissionJsonField "o" (encoded)
            ])
  | .max left right =>
      match psEncodeCodecLevel left with
      | Except.error error => Except.error error
      | Except.ok encodedLeft =>
          match psEncodeCodecLevel right with
          | Except.error error => Except.error error
          | Except.ok encodedRight =>
              Except.ok
                (psJsonObject [
                  psCheckedAdmissionJsonField "k" (psJsonQuote "max"),
                  psCheckedAdmissionJsonField "l" (encodedLeft),
                  psCheckedAdmissionJsonField "r" (encodedRight)
                ])
  | .imax left right =>
      match psEncodeCodecLevel left with
      | Except.error error => Except.error error
      | Except.ok encodedLeft =>
          match psEncodeCodecLevel right with
          | Except.error error => Except.error error
          | Except.ok encodedRight =>
              Except.ok
                (psJsonObject [
                  psCheckedAdmissionJsonField "k" (psJsonQuote "imax"),
                  psCheckedAdmissionJsonField "l" (encodedLeft),
                  psCheckedAdmissionJsonField "r" (encodedRight)
                ])
  | .param name =>
      Except.ok
        (psJsonObject [
          psCheckedAdmissionJsonField "k" (psJsonQuote "p"),
          psCheckedAdmissionJsonField "n" (psEncodeCodecName name)
        ])
  | .mvar _ =>
      Except.error PsCheckedAdmissionCodecError.universeMetavariable

def psEncodeCodecBinderInfo (binder : PsBinderInfo) : String :=
  match binder with
  | .explicit => "default"
  | .implicit => "implicit"
  | .strictImplicit => "strictImplicit"
  | .instanceImplicit => "instImplicit"

def psEncodeCodecLevelList
    (levels : List PsLevel) :
    Except PsCheckedAdmissionCodecError (List String) :=
  match levels with
  | List.nil =>
      Except.ok List.nil
  | List.cons level rest =>
      match psEncodeCodecLevel level with
      | Except.error error =>
          Except.error error
      | Except.ok encodedHead =>
          match psEncodeCodecLevelList rest with
          | Except.error error =>
              Except.error error
          | Except.ok encodedTail =>
              Except.ok (List.cons encodedHead encodedTail)

def psEncodeCodecLevels
    (levels : List PsLevel) :
    Except PsCheckedAdmissionCodecError String :=
  match psEncodeCodecLevelList levels with
  | Except.error error => Except.error error
  | Except.ok encoded => Except.ok (psJsonArray encoded)

def psEncodeCodecExpr
    (expr : PsExpr) :
    Except PsCheckedAdmissionCodecError String :=
  match expr with
  | .bvar index =>
      Except.ok
        (psJsonObject [
          psCheckedAdmissionJsonField "i" (psCheckedAdmissionNatToString index),
          psCheckedAdmissionJsonField "k" (psJsonQuote "b")
        ])
  | .fvar _ =>
      Except.error PsCheckedAdmissionCodecError.freeVariable
  | .mvar _ =>
      Except.error PsCheckedAdmissionCodecError.expressionMetavariable
  | .sortE level =>
      match psEncodeCodecLevel level with
      | Except.error error => Except.error error
      | Except.ok encodedLevel =>
          Except.ok
            (psJsonObject [
              psCheckedAdmissionJsonField "k" (psJsonQuote "sort"),
              psCheckedAdmissionJsonField "l" (encodedLevel)
            ])
  | .constE name levels =>
      match psEncodeCodecLevels levels with
      | Except.error error => Except.error error
      | Except.ok encodedLevels =>
          Except.ok
            (psJsonObject [
              psCheckedAdmissionJsonField "k" (psJsonQuote "const"),
              psCheckedAdmissionJsonField "ls" (encodedLevels),
              psCheckedAdmissionJsonField "n" (psEncodeCodecName name)
            ])
  | .app fn arg =>
      match psEncodeCodecExpr arg with
      | Except.error error => Except.error error
      | Except.ok encodedArg =>
          match psEncodeCodecExpr fn with
          | Except.error error => Except.error error
          | Except.ok encodedFn =>
              Except.ok
                (psJsonObject [
                  psCheckedAdmissionJsonField "a" (encodedArg),
                  psCheckedAdmissionJsonField "f" (encodedFn),
                  psCheckedAdmissionJsonField "k" (psJsonQuote "app")
                ])
  | .lam name type body binder =>
      match psEncodeCodecExpr body with
      | Except.error error => Except.error error
      | Except.ok encodedBody =>
          match psEncodeCodecExpr type with
          | Except.error error => Except.error error
          | Except.ok encodedType =>
              Except.ok
                (psJsonObject [
                  psCheckedAdmissionJsonField "b" (encodedBody),
                  psCheckedAdmissionJsonField "bi" (psJsonQuote (psEncodeCodecBinderInfo binder)),
                  psCheckedAdmissionJsonField "k" (psJsonQuote "lam"),
                  psCheckedAdmissionJsonField "n" (psEncodeCodecName name),
                  psCheckedAdmissionJsonField "t" (encodedType)
                ])
  | .forallE name type body binder =>
      match psEncodeCodecExpr body with
      | Except.error error => Except.error error
      | Except.ok encodedBody =>
          match psEncodeCodecExpr type with
          | Except.error error => Except.error error
          | Except.ok encodedType =>
              Except.ok
                (psJsonObject [
                  psCheckedAdmissionJsonField "b" (encodedBody),
                  psCheckedAdmissionJsonField "bi" (psJsonQuote (psEncodeCodecBinderInfo binder)),
                  psCheckedAdmissionJsonField "k" (psJsonQuote "forall"),
                  psCheckedAdmissionJsonField "n" (psEncodeCodecName name),
                  psCheckedAdmissionJsonField "t" (encodedType)
                ])
  | .letE name type value body =>
      match psEncodeCodecExpr body with
      | Except.error error => Except.error error
      | Except.ok encodedBody =>
          match psEncodeCodecExpr type with
          | Except.error error => Except.error error
          | Except.ok encodedType =>
              match psEncodeCodecExpr value with
              | Except.error error => Except.error error
              | Except.ok encodedValue =>
                  Except.ok
                    (psJsonObject [
                      psCheckedAdmissionJsonField "b" (encodedBody),
                      psCheckedAdmissionJsonField "k" (psJsonQuote "let"),
                      psCheckedAdmissionJsonField "n" (psEncodeCodecName name),
                      psCheckedAdmissionJsonField "t" (encodedType),
                      psCheckedAdmissionJsonField "v" (encodedValue)
                    ])
  | .lit literal =>
      match literal with
      | .natural value =>
          Except.ok
            (psJsonObject [
              psCheckedAdmissionJsonField "k" (psJsonQuote "nat"),
              psCheckedAdmissionJsonField "v" (psJsonQuote (psCheckedAdmissionNatToString value))
            ])
      | .string value =>
          Except.ok
            (psJsonObject [
              psCheckedAdmissionJsonField "k" (psJsonQuote "str"),
              psCheckedAdmissionJsonField "v" (psJsonQuote value)
            ])
  | .proj typeName index value =>
      match psEncodeCodecExpr value with
      | Except.error error => Except.error error
      | Except.ok encodedValue =>
          Except.ok
            (psJsonObject [
              psCheckedAdmissionJsonField "e" (encodedValue),
              psCheckedAdmissionJsonField "i" (psCheckedAdmissionNatToString index),
              psCheckedAdmissionJsonField "k" (psJsonQuote "proj"),
              psCheckedAdmissionJsonField "n" (psEncodeCodecName typeName)
            ])

def psEncodeCodecNames
    (names : List PsName) : List String :=
  match names with
  | List.nil =>
      List.nil
  | List.cons name rest =>
      List.cons
        (psEncodeCodecName name)
        (psEncodeCodecNames rest)

def psEncodeCodecNameList (names : List PsName) : String :=
  psJsonArray (psEncodeCodecNames names)

def psBridgeFindConstructor
    (declarations : List PsDeclaration) :
    PsName -> Option PsConstructorInfo :=
  match declarations with
  | List.nil =>
      fun (_name : PsName) => Option.none
  | List.cons declaration rest =>
      let smaller : PsName -> Option PsConstructorInfo :=
        psBridgeFindConstructor rest;
      fun (name : PsName) =>
        match declaration with
        | .constructorDecl info =>
            if psNameEq info.name name then
              Option.some info
            else
              smaller name
        | _ =>
            smaller name

def psEncodeCodecConstructor
    (allDeclarations : List PsDeclaration)
    (inductiveName : PsName)
    (constructorName : PsName) :
    Except PsCheckedAdmissionCodecError String :=
  match psBridgeFindConstructor allDeclarations constructorName with
  | none =>
      Except.error
        (PsCheckedAdmissionCodecError.missingConstructor constructorName)
  | some info =>
      if psCheckedAdmissionBoolNot (psNameEq info.inductiveName inductiveName) then
        Except.error
          (PsCheckedAdmissionCodecError.mismatchedConstructor constructorName)
      else
        match psEncodeCodecExpr info.type with
        | Except.error error => Except.error error
        | Except.ok encodedType =>
            Except.ok
              (psJsonObject [
                psCheckedAdmissionJsonField "n" (psEncodeCodecName info.name),
                psCheckedAdmissionJsonField "t" (encodedType)
              ])

def psEncodeCodecConstructors
    (allDeclarations : List PsDeclaration)
    (inductiveName : PsName)
    (constructors : List PsName) :
    Except PsCheckedAdmissionCodecError (List String) :=
  match constructors with
  | List.nil =>
      Except.ok List.nil
  | List.cons constructorName rest =>
      match
          psEncodeCodecConstructor
            allDeclarations
            inductiveName
            constructorName with
      | Except.error error =>
          Except.error error
      | Except.ok encodedHead =>
          match
              psEncodeCodecConstructors
                allDeclarations
                inductiveName
                rest with
          | Except.error error =>
              Except.error error
          | Except.ok encodedTail =>
              Except.ok (List.cons encodedHead encodedTail)

def psEncodeCodecInductive
    (allDeclarations : List PsDeclaration)
    (info : PsInductiveInfo) :
    Except PsCheckedAdmissionCodecError String :=
  match
      psEncodeCodecConstructors
        allDeclarations
        info.name
        info.constructors with
  | Except.error error => Except.error error
  | Except.ok encodedConstructors =>
      match psEncodeCodecExpr info.type with
      | Except.error error => Except.error error
      | Except.ok encodedType =>
          let encodedTypeEntry :=
            psJsonObject [
              psCheckedAdmissionJsonField "cs" (psJsonArray encodedConstructors),
              psCheckedAdmissionJsonField "n" (psEncodeCodecName info.name),
              psCheckedAdmissionJsonField "t" (encodedType)
            ];
          Except.ok
            (psJsonObject [
              psCheckedAdmissionJsonField "lp" (psEncodeCodecNameList info.levelParams),
              psCheckedAdmissionJsonField "np" (psCheckedAdmissionNatToString info.numParams),
              psCheckedAdmissionJsonField "ts" (psJsonArray [encodedTypeEntry])
            ])

def psBridgeFindRegularHeightInBucket
    (entries : List (PsName × Nat)) :
    PsName -> Nat :=
  match entries with
  | List.nil =>
      fun (_name : PsName) => 0
  | List.cons entry rest =>
      let smaller : PsName -> Nat :=
        psBridgeFindRegularHeightInBucket rest;
      fun (name : PsName) =>
        if psNameEq (Prod.fst entry) name then
          Prod.snd entry
        else
          smaller name

-- Heights are internal encoding metadata. Keep full structured-name equality
-- in collision buckets and retain the newest binding, as the original list did.
inductive PsBridgeHeightIndex where
  | empty
  | bucket (entries : List (PsName × Nat))
  | branch (left right : PsBridgeHeightIndex)

def psBridgeHeightBucket (fuel : Nat) : PsBridgeHeightIndex -> Nat -> List (PsName × Nat) :=
  match fuel with
  | Nat.zero => fun (index : PsBridgeHeightIndex) (_hash : Nat) =>
      match index with
      | PsBridgeHeightIndex.bucket entries => entries
      | _ => List.nil
  | Nat.succ remaining =>
      fun (index : PsBridgeHeightIndex) (hash : Nat) =>
        let smaller : PsBridgeHeightIndex -> Nat -> List (PsName × Nat) := psBridgeHeightBucket remaining;
        match index with
        | PsBridgeHeightIndex.branch left right =>
            if Nat.beq (Nat.mod hash 2) 0 then smaller left (Nat.div hash 2)
            else smaller right (Nat.div hash 2)
        | _ => List.nil

def psBridgeHeightInsertWorker (fuel : Nat) : PsBridgeHeightIndex -> Nat -> PsName -> Nat -> PsBridgeHeightIndex :=
  match fuel with
  | Nat.zero => fun (index : PsBridgeHeightIndex) (_hash : Nat) (name : PsName) (height : Nat) =>
      let entries : List (PsName × Nat) := match index with
        | PsBridgeHeightIndex.bucket values => values
        | _ => List.nil;
      PsBridgeHeightIndex.bucket (List.cons (Prod.mk name height) entries)
  | Nat.succ remaining =>
      fun (index : PsBridgeHeightIndex) (hash : Nat) (name : PsName) (height : Nat) =>
        let smaller : PsBridgeHeightIndex -> Nat -> PsName -> Nat -> PsBridgeHeightIndex := psBridgeHeightInsertWorker remaining;
        let left : PsBridgeHeightIndex := match index with
          | PsBridgeHeightIndex.branch value _ => value
          | _ => PsBridgeHeightIndex.empty;
        let right : PsBridgeHeightIndex := match index with
          | PsBridgeHeightIndex.branch _ value => value
          | _ => PsBridgeHeightIndex.empty;
        if Nat.beq (Nat.mod hash 2) 0 then
          PsBridgeHeightIndex.branch (smaller left (Nat.div hash 2) name height) right
        else PsBridgeHeightIndex.branch left (smaller right (Nat.div hash 2) name height)

def psBridgeHeightInsert (index : PsBridgeHeightIndex) (name : PsName) (height : Nat) : PsBridgeHeightIndex :=
  psBridgeHeightInsertWorker 16 index (psEnvironmentNameHash name) name height

def psBridgeFindRegularHeight (index : PsBridgeHeightIndex) (name : PsName) : Nat :=
  psBridgeFindRegularHeightInBucket (psBridgeHeightBucket 16 index (psEnvironmentNameHash name)) name

def psBridgeNatMax (left : Nat) : Nat -> Nat :=
  match left with
  | Nat.zero =>
      fun (right : Nat) => right
  | Nat.succ leftPred =>
      fun (right : Nat) =>
        let smaller : Nat -> Nat :=
          psBridgeNatMax leftPred;
        match right with
        | Nat.zero =>
            left
        | Nat.succ rightPred =>
            Nat.succ (smaller rightPred)

def psBridgeExprMaxRegularHeight
    (heights : PsBridgeHeightIndex)
    (expr : PsExpr) : Nat :=
  match expr with
  | .constE name _ =>
      psBridgeFindRegularHeight heights name
  | .app fn arg =>
      psBridgeNatMax
        (psBridgeExprMaxRegularHeight heights fn)
        (psBridgeExprMaxRegularHeight heights arg)
  | .lam _ type body _ =>
      psBridgeNatMax
        (psBridgeExprMaxRegularHeight heights type)
        (psBridgeExprMaxRegularHeight heights body)
  | .forallE _ type body _ =>
      psBridgeNatMax
        (psBridgeExprMaxRegularHeight heights type)
        (psBridgeExprMaxRegularHeight heights body)
  | .letE _ type value body =>
      psBridgeNatMax
        (psBridgeExprMaxRegularHeight heights type)
        (psBridgeNatMax
          (psBridgeExprMaxRegularHeight heights value)
          (psBridgeExprMaxRegularHeight heights body))
  | .proj _ _ value =>
      psBridgeExprMaxRegularHeight heights value
  | _ => 0

def psEncodeCodecDefinition
    (name : PsName)
    (levelParams : List PsName)
    (type value : PsExpr)
    (height : Nat) :
    Except PsCheckedAdmissionCodecError String :=
  match psEncodeCodecExpr type with
  | Except.error error => Except.error error
  | Except.ok encodedType =>
      match psEncodeCodecExpr value with
      | Except.error error => Except.error error
      | Except.ok encodedValue =>
          let hints :=
            psJsonObject [
              psCheckedAdmissionJsonField "h" (psJsonQuote (psCheckedAdmissionNatToString height)),
              psCheckedAdmissionJsonField "k" (psJsonQuote "regular")
            ];
          Except.ok
            (psJsonObject [
              psCheckedAdmissionJsonField "h" (hints),
              psCheckedAdmissionJsonField "k" (psJsonQuote "definition"),
              psCheckedAdmissionJsonField "lp" (psEncodeCodecNameList levelParams),
              psCheckedAdmissionJsonField "n" (psEncodeCodecName name),
              psCheckedAdmissionJsonField "s" (psJsonQuote "safe"),
              psCheckedAdmissionJsonField "t" (encodedType),
              psCheckedAdmissionJsonField "v" (encodedValue)
            ])

def psEncodeCodecTheorem
    (name : PsName)
    (levelParams : List PsName)
    (type value : PsExpr) :
    Except PsCheckedAdmissionCodecError String :=
  match psEncodeCodecExpr type with
  | Except.error error => Except.error error
  | Except.ok encodedType =>
      match psEncodeCodecExpr value with
      | Except.error error => Except.error error
      | Except.ok encodedValue =>
          Except.ok
            (psJsonObject [
              psCheckedAdmissionJsonField "k" (psJsonQuote "theorem"),
              psCheckedAdmissionJsonField "lp" (psEncodeCodecNameList levelParams),
              psCheckedAdmissionJsonField "n" (psEncodeCodecName name),
              psCheckedAdmissionJsonField "t" (encodedType),
              psCheckedAdmissionJsonField "v" (encodedValue)
            ])

def psEncodeConstantAdmission (declaration : String) : String :=
  psJsonObject [
    psCheckedAdmissionJsonField "declaration" (declaration),
    psCheckedAdmissionJsonField "kind" (psJsonQuote "constant")
  ]

def psEncodeInductiveAdmission (declaration : String) : String :=
  psJsonObject [
    psCheckedAdmissionJsonField "declaration" (declaration),
    psCheckedAdmissionJsonField "kind" (psJsonQuote "inductive")
  ]

structure PsCheckedAdmissionEncodeState where
  heights : PsBridgeHeightIndex
  admissionsRev : List String

def psEncodeCheckedAdmissionsLoop
    (allDeclarations : List PsDeclaration)
    (declarations : List PsDeclaration) :
    PsCheckedAdmissionEncodeState -> Except PsCheckedAdmissionCodecError PsCheckedAdmissionEncodeState :=
  match declarations with
  | List.nil =>
      fun (state : PsCheckedAdmissionEncodeState) =>
        Except.ok state
  | List.cons declaration rest =>
      let smaller : PsCheckedAdmissionEncodeState -> Except PsCheckedAdmissionCodecError PsCheckedAdmissionEncodeState :=
        psEncodeCheckedAdmissionsLoop allDeclarations rest;
      fun (state : PsCheckedAdmissionEncodeState) =>
        match declaration with
        | .definitionDecl name levelParams type value =>
            let height :=
              Nat.succ
                (psBridgeExprMaxRegularHeight
                  state.heights
                  value);
            match
                psEncodeCodecDefinition
                  name
                  levelParams
                  type
                  value
                  height with
            | Except.error error =>
                Except.error error
            | Except.ok encoded =>
                smaller {
                  heights := psBridgeHeightInsert state.heights name height
                  admissionsRev :=
                    List.cons
                      (psEncodeConstantAdmission encoded)
                      state.admissionsRev
                }
        | .theoremDecl name levelParams type value =>
            match psEncodeCodecTheorem name levelParams type value with
            | Except.error error =>
                Except.error error
            | Except.ok encoded =>
                smaller {
                  heights := state.heights
                  admissionsRev :=
                    List.cons
                      (psEncodeConstantAdmission encoded)
                      state.admissionsRev
                }
        | .inductiveDecl info =>
            match psEncodeCodecInductive allDeclarations info with
            | Except.error error =>
                Except.error error
            | Except.ok encoded =>
                smaller {
                  heights := state.heights
                  admissionsRev :=
                    List.cons
                      (psEncodeInductiveAdmission encoded)
                      state.admissionsRev
                }
        | .constructorDecl _ =>
            smaller state
        | .recursorDecl _ =>
            smaller state
        | .axiomDecl _ _ _ =>
            Except.error
              PsCheckedAdmissionCodecError.unsupportedDeclaration
        | .opaqueDecl _ _ _ _ =>
            Except.error
              PsCheckedAdmissionCodecError.unsupportedDeclaration
        | .partialDecl _ _ _ _ =>
            Except.error
              PsCheckedAdmissionCodecError.unsupportedDeclaration

def psCheckedAdmissionReverseStringsAcc
    (values : List String) :
    List String -> List String :=
  match values with
  | List.nil =>
      fun (acc : List String) => acc
  | List.cons head tail =>
      let smaller : List String -> List String :=
        psCheckedAdmissionReverseStringsAcc tail;
      fun (acc : List String) =>
        smaller (List.cons head acc)


def psCheckedAdmissionReverseStrings
    (values : List String) : List String :=
  psCheckedAdmissionReverseStringsAcc values List.nil

-- Lean generates additional motives and minors for nested recursive containers.
-- PSC's shallow recursor is implemented by an ordinary checked definition: its
-- auxiliary motives return a private unit in the same universe as the motive.
-- This changes only the admission representation, never the portable IR.
structure PsCheckedNestedBinder where
  id : Nat
  name : PsName
  type : PsExpr

def psCheckedNestedName (text : String) : PsName :=
  PsName.str PsName.anonymous text

def psCheckedNestedUnitName : PsName := psCheckedNestedName "_pscCheckedNestedUnit"

def psCheckedNestedLevelName : PsName := psCheckedNestedName "_pscCheckedMotive"

def psCheckedNestedLevel : PsLevel := PsLevel.param psCheckedNestedLevelName

def psCheckedNestedUnit : PsExpr :=
  PsExpr.constE psCheckedNestedUnitName [psCheckedNestedLevel]

def psCheckedNestedUnitValue : PsExpr :=
  PsExpr.constE (PsName.str psCheckedNestedUnitName "unit") [psCheckedNestedLevel]

def psCheckedNestedBind (lambda : Bool) (binders : List PsCheckedNestedBinder) : PsExpr -> PsExpr :=
  match binders with
  | List.nil => fun (body : PsExpr) => body
  | List.cons binder rest =>
      let smaller : PsExpr -> PsExpr := psCheckedNestedBind lambda rest;
      fun (body : PsExpr) =>
        let bound := psExprAbstractFVar binder.id (smaller body);
        if lambda then PsExpr.lam binder.name binder.type bound PsBinderInfo.explicit
        else PsExpr.forallE binder.name binder.type bound PsBinderInfo.explicit

def psCheckedNestedSize (expr : PsExpr) : Nat :=
  match expr with
  | PsExpr.app fn arg => Nat.succ (Nat.add (psCheckedNestedSize fn) (psCheckedNestedSize arg))
  | PsExpr.lam _ type body _ => Nat.succ (Nat.add (psCheckedNestedSize type) (psCheckedNestedSize body))
  | PsExpr.forallE _ type body _ => Nat.succ (Nat.add (psCheckedNestedSize type) (psCheckedNestedSize body))
  | PsExpr.letE _ type value body => Nat.succ (Nat.add (psCheckedNestedSize type) (Nat.add (psCheckedNestedSize value) (psCheckedNestedSize body)))
  | PsExpr.proj _ _ value => Nat.succ (psCheckedNestedSize value)
  | _ => 1

def psCheckedNestedOpenWorker (fuel : Nat) : Nat -> PsExpr -> List PsCheckedNestedBinder :=
  match fuel with
  | Nat.zero => fun (_id : Nat) (_type : PsExpr) => List.nil
  | Nat.succ remaining =>
      fun (id : Nat) (type : PsExpr) =>
        let smaller : Nat -> PsExpr -> List PsCheckedNestedBinder := psCheckedNestedOpenWorker remaining;
        match type with
        | PsExpr.forallE name domain body _ =>
            List.cons (PsCheckedNestedBinder.mk id name domain)
              (smaller (Nat.succ id) (psExprInstantiate1 body (PsExpr.fvar id)))
        | _ => List.nil

def psCheckedNestedOpen (id : Nat) (type : PsExpr) : List PsCheckedNestedBinder :=
  psCheckedNestedOpenWorker (psCheckedNestedSize type) id type

def psCheckedNestedContains (name : PsName) (expr : PsExpr) : Bool :=
  match expr with
  | PsExpr.constE other _ => psNameEq name other
  | PsExpr.app fn arg => if psCheckedNestedContains name fn then true else psCheckedNestedContains name arg
  | PsExpr.lam _ type body _ => if psCheckedNestedContains name type then true else psCheckedNestedContains name body
  | PsExpr.forallE _ type body _ => if psCheckedNestedContains name type then true else psCheckedNestedContains name body
  | PsExpr.letE _ type value body =>
      if psCheckedNestedContains name type then true
      else if psCheckedNestedContains name value then true
      else psCheckedNestedContains name body
  | PsExpr.proj _ _ value => psCheckedNestedContains name value
  | _ => false

-- A recursive family applied to its parameters/indices is still a direct
-- recursive field. Self occurrences inside an argument remain nested.
def psCheckedNestedDirect (name : PsName) (type : PsExpr) : Bool :=
  match type with
  | PsExpr.constE other _ => psNameEq name other
  | PsExpr.app fn arg =>
      if psCheckedNestedContains name arg then false else psCheckedNestedDirect name fn
  | _ => false

def psCheckedNestedAdd (name : PsName) (type : PsExpr) (shapes : List PsExpr) : List PsExpr :=
  if psCheckedNestedContains name type then
    if psCheckedNestedDirect name type then shapes
    else if psListAny (psExprAlphaEq type) shapes then shapes
    else psListAppend shapes [type]
  else shapes

def psCheckedNestedAddTypes (name : PsName) (types : List PsExpr) : List PsExpr -> List PsExpr :=
  match types with
  | List.nil => fun (shapes : List PsExpr) => shapes
  | List.cons type rest =>
      let smaller : List PsExpr -> List PsExpr := psCheckedNestedAddTypes name rest;
      fun (shapes : List PsExpr) => smaller (psCheckedNestedAdd name type shapes)

def psCheckedNestedBinderType (binder : PsCheckedNestedBinder) : PsExpr := binder.type

def psCheckedNestedBinderExpr (binder : PsCheckedNestedBinder) : PsExpr := PsExpr.fvar binder.id

def psCheckedNestedRoots (all : List PsDeclaration) (name : PsName) (constructors : List PsName) :
    List PsExpr -> Except PsCheckedAdmissionCodecError (List PsExpr) :=
  match constructors with
  | List.nil => fun (shapes : List PsExpr) => Except.ok shapes
  | List.cons constructor rest =>
      let smaller : List PsExpr -> Except PsCheckedAdmissionCodecError (List PsExpr) := psCheckedNestedRoots all name rest;
      fun (shapes : List PsExpr) =>
        match psBridgeFindConstructor all constructor with
        | Option.none => Except.error (PsCheckedAdmissionCodecError.missingConstructor constructor)
        | Option.some info =>
            smaller (psCheckedNestedAddTypes name (psListMap psCheckedNestedBinderType (psCheckedNestedOpen 0 info.type)) shapes)

def psCheckedNestedContainerFields (type : PsExpr) : Except PsCheckedAdmissionCodecError (List (List PsExpr)) :=
  match type with
  | PsExpr.app fn arg =>
      match fn with
      | PsExpr.constE name _ =>
          if psNameEq name (psCheckedNestedName "List") then
            Except.ok (List.cons List.nil (List.cons (List.cons arg (List.cons type List.nil)) List.nil))
          else if psNameEq name (psCheckedNestedName "Option") then
            Except.ok (List.cons List.nil (List.cons (List.cons arg List.nil) List.nil))
          else Except.error PsCheckedAdmissionCodecError.unsupportedDeclaration
      | PsExpr.app head left =>
          match head with
          | PsExpr.constE name _ =>
              if psNameEq name (psCheckedNestedName "Prod") then Except.ok (List.cons (List.cons left (List.cons arg List.nil)) List.nil)
              else Except.error PsCheckedAdmissionCodecError.unsupportedDeclaration
          | _ => Except.error PsCheckedAdmissionCodecError.unsupportedDeclaration
      | _ => Except.error PsCheckedAdmissionCodecError.unsupportedDeclaration
  | _ => Except.error PsCheckedAdmissionCodecError.unsupportedDeclaration

def psCheckedNestedConcat {alpha : Type} (lists : List (List alpha)) : List alpha :=
  match lists with
  | List.nil => List.nil
  | List.cons values rest => psListAppend values (psCheckedNestedConcat rest)

def psCheckedNestedExpand (name : PsName) (fuel : Nat) : List PsExpr -> List PsExpr -> Except PsCheckedAdmissionCodecError (List PsExpr) :=
  match fuel with
  | Nat.zero => fun (pending : List PsExpr) (done : List PsExpr) =>
      if psListIsEmpty pending then Except.ok done else Except.error PsCheckedAdmissionCodecError.unsupportedDeclaration
  | Nat.succ remaining =>
      fun (pending : List PsExpr) (done : List PsExpr) =>
        let smaller : List PsExpr -> List PsExpr -> Except PsCheckedAdmissionCodecError (List PsExpr) := psCheckedNestedExpand name remaining;
        match pending with
        | List.nil => Except.ok done
        | List.cons type rest =>
            match psCheckedNestedContainerFields type with
            | Except.error error => Except.error error
            | Except.ok fields =>
                let known := psListAppend done pending;
                let added := psCheckedNestedAddTypes name (psCheckedNestedConcat fields) known;
                let fresh := psListReverse (psListTake (Nat.sub (psListLength added) (psListLength known)) (psListReverse added));
                smaller (psListAppend rest fresh) (psListAppend done [type])

def psCheckedNestedSizes (types : List PsExpr) : Nat :=
  match types with
  | List.nil => 0
  | List.cons type rest => Nat.add (psCheckedNestedSize type) (psCheckedNestedSizes rest)

def psCheckedNestedApply (args : List PsExpr) : PsExpr -> PsExpr :=
  match args with
  | List.nil => fun (fn : PsExpr) => fn
  | List.cons arg rest =>
      let smaller : PsExpr -> PsExpr := psCheckedNestedApply rest;
      fun (fn : PsExpr) => smaller (PsExpr.app fn arg)

def psCheckedNestedHypotheses (name : PsName) (fields : List PsCheckedNestedBinder) : Nat -> List PsCheckedNestedBinder :=
  match fields with
  | List.nil => fun (_id : Nat) => List.nil
  | List.cons field rest =>
      let smaller : Nat -> List PsCheckedNestedBinder := psCheckedNestedHypotheses name rest;
      fun (id : Nat) =>
        if psCheckedNestedContains name field.type then
          let type := if psExprAlphaEq field.type (PsExpr.constE name List.nil)
            then PsExpr.app (PsExpr.fvar 0) (PsExpr.fvar field.id) else psCheckedNestedUnit;
          List.cons (PsCheckedNestedBinder.mk id (psCheckedNestedName "ih") type) (smaller (Nat.succ id))
        else smaller id

def psCheckedNestedDirectHypotheses (hypotheses : List PsCheckedNestedBinder) : List PsCheckedNestedBinder :=
  match hypotheses with
  | List.nil => List.nil
  | List.cons hypothesis rest =>
      let tail := psCheckedNestedDirectHypotheses rest;
      if psExprAlphaEq hypothesis.type psCheckedNestedUnit then tail else List.cons hypothesis tail

structure PsCheckedNestedMinor where
  binder : PsCheckedNestedBinder
  adapter : PsExpr

def psCheckedNestedMinors (all : List PsDeclaration) (name : PsName) (start : Nat) (constructors : List PsName) :
    Nat -> Except PsCheckedAdmissionCodecError (List PsCheckedNestedMinor) :=
  match constructors with
  | List.nil => fun (_id : Nat) => Except.ok List.nil
  | List.cons constructor rest =>
      let smaller : Nat -> Except PsCheckedAdmissionCodecError (List PsCheckedNestedMinor) := psCheckedNestedMinors all name start rest;
      fun (id : Nat) =>
        match psBridgeFindConstructor all constructor with
        | Option.none => Except.error (PsCheckedAdmissionCodecError.missingConstructor constructor)
        | Option.some info =>
            let fields := psCheckedNestedOpen start info.type;
            let hypotheses := psCheckedNestedHypotheses name fields (Nat.add start (psListLength fields));
            let direct := psCheckedNestedDirectHypotheses hypotheses;
            let value := psCheckedNestedApply (psListMap psCheckedNestedBinderExpr fields) (PsExpr.constE constructor List.nil);
            let type := psCheckedNestedBind false (psListAppend fields direct) (PsExpr.app (PsExpr.fvar 0) value);
            let body := psCheckedNestedApply (psListMap psCheckedNestedBinderExpr (psListAppend fields direct)) (PsExpr.fvar id);
            let adapter := psCheckedNestedBind true (psListAppend fields hypotheses) body;
            match smaller (Nat.succ id) with
            | Except.error error => Except.error error
            | Except.ok tail => Except.ok (List.cons (PsCheckedNestedMinor.mk (PsCheckedNestedBinder.mk id (psCheckedNestedName "minor") type) adapter) tail)

def psCheckedNestedMinorBinder (minor : PsCheckedNestedMinor) : PsCheckedNestedBinder := minor.binder

def psCheckedNestedMinorAdapter (minor : PsCheckedNestedMinor) : PsExpr := minor.adapter

def psCheckedNestedFields (types : List PsExpr) : Nat -> List PsCheckedNestedBinder :=
  match types with
  | List.nil => fun (_id : Nat) => List.nil
  | List.cons type rest =>
      let smaller : Nat -> List PsCheckedNestedBinder := psCheckedNestedFields rest;
      fun (id : Nat) => List.cons (PsCheckedNestedBinder.mk id (psCheckedNestedName "field") type) (smaller (Nat.succ id))

def psCheckedNestedAuxiliaryMinor (name : PsName) (start : Nat) (types : List PsExpr) : PsExpr :=
  let fields := psCheckedNestedFields types start;
  let hypotheses := psCheckedNestedHypotheses name fields (Nat.add start (psListLength fields));
  psCheckedNestedBind true (psListAppend fields hypotheses) psCheckedNestedUnitValue

def psCheckedNestedAuxiliaryMinors (name : PsName) (start : Nat) (shapes : List PsExpr) : Except PsCheckedAdmissionCodecError (List PsExpr) :=
  match shapes with
  | List.nil => Except.ok List.nil
  | List.cons shape rest =>
      match psCheckedNestedContainerFields shape with
      | Except.error error => Except.error error
      | Except.ok fields =>
          match psCheckedNestedAuxiliaryMinors name start rest with
          | Except.error error => Except.error error
          | Except.ok tail => Except.ok (psListAppend (psListMap (psCheckedNestedAuxiliaryMinor name start) fields) tail)

def psCheckedNestedMotive (type : PsExpr) : PsExpr :=
  PsExpr.lam (psCheckedNestedName "nested") type psCheckedNestedUnit PsBinderInfo.explicit

def psCheckedNestedWrapper (all : List PsDeclaration) (info : PsInductiveInfo) (shapes : List PsExpr) : Except PsCheckedAdmissionCodecError PsDeclaration :=
  if psListIsEmpty info.levelParams then
    if Nat.beq info.numParams 0 then
      if Nat.beq info.numIndices 0 then
        let majorId := Nat.succ (psListLength info.constructors);
        let start := Nat.succ majorId;
        let self := PsExpr.constE info.name List.nil;
        let major := PsCheckedNestedBinder.mk majorId (psCheckedNestedName "major") self;
        let motive := PsCheckedNestedBinder.mk 0 (psCheckedNestedName "motive")
          (PsExpr.forallE major.name self (PsExpr.sortE psCheckedNestedLevel) PsBinderInfo.explicit);
        match psCheckedNestedMinors all info.name start info.constructors 1 with
        | Except.error error => Except.error error
        | Except.ok minors =>
            match psCheckedNestedAuxiliaryMinors info.name start shapes with
            | Except.error error => Except.error error
            | Except.ok auxiliaries =>
                let binders := List.cons motive (psListAppend (psListMap psCheckedNestedMinorBinder minors) [major]);
                let args := List.cons (PsExpr.fvar 0) (psListAppend (psListMap psCheckedNestedMotive shapes)
                  (psListAppend (psListMap psCheckedNestedMinorAdapter minors) (psListAppend auxiliaries [PsExpr.fvar majorId])));
                let recursor := PsExpr.constE (PsName.str info.name "rec") [psCheckedNestedLevel];
                Except.ok (PsDeclaration.definitionDecl (PsName.str info.name "_pscShallowRec") [psCheckedNestedLevelName]
                  (psCheckedNestedBind false binders (PsExpr.app (PsExpr.fvar 0) (PsExpr.fvar majorId)))
                  (psCheckedNestedBind true binders (psCheckedNestedApply args recursor)))
      else Except.error PsCheckedAdmissionCodecError.unsupportedDeclaration
    else Except.error PsCheckedAdmissionCodecError.unsupportedDeclaration
  else Except.error PsCheckedAdmissionCodecError.unsupportedDeclaration

def psCheckedNestedCollect (all : List PsDeclaration) (declarations : List PsDeclaration) : Except PsCheckedAdmissionCodecError (List (Prod PsName PsDeclaration)) :=
  match declarations with
  | List.nil => Except.ok List.nil
  | List.cons declaration rest =>
      match psCheckedNestedCollect all rest with
      | Except.error error => Except.error error
      | Except.ok tail =>
          match declaration with
          | PsDeclaration.inductiveDecl info =>
              match psCheckedNestedRoots all info.name info.constructors List.nil with
              | Except.error error => Except.error error
              | Except.ok roots =>
                  if psListIsEmpty roots then Except.ok tail
                  else
                    match psCheckedNestedExpand info.name (Nat.succ (psCheckedNestedSizes roots)) roots List.nil with
                    | Except.error error => Except.error error
                    | Except.ok shapes =>
                        match psCheckedNestedWrapper all info shapes with
                        | Except.error error => Except.error error
                        | Except.ok wrapper => Except.ok (List.cons (Prod.mk info.name wrapper) tail)
          | _ => Except.ok tail

def psCheckedNestedFind (wrappers : List (Prod PsName PsDeclaration)) : PsName -> Option PsDeclaration :=
  match wrappers with
  | List.nil => fun (_name : PsName) => Option.none
  | List.cons entry rest =>
      let smaller : PsName -> Option PsDeclaration := psCheckedNestedFind rest;
      fun (name : PsName) => if psNameEq name (Prod.fst entry) then Option.some (Prod.snd entry) else smaller name

def psCheckedNestedRewrite (wrappers : List (Prod PsName PsDeclaration)) (expr : PsExpr) : PsExpr :=
  match expr with
  | PsExpr.constE name levels =>
      match name with
      | PsName.str parent component =>
          if psStringEq component "rec" then
            match psCheckedNestedFind wrappers parent with
            | Option.some _ => PsExpr.constE (PsName.str parent "_pscShallowRec") levels
            | Option.none => expr
          else expr
      | _ => expr
  | PsExpr.app fn arg => PsExpr.app (psCheckedNestedRewrite wrappers fn) (psCheckedNestedRewrite wrappers arg)
  | PsExpr.lam name type body binder => PsExpr.lam name (psCheckedNestedRewrite wrappers type) (psCheckedNestedRewrite wrappers body) binder
  | PsExpr.forallE name type body binder => PsExpr.forallE name (psCheckedNestedRewrite wrappers type) (psCheckedNestedRewrite wrappers body) binder
  | PsExpr.letE name type value body => PsExpr.letE name (psCheckedNestedRewrite wrappers type) (psCheckedNestedRewrite wrappers value) (psCheckedNestedRewrite wrappers body)
  | PsExpr.proj name index value => PsExpr.proj name index (psCheckedNestedRewrite wrappers value)
  | _ => expr

def psCheckedNestedNormalize (wrappers : List (Prod PsName PsDeclaration)) (declarations : List PsDeclaration) : List PsDeclaration :=
  match declarations with
  | List.nil => List.nil
  | List.cons declaration rest =>
      let tail := psCheckedNestedNormalize wrappers rest;
      match declaration with
      | PsDeclaration.definitionDecl name levels type value =>
          List.cons (PsDeclaration.definitionDecl name levels (psCheckedNestedRewrite wrappers type) (psCheckedNestedRewrite wrappers value)) tail
      | PsDeclaration.theoremDecl name levels type value =>
          List.cons (PsDeclaration.theoremDecl name levels (psCheckedNestedRewrite wrappers type) (psCheckedNestedRewrite wrappers value)) tail
      | PsDeclaration.inductiveDecl info =>
          match psCheckedNestedFind wrappers info.name with
          | Option.none => List.cons declaration tail
          | Option.some wrapper => List.cons declaration (List.cons wrapper tail)
      | _ => List.cons declaration tail

def psCheckedNestedUnitDeclarations : List PsDeclaration :=
  let constructor := PsName.str psCheckedNestedUnitName "unit";
  List.cons (PsDeclaration.inductiveDecl
    (PsInductiveInfo.mk psCheckedNestedUnitName [psCheckedNestedLevelName]
      (PsExpr.sortE psCheckedNestedLevel) 0 0 [constructor] false))
    [PsDeclaration.constructorDecl (PsConstructorInfo.mk constructor [psCheckedNestedLevelName]
      psCheckedNestedUnit psCheckedNestedUnitName 0 0 0 List.nil)]

def psEncodeCheckedAdmissionsNormalized
    (declarations : List PsDeclaration) :
    Except PsCheckedAdmissionCodecError String :=
  match psEncodeCheckedAdmissionsLoop
      declarations
      declarations
      {
        heights := PsBridgeHeightIndex.empty
        admissionsRev := []
      } with
  | Except.error error => Except.error error
  | Except.ok state =>
      Except.ok
        (psJsonObject [
          psCheckedAdmissionJsonField "admissions" (psJsonArray (psCheckedAdmissionReverseStrings state.admissionsRev)),
          psCheckedAdmissionJsonField "format" (psJsonQuote "proofscript-checked-admissions"),
          psCheckedAdmissionJsonField "version" ("2")
        ])

def psEncodeCheckedAdmissionsCanonical
    (declarations : List PsDeclaration) : Except PsCheckedAdmissionCodecError String :=
  match psCheckedNestedCollect declarations declarations with
  | Except.error error => Except.error error
  | Except.ok wrappers =>
      if psListIsEmpty wrappers then psEncodeCheckedAdmissionsNormalized declarations
      else psEncodeCheckedAdmissionsNormalized
        (psListAppend psCheckedNestedUnitDeclarations (psCheckedNestedNormalize wrappers declarations))

def psEncodeCheckedAdmissionsText
    (declarations : List PsDeclaration) :
    Except PsCheckedAdmissionCodecError String :=
  match psEncodeCheckedAdmissionsCanonical declarations with
  | Except.error error => Except.error error
  | Except.ok encoded => Except.ok (String.Internal.append encoded "\n")
