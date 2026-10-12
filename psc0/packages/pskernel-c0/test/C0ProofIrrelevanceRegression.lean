import Ps.KernelCore.Admission.Declaration.Admission
import Ps.KernelCore.Checker.Reduction.IndexedWhnf
import Ps.KernelCore.Runtime.Acceleration.EnvironmentIndex
import Ps.KernelCore.Checker.Session
import Ps.KernelCore.Checker.IndexedSession

/- Native checker regression only. No bootstrap or self-host tests.
   The old metatheory equated arbitrary terms, while the executable
   conversion checker must reject distinct universe sorts. -/


/- Before the lazy-spine refactor: differential oracles only. These are
   deliberately not used by the accepting checker. -/
def c0ReferenceReduceProjCore
    (context : PsKernelCheckerContext)
    (typeName : PsKernelName)
    (index : Nat)
    (structValue : PsKernelExpr) :
    Option PsKernelExpr :=
  if psKernelNatGt index psKernelLeanUInt32Max then
    Option.none
  else
    let fn :=
      psKernelExprGetAppFn structValue;
    let args :=
      psKernelExprGetAppArgs structValue;
    match fn with
    | PsKernelExpr.const ctorName _ =>
        match
            psKernelEnvironmentFind
              context.environment
              ctorName with
        | Option.some info =>
            match info with
            | PsKernelConstantInfo.ctorInfo ctor =>
                if
                    psKernelNameEq
                      ctor.induct
                      typeName then
                  psKernelExprListGet
                    args
                    (Nat.add
                      ctor.numParams
                      index)
                else
                  Option.none
            | _ =>
                Option.none
        | Option.none =>
            Option.none
    | _ =>
        Option.none


def c0ReferenceUnfoldDefinition
    (context : PsKernelCheckerContext)
    (expr : PsKernelExpr) :
    Option PsKernelExpr :=
  let fn :=
    psKernelExprGetAppFn expr;
  let args :=
    psKernelExprGetAppArgs expr;
  match fn with
  | PsKernelExpr.const name levels =>
      match
          psKernelEnvironmentFind
            context.environment
            name with
      | Option.none =>
          Option.none
      | Option.some info =>
          match
              psKernelConstantInfoDeltaValue info with
          | Option.none =>
              Option.none
          | Option.some value =>
              let params :=
                psKernelConstantInfoLevelParams info;
              if
                  Nat.beq
                    (psKernelNameListLength params)
                    (psKernelLevelListLength levels) then
                Option.some
                  (psKernelApplyArgs
                    (psKernelExprInstantiateLevelParams
                      value
                      params
                      levels)
                    args)
              else
                Option.none
  | _ =>
      Option.none


/-- Prebuilt well-typed lambda spine with every binder domain Sort 1. -/
def c0CheckedSpineFixture : Nat → PsKernelExpr
  | 0 => PsKernelExpr.bvar 0
  | n + 1 =>
      PsKernelExpr.lam PsKernelName.anonymous
        (PsKernelExpr.sort (.succ PsKernelLevel.zero))
        (c0CheckedSpineFixture n) PsKernelBinderInfo.default

def c0RegressionForalls : Nat → PsKernelExpr
  | 0 => .sort PsKernelLevel.zero
  | n + 1 =>
      .forallE PsKernelName.anonymous
        (.sort (.succ PsKernelLevel.zero))
        (c0RegressionForalls n) PsKernelBinderInfo.default

def c0RegressionDependentPi (n : Nat) : PsKernelExpr :=
  .forallE PsKernelName.anonymous (.sort (.succ PsKernelLevel.zero))
    (.forallE PsKernelName.anonymous (.bvar 0)
      (c0RegressionForalls n) PsKernelBinderInfo.default)
    PsKernelBinderInfo.default

def c0RegressionApps : Nat → PsKernelExpr → PsKernelExpr → PsKernelExpr
  | 0, fn, _ => fn
  | n + 1, fn, arg => c0RegressionApps n (.app fn arg) arg

/-- Exact closed/open binder-range oracles. The existing independent
    loose-variable syntax predicate is used at every nested body position. -/
def c0BinderForallTail : Nat → PsKernelExpr → PsKernelExpr
  | 0, term => term
  | n + 1, term =>
      .forallE PsKernelName.anonymous
        (.sort (.succ PsKernelLevel.zero))
        (c0BinderForallTail n term) PsKernelBinderInfo.default

def c0BinderLambdaTail : Nat → PsKernelExpr → PsKernelExpr
  | 0, term => term
  | n + 1, term =>
      .lam PsKernelName.anonymous
        (.sort (.succ PsKernelLevel.zero))
        (c0BinderLambdaTail n term) PsKernelBinderInfo.default

/-- Two nested dependent Pi binder domains. The innermost binder
    refers past the middle binder to the outermost binder (bvar 1). -/
def c0BinderDependentPair (width : Nat) (annotate : Bool) :
    PsKernelExpr :=
  let innerDomain :=
    if annotate then PsKernelExpr.mdata 71 (PsKernelExpr.bvar 1)
    else PsKernelExpr.bvar 1
  PsKernelExpr.forallE PsKernelName.anonymous
    (PsKernelExpr.sort (.succ PsKernelLevel.zero))
    (PsKernelExpr.forallE PsKernelName.anonymous
      (PsKernelExpr.sort (.succ PsKernelLevel.zero))
      (PsKernelExpr.forallE PsKernelName.anonymous
        innerDomain
        (c0BinderForallTail width
          (PsKernelExpr.sort PsKernelLevel.zero))
        PsKernelBinderInfo.default)
      PsKernelBinderInfo.default)
    PsKernelBinderInfo.default

/-- Long source let/zeta spine used only by negative and WHNF regression. -/
def c0ZetaFixture : Nat → PsKernelExpr → PsKernelExpr
  | 0, leaf => leaf
  | n + 1, leaf =>
      .letE PsKernelName.anonymous
        (.sort (.succ PsKernelLevel.zero))
        (.sort PsKernelLevel.zero)
        (c0ZetaFixture n leaf) false

def main : IO Unit := do
  let session :=
    psKernelMkCheckerSession
      psKernelEnvironmentEmpty
      []
      PsKernelDefinitionSafety.safe
      4096
      psKernelLeanNatMaxSizeDefault
  let sort0 := PsKernelExpr.sort PsKernelLevel.zero
  let sort1 := PsKernelExpr.sort (PsKernelLevel.succ PsKernelLevel.zero)
  -- Exact body-range oracle and actual WHNF for long let chains.
  -- A syntax summary is never allowed to authorize ill-typed checking.
  for depth in [1, 12, 24, 48, 96] do
    for leaf in [sort0, PsKernelExpr.bvar 0, PsKernelExpr.bvar 5] do
      match psKernelC0LetCacheFramesWithFuel 1024
          (c0ZetaFixture depth leaf) with
      | none => throw (IO.userError "C0 zeta summary unexpectedly absent")
      | some (_, _, ranges) =>
          let mut current := c0ZetaFixture depth leaf
          let mut tail := ranges
          for _ in [:depth] do
            match current, tail with
            | .letE _ _ _ body _, (range, _) :: rest =>
                for cutoff in [:8] do
                  if (range > cutoff) != psKernelExprHasLooseAt body cutoff then
                    throw (IO.userError "C0 zeta range differs from oracle")
                current := body
                tail := rest
            | _, _ => throw (IO.userError "C0 zeta ranges misaligned")
          if !tail.isEmpty then
            throw (IO.userError "C0 zeta ranges contain excess entries")
    match psKernelSessionWhnf 4096 session (c0ZetaFixture depth sort0) with
    | Except.ok (result, _) =>
        if !psKernelExprEqual result sort0 then
          throw (IO.userError "C0 closed zeta WHNF changed result")
    | Except.error err =>
        throw (IO.userError ("C0 closed zeta WHNF failed: " ++ err))
  -- An innermost de Bruijn variable reaching the *outermost* let
  -- exercises real substitution and invalidation of all suffix metadata.
  for depth in [1, 12, 24, 64] do
    let dependentTerm := c0ZetaFixture depth (.bvar (depth - 1))
    match psKernelSessionWhnf 4096 session dependentTerm with
    | Except.ok (result, _) =>
        if !psKernelExprEqual result sort0 then
          throw (IO.userError "C0 dependent zeta WHNF skipped substitution")
    | Except.error err =>
        throw (IO.userError ("C0 dependent zeta WHNF failed: " ++ err))
  IO.println "C0_PERF_REGRESSION dependent_zeta_substitution=pass"
  if (psKernelC0LetCacheFramesWithFuel 1
      (c0ZetaFixture 32 sort0)).isSome then
    throw (IO.userError "C0 zeta metadata exceeded recursion budget")
  -- Exact structural hash and range equivalence at *every* intermediate
  -- let source, not only at the root. A cache fingerprint never replaces
  -- collision-checked source equality.
  for depth in [1, 12, 16, 24, 48, 96] do
    for leaf in [sort0, PsKernelExpr.bvar 0, PsKernelExpr.bvar 5] do
      let source := c0ZetaFixture depth leaf
      match psKernelC0LetCacheFramesWithFuel 1024 source with
      | some (_, fullHash, frames) =>
          if fullHash != psKernelExprHash source then
            throw (IO.userError "C0 cached zeta root hash differs")
          let mut term := source
          let mut remainingFrames := frames
          for _ in [:depth] do
            match term, remainingFrames with
            | .letE _ _ _ body _, (range, hash) :: tail =>
                if hash != psKernelExprHash term then
                  throw (IO.userError "C0 zeta suffix fingerprint differs")
                for cutoff in [:8] do
                  if (range > cutoff) != psKernelExprHasLooseAt body cutoff then
                    throw (IO.userError "C0 zeta suffix range differs")
                term := body
                remainingFrames := tail
            | _, _ => throw (IO.userError "C0 zeta hash frames misaligned")
          if !remainingFrames.isEmpty then
            throw (IO.userError "C0 zeta cache frame size differs")
      | none => throw (IO.userError "C0 zeta cache metadata unavailable")
  -- Exact hash-key fast paths must be observationally equivalent across
  -- both the small-list cache and promoted collision-checked radix index.
  let mut ordinaryCache := psKernelExprMapEmpty
  let mut hashedCache := psKernelExprMapEmpty
  for depth in [1, 2, 4, 8, 12, 16, 24, 32, 48, 64, 96, 128] do
    let source := c0ZetaFixture depth sort0
    ordinaryCache := psKernelExprMapInsert ordinaryCache source sort0
    hashedCache := psKernelExprMapInsertWithKnownHash
      hashedCache source sort0 (some (psKernelExprHash source))
  for depth in [1, 2, 4, 8, 12, 16, 24, 32, 48, 64, 96, 128] do
    let source := c0ZetaFixture depth sort0
    match psKernelExprMapGet ordinaryCache source,
          psKernelExprMapGetWithKnownHash hashedCache source
            (some (psKernelExprHash source)) with
    | some normal, some hashed =>
        if !(psKernelExprEqual normal hashed &&
             psKernelExprEqual hashed sort0) then
          throw (IO.userError "C0 prehashed cache changed returned expression")
    | _, _ => throw (IO.userError "C0 prehashed cache missed original entry")
  -- Checked inference has stronger obligations than WHNF: every
  -- let domain and value must be checked, each binder allocates its fresh
  -- local, and the closed body is inferred under the new local context.
  -- Compare the optimized public checker to the independent hook-free
  -- historical syntax-directed engine at exact resource budgets.
  for depth in [1, 8, 11, 12, 13, 24, 48, 96] do
    for leaf in [sort0, PsKernelExpr.bvar 0, PsKernelExpr.bvar 5] do
      let term := c0ZetaFixture depth leaf
      for fuel in [0, 1, 8, 24, 64, 512, 4096] do
        let defeq := psKernelIsDefEqWithFuel fuel
        let whnf := psKernelWhnfWithRecursorFuel fuel defeq
        match psKernelSessionCheck fuel session term,
            psKernelInferCoreWithFuel fuel whnf defeq
              session.context session.state term false with
        | Except.error candidate, Except.error reference =>
            if candidate != reference then
              throw (IO.userError
                "C0 checked zeta changed resource/error classification")
        | Except.ok (candidate, checked), Except.ok (reference, originalState) =>
            if !(psKernelExprEqual candidate reference &&
                checked.state.nextFresh == originalState.nextFresh) then
              throw (IO.userError
                "C0 checked zeta changed type or fresh-name state")
        | _, _ =>
            throw (IO.userError
              "C0 checked zeta changed acceptance/rejection")
  IO.println "C0_PERF_REGRESSION checked_zeta_fingerprint_inference=pass"

  IO.println "C0_PERF_REGRESSION zeta_hash_cache_exactness=pass"

  IO.println "C0_PERF_REGRESSION exact_zeta_suffix_oracle=pass"

  -- One bounded bottom-up syntax analysis must agree with the independent
  -- loose-variable traversal at every binder depth, including a non-closed
  -- innermost body. Budget exhaustion must leave the checker unchanged.
  for n in [1, 12, 16, 64, 192] do
    for isLambda in [false, true] do
      for leaf in [sort0, PsKernelExpr.bvar 0, PsKernelExpr.bvar 5] do
        let source :=
          if isLambda then c0BinderLambdaTail n leaf
          else c0BinderForallTail n leaf
        match psKernelC0BinderBodyRangesWithFuel 1024 source with
        | none =>
            throw (IO.userError "C0 binder metadata unexpectedly unavailable")
        | some (_, ranges) =>
            let mut current := source
            let mut unread := ranges
            for _ in [:n] do
              match current, unread with
              | PsKernelExpr.lam _ _ body _, range :: rest =>
                  for cutoff in [:8] do
                    if (range > cutoff) != psKernelExprHasLooseAt body cutoff then
                      throw (IO.userError "C0 lambda body range is not exact")
                  current := body
                  unread := rest
              | PsKernelExpr.forallE _ _ body _, range :: rest =>
                  for cutoff in [:8] do
                    if (range > cutoff) != psKernelExprHasLooseAt body cutoff then
                      throw (IO.userError "C0 Pi body range is not exact")
                  current := body
                  unread := rest
              | _, _ => throw (IO.userError "C0 binder metadata spine misaligned")
            if !unread.isEmpty then
              throw (IO.userError "C0 binder metadata retained extra ranges")
    let longPi := c0BinderForallTail n (PsKernelExpr.bvar 0)
    if psKernelC0BinderBodyRangesWithFuel 1 longPi |>.isSome then
      throw (IO.userError "C0 binder metadata did not respect recursion budget")
  IO.println "C0_PERF_REGRESSION exact_binder_body_range_oracle=pass"
  -- Binder summaries are shared with DefEq, but now also guide real
  -- fully checked inference. Every domain, fresh name and body still goes
  -- through the original source typing rules; compare exact error/fuel and
  -- nextFresh against the hook-free recursive reference.
  for depth in [1, 8, 11, 12, 13, 32, 64, 96] do
    for isLambda in [true, false] do
      for leaf in [sort0, PsKernelExpr.bvar 0, PsKernelExpr.bvar 5] do
        let term :=
          if isLambda then c0BinderLambdaTail depth leaf
          else c0BinderForallTail depth leaf
        for fuel in [0, 1, 8, 32, 128, 4096] do
          let defeq := psKernelIsDefEqWithFuel fuel
          let whnf := psKernelWhnfWithRecursorFuel fuel defeq
          match psKernelSessionCheck fuel session term,
              psKernelInferCoreWithFuel fuel whnf defeq
                session.context session.state term false with
          | Except.error candidate, Except.error reference =>
              if candidate != reference then
                throw (IO.userError
                  "C0 checked binder changed error classification")
          | Except.ok (candidate, checked), Except.ok (reference, historical) =>
              if !(psKernelExprEqual candidate reference &&
                  checked.state.nextFresh == historical.nextFresh) then
                throw (IO.userError
                  "C0 checked binder changed type or fresh names")
          | _, _ =>
              throw (IO.userError "C0 checked binder changed acceptance")
  IO.println "C0_PERF_REGRESSION checked_binder_range_inference=pass"


  -- A dependent Pi domain referencing an *outer* binder must see
  -- substitution variables newest-first. Metadata changes exact syntax
  -- but not definitional equality; the malformed outer-domain case must
  -- continue to be rejected by full checking, not accepted by metadata.
  for width in [0, 4, 12, 64] do
    let left := c0BinderDependentPair width false
    let right := c0BinderDependentPair width true
    match psKernelSessionIsDefEq 4096 session left right with
    | Except.ok (true, _) => pure ()
    | Except.ok (false, _) =>
        throw (IO.userError "C0 dependent binder DefEq lost equivalence")
    | Except.error err =>
        throw (IO.userError ("C0 dependent binder DefEq errored: " ++ err))
  IO.println "C0_PERF_REGRESSION dependent_binder_substitution_order=pass"
  -- Derive a sufficient DefEq recursion budget from the *actual* spine
  -- geometry. Compare it to the historical whole-tree bound and preserve
  -- negative classifications at smaller explicit budgets. These are
  -- nontrivial dependent/open bodies, not just closed Sort terminals.
  for width in [0, 1, 8, 32, 96] do
    let app := c0RegressionApps width
      (PsKernelExpr.mdata 17 sort0) sort0
    let appWithDifferentArg := c0RegressionApps width
      (PsKernelExpr.mdata 17 sort0) sort1
    for right in [app, appWithDifferentArg] do
      let enough := Nat.succ
        (psKernelExprGetAppNumArgs app +
         psKernelExprGetAppNumArgs right)
      let oldEnough := Nat.succ
        (psKernelExprNodeCount app + psKernelExprNodeCount right)
      let callback :=
        fun (_ : PsKernelCheckerContext) (st : PsKernelCheckerState)
            (left : PsKernelExpr) (other : PsKernelExpr) =>
          Except.ok (psKernelExprEq left other, st)
      match psKernelDefEqArgsWithFuel enough callback
          session.context session.state app right,
          psKernelDefEqArgsWithFuel oldEnough callback
            session.context session.state app right with
      | Except.ok (fast, _), Except.ok (reference, _) =>
          if fast != reference then
            throw (IO.userError "C0 app-spine bound changed congruence")
      | Except.error fast, Except.error reference =>
          if fast != reference then
            throw (IO.userError "C0 app-spine bound changed error")
      | _, _ =>
          throw (IO.userError "C0 app-spine bound changed acceptance category")
    let binders := c0BinderForallTail width (.mdata 99 sort0)
    let different := c0BinderForallTail width sort0
    let depthFuel := Nat.succ
      (psKernelC0ForallSpineLength binders +
       psKernelC0ForallSpineLength different)
    let oldFuel := Nat.succ
      (psKernelExprNodeCount binders + psKernelExprNodeCount different)
    let eqCallback :=
      fun (_ : PsKernelCheckerContext) (st : PsKernelCheckerState)
          (a : PsKernelExpr) (z : PsKernelExpr) =>
        Except.ok (psKernelExprEq a z, st)
    match psKernelDefEqForallSpineWithFuel depthFuel eqCallback
        session.context session.state binders different [] [] [],
        psKernelDefEqForallSpineWithFuel oldFuel eqCallback
          session.context session.state binders different [] [] [] with
    | Except.ok (fast, _), Except.ok (reference, _) =>
        if fast != reference then
          throw (IO.userError "C0 forall spine bound changed result")
    | Except.error fast, Except.error reference =>
        if fast != reference then
          throw (IO.userError "C0 forall spine bound changed error")
    | _, _ =>
        throw (IO.userError "C0 forall spine bound changed classification")
  IO.println "C0_PERF_REGRESSION exact_structural_spine_fuel_oracle=pass"





  -- A genuine dependent first binder, followed by a long closed Pi
  -- suffix, exercises range invalidation followed by exact bounded
  -- resummarization. Both paths must agree with independent recursive
  -- acceptance, including malformed arguments and small fuel.
  let propName :=
    PsKernelName.str PsKernelName.anonymous "C0DependentProp"
  let depName :=
    PsKernelName.str PsKernelName.anonymous "C0DependentFn"
  let propAxiom : PsKernelAxiomInfo := {
    base := { name := propName, levelParams := [], type := sort0 }
    isUnsafe := false
  }
  let propEnv ←
    match psKernelAddAxiom 4096 psKernelEnvironmentEmpty propAxiom
        4096 psKernelLeanNatMaxSizeDefault with
    | Except.ok accepted => pure accepted
    | Except.error err =>
        throw (IO.userError ("C0 dependent proposition rejected: " ++ err))
  for width in [12, 24, 64] do
    let fnName := PsKernelName.num depName width
    let fnAxiom : PsKernelAxiomInfo := {
      base := {
        name := fnName
        levelParams := []
        type := c0RegressionDependentPi width
      }
      isUnsafe := false
    }
    let depEnv ←
      match psKernelAddAxiom 4096 propEnv fnAxiom
          4096 psKernelLeanNatMaxSizeDefault with
      | Except.ok accepted => pure accepted
      | Except.error err =>
          throw (IO.userError ("C0 dependent function rejected: " ++ err))
    let ctx := psKernelCheckerContextEmpty depEnv
    let baseTerm := PsKernelExpr.app
      (PsKernelExpr.app (PsKernelExpr.const fnName []) sort0)
      (PsKernelExpr.const propName [])
    let accepted := c0RegressionApps width baseTerm sort0
    let rejected := c0RegressionApps width
      (PsKernelExpr.app (PsKernelExpr.app
        (PsKernelExpr.const fnName []) sort0) sort0) sort0
    for term in [accepted, rejected] do
      for fuel in [0, 1, 8, 32, 128, 512, 4096] do
        let defeq := psKernelIsDefEqWithFuel fuel
        let whnf := psKernelWhnfWithRecursorFuel fuel defeq
        let oldCheck :=
          psKernelC0CheckAppRecursive fuel whnf defeq
            ctx psKernelCheckerStateEmpty term
        let improved :=
          psKernelC0CheckAppRecursiveResummarized fuel whnf defeq
            ctx psKernelCheckerStateEmpty term
        let reference :=
          psKernelInferCoreWithFuel fuel whnf defeq
            ctx psKernelCheckerStateEmpty term false
        match oldCheck, improved, reference with
        | Except.error a, Except.error b, Except.error referenceError =>
            if a != b || b != referenceError then
              throw (IO.userError
                "C0 dependent Pi reanalysis changed exact error")
        | Except.ok (a, stateA), Except.ok (b, stateB),
            Except.ok (referenceType, stateRef) =>
            if !(psKernelExprEqual a b &&
                psKernelExprEqual b referenceType &&
                stateA.nextFresh == stateB.nextFresh &&
                stateB.nextFresh == stateRef.nextFresh) then
              throw (IO.userError
                "C0 dependent Pi reanalysis changed checked result")
        | _, _, _ =>
            throw (IO.userError
              "C0 dependent Pi reanalysis changed acceptance")
  IO.println "C0_PERF_REGRESSION dependent_pi_suffix_resummary=pass"

  -- The flattened checked-spine candidate must have identical fully checked
  -- outcomes, exact error strings, resource exhaustion and fresh-name state.
  -- This includes a deeply nested app, a bad argument and tight fuel limits.
  for arity in [1, 4, 12, 24, 31, 32, 33, 48, 63, 64, 65, 192, 320] do
    let source := (List.range arity).foldl
      (fun expr _ => PsKernelExpr.app expr sort0)
      (c0CheckedSpineFixture arity)
    let invalid := PsKernelExpr.app source sort1
    for expr in [source, invalid] do
      for fuel in [0, 1, 2, 4, 12, 64, 4096] do
        let defeq := psKernelIsDefEqWithFuel fuel
        let whnf := psKernelWhnfWithRecursorFuel fuel defeq
        -- Public checking routes wide spines to this candidate. Compare to
        -- the independent recursive implementation, never to itself.
        match psKernelC0CheckAppSpineWithFuel fuel whnf defeq
            session.context session.state expr,
            psKernelInferCoreWithFuel fuel whnf defeq
              session.context session.state expr false with
        | Except.error candidate, Except.error reference =>
            if candidate != reference then
              throw (IO.userError "C0 checked spine changed rejection category")
        | Except.ok (candidate, state), Except.ok (reference, originalState) =>
            if !(psKernelExprEqual candidate reference &&
                state.nextFresh == originalState.nextFresh) then
              throw (IO.userError "C0 checked spine changed type or fresh names")
        | _, _ =>
            throw (IO.userError "C0 checked spine changed success/rejection")
  -- Medium and wide application paths must reject malformed function heads
  -- and malformed arguments exactly as the independent recursive checker.
  -- These checks include cases where an earlier error must take precedence
  -- over later argument validation and resource exhaustion.
  let missingHead :=
    PsKernelExpr.const
      (PsKernelName.str PsKernelName.anonymous "C0MissingCheckedHead")
      []
  let unknownArgument :=
    PsKernelExpr.mvar
      (PsKernelName.str PsKernelName.anonymous "C0InvalidCheckedArgument")
  for arity in [31, 32, 33, 48, 64] do
    let malformedHead := (List.range arity).foldl
      (fun fn _ => PsKernelExpr.app fn sort0) missingHead
    let malformedArgument := (List.range arity).foldl
      (fun fn i =>
        PsKernelExpr.app fn
          (if i == arity / 2 then unknownArgument else sort0))
      (c0CheckedSpineFixture arity)
    for expr in [malformedHead, malformedArgument] do
      for fuel in [1, 2, 16, 64, 512, 4096] do
        let defeq := psKernelIsDefEqWithFuel fuel
        let whnf := psKernelWhnfWithRecursorFuel fuel defeq
        match psKernelSessionCheck fuel session expr,
            psKernelInferCoreWithFuel fuel whnf defeq
              session.context session.state expr false with
        | Except.error checkedError, Except.error originalError =>
            if checkedError != originalError then
              throw (IO.userError
                "C0 malformed checked spine changed error precedence")
        | _, _ =>
            throw (IO.userError
              "C0 malformed checked spine changed rejection into acceptance")
  -- Independently compare the structurally recursive metadata-carrying
  -- alternative against the original checked core. Its only possible
  -- acceptance difference must be caught here, including exact resource
  -- exhaustion, failed heads, typed arguments and metadata-bearing syntax.
  for arity in [1, 8, 15, 16, 17, 23, 24, 31, 32, 33, 48, 64, 192, 320] do
    let source := (List.range arity).foldl
      (fun fn i =>
        PsKernelExpr.app fn
          (if i % 3 == 0 then PsKernelExpr.mdata i sort0 else sort0))
      (c0CheckedSpineFixture arity)
    let bad := PsKernelExpr.app source sort1
    for expr in [source, bad] do
      for fuel in [0, 1, 4, 16, 64, 512, 4096] do
        let defeq := psKernelIsDefEqWithFuel fuel
        let whnf := psKernelWhnfWithRecursorFuel fuel defeq
        match psKernelC0CheckAppRecursive fuel whnf defeq
            session.context session.state expr,
            psKernelInferCoreWithFuel fuel whnf defeq
              session.context session.state expr false with
        | Except.error candidateError, Except.error originalError =>
            if candidateError != originalError then
              throw (IO.userError
                "C0 recursive Pi metadata changed checked error")
        | Except.ok (candidateType, candidateState),
            Except.ok (originalType, originalState) =>
            if !(psKernelExprEqual candidateType originalType &&
                candidateState.nextFresh == originalState.nextFresh) then
              throw (IO.userError
                "C0 recursive Pi metadata changed type or fresh names")
        | _, _ =>
            throw (IO.userError
              "C0 recursive Pi metadata changed acceptance")
  -- A wide application argument must use the exact original recursive
  -- resource budget and preserve checking order. Compare the production
  -- full checker to the independently retained recursive source worker.
  for outerWidth in [16, 24, 48] do
    for innerWidth in [15, 16, 24] do
      let inner := (List.range innerWidth).foldl
        (fun fn _ => PsKernelExpr.app fn sort0)
        (c0CheckedSpineFixture innerWidth)
      let unknownInner := (List.range innerWidth).foldl
        (fun fn _ => PsKernelExpr.app fn sort0)
        (PsKernelExpr.mvar
          (PsKernelName.str PsKernelName.anonymous "C0NestedAppUnknown"))
      for nested in [inner, unknownInner] do
        let outer := (List.range outerWidth).foldl
          (fun fn i => PsKernelExpr.app fn
            (if i == outerWidth / 2 then nested else sort0))
          (c0CheckedSpineFixture outerWidth)
        for fuel in [0, 1, 8, 16, 32, 64, 512, 4096] do
          let defeq := psKernelIsDefEqWithFuel fuel
          let whnf := psKernelWhnfWithRecursorFuel fuel defeq
          match psKernelSessionCheck fuel session outer,
              psKernelInferCoreWithFuel fuel whnf defeq
                session.context session.state outer false with
          | Except.error fast, Except.error original =>
              if fast != original then
                throw (IO.userError
                  "C0 nested argument application changed error order/fuel")
          | Except.ok (fastType, fastSession),
              Except.ok (originalType, originalState) =>
              if !(psKernelExprEqual fastType originalType &&
                  fastSession.state.nextFresh == originalState.nextFresh) then
                throw (IO.userError
                  "C0 nested argument application changed checked type/state")
          | _, _ =>
              throw (IO.userError
                "C0 nested argument application changed acceptance")
  IO.println "C0_PERF_REGRESSION nested_app_argument_fuel_and_errors=pass"
  IO.println "C0_PERF_REGRESSION recursive_pi_metadata_exact_checker=pass"
  -- The public production router must match an *independent* recursive
  -- acceptance oracle across the medium-width routing boundary.
  for arity in [8, 15, 16, 17, 23, 24, 31, 32, 33, 48, 64, 192] do
    let term := (List.range arity).foldl
      (fun fn _ => PsKernelExpr.app fn sort0)
      (c0CheckedSpineFixture arity)
    for fuel in [0, 1, 8, 32, 512, 4096] do
      let defeq := psKernelIsDefEqWithFuel fuel
      let whnf := psKernelWhnfWithRecursorFuel fuel defeq
      match psKernelSessionCheck fuel session term,
          psKernelInferCoreWithFuel fuel whnf defeq
            session.context session.state term false with
      | Except.error a, Except.error b =>
          if a != b then
            throw (IO.userError "C0 public recursion metadata changed error")
      | Except.ok (a, next), Except.ok (b, originalState) =>
          if !(psKernelExprEqual a b &&
              next.state.nextFresh == originalState.nextFresh) then
            throw (IO.userError "C0 public recursion metadata changed type")
      | _, _ =>
          throw (IO.userError "C0 public recursion metadata changed acceptance")
  -- The public nested checked route must not compare against itself.
  -- Include common enclosing syntax, exact low-fuel errors and local binder
  -- freshness. The hook-free recursive worker is the independent oracle.
  for arity in [15, 16, 17, 24, 48, 64] do
    let application := (List.range arity).foldl
      (fun term _ => PsKernelExpr.app term sort0)
      (c0CheckedSpineFixture arity)
    let wrapped : List PsKernelExpr := [
      PsKernelExpr.mdata arity application,
      PsKernelExpr.lam PsKernelName.anonymous sort1 application
        PsKernelBinderInfo.default,
      PsKernelExpr.letE PsKernelName.anonymous sort1 sort0 application false,
      PsKernelExpr.forallE PsKernelName.anonymous sort1 application
        PsKernelBinderInfo.default
    ]
    for term in wrapped do
      for fuel in [0, 1, 2, 16, 64, 4096] do
        let defeq := psKernelIsDefEqWithFuel fuel
        let whnf := psKernelWhnfWithRecursorFuel fuel defeq
        match psKernelSessionCheck fuel session term,
            psKernelInferCoreWithFuel fuel whnf defeq
              session.context session.state term false with
        | Except.error fastError, Except.error referenceError =>
            if fastError != referenceError then
              throw (IO.userError
                "C0 nested checked applications changed resource/error")
        | Except.ok (fastType, fastSession),
            Except.ok (referenceType, referenceState) =>
            if !(psKernelExprEqual fastType referenceType &&
                fastSession.state.nextFresh == referenceState.nextFresh) then
              throw (IO.userError
                "C0 nested checked applications changed inferred type/state")
        | _, _ =>
            throw (IO.userError "C0 nested checked acceptance diverged")
  IO.println "C0_PERF_REGRESSION nested_checked_application_core_hook=pass"

  IO.println "C0_PERF_REGRESSION public_recursive_checked_spine_boundary=pass"

  IO.println "C0_PERF_REGRESSION checked_spine_malformed_heads_args=pass"

  IO.println "C0_PERF_REGRESSION checked_spine_exact_fuel_and_errors=pass"
  -- A finite recursive-context limit is independent of expression fuel.
  -- The production router must preserve the exact recursion-depth rejection
  -- on both shorter and wider application spines.
  for bound in [1, 2, 64, 192, 256] do
    let bounded : PsKernelCheckerSession := {
      session with
      context := { session.context with maxRecDepth := bound }
    }
    for arity in [12, 31, 32, 33, 48, 192] do
      let expr := (List.range arity).foldl
        (fun term _ => PsKernelExpr.app term sort0)
        (c0CheckedSpineFixture arity)
      let defeq := psKernelIsDefEqWithFuel 4096
      let whnf := psKernelWhnfWithRecursorFuel 4096 defeq
      match psKernelC0CheckAppSpineWithFuel 4096 whnf defeq
          bounded.context bounded.state expr,
          psKernelInferCoreWithFuel 4096 whnf defeq
            bounded.context bounded.state expr false with
      | Except.error a, Except.error b =>
          if a != b then
            throw (IO.userError "C0 framed spine recursion error differed")
      | Except.ok (a, _), Except.ok (b, _) =>
          if !(psKernelExprEqual a b) then
            throw (IO.userError "C0 framed spine recursion result differed")
      | _, _ =>
          throw (IO.userError "C0 framed spine recursion classification differed")
  IO.println "C0_PERF_REGRESSION checked_spine_context_bounds=pass"


  -- Exact source cached-range oracle: a range greater than the cutoff
  -- must agree with the independent recursive loose-variable predicate
  -- at every offset, including under let/lambda/Pi binders.
  let dependentPi :=
    PsKernelExpr.forallE PsKernelName.anonymous sort0
      (PsKernelExpr.forallE PsKernelName.anonymous
        (PsKernelExpr.bvar 0) (PsKernelExpr.bvar 1)
        PsKernelBinderInfo.default)
      PsKernelBinderInfo.default
  let sourceRanges : List PsKernelExpr := [
    sort0,
    PsKernelExpr.bvar 0,
    PsKernelExpr.bvar 3,
    PsKernelExpr.app (PsKernelExpr.bvar 2) sort0,
    dependentPi,
    PsKernelExpr.lam PsKernelName.anonymous sort0
      (PsKernelExpr.bvar 0) PsKernelBinderInfo.default,
    PsKernelExpr.letE PsKernelName.anonymous sort0
      (PsKernelExpr.bvar 4) (PsKernelExpr.bvar 1) false
  ]
  for expr in sourceRanges do
    match psKernelC0SourceLooseRangeWithFuel 1024 expr with
    | none => throw (IO.userError "C0 bounded metadata unexpectedly exhausted")
    | some range =>
        for cutoff in [:range + 3] do
          if (range > cutoff) != psKernelExprHasLooseAt expr cutoff then
            throw (IO.userError "C0 source loose range diverged from syntax")
  match psKernelC0PiBodyRangesWithFuel 1024 dependentPi with
  | some (_, [first, second]) =>
      if first != 1 || second != 2 then
        throw (IO.userError "C0 Pi suffix ranges lost binder shift")
  | _ => throw (IO.userError "C0 Pi suffix metadata shape diverged")
  if (psKernelC0PiBodyRangesWithFuel 1 dependentPi).isSome then
    throw (IO.userError "C0 bounded Pi metadata failed to exhaust safely")
  IO.println "C0_PERF_REGRESSION source_pi_range_oracle=pass"

  match psKernelSessionIsDefEq 4096 session sort0 sort1 with
  | Except.error message =>
      throw (IO.userError ("unexpected sort comparison error: " ++ message))
  | Except.ok result =>
      if Prod.fst result then
        throw (IO.userError "unsound: Sort 0 equated with Sort 1")
      else
        IO.println "C0_PROOF_AUDIT sort0_sort1_distinct=pass"


  -- Compare the accepting lazy argument-spine operations with the exact
  -- pre-refactor helpers. Exercise no-op, unfoldable, opaque, and constructor
  -- cases using an isolated immutable environment. No declaration admission
  -- shortcut or cache decision is introduced by these optimizations.
  let deltaName := PsKernelName.str PsKernelName.anonymous "C0.delta"
  let ctorName := PsKernelName.str PsKernelName.anonymous "C0.mk"
  let inductName := PsKernelName.str PsKernelName.anonymous "C0"
  let definition : PsKernelDefinitionInfo := {
    base := { name := deltaName, levelParams := [], type := sort0 }
    value := sort1
    hints := PsKernelReducibilityHints.abbrevHint
    safety := PsKernelDefinitionSafety.safe
  }
  let constructor : PsKernelConstructorInfo := {
    base := { name := ctorName, levelParams := [], type := sort0 }
    induct := inductName
    cidx := 0
    numParams := 0
    numFields := 1
    isUnsafe := false
  }
  let deltaEnv :=
    psKernelEnvironmentAddUnchecked psKernelEnvironmentEmpty
      (PsKernelConstantInfo.defnInfo definition)
  let fixtureEnv :=
    psKernelEnvironmentAddUnchecked deltaEnv
      (PsKernelConstantInfo.ctorInfo constructor)
  let fixtureCtx := psKernelCheckerContextEmpty fixtureEnv
  let noDelta := PsKernelName.str PsKernelName.anonymous "C0.noDelta"
  let namedMVar := PsKernelExpr.mvar noDelta
  let shallow := PsKernelExpr.app namedMVar sort0
  let deep := PsKernelExpr.app (PsKernelExpr.app shallow sort1) sort0
  let defined := PsKernelExpr.app (PsKernelExpr.const deltaName []) sort0
  let opaqueTerm := PsKernelExpr.app (PsKernelExpr.const ctorName []) sort0
  let missing := PsKernelExpr.app (PsKernelExpr.const noDelta []) sort0
  for expr in [sort0, shallow, deep, defined, opaqueTerm, missing] do
    match c0ReferenceUnfoldDefinition fixtureCtx expr,
        psKernelUnfoldDefinition fixtureCtx expr with
    | Option.none, Option.none => pure ()
    | Option.some before, Option.some after =>
        if !(psKernelExprEqual before after) then
          throw (IO.userError "C0 lazy-delta changed unfolded expression")
    | _, _ =>
        throw (IO.userError "C0 lazy-delta changed unfold decision")
  let ctorTerm := PsKernelExpr.app (PsKernelExpr.const ctorName []) sort1
  for expr in [sort0, shallow, deep, ctorTerm, defined, missing] do
    for typeName in [inductName, deltaName] do
      match c0ReferenceReduceProjCore fixtureCtx typeName 0 expr,
          psKernelReduceProjCore fixtureCtx typeName 0 expr with
      | Option.none, Option.none => pure ()
      | Option.some before, Option.some after =>
          if !(psKernelExprEqual before after) then
            throw (IO.userError "C0 lazy-projection changed selected field")
      | _, _ =>
          throw (IO.userError "C0 lazy-projection changed decision")
  if !(psKernelExprEqual
      (Option.getD (psKernelUnfoldDefinition fixtureCtx defined) sort0)
      (PsKernelExpr.app sort1 sort0)) then
    throw (IO.userError "C0 delta fixture failed to unfold")
  if !(psKernelExprEqual
      (Option.getD (psKernelReduceProjCore fixtureCtx inductName 0 ctorTerm) sort0)
      sort1) then
    throw (IO.userError "C0 projection fixture failed to select field")
  IO.println "C0_PERF_REGRESSION lazy_delta_projection_spines=pass"

  -- A direct application-spine selector must match the historical
  -- fully materialized argument-list representation for every index.
  for arity in [0, 1, 2, 3, 32, 128] do
    let input := (List.range arity).foldl
      (fun term i => PsKernelExpr.app term (PsKernelExpr.bvar i))
      (PsKernelExpr.const ctorName [])
    for index in [:arity + 2] do
      match psKernelExprListGet (psKernelExprGetAppArgs input) index,
          psKernelExprGetAppArgAt input index with
      | Option.none, Option.none => pure ()
      | Option.some before, Option.some after =>
          if !(psKernelExprEqual before after) then
            throw (IO.userError "C0 direct application argument changed value")
      | _, _ =>
          throw (IO.userError "C0 direct application argument changed bounds")
  IO.println "C0_PERF_REGRESSION app_arg_direct_selection=pass"

  -- Session-owned indexed roots do not escape into checked decisions.
  -- Retaining the same exact syntax twice preserves the arena and root count,
  -- while binder names are represented exactly (unlike semantic alpha Eq).
  let rootNameA := PsKernelName.str PsKernelName.anonymous "Alpha"
  let rootNameB := PsKernelName.str PsKernelName.anonymous "Beta"
  let indexedA := PsKernelExpr.lam rootNameA sort0
    (PsKernelExpr.bvar 0) PsKernelBinderInfo.default
  let indexedB := PsKernelExpr.lam rootNameB sort0
    (PsKernelExpr.bvar 0) PsKernelBinderInfo.default
  let emptyOwned := psKernelC0IndexedSessionNew session
  match psKernelC0IndexedSessionRetain emptyOwned indexedA with
  | none => throw (IO.userError "C0 session failed to index exact lambda")
  | some ownedA =>
      match psKernelC0IndexedSessionRetain ownedA indexedA with
      | none => throw (IO.userError "C0 session failed repeated retention")
      | some repeated =>
          if psKernelC0IndexedSessionNodeCount emptyOwned != 0 ||
              psKernelC0IndexedSessionRootCount emptyOwned != 0 ||
              psKernelC0IndexedSessionNodeCount repeated !=
                psKernelC0IndexedSessionNodeCount ownedA ||
              psKernelC0IndexedSessionRootCount repeated != 1 then
            throw (IO.userError "C0 indexed session lost persistent root sharing")
          match psKernelC0IndexedSessionRetain repeated indexedB with
          | none => throw (IO.userError "C0 session failed distinct binder retention")
          | some ownedB =>
              if psKernelC0IndexedSessionNodeCount ownedB <=
                  psKernelC0IndexedSessionNodeCount ownedA ||
                  psKernelC0IndexedSessionRootCount ownedB != 2 then
                throw (IO.userError "C0 binder-name-sensitive indexing aliased roots")
              match psKernelC0IndexedSessionIsDefEq 4096 ownedB sort0 sort1,
                    psKernelSessionIsDefEq 4096 session sort0 sort1 with
              | Except.ok (fastNo, next), Except.ok (referenceNo, _) =>
                  if fastNo || referenceNo ||
                      psKernelC0IndexedSessionRootCount next != 4 then
                    throw (IO.userError "C0 indexed negative DefEq changed behavior")
              | _, _ =>
                  throw (IO.userError "C0 indexed negative DefEq changed category")
  match psKernelC0IndexedSessionWhnf 4096 emptyOwned
      (PsKernelExpr.app indexedA sort0),
      psKernelSessionWhnf 4096 session (PsKernelExpr.app indexedA sort0) with
  | Except.ok (indexedValue, owned), Except.ok (plainValue, _) =>
      if !(psKernelExprEqual indexedValue plainValue &&
            psKernelExprEqual indexedValue sort0 &&
            psKernelC0IndexedSessionRootCount owned == 2) then
        throw (IO.userError "C0 indexed WHNF differed from checked result")
  | _, _ => throw (IO.userError "C0 indexed WHNF changed outcome")
  match psKernelC0IndexedSessionInfer 4096 emptyOwned indexedA,
        psKernelSessionInfer 4096 session indexedA with
  | Except.ok (a, _), Except.ok (b, _) =>
      if !(psKernelExprEqual a b) then
        throw (IO.userError "C0 indexed inference changed checked type")
  | _, _ => throw (IO.userError "C0 indexed inference changed outcome")
  match psKernelC0IndexedSessionCheck 4096 emptyOwned (PsKernelExpr.bvar 0),
        psKernelSessionCheck 4096 session (PsKernelExpr.bvar 0) with
  | Except.error _, Except.error _ => pure ()
  | _, _ => throw (IO.userError "C0 indexed session accepted an unbound variable")
  IO.println "C0_PERF_REGRESSION indexed_session_owned_roots=pass"
  -- Promotion beyond the tiny-list threshold must not lose old handles,
  -- confuse separately stored syntax, or mutate earlier session snapshots.
  let mut promoted := emptyOwned
  for i in [:40] do
    match psKernelC0IndexedSessionRetain promoted (PsKernelExpr.bvar i) with
    | none => throw (IO.userError "C0 radix-owned root retention failed")
    | some next => promoted := next
  if psKernelC0IndexedSessionRootCount promoted != 40 ||
      psKernelC0IndexedSessionNodeCount promoted != 40 ||
      psKernelC0IndexedSessionRootCount emptyOwned != 0 then
    throw (IO.userError "C0 radix-owned session count or snapshot mismatch")
  let originalCount := psKernelC0IndexedSessionNodeCount promoted
  for i in [:40] do
    match psKernelC0IndexedSessionRetain promoted (PsKernelExpr.bvar i) with
    | none => throw (IO.userError "C0 radix-owned lookup failed")
    | some next => promoted := next
  if psKernelC0IndexedSessionNodeCount promoted != originalCount ||
      psKernelC0IndexedSessionRootCount promoted != 40 then
    throw (IO.userError "C0 radix-owned root cache duplicated previous nodes")
  IO.println "C0_PERF_REGRESSION indexed_session_radix_roots=pass"

  -- Old hash buckets discarded binder name/info and let names, producing
  -- long linear collision chains for distinct canonical binder nodes.
  -- Each new fingerprint must still agree with the exact structural node.
  match psKernelC0Intern psKernelC0StoreEmpty (.sort PsKernelLevel.zero) with
  | none => throw (IO.userError "C0 binder-hash sort fixture rejected")
  | some (initial, domainId) =>
      match psKernelC0Intern initial (.bvar 0) with
      | none => throw (IO.userError "C0 binder-hash body fixture rejected")
      | some (prepared, bodyId) =>
          let mut store := prepared
          let mut hashes : List Nat := []
          for i in [:96] do
            let binderName := PsKernelName.num PsKernelName.anonymous i
            let canonical : PsKernelC0Node :=
              .lam binderName domainId bodyId PsKernelBinderInfo.default
            let hashed := psKernelC0NodeHash store canonical
            if !hashes.contains hashed then hashes := hashed :: hashes
            match psKernelC0Intern store canonical with
            | none => throw (IO.userError "C0 exact binder interning rejected")
            | some (next, id) =>
                store := next
                match psKernelC0StoreGet next id with
                | none => throw (IO.userError "C0 exact binder handle invalid")
                | some stored =>
                    if !(psKernelC0NodeEq stored.node canonical) then
                      throw (IO.userError "C0 distinct binder node was aliased")
          if hashes.length < 60 || store.nodes.size != 98 then
            throw (IO.userError "C0 binder hashes still form a degenerate bucket")
          let name := PsKernelName.str PsKernelName.anonymous "BinderKinds"
          for node in [
            PsKernelC0Node.lam name domainId bodyId PsKernelBinderInfo.default,
            PsKernelC0Node.lam name domainId bodyId PsKernelBinderInfo.implicit,
            PsKernelC0Node.forallE name domainId bodyId PsKernelBinderInfo.default,
            PsKernelC0Node.letE name domainId domainId bodyId false
          ] do
            match psKernelC0Intern store node with
            | none => throw (IO.userError "C0 binder-kind store refused node")
            | some (next, id) =>
                store := next
                match psKernelC0StoreGet store id with
                | some stored =>
                    if !(psKernelC0NodeEq stored.node node) then
                      throw (IO.userError "C0 binder kinds aliased")
                | none => throw (IO.userError "C0 binder kind handle invalid")
  IO.println "C0_PERF_REGRESSION indexed_binder_hash_identity=pass"

  -- The infer-only application-spine worker keeps the same fuel and callback
  -- classification while counting an immutable argument list only once.
  let inferSpine := PsKernelExpr.forallE PsKernelName.anonymous sort0
    (PsKernelExpr.forallE PsKernelName.anonymous sort0 sort0
      PsKernelBinderInfo.default)
    PsKernelBinderInfo.default
  let spineArgs := [sort0, sort1]
  let inertWhnf :=
    fun (_ctx : PsKernelCheckerContext)
        (st : PsKernelCheckerState)
        (term : PsKernelExpr) =>
      Except.ok (term, st)
  for fuel in [0, 1, 2, 3, 4, 8] do
    match psKernelInferAppOnlyLoopWithFuel fuel inertWhnf
        session.context psKernelCheckerStateEmpty spineArgs 0 0 inferSpine,
        psKernelInferAppOnlyLoopWithFuelCount fuel 2 inertWhnf
          session.context psKernelCheckerStateEmpty spineArgs 0 0 inferSpine with
    | Except.ok (oldType, _), Except.ok (newType, _) =>
        if !(psKernelExprEqual oldType newType) then
          throw (IO.userError "C0 counted infer-only spine changed type")
    | Except.error oldError, Except.error newError =>
        if !(psKernelStringEq oldError newError) then
          throw (IO.userError "C0 counted infer-only spine changed exhaustion error")
    | _, _ =>
        throw (IO.userError "C0 counted infer-only spine changed fuel decision")
  IO.println "C0_PERF_REGRESSION infer_only_spine_count_fuel=pass"


  -- Native accepting DefEq first checks structural equality and successful
  -- pair-cache hits. The guarded quick entry may only be used after both
  -- are known to miss; verify it matches the public path on such inputs.
  let quickContext := psKernelCheckerContextEmpty psKernelEnvironmentEmpty
  let quickState := psKernelCheckerStateEmpty
  let quickDefeq :=
    fun (ctx : PsKernelCheckerContext)
        (st : PsKernelCheckerState)
        (left : PsKernelExpr)
        (right : PsKernelExpr) =>
      psKernelIsDefEq 128 ctx st left right
  for (left, right) in [
    (sort0, sort1),
    (PsKernelExpr.bvar 0, sort0),
    (PsKernelExpr.app (PsKernelExpr.mvar PsKernelName.anonymous)
      sort0, sort1)
  ] do
    if psKernelExprEq left right ||
        psKernelExprPairSetContains quickState.success left right then
      throw (IO.userError "C0 guarded quick test did not miss outer guards")
    match
        psKernelDefEqQuick quickDefeq quickContext quickState left right,
        psKernelDefEqQuickAfterCommon quickDefeq quickContext quickState left right with
    | Except.ok general, Except.ok guarded =>
        match Prod.fst general, Prod.fst guarded with
        | Option.none, Option.none => pure ()
        | Option.some x, Option.some y =>
            if !(psKernelBoolEq x y) then
              throw (IO.userError "C0 guarded quick comparison changed result")
        | _, _ =>
            throw (IO.userError "C0 guarded quick comparison changed decision")
    | Except.error x, Except.error y =>
        if !(psKernelStringEq x y) then
          throw (IO.userError "C0 guarded quick comparison changed error")
    | _, _ =>
        throw (IO.userError "C0 guarded quick comparison changed result category")
  IO.println "C0_PERF_REGRESSION defeq_guarded_quick=pass"

  match psKernelSessionCheck 4096 session (PsKernelExpr.bvar 0) with
  | Except.error _ =>
      IO.println "C0_PROOF_AUDIT unbound_bvar_rejected=pass"
  | Except.ok _ =>
      throw (IO.userError "unsound: unbound de Bruijn variable was checked")

  -- The performance refactor must retain the historical lambda-consumption
  -- semantics, including nonzero already-consumed argument prefixes.
  let info := PsKernelBinderInfo.default
  let base := PsKernelExpr.bvar 0
  let f1 := PsKernelExpr.lam PsKernelName.anonymous sort0 base info
  let f2 := PsKernelExpr.lam PsKernelName.anonymous sort0 f1 info
  let args := [sort0, sort1, sort0]
  for fn in [base, f1, f2] do
    for count in [0, 1, 2, 3, 4] do
      let old :=
        psKernelExprConsumeLambdaSpineWithFuel
          (Nat.succ (psKernelExprNodeCount fn))
          fn args count
      let next := psKernelExprConsumeLambdaSpine fn args count
      if !(psKernelExprEq (Prod.fst old) (Prod.fst next) &&
            Nat.beq (Prod.snd old) (Prod.snd next)) then
        throw (IO.userError "beta-spine linear optimization changed behavior")
  IO.println "C0_PERF_REGRESSION beta_spine_semantics=pass"
  -- Native-only differential checks for the specialized beta/zeta
  -- substitution. The generic multi-substitution algorithm is independent.
  let nested := PsKernelExpr.lam PsKernelName.anonymous sort0
    (PsKernelExpr.app (PsKernelExpr.bvar 1)
      (PsKernelExpr.bvar 0)) info
  let many := PsKernelExpr.letE PsKernelName.anonymous sort0
    sort1 (PsKernelExpr.forallE PsKernelName.anonymous sort0
      (PsKernelExpr.proj PsKernelName.anonymous 0
        (PsKernelExpr.mdata 10 (PsKernelExpr.bvar 2))) info) false
  for term in [base, sort0, sort1, nested, many,
      PsKernelExpr.app nested many] do
    for replacement in [base, sort0, sort1, nested, many] do
      let expected :=
        psKernelExprInstantiateAt term 0 [replacement] 0
      let actual :=
        psKernelExprInstantiate1 term replacement
      if !(psKernelExprEqual expected actual) then
        throw (IO.userError "C0 optimized single substitution mismatch")
  IO.println "C0_PERF_REGRESSION single_substitution_semantics=pass"
  -- Independent fuel-based lifting oracle versus direct traversal.
  for term in [base, sort0, nested, many,
      PsKernelExpr.app nested many] do
    for start in [0, 1, 2, 4] do
      for amount in [0, 1, 3] do
        let old :=
          psKernelExprLiftLooseBVarsChangedWithFuel
            (Nat.succ (psKernelExprNodeCount term))
            term start amount
        let next :=
          psKernelExprLiftLooseBVarsChanged term start amount
        if !(psKernelExprEqual (Prod.fst old) (Prod.fst next) &&
              psKernelBoolEq (Prod.snd old) (Prod.snd next)) then
          throw (IO.userError "C0 direct lifting changed semantics")
  IO.println "C0_PERF_REGRESSION structural_lift_semantics=pass"
  -- Paired comparison must agree with the historical curried comparator,
  -- including ignored binder names/annotations in kernel semantic equality.
  let renamed := PsKernelExpr.lam
    (PsKernelName.str PsKernelName.anonymous "renamed")
    sort0 (PsKernelExpr.bvar 0) PsKernelBinderInfo.implicit
  let original := PsKernelExpr.lam PsKernelName.anonymous
    sort0 (PsKernelExpr.bvar 0) PsKernelBinderInfo.default
  let candidates := [base, sort0, sort1, renamed, original,
    nested, many, PsKernelExpr.app nested many,
    PsKernelExpr.mdata 10 nested,
    PsKernelExpr.proj PsKernelName.anonymous 0 nested]
  for left in candidates do
    for right in candidates do
      if !(psKernelBoolEq
            (psKernelExprEqLegacy left right)
            (psKernelExprEq left right)) then
        throw (IO.userError "C0 paired expression equality mismatch")
      if !(psKernelBoolEq
            (psKernelExprEqualLegacy left right)
            (psKernelExprEqual left right)) then
        throw (IO.userError "C0 exact expression equality mismatch")
  IO.println "C0_PERF_REGRESSION paired_equality_semantics=pass"



  -- Test the indexed store's shared radix-16 interner, including duplicates.
  let first := psKernelC0Intern psKernelC0StoreEmpty (.bvar 0)
  match first with
  | Option.none =>
      throw (IO.userError "C0 indexed store rejected valid leaf")
  | Option.some (store1, id1) =>
      let second := psKernelC0Intern store1 (.bvar 0)
      match second with
      | Option.none =>
          throw (IO.userError "C0 indexed store rejected duplicate")
      | Option.some (store2, id2) =>
          if !(Nat.beq id1 id2 && Nat.beq store1.nodes.size store2.nodes.size) then
            throw (IO.userError "C0 indexed interning broke identity")
          match psKernelC0Intern store2 (.app id1 id2) with
          | Option.none =>
              throw (IO.userError "C0 indexed store rejected valid application")
          | Option.some (store3, id3) =>
              match psKernelC0Intern store3 (.app id1 id2) with
              | Option.none =>
                  throw (IO.userError "C0 indexed store rejected shared application")
              | Option.some (_, id4) =>
                  if !(Nat.beq id3 id4) then
                    throw (IO.userError "C0 radix-16 interning lost duplicate")
  IO.println "C0_PERF_REGRESSION radix_indexed_interning=pass"
  -- Exercise the >8-entry threshold, exact-name collisions and updates in
  -- the C0 radix-16 declaration index. No self-hosting involved.
  let mut decls := PsKernelEnvironmentIndex.empty
  for k in [:40] do
    let name := PsKernelName.num PsKernelName.anonymous k
    let base : PsKernelConstantBase :=
      { name := name, levelParams := [], type := sort0 }
    let axiomValue : PsKernelAxiomInfo :=
      { base := base, isUnsafe := false }
    decls := psKernelEnvironmentIndexInsert decls
      (PsKernelConstantInfo.axiomInfo axiomValue)
  for k in [:40] do
    let name := PsKernelName.num PsKernelName.anonymous k
    let bucket := psKernelEnvironmentIndexFind decls name
    let found := bucket.any (fun info =>
      psKernelNameEq (psKernelConstantInfoName info) name)
    if !found then
      throw (IO.userError "C0 radix declaration index lost a name")
  let replaceName := PsKernelName.num PsKernelName.anonymous 5
  let replacement : PsKernelConstantInfo :=
    PsKernelConstantInfo.axiomInfo
      { base := { name := replaceName, levelParams := [], type := sort1 },
        isUnsafe := false }
  let updated := psKernelEnvironmentIndexInsert decls replacement
  let foundUpdated := (psKernelEnvironmentIndexFind updated replaceName).any
    (fun info => psKernelNameEq (psKernelConstantInfoName info) replaceName &&
      psKernelExprEqual (psKernelConstantInfoType info) sort1)
  if !foundUpdated then
    throw (IO.userError "C0 radix declaration index lost replacement")
  IO.println "C0_PERF_REGRESSION radix_declaration_index=pass"
  -- Check the local-context transition across the eight-declaration
  -- threshold, persistent shadowing, and complete lookup equivalence.
  let mut locals := psKernelLocalContextEmpty
  for k in [:40] do
    let name := PsKernelName.num PsKernelName.anonymous k
    locals := psKernelLocalContextAddLocal locals name name
      sort0 PsKernelBinderInfo.default
  for k in [:45] do
    let name := PsKernelName.num PsKernelName.anonymous k
    let expected := psKernelLocalContextFindIn name locals.decls
    let actual := psKernelLocalContextFind locals name
    match expected, actual with
    | Option.none, Option.none => pure ()
    | Option.some x, Option.some y =>
        if !(psKernelNameEq (psKernelLocalDeclName x)
              (psKernelLocalDeclName y) &&
              psKernelExprEqual (psKernelLocalDeclType x)
                (psKernelLocalDeclType y)) then
          throw (IO.userError "C0 indexed locals disagreed with linear lookup")
    | _, _ =>
        throw (IO.userError "C0 indexed locals changed presence")
  let shadowName := PsKernelName.num PsKernelName.anonymous 5
  let shadowed := psKernelLocalContextAddLet locals shadowName
    shadowName sort1 sort0
  match psKernelLocalContextFind shadowed shadowName with
  | Option.some decl =>
      if !(psKernelExprEqual (psKernelLocalDeclType decl) sort1) then
        throw (IO.userError "C0 indexed local shadowing failed")
  | Option.none =>
      throw (IO.userError "C0 indexed local shadow missing")
  match psKernelLocalContextFind locals shadowName with
  | Option.some decl =>
      if !(psKernelExprEqual (psKernelLocalDeclType decl) sort0) then
        throw (IO.userError "C0 indexed context mutated persistent predecessor")
  | Option.none =>
      throw (IO.userError "C0 original local context lost its entry")
  IO.println "C0_PERF_REGRESSION indexed_local_shadowing=pass"

  -- A local index is non-semantic acceleration: no construction before
  -- depth 33, exact lookup and shadowing on both sides of promotion, and
  -- immutable older snapshots with no index.
  let threshold := psKernelC0LocalIndexThreshold
  let mut smallCtx := psKernelLocalContextEmpty
  for k in [:threshold] do
    let name := PsKernelName.num PsKernelName.anonymous k
    smallCtx := psKernelLocalContextAddLocal smallCtx name name
      sort0 PsKernelBinderInfo.default
  match smallCtx.index with
  | Option.none => pure ()
  | Option.some _ => throw (IO.userError "C0 short context eagerly indexed")
  let deepName := PsKernelName.num PsKernelName.anonymous threshold
  let deepCtx := psKernelLocalContextAddLet smallCtx deepName
    deepName sort1 sort0
  match deepCtx.index with
  | Option.none => throw (IO.userError "C0 deep context missed radix promotion")
  | Option.some _ => pure ()
  for ctx in [smallCtx, deepCtx] do
    for k in [:threshold + 3] do
      let name := PsKernelName.num PsKernelName.anonymous k
      match psKernelLocalContextFindIn name ctx.decls,
          psKernelLocalContextFind ctx name with
      | Option.none, Option.none => pure ()
      | Option.some expected, Option.some actual =>
          if !(psKernelNameEq (psKernelLocalDeclName expected)
              (psKernelLocalDeclName actual) &&
              psKernelExprEqual (psKernelLocalDeclType expected)
                (psKernelLocalDeclType actual)) then
            throw (IO.userError "C0 delayed local indexing changed result")
      | _, _ => throw (IO.userError "C0 delayed local lookup changed presence")
  if smallCtx.nextIndex != threshold || deepCtx.nextIndex != threshold + 1 then
    throw (IO.userError "C0 delayed local index changed fresh-name counter")
  IO.println "C0_PERF_REGRESSION deferred_local_index_promotion=pass"

  -- Recursor continuations may advance fresh names without adding locals.
  -- The exact declaration count must remain independent of nextIndex,
  -- preventing premature index promotion and keeping shadowing unchanged.
  let jumpedBase := psKernelLocalContextWithNextIndex locals 1024
  let jumpedName := PsKernelName.num PsKernelName.anonymous 1024
  let jumped := psKernelLocalContextAddLocal jumpedBase jumpedName
    jumpedName sort0 PsKernelBinderInfo.default
  if jumped.declCount != locals.declCount + 1 ||
      jumped.nextIndex != 1025 then
    throw (IO.userError "C0 continuation corrupted local count or fresh counter")
  match jumped.index with
  | none => pure ()
  | some _ => throw (IO.userError "C0 continuation promoted short local context")
  match psKernelLocalContextFind jumped jumpedName with
  | some found =>
      if !(psKernelNameEq (psKernelLocalDeclName found) jumpedName) then
        throw (IO.userError "C0 continuation lost fresh local")
  | none => throw (IO.userError "C0 continuation fresh local missing")
  IO.println "C0_PERF_REGRESSION exact_local_count_independent_of_fresh_names=pass"

  -- Force the immutable local-index thunk only beyond the deep lookup
  -- threshold. The same stored context must be safely reused, while
  -- snapshots predating a shadowed declaration remain unchanged.
  let mut lazyDeep := psKernelLocalContextEmpty
  for i in [:psKernelC0LocalIndexLookupThreshold + 8] do
    let name := PsKernelName.num PsKernelName.anonymous i
    lazyDeep := psKernelLocalContextAddLocal lazyDeep name name
      sort0 PsKernelBinderInfo.default
  match lazyDeep.index with
  | none => throw (IO.userError "C0 deep lazy context has no available snapshot")
  | some _ => pure ()
  for _ in [:3] do
    for k in [0, 1, 8, 60, 127, 128, 191,
        psKernelC0LocalIndexLookupThreshold - 1,
        psKernelC0LocalIndexLookupThreshold + 7,
        psKernelC0LocalIndexLookupThreshold + 8] do
      let name := PsKernelName.num PsKernelName.anonymous k
      match psKernelLocalContextFindIn name lazyDeep.decls,
          psKernelLocalContextFind lazyDeep name with
      | none, none => pure ()
      | some before, some after =>
          if !(psKernelNameEq (psKernelLocalDeclName before)
              (psKernelLocalDeclName after) &&
              psKernelExprEqual (psKernelLocalDeclType before)
                (psKernelLocalDeclType after)) then
            throw (IO.userError "C0 lazy indexed local lookup changed declaration")
      | _, _ => throw (IO.userError "C0 lazy indexed local lookup changed presence")
  let lazyShadowName := PsKernelName.num PsKernelName.anonymous 8
  let lazyShadow := psKernelLocalContextAddLet lazyDeep lazyShadowName
    lazyShadowName sort1 sort0
  match psKernelLocalContextFind lazyShadow lazyShadowName,
      psKernelLocalContextFind lazyDeep lazyShadowName with
  | some newDecl, some previousDecl =>
      if !(psKernelExprEqual (psKernelLocalDeclType newDecl) sort1 &&
          psKernelExprEqual (psKernelLocalDeclType previousDecl) sort0) then
        throw (IO.userError "C0 lazy snapshot shadowing or persistence changed")
  | _, _ => throw (IO.userError "C0 lazy snapshot shadowed name missing")
  IO.println "C0_PERF_REGRESSION forced_lazy_local_snapshot=pass"
  -- A persistent indexed snapshot plus a small overlay must preserve
  -- precedence for a new shadowing let, including the batch commit edge.
  let mut pendingCtx := deepCtx
  for k in [:psKernelC0LocalIndexBatchSize - 1] do
    let name := PsKernelName.num PsKernelName.anonymous
      (threshold + 1 + k)
    pendingCtx := psKernelLocalContextAddLocal pendingCtx name name
      sort0 PsKernelBinderInfo.default
  if pendingCtx.pendingCount != psKernelC0LocalIndexBatchSize - 1 ||
      pendingCtx.pending.length != psKernelC0LocalIndexBatchSize - 1 then
    throw (IO.userError "C0 batched local context lost pending entries")
  let oldPending := pendingCtx
  let shadowKey := PsKernelName.num PsKernelName.anonymous 3
  let committed := psKernelLocalContextAddLet pendingCtx shadowKey
    shadowKey sort1 sort0
  if committed.pendingCount != 0 || !committed.pending.isEmpty then
    throw (IO.userError "C0 local index failed to publish pending batch")
  match psKernelLocalContextFind committed shadowKey with
  | Option.none => throw (IO.userError "C0 committed local shadow missing")
  | Option.some decl =>
      if !(psKernelExprEqual (psKernelLocalDeclType decl) sort1) then
        throw (IO.userError "C0 committed local shadow selected older entry")
  match psKernelLocalContextFind oldPending shadowKey with
  | Option.none => throw (IO.userError "C0 predecessor lost shadowed local")
  | Option.some decl =>
      if !(psKernelExprEqual (psKernelLocalDeclType decl) sort0) then
        throw (IO.userError "C0 batched local update mutated predecessor")
  for ctx in [deepCtx, oldPending, committed] do
    for k in [:threshold + psKernelC0LocalIndexBatchSize + 3] do
      let name := PsKernelName.num PsKernelName.anonymous k
      match psKernelLocalContextFindIn name ctx.decls,
          psKernelLocalContextFind ctx name with
      | Option.none, Option.none => pure ()
      | Option.some a, Option.some b =>
          if !(psKernelNameEq (psKernelLocalDeclName a)
              (psKernelLocalDeclName b) &&
              psKernelExprEqual (psKernelLocalDeclType a)
                (psKernelLocalDeclType b)) then
            throw (IO.userError "C0 local overlay lookup diverged")
      | _, _ =>
          throw (IO.userError "C0 local overlay changed entry presence")
  IO.println "C0_PERF_REGRESSION batched_local_context_shadowing=pass"


  -- The UTF-8 optimized fingerprint is identical to the original decoder
  -- for ASCII, multi-byte scalar values and mixed names at varied seeds.
  for value in ["", "a", "abc", "A.B", "βeta", "中文", "emoji 😀"] do
    for seed in [0, 1, 17, 65520] do
      let old :=
        psKernelEnvironmentHashStringWorker
          (Nat.succ (String.utf8ByteSize value))
          value 0 seed
      let fast := psKernelC0HashStringFrom value seed
      if !(Nat.beq old fast) then
        throw (IO.userError "C0 UTF-8 fingerprint changed semantics")
  IO.println "C0_PERF_REGRESSION native_utf8_hash=pass"





  -- Exact recursive-expression <-> indexed-node bridge.
  -- Compare *full* syntax, not alpha or definitional equality: binder
  -- names, metadata, info and nondependent let flags must survive.
  let named := PsKernelName.str PsKernelName.anonymous "c0.bridge"
  let leftSort := PsKernelExpr.sort PsKernelLevel.zero
  let rightSort := PsKernelExpr.sort
    (PsKernelLevel.succ PsKernelLevel.zero)
  let binder := PsKernelExpr.lam named leftSort
    (PsKernelExpr.app (PsKernelExpr.bvar 0)
      (PsKernelExpr.lit (PsKernelLiteral.nat 123)))
    PsKernelBinderInfo.implicit
  let piTerm := PsKernelExpr.forallE named rightSort binder
    PsKernelBinderInfo.strictImplicit
  let letTerm := PsKernelExpr.letE named rightSort
    (PsKernelExpr.const named [PsKernelLevel.zero])
    piTerm true
  let metadata := PsKernelExpr.mdata 29
    (PsKernelExpr.proj named 3 letTerm)
  let examples := [
    PsKernelExpr.bvar 0, PsKernelExpr.fvar named,
    PsKernelExpr.mvar named, leftSort, rightSort,
    PsKernelExpr.const named [PsKernelLevel.zero],
    PsKernelExpr.lit (PsKernelLiteral.nat 7654321),
    PsKernelExpr.lit (PsKernelLiteral.str "βeta 中文"),
    binder, piTerm, letTerm, metadata
  ]
  let mut interned := psKernelC0StoreEmpty
  for expr in examples do
    match psKernelC0EncodeExpr interned expr with
    | Option.none => throw (IO.userError "C0 indexed encode rejected valid syntax")
    | Option.some (next, id) =>
        match psKernelC0DecodeExpr next id with
        | Option.none => throw (IO.userError "C0 indexed decode failed")
        | Option.some restored =>
            if !(psKernelExprEqual expr restored) then
              throw (IO.userError "C0 indexed bridge changed exact syntax")
        match psKernelC0EncodeExpr next expr with
        | Option.some (again, id2) =>
            if !(Nat.beq id id2 && Nat.beq next.nodes.size again.nodes.size) then
              throw (IO.userError "C0 indexed re-encoding broke identity")
        | Option.none => throw (IO.userError "C0 indexed re-encoding failed")
        interned := next
  match psKernelC0DecodeExpr interned interned.nodes.size with
  | Option.none => pure ()
  | Option.some _ => throw (IO.userError "C0 decoder accepted invalid handle")
  IO.println "C0_PERF_REGRESSION indexed_expr_roundtrip=pass"


  -- Demand-driven application-spine WHNF must preserve the old outcomes.
  -- This directly exercises the accepting Lean engine, not the Rust sketch.
  let context := psKernelCheckerContextEmpty psKernelEnvironmentEmpty
  let stopped := PsKernelExpr.app
    (PsKernelExpr.app (PsKernelExpr.mvar named) leftSort) rightSort
  match psKernelWhnfNoRecursor 4096 context psKernelCheckerStateEmpty stopped with
  | Except.error message =>
      throw (IO.userError ("C0 stuck-spine WHNF error: " ++ message))
  | Except.ok (result, _) =>
      if !(psKernelExprEqual result stopped) then
        throw (IO.userError "C0 WHNF changed stuck application spine")
  let identity := PsKernelExpr.lam named leftSort
    (PsKernelExpr.bvar 0) PsKernelBinderInfo.default
  let beta := PsKernelExpr.app identity rightSort
  match psKernelWhnfNoRecursor 4096 context psKernelCheckerStateEmpty beta with
  | Except.error message =>
      throw (IO.userError ("C0 beta WHNF error: " ++ message))
  | Except.ok (result, _) =>
      if !(psKernelExprEqual result rightSort) then
        throw (IO.userError "C0 WHNF lost beta reduction")
  let reducibleHead := PsKernelExpr.letE named leftSort
    identity (PsKernelExpr.bvar 0) false
  let zetaBeta := PsKernelExpr.app reducibleHead rightSort
  match psKernelWhnfNoRecursor 4096 context psKernelCheckerStateEmpty zetaBeta with
  | Except.error message =>
      throw (IO.userError ("C0 zeta-beta WHNF error: " ++ message))
  | Except.ok (result, _) =>
      if !(psKernelExprEqual result rightSort) then
        throw (IO.userError "C0 WHNF changed reducible application head")
  IO.println "C0_PERF_REGRESSION demand_driven_whnf=pass"

  -- Native indexed de Bruijn rewrite must match the current Lean expression
  -- substitution exactly, including binder shifting and changed let bodies.
  for expr in examples do
    for replacement in [PsKernelExpr.bvar 0, PsKernelExpr.bvar 3,
        leftSort, binder, metadata] do
      match psKernelC0EncodeExpr psKernelC0StoreEmpty expr with
      | Option.none =>
          throw (IO.userError "C0 indexed substitution setup failed")
      | Option.some (st1, inputId) =>
          match psKernelC0EncodeExpr st1 replacement with
          | Option.none =>
              throw (IO.userError "C0 indexed replacement setup failed")
          | Option.some (st2, replacementId) =>
              match psKernelC0Instantiate1Indexed st2 inputId replacementId with
              | Option.none =>
                  throw (IO.userError "C0 indexed substitution failed")
              | Option.some (st3, resultId) =>
                  match psKernelC0DecodeExpr st3 resultId with
                  | Option.none =>
                      throw (IO.userError "C0 indexed rewritten expression is invalid")
                  | Option.some result =>
                      let expected := psKernelExprInstantiate1 expr replacement
                      if !(psKernelExprEqual result expected) then
                        throw (IO.userError "C0 indexed beta substitution differs from reference")
  IO.println "C0_PERF_REGRESSION indexed_beta_substitution=pass"

  -- Every index-reused application contains two references to the same
  -- child. Without per-(term, binder-depth) memoization, substitution would
  -- revisit an exponentially growing logical tree.
  match psKernelC0Intern psKernelC0StoreEmpty (.bvar 0) with
  | Option.none => throw (IO.userError "C0 shared-DAG leaf admission failed")
  | Option.some (seedStore, seedId) =>
      match psKernelC0Intern seedStore (.bvar 42) with
      | Option.none => throw (IO.userError "C0 shared-DAG replacement failed")
      | Option.some (seed2, replacementId) =>
          let mut dagStore := seed2
          let mut dagId := seedId
          for _ in [:24] do
            match psKernelC0Intern dagStore (.app dagId dagId) with
            | Option.none => throw (IO.userError "C0 shared DAG construction failed")
            | Option.some (next, nextId) =>
                dagStore := next
                dagId := nextId
          match psKernelC0Instantiate1Indexed dagStore dagId replacementId with
          | Option.none => throw (IO.userError "C0 memoized DAG rewrite failed")
          | Option.some (rewritten, resultId) =>
              if !(psKernelC0StoreValid rewritten resultId) then
                throw (IO.userError "C0 rewrite produced invalid handle")
              if rewritten.nodes.size > 90 then
                throw (IO.userError "C0 DAG rewrite lost structural sharing")
  IO.println "C0_PERF_REGRESSION memoized_indexed_dag=pass"

  -- Invariant of the canonical term store: cached looseBVarRange is
  -- exactly max loose index + 1, independent of hash collisions/sharing.
  -- Confirm against the independent recursive expression predicate at
  -- every tested binder offset; no cached metadata is used as a proof.
  let metadataExamples := [
    PsKernelExpr.bvar 0,
    PsKernelExpr.bvar 4,
    PsKernelExpr.app (PsKernelExpr.bvar 3) (PsKernelExpr.bvar 1),
    PsKernelExpr.lam named leftSort (PsKernelExpr.bvar 1)
      PsKernelBinderInfo.default,
    PsKernelExpr.forallE named (PsKernelExpr.bvar 3)
      (PsKernelExpr.bvar 0) PsKernelBinderInfo.implicit,
    PsKernelExpr.letE named leftSort rightSort
      (PsKernelExpr.bvar 2) false,
    PsKernelExpr.mdata 8 (PsKernelExpr.bvar 3),
    PsKernelExpr.proj named 0 (PsKernelExpr.bvar 2),
    PsKernelExpr.lam named leftSort
      (PsKernelExpr.lam named rightSort (PsKernelExpr.bvar 0)
        PsKernelBinderInfo.default) PsKernelBinderInfo.default
  ]
  for term in metadataExamples do
    match psKernelC0EncodeExpr psKernelC0StoreEmpty term with
    | none => throw (IO.userError "C0 loose range encoding failed")
    | some (stored, id) =>
        match psKernelC0StoreGet stored id with
        | none => throw (IO.userError "C0 loose range root absent")
        | some entry =>
            for offset in [:8] do
              let expected := psKernelExprHasLooseAt term offset
              let actual := entry.looseBVarRange > offset
              if !(psKernelBoolEq expected actual) then
                throw (IO.userError "C0 indexed loose-range metadata disagreed with recursive reference")
            for replacement in [PsKernelExpr.bvar 0, PsKernelExpr.bvar 4, leftSort] do
              match psKernelC0EncodeExpr stored replacement with
              | none => throw (IO.userError "C0 loose range replacement encode failed")
              | some (prepared, replacementId) =>
                  match psKernelC0Instantiate1Indexed prepared id replacementId,
                        psKernelC0Instantiate1IndexedReference prepared id replacementId with
                  | some (memoStore, memoId), some (referenceStore, referenceId) =>
                      match psKernelC0DecodeExpr memoStore memoId,
                            psKernelC0DecodeExpr referenceStore referenceId with
                      | some optimized, some reference =>
                          if !(psKernelExprEqual optimized reference) then
                            throw (IO.userError "C0 loose-range pruning changed indexed substitution")
                      | _, _ =>
                          throw (IO.userError "C0 loose-range indexed decode failed")
                  | _, _ =>
                      throw (IO.userError "C0 loose-range indexed rewrite failed")
                for start in [0, 1, 3, 6] do
                  match psKernelC0LiftIndexed stored id start 2 with
                  | some (liftStore, liftId) =>
                      match psKernelC0DecodeExpr liftStore liftId with
                      | some optimized =>
                          let reference := psKernelExprLiftLooseBVars term start 2
                          if !(psKernelExprEqual optimized reference) then
                            throw (IO.userError "C0 loose-range pruning changed indexed lift")
                      | none =>
                          throw (IO.userError "C0 loose-range lifted result undecodable")
                  | none =>
                      throw (IO.userError "C0 loose-range indexed lift failed")
  IO.println "C0_PERF_REGRESSION cached_indexed_loose_bvar_range=pass"

  -- Indexed WHNF is not an accepting checker, but its supported
  -- beta/zeta/spine fragment must agree with native expression normalization.
  let indexedIdentity := PsKernelExpr.lam named leftSort
    (PsKernelExpr.bvar 0) PsKernelBinderInfo.default
  let nestedIdentity := PsKernelExpr.lam named leftSort
    (PsKernelExpr.lam named leftSort
      (PsKernelExpr.bvar 1) PsKernelBinderInfo.default)
    PsKernelBinderInfo.default
  let doubleApply := PsKernelExpr.app
    (PsKernelExpr.app nestedIdentity leftSort) rightSort
  let metadataOnly := PsKernelExpr.mdata 10 rightSort
  for (term, expected) in [
    (stopped, stopped),
    (PsKernelExpr.app indexedIdentity rightSort, rightSort),
    (zetaBeta, rightSort),
    (doubleApply, leftSort),
    (metadataOnly, rightSort)
  ] do
    match psKernelC0EncodeExpr psKernelC0StoreEmpty term with
    | Option.none => throw (IO.userError "C0 WHNF encode failed")
    | Option.some (store, id) =>
        match psKernelC0IndexedWhnf 4096 store id with
        | Option.none => throw (IO.userError "C0 indexed WHNF exhausted unexpectedly")
        | Option.some (next, resultId) =>
            match psKernelC0DecodeExpr next resultId with
            | Option.none => throw (IO.userError "C0 indexed WHNF decode failed")
            | Option.some result =>
                if !(psKernelExprEqual result expected) then
                  throw (IO.userError "C0 indexed WHNF semantic disagreement")
  IO.println "C0_PERF_REGRESSION indexed_beta_zeta_whnf=pass"

  -- A stuck indexed spine must retain the *exact* original term handle
  -- without allocating a second application chain.
  match psKernelC0EncodeExpr psKernelC0StoreEmpty stopped with
  | Option.none => throw (IO.userError "C0 stuck spine encoding failed")
  | Option.some (st, id) =>
      match psKernelC0IndexedWhnf 4096 st id with
      | Option.some (next, resultId) =>
          if !(Nat.beq id resultId &&
               Nat.beq st.nodes.size next.nodes.size) then
            throw (IO.userError "C0 stuck indexed spine rebuilt unnecessarily")
      | Option.none => throw (IO.userError "C0 stuck indexed spine rejected")

  -- The no-reconstruction shortcut must NOT return the original handle
  -- when metadata disappears from an application head.
  let metadataHead := PsKernelExpr.app
    (PsKernelExpr.mdata 99 (PsKernelExpr.mvar named)) rightSort
  let metadataReduced := PsKernelExpr.app (PsKernelExpr.mvar named) rightSort
  match psKernelC0EncodeExpr psKernelC0StoreEmpty metadataHead with
  | Option.none => throw (IO.userError "C0 metadata-head encoding failed")
  | Option.some (st, id) =>
      match psKernelC0IndexedWhnf 4096 st id with
      | Option.some (next, resultId) =>
          if Nat.beq id resultId then
            throw (IO.userError "C0 indexed metadata incorrectly reused original")
          match psKernelC0DecodeExpr next resultId with
          | Option.some restored =>
              if !(psKernelExprEqual restored metadataReduced) then
                throw (IO.userError "C0 metadata-head rewrite changed meaning")
          | Option.none => throw (IO.userError "C0 metadata-head decoder rejected result")
      | Option.none => throw (IO.userError "C0 indexed metadata-head rejected")
  IO.println "C0_PERF_REGRESSION indexed_stuck_spine_identity=pass"



  -- Native accepting-beta helper: single-argument specialization agrees with
  -- the historical generic list-instantiation path, including multi-spines.
  for (fn, supplied) in [
    (indexedIdentity, [rightSort]),
    (nestedIdentity, [leftSort, rightSort]),
    (nestedIdentity, [leftSort]),
    (indexedIdentity, [rightSort, leftSort])
  ] do
    match psKernelC0BetaSpinePlan fn supplied with
    | Option.none =>
        throw (IO.userError "C0 beta-spine plan unexpectedly missing")
    | Option.some plan =>
        let body := Prod.fst plan
        let selected := Prod.fst (Prod.snd plan)
        let remaining := Prod.snd (Prod.snd plan)
        let oldResult := psKernelExprApplyArgsCheap
          (psKernelExprInstantiate body selected) remaining
        let newResult := psKernelC0BetaSpineApply plan
        if !(psKernelExprEqual oldResult newResult) then
          throw (IO.userError "C0 specialized WHNF beta changed expression")
  IO.println "C0_PERF_REGRESSION beta_single_specialization=pass"

  -- Binder-family dispatch: the lightweight closed-term probe may skip
  -- substitution only if the generic simultaneous-instantiation oracle
  -- confirms that no loose de Bruijn variable is affected. Exercise
  -- deeply closed and genuinely open binder bodies, plus let and lambdas.
  let binderName := PsKernelName.str PsKernelName.anonymous "C0BinderProbe"
  let closedPi := PsKernelExpr.forallE binderName sort0
    (PsKernelExpr.forallE binderName sort0 sort1
      PsKernelBinderInfo.default) PsKernelBinderInfo.default
  let openPi := PsKernelExpr.forallE binderName sort0
    (PsKernelExpr.bvar 1) PsKernelBinderInfo.default
  let openLam := PsKernelExpr.lam binderName sort0
    (PsKernelExpr.bvar 1) PsKernelBinderInfo.default
  let closedLet := PsKernelExpr.letE binderName sort0 sort1
    sort0 false
  let openLet := PsKernelExpr.letE binderName sort0 sort0
    (PsKernelExpr.bvar 1) false
  for expr in [closedPi, openPi, openLam, closedLet, openLet] do
    for replacement in [sort0, sort1, PsKernelExpr.bvar 3] do
      let expected := psKernelExprInstantiate expr [replacement]
      let actual := psKernelExprInstantiate1 expr replacement
      if !(psKernelExprEqual expected actual) then
        throw (IO.userError "C0 binder-probe instantiation differs from generic reference")
  IO.println "C0_PERF_REGRESSION instantiate1_binder_family=pass"

  -- Independently retained fuel-bounded original substitution worker checks
  -- the entire family, not merely the new generic C0 entry. Generate varied
  -- binder depths and embed the bound-variable case into every expression
  -- constructor that can carry a substitutable child.
  let oracleName := PsKernelName.str PsKernelName.anonymous "C0SubstOracle"
  for depth in [0, 1, 2, 4, 8, 12] do
    let mut nested := PsKernelExpr.bvar (depth + 1)
    for i in [:depth] do
      nested := PsKernelExpr.forallE
        (PsKernelName.num oracleName i) sort0 nested
        PsKernelBinderInfo.default
    let forms := [
      nested,
      PsKernelExpr.lam oracleName sort0 nested PsKernelBinderInfo.default,
      PsKernelExpr.letE oracleName sort0 sort0 nested false,
      PsKernelExpr.app nested sort1,
      PsKernelExpr.mdata depth nested,
      PsKernelExpr.proj oracleName depth nested
    ]
    for term in forms do
      for replacement in [sort0, PsKernelExpr.bvar 2] do
        let reference := psKernelExprInstantiateAtChangedWithFuel
          (Nat.succ (psKernelExprNodeCount term))
          term 0 [replacement] 0
        let actual := psKernelExprInstantiate1 term replacement
        if !(psKernelExprEqual (Prod.fst reference) actual) then
          throw (IO.userError "C0 instantiated term differs from independent old worker")
  IO.println "C0_PERF_REGRESSION instantiate1_independent_binder_oracle=pass"

