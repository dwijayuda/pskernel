import Ps.KernelCore.Admission.Inductive.Ordinary.Admission

/-- Diagnostic-only attribution of exhausted reduction budgets.
    The admission rules and limits do not change, and invalid declarations
    retain their original messages. These labels locate the actual expensive
    coherent subsystem before any WHNF architecture redesign. -/
def psKernelMutualBudgetAt (stage message : String) : String :=
  if message == "kernel reduction budget exhausted" then
    "mutual-" ++ stage ++ ": " ++ message
  else message


/-
Mutual-inductive declaration analysis.

This module discovers mutual family targets, opens constructor fields, checks
recursive occurrences, and records the shape information consumed by recursor
construction. It intentionally contains no environment mutation.
-/


structure PsKernelSimpleMutualTypeDecl where
  name : PsKernelName
  type : PsKernelExpr
  ctors : List PsKernelSimpleConstructorDecl

structure PsKernelSimpleMutualInductiveDecl where
  levelParams : List PsKernelName
  numParams : Nat
  types : List PsKernelSimpleMutualTypeDecl
  isUnsafe : Bool

structure PsKernelSimpleMutualTypeShape where
  decl : PsKernelSimpleMutualTypeDecl
  indices : List PsKernelOpenBinder

structure PsKernelSimpleMutualRecursiveField where
  field : PsKernelOpenBinder
  args : List PsKernelOpenBinder
  target : Nat
  indices : List PsKernelExpr

structure PsKernelSimpleMutualConstructorShape where
  owner : Nat
  ctor : PsKernelSimpleConstructorDecl
  fields : List PsKernelOpenBinder
  recursiveFields : List PsKernelSimpleMutualRecursiveField
  resultIndices : List PsKernelExpr

structure PsKernelSimpleMutualAppInfo where
  target : Nat
  indices : List PsKernelExpr

structure PsKernelMutualRecursiveArgumentResult where
  session : PsKernelCheckerSession
  recursiveInfo : Option PsKernelSimpleMutualRecursiveField

structure PsKernelMutualOpenFieldsResult where
  session : PsKernelCheckerSession
  fields : List PsKernelOpenBinder
  recursiveFields : List PsKernelSimpleMutualRecursiveField
  result : PsKernelExpr

def psKernelSimpleMutualNames
    (types : List PsKernelSimpleMutualTypeDecl) :
    List PsKernelName :=
  match types with
  | List.nil =>
      List.nil
  | List.cons typeDecl rest =>
      List.cons
        typeDecl.name
        (psKernelSimpleMutualNames rest)

def psKernelSimpleMutualContainsConstWorker
    (expr : PsKernelExpr) :
    List PsKernelName -> Bool :=
  match expr with
  | PsKernelExpr.const name _ =>
      fun (targets : List PsKernelName) =>
        psKernelNameMember name targets
  | PsKernelExpr.app fn arg =>
      let left :
          List PsKernelName -> Bool :=
        psKernelSimpleMutualContainsConstWorker fn;
      let right :
          List PsKernelName -> Bool :=
        psKernelSimpleMutualContainsConstWorker arg;
      fun (targets : List PsKernelName) =>
        if left targets then
          true
        else
          right targets
  | PsKernelExpr.lam _ type body _ =>
      let left :
          List PsKernelName -> Bool :=
        psKernelSimpleMutualContainsConstWorker type;
      let right :
          List PsKernelName -> Bool :=
        psKernelSimpleMutualContainsConstWorker body;
      fun (targets : List PsKernelName) =>
        if left targets then
          true
        else
          right targets
  | PsKernelExpr.forallE _ type body _ =>
      let left :
          List PsKernelName -> Bool :=
        psKernelSimpleMutualContainsConstWorker type;
      let right :
          List PsKernelName -> Bool :=
        psKernelSimpleMutualContainsConstWorker body;
      fun (targets : List PsKernelName) =>
        if left targets then
          true
        else
          right targets
  | PsKernelExpr.letE _ type value body _ =>
      let typeCheck :
          List PsKernelName -> Bool :=
        psKernelSimpleMutualContainsConstWorker type;
      let valueCheck :
          List PsKernelName -> Bool :=
        psKernelSimpleMutualContainsConstWorker value;
      let bodyCheck :
          List PsKernelName -> Bool :=
        psKernelSimpleMutualContainsConstWorker body;
      fun (targets : List PsKernelName) =>
        if typeCheck targets then
          true
        else if valueCheck targets then
          true
        else
          bodyCheck targets
  | PsKernelExpr.mdata _ body =>
      let smaller :
          List PsKernelName -> Bool :=
        psKernelSimpleMutualContainsConstWorker body;
      fun (targets : List PsKernelName) =>
        smaller targets
  | PsKernelExpr.proj typeName _ body =>
      let smaller :
          List PsKernelName -> Bool :=
        psKernelSimpleMutualContainsConstWorker body;
      fun (targets : List PsKernelName) =>
        if psKernelNameMember typeName targets then
          true
        else
          smaller targets
  | _ =>
      fun (_targets : List PsKernelName) =>
        false

def psKernelSimpleMutualContainsConst
    (targets : List PsKernelName)
    (expr : PsKernelExpr) : Bool :=
  psKernelSimpleMutualContainsConstWorker
    expr
    targets

def psKernelSimpleMutualTargetIndexWorker
    (name : PsKernelName)
    (shapes : List PsKernelSimpleMutualTypeShape) :
    Nat -> Option Nat :=
  match shapes with
  | List.nil =>
      fun (_index : Nat) =>
        Option.none
  | List.cons shape rest =>
      let smaller :
          Nat -> Option Nat :=
        psKernelSimpleMutualTargetIndexWorker
          name
          rest;
      fun (index : Nat) =>
        if psKernelNameEq name shape.decl.name then
          Option.some index
        else
          smaller (Nat.succ index)

def psKernelSimpleMutualTargetIndex
    (name : PsKernelName)
    (shapes : List PsKernelSimpleMutualTypeShape) :
    Option Nat :=
  psKernelSimpleMutualTargetIndexWorker
    name
    shapes
    0

def psKernelMutualTypeShapeListGet
    (values : List PsKernelSimpleMutualTypeShape) :
    Nat -> Option PsKernelSimpleMutualTypeShape :=
  match values with
  | List.nil =>
      fun (_index : Nat) =>
        Option.none
  | List.cons head tail =>
      let smaller :
          Nat -> Option PsKernelSimpleMutualTypeShape :=
        psKernelMutualTypeShapeListGet tail;
      fun (index : Nat) =>
        match index with
        | Nat.zero =>
            Option.some head
        | Nat.succ remaining =>
            smaller remaining

def psKernelSimpleMutualIndicesContainTarget
    (targets : List PsKernelName)
    (indices : List PsKernelExpr) : Bool :=
  match indices with
  | List.nil =>
      false
  | List.cons head tail =>
      if
          psKernelSimpleMutualContainsConst
            targets
            head then
        true
      else
        psKernelSimpleMutualIndicesContainTarget
          targets
          tail

def psKernelSimpleMutualAppInfo
    (targets : List PsKernelName)
    (shapes : List PsKernelSimpleMutualTypeShape)
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (expr : PsKernelExpr) :
    Option PsKernelSimpleMutualAppInfo :=
  match psKernelExprGetAppFn expr with
  | PsKernelExpr.const name foundLevels =>
      if psKernelLevelListEq foundLevels levels then
        match
            psKernelSimpleMutualTargetIndex
              name
              shapes with
        | Option.none =>
            Option.none
        | Option.some target =>
            match
                psKernelMutualTypeShapeListGet
                  shapes
                  target with
            | Option.none =>
                Option.none
            | Option.some shape =>
                match
                    psKernelConsumeSimpleResultParams
                      params
                      (psKernelExprGetAppArgs expr) with
                | Option.none =>
                    Option.none
                | Option.some indices =>
                    if
                        Nat.beq
                          (psKernelExprListLength indices)
                          (psKernelOpenBinderListLength
                            shape.indices) then
                      if
                          psKernelSimpleMutualIndicesContainTarget
                            targets
                            indices then
                        Option.none
                      else
                        Option.some
                          (PsKernelSimpleMutualAppInfo.mk
                            target
                            indices)
                    else
                      Option.none
      else
        Option.none
  | _ =>
      Option.none

def psKernelSimpleMutualCtorApp
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (shape : PsKernelSimpleMutualConstructorShape) :
    PsKernelExpr :=
  psKernelApplyArgs
    (PsKernelExpr.const
      shape.ctor.name
      levels)
    (psKernelExprListAppend
      (psKernelSimpleParamArgs params)
      (psKernelOpenBinderExprs shape.fields))

def psKernelMutualOpenBinderListGet
    (values : List PsKernelOpenBinder) :
    Nat -> Option PsKernelOpenBinder :=
  match values with
  | List.nil =>
      fun (_index : Nat) =>
        Option.none
  | List.cons head tail =>
      let smaller :
          Nat -> Option PsKernelOpenBinder :=
        psKernelMutualOpenBinderListGet tail;
      fun (index : Nat) =>
        match index with
        | Nat.zero =>
            Option.some head
        | Nat.succ remaining =>
            smaller remaining

def psKernelSimpleMutualMotiveApp
    (motives : List PsKernelOpenBinder)
    (target : Nat)
    (indices : List PsKernelExpr)
    (major : PsKernelExpr) :
    Except String PsKernelExpr :=
  match
      psKernelMutualOpenBinderListGet
        motives
        target with
  | Option.none =>
      Except.error
        "mutual recursor motive target is out of bounds"
  | Option.some motive =>
      Except.ok
        (psKernelSimpleMotiveApp
          (PsKernelExpr.fvar
            motive.internalName)
          indices
          major)

def psKernelSimpleMutualHasRecursiveFields
    (shapes : List PsKernelSimpleMutualConstructorShape) :
    Bool :=
  match shapes with
  | List.nil =>
      false
  | List.cons shape rest =>
      match shape.recursiveFields with
      | List.nil =>
          psKernelSimpleMutualHasRecursiveFields rest
      | List.cons _ _ =>
          true

def psKernelSimpleMutualRecursiveFieldsHaveArgs
    (fields : List PsKernelSimpleMutualRecursiveField) :
    Bool :=
  match fields with
  | List.nil =>
      false
  | List.cons field rest =>
      match field.args with
      | List.nil =>
          psKernelSimpleMutualRecursiveFieldsHaveArgs rest
      | List.cons _ _ =>
          true

def psKernelSimpleMutualHasReflexiveFields
    (shapes : List PsKernelSimpleMutualConstructorShape) :
    Bool :=
  match shapes with
  | List.nil =>
      false
  | List.cons shape rest =>
      if
          psKernelSimpleMutualRecursiveFieldsHaveArgs
            shape.recursiveFields then
        true
      else
        psKernelSimpleMutualHasReflexiveFields
          rest


def psKernelReverseMutualRecursiveFieldsWorker
    (values : List PsKernelSimpleMutualRecursiveField) :
    List PsKernelSimpleMutualRecursiveField ->
    List PsKernelSimpleMutualRecursiveField :=
  match values with
  | List.nil =>
      fun
        (acc : List PsKernelSimpleMutualRecursiveField) =>
        acc
  | List.cons head tail =>
      let smaller :
          List PsKernelSimpleMutualRecursiveField ->
          List PsKernelSimpleMutualRecursiveField :=
        psKernelReverseMutualRecursiveFieldsWorker tail;
      fun
        (acc : List PsKernelSimpleMutualRecursiveField) =>
        smaller
          (List.cons head acc)

def psKernelReverseMutualRecursiveFields
    (values : List PsKernelSimpleMutualRecursiveField) :
    List PsKernelSimpleMutualRecursiveField :=
  psKernelReverseMutualRecursiveFieldsWorker
    values
    List.nil

/-- Conservative, checked neutral-form shortcut. An application whose
    head is an already admitted *inductive type* (not a definition, primitive,
    recursor, let, or local value) cannot perform a head delta/beta/iota step.
    This is only used when the complete source syntax has no occurrence of
    any fresh type being declared. Thus its WHNF is the same expression for
    the purposes of recursive-occurrence classification, and no positivity
    condition or checked constructor judgment is bypassed. Unknown heads,
    definitions and domains mentioning any target take the full WHNF path. -/
def psKernelMutualInductiveNeutralDomain
    (session : PsKernelCheckerSession)
    (targets : List PsKernelName)
    (domain : PsKernelExpr) : Bool :=
  if psKernelSimpleMutualContainsConst targets domain then
    false
  else
    match psKernelExprGetAppFn domain with
    | PsKernelExpr.const name _ =>
        match psKernelEnvironmentFind session.context.environment name with
        | some (.inductInfo _) => true
        | _ => false
    | _ => false

/-- A single *actual* delta step may reveal a canonical, already checked
    inductive type head. Delta unfolding is exactly the same operation used by
    the authoritative WHNF engine; a checked inductive type head is irreducible.
    Both source and expansion must be free of freshly declared family names.
    All other definitions, recursive heads, local values and target-bearing
    expressions use the original full WHNF and positivity analysis. -/
def psKernelMutualNeutralAfterOneDelta
    (session : PsKernelCheckerSession)
    (targets : List PsKernelName)
    (domain : PsKernelExpr) : Option PsKernelExpr :=
  if psKernelSimpleMutualContainsConst targets domain then
    none
  else
    match psKernelUnfoldDefinition session.context domain with
    | some expanded =>
        if psKernelMutualInductiveNeutralDomain session targets expanded then
          some expanded
        else none
    | none => none

/-- Render the failing *head only*, never the full (potentially huge)
    type expression. No source-level identifier is used as an acceptance rule. -/
def psKernelMutualDiagnosticName : PsKernelName → String
  | .anonymous => ""
  | .str parent suffix =>
      let head := psKernelMutualDiagnosticName parent
      if head.isEmpty then suffix else head ++ "." ++ suffix
  | .num parent suffix =>
      let head := psKernelMutualDiagnosticName parent
      if head.isEmpty then toString suffix else head ++ "." ++ toString suffix

/-- Only invoked after genuine fuel exhaustion. Inspect one exact delta step
    without treating that inspection as proof, fuel credit, or a checked result. -/
def psKernelMutualRecursiveDeltaHead
    (session : PsKernelCheckerSession)
    (domain : PsKernelExpr) : String :=
  match psKernelUnfoldDefinition session.context domain with
  | none => "no-delta"
  | some unfolded =>
      if psKernelExprEqual unfolded domain then
        "unchanged-delta"
      else
        match psKernelExprGetAppFn unfolded with
        | .const name _ => "delta-to-" ++ psKernelMutualDiagnosticName name
        | .lam .. => "delta-to-lambda"
        | .fvar .. => "delta-to-fvar"
        | _ => "delta-to-other"

/-- Diagnostics only: classify the already resolved head *declaration* kind
    of the first exhausting recursive field. No reduction or type judgment
    changes, and unknown heads never gain an accepting shortcut. -/
def psKernelMutualRecursiveDomainHeadKind
    (session : PsKernelCheckerSession)
    (domain : PsKernelExpr) : String :=
  match psKernelExprGetAppFn domain with
  | .const name _ =>
      match psKernelEnvironmentFind session.context.environment name with
      | some (.defnInfo _) =>
          "definition-" ++ psKernelMutualDiagnosticName name ++ "-" ++
            psKernelMutualRecursiveDeltaHead session domain
      | some (.inductInfo _) => "inductive"
      | some (.recInfo _) => "recursor"
      | some (.ctorInfo _) => "constructor"
      | some (.axiomInfo _) => "axiom"
      | some (.thmInfo _) => "theorem"
      | some (.opaqueInfo _) => "opaque"
      | some (.quotInfo _) => "quotient"
      | none => "unknown"
  | .fvar name =>
      match psKernelLocalContextFind session.context.localContext name with
      | some (.localDecl ..) => "local-variable"
      | some (.letDecl ..) => "local-let"
      | none => "unknown-variable"
  | .lam .. => "lambda"
  | .forallE .. => "forall"
  | .proj .. => "projection"
  | _ => "other"

def psKernelAnalyzeSimpleMutualRecursiveArgumentWithFuel
    (fuel checkerFuel : Nat) :
    PsKernelCheckerSession ->
    List PsKernelName ->
    List PsKernelSimpleMutualTypeShape ->
    List PsKernelLevel ->
    List PsKernelOpenBinder ->
    PsKernelOpenBinder ->
    PsKernelExpr ->
    List PsKernelOpenBinder ->
    PsKernelExpr ->
    Except String PsKernelMutualRecursiveArgumentResult :=
  match fuel with
  | Nat.zero =>
      fun
        (_session : PsKernelCheckerSession)
        (_targets : List PsKernelName)
        (_shapes : List PsKernelSimpleMutualTypeShape)
        (_levels : List PsKernelLevel)
        (_params : List PsKernelOpenBinder)
        (_field : PsKernelOpenBinder)
        (_domain : PsKernelExpr)
        (_revArgs : List PsKernelOpenBinder)
        (_applied : PsKernelExpr) =>
        Except.error
          "mutual recursive-argument budget exhausted"
  | Nat.succ remaining =>
      let smaller :=
        psKernelAnalyzeSimpleMutualRecursiveArgumentWithFuel
          remaining checkerFuel;
      fun
        (session : PsKernelCheckerSession)
        (targets : List PsKernelName)
        (shapes : List PsKernelSimpleMutualTypeShape)
        (levels : List PsKernelLevel)
        (params : List PsKernelOpenBinder)
        (field : PsKernelOpenBinder)
        (domain : PsKernelExpr)
        (revArgs : List PsKernelOpenBinder)
        (applied : PsKernelExpr) =>
        match
            psKernelSimpleMutualAppInfo
              targets
              shapes
              levels
              params
              domain with
        | Option.some directInfo =>
            Except.ok
              (PsKernelMutualRecursiveArgumentResult.mk
                session
                (Option.some
                  (PsKernelSimpleMutualRecursiveField.mk
                    field
                    (psKernelReverseOpenBinders revArgs)
                    directInfo.target
                    directInfo.indices)))
        | Option.none =>
            let whnfResult : Except String (Prod PsKernelExpr PsKernelCheckerSession) :=
              if psKernelMutualInductiveNeutralDomain session targets domain then
                Except.ok (Prod.mk domain session)
              else
                match psKernelMutualNeutralAfterOneDelta session targets domain with
                | some expanded => Except.ok (Prod.mk expanded session)
                | none => psKernelSessionWhnf checkerFuel session domain
            match whnfResult with
            | Except.error error =>
                -- Pure diagnostic distinction: an occurrence-free constructor
                -- domain and a domain mentioning an in-progress inductive
                -- must not be optimized by the same positivity shortcut.
                if psKernelSimpleMutualContainsConst targets domain then
                  Except.error (psKernelMutualBudgetAt
                    "recursive-domain-with-target" error)
                else
                  Except.error (psKernelMutualBudgetAt
                    ("recursive-domain-without-target-" ++
                      psKernelMutualRecursiveDomainHeadKind session domain)
                    error)
            | Except.ok reduced =>
                match
                    psKernelSimpleMutualAppInfo
                      targets
                      shapes
                      levels
                      params
                      (Prod.fst reduced) with
                | Option.some info =>
                    Except.ok
                      (PsKernelMutualRecursiveArgumentResult.mk
                        (Prod.snd reduced)
                        (Option.some
                          (PsKernelSimpleMutualRecursiveField.mk
                            field
                            (psKernelReverseOpenBinders revArgs)
                            info.target
                            info.indices)))
                | Option.none =>
                    match Prod.fst reduced with
                | PsKernelExpr.forallE
                    userName
                    argDomain
                    body
                    binderInfo =>
                    if
                        psKernelSimpleMutualContainsConst
                          targets
                          argDomain then
                      Except.error
                        "mutual inductive field has a non-positive recursive occurrence"
                    else
                      let localDomain :=
                        psKernelExprConsumeTypeAnnotations
                          argDomain;
                      let opened :=
                        psKernelSessionWithLocal
                          (Prod.snd reduced)
                          userName
                          localDomain
                          binderInfo;
                      let fresh :=
                        Prod.fst opened;
                      let child :=
                        Prod.snd opened;
                      let arg :=
                        PsKernelOpenBinder.mk
                          fresh
                          userName
                          localDomain
                          binderInfo;
                      smaller
                        child
                        targets
                        shapes
                        levels
                        params
                        field
                        (psKernelExprInstantiate1
                          body
                          (PsKernelExpr.fvar fresh))
                        (List.cons arg revArgs)
                        (PsKernelExpr.app
                          applied
                          (PsKernelExpr.fvar fresh))
                | _ =>
                    if
                        psKernelSimpleMutualContainsConst
                          targets
                          domain then
                      Except.error
                        "nested or invalid mutual inductive occurrence is not supported"
                    else if
                        psKernelSimpleMutualContainsConst
                          targets
                          (Prod.fst reduced) then
                      Except.error
                        "nested or invalid mutual inductive occurrence is not supported"
                    else
                      Except.ok
                        (PsKernelMutualRecursiveArgumentResult.mk
                          (Prod.snd reduced)
                          Option.none)

def psKernelAnalyzeSimpleMutualRecursiveArgument
    (checkerFuel : Nat)
    (session : PsKernelCheckerSession)
    (targets : List PsKernelName)
    (shapes : List PsKernelSimpleMutualTypeShape)
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (field : PsKernelOpenBinder)
    (domain : PsKernelExpr) :
    Except String PsKernelMutualRecursiveArgumentResult :=
  psKernelAnalyzeSimpleMutualRecursiveArgumentWithFuel
    (Nat.succ (psKernelExprNodeCount domain))
    checkerFuel
    session
    targets
    shapes
    levels
    params
    field
    domain
    List.nil
    (PsKernelExpr.fvar field.internalName)

def psKernelOpenSimpleMutualConstructorFieldsWithFuel
    (fuel checkerFuel : Nat) :
    PsKernelCheckerSession ->
    List PsKernelName ->
    List PsKernelSimpleMutualTypeShape ->
    List PsKernelLevel ->
    List PsKernelOpenBinder ->
    PsKernelLevel ->
    PsKernelExpr ->
    List PsKernelOpenBinder ->
    List PsKernelSimpleMutualRecursiveField ->
    Except String PsKernelMutualOpenFieldsResult :=
  match fuel with
  | Nat.zero =>
      fun
        (_session : PsKernelCheckerSession)
        (_targets : List PsKernelName)
        (_shapes : List PsKernelSimpleMutualTypeShape)
        (_levels : List PsKernelLevel)
        (_params : List PsKernelOpenBinder)
        (_resultLevel : PsKernelLevel)
        (_type : PsKernelExpr)
        (_revFields : List PsKernelOpenBinder)
        (_revRecursive : List PsKernelSimpleMutualRecursiveField) =>
        Except.error
          "mutual constructor field budget exhausted"
  | Nat.succ remaining =>
      let smaller :=
        psKernelOpenSimpleMutualConstructorFieldsWithFuel
          remaining checkerFuel;
      fun
        (session : PsKernelCheckerSession)
        (targets : List PsKernelName)
        (shapes : List PsKernelSimpleMutualTypeShape)
        (levels : List PsKernelLevel)
        (params : List PsKernelOpenBinder)
        (resultLevel : PsKernelLevel)
        (type : PsKernelExpr)
        (revFields : List PsKernelOpenBinder)
        (revRecursive : List PsKernelSimpleMutualRecursiveField) =>
        -- Preserve raw constructor Pi spine; domains may be checked
        -- and reduced, but an outer non-Pi must not become a binder.
        match type with
            | PsKernelExpr.forallE
                userName
                domain
                body
                binderInfo =>
                match
                    psKernelSessionCheck
                      checkerFuel
                      session
                      domain with
                | Except.error error =>
                    Except.error (psKernelMutualBudgetAt "field-domain-check" error)
                | Except.ok domainType =>
                    match
                        psKernelSessionEnsureSort
                          checkerFuel
                          (Prod.snd domainType)
                          (Prod.fst domainType) with
                    | Except.error error =>
                        Except.error (psKernelMutualBudgetAt "field-ensure-sort" error)
                    | Except.ok fieldLevel =>
                        if
                            if
                                psKernelLevelLe
                                  (Prod.fst fieldLevel)
                                  resultLevel then
                              true
                            else
                              psKernelLevelNormalizesToZero
                                resultLevel then
                          let localDomain :=
                            psKernelExprConsumeTypeAnnotations
                              domain;
                          let opened :=
                            psKernelSessionWithLocal
                              (Prod.snd fieldLevel)
                              userName
                              localDomain
                              binderInfo;
                          let fresh :=
                            Prod.fst opened;
                          let child :=
                            Prod.snd opened;
                          let field :=
                            PsKernelOpenBinder.mk
                              fresh
                              userName
                              localDomain
                              binderInfo;
                          match
                              psKernelAnalyzeSimpleMutualRecursiveArgument
                                checkerFuel
                                child
                                targets
                                shapes
                                levels
                                params
                                field
                                domain with
                          | Except.error error =>
                              Except.error (psKernelMutualBudgetAt "field-recursive-analysis" error)
                          | Except.ok recursiveResult =>
                              let continuation :=
                                psKernelSessionRestoreLocalScope
                                  child recursiveResult.session;
                              let nextRecursive :
                                  List PsKernelSimpleMutualRecursiveField :=
                                match
                                    recursiveResult.recursiveInfo with
                                | Option.none =>
                                    revRecursive
                                | Option.some recursive =>
                                    List.cons
                                      recursive
                                      revRecursive;
                              smaller
                                continuation
                                targets
                                shapes
                                levels
                                params
                                resultLevel
                                (psKernelExprInstantiate1
                                  body
                                  (PsKernelExpr.fvar fresh))
                                (List.cons field revFields)
                                nextRecursive
                        else
                          Except.error
                            "mutual inductive constructor field universe is too large"
            | _ =>
                Except.ok
                  (PsKernelMutualOpenFieldsResult.mk
                    session
                    (psKernelReverseOpenBinders revFields)
                    (psKernelReverseMutualRecursiveFields
                      revRecursive)
                    type)

def psKernelOpenSimpleMutualConstructorFields
    (fuel : Nat)
    (session : PsKernelCheckerSession)
    (targets : List PsKernelName)
    (shapes : List PsKernelSimpleMutualTypeShape)
    (levels : List PsKernelLevel)
    (params : List PsKernelOpenBinder)
    (resultLevel : PsKernelLevel)
    (type : PsKernelExpr) :
    Except String PsKernelMutualOpenFieldsResult :=
  psKernelOpenSimpleMutualConstructorFieldsWithFuel
    (Nat.succ fuel)
    fuel
    session
    targets
    shapes
    levels
    params
    resultLevel
    type
    List.nil
    List.nil


def psKernelSimpleMutualIHBindersWorker
    (fields : List PsKernelSimpleMutualRecursiveField) :
    List PsKernelOpenBinder ->
    Nat ->
    Except String (List PsKernelOpenBinder) :=
  match fields with
  | List.nil =>
      fun
        (_motives : List PsKernelOpenBinder)
        (_index : Nat) =>
        Except.ok List.nil
  | List.cons recursive rest =>
      let smaller :=
        psKernelSimpleMutualIHBindersWorker rest;
      fun
        (motives : List PsKernelOpenBinder)
        (index : Nat) =>
        match
            psKernelSimpleMutualMotiveApp
              motives
              recursive.target
              recursive.indices
              (psKernelApplyArgs
                (PsKernelExpr.fvar
                  recursive.field.internalName)
                (psKernelOpenBinderExprs
                  recursive.args)) with
        | Except.error error =>
            Except.error error
        | Except.ok target =>
            let internalName :=
              PsKernelName.num
                (psKernelSimpleInternalName
                  "mutualIH")
                index;
            let binder :=
              PsKernelOpenBinder.mk
                internalName
                (psKernelNameAppendAfter
                  recursive.field.userName
                  "_ih")
                (psKernelCloseOpenBinders
                  recursive.args
                  target)
                PsKernelBinderInfo.default;
            match
                smaller
                  motives
                  (Nat.succ index) with
            | Except.error error =>
                Except.error error
            | Except.ok tail =>
                Except.ok
                  (List.cons binder tail)

def psKernelSimpleMutualIHBinders
    (motives : List PsKernelOpenBinder)
    (shape : PsKernelSimpleMutualConstructorShape) :
    Except String (List PsKernelOpenBinder) :=
  psKernelSimpleMutualIHBindersWorker
    shape.recursiveFields
    motives
    0
