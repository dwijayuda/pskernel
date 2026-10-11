import Ps.Elab.Binders
import Ps.Elab.Application

def psExprApplyManyWorker
    (arguments : List PsExpr)
    (fn : PsExpr) : PsExpr :=
  match arguments with
  | [] => fn
  | argument :: rest =>
      psExprApplyManyWorker rest (PsExpr.app fn argument)

def psExprApplyMany
    (fn : PsExpr)
    (arguments : List PsExpr) :
    PsExpr :=
  psExprApplyManyWorker arguments fn

def psElabIf
    (elaborate :
      PsElabContext ->
      PsSyntaxTerm ->
      Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (context : PsElabContext)
    (condition : PsSyntaxTerm)
    (thenBranch : PsSyntaxTerm)
    (elseBranch : PsSyntaxTerm)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  let boolType := PsExpr.constE psBoolName [];
  match elaborate context condition (Option.some boolType) with
  | Except.error error => Except.error error
  | Except.ok conditionResult =>
      let trueTerm := PsExpr.constE psBoolTrueName [];
      let conditionProp :=
        psExprApplyMany
          (PsExpr.constE
            psEqName
            [PsLevel.succ PsLevel.zero])
          [boolType, conditionResult.term, trueTerm];
      let decider :=
        psExprApplyMany
          (PsExpr.constE psBoolDecEqName [])
          [conditionResult.term, trueTerm];
      match elaborate
          conditionResult.context
          thenBranch
          expected with
      | Except.error error => Except.error error
      | Except.ok thenResult =>
          let resultType : PsExpr :=
            match expected with
            | some type => type
            | none => thenResult.type;
          match elaborate
              thenResult.context
              elseBranch
              (Option.some resultType) with
          | Except.error error => Except.error error
          | Except.ok elseResult =>
              let metaContext := elseResult.context.metaContext;
              let instantiatedType :=
                psMetaInstantiate metaContext resultType;
              match psInferType
                  elseResult.context.environment
                  metaContext
                  elseResult.context.localContext
                  instantiatedType with
              | Except.error error =>
                  Except.error (PsElabError.infer error)
              | Except.ok typeType =>
                  match psInferEnsureSort
                      elseResult.context.environment
                      metaContext
                      elseResult.context.localContext
                      typeType with
                  | Except.error error =>
                      Except.error (PsElabError.infer error)
                  | Except.ok universeLevel =>
                      let term :=
                        psExprApplyMany
                          (PsExpr.constE psIteName [universeLevel])
                          [
                            instantiatedType,
                            psMetaInstantiate metaContext conditionProp,
                            psMetaInstantiate metaContext decider,
                            psMetaInstantiate metaContext thenResult.term,
                            psMetaInstantiate metaContext elseResult.term
                          ];
                      let restoredContext :=
                        psElabLeaveScope context elseResult.context;
                      psElabResolvedTerm
                        restoredContext
                        term
                        expected

structure PsExprAppView where
  head : PsExpr
  args : List PsExpr

def psExprAppViewAccWorker
    (expr : PsExpr)
    (args : List PsExpr) : PsExprAppView :=
  match expr with
  | .app fn argument =>
      psExprAppViewAccWorker fn (List.cons argument args)
  | _ =>
      {
        head := expr
        args := args
      }

def psExprAppViewAcc
    (expr : PsExpr)
    (args : List PsExpr) : PsExprAppView :=
  psExprAppViewAccWorker expr args

def psExprAppView (expr : PsExpr) : PsExprAppView :=
  psExprAppViewAcc expr []

def psExprHasConst
    (target : PsName)
    (expr : PsExpr) : Bool :=
  match expr with
  | .constE name _ => psNameEq name target
  | .app fn argument =>
      psElabBoolOr
        (psExprHasConst target fn)
        (psExprHasConst target argument)
  | .lam _ type body _ =>
      psElabBoolOr
        (psExprHasConst target type)
        (psExprHasConst target body)
  | .forallE _ type body _ =>
      psElabBoolOr
        (psExprHasConst target type)
        (psExprHasConst target body)
  | .letE _ type value body =>
      psElabBoolOr
        (psExprHasConst target type)
        (psElabBoolOr
          (psExprHasConst target value)
          (psExprHasConst target body))
  | .proj _ _ value => psExprHasConst target value
  | _ => false

def psMatchNameEqTarget
    (target : PsName)
    (name : PsName) : Bool :=
  psNameEq name target

def psMatchNameListContains
    (names : List PsName)
    (target : PsName) : Bool :=
  match names with
  | [] =>
      false
  | name :: rest =>
      if psMatchNameEqTarget target name then
        true
      else
        psMatchNameListContains rest target

structure PsElabMatchAlternative where
  constructorName : PsName
  pattern : PsSyntaxPattern
  body : PsSyntaxTerm
  span : PsSourceSpan

def psElabMatchAlternativeFind
    (name : PsName)
    (alternatives : List PsElabMatchAlternative) :
    Option PsElabMatchAlternative :=
  match alternatives with
  | [] => Option.none
  | alternative :: rest =>
      if psNameEq alternative.constructorName name then
        Option.some alternative
      else
        psElabMatchAlternativeFind name rest

def psElabMatchAlternativeCovered
    (alternatives : List PsElabMatchAlternative)
    (ctorName : PsName) : Bool :=
  match psElabMatchAlternativeFind ctorName alternatives with
  | some _ => true
  | none => false

def psElabFillWildcardAlternatives
    (pattern : PsSyntaxPattern)
    (body : PsSyntaxTerm)
    (span : PsSourceSpan)
    (constructors : List PsName) :
    List PsElabMatchAlternative ->
    List PsElabMatchAlternative :=
  match constructors with
  | [] =>
      fun (alternativesRev : List PsElabMatchAlternative) =>
        alternativesRev
  | ctorName :: rest =>
      let smaller :
          List PsElabMatchAlternative ->
          List PsElabMatchAlternative :=
        psElabFillWildcardAlternatives
          pattern
          body
          span
          rest;
      fun (alternativesRev : List PsElabMatchAlternative) =>
        let next : List PsElabMatchAlternative :=
          match psElabMatchAlternativeFind ctorName alternativesRev with
          | some _ => alternativesRev
          | none =>
              let alternative : PsElabMatchAlternative := {
                constructorName := ctorName
                pattern := pattern
                body := body
                span := span
              };
              List.cons alternative alternativesRev;
        smaller next

def psElabMatchAlternativeListReverseAux
    (values : List PsElabMatchAlternative) :
    List PsElabMatchAlternative ->
    List PsElabMatchAlternative :=
  match values with
  | [] =>
      fun (acc : List PsElabMatchAlternative) => acc
  | value :: rest =>
      let smaller :
          List PsElabMatchAlternative ->
          List PsElabMatchAlternative :=
        psElabMatchAlternativeListReverseAux rest;
      fun (acc : List PsElabMatchAlternative) =>
        smaller (List.cons value acc)

def psElabMatchAlternativeListReverse
    (values : List PsElabMatchAlternative) :
    List PsElabMatchAlternative :=
  psElabMatchAlternativeListReverseAux values []

def psElabMatchAlternativesCoverConstructors
    (alternatives : List PsElabMatchAlternative)
    (constructors : List PsName) : Bool :=
  match constructors with
  | [] => true
  | constructorName :: rest =>
      if
          psElabMatchAlternativeCovered
            alternatives
            constructorName then
        psElabMatchAlternativesCoverConstructors alternatives rest
      else
        false

def psElabMatchPatternConstructorName
    (inductiveInfo : PsName)
    (pattern : PsSyntaxPattern) :
    Except PsElabError PsName :=
  match pattern with
  | .bool value _ =>
      if psNameEq inductiveInfo psBoolName then
        if value then
          Except.ok psBoolTrueName
        else
          Except.ok psBoolFalseName
      else
        Except.error PsElabError.matchPatternUnsupported
  | .wildcard _ =>
      Except.error PsElabError.matchPatternUnsupported
  | .constructor syntaxName _ _ =>
      match syntaxName.segments with
      | [] => Except.error PsElabError.matchPatternUnsupported
      | segment :: rest =>
          match rest with
          | [] =>
              Except.ok (psNameAppendStr inductiveInfo segment)
          | _ :: _ =>
              match psSyntaxNameToName syntaxName with
              | none => Except.error PsElabError.matchPatternUnsupported
              | some name => Except.ok name

def psElabPrepareMatchAlternativesWorker
    (inductiveInfo : PsInductiveInfo)
    (entries : List (Prod PsSyntaxPattern (Prod PsSyntaxTerm PsSourceSpan))) :
    List PsElabMatchAlternative ->
    Except PsElabError (List PsElabMatchAlternative) :=
  match entries with
  | [] =>
      fun (alternativesRev : List PsElabMatchAlternative) =>
        let alternatives :=
          psElabMatchAlternativeListReverse alternativesRev;
        let exhaustive :=
          psElabMatchAlternativesCoverConstructors
            alternatives
            inductiveInfo.constructors;
        if exhaustive then
          Except.ok alternatives
        else
          Except.error PsElabError.matchNonExhaustive
  | entry :: rest =>
      let smaller :
          List PsElabMatchAlternative ->
          Except PsElabError (List PsElabMatchAlternative) :=
        psElabPrepareMatchAlternativesWorker
          inductiveInfo
          rest;
      fun (alternativesRev : List PsElabMatchAlternative) =>
        let pattern := Prod.fst entry;
        let payload := Prod.snd entry;
        let body := Prod.fst payload;
        let span := Prod.snd payload;
        match pattern with
        | .wildcard _ =>
            match rest with
            | [] =>
                Except.ok
                  (psElabMatchAlternativeListReverse
                    (psElabFillWildcardAlternatives
                      pattern
                      body
                      span
                      inductiveInfo.constructors
                      alternativesRev))
            | _ :: _ =>
                Except.error PsElabError.matchPatternUnsupported
        | _ =>
            match psElabMatchPatternConstructorName
                inductiveInfo.name
                pattern with
            | Except.error error => Except.error error
            | Except.ok ctorName =>
                if psElabBoolNot
                    (psMatchNameListContains
                      inductiveInfo.constructors
                      ctorName) then
                  Except.error
                    (PsElabError.matchConstructorUnknown ctorName)
                else
                  match
                      psElabMatchAlternativeFind
                        ctorName
                        alternativesRev with
                  | some _ =>
                      Except.error
                        (PsElabError.matchDuplicateConstructor ctorName)
                  | none =>
                      let alternative : PsElabMatchAlternative := {
                        constructorName := ctorName
                        pattern := pattern
                        body := body
                        span := span
                      };
                      smaller
                        (List.cons alternative alternativesRev)

def psElabPrepareMatchAlternatives
    (inductiveInfo : PsInductiveInfo)
    (entries : List (Prod PsSyntaxPattern (Prod PsSyntaxTerm PsSourceSpan)))
    (alternativesRev : List PsElabMatchAlternative) :
    Except PsElabError (List PsElabMatchAlternative) :=
  psElabPrepareMatchAlternativesWorker
    inductiveInfo
    entries
    alternativesRev

structure PsElabMatchField where
  id : Nat
  name : PsName
  type : PsExpr
  binder : PsBinderInfo

structure PsElabMatchFieldsResult where
  context : PsElabContext
  fieldsRev : List PsElabMatchField

def psElabMatchApplyParametersWorker
    (context : PsElabContext)
    (parameters : List PsExpr) :
    PsExpr ->
    Except PsElabError PsExpr :=
  match parameters with
  | [] =>
      fun (cursor : PsExpr) =>
        Except.ok cursor
  | parameter :: rest =>
      let smaller : PsExpr -> Except PsElabError PsExpr :=
        psElabMatchApplyParametersWorker
          context
          rest;
      fun (cursor : PsExpr) =>
        match psInferEnsureForall
            context.environment
            context.metaContext
            context.localContext
            cursor with
        | Except.error error =>
            Except.error (PsElabError.infer error)
        | Except.ok forallView =>
            smaller
              (psExprInstantiate1
                forallView.body
                parameter)

def psElabMatchApplyParameters
    (context : PsElabContext)
    (parameters : List PsExpr)
    (cursor : PsExpr) :
    Except PsElabError PsExpr :=
  psElabMatchApplyParametersWorker
    context
    parameters
    cursor

def psSyntaxNameIsWildcardBinder
    (name : PsSyntaxName) : Bool :=
  match name.segments with
  | List.nil =>
      false
  | List.cons segment rest =>
      match rest with
      | List.nil =>
          psStringEq segment "_"
      | List.cons _ _ =>
          false

def psSyntaxNameMatchesCore
    (coreName : Option PsName)
    (candidate : PsSyntaxName) : Bool :=
  if psSyntaxNameIsWildcardBinder candidate then
    false
  else
    match coreName with
    | none =>
        false
    | some left =>
        match psSyntaxNameToName candidate with
        | none =>
            false
        | some right =>
            psNameEq left right

def psSyntaxNameListContainsCore
    (coreName : Option PsName)
    (candidates : List PsSyntaxName) : Bool :=
  match candidates with
  | List.nil =>
      false
  | List.cons candidate rest =>
      if psSyntaxNameMatchesCore coreName candidate then
        true
      else
        psSyntaxNameListContainsCore coreName rest

def psSyntaxNameListHasDuplicate
    (names : List PsSyntaxName) : Bool :=
  match names with
  | List.nil =>
      false
  | List.cons name rest =>
      if psSyntaxNameIsWildcardBinder name then
        psSyntaxNameListHasDuplicate rest
      else
        let coreName := psSyntaxNameToName name;
        if psSyntaxNameListContainsCore coreName rest then
          true
        else
          psSyntaxNameListHasDuplicate rest

def psElabMatchFieldsWorker
    (inductiveName : PsName)
    (binderSyntaxes : List PsSyntaxName) :
    PsElabContext ->
    PsExpr ->
    List PsElabMatchField ->
    Except PsElabError PsElabMatchFieldsResult :=
  match binderSyntaxes with
  | [] =>
      fun (context : PsElabContext) =>
        fun (_cursor : PsExpr) =>
          fun (fieldsRev : List PsElabMatchField) =>
            Except.ok {
              context := context
              fieldsRev := fieldsRev
            }
  | binderSyntax :: rest =>
      let smaller :
          PsElabContext ->
          PsExpr ->
          List PsElabMatchField ->
          Except PsElabError PsElabMatchFieldsResult :=
        psElabMatchFieldsWorker
          inductiveName
          rest;
      fun (context : PsElabContext) =>
        fun (cursor : PsExpr) =>
          fun (fieldsRev : List PsElabMatchField) =>
            match psInferEnsureForall
                context.environment
                context.metaContext
                context.localContext
                cursor with
            | Except.error error =>
                Except.error (PsElabError.infer error)
            | Except.ok forallView =>
                match psSyntaxNameToName binderSyntax with
                | none => Except.error PsElabError.emptyName
                | some binderName =>
                    let pushed :=
                      psLocalPushBinding
                        context.localContext
                        binderName
                        forallView.domain
                        forallView.binder;
                    let nextContext :=
                      psElabContextWithLocal context pushed.context;
                    let field : PsElabMatchField := {
                      id := pushed.id
                      name := binderName
                      type := forallView.domain
                      binder := forallView.binder
                    };
                    smaller
                      nextContext
                      (psExprInstantiate1
                        forallView.body
                        (PsExpr.fvar pushed.id))
                      (List.cons field fieldsRev)

def psElabMatchFields
    (context : PsElabContext)
    (inductiveName : PsName)
    (cursor : PsExpr)
    (binderSyntaxes : List PsSyntaxName)
    (fieldsRev : List PsElabMatchField) :
    Except PsElabError PsElabMatchFieldsResult :=
  psElabMatchFieldsWorker
    inductiveName
    binderSyntaxes
    context
    cursor
    fieldsRev

def psElabMatchFieldAtWorker
    (index : Nat) :
    List PsElabMatchField -> Option PsElabMatchField :=
  match index with
  | 0 =>
      fun (fields : List PsElabMatchField) =>
        match fields with
        | [] =>
            Option.none
        | field :: _rest =>
            Option.some field
  | nextIndex + 1 =>
      fun (fields : List PsElabMatchField) =>
        let smaller :
            List PsElabMatchField -> Option PsElabMatchField :=
          psElabMatchFieldAtWorker nextIndex;
        match fields with
        | [] =>
            Option.none
        | _field :: rest =>
            smaller rest

def psElabMatchFieldAt
    (fields : List PsElabMatchField)
    (index : Nat) : Option PsElabMatchField :=
  psElabMatchFieldAtWorker index fields

structure PsElabMatchHypothesesResult where
  context : PsElabContext
  hypothesesRev : List PsElabMatchField

def psElabPushRecursiveHypothesesWorker
    (expectedType : PsExpr)
    (fields : List PsElabMatchField)
    (fieldIndices : List Nat) :
    PsElabContext ->
    List PsElabMatchField ->
    Except PsElabError PsElabMatchHypothesesResult :=
  match fieldIndices with
  | [] =>
      fun (context : PsElabContext) =>
        fun (hypothesesRev : List PsElabMatchField) =>
          Except.ok {
            context := context
            hypothesesRev := hypothesesRev
          }
  | fieldIndex :: rest =>
      let smaller :
          PsElabContext ->
          List PsElabMatchField ->
          Except PsElabError PsElabMatchHypothesesResult :=
        psElabPushRecursiveHypothesesWorker
          expectedType
          fields
          rest;
      fun (context : PsElabContext) =>
        fun (hypothesesRev : List PsElabMatchField) =>
          match psElabMatchFieldAt fields fieldIndex with
          | none => Except.error PsElabError.structuralRecursionInternal
          | some field =>
              let hypothesisName :=
                psNameAppendNum
                  (psRootName "_ih")
                  fieldIndex;
              let pushed :=
                psLocalPushBinding
                  context.localContext
                  hypothesisName
                  expectedType
                  PsBinderInfo.explicit;
              let withLocal :=
                psElabContextWithLocal
                  context
                  pushed.context;
              let withRecursion : PsElabContext :=
                match context.structuralRecursion with
                | none =>
                    withLocal
                | some recursion =>
                    let nextRecursion : PsElabStructuralRecursion := {
                      functionName := recursion.functionName
                      parameterIds := recursion.parameterIds
                      explicitParameterIds := recursion.explicitParameterIds
                      recursiveParameterIndex := recursion.recursiveParameterIndex
                      calls :=
                        if recursion.collectCalls then
                          List.cons (Prod.mk field.id pushed.id) recursion.calls
                        else recursion.calls
                      resultType := recursion.resultType
                      collectCalls := recursion.collectCalls
                    };
                    psElabContextWithStructuralRecursion
                      withLocal
                      (Option.some nextRecursion);
              let hypothesis : PsElabMatchField := {
                id := pushed.id
                name := hypothesisName
                type := expectedType
                binder := PsBinderInfo.explicit
              };
              smaller
                withRecursion
                (List.cons hypothesis hypothesesRev)

def psElabPushRecursiveHypotheses
    (expectedType : PsExpr)
    (fields : List PsElabMatchField)
    (fieldIndices : List Nat)
    (context : PsElabContext)
    (hypothesesRev : List PsElabMatchField) :
    Except PsElabError PsElabMatchHypothesesResult :=
  psElabPushRecursiveHypothesesWorker
    expectedType
    fields
    fieldIndices
    context
    hypothesesRev

def psCloseElabMatchFieldsWorker
    (metaContext : PsMetaContext)
    (fields : List PsElabMatchField) :
    PsExpr -> PsExpr :=
  match fields with
  | [] =>
      fun (term : PsExpr) =>
        term
  | field :: rest =>
      let smaller : PsExpr -> PsExpr :=
        psCloseElabMatchFieldsWorker metaContext rest;
      fun (term : PsExpr) =>
        let closed :=
          PsExpr.lam
            field.name
            (psMetaInstantiate metaContext field.type)
            (psExprAbstractFVar field.id term)
            field.binder;
        smaller closed

def psCloseElabMatchFields
    (metaContext : PsMetaContext)
    (fields : List PsElabMatchField)
    (term : PsExpr) : PsExpr :=
  psCloseElabMatchFieldsWorker
    metaContext
    fields
    term

structure PsElabMatchMinorResult where
  context : PsElabContext
  term : PsExpr

def psElabWildcardBinderNamesWorker
    (span : PsSourceSpan)
    (remaining : Nat) :
    Nat -> List PsSyntaxName :=
  match remaining with
  | 0 =>
      fun (_index : Nat) =>
        []
  | nextRemaining + 1 =>
      fun (index : Nat) =>
        let smaller : Nat -> List PsSyntaxName :=
          psElabWildcardBinderNamesWorker
            span
            nextRemaining;
        let segment :=
          String.Internal.append "_wild" (psNatToString index);
        let syntaxName : PsSyntaxName := {
          segments := List.cons segment List.nil
          span := span
        };
        List.cons
          syntaxName
          (smaller (Nat.succ index))

def psElabWildcardBinderNames
    (span : PsSourceSpan)
    (index : Nat)
    (remaining : Nat) :
    List PsSyntaxName :=
  psElabWildcardBinderNamesWorker
    span
    remaining
    index

def psElabMatchFieldListReverseWorker
    (fields : List PsElabMatchField) :
    List PsElabMatchField -> List PsElabMatchField :=
  match fields with
  | [] =>
      fun (acc : List PsElabMatchField) =>
        acc
  | field :: rest =>
      let smaller :
          List PsElabMatchField -> List PsElabMatchField :=
        psElabMatchFieldListReverseWorker rest;
      fun (acc : List PsElabMatchField) =>
        smaller (List.cons field acc)

def psElabMatchFieldListReverse
    (fields : List PsElabMatchField) :
    List PsElabMatchField :=
  psElabMatchFieldListReverseWorker fields []
def psElabMatchConstructorMinor
    (elaborate :
      PsElabContext ->
      PsSyntaxTerm ->
      Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (context : PsElabContext)
    (inductiveInfo : PsInductiveInfo)
    (inductiveLevels : List PsLevel)
    (parameterArgs : List PsExpr)
    (expectedType : PsExpr)
    (constructorName : PsName)
    (body : PsSyntaxTerm)
    (span : PsSourceSpan)
    (sourceBinders : Option (List PsSyntaxName)) :
    Except PsElabError PsElabMatchMinorResult :=
  match psEnvironmentFindConstructor
      context.environment
      constructorName with
  | none =>
      Except.error
        (PsElabError.matchConstructorUnknown constructorName)
  | some ctorInfo =>
      let binders : List PsSyntaxName :=
        match sourceBinders with
        | some values => values
        | none =>
            psElabWildcardBinderNames
              span
              0
              ctorInfo.numFields;
      if psElabBoolNot (psNameEq ctorInfo.inductiveName inductiveInfo.name) then
        Except.error
          (PsElabError.matchConstructorUnknown constructorName)
      else if psElabNatNe ctorInfo.numParams (psElabListLength parameterArgs) then
        Except.error PsElabError.matchParameterArity
      else if psElabNatNe ctorInfo.numFields (psElabListLength binders) then
        Except.error
          (PsElabError.matchConstructorArity constructorName)
      else if psSyntaxNameListHasDuplicate binders then
        Except.error
          (PsElabError.matchConstructorArity constructorName)
      else if psElabNatNe (psElabListLength ctorInfo.levelParams) (psElabListLength inductiveLevels) then
        Except.error PsElabError.matchRecursorLevels
      else
        let ctorType :=
          psExprInstantiateLevelParams
            ctorInfo.levelParams
            inductiveLevels
            ctorInfo.type;
        match psElabMatchApplyParameters
            context
            parameterArgs
            ctorType with
        | Except.error error => Except.error error
        | Except.ok fieldCursor =>
            match psElabMatchFields
                context
                inductiveInfo.name
                fieldCursor
                binders
                [] with
            | Except.error error => Except.error error
            | Except.ok fieldResult =>
                let fields :=
                  psElabMatchFieldListReverse fieldResult.fieldsRev;
                match
                    psElabPushRecursiveHypotheses
                      expectedType
                      fields
                      ctorInfo.recursiveFields
                      fieldResult.context
                      [] with
                | Except.error error => Except.error error
                | Except.ok hypotheses =>
                    match elaborate
                        (psElabContextAfterStructuralFields hypotheses.context)
                        body
                        (Option.some expectedType) with
                    | Except.error error => Except.error error
                    | Except.ok bodyResult =>
                        let metaContext := bodyResult.context.metaContext;
                        let withHypotheses :=
                          psCloseElabMatchFields
                            metaContext
                            hypotheses.hypothesesRev
                            (psMetaInstantiate
                              metaContext
                              bodyResult.term);
                        let closed :=
                          psCloseElabMatchFields
                            metaContext
                            fieldResult.fieldsRev
                            withHypotheses;
                        Except.ok {
                          context :=
                            psElabLeaveScope context bodyResult.context
                          term := closed
                        }

def psElabMatchMinor
    (elaborate :
      PsElabContext ->
      PsSyntaxTerm ->
      Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (context : PsElabContext)
    (inductiveInfo : PsInductiveInfo)
    (inductiveLevels : List PsLevel)
    (parameterArgs : List PsExpr)
    (expectedType : PsExpr)
    (alternative : PsElabMatchAlternative) :
    Except PsElabError PsElabMatchMinorResult :=
  match alternative.pattern with
  | .bool _ _ =>
      match elaborate context alternative.body (Option.some expectedType) with
      | Except.error error => Except.error error
      | Except.ok bodyResult =>
          Except.ok {
            context := bodyResult.context
            term := bodyResult.term
          }
  | .wildcard span =>
      psElabMatchConstructorMinor
        elaborate
        context
        inductiveInfo
        inductiveLevels
        parameterArgs
        expectedType
        alternative.constructorName
        alternative.body
        span
        Option.none
  | .constructor _ binders span =>
      psElabMatchConstructorMinor
        elaborate
        context
        inductiveInfo
        inductiveLevels
        parameterArgs
        expectedType
        alternative.constructorName
        alternative.body
        span
        (Option.some binders)

structure PsElabMatchMinorsResult where
  context : PsElabContext
  minors : List PsExpr

def psElabMatchMinorsWorker
    (elaborate :
      PsElabContext ->
      PsSyntaxTerm ->
      Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (inductiveInfo : PsInductiveInfo)
    (inductiveLevels : List PsLevel)
    (parameterArgs : List PsExpr)
    (expectedType : PsExpr)
    (alternatives : List PsElabMatchAlternative)
    (constructorNames : List PsName) :
    PsElabContext ->
    Except PsElabError PsElabMatchMinorsResult :=
  match constructorNames with
  | [] =>
      fun (context : PsElabContext) =>
        Except.ok {
          context := context
          minors := []
        }
  | ctorName :: rest =>
      let smaller :
          PsElabContext ->
          Except PsElabError PsElabMatchMinorsResult :=
        psElabMatchMinorsWorker
          elaborate
          inductiveInfo
          inductiveLevels
          parameterArgs
          expectedType
          alternatives
          rest;
      fun (context : PsElabContext) =>
        match psElabMatchAlternativeFind ctorName alternatives with
        | none => Except.error PsElabError.matchNonExhaustive
        | some alternative =>
            match psElabMatchMinor
                elaborate
                context
                inductiveInfo
                inductiveLevels
                parameterArgs
                expectedType
                alternative with
            | Except.error error => Except.error error
            | Except.ok minor =>
                match smaller minor.context with
                | Except.error error => Except.error error
                | Except.ok tail =>
                    Except.ok {
                      context := tail.context
                      minors := List.cons minor.term tail.minors
                    }

-- Refine only the whole structural match, after every minor has contributed
-- its meta solutions. Reopen exactly the constructor fields, replace the major
-- through the remaining term (including IH lambdas), and close the same IDs.
def psElabRefineStructuralMinor
    (majorId fieldCount : Nat) (context : PsLocalContext)
    (constructorValue minor : PsExpr) : Except PsElabError PsExpr :=
  match fieldCount with
  | Nat.zero =>
      Except.ok (psExprInstantiate1 (psExprAbstractFVar majorId minor) constructorValue)
  | Nat.succ remaining =>
      match minor with
      | PsExpr.lam name domain body binder =>
          let pushed := psLocalPushBinding context name domain binder;
          match psElabRefineStructuralMinor majorId remaining pushed.context
              (PsExpr.app constructorValue (PsExpr.fvar pushed.id))
              (psExprInstantiate1 body (PsExpr.fvar pushed.id)) with
          | Except.error error => Except.error error
          | Except.ok refined =>
              Except.ok (PsExpr.lam name domain
                (psExprAbstractFVar pushed.id refined) binder)
      | _ => Except.error PsElabError.structuralRecursionInternal

def psElabRefineStructuralMinors
    (context : PsElabContext) (majorId : Nat)
    (inductiveLevels : List PsLevel) (parameterArgs : List PsExpr)
    (constructorNames : List PsName) (minors : List PsExpr) :
    Except PsElabError (List PsExpr) :=
  match constructorNames with
  | List.nil =>
      match minors with
      | List.nil => Except.ok List.nil
      | _ => Except.error PsElabError.structuralRecursionInternal
  | List.cons constructorName rest =>
      match minors with
      | List.nil => Except.error PsElabError.structuralRecursionInternal
      | List.cons minor tail =>
          match psEnvironmentFindConstructor context.environment constructorName with
          | Option.none => Except.error PsElabError.structuralRecursionInternal
          | Option.some constructorInfo =>
              let constructorValue := psMetaInstantiate context.metaContext
                (psExprApplyMany (PsExpr.constE constructorName inductiveLevels) parameterArgs);
              match psElabRefineStructuralMinor majorId constructorInfo.numFields
                  context.localContext constructorValue (psMetaInstantiate context.metaContext minor) with
              | Except.error error => Except.error error
              | Except.ok refined =>
                  match psElabRefineStructuralMinors context majorId
                      inductiveLevels parameterArgs rest tail with
                  | Except.error error => Except.error error
                  | Except.ok refinedTail => Except.ok (List.cons refined refinedTail)

def psElabRefineStructuralMatch
    (inductiveLevels : List PsLevel) (parameterArgs : List PsExpr)
    (constructorNames : List PsName) (result : PsElabMatchMinorsResult) :
    Except PsElabError PsElabMatchMinorsResult :=
  match result.context.structuralRecursion with
  | Option.none => Except.ok result
  | Option.some recursion =>
      if recursion.collectCalls then
        match psElabCheckStructuralTelescope result.context recursion with
        -- An actual recursive call refuses these errors before returning its IH.
        -- Nonrecursive dependent/Prop matches retain their constant motive.
        | Except.error _ => Except.ok result
        | Except.ok majorId =>
            match psElabRefineStructuralMinors result.context majorId
                inductiveLevels parameterArgs constructorNames result.minors with
            | Except.error error => Except.error error
            | Except.ok minors =>
                Except.ok (PsElabMatchMinorsResult.mk result.context minors)
      else Except.ok result

def psElabMatchMinors
    (elaborate :
      PsElabContext ->
      PsSyntaxTerm ->
      Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (inductiveInfo : PsInductiveInfo)
    (inductiveLevels : List PsLevel)
    (parameterArgs : List PsExpr)
    (expectedType : PsExpr)
    (alternatives : List PsElabMatchAlternative)
    (context : PsElabContext)
    (constructorNames : List PsName) :
    Except PsElabError PsElabMatchMinorsResult :=
  match psElabMatchMinorsWorker
      elaborate
      inductiveInfo
      inductiveLevels
      parameterArgs
      expectedType
      alternatives
      constructorNames
      context with
  | Except.error error => Except.error error
  | Except.ok result =>
      psElabRefineStructuralMatch inductiveLevels parameterArgs constructorNames result

def psElabExprListAppendWorker
    (values : List PsExpr) :
    List PsExpr -> List PsExpr :=
  match values with
  | [] =>
      fun (right : List PsExpr) =>
        right
  | value :: rest =>
      let smaller : List PsExpr -> List PsExpr :=
        psElabExprListAppendWorker rest;
      fun (right : List PsExpr) =>
        List.cons value (smaller right)

def psElabExprListAppend
    (left : List PsExpr)
    (right : List PsExpr) :
    List PsExpr :=
  psElabExprListAppendWorker left right

-- The declaration's root match has one permission to establish its IH map.
-- Nested matches retain existing root-child identities but cannot create aliases
-- from a different recurrence, even when the result types happen to agree.
def psElabStructuralMatchContext
    (context : PsElabContext) (scrutinee expectedType : PsExpr) : PsElabContext :=
  match context.structuralRecursion with
  | Option.none => context
  | Option.some recursion =>
      let sameResult := psExprAlphaEq
        (psMetaInstantiate context.metaContext expectedType)
        (psMetaInstantiate context.metaContext recursion.resultType);
      let permitted : Bool :=
        if recursion.collectCalls then
          if sameResult then
            match scrutinee with
            | PsExpr.fvar id =>
                match psElabStructuralParameterAt
                    recursion.explicitParameterIds recursion.recursiveParameterIndex with
                | Option.none => false
                | Option.some majorId => Nat.beq id majorId
            | _ => false
          else false
        else false;
      psElabContextWithStructuralRecursion context
        (Option.some (PsElabStructuralRecursion.mk
          recursion.functionName recursion.parameterIds recursion.explicitParameterIds
          recursion.recursiveParameterIndex recursion.calls recursion.resultType permitted))

def psElabMatch
    (elaborate :
      PsElabContext ->
      PsSyntaxTerm ->
      Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (context : PsElabContext)
    (scrutineeSyntax : PsSyntaxTerm)
    (alternativesSyntax :
      List (Prod PsSyntaxPattern (Prod PsSyntaxTerm PsSourceSpan)))
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  match expected with
  | none => Except.error PsElabError.matchExpectedType
  | some expectedType =>
      match elaborate context scrutineeSyntax Option.none with
      | Except.error error => Except.error error
      | Except.ok scrutineeResult =>
          let scrutineeType :=
            psWhnf
              scrutineeResult.context.environment
              scrutineeResult.context.metaContext
              scrutineeResult.context.localContext
              scrutineeResult.type;
          let typeView := psExprAppView scrutineeType;
          match typeView.head with
          | .constE inductiveName inductiveLevels =>
              match psEnvironmentFindInductive
                  scrutineeResult.context.environment
                  inductiveName with
              | none =>
                  Except.error PsElabError.matchScrutineeUnsupported
              | some inductiveInfo =>
                  if psElabNatNe inductiveInfo.numIndices 0 then
                    Except.error PsElabError.matchInductiveUnsupported
                  else if psElabNatNe (psElabListLength typeView.args) inductiveInfo.numParams then
                    Except.error PsElabError.matchParameterArity
                  else
                    match psElabPrepareMatchAlternatives
                        inductiveInfo
                        alternativesSyntax
                        [] with
                    | Except.error error => Except.error error
                    | Except.ok alternatives =>
                        let recursorName :=
                          psNameAppendStr inductiveInfo.name "rec";
                        match psEnvironmentFindRecursor
                            scrutineeResult.context.environment
                            recursorName with
                        | none =>
                            Except.error PsElabError.matchRecursorUnsupported
                        | some recInfo =>
                            if
                                psElabBoolOr
                                  (psElabNatNe
                                    recInfo.numParams
                                    inductiveInfo.numParams)
                                  (psElabBoolOr
                                    (psElabNatNe recInfo.numIndices 0)
                                    (psElabBoolOr
                                      (psElabNatNe recInfo.numMotives 1)
                                      (psElabNatNe
                                        recInfo.numMinors
                                        (psElabListLength inductiveInfo.constructors)))) then
                              Except.error
                                PsElabError.matchRecursorUnsupported
                            else
                              let instantiatedExpected :=
                                psMetaInstantiate
                                  scrutineeResult.context.metaContext
                                  expectedType;
                              match psInferType
                                  scrutineeResult.context.environment
                                  scrutineeResult.context.metaContext
                                  scrutineeResult.context.localContext
                                  instantiatedExpected with
                              | Except.error error =>
                                  Except.error (PsElabError.infer error)
                              | Except.ok expectedTypeType =>
                                  match psInferEnsureSort
                                      scrutineeResult.context.environment
                                      scrutineeResult.context.metaContext
                                      scrutineeResult.context.localContext
                                      expectedTypeType with
                                  | Except.error error =>
                                      Except.error (PsElabError.infer error)
                                  | Except.ok resultLevel =>
                                      let recursorLevels :=
                                        if Nat.beq (psElabListLength recInfo.levelParams) 0 then
                                          []
                                        else if Nat.beq (psElabListLength recInfo.levelParams) 1 then
                                          [resultLevel]
                                        else
                                          [];
                                      if Nat.blt 1 (psElabListLength recInfo.levelParams) then
                                        Except.error
                                          PsElabError.matchRecursorLevels
                                      else
                                        match psElabMatchMinors
                                            elaborate
                                            inductiveInfo
                                            inductiveLevels
                                            typeView.args
                                            instantiatedExpected
                                            alternatives
                                            (psElabStructuralMatchContext
                                              scrutineeResult.context
                                              scrutineeResult.term
                                              instantiatedExpected)
                                            inductiveInfo.constructors with
                                        | Except.error error =>
                                            Except.error error
                                        | Except.ok minors =>
                                            let motive :=
                                              PsExpr.lam
                                                (psRootName "_match")
                                                scrutineeType
                                                instantiatedExpected
                                                PsBinderInfo.explicit;
                                            let recursorTail :=
                                              psElabExprListAppend
                                                minors.minors
                                                (List.cons
                                                  scrutineeResult.term
                                                  List.nil);
                                            let recursorArgs :=
                                              psElabExprListAppend
                                                typeView.args
                                                (List.cons
                                                  motive
                                                  recursorTail);
                                            let recursorTerm :=
                                              psExprApplyMany
                                                (PsExpr.constE
                                                  recursorName
                                                  recursorLevels)
                                                recursorArgs;
                                            psElabResolvedTerm
                                              minors.context
                                              recursorTerm
                                              (Option.some instantiatedExpected)
          | _ =>
              Except.error PsElabError.matchScrutineeUnsupported

structure PsElabRecordCandidate where
  constructorName : PsName
  fieldNames : List String

def psElabDropForallBindersWorker
    (remaining : Nat) :
    PsExpr -> Option PsExpr :=
  match remaining with
  | 0 =>
      fun (type : PsExpr) =>
        Option.some type
  | nextRemaining + 1 =>
      fun (type : PsExpr) =>
        let smaller : PsExpr -> Option PsExpr :=
          psElabDropForallBindersWorker nextRemaining;
        match type with
        | .forallE _ _ body _ =>
            smaller body
        | _ => Option.none

def psElabDropForallBinders
    (remaining : Nat)
    (type : PsExpr) : Option PsExpr :=
  psElabDropForallBindersWorker
    remaining
    type

def psElabTakeForallNamesWorker
    (remaining : Nat) :
    PsExpr -> Option (List String) :=
  match remaining with
  | 0 =>
      fun (_type : PsExpr) =>
        Option.some []
  | nextRemaining + 1 =>
      fun (type : PsExpr) =>
        let smaller : PsExpr -> Option (List String) :=
          psElabTakeForallNamesWorker nextRemaining;
        match type with
        | .forallE name _ body _ =>
            match smaller body with
            | none => Option.none
            | some rest =>
                Option.some
                  (List.cons (psNameLastComponent name) rest)
        | _ => Option.none

def psElabTakeForallNames
    (remaining : Nat)
    (type : PsExpr) : Option (List String) :=
  psElabTakeForallNamesWorker
    remaining
    type

def psSyntaxRecordLastSegment
    (segments : List String) : Option String :=
  match segments with
  | [] =>
      Option.none
  | first :: rest =>
      match rest with
      | [] =>
          Option.some first
      | _ :: _ =>
          psSyntaxRecordLastSegment rest

def psSyntaxRecordFieldName
    (field : Prod PsSyntaxName PsSyntaxTerm) :
    Option String :=
  let syntaxName := Prod.fst field;
  psSyntaxRecordLastSegment syntaxName.segments

def psSyntaxRecordFieldMatchesName
    (name : String)
    (field : Prod PsSyntaxName PsSyntaxTerm) : Bool :=
  match psSyntaxRecordFieldName field with
  | none => false
  | some fieldName => psStringEq fieldName name

def psSyntaxRecordHasField
    (fields :
      List (Prod PsSyntaxName PsSyntaxTerm))
    (name : String) : Bool :=
  match fields with
  | [] =>
      false
  | field :: rest =>
      if psSyntaxRecordFieldMatchesName name field then
        true
      else
        psSyntaxRecordHasField rest name

def psSyntaxRecordHasNamedField
    (fields : List (Prod PsSyntaxName PsSyntaxTerm))
    (name : String) : Bool :=
  psSyntaxRecordHasField fields name

def psSyntaxRecordFieldsMatchWorker
    (names : List String) :
    List (Prod PsSyntaxName PsSyntaxTerm) -> Bool :=
  match names with
  | [] =>
      fun (_fields : List (Prod PsSyntaxName PsSyntaxTerm)) =>
        true
  | name :: rest =>
      let smaller :
          List (Prod PsSyntaxName PsSyntaxTerm) -> Bool :=
        psSyntaxRecordFieldsMatchWorker rest;
      fun (fields : List (Prod PsSyntaxName PsSyntaxTerm)) =>
        if psSyntaxRecordHasNamedField fields name then
          smaller fields
        else
          false

def psSyntaxRecordFieldsMatch
    (fields :
      List (Prod PsSyntaxName PsSyntaxTerm))
    (names : List String) : Bool :=
  psElabBoolAnd
    (Nat.beq (psElabListLength fields) (psElabListLength names))
    (psSyntaxRecordFieldsMatchWorker names fields)

def psSyntaxRecordFindField
    (fields : List (Prod PsSyntaxName PsSyntaxTerm))
    (name : String) :
    Option PsSyntaxTerm :=
  match fields with
  | [] =>
      Option.none
  | field :: rest =>
      match psSyntaxRecordFieldName field with
      | Option.some fieldName =>
          if psStringEq fieldName name then
            Option.some (Prod.snd field)
          else
            psSyntaxRecordFindField rest name
      | Option.none =>
          psSyntaxRecordFindField rest name

def psSyntaxRecordOrderFields
    (fields : List (Prod PsSyntaxName PsSyntaxTerm))
    (names : List String) :
    Option (List PsSyntaxTerm) :=
  match names with
  | [] =>
      Option.some []
  | name :: rest =>
      match psSyntaxRecordFindField fields name with
      | Option.none =>
          Option.none
      | Option.some value =>
          match psSyntaxRecordOrderFields fields rest with
          | Option.none =>
              Option.none
          | Option.some values =>
              Option.some (List.cons value values)

def psElabRecordCandidateForInfo
    (environment : PsEnvironment)
    (info : PsInductiveInfo) :
    Option PsElabRecordCandidate :=
  if info.isStructure then
    match info.constructors with
    | [] =>
        Option.none
    | constructorName :: rest =>
        match rest with
        | [] =>
            match
                psEnvironmentFindConstructor
                  environment
                  constructorName with
            | Option.none => Option.none
            | Option.some constructorInfo =>
                match
                    psElabDropForallBinders
                      constructorInfo.numParams
                      constructorInfo.type with
                | Option.none => Option.none
                | Option.some fieldsType =>
                    match
                        psElabTakeForallNames
                          constructorInfo.numFields
                          fieldsType with
                    | Option.none => Option.none
                    | Option.some fieldNames =>
                        Option.some {
                          constructorName := constructorName
                          fieldNames := fieldNames
                        }
        | _ :: _ =>
            Option.none
  else
    Option.none

def psElabRecordCandidateFromExpected
    (context : PsElabContext)
    (expected : PsExpr) :
    Option PsElabRecordCandidate :=
  let reduced :=
    psWhnf
      context.environment
      context.metaContext
      context.localContext
      expected;
  let view := psInferAppView reduced;
  match view.head with
  | .constE typeName _ =>
      match
          psEnvironmentFindInductive
            context.environment
            typeName with
      | Option.none => Option.none
      | Option.some info =>
          if psElabNatNe (psElabListLength view.args) info.numParams then
            Option.none
          else
            psElabRecordCandidateForInfo
              context.environment
              info
  | _ => Option.none

def psElabRecordCandidates
    (environment : PsEnvironment)
    (fields : List (Prod PsSyntaxName PsSyntaxTerm))
    (declarations : List PsDeclaration)
    (candidatesRev : List PsElabRecordCandidate) :
    List PsElabRecordCandidate :=
  match declarations with
  | [] =>
      candidatesRev
  | declaration :: rest =>
      let candidates :=
        psElabRecordCandidates
          environment
          fields
          rest
          candidatesRev;
      match declaration with
      | .inductiveDecl info =>
          match
              psElabRecordCandidateForInfo
                environment
                info with
          | some candidate =>
              if
                  psSyntaxRecordFieldsMatch
                    fields
                    candidate.fieldNames then
                List.cons candidate candidates
              else
                candidates
          | none =>
              candidates
      | _ =>
          candidates

def psElabUniqueRecordCandidate
    (environment : PsEnvironment)
    (fields :
      List (Prod PsSyntaxName PsSyntaxTerm)) :
    Option PsElabRecordCandidate :=
  match
      psElabRecordCandidates
        environment
        fields
        environment.declarations
        [] with
  | [] =>
      Option.none
  | candidate :: rest =>
      match rest with
      | [] => Option.some candidate
      | _ :: _ => Option.none

def psElabRecord
    (elaborate :
      PsElabContext ->
      PsSyntaxTerm ->
      Option PsExpr ->
      Except PsElabError PsElabTermResult)
    (context : PsElabContext)
    (fields :
      List (Prod PsSyntaxName PsSyntaxTerm))
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  let candidate : Option PsElabRecordCandidate :=
    match expected with
    | some expectedType =>
        match
            psElabRecordCandidateFromExpected
              context
              expectedType with
        | some found =>
            if
                psSyntaxRecordFieldsMatch
                  fields
                  found.fieldNames then
              Option.some found
            else
              Option.none
        | none =>
            psElabUniqueRecordCandidate
              context.environment
              fields
    | none =>
        psElabUniqueRecordCandidate
          context.environment
          fields;
  match candidate with
  | none => Except.error PsElabError.unsupportedTerm
  | some found =>
      match
          psSyntaxRecordOrderFields
            fields
            found.fieldNames with
      | none => Except.error PsElabError.unsupportedTerm
      | some arguments =>
          match
              psElabResolvedTerm
                context
                (PsExpr.constE
                  found.constructorName
                  [])
                Option.none with
          | Except.error error => Except.error error
          | Except.ok constructor =>
              match
                  psElabApplyArgs
                    elaborate
                    constructor
                    arguments
                    [] with
              | Except.error error => Except.error error
              | Except.ok application =>
                  psElabFinishApplication
                    application
                    expected

def psElabSyntaxLocalId
    (context : PsElabContext) :
    PsSyntaxTerm -> Option Nat
  | .reference sourceName =>
      match psSyntaxNameToName sourceName with
      | Option.none => Option.none
      | Option.some name =>
          match
              psResolveName
                context.localContext
                context.environment
                name with
          | Option.none => Option.none
          | Option.some resolved =>
              match resolved with
              | .local id => Option.some id
              | .global _ => Option.none
  | _ => Option.none

def psElabNatListAtWorker
    (index : Nat) :
    List Nat -> Option Nat :=
  match index with
  | 0 =>
      fun (values : List Nat) =>
        match values with
        | [] =>
            Option.none
        | value :: _ =>
            Option.some value
  | nextIndex + 1 =>
      fun (values : List Nat) =>
        let smaller :
            List Nat -> Option Nat :=
          psElabNatListAtWorker nextIndex;
        match values with
        | [] =>
            Option.none
        | _ :: rest =>
            smaller rest

def psElabNatListAt
    (values : List Nat)
    (index : Nat) : Option Nat :=
  psElabNatListAtWorker
    index
    values
def psElabValidateStructuralCallWorker
    (arguments : List PsSyntaxTerm) :
    PsElabContext ->
    PsElabStructuralRecursion ->
    Nat ->
    Option Nat ->
    Except PsElabError Nat :=
  match arguments with
  | [] =>
      fun (context : PsElabContext) =>
        fun (recursion : PsElabStructuralRecursion) =>
          fun (index : Nat) =>
            fun (hypothesisId : Option Nat) =>
              match hypothesisId with
              | Option.some resolvedHypothesisId =>
                  Except.ok resolvedHypothesisId
              | Option.none =>
                  Except.error PsElabError.structuralRecursionInternal
  | argument :: rest =>
      let smaller :
          PsElabContext ->
          PsElabStructuralRecursion ->
          Nat ->
          Option Nat ->
          Except PsElabError Nat :=
        psElabValidateStructuralCallWorker rest;
      fun (context : PsElabContext) =>
        fun (recursion : PsElabStructuralRecursion) =>
          fun (index : Nat) =>
            fun (hypothesisId : Option Nat) =>
              match psElabSyntaxLocalId context argument with
              | Option.none =>
                  if Nat.beq index recursion.recursiveParameterIndex then
                    Except.error PsElabError.structuralRecursionNotDecreasing
                  else
                    Except.error PsElabError.structuralRecursionInvariantArgument
              | Option.some argumentId =>
                  if Nat.beq index recursion.recursiveParameterIndex then
                    match
                        psElabStructuralRecursionFindCall
                          recursion.calls
                          argumentId with
                    | Option.none =>
                        Except.error PsElabError.structuralRecursionNotDecreasing
                    | Option.some nextHypothesisId =>
                        smaller
                          context
                          recursion
                          (Nat.succ index)
                          (Option.some nextHypothesisId)
                  else
                    match
                        psElabNatListAt
                          recursion.explicitParameterIds
                          index with
                    | Option.none =>
                        Except.error PsElabError.structuralRecursionArity
                    | Option.some originalId =>
                        if Nat.beq argumentId originalId then
                          smaller
                            context
                            recursion
                            (Nat.succ index)
                            hypothesisId
                        else
                          Except.error
                            PsElabError.structuralRecursionInvariantArgument

def psElabValidateStructuralCall
    (context : PsElabContext)
    (recursion : PsElabStructuralRecursion)
    (index : Nat)
    (arguments : List PsSyntaxTerm)
    (hypothesisId : Option Nat) :
    Except PsElabError Nat :=
  psElabValidateStructuralCallWorker
    arguments
    context
    recursion
    index
    hypothesisId
def psElabStructuralNameIsLocal (context : PsElabContext) (name : PsName) : Bool :=
  match psLocalFindUser context.localContext name with
  | Option.none => false
  | Option.some _ => true

def psTryElabStructuralSelfCall
    (context : PsElabContext)
    (fn : PsSyntaxTerm)
    (arguments : List PsSyntaxTerm)
    (expected : Option PsExpr) :
    Except PsElabError (Option PsElabTermResult) :=
  match context.structuralRecursion with
  | Option.none =>
      Except.ok Option.none
  | Option.some recursion =>
      match fn with
      | .reference sourceName =>
          match psSyntaxNameToName sourceName with
          | Option.some calledName =>
              if psElabBoolNot (psNameEq calledName recursion.functionName) then
                Except.ok Option.none
              else if psElabStructuralNameIsLocal context calledName then
                Except.ok Option.none
              else if
                  psElabNatNe
                    (psElabListLength arguments)
                    (psElabListLength recursion.explicitParameterIds) then
                Except.error PsElabError.structuralRecursionArity
              else
                match
                    psElabValidateStructuralCall
                      context
                      recursion
                      0
                      arguments
                      Option.none with
                | Except.error error => Except.error error
                | Except.ok hypothesisId =>
                    match psElabCheckStructuralTelescope context recursion with
                    | Except.error error => Except.error error
                    | Except.ok _ =>
                        match
                            psElabResolvedTerm
                              context
                              (PsExpr.fvar hypothesisId)
                              expected with
                        | Except.error error => Except.error error
                        | Except.ok result => Except.ok (Option.some result)
          | Option.none => Except.ok Option.none
      | _ =>
          Except.ok Option.none

def psElabStructuralReferenceEscapes
    (context : PsElabContext) (sourceName : PsSyntaxName) : Bool :=
  match context.structuralRecursion with
  | Option.none => false
  | Option.some recursion =>
      match psSyntaxNameToName sourceName with
      | Option.none => false
      | Option.some name =>
          if psNameEq name recursion.functionName then
            match psLocalFindUser context.localContext name with
            | Option.none => true
            | Option.some _ => false
          else false

def psElabTermWithFuel
    (fuel : Nat) :
    PsElabContext ->
    PsSyntaxTerm ->
    Option PsExpr ->
    Except PsElabError PsElabTermResult :=
  match fuel with
  | 0 =>
      fun (_context : PsElabContext) =>
        fun (_term : PsSyntaxTerm) =>
          fun (_expected : Option PsExpr) =>
            Except.error PsElabError.fuelExhausted
  | remaining + 1 =>
      fun (context : PsElabContext) =>
        fun (term : PsSyntaxTerm) =>
          fun (expected : Option PsExpr) =>
            let smaller :
                PsElabContext ->
                PsSyntaxTerm ->
                Option PsExpr ->
                Except PsElabError PsElabTermResult :=
              psElabTermWithFuel remaining;
            let readHead : PsElaborator := fun ctx source target =>
              match source with
              | .reference name =>
                  if psElabStructuralReferenceEscapes ctx name then
                    Except.error PsElabError.structuralRecursionEscapingReference
                  else psElabReference ctx name target
              | _ => smaller ctx source target
            match term with
            | .hole _ => Except.ok (psElabHole context expected)
            | .optionalType _ _ _ => Except.error PsElabError.unsupportedTerm
            | .ascription value type _ => psElabAscription smaller context value type expected
            | .call fn args span =>
                if args.all (fun arg => arg.fst.isNone) && !args.isEmpty then
                  -- Reuse the structural-call path for positional applications.
                  smaller context (.app fn (args.map Prod.snd) span) expected
                else
                  match readHead context fn none with
                  | .error error => .error error
                  | .ok head => psElabCall smaller head args expected
            | .reference name =>
                if psElabStructuralReferenceEscapes context name then
                  Except.error PsElabError.structuralRecursionEscapingReference
                else
                  match psElabReference context name Option.none with
                  | Except.error error => Except.error error
                  | Except.ok reference =>
                      match psElabApplyArgs
                          smaller
                          reference
                          []
                          [] expected with
                      | Except.error error => Except.error error
                      | Except.ok application =>
                          psElabFinishApplication application expected
            | .natural text _ =>
                psElabNatural context text expected
            | .string text _ =>
                psElabString context text expected
            | .character text _ =>
                psElabCharacter context text expected
            | .unit _ =>
                psElabUnit context expected
            | .record fields _ =>
                psElabRecord
                  smaller
                  context
                  fields
                  expected
            | .bool value _ =>
                psElabBool context value expected
            | .lambda binders body _ =>
                psElabLambda
                  smaller
                  context
                  binders
                  body
                  expected
            | .forallE binders body _ =>
                psElabForall
                  smaller
                  context
                  binders
                  body
                  expected
            | .letE name declaredType value body _ =>
                psElabLet
                  smaller
                  context
                  name
                  declaredType
                  value
                  body
                  expected
            | .ifE condition thenBranch elseBranch _ =>
                psElabIf
                  smaller
                  context
                  condition
                  thenBranch
                  elseBranch
                  expected
            | .matchE scrutinee alternatives _ =>
                psElabMatch
                  smaller
                  context
                  scrutinee
                  alternatives
                  expected
            | .app fn args _ =>
                -- An adjacent empty call has its own completion path above.
                match args with
                | List.nil => Except.error PsElabError.emptyCallUnsupported
                | List.cons _ _ =>
                    match
                        psTryElabStructuralSelfCall
                          context
                          fn
                          args
                          expected with
                    | Except.error error => Except.error error
                    | Except.ok selfCall =>
                        match selfCall with
                        | Option.some result => Except.ok result
                        | Option.none =>
                            match readHead context fn Option.none with
                            | Except.error error => Except.error error
                            | Except.ok elaboratedFn =>
                                match psElabApplyArgs
                                    smaller
                                    elaboratedFn
                                    args
                                    [] expected with
                                | Except.error error => Except.error error
                                | Except.ok application =>
                                    psElabFinishApplication application expected

def psElabTerm
    (context : PsElabContext)
    (term : PsSyntaxTerm)
    (expected : Option PsExpr) :
    Except PsElabError PsElabTermResult :=
  psElabTermWithFuel 4096 context term expected
