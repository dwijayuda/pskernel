import Ps.KernelCore.Architecture.DeepSubstitutionTape

/-!
Native source-level regression for deferred capture-avoiding substitution.
All results are computed from the SAME original source expression and
ordered operations; no proof admission, source fuel or logical axiom changes.
-/

def c0DeepSubstSamples : List PsKernelExpr := Id.run do
  let a : PsKernelName := .str .anonymous "a"
  let b : PsKernelName := .str .anonymous "b"
  return [
    .bvar 0,
    .bvar 1,
    .bvar 4,
    .sort .zero,
    .fvar a,
    .app (.bvar 1) (.bvar 0),
    .app (.app (.bvar 3) (.bvar 0)) (.bvar 2),
    .lam a (.sort .zero) (.app (.bvar 1) (.bvar 0)) .default,
    .forallE a (.sort .zero) (.app (.bvar 2) (.bvar 0)) .implicit,
    .letE b (.sort .zero) (.bvar 0) (.app (.bvar 1) (.bvar 0)) false,
    .mdata 17 (.proj b 0 (.app (.bvar 2) (.bvar 0)))
  ]

def main : IO Unit := do
  let a : PsKernelName := .str .anonymous "a"
  let operations : List PsKernelC0DeepSubstOperation := [
    ⟨.fvar a, 0⟩,
    ⟨.bvar 1, 1⟩,
    ⟨.sort .zero, 2⟩,
    ⟨.app (.bvar 1) (.bvar 0), 0⟩
  ]
  let mut samples := 0
  for expr in c0DeepSubstSamples do
    for n in [:operations.length + 1] do
      let selected := operations.take n
      let tape := selected.foldl psKernelC0DeepSubstPush
        (psKernelC0DeepSubstPure expr)
      let source := selected.foldl psKernelC0DeepSubstApply expr
      let actual := psKernelC0DeepSubstForce tape
      if !psKernelExprEqual source actual then
        throw (IO.userError "deferred sequence diverged from source order")
      samples := samples + 1
    for fresh in [a, .str .anonymous "fresh"] do
      for ranges in [[], [0], [1], [2], [0, 1], [3, 0]] do
        let deferred := psKernelC0DeepDeferBinderOpening expr fresh ranges
        let source := psKernelC0DeepEagerBinderOpening expr fresh ranges
        if !psKernelExprEqual
             (psKernelC0DeepSubstForce deferred.1) source.1 ||
           deferred.2 != source.2 then
          throw (IO.userError "deferred binder opening diverged from source")
        samples := samples + 1
  IO.println s!"C0_DEEP_SUBST source_order_and_binder_ranges=exact cases={samples}"
