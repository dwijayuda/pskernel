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
    let axiom : PsKernelAxiomInfo :=
      { base := base, isUnsafe := false }
    decls := psKernelEnvironmentIndexInsert decls
      (PsKernelConstantInfo.axiomInfo axiom)
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


