import Ps.Elab.Term
import Ps.Foundation.List

-- SH/1 normalization is a typed, bounded fallback for the stable elaborator's
-- changing-argument refusal. It does not relax structural-call validation.
structure PsElabRecursionPlan where
  functionName : PsName
  parameterIds : List Nat
  explicitIds : List Nat
  majorId : Nat
  generalizedIds : List Nat

structure PsElabRecursionWalkResult where
  term : PsSyntaxTerm
  changedIds : List Nat

def psElabRecursionContains (values : List Nat) : Nat -> Bool :=
  match values with
  | List.nil => fun (_target : Nat) => false
  | List.cons value rest =>
      let smaller : Nat -> Bool := psElabRecursionContains rest;
      fun (target : Nat) => if Nat.beq value target then true else smaller target

def psElabRecursionLocalId
    (context : PsLocalContext) (source : PsSyntaxTerm) : Option Nat :=
  match source with
  | PsSyntaxTerm.reference sourceName =>
      match psSyntaxNameToName sourceName with
      | Option.none => Option.none
      | Option.some name =>
          match psLocalFindUser context name with
          | Option.none => Option.none
          | Option.some declaration => Option.some (psLocalDeclId declaration)
  | _ => Option.none

def psElabRecursionIsSelf
    (plan : PsElabRecursionPlan) (context : PsLocalContext)
    (source : PsSyntaxTerm) : Bool :=
  match source with
  | PsSyntaxTerm.reference sourceName =>
      match psSyntaxNameToName sourceName with
      | Option.none => false
      | Option.some name =>
          if psNameEq name plan.functionName then
            match psLocalFindUser context name with
            | Option.none => true
            | Option.some _ => false
          else false
  | _ => false

-- '$' is not a PSC source identifier character. These names exist only in the
-- internal AST, retain the original span, and cannot capture a source binder.
def psElabRecursionParameterName (id : Nat) (span : PsSourceSpan) : PsSyntaxName :=
  PsSyntaxName.mk
    (List.cons "$psc0SH" (List.cons (psNatToString id) List.nil))
    span

def psElabRecursionPushName
    (context : PsLocalContext) (sourceName : PsSyntaxName) : PsLocalContext :=
  match psSyntaxNameToName sourceName with
  | Option.none => context
  | Option.some name =>
      let pushed := psLocalPushBinding context name
        (PsExpr.sortE PsLevel.zero) PsBinderInfo.explicit;
      pushed.context

def psElabRecursionPushNames
    (names : List PsSyntaxName) : PsLocalContext -> PsLocalContext :=
  match names with
  | List.nil => fun (context : PsLocalContext) => context
  | List.cons name rest =>
      let smaller : PsLocalContext -> PsLocalContext :=
        psElabRecursionPushNames rest;
      fun (context : PsLocalContext) =>
        smaller (psElabRecursionPushName context name)

def psElabRecursionPatternContext
    (context : PsLocalContext) (pattern : PsSyntaxPattern) : PsLocalContext :=
  match pattern with
  | PsSyntaxPattern.constructor _ names _ => psElabRecursionPushNames names context
  | _ => context

def psElabRecursionChangedArguments
    (plan : PsElabRecursionPlan) (context : PsLocalContext)
    (ids : List Nat) : List PsSyntaxTerm -> Except PsElabError (List Nat) :=
  match ids with
  | List.nil =>
      fun (arguments : List PsSyntaxTerm) =>
        match arguments with
        | List.nil => Except.ok List.nil
        | List.cons _ _ => Except.error PsElabError.structuralRecursionArity
  | List.cons id rest =>
      let smaller : List PsSyntaxTerm -> Except PsElabError (List Nat) :=
        psElabRecursionChangedArguments plan context rest;
      fun (arguments : List PsSyntaxTerm) =>
        match arguments with
        | List.nil => Except.error PsElabError.structuralRecursionArity
        | List.cons argument tail =>
            match smaller tail with
            | Except.error error => Except.error error
            | Except.ok changed =>
                if Nat.beq id plan.majorId then Except.ok changed
                else
                  match psElabRecursionLocalId context argument with
                  | Option.some actual =>
                      if Nat.beq actual id then Except.ok changed
                      else Except.ok (List.cons id changed)
                  | Option.none => Except.ok (List.cons id changed)

def psElabRecursionSelectArguments
    (generalized : List Nat) (selectGeneralized : Bool)
    (ids : List Nat) : List PsSyntaxTerm -> List PsSyntaxTerm :=
  match ids with
  | List.nil => fun (_arguments : List PsSyntaxTerm) => List.nil
  | List.cons id rest =>
      let smaller : List PsSyntaxTerm -> List PsSyntaxTerm :=
        psElabRecursionSelectArguments generalized selectGeneralized rest;
      fun (arguments : List PsSyntaxTerm) =>
        match arguments with
        | List.nil => List.nil
        | List.cons argument tail =>
            let selected := psElabRecursionContains generalized id;
            if psElabBoolAnd selected selectGeneralized then
              List.cons argument (smaller tail)
            else if psElabBoolOr selected selectGeneralized then
              smaller tail
            else List.cons argument (smaller tail)

def psElabRecursionWalkTerms
    (walk : PsLocalContext -> PsSyntaxTerm ->
      Except PsElabError PsElabRecursionWalkResult)
    (terms : List PsSyntaxTerm) :
    PsLocalContext ->
    Except PsElabError (Prod (List PsSyntaxTerm) (List Nat)) :=
  match terms with
  | List.nil =>
      fun (_context : PsLocalContext) => Except.ok (Prod.mk List.nil List.nil)
  | List.cons term rest =>
      let smaller : PsLocalContext ->
          Except PsElabError (Prod (List PsSyntaxTerm) (List Nat)) :=
        psElabRecursionWalkTerms walk rest;
      fun (context : PsLocalContext) =>
        match walk context term with
        | Except.error error => Except.error error
        | Except.ok head =>
            match smaller context with
            | Except.error error => Except.error error
            | Except.ok tail =>
                Except.ok (Prod.mk
                  (List.cons head.term (Prod.fst tail))
                  (psListAppend head.changedIds (Prod.snd tail)))

def psElabRecursionWalkFields
    (walk : PsLocalContext -> PsSyntaxTerm ->
      Except PsElabError PsElabRecursionWalkResult)
    (fields : List (Prod PsSyntaxName PsSyntaxTerm)) :
    PsLocalContext ->
    Except PsElabError (Prod (List (Prod PsSyntaxName PsSyntaxTerm)) (List Nat)) :=
  match fields with
  | List.nil =>
      fun (_context : PsLocalContext) => Except.ok (Prod.mk List.nil List.nil)
  | List.cons field rest =>
      let smaller : PsLocalContext ->
          Except PsElabError (Prod (List (Prod PsSyntaxName PsSyntaxTerm)) (List Nat)) :=
        psElabRecursionWalkFields walk rest;
      fun (context : PsLocalContext) =>
        match walk context (Prod.snd field) with
        | Except.error error => Except.error error
        | Except.ok value =>
            match smaller context with
            | Except.error error => Except.error error
            | Except.ok tail =>
                Except.ok (Prod.mk
                  (List.cons (Prod.mk (Prod.fst field) value.term) (Prod.fst tail))
                  (psListAppend value.changedIds (Prod.snd tail)))

structure PsElabRecursionBinderWalk where
  binders : List (Prod PsSyntaxBinderHead PsSyntaxTerm)
  context : PsLocalContext
  changedIds : List Nat

def psElabRecursionWalkBinders
    (walk : PsLocalContext -> PsSyntaxTerm ->
      Except PsElabError PsElabRecursionWalkResult)
    (binders : List (Prod PsSyntaxBinderHead PsSyntaxTerm)) :
    PsLocalContext -> Except PsElabError PsElabRecursionBinderWalk :=
  match binders with
  | List.nil =>
      fun (context : PsLocalContext) =>
        Except.ok (PsElabRecursionBinderWalk.mk List.nil context List.nil)
  | List.cons binder rest =>
      let smaller : PsLocalContext -> Except PsElabError PsElabRecursionBinderWalk :=
        psElabRecursionWalkBinders walk rest;
      fun (context : PsLocalContext) =>
        let head := Prod.fst binder;
        match walk context (Prod.snd binder) with
        | Except.error error => Except.error error
        | Except.ok type =>
            match smaller (psElabRecursionPushName context head.name) with
            | Except.error error => Except.error error
            | Except.ok tail =>
                Except.ok (PsElabRecursionBinderWalk.mk
                  (List.cons (Prod.mk head type.term) tail.binders)
                  tail.context
                  (psListAppend type.changedIds tail.changedIds))

def psElabRecursionWalkAlternatives
    (walk : PsLocalContext -> PsSyntaxTerm ->
      Except PsElabError PsElabRecursionWalkResult)
    (alternatives : List (Prod PsSyntaxPattern (Prod PsSyntaxTerm PsSourceSpan))) :
    PsLocalContext ->
    Except PsElabError
      (Prod (List (Prod PsSyntaxPattern (Prod PsSyntaxTerm PsSourceSpan))) (List Nat)) :=
  match alternatives with
  | List.nil =>
      fun (_context : PsLocalContext) => Except.ok (Prod.mk List.nil List.nil)
  | List.cons alternative rest =>
      let smaller : PsLocalContext ->
          Except PsElabError
            (Prod (List (Prod PsSyntaxPattern (Prod PsSyntaxTerm PsSourceSpan))) (List Nat)) :=
        psElabRecursionWalkAlternatives walk rest;
      fun (context : PsLocalContext) =>
        let pattern := Prod.fst alternative;
        let source := Prod.snd alternative;
        match walk (psElabRecursionPatternContext context pattern) (Prod.fst source) with
        | Except.error error => Except.error error
        | Except.ok body =>
            match smaller context with
            | Except.error error => Except.error error
            | Except.ok tail =>
                Except.ok (Prod.mk
                  (List.cons
                    (Prod.mk pattern (Prod.mk body.term (Prod.snd source)))
                    (Prod.fst tail))
                  (psListAppend body.changedIds (Prod.snd tail)))

def psElabRecursionWalkOptionalType
    (walk : PsLocalContext -> PsSyntaxTerm ->
      Except PsElabError PsElabRecursionWalkResult)
    (context : PsLocalContext) (type : Option PsSyntaxTerm) :
    Except PsElabError (Prod (Option PsSyntaxTerm) (List Nat)) :=
  match type with
  | Option.none => Except.ok (Prod.mk Option.none List.nil)
  | Option.some source =>
      match walk context source with
      | Except.error error => Except.error error
      | Except.ok result =>
          Except.ok (Prod.mk (Option.some result.term) result.changedIds)

def psElabRecursionRewriteCall
    (plan : PsElabRecursionPlan) (context : PsLocalContext)
    (fn : PsSyntaxTerm) (originalArguments : List PsSyntaxTerm)
    (arguments : List PsSyntaxTerm) (span : PsSourceSpan) :
    Except PsElabError PsElabRecursionWalkResult :=
  match psElabRecursionChangedArguments plan context plan.explicitIds originalArguments with
  | Except.error error => Except.error error
  | Except.ok changed =>
      if psListIsEmpty plan.generalizedIds then
        Except.ok (PsElabRecursionWalkResult.mk
          (PsSyntaxTerm.app fn arguments span) changed)
      else
        let fixed := psElabRecursionSelectArguments
          plan.generalizedIds false plan.explicitIds arguments;
        let state := psElabRecursionSelectArguments
          plan.generalizedIds true plan.explicitIds arguments;
        -- Keep the inner application saturated at the worker's fixed/major
        -- arity. The ordinary application elaborator applies changing state to
        -- the resulting induction hypothesis, exactly once and in source order.
        Except.ok (PsElabRecursionWalkResult.mk
          (PsSyntaxTerm.app (PsSyntaxTerm.app fn fixed span) state span) changed)

def psElabRecursionWalkWithFuel
    (fuel : Nat) (plan : PsElabRecursionPlan) (environment : PsEnvironment) :
    PsLocalContext -> PsSyntaxTerm ->
    Except PsElabError PsElabRecursionWalkResult :=
  match fuel with
  | Nat.zero =>
      fun (_context : PsLocalContext) (_source : PsSyntaxTerm) =>
        Except.error PsElabError.fuelExhausted
  | Nat.succ remaining =>
      let smaller : PsLocalContext -> PsSyntaxTerm ->
          Except PsElabError PsElabRecursionWalkResult :=
        psElabRecursionWalkWithFuel remaining plan environment;
      fun (context : PsLocalContext) (source : PsSyntaxTerm) =>
        match source with
        | PsSyntaxTerm.reference sourceName =>
            if psElabRecursionIsSelf plan context source then
              Except.error PsElabError.structuralRecursionEscapingReference
            else if psListIsEmpty plan.generalizedIds then
              Except.ok (PsElabRecursionWalkResult.mk source List.nil)
            else
              match psElabResolveReferenceBase context environment sourceName with
              | Option.none => Except.ok (PsElabRecursionWalkResult.mk source List.nil)
              | Option.some selected =>
                  match Prod.fst selected with
                  | PsResolvedName.global _ =>
                      Except.ok (PsElabRecursionWalkResult.mk source List.nil)
                  | PsResolvedName.local id =>
                      if psElabRecursionContains plan.parameterIds id then
                        let renamed := psElabRecursionParameterName id sourceName.span;
                        let projected := PsSyntaxName.mk
                          (psListAppend renamed.segments (Prod.snd selected)) sourceName.span;
                        Except.ok (PsElabRecursionWalkResult.mk
                          (PsSyntaxTerm.reference projected) List.nil)
                      else Except.ok (PsElabRecursionWalkResult.mk source List.nil)
        | PsSyntaxTerm.app fn arguments span =>
            match psElabRecursionWalkTerms smaller arguments context with
            | Except.error error => Except.error error
            | Except.ok args =>
                if psElabRecursionIsSelf plan context fn then
                  match psElabRecursionRewriteCall
                      plan context fn arguments (Prod.fst args) span with
                  | Except.error error => Except.error error
                  | Except.ok result =>
                      Except.ok (PsElabRecursionWalkResult.mk result.term
                        (psListAppend (Prod.snd args) result.changedIds))
                else
                  match smaller context fn with
                  | Except.error error => Except.error error
                  | Except.ok fnResult =>
                      Except.ok (PsElabRecursionWalkResult.mk
                        (PsSyntaxTerm.app fnResult.term (Prod.fst args) span)
                        (psListAppend fnResult.changedIds (Prod.snd args)))
        | PsSyntaxTerm.record fields span =>
            match psElabRecursionWalkFields smaller fields context with
            | Except.error error => Except.error error
            | Except.ok result =>
                Except.ok (PsElabRecursionWalkResult.mk
                  (PsSyntaxTerm.record (Prod.fst result) span) (Prod.snd result))
        | PsSyntaxTerm.lambda binders body span =>
            match psElabRecursionWalkBinders smaller binders context with
            | Except.error error => Except.error error
            | Except.ok binderResult =>
                match smaller binderResult.context body with
                | Except.error error => Except.error error
                | Except.ok bodyResult =>
                    Except.ok (PsElabRecursionWalkResult.mk
                      (PsSyntaxTerm.lambda binderResult.binders bodyResult.term span)
                      (psListAppend binderResult.changedIds bodyResult.changedIds))
        | PsSyntaxTerm.forallE binders body span =>
            match psElabRecursionWalkBinders smaller binders context with
            | Except.error error => Except.error error
            | Except.ok binderResult =>
                match smaller binderResult.context body with
                | Except.error error => Except.error error
                | Except.ok bodyResult =>
                    Except.ok (PsElabRecursionWalkResult.mk
                      (PsSyntaxTerm.forallE binderResult.binders bodyResult.term span)
                      (psListAppend binderResult.changedIds bodyResult.changedIds))
        | PsSyntaxTerm.letE name type value body span =>
            match psElabRecursionWalkOptionalType smaller context type with
            | Except.error error => Except.error error
            | Except.ok typeResult =>
                match smaller context value with
                | Except.error error => Except.error error
                | Except.ok valueResult =>
                    match smaller (psElabRecursionPushName context name) body with
                    | Except.error error => Except.error error
                    | Except.ok bodyResult =>
                        Except.ok (PsElabRecursionWalkResult.mk
                          (PsSyntaxTerm.letE name (Prod.fst typeResult)
                            valueResult.term bodyResult.term span)
                          (psListAppend (Prod.snd typeResult)
                            (psListAppend valueResult.changedIds bodyResult.changedIds)))
        | PsSyntaxTerm.ifE condition thenBranch elseBranch span =>
            match smaller context condition with
            | Except.error error => Except.error error
            | Except.ok conditionResult =>
                match smaller context thenBranch with
                | Except.error error => Except.error error
                | Except.ok thenResult =>
                    match smaller context elseBranch with
                    | Except.error error => Except.error error
                    | Except.ok elseResult =>
                        Except.ok (PsElabRecursionWalkResult.mk
                          (PsSyntaxTerm.ifE conditionResult.term
                            thenResult.term elseResult.term span)
                          (psListAppend conditionResult.changedIds
                            (psListAppend thenResult.changedIds elseResult.changedIds)))
        | PsSyntaxTerm.matchE scrutinee alternatives span =>
            match smaller context scrutinee with
            | Except.error error => Except.error error
            | Except.ok scrutineeResult =>
                match psElabRecursionWalkAlternatives smaller alternatives context with
                | Except.error error => Except.error error
                | Except.ok alternativesResult =>
                    Except.ok (PsElabRecursionWalkResult.mk
                      (PsSyntaxTerm.matchE scrutineeResult.term
                        (Prod.fst alternativesResult) span)
                      (psListAppend scrutineeResult.changedIds (Prod.snd alternativesResult)))
        | _ => Except.ok (PsElabRecursionWalkResult.mk source List.nil)

def psElabRecursionParameterIds (binders : List PsElabTypedBinder) : List Nat :=
  match binders with
  | List.nil => List.nil
  | List.cons binder rest =>
      List.cons binder.id (psElabRecursionParameterIds rest)

def psElabRecursionExplicitIds (binders : List PsElabTypedBinder) : List Nat :=
  match binders with
  | List.nil => List.nil
  | List.cons binder rest =>
      let smaller : List Nat := psElabRecursionExplicitIds rest;
      match binder.binder with
      | PsBinderInfo.explicit => List.cons binder.id smaller
      | _ => smaller

-- The predicate is over elaborated free-variable identities, not source text.
-- Check all domains and the result before rearranging the nondependent telescope.
def psElabRecursionHasFreeVariable (forbidden : List Nat) (expression : PsExpr) : Bool :=
  match expression with
  | PsExpr.fvar id => psElabRecursionContains forbidden id
  | PsExpr.app fn argument =>
      psElabBoolOr
        (psElabRecursionHasFreeVariable forbidden fn)
        (psElabRecursionHasFreeVariable forbidden argument)
  | PsExpr.lam _ type body _ =>
      psElabBoolOr
        (psElabRecursionHasFreeVariable forbidden type)
        (psElabRecursionHasFreeVariable forbidden body)
  | PsExpr.forallE _ type body _ =>
      psElabBoolOr
        (psElabRecursionHasFreeVariable forbidden type)
        (psElabRecursionHasFreeVariable forbidden body)
  | PsExpr.letE _ type value body =>
      psElabBoolOr
        (psElabRecursionHasFreeVariable forbidden type)
        (psElabBoolOr
          (psElabRecursionHasFreeVariable forbidden value)
          (psElabRecursionHasFreeVariable forbidden body))
  | PsExpr.proj _ _ value => psElabRecursionHasFreeVariable forbidden value
  | _ => false

def psElabRecursionLevelIsProp (level : PsLevel) : Bool :=
  match level with
  | PsLevel.zero => true
  | PsLevel.max left right =>
      psElabBoolAnd (psElabRecursionLevelIsProp left) (psElabRecursionLevelIsProp right)
  | PsLevel.imax _ right => psElabRecursionLevelIsProp right
  | _ => false

def psElabRecursionStateIsRuntime
    (context : PsElabContext) (type : PsExpr) : Bool :=
  match psWhnf context.environment context.metaContext context.localContext type with
  | PsExpr.sortE _ => false
  | _ =>
      match psInferType context.environment context.metaContext context.localContext type with
      | Except.error _ => false
      | Except.ok typeType =>
          match psWhnf context.environment context.metaContext context.localContext typeType with
          | PsExpr.sortE level => psElabBoolNot (psElabRecursionLevelIsProp level)
          | _ => false

def psElabRecursionCheckDomains
    (context : PsElabContext) (forbidden generalized : List Nat)
    (binders : List PsElabTypedBinder) : Except PsElabError Unit :=
  match binders with
  | List.nil => Except.ok Unit.unit
  | List.cons binder rest =>
      let type := psMetaInstantiate context.metaContext binder.type;
      if psExprHasUnresolvedMeta type then
        Except.error PsElabError.unresolvedMetavariable
      else if psElabRecursionHasFreeVariable forbidden type then
        Except.error PsElabError.structuralRecursionDependentParameter
      else if psElabBoolAnd
          (psElabRecursionContains generalized binder.id)
          (psElabBoolNot (psElabRecursionStateIsRuntime context type)) then
        Except.error PsElabError.structuralRecursionDependentParameter
      else psElabRecursionCheckDomains context forbidden generalized rest

def psElabRecursionSelectedBinders
    (generalized : List Nat) (selectGeneralized : Bool)
    (typed : List PsElabTypedBinder) :
    List (Prod PsSyntaxBinderHead PsSyntaxTerm) ->
    List (Prod PsSyntaxBinderHead PsSyntaxTerm) :=
  match typed with
  | List.nil => fun (_source : List (Prod PsSyntaxBinderHead PsSyntaxTerm)) => List.nil
  | List.cons binder rest =>
      let smaller : List (Prod PsSyntaxBinderHead PsSyntaxTerm) ->
          List (Prod PsSyntaxBinderHead PsSyntaxTerm) :=
        psElabRecursionSelectedBinders generalized selectGeneralized rest;
      fun (source : List (Prod PsSyntaxBinderHead PsSyntaxTerm)) =>
        match source with
        | List.nil => List.nil
        | List.cons head tail =>
            let selected := psElabRecursionContains generalized binder.id;
            if psElabBoolAnd selected selectGeneralized then List.cons head (smaller tail)
            else if psElabBoolOr selected selectGeneralized then smaller tail
            else List.cons head (smaller tail)

def psElabRecursionSelectedValues
    (generalized : List Nat) (selectGeneralized : Bool)
    (typed : List PsElabTypedBinder) : List PsExpr :=
  match typed with
  | List.nil => List.nil
  | List.cons binder rest =>
      let smaller : List PsExpr :=
        psElabRecursionSelectedValues generalized selectGeneralized rest;
      let selected := psElabRecursionContains generalized binder.id;
      if psElabBoolAnd selected selectGeneralized then
        List.cons (PsExpr.fvar binder.id) smaller
      else if psElabBoolOr selected selectGeneralized then smaller
      else List.cons (PsExpr.fvar binder.id) smaller

def psElabRecursionRenameParameters
    (plan : PsElabRecursionPlan) (environment : PsEnvironment)
    (typed : List PsElabTypedBinder) :
    List (Prod PsSyntaxBinderHead PsSyntaxTerm) ->
    PsLocalContext ->
    Except PsElabError (List (Prod PsSyntaxBinderHead PsSyntaxTerm)) :=
  match typed with
  | List.nil =>
      fun (source : List (Prod PsSyntaxBinderHead PsSyntaxTerm)) (_context : PsLocalContext) =>
        match source with
        | List.nil => Except.ok List.nil
        | List.cons _ _ => Except.error PsElabError.structuralRecursionInternal
  | List.cons binder rest =>
      let smaller : List (Prod PsSyntaxBinderHead PsSyntaxTerm) ->
          PsLocalContext ->
          Except PsElabError (List (Prod PsSyntaxBinderHead PsSyntaxTerm)) :=
        psElabRecursionRenameParameters plan environment rest;
      fun (source : List (Prod PsSyntaxBinderHead PsSyntaxTerm)) (context : PsLocalContext) =>
        match source with
        | List.nil => Except.error PsElabError.structuralRecursionInternal
        | List.cons entry tail =>
            let sourceHead := Prod.fst entry;
            match psElabRecursionWalkWithFuel 4096 plan environment context (Prod.snd entry) with
            | Except.error error => Except.error error
            | Except.ok type =>
                let next := PsLocalContext.mk (Nat.succ binder.id)
                  (List.cons
                    (PsLocalDecl.binding binder.id binder.name binder.type binder.binder)
                    context.declarations);
                match smaller tail next with
                | Except.error error => Except.error error
                | Except.ok renamed =>
                    let head := PsSyntaxBinderHead.mk
                      (psElabRecursionParameterName binder.id sourceHead.name.span)
                      sourceHead.kind sourceHead.span;
                    Except.ok (List.cons (Prod.mk head type.term) renamed)

def psElabRecursionWrapAlternatives
    (state : List (Prod PsSyntaxBinderHead PsSyntaxTerm))
    (alternatives : List (Prod PsSyntaxPattern (Prod PsSyntaxTerm PsSourceSpan))) :
    List (Prod PsSyntaxPattern (Prod PsSyntaxTerm PsSourceSpan)) :=
  match alternatives with
  | List.nil => List.nil
  | List.cons alternative rest =>
      let source := Prod.snd alternative;
      List.cons
        (Prod.mk (Prod.fst alternative)
          (Prod.mk
            (PsSyntaxTerm.lambda state (Prod.fst source) (Prod.snd source))
            (Prod.snd source)))
        (psElabRecursionWrapAlternatives state rest)

structure PsElabStructuralNormalization where
  publicName : PsName
  workerName : PsName
  workerBinders : List (Prod PsSyntaxBinderHead PsSyntaxTerm)
  workerType : PsSyntaxTerm
  workerValue : PsSyntaxTerm
  publicContext : PsElabContext
  publicBindersRev : List PsElabTypedBinder
  publicType : PsExpr
  workerArguments : List PsExpr

-- This record retains the actual successful plan and constructed worker syntax.
-- It deliberately contains no elaboration context or environment snapshot.
structure PsElabNormalizationOrigin where
  plan : PsElabRecursionPlan
  span : PsSourceSpan
  workerName : PsName
  workerBinders : List (Prod PsSyntaxBinderHead PsSyntaxTerm)
  workerType : PsSyntaxTerm
  workerValue : PsSyntaxTerm

structure PsElabStructuralNormalizationWithOrigin where
  normalization : PsElabStructuralNormalization
  origin : PsElabNormalizationOrigin

def psElabRecursionBuildNormalizationWithOrigin
    (plan : PsElabRecursionPlan)
    (binders : List (Prod PsSyntaxBinderHead PsSyntaxTerm))
    (typeSyntax valueSyntax : PsSyntaxTerm)
    (span : PsSourceSpan)
    (binderResult : PsElabTypedBindersResult)
    (typeResult : PsElabTermResult) :
    Except PsElabError PsElabStructuralNormalizationWithOrigin :=
  let typed := psElabTypedBinderListReverse binderResult.bindersRev;
  let forbidden := List.cons plan.majorId plan.generalizedIds;
  let publicType := psMetaInstantiate typeResult.context.metaContext typeResult.term;
  if psExprHasUnresolvedMeta publicType then
    Except.error PsElabError.unresolvedMetavariable
  else if psElabRecursionHasFreeVariable forbidden publicType then
    Except.error PsElabError.structuralRecursionDependentParameter
  else
    match psElabRecursionCheckDomains typeResult.context forbidden plan.generalizedIds typed with
    | Except.error error => Except.error error
    | Except.ok _ =>
        match psElabRecursionRenameParameters
            plan typeResult.context.environment typed binders psLocalEmpty with
        | Except.error error => Except.error error
        | Except.ok renamedBinders =>
            match psElabRecursionWalkWithFuel
                4096 plan typeResult.context.environment
                typeResult.context.localContext typeSyntax with
            | Except.error error => Except.error error
            | Except.ok renamedType =>
                match psElabRecursionWalkWithFuel
                    4096 plan typeResult.context.environment
                    typeResult.context.localContext valueSyntax with
                | Except.error error => Except.error error
                | Except.ok renamedValue =>
                    match renamedValue.term with
                    | PsSyntaxTerm.matchE major alternatives matchSpan =>
                        let fixed := psElabRecursionSelectedBinders
                          plan.generalizedIds false typed renamedBinders;
                        let state := psElabRecursionSelectedBinders
                          plan.generalizedIds true typed renamedBinders;
                        let fixedValues := psElabRecursionSelectedValues
                          plan.generalizedIds false typed;
                        let stateValues := psElabRecursionSelectedValues
                          plan.generalizedIds true typed;
                        -- Numeric name components cannot be denoted by PSC
                        -- source identifiers. Environment insertion additionally
                        -- rejects an existing internal declaration with this name.
                        let workerName := psNameAppendNum
                          (psNameAppendStr plan.functionName "$psc0SH") 0;
                        let workerType : PsSyntaxTerm :=
                          PsSyntaxTerm.forallE state renamedType.term span;
                        let workerValue : PsSyntaxTerm :=
                          PsSyntaxTerm.matchE major
                            (psElabRecursionWrapAlternatives state alternatives) matchSpan;
                        let normalization : PsElabStructuralNormalization :=
                          PsElabStructuralNormalization.mk
                            plan.functionName workerName fixed workerType workerValue
                            typeResult.context binderResult.bindersRev publicType
                            (psListAppend fixedValues stateValues);
                        let origin : PsElabNormalizationOrigin :=
                          PsElabNormalizationOrigin.mk
                            plan span workerName fixed workerType workerValue;
                        Except.ok
                          (PsElabStructuralNormalizationWithOrigin.mk normalization origin)
                    | _ => Except.error PsElabError.structuralRecursionInternal

def psElabRecursionBuildNormalization
    (plan : PsElabRecursionPlan)
    (binders : List (Prod PsSyntaxBinderHead PsSyntaxTerm))
    (typeSyntax valueSyntax : PsSyntaxTerm)
    (span : PsSourceSpan)
    (binderResult : PsElabTypedBindersResult)
    (typeResult : PsElabTermResult) :
    Except PsElabError PsElabStructuralNormalization :=
  match psElabRecursionBuildNormalizationWithOrigin
      plan binders typeSyntax valueSyntax span binderResult typeResult with
  | Except.error error => Except.error error
  | Except.ok result => Except.ok result.normalization

def psElabRecursionTermCallback
    (context : PsElabContext) (term : PsSyntaxTerm) (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  psElabTerm context term expected

def psElabPlanStructuralNormalizationWithOrigin
    (environment : PsEnvironment) (nameSyntax : PsSyntaxName)
    (binders : List (Prod PsSyntaxBinderHead PsSyntaxTerm))
    (typeSyntax valueSyntax : PsSyntaxTerm) (span : PsSourceSpan) :
    Except PsElabError (Option PsElabStructuralNormalizationWithOrigin) :=
  match valueSyntax with
  | PsSyntaxTerm.matchE scrutinee _ _ =>
      match psSyntaxNameToName nameSyntax with
      | Option.none => Except.error PsElabError.emptyName
      | Option.some name =>
          match psElabTypedBinders psElabRecursionTermCallback
              (psElabContextEmpty environment) binders with
          | Except.error error => Except.error error
          | Except.ok binderResult =>
              match psElabRecursionLocalId binderResult.context.localContext scrutinee with
              | Option.none => Except.ok Option.none
              | Option.some majorId =>
                  let typed := psElabTypedBinderListReverse binderResult.bindersRev;
                  let explicitIds := psElabRecursionExplicitIds typed;
                  if psElabBoolNot (psElabRecursionContains explicitIds majorId) then
                    Except.ok Option.none
                  else
                    match psElabTerm binderResult.context typeSyntax Option.none with
                    | Except.error error => Except.error error
                    | Except.ok typeResult =>
                        match psInferEnsureSort typeResult.context.environment
                            typeResult.context.metaContext typeResult.context.localContext
                            typeResult.type with
                        | Except.error error => Except.error (PsElabError.infer error)
                        | Except.ok _ =>
                            let plan := PsElabRecursionPlan.mk name
                              (psElabRecursionParameterIds typed) explicitIds majorId List.nil;
                            match psElabRecursionWalkWithFuel
                                4096 plan environment typeResult.context.localContext valueSyntax with
                            | Except.error error => Except.error error
                            | Except.ok scanned =>
                                if psListIsEmpty scanned.changedIds then Except.ok Option.none
                                else
                                  let generalized := PsElabRecursionPlan.mk name
                                    plan.parameterIds explicitIds majorId scanned.changedIds;
                                  match psElabRecursionBuildNormalizationWithOrigin generalized
                                      binders typeSyntax valueSyntax span binderResult typeResult with
                                  | Except.error error => Except.error error
                                  | Except.ok normalized => Except.ok (Option.some normalized)
  | _ => Except.ok Option.none

-- Existing callers receive the same plan result and errors by projection.
def psElabPlanStructuralNormalization
    (environment : PsEnvironment) (nameSyntax : PsSyntaxName)
    (binders : List (Prod PsSyntaxBinderHead PsSyntaxTerm))
    (typeSyntax valueSyntax : PsSyntaxTerm) (span : PsSourceSpan) :
    Except PsElabError (Option PsElabStructuralNormalization) :=
  match psElabPlanStructuralNormalizationWithOrigin
      environment nameSyntax binders typeSyntax valueSyntax span with
  | Except.error error => Except.error error
  | Except.ok result =>
      match result with
      | Option.none => Except.ok Option.none
      | Option.some normalized => Except.ok (Option.some normalized.normalization)
