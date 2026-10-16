import Ps.Bridge.Json
import Ps.Core.Declaration
import Ps.Core.InductiveGroup
import Ps.Core.Nested
import Ps.Core.Abstract
import Ps.Core.Subst
import Ps.Core.Equality
import Ps.Foundation.List
import Ps.Environment.Basic
import Ps.Meta.Reduce

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
      if psCheckedAdmissionBoolNot (psNameEq info.inductiveName inductiveName) ||
          psCheckedAdmissionBoolNot (psConstructorRecursiveFieldsOrdered info) then
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

-- Core owns group identity and motive/minor order; transport only resolves
-- the retained declarations and serializes a single official inductive batch.
def psBridgeInductiveGroupPlanIn (environment : PsEnvironment)
    (all : List PsDeclaration) (info : PsInductiveInfo) :
    Except PsCheckedAdmissionCodecError PsInductiveGroupPlan := do
  let findInductive := psEnvironmentFindInductive environment
  let findRecursor := psEnvironmentFindRecursor environment
  let some plan := psInductiveGroupIdentityFor findInductive findRecursor info
    | throw .unsupportedDeclaration
  -- Emitting a group once must never turn a repeated/conflicting retained
  -- descriptor into an ignored record. Resolve every owned name uniquely
  -- before any member can be marked emitted; missing constructors retain
  -- their existing precise codec error below.
  for member in plan.members do
    if (all.filter (fun declaration =>
        psNameEq (psDeclarationName declaration) member.name)).length != 1 then
      throw .unsupportedDeclaration
    let names := member.name :: (psNameAppendStr member.name "rec" :: member.constructors)
    for name in names do
      if (all.filter (fun declaration => psNameEq (psDeclarationName declaration) name)).length > 1 then
        throw .unsupportedDeclaration
  -- Constructor-only standalone batches retain no recursor/group claim.
  -- Every retained recursor otherwise requires the complete canonical closure
  -- built from actual container declarations in the supplied environment.
  if (findRecursor (psNameAppendStr info.name "rec")).isSome then
    let some elimination := psBuildInductiveEliminationPlan
        (psWhnf environment psMetaEmpty psLocalEmpty) findInductive
        (psEnvironmentFindConstructor environment) plan | throw .unsupportedDeclaration
    for slot in elimination.slots do
      for constructor in slot.constructors do
        if !psInductiveEliminationConstructorMetadataValid slot constructor then
          throw (.mismatchedConstructor constructor.info.name)
      if (all.filter (fun declaration =>
          psNameEq (psDeclarationName declaration) slot.recursorName)).length != 1 then
        throw .unsupportedDeclaration
    if !psInductiveEliminationRegistered (psWhnf environment psMetaEmpty psLocalEmpty)
        findRecursor elimination then throw .unsupportedDeclaration
    for declaration in all do
      if let .recursorDecl recursor := declaration then
        if recursor.inductiveNames.any (fun name => (psInductiveGroupNames plan).any (psNameEq name)) &&
            (psInductiveEliminationSlotFor elimination recursor.name).isNone then
          throw .unsupportedDeclaration
  return plan

def psBridgeAdmissionEnvironment (environment : PsEnvironment)
    (declarations : List PsDeclaration) : PsEnvironment :=
  declarations.foldr (fun declaration current => psEnvironmentInsert current declaration) environment

def psBridgeInductiveGroupPlan (all : List PsDeclaration) (info : PsInductiveInfo) :
    Except PsCheckedAdmissionCodecError PsInductiveGroupPlan :=
  psBridgeInductiveGroupPlanIn (psBridgeAdmissionEnvironment psEnvironmentEmpty all) all info

def psEncodeCodecInductiveType (all : List PsDeclaration) (info : PsInductiveInfo) :
    Except PsCheckedAdmissionCodecError String := do
  let constructors ← psEncodeCodecConstructors all info.name info.constructors
  let type ← psEncodeCodecExpr info.type
  return psJsonObject [
    psCheckedAdmissionJsonField "cs" (psJsonArray constructors),
    psCheckedAdmissionJsonField "n" (psEncodeCodecName info.name),
    psCheckedAdmissionJsonField "t" type ]

def psEncodeCodecInductiveGroup (all : List PsDeclaration) (plan : PsInductiveGroupPlan) :
    Except PsCheckedAdmissionCodecError String := do
  let first :: _ := plan.members | throw .unsupportedDeclaration
  let entries ← plan.members.mapM (psEncodeCodecInductiveType all)
  return psJsonObject [
    psCheckedAdmissionJsonField "lp" (psEncodeCodecNameList first.levelParams),
    psCheckedAdmissionJsonField "np" (psCheckedAdmissionNatToString first.numParams),
    psCheckedAdmissionJsonField "ts" (psJsonArray entries) ]

def psEncodeCodecInductive (allDeclarations : List PsDeclaration) (info : PsInductiveInfo) :
    Except PsCheckedAdmissionCodecError String := do
  let plan ← psBridgeInductiveGroupPlan allDeclarations info
  psEncodeCodecInductiveGroup allDeclarations plan

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

-- Opaque bodies are checked by the official kernel, without a reducibility hint.
def psEncodeCodecOpaque (name : PsName) (levelParams : List PsName)
    (type value : PsExpr) : Except PsCheckedAdmissionCodecError String := do
  let encodedType ← psEncodeCodecExpr type
  let encodedValue ← psEncodeCodecExpr value
  return psJsonObject [
    psCheckedAdmissionJsonField "k" (psJsonQuote "opaque"),
    psCheckedAdmissionJsonField "lp" (psEncodeCodecNameList levelParams),
    psCheckedAdmissionJsonField "n" (psEncodeCodecName name),
    psCheckedAdmissionJsonField "t" encodedType,
    psCheckedAdmissionJsonField "v" encodedValue ]

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
  inductiveNames : List PsName := []

def psEncodeCheckedAdmissionsLoopIn
    (environment : PsEnvironment)
    (allDeclarations : List PsDeclaration)
    (declarations : List PsDeclaration) :
    PsCheckedAdmissionEncodeState -> Except PsCheckedAdmissionCodecError PsCheckedAdmissionEncodeState :=
  match declarations with
  | List.nil =>
      fun (state : PsCheckedAdmissionEncodeState) =>
        Except.ok state
  | List.cons declaration rest =>
      let smaller : PsCheckedAdmissionEncodeState -> Except PsCheckedAdmissionCodecError PsCheckedAdmissionEncodeState :=
        psEncodeCheckedAdmissionsLoopIn environment allDeclarations rest;
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
                smaller { state with
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
                smaller { state with
                  heights := state.heights
                  admissionsRev :=
                    List.cons
                      (psEncodeConstantAdmission encoded)
                      state.admissionsRev
                }
        | .inductiveDecl info => do
            if state.inductiveNames.any (psNameEq info.name) then smaller state
            else do
              let plan ← psBridgeInductiveGroupPlanIn environment allDeclarations info
              let names := psInductiveGroupNames plan
              if names.any (fun name => state.inductiveNames.any (psNameEq name)) then
                throw .unsupportedDeclaration
              let encoded ← psEncodeCodecInductiveGroup allDeclarations plan
              smaller { state with
                inductiveNames := names ++ state.inductiveNames
                admissionsRev := psEncodeInductiveAdmission encoded :: state.admissionsRev }
        | .constructorDecl _ =>
            smaller state
        | .recursorDecl _ =>
            smaller state
        | .quotientDecl .. | .axiomDecl _ _ _ =>
            Except.error
              PsCheckedAdmissionCodecError.unsupportedDeclaration
        | .opaqueDecl name levelParams type value =>
            match psEncodeCodecOpaque name levelParams type value with
            | .error error => .error error
            | .ok encoded =>
              smaller { state with
                admissionsRev := List.cons (psEncodeConstantAdmission encoded)
                  state.admissionsRev }
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

def psEncodeCheckedAdmissionsNormalizedIn
    (environment : PsEnvironment)
    (declarations : List PsDeclaration) :
    Except PsCheckedAdmissionCodecError String :=
  match psEncodeCheckedAdmissionsLoopIn
      (psBridgeAdmissionEnvironment environment declarations)
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

-- Nested declarations use their actual public and auxiliary recursors. There
-- is no shallow wrapper or unit substitution in the admission representation.
def psEncodeCheckedAdmissionsCanonicalIn (environment : PsEnvironment)
    (declarations : List PsDeclaration) : Except PsCheckedAdmissionCodecError String :=
  psEncodeCheckedAdmissionsNormalizedIn environment declarations

def psEncodeCheckedAdmissionsNormalized
    (declarations : List PsDeclaration) : Except PsCheckedAdmissionCodecError String :=
  psEncodeCheckedAdmissionsNormalizedIn psEnvironmentEmpty declarations

def psEncodeCheckedAdmissionsCanonical
    (declarations : List PsDeclaration) : Except PsCheckedAdmissionCodecError String :=
  psEncodeCheckedAdmissionsCanonicalIn psEnvironmentEmpty declarations

def psEncodeCheckedAdmissionsText
    (declarations : List PsDeclaration) :
    Except PsCheckedAdmissionCodecError String :=
  match psEncodeCheckedAdmissionsCanonical declarations with
  | Except.error error => Except.error error
  | Except.ok encoded => Except.ok (String.Internal.append encoded "\n")

