import Ps.KernelCore.Checker.Reduction.Whnf

/-!
The complete Option-valued WHNF cache lookup is re-ordered, not changed.
Every possible expression and cache lookup result has an all-input theorem
in CachePolicy. These concrete native cases also verify that a forged
FVar-positive cache hit is discarded and a cache miss cannot be a proof.
-/

def c0LookupShared : Nat → PsKernelExpr → PsKernelExpr
  | 0, expr => expr
  | n + 1, expr =>
      let previous := c0LookupShared n expr
      .app previous previous

def main : IO Unit := do
  let name : PsKernelName := .str .anonymous "scope"
  let atom : PsKernelExpr := .const name []
  let bound : PsKernelExpr := .fvar name
  let cases : List PsKernelExpr := [
    .bvar 0, .sort .zero, atom, .lit (.nat 0),
    bound, .mvar name, .app bound atom,
    .app atom bound, .lam name atom bound .default,
    .forallE name atom bound .default,
    .letE name atom bound (.bvar 0) false,
    .mdata 0 bound, .proj name 0 bound,
    c0LookupShared 8 atom, c0LookupShared 8 bound
  ]
  let lookups : List (Option Nat) := [none, some 0, some 197]
  for expr in cases do
    for rawHit in lookups do
      let old := if psKernelSemanticCacheEligible expr then rawHit else none
      let new := psKernelC0LookupBeforeEligibility expr rawHit
      if new != old then
        throw (IO.userError "WHNF lookup order changed source result")
  if psKernelC0LookupBeforeEligibility bound (some 197 : Option Nat) != none then
    throw (IO.userError "free-variable hit leaked across local context")
  if psKernelC0LookupBeforeEligibility atom (none : Option Nat) != none then
    throw (IO.userError "cache miss forged an acceptance")
  IO.println "C0_WHNF_LOOKUP_FIRST cases=15 raw_hit_variants=3 source_all_input=Lean_proved FVar_scope_hit_denied=true no_admission=true"
