import Ps.Elab.DoLoopLift
import Ps.Environment.Control

-- Specialize finite Nat iteration before admission. Helpers remain total
-- Nat.rec definitions; erased theorems require official conversion equality.
def psElabDoForLiftName (owner : PsName) (index : Nat) : PsName :=
  PsName.num (PsName.str owner "_psc1ForBody") index

def psElabDoForIsLiftedName (name : PsName) : Bool :=
  match name with
  | PsName.num parent _ =>
      match parent with
      | PsName.str _ segment => psStringEq segment "_psc1ForBody"
      | _ => false
  | PsName.str parent segment =>
      psStringEq segment "_psc1ForEquivalence" && psElabDoForIsLiftedName parent
  | _ => false

def psElabDoForLiftEta (fuel : Nat) (environment : PsEnvironment)
    (locals : PsLocalContext) (type value : PsExpr) :
    Except PsElabError PsExpr :=
  match fuel with
  | Nat.zero => Except.error PsElabError.fuelExhausted
  | Nat.succ remaining =>
      match psWhnf environment psMetaEmpty locals type with
      | PsExpr.forallE name domain body binder =>
          let pushed := psLocalPushBinding locals name domain binder;
          let id := pushed.id;
          match psElabDoForLiftEta remaining environment pushed.context
              (psExprInstantiate1 body (PsExpr.fvar id))
              (PsExpr.app value (PsExpr.fvar id)) with
          | Except.error error => Except.error error
          | Except.ok nested =>
              Except.ok (PsExpr.lam name domain (psExprAbstractFVar id nested) binder)
      | _ => Except.ok value

def psElabDoForLiftMinor (step index rest : PsExpr) (placeholder : PsName) :
    Except PsElabError PsExpr :=
  match step with
  | PsExpr.lam _ _ first _ =>
      match psExprInstantiate1 first index with
      | PsExpr.lam _ _ second _ =>
          match psElabDoLoopNormalize 4096 placeholder (psExprInstantiate1 second rest) with
          | Except.error error => Except.error error
          | Except.ok body => Except.ok body
      | _ => Except.error PsElabError.unsupportedTerm
  | _ => Except.error PsElabError.unsupportedTerm

def psElabDoForSpecialize
    (owner : PsName) (ownerType : PsExpr) (locals : PsLocalContext)
    (work : PsElabDoLoopLiftState) (resultType base step count : PsExpr) :
    Except PsElabError PsElabDoLoopLiftResult :=
  let name := psElabDoForLiftName owner work.nextIndex;
  let placeholder := PsName.str name "_psc1Induction";
  let capturesRev := psElabDoLoopCaptures [resultType, base, step] locals.declarations;
  let captures := psListReverse capturesRev;
  let captureArguments := psElabDoLoopCaptureArguments captures;
  let natType := PsExpr.constE psNatName [];
  let countId := locals.nextId;
  let indexId := Nat.succ countId;
  let restId := Nat.succ indexId;
  let sourceId := Nat.succ restId;
  let predicateId := Nat.succ sourceId;
  let witnessId := Nat.succ predicateId;
  let countName := psRootName "_psc1ForCount";
  let bindersRev := List.cons (Prod.mk countId (Prod.mk countName natType))
    (psElabDoLoopCaptureBinders capturesRev);
  let closedType := psElabDoLoopCloseType bindersRev resultType;
  let captureSource := psElabDoLoopOccurs owner closedType || psElabDoLoopOccurs owner step ||
    psElabDoLoopOccurs owner base;
  let sourceName := psRootName "_psc1SourceFunction";
  let closeSourceType : PsExpr -> PsExpr := fun (term : PsExpr) =>
    if captureSource then
      PsExpr.forallE sourceName ownerType
        (psExprAbstractFVar sourceId (psElabDoLoopReplaceOwner owner (PsExpr.fvar sourceId) term))
        PsBinderInfo.explicit
    else term;
  let closeSourceValue : PsExpr -> PsExpr := fun (term : PsExpr) =>
    if captureSource then
      PsExpr.lam sourceName ownerType
        (psExprAbstractFVar sourceId (psElabDoLoopReplaceOwner owner (PsExpr.fvar sourceId) term))
        PsBinderInfo.explicit
    else term;
  let helperType := closeSourceType closedType;
  let sourceArguments := if captureSource then [PsExpr.constE owner []] else [];
  let prefix := psListAppend sourceArguments captureArguments;
  let withCount := psLocalPushBinding locals countName natType PsBinderInfo.explicit;
  let withIndex := psLocalPushBinding withCount.context (psRootName "_psc1ForIndex") natType PsBinderInfo.explicit;
  let withRest := psLocalPushBinding withIndex.context (psRootName "_psc1ForRest") resultType PsBinderInfo.explicit;
  match psElabDoForLiftEta 64 work.environment withRest.context resultType base with
  | Except.error error => Except.error error
  | Except.ok etaBase =>
      let deferred := PsExpr.lam (psRootName "_unit") (PsExpr.constE psUnitName [])
        (PsExpr.constE placeholder []) PsBinderInfo.explicit;
      match psElabDoForLiftMinor step (PsExpr.fvar indexId) deferred placeholder with
      | Except.error error => Except.error error
      | Except.ok body =>
          let body := psElabDoLoopReplaceOwner placeholder (PsExpr.fvar restId) body;
          let minor := PsExpr.lam (psRootName "_psc1ForIndex") natType
            (psExprAbstractFVar indexId
              (PsExpr.lam (psRootName "_psc1ForRest") resultType
                (psExprAbstractFVar restId body) PsBinderInfo.explicit))
            PsBinderInfo.explicit;
          let motive := PsExpr.lam (psRootName "_major") natType
            (psExprLiftBVars 1 0 resultType) PsBinderInfo.explicit;
          let value := psExprApplyMany (PsExpr.constE psNatRecName [PsLevel.succ PsLevel.zero])
            [motive, etaBase, minor, PsExpr.fvar countId];
          let helperValue := closeSourceValue (psElabDoLoopCloseValue bindersRev value);
          let declaration := PsDeclaration.definitionDecl name [] helperType helperValue;
          match psEnvironmentAddOwnedBootstrapDeclaration work.environment declaration with
          | Option.none => Except.error (PsElabError.duplicateDeclaration name)
          | Option.some environment =>
              match psElabDoLoopCheck environment psLocalEmpty helperValue helperType with
              | Except.error error => Except.error error
              | Except.ok _ =>
                  let original := psExprApplyMany (PsExpr.constE psControlLazyNatFoldName [])
                    [resultType, base, step, PsExpr.fvar countId];
                  let replacement := psExprApplyMany (PsExpr.constE name [])
                    (psListAppend prefix [PsExpr.fvar countId]);
                  let predicateType := PsExpr.forallE (psRootName "_value") resultType
                    (PsExpr.sortE PsLevel.zero) PsBinderInfo.explicit;
                  let proofBinders := psListAppend
                    [Prod.mk witnessId (Prod.mk (psRootName "_h")
                      (PsExpr.app (PsExpr.fvar predicateId) original)),
                      Prod.mk predicateId (Prod.mk (psRootName "_P") predicateType)]
                    bindersRev;
                  let proofType := closeSourceType (psElabDoLoopCloseType proofBinders
                    (PsExpr.app (PsExpr.fvar predicateId) replacement));
                  let proofValue := closeSourceValue (psElabDoLoopCloseValue proofBinders (PsExpr.fvar witnessId));
                  let proof := PsDeclaration.theoremDecl (PsName.str name "_psc1ForEquivalence") [] proofType proofValue;
                  let call := psExprApplyMany (PsExpr.constE name []) (psListAppend prefix [count]);
                  match psElabDoLoopCheck environment locals call resultType with
                  | Except.error error => Except.error error
                  | Except.ok _ =>
                      let state := PsElabDoLoopLiftState.mk environment
                        (List.cons proof (List.cons declaration work.declarationsRev)) (Nat.succ work.nextIndex);
                      Except.ok (PsElabDoLoopLiftResult.mk call state)

structure PsElabDoForLiftCall where
  resultType : PsExpr
  base : PsExpr
  step : PsExpr
  count : PsExpr

def psElabDoForLiftApplication (term : PsExpr) : Option PsElabDoForLiftCall :=
  let view := psExprAppView term;
  match view.head with
  | PsExpr.constE name levels =>
      if psNameEq name psControlLazyNatFoldName && psListIsEmpty levels then
        match view.args with
        | List.nil => Option.none
        | List.cons resultType a =>
            match a with
            | List.nil => Option.none
            | List.cons base b =>
                match b with
                | List.nil => Option.none
                | List.cons step c =>
                    match c with
                    | List.nil => Option.none
                    | List.cons count rest =>
                        match rest with
                        | List.nil => Option.some (PsElabDoForLiftCall.mk resultType base step count)
                        | _ => Option.none
      else Option.none
  | _ => Option.none

def psElabDoForLiftExprWorker
    (fuel : Nat) (owner : PsName) (ownerType : PsExpr) :
    PsLocalContext -> PsElabDoLoopLiftState -> PsExpr ->
    Except PsElabError PsElabDoLoopLiftResult :=
  match fuel with
  | 0 =>
      fun (locals : PsLocalContext) (work : PsElabDoLoopLiftState) (term : PsExpr) =>
        if psElabDoLoopOccurs psControlLazyNatFoldName term then Except.error PsElabError.fuelExhausted
        else Except.ok (PsElabDoLoopLiftResult.mk term work)
  | remaining + 1 =>
      fun (locals : PsLocalContext) (work : PsElabDoLoopLiftState) (term : PsExpr) =>
        if !psElabDoLoopOccurs psControlLazyNatFoldName term then Except.ok (PsElabDoLoopLiftResult.mk term work)
        else
          let smaller : PsLocalContext -> PsElabDoLoopLiftState -> PsExpr ->
              Except PsElabError PsElabDoLoopLiftResult :=
            psElabDoForLiftExprWorker remaining owner ownerType;
          match term with
          | PsExpr.app fn argument =>
              match psElabDoForLiftApplication term with
              | Option.some call =>
                  match smaller locals work call.base with
                  | Except.error error => Except.error error
                  | Except.ok base =>
                      match smaller locals base.state call.step with
                      | Except.error error => Except.error error
                      | Except.ok step =>
                          match smaller locals step.state call.count with
                          | Except.error error => Except.error error
                          | Except.ok count =>
                              psElabDoForSpecialize owner ownerType locals count.state
                                call.resultType base.term step.term count.term
              | Option.none =>
                  match smaller locals work fn with
                  | Except.error error => Except.error error
                  | Except.ok fn =>
                      match smaller locals fn.state argument with
                      | Except.error error => Except.error error
                      | Except.ok argument =>
                          Except.ok (PsElabDoLoopLiftResult.mk
                            (PsExpr.app fn.term argument.term) argument.state)
          | PsExpr.lam name type body binder =>
              if psElabDoLoopOccurs psControlLazyNatFoldName type then Except.error PsElabError.doWhileUnsupportedBody
              else
                let pushed := psLocalPushBinding locals name type binder;
                match smaller pushed.context work
                    (psExprInstantiate1 body (PsExpr.fvar pushed.id)) with
                | Except.error error => Except.error error
                | Except.ok body =>
                    Except.ok (PsElabDoLoopLiftResult.mk
                      (PsExpr.lam name type (psExprAbstractFVar pushed.id body.term) binder) body.state)
          | PsExpr.letE name type value body =>
              if psElabDoLoopOccurs psControlLazyNatFoldName type then Except.error PsElabError.doWhileUnsupportedBody
              else
                match smaller locals work value with
                | Except.error error => Except.error error
                | Except.ok value =>
                    let pushed := psLocalPushLet locals name type value.term;
                    match smaller pushed.context value.state
                        (psExprInstantiate1 body (PsExpr.fvar pushed.id)) with
                    | Except.error error => Except.error error
                    | Except.ok body =>
                        Except.ok (PsElabDoLoopLiftResult.mk
                          (PsExpr.letE name type value.term
                            (psExprAbstractFVar pushed.id body.term)) body.state)
          | PsExpr.proj name index value =>
              match smaller locals work value with
              | Except.error error => Except.error error
              | Except.ok value =>
                  Except.ok (PsElabDoLoopLiftResult.mk
                    (PsExpr.proj name index value.term) value.state)
          | _ => Except.error PsElabError.doWhileUnsupportedBody


def psElabDoForLiftDeclaration
    (environment : PsEnvironment) (declaration : PsDeclaration) :
    Except PsElabError (List PsDeclaration) :=
  let owner := psDeclarationName declaration;
  let type := psDeclarationType declaration;
  match psDeclarationValue declaration with
  | Option.none => Except.ok [declaration]
  | Option.some value =>
      if !psElabDoLoopOccurs psControlLazyNatFoldName value then Except.ok [declaration]
      else
        let levels := psDeclarationLevelParams declaration;
        if !psListIsEmpty levels then Except.ok [declaration]
        else
          match psElabDoLoopAddHeader environment owner type with
          | Except.error error => Except.error error
          | Except.ok environment =>
              let work := PsElabDoLoopLiftState.mk environment [] 0;
              match psElabDoForLiftExprWorker 4096 owner type psLocalEmpty work value with
              | Except.error error => Except.error error
              | Except.ok lifted =>
                  let result := match declaration with
                    | PsDeclaration.definitionDecl name levels type _ =>
                        PsDeclaration.definitionDecl name levels type lifted.term
                    | PsDeclaration.partialDecl name levels type _ =>
                        PsDeclaration.partialDecl name levels type lifted.term
                    | PsDeclaration.theoremDecl name levels type _ =>
                        PsDeclaration.theoremDecl name levels type lifted.term
                    | _ => declaration;
                  Except.ok (psListAppend (psListReverse lifted.state.declarationsRev) [result])

def psElabDoForLiftInsert
    (declarations : List PsDeclaration) (environment : PsEnvironment) :
    Except PsElabError PsEnvironment :=
  match declarations with
  | List.nil => Except.ok environment
  | List.cons declaration rest =>
      match psEnvironmentAddOwnedBootstrapDeclaration environment declaration with
      | Option.none => Except.error (PsElabError.duplicateDeclaration (psDeclarationName declaration))
      | Option.some next => psElabDoForLiftInsert rest next

def psElabDoForLiftDeclarations
    (environment : PsEnvironment) (declarations : List PsDeclaration) :
    Except PsElabError (List PsDeclaration) :=
  match declarations with
  | List.nil => Except.ok []
  | List.cons declaration rest =>
      match psElabDoForLiftDeclaration environment declaration with
      | Except.error error => Except.error error
      | Except.ok lifted =>
          match psElabDoForLiftInsert lifted environment with
          | Except.error error => Except.error error
          | Except.ok next =>
              match psElabDoForLiftDeclarations next rest with
              | Except.error error => Except.error error
              | Except.ok tail => Except.ok (psListAppend lifted tail)
