import Ps.KernelCore.Research.ExprV2ChunkedBuilder
import Ps.KernelCore.Research.ExprV2Validation

/-
Expression V2 / M3 native research: validated DAG-aware loose-bound-variable
lifting. This is source-correctness research, not a replacement for the
existing kernel substitution or a production checking capability.

The entire chunked input arena is replay-validated on entry. A cached exact
loose-bvar range permits safe early pruning. The output preserves unchanged
node IDs and memoizes transformed shared nodes by (node, cutoff, amount),
avoiding exponentially repeated traversals over DAG subexpressions.
-/

private structure PsKernelExprV2LiftMemoEntry where
  source : Nat
  cutoff : Nat
  amount : Nat
  result : Nat

private structure PsKernelExprV2LiftState where
  arena : PsKernelExprV2ChunkedArena
  memo : List PsKernelExprV2LiftMemoEntry

private def psKernelExprV2LiftMemoFind
    (memo : List PsKernelExprV2LiftMemoEntry)
    (source cutoff amount : Nat) : Option Nat :=
  match memo with
  | [] => Option.none
  | h :: rest =>
      if h.source == source && h.cutoff == cutoff &&
          h.amount == amount then
        Option.some h.result
      else
        psKernelExprV2LiftMemoFind rest source cutoff amount

private def psKernelExprV2LiftFinish
    (state : PsKernelExprV2LiftState)
    (source cutoff amount result : Nat) :
    PsKernelExprV2LiftState × Nat :=
  let saved : PsKernelExprV2LiftMemoEntry := {
    source := source
    cutoff := cutoff
    amount := amount
    result := result
  }
  ({ state with memo := saved :: state.memo }, result)

private def psKernelExprV2LiftWithFuel
    (fuel : Nat) (state : PsKernelExprV2LiftState)
    (id cutoff amount : Nat) :
    Except String (PsKernelExprV2LiftState × Nat) := do
  match fuel with
  | 0 => throw "PSKERNEL_V2_LIFT_FUEL_EXHAUSTED"
  | Nat.succ remaining =>
      let entry ← match psKernelExprV2ChunkedFind state.arena id with
        | Option.some v => pure v
        | Option.none => throw "PSKERNEL_V2_LIFT_INVALID_NODE_ID"
      if amount == 0 || entry.looseRange <= cutoff then
        return (state,id)
      if let some prior := psKernelExprV2LiftMemoFind state.memo id cutoff amount then
        return (state,prior)
      match entry.node with
      | .bvar index =>
          if index < cutoff then
            return psKernelExprV2LiftFinish state id cutoff amount id
          let (a,newId) ← psKernelExprV2ChunkedMkBVar state.arena (index+amount)
          return psKernelExprV2LiftFinish
            { state with arena := a } id cutoff amount newId
      | .app fn arg =>
          let (s1,newFn) ← psKernelExprV2LiftWithFuel remaining state fn cutoff amount
          let (s2,newArg) ← psKernelExprV2LiftWithFuel remaining s1 arg cutoff amount
          if newFn == fn && newArg == arg then
            return psKernelExprV2LiftFinish s2 id cutoff amount id
          let (a,newId) ← psKernelExprV2ChunkedMkApp s2.arena newFn newArg
          return psKernelExprV2LiftFinish
            { s2 with arena := a } id cutoff amount newId
      | .lam name type body binderInfo =>
          let (s1,newType) ← psKernelExprV2LiftWithFuel remaining state type cutoff amount
          let (s2,newBody) ← psKernelExprV2LiftWithFuel remaining s1 body (cutoff+1) amount
          if newType == type && newBody == body then
            return psKernelExprV2LiftFinish s2 id cutoff amount id
          let (a,newId) ←
            psKernelExprV2ChunkedMkLam s2.arena name newType newBody binderInfo
          return psKernelExprV2LiftFinish
            { s2 with arena := a } id cutoff amount newId
      | .forallE name type body binderInfo =>
          let (s1,newType) ← psKernelExprV2LiftWithFuel remaining state type cutoff amount
          let (s2,newBody) ← psKernelExprV2LiftWithFuel remaining s1 body (cutoff+1) amount
          if newType == type && newBody == body then
            return psKernelExprV2LiftFinish s2 id cutoff amount id
          let (a,newId) ←
            psKernelExprV2ChunkedMkForall s2.arena name newType newBody binderInfo
          return psKernelExprV2LiftFinish
            { s2 with arena := a } id cutoff amount newId
      | .letE name type value body nondep =>
          let (s1,newType) ← psKernelExprV2LiftWithFuel remaining state type cutoff amount
          let (s2,newValue) ← psKernelExprV2LiftWithFuel remaining s1 value cutoff amount
          let (s3,newBody) ← psKernelExprV2LiftWithFuel remaining s2 body (cutoff+1) amount
          if newType == type && newValue == value && newBody == body then
            return psKernelExprV2LiftFinish s3 id cutoff amount id
          let (a,newId) ←
            psKernelExprV2ChunkedMkLet s3.arena name newType newValue newBody nondep
          return psKernelExprV2LiftFinish
            { s3 with arena := a } id cutoff amount newId
      | .mdata tag body =>
          let (s1,newBody) ← psKernelExprV2LiftWithFuel remaining state body cutoff amount
          if newBody == body then
            return psKernelExprV2LiftFinish s1 id cutoff amount id
          let (a,newId) ← psKernelExprV2ChunkedMkMData s1.arena tag newBody
          return psKernelExprV2LiftFinish
            { s1 with arena := a } id cutoff amount newId
      | .proj typeName idx body =>
          let (s1,newBody) ← psKernelExprV2LiftWithFuel remaining state body cutoff amount
          if newBody == body then
            return psKernelExprV2LiftFinish s1 id cutoff amount id
          let (a,newId) ←
            psKernelExprV2ChunkedMkProj s1.arena typeName idx newBody
          return psKernelExprV2LiftFinish
            { s1 with arena := a } id cutoff amount newId
      | _ =>
          return psKernelExprV2LiftFinish state id cutoff amount id

/-
Only public entry: fail-closed replay validation of *all* source metadata,
lookup and bounded transformation, followed by full output validation. This
expensive wrapper is a correctness reference, not a production benchmark.
-/
def psKernelExprV2LiftChecked
    (source : PsKernelExprV2ChunkedArena)
    (root cutoff amount : Nat) :
    Except String (PsKernelExprV2ChunkedArena × Nat) := do
  let _ ← psKernelExprV2ValidateChunked source
  let rootEntry ← match psKernelExprV2ChunkedFind source root with
    | Option.some e => pure e
    | Option.none => throw "PSKERNEL_V2_LIFT_INVALID_ROOT"
  let initial : PsKernelExprV2LiftState := {
    arena := source
    memo := []
  }
  let (state,newRoot) ←
    psKernelExprV2LiftWithFuel (rootEntry.depth+1)
      initial root cutoff amount
  let _ ← psKernelExprV2ValidateChunked state.arena
  return (state.arena,newRoot)
