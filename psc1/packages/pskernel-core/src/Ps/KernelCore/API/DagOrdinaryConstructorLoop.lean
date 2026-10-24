import Ps.KernelCore.API.DagOrdinaryConstructorAnalysis
import Ps.KernelCore.Core.ExprV2.Decode

/-
Private ordinary-constructor loop. This is not complete inductive admission.

The caller has established the checked header parameter owner and a matching
private provisional environment/reference table for the datatype. The existing
PsKernelExprV2Decoded carrier must come from the validated original input arena;
that arena is a prefix of the current owner and contains every original ctor
root. Thus DecodedRequire built ctor.type is the boundary expression for that
same original DAG root. Caller-constructed decoded records are not certificates,
and these internal preconditions are not guarantees for untrusted input.

Boundary expressions are used only for constructor metadata. Closure, typing,
parameters, fields, positivity and result indices are checked by the DAG-native
single-constructor analysis. An injected analysis callback must satisfy that
helper's owner/shape contract; the actual wrapper supplies the real checker.

Each constructor starts from the header locals, freshness and semantic caches.
Only its appended arena survives into the next constructor's header owner.
Checked constructor metadata and its original-root reference are staged together
in the private work environment before checking the next constructor. Shapes
remain in source order and are returned only when the complete tail succeeds.
No recursor is generated, no public route is changed and no admission receipt
is produced. None/error discard the attempted private result.

The raw fuel matches psKernelAddSimpleConstructorsWithFuel: zero fails even for
an empty list, a successor consumes one step before analysis and tail recursion.
The future ordinary-admission caller supplies Nat.succ admissionFuel.
-/
structure PsKernelExprV2OrdinaryConstructorsResult where
  context : PsKernelExprV2CheckContext
  state : PsKernelExprV2CheckState
  shapes : List PsKernelExprV2OrdinaryConstructorShape

def psKernelExprV2OrdinaryOpenBinderCount
    (values : List PsKernelExprV2OrdinaryOpenBinder) : Nat :=
  match values with
  | List.nil => 0
  | List.cons _ rest =>
      Nat.succ (psKernelExprV2OrdinaryOpenBinderCount rest)

/- Materialize metadata only after successful analysis. Both the legacy type
   lookup and the new declaration reference use the original input ctor.type.
   The analyzed field context, references, freshness and caches are discarded.
   Its appended arena retains every ID appearing in the returned shape. -/
def psKernelExprV2OrdinaryInstallConstructor
    (built : PsKernelExprV2Decoded) (target : PsKernelName)
    (numParams : Nat) (isUnsafe : Bool) (index : Nat)
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (ctor : PsKernelDagConstructor)
    (analyzed : PsKernelExprV2OrdinaryConstructorAnalysis) :
    Except String (Prod PsKernelExprV2CheckContext PsKernelExprV2CheckState) :=
  match psKernelExprV2DecodedRequire built ctor.type with
  | Except.error error => Except.error error
  | Except.ok type =>
      let info :=
        PsKernelConstructorInfo.mk
          (PsKernelConstantBase.mk ctor.name context.scalar.levelParams type)
          target index numParams
          (psKernelExprV2OrdinaryOpenBinderCount analyzed.shape.fields) isUnsafe;
      let work :=
        psKernelEnvironmentAddUnchecked context.scalar.environment
          (PsKernelConstantInfo.ctorInfo info);
      let reference :=
        PsKernelExprV2DeclarationRef.mk ctor.name context.scalar.levelParams
          ctor.type Option.none PsKernelExprV2DeclarationRefKind.constructorDecl;
      let nextContext :=
        PsKernelExprV2CheckContext.mk
          (psKernelCheckerContextWithEnvironment context.scalar work) context.locals;
      let nextWhnf :=
        PsKernelExprV2WhnfState.mk analyzed.state.whnf.arena
          state.whnf.coreCache state.whnf.publicCache
          (List.cons reference state.whnf.declarations);
      Except.ok
        (Prod.mk nextContext (psKernelExprV2CheckStateWithWhnf state nextWhnf))

def psKernelExprV2OrdinaryAddConstructorsWorker
    (fuel : Nat) :
    (Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState ->
      PsKernelName -> List PsKernelLevel -> List PsKernelExprV2OrdinaryOpenBinder ->
      Nat -> PsKernelLevel -> PsKernelDagConstructor ->
      Option (Except String PsKernelExprV2OrdinaryConstructorAnalysis)) ->
    PsKernelExprV2Decoded -> PsKernelName -> Nat -> Bool ->
    List PsKernelLevel -> List PsKernelExprV2OrdinaryOpenBinder -> Nat ->
    PsKernelLevel -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState ->
    Nat -> List PsKernelDagConstructor ->
    Option (Except String PsKernelExprV2OrdinaryConstructorsResult) :=
  match fuel with
  | Nat.zero =>
      fun
        (_analyze : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState ->
          PsKernelName -> List PsKernelLevel -> List PsKernelExprV2OrdinaryOpenBinder ->
          Nat -> PsKernelLevel -> PsKernelDagConstructor ->
          Option (Except String PsKernelExprV2OrdinaryConstructorAnalysis))
        (_built : PsKernelExprV2Decoded) (_target : PsKernelName)
        (_numParams : Nat) (_isUnsafe : Bool) (_levels : List PsKernelLevel)
        (_parameters : List PsKernelExprV2OrdinaryOpenBinder) (_numIndices : Nat)
        (_resultLevel : PsKernelLevel) (_context : PsKernelExprV2CheckContext)
        (_state : PsKernelExprV2CheckState) (_index : Nat)
        (_ctors : List PsKernelDagConstructor) =>
        Option.some
          (Except.error "simple inductive constructor admission budget exhausted")
  | Nat.succ remaining =>
      let smaller :
          (Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState ->
            PsKernelName -> List PsKernelLevel -> List PsKernelExprV2OrdinaryOpenBinder ->
            Nat -> PsKernelLevel -> PsKernelDagConstructor ->
            Option (Except String PsKernelExprV2OrdinaryConstructorAnalysis)) ->
          PsKernelExprV2Decoded -> PsKernelName -> Nat -> Bool ->
          List PsKernelLevel -> List PsKernelExprV2OrdinaryOpenBinder -> Nat ->
          PsKernelLevel -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState ->
          Nat -> List PsKernelDagConstructor ->
          Option (Except String PsKernelExprV2OrdinaryConstructorsResult) :=
        psKernelExprV2OrdinaryAddConstructorsWorker remaining;
      fun
        (analyze : Nat -> PsKernelExprV2CheckContext -> PsKernelExprV2CheckState ->
          PsKernelName -> List PsKernelLevel -> List PsKernelExprV2OrdinaryOpenBinder ->
          Nat -> PsKernelLevel -> PsKernelDagConstructor ->
          Option (Except String PsKernelExprV2OrdinaryConstructorAnalysis))
        (built : PsKernelExprV2Decoded) (target : PsKernelName)
        (numParams : Nat) (isUnsafe : Bool) (levels : List PsKernelLevel)
        (parameters : List PsKernelExprV2OrdinaryOpenBinder) (numIndices : Nat)
        (resultLevel : PsKernelLevel) (context : PsKernelExprV2CheckContext)
        (state : PsKernelExprV2CheckState) (index : Nat)
        (ctors : List PsKernelDagConstructor) =>
        match ctors with
        | List.nil =>
            Option.some
              (Except.ok
                (PsKernelExprV2OrdinaryConstructorsResult.mk context state List.nil))
        | List.cons ctor rest =>
            match analyze remaining context state target levels parameters
                numIndices resultLevel ctor with
            | Option.none => Option.none
            | Option.some attempted =>
                match attempted with
                | Except.error error => Option.some (Except.error error)
                | Except.ok analyzed =>
                    match psKernelExprV2OrdinaryInstallConstructor
                        built target numParams isUnsafe index context state ctor analyzed with
                    | Except.error error => Option.some (Except.error error)
                    | Except.ok installed =>
                        match smaller analyze built target numParams isUnsafe levels parameters
                            numIndices resultLevel (Prod.fst installed) (Prod.snd installed)
                            (Nat.succ index) rest with
                        | Option.none => Option.none
                        | Option.some attemptedTail =>
                            match attemptedTail with
                            | Except.error error => Option.some (Except.error error)
                            | Except.ok tail =>
                                Option.some
                                  (Except.ok
                                    (PsKernelExprV2OrdinaryConstructorsResult.mk
                                      tail.context tail.state
                                      (List.cons analyzed.shape tail.shapes)))

def psKernelExprV2OrdinaryAddConstructorsWithFuel
    (fuel : Nat) (built : PsKernelExprV2Decoded)
    (target : PsKernelName) (numParams : Nat) (isUnsafe : Bool)
    (levels : List PsKernelLevel)
    (parameters : List PsKernelExprV2OrdinaryOpenBinder) (numIndices : Nat)
    (resultLevel : PsKernelLevel) (context : PsKernelExprV2CheckContext)
    (state : PsKernelExprV2CheckState) (index : Nat)
    (ctors : List PsKernelDagConstructor) :
    Option (Except String PsKernelExprV2OrdinaryConstructorsResult) :=
  let analyze :=
    fun (phaseFuel : Nat) (nextContext : PsKernelExprV2CheckContext)
        (nextState : PsKernelExprV2CheckState) (nextTarget : PsKernelName)
        (nextLevels : List PsKernelLevel)
        (nextParameters : List PsKernelExprV2OrdinaryOpenBinder) (nextNumIndices : Nat)
        (nextResultLevel : PsKernelLevel) (ctor : PsKernelDagConstructor) =>
      psKernelExprV2OrdinaryAnalyzeConstructorWithFuel phaseFuel nextContext nextState
        nextTarget nextLevels nextParameters nextNumIndices nextResultLevel ctor;
  psKernelExprV2OrdinaryAddConstructorsWorker fuel analyze built target numParams isUnsafe
    levels parameters numIndices resultLevel context state index ctors
