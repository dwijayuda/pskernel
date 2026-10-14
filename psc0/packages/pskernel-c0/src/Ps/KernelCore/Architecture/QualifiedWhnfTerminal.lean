import Ps.KernelCore.Architecture.QualifiedContextualWhnf

/-!
E.4AG: one shared, source-proved WHNF terminal fragment.

Official Lean 4.35 src/kernel/type_checker.cpp::whnf_core returns
BVar/Sort/MVar/Pi/Lambda/Lit immediately. The *public* pipeline then
tries Nat primitives and delta. These six heads are inert in that
post-core pipeline: they require no extra recursive evaluation, and
the full checker state remains unchanged until the enclosing
application/let writes its own exact core/public cache entries.

Constants are deliberately excluded (delta), local FVars are
contextual, and applications/projections/lets/metadata may reduce.
A terminal match is ONLY a normalization fact, not a typing verdict
or authorization to admit proof terms.
-/

/-- WHNF-core and post-core terminal forms, for both one-step beta and
    zeta. Sharing this boundary prevents drift between their independent
    source-equivalence proofs. -/
def psKernelC0StableWhnfTerminal : PsKernelExpr → Bool
  | .bvar _ => true
  | .sort _ => true
  | .mvar _ => true
  | .forallE _ _ _ _ => true
  | .lam _ _ _ _ => true
  | .lit _ => true
  | _ => false

/-- Any supported terminal consumes exactly one nonzero core fuel and
    checks the same context recursion depth as the original C0 WHNF,
    but does not touch either source cache, invoke publicWhnf, or
    depend on a recursor callback. -/
theorem psKernelC0StableWhnfTerminal_core
    (remaining : Nat)
    (publicWhnf :
      PsKernelCheckerContext → PsKernelCheckerState → PsKernelExpr →
        Except String (PsKernelExpr × PsKernelCheckerState))
    (reduceRecursor :
      PsKernelCheckerContext → PsKernelCheckerState → PsKernelExpr →
        Bool → Bool →
        Except String (Option PsKernelExpr × PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (expr : PsKernelExpr)
    (entered : PsKernelCheckerContext)
    (hdepth : psKernelCheckerContextEnterRecDepth context = .ok entered)
    (hterm : psKernelC0StableWhnfTerminal expr = true) :
    psKernelWhnfCoreWithFuelRanges (Nat.succ remaining) []
      publicWhnf reduceRecursor context state expr false false =
        .ok (expr, state) := by
  cases expr <;>
    simp [psKernelC0StableWhnfTerminal] at hterm <;>
    simp [psKernelWhnfCoreWithFuelRanges, hdepth]

/-- Nat and delta can never rewrite a terminal. This equation is about
    the entire source post-core operation; the enclosing expression's
    public cache insertion still happens through psKernelWhnfFinish. -/
theorem psKernelC0StableWhnfTerminal_post
    (publicWhnf :
      PsKernelCheckerContext → PsKernelCheckerState → PsKernelExpr →
        Except String (PsKernelExpr × PsKernelCheckerState))
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (original expr : PsKernelExpr)
    (hterm : psKernelC0StableWhnfTerminal expr = true) :
    psKernelWhnfAfterCore publicWhnf context state original expr =
      psKernelWhnfFinish original expr state := by
  cases expr <;>
    simp [psKernelC0StableWhnfTerminal] at hterm <;>
    simp [psKernelWhnfAfterCore, psKernelReduceNatWith,
      psKernelUnfoldDefinition, psKernelExprGetAppFn]
