import Ps.Elab.DoLoop
import Ps.Environment.SelfHostPrelude
import Ps.Foundation.List

-- Convert the temporary generic marker before ordinary admission.
def psElabDoLoopLiftName (owner : PsName) (index : Nat) : PsName :=
  PsName.num (PsName.str owner "_psc1WhileBody") index

def psElabDoLoopIsLiftedName (owner : PsName) (name : PsName) : Bool :=
  match name with
  | PsName.num parent _ =>
      match parent with
      | PsName.str root segment =>
          psNameEq root owner && psStringEq segment "_psc1WhileBody"
      | _ => false
  | _ => false

def psElabDoLoopHasFVar (target : Nat) (term : PsExpr) : Bool :=
  match term with
  | PsExpr.fvar id => Nat.beq id target
  | PsExpr.app fn arg => psElabDoLoopHasFVar target fn || psElabDoLoopHasFVar target arg
  | PsExpr.lam _ type body _ => psElabDoLoopHasFVar target type || psElabDoLoopHasFVar target body
  | PsExpr.forallE _ type body _ => psElabDoLoopHasFVar target type || psElabDoLoopHasFVar target body
  | PsExpr.letE _ type value body =>
      psElabDoLoopHasFVar target type || psElabDoLoopHasFVar target value ||
        psElabDoLoopHasFVar target body
  | PsExpr.proj _ _ value => psElabDoLoopHasFVar target value
  | _ => false

def psElabDoLoopNeedsLocal (id : Nat) (values : List PsExpr) : Bool :=
  match values with
  | List.nil => false
  | List.cons value rest => psElabDoLoopHasFVar id value || psElabDoLoopNeedsLocal id rest

-- Newest-first traversal closes dependencies without changing telescope order.
def psElabDoLoopCapturesWorker (declarations : List PsLocalDecl) :
    List PsExpr -> List PsLocalDecl :=
  match declarations with
  | List.nil => fun (roots : List PsExpr) => List.nil
  | List.cons declaration rest =>
      let smaller : List PsExpr -> List PsLocalDecl := psElabDoLoopCapturesWorker rest;
      fun (roots : List PsExpr) =>
        if psElabDoLoopNeedsLocal (psLocalDeclId declaration) roots then
          List.cons declaration (smaller (List.cons (psLocalDeclType declaration) roots))
        else smaller roots

def psElabDoLoopCaptures (roots : List PsExpr) (declarations : List PsLocalDecl) :
    List PsLocalDecl :=
  psElabDoLoopCapturesWorker declarations roots

def psElabDoLoopCaptureBinders (declarations : List PsLocalDecl) :
    List (Prod Nat (Prod PsName PsExpr)) :=
  match declarations with
  | List.nil => List.nil
  | List.cons declaration rest =>
      List.cons (Prod.mk (psLocalDeclId declaration)
        (Prod.mk (psLocalDeclUserName declaration) (psLocalDeclType declaration)))
        (psElabDoLoopCaptureBinders rest)

def psElabDoLoopCaptureArguments (declarations : List PsLocalDecl) : List PsExpr :=
  match declarations with
  | List.nil => List.nil
  | List.cons declaration rest =>
      List.cons (PsExpr.fvar (psLocalDeclId declaration)) (psElabDoLoopCaptureArguments rest)

def psElabDoLoopReplaceOwner (owner : PsName) (replacement : PsExpr) (term : PsExpr) : PsExpr :=
  match term with
  | PsExpr.constE name levels =>
      if psNameEq name owner then replacement else PsExpr.constE name levels
  | PsExpr.app fn arg =>
      PsExpr.app (psElabDoLoopReplaceOwner owner replacement fn)
        (psElabDoLoopReplaceOwner owner replacement arg)
  | PsExpr.lam name type body binder =>
      PsExpr.lam name (psElabDoLoopReplaceOwner owner replacement type)
        (psElabDoLoopReplaceOwner owner replacement body) binder
  | PsExpr.forallE name type body binder =>
      PsExpr.forallE name (psElabDoLoopReplaceOwner owner replacement type)
        (psElabDoLoopReplaceOwner owner replacement body) binder
  | PsExpr.letE name type value body =>
      PsExpr.letE name (psElabDoLoopReplaceOwner owner replacement type)
        (psElabDoLoopReplaceOwner owner replacement value)
        (psElabDoLoopReplaceOwner owner replacement body)
  | PsExpr.proj name index value =>
      PsExpr.proj name index (psElabDoLoopReplaceOwner owner replacement value)
  | _ => term

def psElabDoLoopBetaValue (term : PsExpr) : Bool :=
  match term with
  | PsExpr.fvar _ => true
  | PsExpr.bvar _ => true
  | PsExpr.lam _ _ _ _ => true
  | PsExpr.sortE _ => true
  | PsExpr.lit _ => true
  | PsExpr.constE name levels =>
      match levels with
      | List.nil =>
          psNameEq name psUnitUnitName || psNameEq name psBoolTrueName ||
            psNameEq name psBoolFalseName
      | _ => false
  | _ => false

-- A nonvalue lambda argument remains under a strict Core let.
def psElabDoLoopNormalizeWorker (fuel : Nat) (helper : PsName) :
    PsExpr -> Except PsElabError PsExpr :=
  match fuel with
  | 0 =>
      fun (term : PsExpr) =>
        if psElabDoLoopOccurs helper term then Except.error PsElabError.fuelExhausted
        else Except.ok term
  | remaining + 1 =>
      fun (term : PsExpr) =>
        if !psElabDoLoopOccurs helper term then Except.ok term
        else
          let smaller : PsExpr -> Except PsElabError PsExpr :=
            psElabDoLoopNormalizeWorker remaining helper;
          match term with
          | PsExpr.app fn arg =>
              match smaller fn with
              | Except.error error => Except.error error
              | Except.ok fn =>
                  match smaller arg with
                  | Except.error error => Except.error error
                  | Except.ok arg =>
                      match fn with
                      | PsExpr.lam name domain body _ =>
                          if psElabDoLoopBetaValue arg then smaller (psExprInstantiate1 body arg)
                          else smaller (PsExpr.letE name domain arg body)
                      | PsExpr.letE name type value body =>
                          smaller (PsExpr.letE name type value
                            (PsExpr.app body (psExprLiftBVars 1 0 arg)))
                      | _ => Except.ok (PsExpr.app fn arg)
          | PsExpr.letE name type value body =>
              if psElabDoLoopOccurs helper type then Except.error PsElabError.doWhileUnsupportedBody
              else
                match smaller value with
                | Except.error error => Except.error error
                | Except.ok value =>
                    let inlineValue : Bool :=
                      match value with
                      | PsExpr.lam _ _ _ _ => psElabDoLoopOccurs helper value
                      | _ => false;
                    if inlineValue then smaller (psExprInstantiate1 body value)
                    else
                      match smaller body with
                      | Except.error error => Except.error error
                      | Except.ok body => Except.ok (PsExpr.letE name type value body)
          | PsExpr.lam name type body binder =>
              if psElabDoLoopOccurs helper type then Except.error PsElabError.doWhileUnsupportedBody
              else
                match smaller body with
                | Except.error error => Except.error error
                | Except.ok body => Except.ok (PsExpr.lam name type body binder)
          | PsExpr.proj name index value =>
              match smaller value with
              | Except.error error => Except.error error
              | Except.ok value => Except.ok (PsExpr.proj name index value)
          | PsExpr.forallE _ _ _ _ => Except.error PsElabError.doWhileUnsupportedBody
          | _ => Except.ok term

def psElabDoLoopNormalize (fuel : Nat) (helper : PsName) (term : PsExpr) :
    Except PsElabError PsExpr :=
  psElabDoLoopNormalizeWorker fuel helper term

def psElabDoLoopCleanArguments (helper : PsName) (arguments : List PsExpr) : Bool :=
  match arguments with
  | List.nil => true
  | List.cons argument rest =>
      !psElabDoLoopOccurs helper argument && psElabDoLoopCleanArguments helper rest

def psElabDoLoopFiveArguments (arguments : List PsExpr)
    (next : PsExpr -> PsExpr -> PsExpr -> PsExpr -> PsExpr -> Bool) : Bool :=
  match arguments with
  | List.nil => false
  | List.cons a rest =>
      match rest with
      | List.nil => false
      | List.cons b tail =>
          match tail with
          | List.nil => false
          | List.cons c more =>
              match more with
              | List.nil => false
              | List.cons d final =>
                  match final with
                  | List.nil => false
                  | List.cons e extra =>
                      match extra with
                      | List.nil => next a b c d e
                      | _ => false

def psElabDoLoopSixArguments (arguments : List PsExpr)
    (next : PsExpr -> PsExpr -> PsExpr -> PsExpr -> PsExpr -> PsExpr -> Bool) : Bool :=
  match arguments with
  | List.nil => false
  | List.cons a rest =>
      psElabDoLoopFiveArguments rest
        (fun (b : PsExpr) (c : PsExpr) (d : PsExpr) (e : PsExpr) (f : PsExpr) =>
          next a b c d e f)

def psElabDoLoopTailValidWorker (fuel : Nat) (helper : PsName) (arity : Nat) :
    PsExpr -> Bool :=
  match fuel with
  | 0 => fun (term : PsExpr) => !psElabDoLoopOccurs helper term
  | remaining + 1 =>
      fun (term : PsExpr) =>
        if !psElabDoLoopOccurs helper term then true
        else
          let smaller : PsExpr -> Bool := psElabDoLoopTailValidWorker remaining helper arity;
          match term with
          | PsExpr.letE _ type value body =>
              !psElabDoLoopOccurs helper type &&
                !psElabDoLoopOccurs helper value && smaller body
          | PsExpr.app _ _ =>
              let view := psExprAppView term;
              match view.head with
              | PsExpr.constE name _ =>
                  if psNameEq name helper then
                    Nat.beq (psListLength view.args) arity &&
                      psElabDoLoopCleanArguments helper view.args
                  else if psNameEq name psIteName then
                    psElabDoLoopFiveArguments view.args
                      (fun (type : PsExpr) (proposition : PsExpr) (decision : PsExpr)
                          (yes : PsExpr) (no : PsExpr) =>
                        psElabDoLoopCleanArguments helper [type, proposition, decision] &&
                          smaller yes && smaller no)
                  else if psNameEq name psSelfHostExceptRecName then
                    psElabDoLoopSixArguments view.args
                      (fun (error : PsExpr) (value : PsExpr) (motive : PsExpr)
                          (failure : PsExpr) (success : PsExpr) (action : PsExpr) =>
                        let branch : PsExpr -> Bool :=
                          fun (minor : PsExpr) =>
                            if !psElabDoLoopOccurs helper minor then true
                            else
                              match minor with
                              | PsExpr.lam _ type body _ =>
                                  !psElabDoLoopOccurs helper type && smaller body
                              | _ => false;
                        psElabDoLoopCleanArguments helper [error, value, motive, action] &&
                          branch failure && branch success)
                  else false
              | _ => false
          | _ => false

def psElabDoLoopTailValid (fuel : Nat) (helper : PsName) (arity : Nat)
    (term : PsExpr) : Bool :=
  psElabDoLoopTailValidWorker fuel helper arity term

structure PsElabDoLoopLiftState where
  environment : PsEnvironment
  declarationsRev : List PsDeclaration
  nextIndex : Nat

structure PsElabDoLoopLiftResult where
  term : PsExpr
  state : PsElabDoLoopLiftState

def psElabDoLoopAddHeader (environment : PsEnvironment) (name : PsName)
    (type : PsExpr) : Except PsElabError PsEnvironment :=
  match psEnvironmentAdd environment (PsDeclaration.axiomDecl name [] type) with
  | Option.none => Except.error (PsElabError.duplicateDeclaration name)
  | Option.some result => Except.ok result

def psElabDoLoopCheck (environment : PsEnvironment) (locals : PsLocalContext)
    (term type : PsExpr) : Except PsElabError Unit :=
  let context := psElabContextWithLocal (psElabContextEmpty environment) locals;
  match psElabResolvedTerm context term (Option.some type) with
  | Except.error error => Except.error error
  | Except.ok checked => Except.ok Unit.unit

def psElabDoLoopApplyStep (step recurrence state unit : PsExpr) :
    Except PsElabError PsExpr :=
  match step with
  | PsExpr.lam _ _ first _ =>
      match psExprInstantiate1 first recurrence with
      | PsExpr.lam _ _ second _ =>
          match psExprInstantiate1 second state with
          | PsExpr.lam _ _ third _ => Except.ok (psExprInstantiate1 third unit)
          | _ => Except.error PsElabError.doWhileUnsupportedBody
      | _ => Except.error PsElabError.doWhileUnsupportedBody
  | _ => Except.error PsElabError.doWhileUnsupportedBody

def psElabDoLoopSpecialize
    (owner : PsName) (ownerType : PsExpr) (marker : PsName)
    (locals : PsLocalContext) (work : PsElabDoLoopLiftState)
    (stateType resultType fallback step initial unit : PsExpr) :
    Except PsElabError PsElabDoLoopLiftResult :=
  if psElabDoLoopOccurs marker step then Except.error PsElabError.doWhileUnsupportedBody
  else
    let name := psElabDoLoopLiftName owner work.nextIndex;
    let capturesRev := psElabDoLoopCaptures [stateType, resultType, step] locals.declarations;
    let captureArguments := psElabDoLoopCaptureArguments (psListReverse capturesRev);
    let unitType := PsExpr.constE psUnitName [];
    let thunkType := psElabDoLoopArrow unitType resultType;
    let fallbackId := locals.nextId;
    let stateId := fallbackId + 1;
    let unitId := stateId + 1;
    let nextId := unitId + 1;
    let sourceId := nextId + 1;
    let sourceName := psRootName "_psc1SourceFunction";
    let bindersRev : List (Prod Nat (Prod PsName PsExpr)) :=
      psListAppend
        [Prod.mk unitId (Prod.mk (psRootName "_psc1WhileUnit") unitType),
          Prod.mk stateId (Prod.mk (psRootName "_psc1WhileState") stateType),
          Prod.mk fallbackId (Prod.mk (psRootName "_psc1WhileFallback") thunkType)]
        (psElabDoLoopCaptureBinders capturesRev);
    let closedType := psElabDoLoopCloseType bindersRev resultType;
    let captureSource : Bool := psElabDoLoopOccurs owner closedType || psElabDoLoopOccurs owner step;
    let helperType : PsExpr :=
      if captureSource then
        PsExpr.forallE sourceName ownerType
          (psExprAbstractFVar sourceId
            (psElabDoLoopReplaceOwner owner (PsExpr.fvar sourceId) closedType))
          PsBinderInfo.explicit
      else closedType;
    let sourceArguments : List PsExpr := if captureSource then [PsExpr.constE owner []] else [];
    let argumentsPrefix : List PsExpr := psListAppend sourceArguments captureArguments;
    match psElabDoLoopAddHeader work.environment name helperType with
    | Except.error error => Except.error error
    | Except.ok environment =>
        let recursiveCall := psExprApplyMany (PsExpr.constE name [])
          (psListAppend argumentsPrefix [PsExpr.fvar fallbackId, PsExpr.fvar nextId]);
        let recurrence := PsExpr.lam (psRootName "_psc1WhileNextState") stateType
          (psExprAbstractFVar nextId recursiveCall) PsBinderInfo.explicit;
        match psElabDoLoopApplyStep step recurrence (PsExpr.fvar stateId) (PsExpr.fvar unitId) with
        | Except.error error => Except.error error
        | Except.ok openBody =>
            match psElabDoLoopNormalize 4096 name openBody with
            | Except.error error => Except.error error
            | Except.ok openBody =>
                let sourceArity : Nat := if captureSource then 1 else 0;
                let arity := psListLength capturesRev + 3 + sourceArity;
                if !psElabDoLoopTailValid 4096 name arity openBody then
                  Except.error PsElabError.doWhileUnsupportedBody
                else
                  let closedValue := psElabDoLoopCloseValue bindersRev openBody;
                  let helperValue : PsExpr :=
                    if captureSource then
                      PsExpr.lam sourceName ownerType
                        (psExprAbstractFVar sourceId
                          (psElabDoLoopReplaceOwner owner (PsExpr.fvar sourceId) closedValue))
                        PsBinderInfo.explicit
                    else closedValue;
                  if psElabDoLoopOccurs owner helperType || psElabDoLoopOccurs owner helperValue then
                    Except.error PsElabError.doWhileUnsupportedBody
                  else
                    match psElabDoLoopCheck environment psLocalEmpty helperValue helperType with
                    | Except.error error => Except.error error
                    | Except.ok checkedHelper =>
                        let call := psExprApplyMany (PsExpr.constE name [])
                          (psListAppend argumentsPrefix [fallback, initial, unit]);
                        match psElabDoLoopCheck environment locals call resultType with
                        | Except.error error => Except.error error
                        | Except.ok checkedCall =>
                            let declaration := PsDeclaration.partialDecl name [] helperType helperValue;
                            let state := PsElabDoLoopLiftState.mk environment
                              (List.cons declaration work.declarationsRev) (work.nextIndex + 1);
                            Except.ok (PsElabDoLoopLiftResult.mk call state)

structure PsElabDoLoopMarkerCall where
  stateType : PsExpr
  resultType : PsExpr
  fallback : PsExpr
  step : PsExpr
  initial : PsExpr
  unit : PsExpr

def psElabDoLoopMarkerArguments (arguments : List PsExpr) : Option PsElabDoLoopMarkerCall :=
  match arguments with
  | List.nil => Option.none
  | List.cons stateType a =>
      match a with
      | List.nil => Option.none
      | List.cons resultType b =>
          match b with
          | List.nil => Option.none
          | List.cons fallback c =>
              match c with
              | List.nil => Option.none
              | List.cons step d =>
                  match d with
                  | List.nil => Option.none
                  | List.cons initial e =>
                      match e with
                      | List.nil => Option.none
                      | List.cons unit final =>
                          match final with
                          | List.nil =>
                              Option.some (PsElabDoLoopMarkerCall.mk
                                stateType resultType fallback step initial unit)
                          | _ => Option.none

def psElabDoLoopMarkerApplication (marker : PsName) (term : PsExpr) :
    Option PsElabDoLoopMarkerCall :=
  let view := psExprAppView term;
  match view.head with
  | PsExpr.constE name levels =>
      match levels with
      | List.nil =>
          if psNameEq name marker then psElabDoLoopMarkerArguments view.args
          else Option.none
      | _ => Option.none
  | _ => Option.none

-- Lift generic marker applications in the original strict traversal order.
def psElabDoLoopLiftExprWorker
    (fuel : Nat) (owner : PsName) (ownerType : PsExpr) (marker : PsName) :
    PsLocalContext -> PsElabDoLoopLiftState -> PsExpr ->
    Except PsElabError PsElabDoLoopLiftResult :=
  match fuel with
  | 0 =>
      fun (locals : PsLocalContext) (work : PsElabDoLoopLiftState) (term : PsExpr) =>
        if psElabDoLoopOccurs marker term then Except.error PsElabError.fuelExhausted
        else Except.ok (PsElabDoLoopLiftResult.mk term work)
  | remaining + 1 =>
      fun (locals : PsLocalContext) (work : PsElabDoLoopLiftState) (term : PsExpr) =>
        if !psElabDoLoopOccurs marker term then Except.ok (PsElabDoLoopLiftResult.mk term work)
        else
          let smaller : PsLocalContext -> PsElabDoLoopLiftState -> PsExpr ->
              Except PsElabError PsElabDoLoopLiftResult :=
            psElabDoLoopLiftExprWorker remaining owner ownerType marker;
          match term with
          | PsExpr.app fn argument =>
              match psElabDoLoopMarkerApplication marker term with
              | Option.some call =>
                  if psElabDoLoopOccurs marker call.stateType ||
                      psElabDoLoopOccurs marker call.resultType then
                    Except.error PsElabError.doWhileUnsupportedBody
                  else
                    match smaller locals work call.fallback with
                    | Except.error error => Except.error error
                    | Except.ok fallback =>
                        match smaller locals fallback.state call.step with
                        | Except.error error => Except.error error
                        | Except.ok step =>
                            match smaller locals step.state call.initial with
                            | Except.error error => Except.error error
                            | Except.ok initial =>
                                match smaller locals initial.state call.unit with
                                | Except.error error => Except.error error
                                | Except.ok unit =>
                                    psElabDoLoopSpecialize owner ownerType marker locals unit.state
                                      call.stateType call.resultType fallback.term step.term initial.term unit.term
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
              if psElabDoLoopOccurs marker type then Except.error PsElabError.doWhileUnsupportedBody
              else
                let pushed := psLocalPushBinding locals name type binder;
                match smaller pushed.context work
                    (psExprInstantiate1 body (PsExpr.fvar pushed.id)) with
                | Except.error error => Except.error error
                | Except.ok body =>
                    Except.ok (PsElabDoLoopLiftResult.mk
                      (PsExpr.lam name type (psExprAbstractFVar pushed.id body.term) binder) body.state)
          | PsExpr.letE name type value body =>
              if psElabDoLoopOccurs marker type then Except.error PsElabError.doWhileUnsupportedBody
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

def psElabDoLoopLiftExpr
    (fuel : Nat) (owner : PsName) (ownerType : PsExpr) (marker : PsName)
    (locals : PsLocalContext) (work : PsElabDoLoopLiftState) (term : PsExpr) :
    Except PsElabError PsElabDoLoopLiftResult :=
  psElabDoLoopLiftExprWorker fuel owner ownerType marker locals work term

def psElabDoLoopLiftDeclaration
    (environment : PsEnvironment) (owner : PsName) (levels : List PsName)
    (type value : PsExpr) : Except PsElabError (List PsDeclaration) :=
  let marker := psElabDoLoopName owner;
  if !psElabDoLoopOccurs marker value then Except.ok [PsDeclaration.partialDecl owner levels type value]
  else
    match levels with
    | List.nil =>
        if psElabDoLoopOccurs marker type then Except.error PsElabError.doWhileUnsupportedBody
        else
          match psElabDoLoopAddHeader environment owner type with
          | Except.error error => Except.error error
          | Except.ok environment =>
              match psElabDoLoopAddHeader environment marker psElabDoLoopType with
              | Except.error error => Except.error error
              | Except.ok environment =>
                  let work := PsElabDoLoopLiftState.mk environment [] 0;
                  match psElabDoLoopLiftExpr 4096 owner type marker psLocalEmpty work value with
                  | Except.error error => Except.error error
                  | Except.ok lifted =>
                      if psElabDoLoopOccurs marker lifted.term then
                        Except.error PsElabError.doWhileUnsupportedBody
                      else
                        match psElabDoLoopCheck lifted.state.environment psLocalEmpty lifted.term type with
                        | Except.error error => Except.error error
                        | Except.ok checked =>
                            Except.ok (psListAppend (psListReverse lifted.state.declarationsRev)
                              [PsDeclaration.partialDecl owner levels type lifted.term])
    | _ => Except.error PsElabError.doWhileUnsupportedBody
