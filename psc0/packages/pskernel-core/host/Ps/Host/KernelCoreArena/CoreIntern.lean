import PSC1Kernel.ReplayJson
import Ps.KernelCore.API.Kernel

namespace PsKernelCoreArena.CoreIntern

/-
Host-only lean4export adapter state.

This table stores PSKernel names, levels, and expressions incrementally by
lean4export index. It preserves the export DAG's sharing so declarations can
reference already-converted PSKernel terms in O(1) instead of recursively
rebuilding entire expression trees. It does not perform kernel acceptance.
-/
structure State where
  names : PSC1Kernel.Replay.IndexTable PsKernelName
  levels : PSC1Kernel.Replay.IndexTable PsKernelLevel
  exprs : PSC1Kernel.Replay.IndexTable PsKernelExpr

def State.empty : State :=
  {
    names := PSC1Kernel.Replay.IndexTable.seed #[PsKernelName.anonymous]
    levels := PSC1Kernel.Replay.IndexTable.seed #[PsKernelLevel.zero]
    exprs := PSC1Kernel.Replay.IndexTable.empty
  }

def State.nameAt (state : State) (index : Nat) : Except String PsKernelName :=
  match state.names.get? index with
  | some value => .ok value
  | none => .error "lean4export Name reference is undefined"

def State.levelAt (state : State) (index : Nat) : Except String PsKernelLevel :=
  match state.levels.get? index with
  | some value => .ok value
  | none => .error "lean4export Level reference is undefined"

def State.exprAt (state : State) (index : Nat) : Except String PsKernelExpr :=
  match state.exprs.get? index with
  | some value => .ok value
  | none => .error "lean4export Expr reference is undefined"

def State.resolveLevels (state : State) : List Nat → Except String (List PsKernelLevel)
  | [] => pure []
  | index :: rest => do
      let level ← state.levelAt index
      let tail ← state.resolveLevels rest
      pure (level :: tail)

def State.addNameRecord
    (state : State)
    (record : PSC1Kernel.Replay.NameRecord) : Except String State := do
  let value ←
    match record.node with
    | .str parent text => pure (.str (← state.nameAt parent) text)
    | .num parent value => pure (.num (← state.nameAt parent) value)
  let names ← state.names.add "Name" record.index value
  pure { state with names := names }

def State.addLevelRecord
    (state : State)
    (record : PSC1Kernel.Replay.LevelRecord) : Except String State := do
  let value ←
    match record.node with
    | .succ parent => pure (.succ (← state.levelAt parent))
    | .max left right => pure (.max (← state.levelAt left) (← state.levelAt right))
    | .imax left right => pure (.imax (← state.levelAt left) (← state.levelAt right))
    | .param name => pure (.param (← state.nameAt name))
  let levels ← state.levels.add "Level" record.index value
  pure { state with levels := levels }

def binderInfo : PSC1Kernel.BinderInfo → PsKernelBinderInfo
  | .default => .default
  | .implicit => .implicit
  | .strictImplicit => .strictImplicit
  | .instImplicit => .instImplicit

def State.addExprRecord
    (state : State)
    (record : PSC1Kernel.Replay.ExprRecord) : Except String State := do
  let value ←
    match record.node with
    | .bvar index => pure (.bvar index)
    | .sort level => pure (.sort (← state.levelAt level))
    | .const name levels =>
        pure (.const (← state.nameAt name) (← state.resolveLevels levels))
    | .app fn arg => pure (.app (← state.exprAt fn) (← state.exprAt arg))
    | .lam name type body info =>
        pure (.lam (← state.nameAt name) (← state.exprAt type)
          (← state.exprAt body) (binderInfo info))
    | .forallE name type body info =>
        pure (.forallE (← state.nameAt name) (← state.exprAt type)
          (← state.exprAt body) (binderInfo info))
    | .letE name type value body nondep =>
        pure (.letE (← state.nameAt name) (← state.exprAt type)
          (← state.exprAt value) (← state.exprAt body) nondep)
    | .proj typeName index struct =>
        pure (.proj (← state.nameAt typeName) index (← state.exprAt struct))
    | .natVal value => pure (.lit (.nat value))
    | .strVal value => pure (.lit (.str value))
    | .mdata metadata expr => pure (.mdata metadata (← state.exprAt expr))
  let exprs ← state.exprs.add "Expr" record.index value
  pure { state with exprs := exprs }

end PsKernelCoreArena.CoreIntern
