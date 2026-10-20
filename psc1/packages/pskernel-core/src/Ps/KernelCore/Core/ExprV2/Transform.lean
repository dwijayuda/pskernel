import Ps.KernelCore.Core.ExprV2.TransformSupport

/-
One DAG visitor owns instantiation, abstraction and universe substitution.
No legacy expression is imported or materialized. Bounded zero-fuel calls
retain the original subtree, matching existing bounded transformations.
Default calls derive the original expanded-node budget, then cap actual
execution to the sufficient validated depth before creating recursive workers.
Memo keys include source, binder offset and effective budget; all memo state
belongs to one operation and one immutable arena lineage.
-/

inductive PsKernelExprV2Transform where
  | instantiate (start : Nat) (values : List Nat)
  | abstractFVars (names : List PsKernelName)
  | levels (params : List PsKernelName) (values : List PsKernelLevel)

structure PsKernelExprV2TransformMemo where
  source : Nat
  offset : Nat
  budget : Nat
  result : Nat

structure PsKernelExprV2TransformState where
  arena : PsKernelExprV2PagedArena
  memo : List PsKernelExprV2TransformMemo

def psKernelExprV2TransformMemoFind
    (memo : List PsKernelExprV2TransformMemo)
    (source offset budget : Nat) : Option Nat :=
  match memo with
  | List.nil => Option.none
  | List.cons first rest =>
      if Nat.beq first.source source then
        if Nat.beq first.offset offset then
          if Nat.beq first.budget budget then Option.some first.result
          else psKernelExprV2TransformMemoFind rest source offset budget
        else psKernelExprV2TransformMemoFind rest source offset budget
      else psKernelExprV2TransformMemoFind rest source offset budget

def psKernelExprV2TransformFinish
    (state : PsKernelExprV2TransformState)
    (source offset budget result : Nat) :
    Prod PsKernelExprV2TransformState Nat :=
  Prod.mk
    (PsKernelExprV2TransformState.mk state.arena
      (List.cons (PsKernelExprV2TransformMemo.mk source offset budget result) state.memo))
    result

def psKernelExprV2TransformRebuilt
    (state : PsKernelExprV2TransformState)
    (source offset budget : Nat)
    (rebuilt : Prod PsKernelExprV2PagedArena Nat) :
    Prod PsKernelExprV2TransformState Nat :=
  psKernelExprV2TransformFinish
    (PsKernelExprV2TransformState.mk (Prod.fst rebuilt) state.memo)
    source offset budget (Prod.snd rebuilt)

def psKernelExprV2TransformNameLength (names : List PsKernelName) : Nat :=
  match names with
  | List.nil => 0
  | List.cons _ rest => Nat.succ (psKernelExprV2TransformNameLength rest)

def psKernelExprV2TransformNameLast
    (names : List PsKernelName) (needle : PsKernelName)
    (index : Nat) (answer : Option Nat) : Option Nat :=
  match names with
  | List.nil => answer
  | List.cons first rest =>
      let next := if psKernelNameEq first needle then Option.some index else answer;
      psKernelExprV2TransformNameLast rest needle (Nat.succ index) next

def psKernelExprV2TransformLevels
    (levels : List PsKernelLevel)
    (params : List PsKernelName) (values : List PsKernelLevel) : List PsKernelLevel :=
  match levels with
  | List.nil => List.nil
  | List.cons first rest =>
      List.cons (psKernelLevelInstantiateParams first params values)
        (psKernelExprV2TransformLevels rest params values)

def psKernelExprV2TransformLevelsEq (left right : List PsKernelLevel) : Bool :=
  match left with
  | List.nil =>
      match right with
      | List.nil => true
      | _ => false
  | List.cons first rest =>
      match right with
      | List.nil => false
      | List.cons second tail =>
          if psKernelLevelEq first second then psKernelExprV2TransformLevelsEq rest tail
          else false

def psKernelExprV2TransformLiftReplacement
    (arena : PsKernelExprV2PagedArena) (replacement offset : Nat) :
    Except String (Prod PsKernelExprV2PagedArena Nat) :=
  match psKernelExprV2PagedFind arena replacement with
  | Option.none => Except.error "PSKERNEL_V2_TRANSFORM_BAD_REFERENCE"
  | Option.some entry =>
      let state := PsKernelExprV2PagedLiftState.mk arena List.nil;
      match psKernelExprV2PagedLiftWithFuel
          (Nat.succ entry.depth) state replacement 0 offset with
      | Except.error error => Except.error error
      | Except.ok result =>
          let transformed := Prod.fst result;
          Except.ok (Prod.mk transformed.arena (Prod.snd result))

def psKernelExprV2TransformLeaf
    (operation : PsKernelExprV2Transform) (arena : PsKernelExprV2PagedArena)
    (source offset : Nat) (entry : PsKernelExprV2Entry) :
    Except String (Prod PsKernelExprV2PagedArena (Option Nat)) :=
  match operation with
  | PsKernelExprV2Transform.instantiate start values =>
      if Nat.ble entry.looseRange (Nat.add start offset) then
        Except.ok (Prod.mk arena (Option.some source))
      else
        match values with
        | List.nil => Except.ok (Prod.mk arena (Option.some source))
        | List.cons _ _ =>
            match entry.node with
            | PsKernelExprV2Node.bvar index =>
                if Nat.blt index (Nat.add start offset) then
                  Except.ok (Prod.mk arena (Option.some source))
                else
                  let relative := Nat.sub index (Nat.add start offset);
                  let rebuilt :=
                    match psKernelExprV2TransformNatGet values relative with
                    | Option.some replacement =>
                        psKernelExprV2TransformLiftReplacement arena replacement offset
                    | Option.none =>
                        psKernelExprV2PagedMkBVar arena
                          (Nat.sub index (psKernelExprV2TransformNatLength values));
                  match rebuilt with
                  | Except.error error => Except.error error
                  | Except.ok result =>
                      Except.ok (Prod.mk (Prod.fst result) (Option.some (Prod.snd result)))
            | _ => Except.ok (Prod.mk arena Option.none)
  | PsKernelExprV2Transform.abstractFVars names =>
      if entry.hasFVar then
        match entry.node with
        | PsKernelExprV2Node.fvar name =>
            match psKernelExprV2TransformNameLast names name 0 Option.none with
            | Option.none => Except.ok (Prod.mk arena (Option.some source))
            | Option.some index =>
                match psKernelExprV2PagedMkBVar arena
                    (Nat.sub
                      (Nat.sub (Nat.add offset (psKernelExprV2TransformNameLength names)) index) 1) with
                | Except.error error => Except.error error
                | Except.ok result =>
                    Except.ok (Prod.mk (Prod.fst result) (Option.some (Prod.snd result)))
        | _ => Except.ok (Prod.mk arena Option.none)
      else Except.ok (Prod.mk arena (Option.some source))
  | PsKernelExprV2Transform.levels params values =>
      match entry.node with
      | PsKernelExprV2Node.sort level =>
          let next := psKernelLevelInstantiateParams level params values;
          if psKernelLevelEq level next then
            Except.ok (Prod.mk arena (Option.some source))
          else
            match psKernelExprV2PagedMkSort arena next with
            | Except.error error => Except.error error
            | Except.ok result =>
                Except.ok (Prod.mk (Prod.fst result) (Option.some (Prod.snd result)))
      | PsKernelExprV2Node.const name levels =>
          let next := psKernelExprV2TransformLevels levels params values;
          if psKernelExprV2TransformLevelsEq levels next then
            Except.ok (Prod.mk arena (Option.some source))
          else
            match psKernelExprV2PagedMkConst arena name next with
            | Except.error error => Except.error error
            | Except.ok result =>
                Except.ok (Prod.mk (Prod.fst result) (Option.some (Prod.snd result)))
      | _ => Except.ok (Prod.mk arena Option.none)

def psKernelExprV2TransformMapChildren
    (children : List (Prod Nat Nat))
    (recurse : PsKernelExprV2TransformState -> Nat -> Nat ->
      Except String (Prod PsKernelExprV2TransformState Nat))
    (state : PsKernelExprV2TransformState) :
    Except String (Prod PsKernelExprV2TransformState (List Nat)) :=
  match children with
  | List.nil => Except.ok (Prod.mk state List.nil)
  | List.cons child rest =>
      match recurse state (Prod.fst child) (Prod.snd child) with
      | Except.error error => Except.error error
      | Except.ok first =>
          match psKernelExprV2TransformMapChildren rest recurse (Prod.fst first) with
          | Except.error error => Except.error error
          | Except.ok tail =>
              Except.ok (Prod.mk (Prod.fst tail)
                (List.cons (Prod.snd first) (Prod.snd tail)))

def psKernelExprV2TransformWithFuel
    (fuel : Nat) :
    PsKernelExprV2Transform -> PsKernelExprV2TransformState -> Nat -> Nat ->
    Except String (Prod PsKernelExprV2TransformState Nat) :=
  match fuel with
  | Nat.zero =>
      fun (_operation : PsKernelExprV2Transform)
        (state : PsKernelExprV2TransformState) (source _offset : Nat) =>
        match psKernelExprV2PagedFind state.arena source with
        | Option.none => Except.error "PSKERNEL_V2_TRANSFORM_BAD_ROOT"
        | Option.some _ => Except.ok (Prod.mk state source)
  | Nat.succ remaining =>
      let smaller := psKernelExprV2TransformWithFuel remaining;
      fun (operation : PsKernelExprV2Transform)
        (state : PsKernelExprV2TransformState) (source offset : Nat) =>
        match psKernelExprV2PagedFind state.arena source with
        | Option.none => Except.error "PSKERNEL_V2_TRANSFORM_BAD_ROOT"
        | Option.some entry =>
            let effective :=
              if Nat.ble (Nat.succ remaining) entry.depth then Nat.succ remaining
              else entry.depth;
            let depth :=
              match operation with
              | PsKernelExprV2Transform.levels _ _ => 0
              | _ => offset;
            match psKernelExprV2TransformMemoFind state.memo source depth effective with
            | Option.some result => Except.ok (Prod.mk state result)
            | Option.none =>
                match psKernelExprV2TransformLeaf operation state.arena source depth entry with
                | Except.error error => Except.error error
                | Except.ok leaf =>
                    match Prod.snd leaf with
                    | Option.some result =>
                        Except.ok (psKernelExprV2TransformRebuilt state source depth effective
                          (Prod.mk (Prod.fst leaf) result))
                    | Option.none =>
                        let children := psKernelExprV2TransformChildren entry.node depth;
                        match psKernelExprV2TransformMapChildren children
                            (smaller operation) state with
                        | Except.error error => Except.error error
                        | Except.ok mapped =>
                            let after := Prod.fst mapped;
                            if psKernelExprV2TransformSameChildren children (Prod.snd mapped) then
                              Except.ok (psKernelExprV2TransformFinish after source depth effective source)
                            else
                              match psKernelExprV2TransformBuild after.arena entry.node (Prod.snd mapped) with
                              | Except.error error => Except.error error
                              | Except.ok rebuilt =>
                                  Except.ok (psKernelExprV2TransformRebuilt after source depth effective rebuilt)

def psKernelExprV2TransformReferences
    (operation : PsKernelExprV2Transform) (arena : PsKernelExprV2PagedArena) : Except String Unit :=
  match operation with
  | PsKernelExprV2Transform.instantiate _ values => psKernelExprV2TransformRequireIds arena values
  | _ => Except.ok ()

def psKernelExprV2TransformOnCanonicalWithFuel
    (fuel : Nat) (operation : PsKernelExprV2Transform)
    (arena : PsKernelExprV2PagedArena) (root offset : Nat) :
    Except String (Prod PsKernelExprV2PagedArena Nat) :=
  match psKernelExprV2TransformReferences operation arena with
  | Except.error error => Except.error error
  | Except.ok _ =>
      match psKernelExprV2PagedFind arena root with
      | Option.none => Except.error "PSKERNEL_V2_TRANSFORM_BAD_ROOT"
      | Option.some entry =>
          let actualFuel := if Nat.ble fuel entry.depth then fuel else entry.depth;
          match psKernelExprV2TransformWithFuel actualFuel operation
              (PsKernelExprV2TransformState.mk arena List.nil) root offset with
          | Except.error error => Except.error error
          | Except.ok result =>
              let transformed := Prod.fst result;
              Except.ok (Prod.mk transformed.arena (Prod.snd result))

def psKernelExprV2TransformOnCanonical
    (operation : PsKernelExprV2Transform) (arena : PsKernelExprV2PagedArena) (root offset : Nat) :
    Except String (Prod PsKernelExprV2PagedArena Nat) :=
  match psKernelExprV2TransformCountOnCanonical arena root with
  | Except.error error => Except.error error
  | Except.ok count =>
      psKernelExprV2TransformOnCanonicalWithFuel (Nat.succ count) operation arena root offset

def psKernelExprV2TransformCheckedWithFuel
    (fuel : Nat) (operation : PsKernelExprV2Transform)
    (source : PsKernelExprV2PagedArena) (root offset : Nat) :
    Except String (Prod PsKernelExprV2PagedArena Nat) :=
  match psKernelExprV2PagedValidate source with
  | Except.error error => Except.error error
  | Except.ok canonical =>
      match psKernelExprV2TransformOnCanonicalWithFuel fuel operation canonical root offset with
      | Except.error error => Except.error error
      | Except.ok result =>
          match psKernelExprV2PagedValidate (Prod.fst result) with
          | Except.error error => Except.error error
          | Except.ok verified => Except.ok (Prod.mk verified (Prod.snd result))

def psKernelExprV2TransformChecked
    (operation : PsKernelExprV2Transform) (source : PsKernelExprV2PagedArena) (root offset : Nat) :
    Except String (Prod PsKernelExprV2PagedArena Nat) :=
  match psKernelExprV2PagedValidate source with
  | Except.error error => Except.error error
  | Except.ok canonical =>
      match psKernelExprV2TransformOnCanonical operation canonical root offset with
      | Except.error error => Except.error error
      | Except.ok result =>
          match psKernelExprV2PagedValidate (Prod.fst result) with
          | Except.error error => Except.error error
          | Except.ok verified => Except.ok (Prod.mk verified (Prod.snd result))

def psKernelExprV2PagedInstantiateAtChecked
    (arena : PsKernelExprV2PagedArena) (root start : Nat) (values : List Nat) (offset : Nat) :
    Except String (Prod PsKernelExprV2PagedArena Nat) :=
  psKernelExprV2TransformChecked (PsKernelExprV2Transform.instantiate start values) arena root offset

def psKernelExprV2PagedInstantiateChecked
    (arena : PsKernelExprV2PagedArena) (root : Nat) (values : List Nat) :
    Except String (Prod PsKernelExprV2PagedArena Nat) :=
  psKernelExprV2PagedInstantiateAtChecked arena root 0 values 0

def psKernelExprV2PagedInstantiateRevChecked
    (arena : PsKernelExprV2PagedArena) (root : Nat) (values : List Nat) :
    Except String (Prod PsKernelExprV2PagedArena Nat) :=
  psKernelExprV2PagedInstantiateChecked arena root (psKernelExprV2TransformNatReverse values List.nil)

def psKernelExprV2PagedAbstractFVarsAtChecked
    (arena : PsKernelExprV2PagedArena) (root : Nat) (names : List PsKernelName) (offset : Nat) :
    Except String (Prod PsKernelExprV2PagedArena Nat) :=
  psKernelExprV2TransformChecked (PsKernelExprV2Transform.abstractFVars names) arena root offset

def psKernelExprV2PagedAbstractFVarsChecked
    (arena : PsKernelExprV2PagedArena) (root : Nat) (names : List PsKernelName) :
    Except String (Prod PsKernelExprV2PagedArena Nat) :=
  psKernelExprV2PagedAbstractFVarsAtChecked arena root names 0

def psKernelExprV2PagedInstantiateLevelParamsChecked
    (arena : PsKernelExprV2PagedArena) (root : Nat)
    (params : List PsKernelName) (values : List PsKernelLevel) :
    Except String (Prod PsKernelExprV2PagedArena Nat) :=
  psKernelExprV2TransformChecked (PsKernelExprV2Transform.levels params values) arena root 0
