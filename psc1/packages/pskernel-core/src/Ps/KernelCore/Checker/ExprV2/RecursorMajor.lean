import Ps.KernelCore.Checker.ExprV2.Quot
import Ps.KernelCore.Checker.ExprV2.String
import Ps.KernelCore.Checker.Recursor.Analysis

/- Recursor-major normalization after any required K conversion over the current owning DAG.
The recursor type belongs to the private index installed after checked
inductive admission. This module never traverses recursive-expression
metadata. Public WHNF and infer-only callbacks retain the recursor owner's
fixed predecessor fuel, independently of the callback used to reduce the
major itself. Every callback result becomes the complete current state. -/

def psKernelExprV2RecursorTake
    (count : Nat) (values : List Nat) : List Nat :=
  match count with
  | Nat.zero => List.nil
  | Nat.succ remaining =>
      match values with
      | List.nil => List.nil
      | List.cons first rest =>
          List.cons first (psKernelExprV2RecursorTake remaining rest)

def psKernelExprV2RecursorNatMajor
    (state : PsKernelExprV2WhnfState) (value : Nat) :
    Except String (Prod PsKernelExprV2WhnfState Nat) :=
  match value with
  | Nat.zero =>
      match psKernelExprV2PagedMkConst state.arena psKernelNatZeroName List.nil with
      | Except.error error => Except.error error
      | Except.ok result =>
          Except.ok (Prod.mk
            (psKernelExprV2WhnfStateWithArena state (Prod.fst result)) (Prod.snd result))
  | Nat.succ predecessor =>
      match psKernelExprV2PagedMkConst state.arena psKernelNatSuccName List.nil with
      | Except.error error => Except.error error
      | Except.ok head =>
          match psKernelExprV2PagedMkLit (Prod.fst head) (PsKernelLiteral.nat predecessor) with
          | Except.error error => Except.error error
          | Except.ok arg =>
              match psKernelExprV2PagedMkApp (Prod.fst arg) (Prod.snd head) (Prod.snd arg) with
              | Except.error error => Except.error error
              | Except.ok result =>
                  Except.ok (Prod.mk
                    (psKernelExprV2WhnfStateWithArena state (Prod.fst result))
                    (Prod.snd result))

def psKernelExprV2RecursorIsConstructorApp
    (context : PsKernelCheckerContext) (arena : PsKernelExprV2PagedArena) (root : Nat) :
    Except String Bool :=
  match psKernelExprV2TransformAppSpineOnCanonical arena root with
  | Except.error error => Except.error error
  | Except.ok spine =>
      match psKernelExprV2PagedRequire arena (Prod.fst spine) with
      | Except.error error => Except.error error
      | Except.ok head =>
          match head.node with
          | PsKernelExprV2Node.const name _ =>
              match psKernelEnvironmentFind context.environment name with
              | Option.some info =>
                  match info with
                  | PsKernelConstantInfo.ctorInfo _ => Except.ok true
                  | _ => Except.ok false
              | Option.none => Except.ok false
          | _ => Except.ok false

def psKernelExprV2RecursorTypeOwner
    (declarations : List PsKernelExprV2DeclarationRef) (recursor : PsKernelRecursorInfo) :
    Option Nat :=
  match psKernelExprV2DeclarationRefFind declarations recursor.base.name with
  | Option.none => Option.none
  | Option.some owner =>
      if psKernelExprV2DeclarationRefMatches owner (PsKernelConstantInfo.recInfo recursor) then
        Option.some owner.type
      else Option.none

def psKernelExprV2RecursorMajorInductWithFuel
    (fuel : Nat) :
    PsKernelExprV2PagedArena -> Nat -> Nat -> Except String (Option PsKernelName) :=
  match fuel with
  | Nat.zero =>
      fun (_arena : PsKernelExprV2PagedArena) (_root _index : Nat) =>
        Except.ok Option.none
  | Nat.succ remaining =>
      fun (arena : PsKernelExprV2PagedArena) (root index : Nat) =>
        match psKernelExprV2PagedRequire arena root with
        | Except.error error => Except.error error
        | Except.ok entry =>
            match entry.node with
            | PsKernelExprV2Node.forallE _ domain body _ =>
                match index with
                | Nat.zero =>
                    match psKernelExprV2TransformAppSpineOnCanonical arena domain with
                    | Except.error error => Except.error error
                    | Except.ok spine =>
                        match psKernelExprV2PagedRequire arena (Prod.fst spine) with
                        | Except.error error => Except.error error
                        | Except.ok head =>
                            match head.node with
                            | PsKernelExprV2Node.const name _ => Except.ok (Option.some name)
                            | _ => Except.ok Option.none
                | Nat.succ rest =>
                    let recur := psKernelExprV2RecursorMajorInductWithFuel remaining;
                    recur arena body rest
            | _ => Except.ok Option.none

def psKernelExprV2RecursorMajorInduct
    (state : PsKernelExprV2CheckState) (recursor : PsKernelRecursorInfo) :
    Option (Except String (Option PsKernelName)) :=
  match psKernelExprV2RecursorTypeOwner state.whnf.declarations recursor with
  | Option.none => Option.none
  | Option.some type =>
      let majorIndex := Nat.add recursor.numParams
        (Nat.add recursor.numMotives (Nat.add recursor.numMinors recursor.numIndices));
      Option.some (psKernelExprV2RecursorMajorInductWithFuel
        (Nat.succ majorIndex) state.whnf.arena type majorIndex)

def psKernelExprV2RecursorStructureFieldsWithFuel
    (fuel : Nat) :
    PsKernelExprV2PagedArena -> PsKernelName -> Nat -> Nat -> Nat ->
    Except String (Prod PsKernelExprV2PagedArena (List Nat)) :=
  match fuel with
  | Nat.zero =>
      fun (arena : PsKernelExprV2PagedArena) (_induct : PsKernelName)
          (_major _fieldCount _index : Nat) =>
        Except.ok (Prod.mk arena List.nil)
  | Nat.succ remaining =>
      fun (arena : PsKernelExprV2PagedArena) (induct : PsKernelName)
          (major fieldCount index : Nat) =>
        if psKernelNatLt index fieldCount then
          match psKernelExprV2PagedMkProj arena induct index major with
          | Except.error error => Except.error error
          | Except.ok projection =>
              let recur := psKernelExprV2RecursorStructureFieldsWithFuel remaining;
              match recur (Prod.fst projection) induct major fieldCount (Nat.succ index) with
              | Except.error error => Except.error error
              | Except.ok tail =>
                  Except.ok (Prod.mk (Prod.fst tail) (List.cons (Prod.snd projection) (Prod.snd tail)))
        else Except.ok (Prod.mk arena List.nil)

def psKernelExprV2RecursorIsPropOwnedWith
    (publicWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (inferType : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState) (root : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  match inferType context state root with
  | Option.none => Option.none
  | Option.some attempted =>
      match attempted with
      | Except.error error => Option.some (Except.error error)
      | Except.ok inferred =>
          match publicWhnf context (Prod.fst inferred) (Prod.snd inferred) with
          | Option.none => Option.none
          | Option.some attemptedWhnf =>
              match attemptedWhnf with
              | Except.error error => Option.some (Except.error error)
              | Except.ok reduced =>
                  let next := Prod.fst reduced;
                  match psKernelExprV2PagedRequire next.whnf.arena (Prod.snd reduced) with
                  | Except.error error => Option.some (Except.error error)
                  | Except.ok entry =>
                      match entry.node with
                      | PsKernelExprV2Node.sort level =>
                          Option.some (Except.ok (Prod.mk next (psKernelLevelNormalizesToZero level)))
                      | _ => Option.some (Except.error "expected sort")

/- Called only after the reference's inference, type WHNF and IsProp checks.
The metadata reads and arity checks below must not move before those callbacks. -/
def psKernelExprV2RecursorExpandStructure
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (inductName : PsKernelName) (major : Nat)
    (levels : List PsKernelLevel) (args : List Nat) :
    Except String (Prod PsKernelExprV2CheckState Nat) :=
  match psKernelEnvironmentFind context.scalar.environment inductName with
  | Option.none => Except.ok (Prod.mk state major)
  | Option.some info =>
      match info with
      | PsKernelConstantInfo.inductInfo induct =>
          match induct.ctors with
          | List.nil => Except.ok (Prod.mk state major)
          | List.cons ctorName rest =>
              match rest with
              | List.cons _ _ => Except.ok (Prod.mk state major)
              | List.nil =>
                  match psKernelEnvironmentFind context.scalar.environment ctorName with
                  | Option.none => Except.ok (Prod.mk state major)
                  | Option.some ctorValue =>
                      match ctorValue with
                      | PsKernelConstantInfo.ctorInfo ctor =>
                          if Nat.ble ctor.numParams (psKernelExprV2TransformNatLength args) then
                            let params := psKernelExprV2RecursorTake ctor.numParams args;
                            match psKernelExprV2RecursorStructureFieldsWithFuel
                                (Nat.succ ctor.numFields) state.whnf.arena
                                inductName major ctor.numFields 0 with
                            | Except.error error => Except.error error
                            | Except.ok fields =>
                                match psKernelExprV2PagedMkConst (Prod.fst fields) ctorName levels with
                                | Except.error error => Except.error error
                                | Except.ok head =>
                                    match psKernelExprV2TransformApplyArgsOnCanonical
                                        params (Prod.fst head) (Prod.snd head) with
                                    | Except.error error => Except.error error
                                    | Except.ok appliedParams =>
                                        match psKernelExprV2TransformApplyArgsOnCanonical
                                            (Prod.snd fields) (Prod.fst appliedParams) (Prod.snd appliedParams) with
                                        | Except.error error => Except.error error
                                        | Except.ok result =>
                                            Except.ok (Prod.mk
                                              (psKernelExprV2CheckStateWithArena state (Prod.fst result))
                                              (Prod.snd result))
                          else Except.ok (Prod.mk state major)
                      | _ => Except.ok (Prod.mk state major)
      | _ => Except.ok (Prod.mk state major)

def psKernelExprV2RecursorToStructureOwnedWith
    (publicWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (inferType : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (recursor : PsKernelRecursorInfo) (major : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match psKernelExprV2RecursorIsConstructorApp context.scalar state.whnf.arena major with
  | Except.error error => Option.some (Except.error error)
  | Except.ok isConstructor =>
      if isConstructor then Option.some (Except.ok (Prod.mk state major))
      else
        match psKernelExprV2RecursorMajorInduct state recursor with
        | Option.none => Option.none
        | Option.some attemptedInduct =>
            match attemptedInduct with
            | Except.error error => Option.some (Except.error error)
            | Except.ok found =>
                match found with
                | Option.none => Option.some (Except.ok (Prod.mk state major))
                | Option.some inductName =>
                    if psKernelEnvironmentIsNonRecStructure context.scalar.environment inductName then
                      match inferType context state major with
                      | Option.none => Option.none
                      | Option.some attemptedType =>
                          match attemptedType with
                          | Except.error error => Option.some (Except.error error)
                          | Except.ok inferred =>
                              match publicWhnf context (Prod.fst inferred) (Prod.snd inferred) with
                              | Option.none => Option.none
                              | Option.some attemptedWhnf =>
                                  match attemptedWhnf with
                                  | Except.error error => Option.some (Except.error error)
                                  | Except.ok reduced =>
                                      let afterType := Prod.fst reduced;
                                      let majorType := Prod.snd reduced;
                                      match psKernelExprV2TransformAppSpineOnCanonical afterType.whnf.arena majorType with
                                      | Except.error error => Option.some (Except.error error)
                                      | Except.ok spine =>
                                          match psKernelExprV2PagedRequire afterType.whnf.arena (Prod.fst spine) with
                                          | Except.error error => Option.some (Except.error error)
                                          | Except.ok head =>
                                              match head.node with
                                              | PsKernelExprV2Node.const typeName levels =>
                                                  if psKernelNameEq typeName inductName then
                                                    match psKernelExprV2RecursorIsPropOwnedWith
                                                        publicWhnf inferType context afterType majorType with
                                                    | Option.none => Option.none
                                                    | Option.some attemptedProp =>
                                                        match attemptedProp with
                                                        | Except.error error => Option.some (Except.error error)
                                                        | Except.ok propResult =>
                                                            if Prod.snd propResult then
                                                              Option.some (Except.ok (Prod.mk (Prod.fst propResult) major))
                                                            else Option.some (psKernelExprV2RecursorExpandStructure
                                                              context (Prod.fst propResult) inductName major levels (Prod.snd spine))
                                                  else Option.some (Except.ok (Prod.mk afterType major))
                                              | _ => Option.some (Except.ok (Prod.mk afterType major))
                    else Option.some (Except.ok (Prod.mk state major))

/- A constructor reached by major WHNF takes the second constructor shortcut.
String expansion uses public WHNF even when the first major reduction used
cheap core WHNF. -/
def psKernelExprV2RecursorNormalizeMajorOwnedWith
    (publicWhnf : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (inferType : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Nat)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (recursor : PsKernelRecursorInfo) (major : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Nat)) :=
  match psKernelExprV2PagedRequire state.whnf.arena major with
  | Except.error error => Option.some (Except.error error)
  | Except.ok entry =>
      match entry.node with
      | PsKernelExprV2Node.lit literal =>
          match literal with
          | PsKernelLiteral.nat value =>
              psKernelExprV2LiftWhnfAttempt state
                (Option.some (psKernelExprV2RecursorNatMajor state.whnf value))
          | PsKernelLiteral.str value =>
              match psKernelExprV2StringLitToConstructorOnCanonical state.whnf.arena value with
              | Except.error error => Option.some (Except.error error)
              | Except.ok built =>
                  publicWhnf context (psKernelExprV2CheckStateWithArena state (Prod.fst built)) (Prod.snd built)
      | _ =>
          psKernelExprV2RecursorToStructureOwnedWith
            publicWhnf inferType context state recursor major
