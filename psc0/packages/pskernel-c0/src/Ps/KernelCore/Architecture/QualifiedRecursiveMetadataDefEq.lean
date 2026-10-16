import Ps.KernelCore.Architecture.QualifiedRecursiveDeltaWhnf

/-!
E.4AJ: one genuinely recursive, independently evaluated metadata DefEq
family, with source-level/Sort/Nat/String literal terminal judgments.

Pinned upstream Lean 4.35:
  src/kernel/type_checker.cpp::{quick_is_def_eq,is_def_eq_core}
Pinned source checker:
  Checker/Knot.lean::psKernelIsDefEqWithFuel
  Checker/DefEq/Quick.lean::psKernelDefEqQuickAfterCommon

For two metadata expressions Lean's quick DefEq strips one wrapper
and recursively compares their bodies, on the ORIGINAL decreasing
DefEq fuel and entered recursion context. Successful recursion then
publishes the source positive-result pair cache at each outer level.
This independently implements that whole family, including nested
metadata, multiple non-syntactically-equivalent Sort levels, Nat/
String literals, structural reflexivity, prior source cache hits and
exact state threading. It never calls the original recursive DefEq
worker when its full-source result theorem is selected.

A false conversion result does not assert either input is type-correct.
Declines, exhausted resources, unqualified term constructors, and all
other algorithmic DefEq cases retain exact original source behavior.
-/

/-- One independent source-proved terminal family for recursive DefEq.
    Reuse the previously certified Sort, Nat/String-literal and
    structurally reflexive source fragments, not the source DefEq worker. -/
def psKernelC0MetadataDefEqLeafWithFuel
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr) :
    Option (Bool × PsKernelCheckerState) :=
  match left, right with
  | .sort lhs, .sort rhs =>
      psKernelC0SortDefEqWithFuel fuel context state lhs rhs
  | .lit lhs, .lit rhs =>
      psKernelC0LiteralDefEqWithFuel fuel context state lhs rhs
  | _, _ =>
      psKernelC0DefEqReflexiveWithFuel fuel context state left right

/-- Complete original DefEq result, success-cache state and resource
    handling for any independently computed terminal result. -/
theorem psKernelC0MetadataDefEqLeaf_source
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (result : Bool × PsKernelCheckerState)
    (h : psKernelC0MetadataDefEqLeafWithFuel fuel context state
      left right = some result) :
    psKernelIsDefEq fuel context state left right = .ok result := by
  cases left <;> cases right <;>
    simp only [psKernelC0MetadataDefEqLeafWithFuel] at h
  all_goals
    first
      | exact psKernelC0SortDefEq_source
          fuel context state _ _ result h
      | exact psKernelC0LiteralDefEq_source
          fuel context state _ _ result h
      | exact psKernelC0DefEqReflexive_source
          fuel context state _ _ result h

/-- A single recursively evaluated metadata DefEq engine. The source
    quick paths are checked in source order: fuel/depth, syntactic
    reflexivity, successful-pair cache, metadata recursion, other leaf
    fragments. A cache hit preserves state, while each successful
    recursive outer judgment uses the original positive-only finish. -/
def psKernelC0RecursiveMetadataDefEqWithFuel :
    Nat → PsKernelCheckerContext → PsKernelCheckerState →
      PsKernelExpr → PsKernelExpr →
        Option (Bool × PsKernelCheckerState)
  | 0, _, _, _, _ => none
  | Nat.succ remaining, context, state, left, right =>
      match left, right with
      | .mdata _ leftBody, .mdata _ rightBody =>
          match psKernelCheckerContextEnterRecDepth context with
          | .error _ => none
          | .ok entered =>
              if psKernelExprEq left right then
                some (psKernelDefEqFinish state left right true)
              else if psKernelSemanticPairCacheEligible left right &&
                  psKernelExprPairSetContains state.success left right then
                some (true, state)
              else
                match psKernelC0RecursiveMetadataDefEqWithFuel
                    remaining entered state leftBody rightBody with
                | none => none
                | some (equal, after) =>
                    some (psKernelDefEqFinish after left right equal)
      | _, _ =>
          psKernelC0MetadataDefEqLeafWithFuel
            (Nat.succ remaining) context state left right

/-- Strong-fuel source refinement for every successful independent
    metadata subtree and terminal. This is the ENTIRE original
    algorithmic conversion result and checker cache/state, not only
    Boolean equality. Recursion uses source's entered context and
    remaining DefEq fuel exactly. -/
theorem psKernelC0RecursiveMetadataDefEq_source
    (fuel : Nat)
    (context : PsKernelCheckerContext)
    (state : PsKernelCheckerState)
    (left right : PsKernelExpr)
    (result : Bool × PsKernelCheckerState)
    (h : psKernelC0RecursiveMetadataDefEqWithFuel
      fuel context state left right = some result) :
    psKernelIsDefEq fuel context state left right = .ok result := by
  induction fuel generalizing context state left right result with
  | zero =>
      simp [psKernelC0RecursiveMetadataDefEqWithFuel] at h
  | succ remaining ih =>
      cases left <;> cases right
      all_goals
        try
          exact psKernelC0MetadataDefEqLeaf_source
            (Nat.succ remaining) context state _ _ result
            (by simpa only [psKernelC0RecursiveMetadataDefEqWithFuel] using h)
      -- Only the real recursive (metadata,metadata) constructor remains.
      rename_i leftMeta leftBody rightMeta rightBody
      let leftTerm : PsKernelExpr := .mdata leftMeta leftBody
      let rightTerm : PsKernelExpr := .mdata rightMeta rightBody
      cases depth : psKernelCheckerContextEnterRecDepth context with
      | error reason =>
          simp [psKernelC0RecursiveMetadataDefEqWithFuel,
            depth, leftTerm, rightTerm] at h
      | ok entered =>
          by_cases same : psKernelExprEq leftTerm rightTerm = true
          · have hr : result =
                psKernelDefEqFinish state leftTerm rightTerm true := by
              have hx :
                  some (psKernelDefEqFinish state leftTerm rightTerm true) =
                    some result := by
                simpa [psKernelC0RecursiveMetadataDefEqWithFuel,
                  depth, same, leftTerm, rightTerm] using h
              exact (Option.some.inj hx).symm
            rw [hr]
            change psKernelIsDefEqWithFuel (Nat.succ remaining)
              context state leftTerm rightTerm =
                .ok (psKernelDefEqFinish state leftTerm rightTerm true)
            simp [psKernelIsDefEqWithFuel, psKernelDefEqSourceStepWithFuel,
              depth, same,
              leftTerm, rightTerm]
          · by_cases cached :
                (psKernelSemanticPairCacheEligible leftTerm rightTerm &&
                  psKernelExprPairSetContains state.success
                    leftTerm rightTerm) = true
            · have hr : result = (true, state) := by
                have hx : some (true, state) = some result := by
                  simpa [psKernelC0RecursiveMetadataDefEqWithFuel,
                    depth, same, cached, leftTerm, rightTerm] using h
                exact (Option.some.inj hx).symm
              rw [hr]
              change psKernelIsDefEqWithFuel (Nat.succ remaining)
                context state leftTerm rightTerm = .ok (true, state)
              simp [psKernelIsDefEqWithFuel, psKernelDefEqSourceStepWithFuel,
              depth, same, Bool.and_eq_true, cached,
                leftTerm, rightTerm]
            · cases child :
                  psKernelC0RecursiveMetadataDefEqWithFuel
                    remaining entered state leftBody rightBody with
              | none =>
                  simp [psKernelC0RecursiveMetadataDefEqWithFuel,
                    depth, same, cached, child, leftTerm, rightTerm] at h
              | some childResult =>
                  rcases childResult with ⟨equal, nextState⟩
                  let finalized :=
                    psKernelDefEqFinish nextState
                      leftTerm rightTerm equal
                  have hr : result = finalized := by
                    have hx : some finalized = some result := by
                      simpa [psKernelC0RecursiveMetadataDefEqWithFuel,
                        depth, same, cached, child,
                        leftTerm, rightTerm, finalized] using h
                    exact (Option.some.inj hx).symm
                  have sourceChild :
                      psKernelIsDefEqWithFuel remaining entered state
                        leftBody rightBody = .ok (equal, nextState) :=
                    ih entered state leftBody rightBody
                      (equal, nextState) child
                  rw [hr]
                  change psKernelIsDefEqWithFuel (Nat.succ remaining)
                    context state leftTerm rightTerm = .ok finalized
                  -- Expand the outer DefEq rule once, NOT its
                  -- recursively proved metadata child.
                  rw [psKernelIsDefEqWithFuel]
                  simp [psKernelDefEqSourceStepWithFuel,
                    depth, same, Bool.and_eq_true, cached,
                    psKernelDefEqQuickAfterCommon, sourceChild,
                    finalized, leftTerm, rightTerm]

/-- Source-exact dependent checked-work result for recursive metadata
    DefEq. No raw user cache verdict can bypass certified work genesis,
    and the original source admission remains independent. -/
theorem psKernelC0RecursiveMetadataDefEq_certified
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (left right : PsKernelExpr)
    (result : Bool × PsKernelCheckerState)
    (h : psKernelC0RecursiveMetadataDefEqWithFuel fuel
      work.raw.checker.context work.raw.checker.state
      left right = some result) :
    psKernelC0CertifiedWorkDefEq fuel work left right =
      .ok (result.fst,
        (psKernelC0CertifiedWorkWithStateOwned work result.snd).val) := by
  have source :
      psKernelIsDefEq fuel work.raw.checker.context
        work.raw.checker.state left right = .ok result :=
    psKernelC0RecursiveMetadataDefEq_source
      fuel work.raw.checker.context work.raw.checker.state
      left right result h
  rcases result with ⟨equal, nextState⟩
  unfold psKernelC0CertifiedWorkDefEq psKernelSessionIsDefEq
  simp only [source]
  rfl

/-- One source-proved DefEq dispatch, with the recursive metadata path
    ahead of the existing Sort/Literal/reflexive source fragments.
    Declined or failed source operations retain exact original
    diagnostics, state and resource classification. -/
def psKernelC0CertifiedWorkDefEqRecursiveMetadataOwned
    (fuel : Nat)
    (work : PsKernelC0CertifiedWork)
    (left right : PsKernelExpr) :
    Except String
      { result : Bool × PsKernelC0CertifiedWork //
        psKernelC0CertifiedWorkDefEq fuel work left right = .ok result } :=
  match h : psKernelC0RecursiveMetadataDefEqWithFuel fuel
      work.raw.checker.context work.raw.checker.state
      left right with
  | none =>
      psKernelC0CertifiedWorkDefEqQualifiedOwned fuel work left right
  | some result =>
      .ok ⟨(result.fst,
        (psKernelC0CertifiedWorkWithStateOwned
          work result.snd).val),
        psKernelC0RecursiveMetadataDefEq_certified
          fuel work left right result h⟩
