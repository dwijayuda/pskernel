import Ps.KernelCore.Core.IndexedExpr
import Ps.KernelCore.Runtime.Acceleration.EnvironmentIndex
import Ps.KernelCore.Checker.Session

/- Native checker regression only. No bootstrap or self-host tests.
   The old metatheory equated arbitrary terms, while the executable
   conversion checker must reject distinct universe sorts. -/

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
  match psKernelSessionIsDefEq 4096 session sort0 sort1 with
  | Except.error message =>
      throw (IO.userError ("unexpected sort comparison error: " ++ message))
  | Except.ok result =>
      if Prod.fst result then
        throw (IO.userError "unsound: Sort 0 equated with Sort 1")
      else
        IO.println "C0_PROOF_AUDIT sort0_sort1_distinct=pass"
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
