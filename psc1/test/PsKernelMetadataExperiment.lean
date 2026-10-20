import Ps.KernelCore.SelfHost

/-
Experimental checked metadata carried beside existing PSC1 Expr values.
NO production expression constructor, checker rule, acceptance path, or
self-hosted source profile is changed. A hypothetical future expression
representation could retain these fields at each node and validate its
smart constructors before relying on them.

Metadata here is only an optimization experiment; it is NEVER an authority
for admitting definitions or skipping kernel checks.
-/
private structure DemoExprMeta where
  expr : PsKernelExpr
  hash : Nat
  hasFVar : Bool
  looseRange : Nat

private def demoBVar (index : Nat) : DemoExprMeta :=
  { expr := PsKernelExpr.bvar index
    hash := psKernelCacheMix 21 index
    hasFVar := false
    looseRange := Nat.succ index }

private def demoSort (level : PsKernelLevel) : DemoExprMeta :=
  { expr := PsKernelExpr.sort level
    hash := psKernelCacheMix 24 (psKernelCacheLevelHash level)
    hasFVar := false
    looseRange := 0 }

private def demoFVar (name : PsKernelName) : DemoExprMeta :=
  { expr := PsKernelExpr.fvar name
    hash := psKernelCacheMix 22 (psKernelCacheNameHash name)
    hasFVar := true
    looseRange := 0 }

private def demoApp (fn arg : DemoExprMeta) : DemoExprMeta :=
  { expr := PsKernelExpr.app fn.expr arg.expr
    hash := psKernelCacheMix (psKernelCacheMix 26 fn.hash) arg.hash
    hasFVar := if fn.hasFVar then true else arg.hasFVar
    looseRange := Nat.max fn.looseRange arg.looseRange }

private def demoLam (name : PsKernelName)
    (domain body : DemoExprMeta) (bi : PsKernelBinderInfo) : DemoExprMeta :=
  { expr := PsKernelExpr.lam name domain.expr body.expr bi
    hash := psKernelCacheMix (psKernelCacheMix 27 domain.hash) body.hash
    hasFVar := if domain.hasFVar then true else body.hasFVar
    looseRange := Nat.max domain.looseRange (Nat.sub body.looseRange 1) }

private def demoLet (name : PsKernelName)
    (type value body : DemoExprMeta) (nondep : Bool) : DemoExprMeta :=
  let flag := if nondep then 1 else 0
  { expr := PsKernelExpr.letE name type.expr value.expr body.expr nondep
    hash := psKernelCacheMix
      (psKernelCacheMix
        (psKernelCacheMix
          (psKernelCacheMix 29 type.hash) value.hash) body.hash)
      flag
    hasFVar := if type.hasFVar then true else
      if value.hasFVar then true else body.hasFVar
    looseRange := Nat.max
      (Nat.max type.looseRange value.looseRange)
      (Nat.sub body.looseRange 1) }

private def demoSpine (depth : Nat) : DemoExprMeta :=
  match depth with
  | Nat.zero => demoBVar 0
  | Nat.succ remaining => demoApp (demoSpine remaining) (demoBVar 1)

private def originalSpine (depth : Nat) : PsKernelExpr :=
  match depth with
  | Nat.zero => PsKernelExpr.bvar 0
  | Nat.succ remaining =>
      PsKernelExpr.app (originalSpine remaining) (PsKernelExpr.bvar 1)

private def validate (label : String) (cached : DemoExprMeta) : IO Unit := do
  unless cached.hash == psKernelExprHash cached.expr &&
      cached.hasFVar == psKernelExprHasFVar cached.expr &&
      (cached.looseRange > 0) == psKernelExprHasLooseBVar cached.expr do
    throw (IO.userError s!"EXPR_METADATA_INVARIANT_FAILED: {label}")
  IO.println s!"PSC1_METADATA_INVARIANT PASS: {label}"

private def bench (operation : String) (depth calls : Nat)
    (query : Nat → Nat) : IO Unit := do
  let mut checksum : Nat := 0
  let start ← IO.monoMsNow
  for i in [:calls] do
    checksum := checksum + query i
  let stop ← IO.monoMsNow
  IO.println s!"PSC1_METADATA_NATIVE operation={operation} depth={depth} calls={calls} ms={stop-start} checksum={checksum}"

private def testDepth (depth : Nat) : IO Unit := do
  let cached := demoSpine depth
  let original := originalSpine depth
  validate s!"application-depth-{depth}" cached
  unless psKernelExprEq cached.expr original do
    throw (IO.userError "EXPR_METADATA_SOURCE_SHAPE_CHANGED")
  let calls := 12000
  bench "raw_hash" depth calls (fun _ => psKernelExprHash original)
  bench "computed_hash" depth calls (fun _ => cached.hash)
  bench "raw_has_fvar" depth calls
    (fun _ => if psKernelExprHasFVar original then 1 else 0)
  bench "computed_has_fvar" depth calls
    (fun _ => if cached.hasFVar then 1 else 0)
  bench "raw_has_bvar" depth calls
    (fun _ => if psKernelExprHasLooseBVar original then 1 else 0)
  bench "computed_has_bvar" depth calls
    (fun _ => if cached.looseRange > 0 then 1 else 0)

def main : IO Unit := do
  let name := PsKernelName.str PsKernelName.anonymous "metaLocal"
  let sort0 := demoSort PsKernelLevel.zero
  let sort1 := demoSort (PsKernelLevel.succ PsKernelLevel.zero)
  let bound := demoBVar 0
  validate "bound-variable-zero" bound
  validate "sort-zero" sort0
  validate "lambda-closed" (demoLam name sort0 bound PsKernelBinderInfo.default)
  validate "let-binder-closed" (demoLet name sort1 sort0 bound false)
  validate "let-binder-open" (demoLet name sort1 (demoBVar 2) (demoBVar 3) true)
  validate "free-variable-app" (demoApp (demoFVar name) sort0)
  testDepth 32
  testDepth 128
  testDepth 512
  IO.println "PSC1_METADATA_NATIVE: COMPLETE"
