import Ps.Compiler.Api

/-- Exact immutable source graph, its checkable logical expansion, and runtime view. -/
structure PsCompilerOrdinaryModule where
  source : PsCompilerAdmissionReadyModule
  logical : PsCompilerAdmissionReadyModule
  runtimeEnvironment : PsEnvironment
  partialNames : List PsName

def psOrdinaryHasType
    (environment : PsEnvironment) (locals : PsLocalContext)
    (value type : PsExpr) : Bool :=
  match psInferType environment psMetaEmpty locals value with
  | Except.error _ => false
  | Except.ok actual =>
      let result := psUnify environment locals psMetaEmpty actual type;
      result.success && !psExprHasUnresolvedMeta value && !psExprHasUnresolvedMeta type

def psOrdinaryLocalWitness
    (environment : PsEnvironment) (locals : PsLocalContext) (type : PsExpr)
    (declarations : List PsLocalDecl) : Option PsExpr :=
  match declarations with
  | List.nil => Option.none
  | List.cons declaration rest =>
      let value := PsExpr.fvar (psLocalDeclId declaration);
      if psOrdinaryHasType environment locals value type then Option.some value
      else psOrdinaryLocalWitness environment locals type rest

def PsOrdinaryWitnessSearch : Type :=
  PsEnvironment -> PsLocalContext -> PsExpr -> Nat -> Prod (Option PsExpr) Nat

def psOrdinaryAtomicWitness (name : PsName) : Option PsExpr :=
  if psNameEq name psNatName then Option.some (PsExpr.lit (PsLiteral.natural 0))
  else if psNameEq name psIntName then
    Option.some (PsExpr.app (PsExpr.constE psIntOfNatName []) (PsExpr.lit (PsLiteral.natural 0)))
  else if psNameEq name psBoolName then Option.some (PsExpr.constE psBoolFalseName [])
  else if psNameEq name psStringName then Option.some (PsExpr.lit (PsLiteral.string ""))
  else if psNameEq name psCharName then
    Option.some (PsExpr.app (PsExpr.constE psCharOfNatName []) (PsExpr.lit (PsLiteral.natural 0)))
  else if psNameEq name psUnitName then Option.some (PsExpr.constE psUnitUnitName [])
  else Option.none

def psOrdinaryUnaryWitness (name : PsName) (element : PsExpr) : Option PsExpr :=
  if psNameEq name psListName then
    Option.some (PsExpr.app (PsExpr.constE psSelfHostListNilName []) element)
  else if psNameEq name psOptionName then
    Option.some (PsExpr.app (PsExpr.constE psSelfHostOptionNoneName []) element)
  else if psNameEq name psArrayName then
    Option.some (psExprApplyMany (PsExpr.constE psArrayEmptyWithCapacityName [])
      [element, PsExpr.lit (PsLiteral.natural 0)])
  else Option.none

-- Siblings and failed alternatives share the remaining witness-attempt budget.
def psOrdinaryBinaryWitness
    (smaller : PsOrdinaryWitnessSearch) (environment : PsEnvironment) (locals : PsLocalContext)
    (name : PsName) (first second : PsExpr) (available : Nat) :
    Prod (Option PsExpr) Nat :=
  if psNameEq name psProdName then
    let left := smaller environment locals first available;
    match left.fst with
    | Option.none => Prod.mk Option.none left.snd
    | Option.some leftValue =>
        let right := smaller environment locals second left.snd;
        match right.fst with
        | Option.none => Prod.mk Option.none right.snd
        | Option.some rightValue =>
            Prod.mk (Option.some (psExprApplyMany (PsExpr.constE psProdMkName [])
              [first, second, leftValue, rightValue])) right.snd
  else if psNameEq name psSelfHostExceptName then
    let success := smaller environment locals second available;
    match success.fst with
    | Option.some value =>
        Prod.mk (Option.some (psSelfHostExceptOkOf first second value)) success.snd
    | Option.none =>
        let failure := smaller environment locals first success.snd;
        match failure.fst with
        | Option.some error =>
            Prod.mk (Option.some (psSelfHostExceptErrorOf first second error)) failure.snd
        | Option.none => Prod.mk Option.none failure.snd
  else Prod.mk Option.none available

def psOrdinaryApplicationWitness
    (smaller : PsOrdinaryWitnessSearch) (environment : PsEnvironment) (locals : PsLocalContext)
    (reduced : PsExpr) (available : Nat) : Prod (Option PsExpr) Nat :=
  let view := psExprAppView reduced;
  match view.head with
  | PsExpr.constE name _ =>
      match view.args with
      | List.nil => Prod.mk Option.none available
      | List.cons first rest =>
          match rest with
          | List.nil => Prod.mk (psOrdinaryUnaryWitness name first) available
          | List.cons second tail =>
              match tail with
              | List.nil => psOrdinaryBinaryWitness smaller environment locals name first second available
              | _ => Prod.mk Option.none available
  | _ => Prod.mk Option.none available

def psOrdinarySortWitness (level : PsLevel) : Option PsExpr :=
  match level with
  | PsLevel.zero =>
      Option.some (psExprApplyMany (PsExpr.constE psEqName [PsLevel.succ PsLevel.zero])
        [PsExpr.constE psNatName [], PsExpr.lit (PsLiteral.natural 0),
          PsExpr.lit (PsLiteral.natural 0)])
  | PsLevel.succ inner =>
      match inner with
      | PsLevel.zero => Option.some (PsExpr.constE psNatName [])
      | _ => Option.none
  | _ => Option.none

-- Constructor search reads checked declaration metadata only. It never consults
-- a recursive executable body, introduces a meta, or resets the shared budget.
def psOrdinaryConstructorFieldsWorker
    (smaller : PsOrdinaryWitnessSearch) (environment : PsEnvironment)
    (locals : PsLocalContext) (target : PsExpr) (fields : Nat) :
    PsExpr -> Nat -> Prod (Option PsExpr) Nat :=
  match fields with
  | 0 =>
      fun (candidate : PsExpr) (budget : Nat) =>
        if psOrdinaryHasType environment locals candidate target then
          Prod.mk (Option.some candidate) budget
        else Prod.mk Option.none budget
  | remaining + 1 =>
      let continue : PsExpr -> Nat -> Prod (Option PsExpr) Nat :=
        psOrdinaryConstructorFieldsWorker smaller environment locals target remaining;
      fun (candidate : PsExpr) (budget : Nat) =>
        match budget with
        | 0 => Prod.mk Option.none 0
        | available + 1 =>
            match psInferType environment psMetaEmpty locals candidate with
            | Except.error _ => Prod.mk Option.none available
            | Except.ok type =>
                match psWhnf environment psMetaEmpty locals type with
                | PsExpr.forallE name domain body binder =>
                    let field := smaller environment locals domain available;
                    match field.fst with
                    | Option.none => Prod.mk Option.none field.snd
                    | Option.some value =>
                        continue (PsExpr.app candidate value) field.snd
                | _ => Prod.mk Option.none available

def psOrdinaryConstructorAlternativesWorker
    (smaller : PsOrdinaryWitnessSearch) (environment : PsEnvironment)
    (locals : PsLocalContext) (target : PsExpr) (parent : PsInductiveInfo)
    (levels : List PsLevel) (parameters : List PsExpr) (constructors : List PsName) :
    Nat -> Prod (Option PsExpr) Nat :=
  match constructors with
  | List.nil => fun (budget : Nat) => Prod.mk Option.none budget
  | List.cons name rest =>
      let next : Nat -> Prod (Option PsExpr) Nat :=
        psOrdinaryConstructorAlternativesWorker smaller environment locals target
          parent levels parameters rest;
      fun (budget : Nat) =>
        match budget with
        | 0 => Prod.mk Option.none 0
        | available + 1 =>
            match psEnvironmentFind environment name with
            | Option.some declaration =>
                match declaration with
                | PsDeclaration.constructorDecl info =>
                    if psNameEq info.inductiveName parent.name &&
                        Nat.beq info.numParams parent.numParams &&
                        Nat.beq info.levelParams.length levels.length then
                      let candidate := psExprApplyMany (PsExpr.constE name levels) parameters;
                      let searched := psOrdinaryConstructorFieldsWorker smaller environment locals
                        target info.numFields candidate available;
                      match searched.fst with
                      | Option.some value => searched
                      | Option.none => next searched.snd
                    else next available
                | _ => next available
            | Option.none => next available

def psOrdinaryInductiveWitness
    (smaller : PsOrdinaryWitnessSearch) (environment : PsEnvironment)
    (locals : PsLocalContext) (target : PsExpr) (available : Nat) :
    Prod (Option PsExpr) Nat :=
  let view := psExprAppView target;
  match view.head with
  | PsExpr.constE name levels =>
      match psEnvironmentFind environment name with
      | Option.some declaration =>
          match declaration with
          | PsDeclaration.inductiveDecl info =>
              if Nat.beq info.numIndices 0 &&
                  Nat.beq info.numParams view.args.length &&
                  Nat.beq info.levelParams.length levels.length then
                psOrdinaryConstructorAlternativesWorker smaller environment locals target
                  info levels view.args info.constructors available
              else Prod.mk Option.none available
          | _ => Prod.mk Option.none available
      | Option.none => Prod.mk Option.none available
  | _ => Prod.mk Option.none available

/-- Bounded constructive search; absence is not uninhabitedness evidence.
The recursive executable body is never consulted here. -/
def psOrdinaryWitnessBudgetWorker (fuel : Nat) : PsOrdinaryWitnessSearch :=
  match fuel with
  | 0 =>
      fun (environment : PsEnvironment) (locals : PsLocalContext) (type : PsExpr) (budget : Nat) =>
        Prod.mk Option.none budget
  | remaining + 1 =>
      let smaller : PsOrdinaryWitnessSearch := psOrdinaryWitnessBudgetWorker remaining;
      fun (environment : PsEnvironment) (locals : PsLocalContext) (type : PsExpr) (budget : Nat) =>
        match budget with
        | 0 => Prod.mk Option.none 0
        | available + 1 =>
            let reduced := psWhnf environment psMetaEmpty locals type;
            let primary : Prod (Option PsExpr) Nat :=
              match psOrdinaryLocalWitness environment locals type locals.declarations with
              | Option.some value => Prod.mk (Option.some value) available
              | Option.none =>
                  match reduced with
                  | PsExpr.forallE name domain body binder =>
                      let pushed := psLocalPushBinding locals name domain binder;
                      let child := smaller environment pushed.context
                        (psExprInstantiate1 body (PsExpr.fvar pushed.id)) available;
                      match child.fst with
                      | Option.none => Prod.mk Option.none child.snd
                      | Option.some value =>
                          Prod.mk (Option.some (PsExpr.lam name domain
                            (psExprAbstractFVar pushed.id value) binder)) child.snd
                  | PsExpr.sortE level => Prod.mk (psOrdinarySortWitness level) available
                  | PsExpr.constE name _ => Prod.mk (psOrdinaryAtomicWitness name) available
                  | _ => psOrdinaryApplicationWitness smaller environment locals reduced available;
            let candidate : Prod (Option PsExpr) Nat :=
              match primary.fst with
              | Option.some value => primary
              | Option.none =>
                  psOrdinaryInductiveWitness smaller environment locals reduced primary.snd;
            match candidate.fst with
            | Option.none => candidate
            | Option.some value =>
                if psOrdinaryHasType environment locals value type then candidate
                else Prod.mk Option.none candidate.snd

def psOrdinaryWitnessBudgetWithFuel
    (fuel : Nat) (environment : PsEnvironment) (locals : PsLocalContext)
    (type : PsExpr) (budget : Nat) : Prod (Option PsExpr) Nat :=
  psOrdinaryWitnessBudgetWorker fuel environment locals type budget

def psOrdinaryWitnessWithFuel
    (fuel : Nat) (environment : PsEnvironment) (locals : PsLocalContext)
    (type : PsExpr) : Option PsExpr :=
  let searched : Prod (Option PsExpr) Nat :=
    psOrdinaryWitnessBudgetWithFuel fuel environment locals type fuel;
  searched.fst

def psOrdinaryBodyName (owner : PsName) : PsName :=
  PsName.num (PsName.str owner "_psc1PartialBody") 0

def psOrdinaryAdd
    (environment : PsEnvironment) (declaration : PsDeclaration) :
    Except String PsEnvironment :=
  match psEnvironmentAdd environment declaration with
  | Option.none =>
      Except.error (String.Internal.append "PSC1_ORDINARY_DUPLICATE: "
        (psNameToString (psDeclarationName declaration)))
  | Option.some result => Except.ok result

def psOrdinaryExpandWorker (declarations : List PsDeclaration) :
    PsEnvironment -> Except String (Prod (List PsDeclaration) (List PsName)) :=
  match declarations with
  | List.nil =>
      fun (environment : PsEnvironment) => Except.ok (Prod.mk List.nil List.nil)
  | List.cons declaration rest =>
      let smaller : PsEnvironment -> Except String (Prod (List PsDeclaration) (List PsName)) :=
        psOrdinaryExpandWorker rest;
      fun (environment : PsEnvironment) =>
        match declaration with
        | PsDeclaration.axiomDecl _ _ _ => Except.error "PSC1_SOURCE_AXIOM_FORBIDDEN"
        | PsDeclaration.opaqueDecl _ _ _ _ => Except.error "PSC1_SOURCE_OPAQUE_NOT_SELECTED"
        | PsDeclaration.partialDecl name levels type body =>
            match psWhnf environment psMetaEmpty psLocalEmpty type with
            | PsExpr.forallE _ _ _ _ =>
                match psOrdinaryWitnessWithFuel 128 environment psLocalEmpty type with
                | Option.none =>
                    Except.error (String.Internal.append
                      "PSC1_PARTIAL_NO_CHECKED_INHABITANT: " (psNameToString name))
                | Option.some witness =>
                    let logical := PsDeclaration.opaqueDecl name levels type witness;
                    match psOrdinaryAdd environment logical with
                    | Except.error error => Except.error error
                    | Except.ok withLogical =>
                        let implementation := PsDeclaration.definitionDecl
                          (psOrdinaryBodyName name) levels type body;
                        match psOrdinaryAdd withLogical implementation with
                        | Except.error error => Except.error error
                        | Except.ok withBody =>
                            match smaller withBody with
                            | Except.error error => Except.error error
                            | Except.ok expanded =>
                                Except.ok (Prod.mk
                                  (List.cons logical (List.cons implementation expanded.fst))
                                  (List.cons name expanded.snd))
            | _ =>
                Except.error (String.Internal.append
                  "PSC1_PARTIAL_EXPECTED_FUNCTION: " (psNameToString name))
        | _ =>
            match psOrdinaryAdd environment declaration with
            | Except.error error => Except.error error
            | Except.ok next =>
                match smaller next with
                | Except.error error => Except.error error
                | Except.ok expanded =>
                    Except.ok (Prod.mk (List.cons declaration expanded.fst) expanded.snd)

def psOrdinaryExpand
    (declarations : List PsDeclaration) (environment : PsEnvironment) :
    Except String (Prod (List PsDeclaration) (List PsName)) :=
  psOrdinaryExpandWorker declarations environment

def psCompilerPrepareOrdinary
    (elaborated : PsElabModuleResult) : Except String PsCompilerOrdinaryModule :=
  match psOrdinaryExpand elaborated.declarations psSelfHostProdPreludeEnvironment with
  | Except.error error => Except.error error
  | Except.ok expanded =>
      match psEncodeCheckedAdmissionsCanonical expanded.fst with
      | Except.error _ => Except.error "PSC1_ORDINARY_LOGICAL_ENCODING_FAILED"
      | Except.ok encoded =>
          match psAddDeclarationList psSelfHostProdPreludeEnvironment elaborated.declarations with
          | Except.error _ => Except.error "PSC1_ORDINARY_RUNTIME_CLOSURE_FAILED"
          | Except.ok runtimeEnvironment =>
              Except.ok (PsCompilerOrdinaryModule.mk
                (PsCompilerAdmissionReadyModule.mk elaborated.declarations)
                (PsCompilerAdmissionReadyModule.mk expanded.fst)
                runtimeEnvironment expanded.snd)

/-- This API computes a typed candidate; independent admission belongs to the host. -/
def psCompilerOrdinaryIr
    (prepared : PsCompilerOrdinaryModule) : Except String PsVerifiedIrModule :=
  let elaborated : PsElabModuleResult :=
    PsElabModuleResult.mk prepared.runtimeEnvironment prepared.source.declarations;
  match psCompilerPrepareOrdinary elaborated with
  | Except.error error => Except.error error
  | Except.ok repeated =>
      match psCompilerAdmissionsFromPrepared prepared.logical with
      | Except.error _ => Except.error "PSC1_ORDINARY_LOGICAL_INTEGRITY_FAILED"
      | Except.ok originalEncoded =>
          match psCompilerAdmissionsFromPrepared repeated.logical with
          | Except.error _ => Except.error "PSC1_ORDINARY_LOGICAL_INTEGRITY_FAILED"
          | Except.ok repeatedEncoded =>
              if psStringEq originalEncoded repeatedEncoded then
                match psEraseCoreModuleWithRuntimePrelude repeated.runtimeEnvironment
                    psSelfHostRuntimePreludeDeclarationsWithProd repeated.source.declarations with
                | Except.error _ => Except.error "PSC1_ORDINARY_ERASURE_FAILED"
                | Except.ok ir => Except.ok ir
              else Except.error "PSC1_ORDINARY_BODY_BINDING_MISMATCH"
