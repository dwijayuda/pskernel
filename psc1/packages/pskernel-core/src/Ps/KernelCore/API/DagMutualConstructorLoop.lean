import Ps.KernelCore.API.DagMutualConstructorAnalysis
import Ps.KernelCore.API.DagOrdinaryConstructorLoop

/- Private mutual constructor installation. Unlike the ordinary constructor
   loop, the retained mutual worker recurses structurally on constructor/type
   lists and keeps checker fuel unchanged. Empty lists succeed at fuel zero.

   input is the existing validated original boundary table. Its roots must
   belong to the immutable input prefix of the current owning arena; forged
   decoded records are not certificates. Metadata uses original boundary types
   only after complete DAG constructor analysis. Every extension remains in a
   private work environment. No recursor or public admission is returned. -/
structure PsKernelExprV2MutualConstructorsResult where
  context : PsKernelExprV2CheckContext
  state : PsKernelExprV2CheckState
  shapes : List PsKernelExprV2MutualConstructorShape

def psKernelExprV2MutualConstructorShapeAppend
    (left : List PsKernelExprV2MutualConstructorShape) :
    List PsKernelExprV2MutualConstructorShape -> List PsKernelExprV2MutualConstructorShape :=
  match left with
  | List.nil => fun (right : List PsKernelExprV2MutualConstructorShape) => right
  | List.cons first rest =>
      let smaller := psKernelExprV2MutualConstructorShapeAppend rest;
      fun (right : List PsKernelExprV2MutualConstructorShape) => List.cons first (smaller right)

def psKernelExprV2MutualInstallConstructor
    (input : PsKernelExprV2Decoded) (target : PsKernelName) (numParams index : Nat)
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (ctor : PsKernelDagConstructor) (analyzed : PsKernelExprV2MutualConstructorAnalysis) :
    Except String (Prod PsKernelExprV2CheckContext PsKernelExprV2CheckState) :=
  match psKernelExprV2DecodedRequire input ctor.type with
  | Except.error error => Except.error error
  | Except.ok type =>
      let info := PsKernelConstructorInfo.mk
        (PsKernelConstantBase.mk ctor.name context.scalar.levelParams type)
        target index numParams (psKernelExprV2OrdinaryOpenBinderCount analyzed.shape.fields)
        (psKernelDefinitionSafetyIsUnsafe context.scalar.safety);
      let work := psKernelEnvironmentAddUnchecked context.scalar.environment
        (PsKernelConstantInfo.ctorInfo info);
      let reference := PsKernelExprV2DeclarationRef.mk ctor.name context.scalar.levelParams
        ctor.type Option.none PsKernelExprV2DeclarationRefKind.constructorDecl;
      let nextContext := PsKernelExprV2CheckContext.mk
        (psKernelCheckerContextWithEnvironment context.scalar work) context.locals;
      let nextWhnf := PsKernelExprV2WhnfState.mk analyzed.state.whnf.arena
        state.whnf.coreCache state.whnf.publicCache (List.cons reference state.whnf.declarations);
      Except.ok (Prod.mk nextContext (psKernelExprV2CheckStateWithWhnf state nextWhnf))

def psKernelExprV2MutualAddConstructorsForTypeWorker
    (ctors : List PsKernelDagConstructor) :
    (Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      PsKernelDagConstructor -> Option (Except String PsKernelExprV2MutualConstructorAnalysis)) ->
    Nat -> PsKernelExprV2Decoded -> PsKernelName -> Nat -> Nat ->
    PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
    Option (Except String PsKernelExprV2MutualConstructorsResult) :=
  match ctors with
  | List.nil =>
      fun (_analyze : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          PsKernelDagConstructor -> Option (Except String PsKernelExprV2MutualConstructorAnalysis))
        (_fuel : Nat) (_input : PsKernelExprV2Decoded) (_target : PsKernelName)
        (_owner _numParams : Nat) (context : PsKernelExprV2CheckContext)
        (state : PsKernelExprV2CheckState) (_index : Nat) =>
        Option.some (Except.ok (PsKernelExprV2MutualConstructorsResult.mk context state List.nil))
  | List.cons ctor rest =>
      let smaller := psKernelExprV2MutualAddConstructorsForTypeWorker rest;
      fun (analyze : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          PsKernelDagConstructor -> Option (Except String PsKernelExprV2MutualConstructorAnalysis))
        (fuel : Nat) (input : PsKernelExprV2Decoded) (target : PsKernelName)
        (owner numParams : Nat) (context : PsKernelExprV2CheckContext)
        (state : PsKernelExprV2CheckState) (index : Nat) =>
        match analyze fuel context state owner ctor with
        | Option.none => Option.none
        | Option.some attempted =>
            match attempted with
            | Except.error error => Option.some (Except.error error)
            | Except.ok analyzed =>
                match psKernelExprV2MutualInstallConstructor
                    input target numParams index context state ctor analyzed with
                | Except.error error => Option.some (Except.error error)
                | Except.ok installed =>
                    match smaller analyze fuel input target owner numParams
                        (Prod.fst installed) (Prod.snd installed) (Nat.succ index) with
                    | Option.none => Option.none
                    | Option.some attemptedTail =>
                        match attemptedTail with
                        | Except.error error => Option.some (Except.error error)
                        | Except.ok tail => Option.some (Except.ok
                            (PsKernelExprV2MutualConstructorsResult.mk tail.context tail.state
                              (List.cons analyzed.shape tail.shapes)))

def psKernelExprV2MutualAddTypesWorker
    (types : List PsKernelExprV2MutualTypeHeader) :
    (Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      PsKernelDagConstructor -> Option (Except String PsKernelExprV2MutualConstructorAnalysis)) ->
    Nat -> PsKernelExprV2Decoded -> Nat -> PsKernelExprV2CheckContext ->
    PsKernelExprV2CheckState -> Nat -> Option (Except String PsKernelExprV2MutualConstructorsResult) :=
  match types with
  | List.nil =>
      fun (_analyze : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          PsKernelDagConstructor -> Option (Except String PsKernelExprV2MutualConstructorAnalysis))
        (_fuel : Nat) (_input : PsKernelExprV2Decoded) (_numParams : Nat)
        (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState) (_owner : Nat) =>
        Option.some (Except.ok (PsKernelExprV2MutualConstructorsResult.mk context state List.nil))
  | List.cons first rest =>
      let smaller := psKernelExprV2MutualAddTypesWorker rest;
      fun (analyze : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
          PsKernelDagConstructor -> Option (Except String PsKernelExprV2MutualConstructorAnalysis))
        (fuel : Nat) (input : PsKernelExprV2Decoded) (numParams : Nat)
        (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState) (owner : Nat) =>
        let own := psKernelExprV2MutualAddConstructorsForTypeWorker first.declaration.ctors;
        match own analyze fuel input first.declaration.name owner numParams context state 0 with
        | Option.none => Option.none
        | Option.some attempted =>
            match attempted with
            | Except.error error => Option.some (Except.error error)
            | Except.ok ownResult =>
                match smaller analyze fuel input numParams ownResult.context ownResult.state (Nat.succ owner) with
                | Option.none => Option.none
                | Option.some attemptedTail =>
                    match attemptedTail with
                    | Except.error error => Option.some (Except.error error)
                    | Except.ok tail => Option.some (Except.ok
                        (PsKernelExprV2MutualConstructorsResult.mk tail.context tail.state
                          (psKernelExprV2MutualConstructorShapeAppend ownResult.shapes tail.shapes)))

def psKernelExprV2MutualAddConstructorsWithFuel
    (fuel : Nat) (input : PsKernelExprV2Decoded)
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (targets : List PsKernelName) (types : List PsKernelExprV2MutualTypeHeader)
    (levels : List PsKernelLevel) (parameters : List PsKernelExprV2OrdinaryOpenBinder)
    (resultLevel : PsKernelLevel) : Option (Except String PsKernelExprV2MutualConstructorsResult) :=
  let analyze := fun (nextFuel : Nat) (nextContext : PsKernelExprV2CheckContext)
      (nextState : PsKernelExprV2CheckState) (owner : Nat) (ctor : PsKernelDagConstructor) =>
    psKernelExprV2MutualAnalyzeConstructorWithFuel nextFuel nextContext nextState
      targets types owner levels parameters resultLevel ctor;
  let visit := psKernelExprV2MutualAddTypesWorker types;
  visit analyze fuel input (psKernelExprV2OrdinaryOpenBinderCount parameters) context state 0
