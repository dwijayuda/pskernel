import Ps.Kernel.Data
import Ps.Kernel.Natural

/- Owned expressions. fvars are internal; closed admission will reject them.
No metavariables, metadata authority, or caller-provided reduction rules. -/
inductive PsKernelBinder where
  | explicit
  | implicit
  | strictImplicit
  | instanceImplicit

inductive PsKernelLiteral where
  | natural (value : PsKernelNatural)
  | text (value : PsKernelText)

inductive PsKernelExpr where
  | bvar (index : PsKernelNatural)
  | fvar (id : PsKernelNatural)
  | sortE (level : PsKernelLevel)
  | constE (name : PsKernelName) (levels : PsKernelList PsKernelLevel)
  | app (fn : PsKernelExpr) (arg : PsKernelExpr)
  | lam (name : PsKernelName) (type : PsKernelExpr) (body : PsKernelExpr) (binder : PsKernelBinder)
  | forallE (name : PsKernelName) (type : PsKernelExpr) (body : PsKernelExpr) (binder : PsKernelBinder)
  | letE (name : PsKernelName) (type : PsKernelExpr) (value : PsKernelExpr) (body : PsKernelExpr)
  | lit (value : PsKernelLiteral)
  | proj (family : PsKernelName) (index : PsKernelNatural) (value : PsKernelExpr)

inductive PsKernelBindingMode where
  | lift (amount : PsKernelNatural)
  | instantiate (replacement : PsKernelExpr)
  | abstract (id : PsKernelNatural)
  | closed

inductive PsKernelBindingTask where
  | visit (mode : PsKernelBindingMode) (depth : PsKernelNatural) (value : PsKernelExpr)
  | orderIndex (mode : PsKernelBindingMode) (depth : PsKernelNatural) (index : PsKernelNatural) (state : PsKernelNumericState)
  | orderFree (depth : PsKernelNatural) (id : PsKernelNatural) (state : PsKernelNumericState)
  | sumIndex (state : PsKernelNumericState)
  | app
  | lam (name : PsKernelName) (binder : PsKernelBinder)
  | forallE (name : PsKernelName) (binder : PsKernelBinder)
  | letE (name : PsKernelName)
  | proj (family : PsKernelName) (index : PsKernelNatural)

inductive PsKernelBindingState where
  | state (tasks : PsKernelList PsKernelBindingTask) (values : PsKernelList PsKernelExpr)

inductive PsKernelBindingResult where
  | outOfFuel
  | invalidState
  | invalidScope
  | done (value : PsKernelExpr)

inductive PsKernelBindingStep where
  | next (state : PsKernelBindingState)
  | final (result : PsKernelBindingResult)
