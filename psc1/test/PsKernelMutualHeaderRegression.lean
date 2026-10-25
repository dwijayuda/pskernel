import Ps.KernelCore.API.DagMutualHeader
import Ps.KernelCore.Research.ExprV2PagedImport
import Lean

/- The frozen prefix below uses only retained V1 operations and stops before
   provisional metadata. Native differential evidence for a private stage is
   not complete mutual admission. No public fallback supplies direct success. -/
private def expect {α : Type} : Except String α → IO α
  | .ok value => pure value
  | .error error => throw (IO.userError error)
private def require (label : String) (ok : Bool) : IO Unit := do
  unless ok do throw (IO.userError ("PSC1_MUTUAL_HEADER_FAIL " ++ label))
  IO.println ("PSC1_MUTUAL_HEADER_ASSERT " ++ label)
private def nm (s : String) := PsKernelName.str .anonymous s
private def s1 := PsKernelExpr.sort (.succ .zero)
private def s2 := PsKernelExpr.sort (.succ (.succ .zero))
private def all (n : String) (domain body : PsKernelExpr) :=
  PsKernelExpr.forallE (nm n) domain body .default
private def a := nm "T06MutualA"
private def b := nm "T06MutualB"
private def c := nm "T06MutualC"
private def u := nm "u"
private def v := nm "v"

private structure OldType where
  declaration : PsKernelSimpleMutualTypeDecl
  indices : PsKernelOpenBindersResult
private structure OldHeader where
  parameters : PsKernelOpenBindersResult
  types : List OldType
  resultLevel : PsKernelLevel

private def frozenRemaining (fuel : Nat) (environment : PsKernelEnvironment)
    (value : PsKernelSimpleMutualInductiveDecl) (depth maxNat : Nat)
    (parameters : PsKernelOpenBindersResult) (level : PsKernelLevel)
    (types : List PsKernelSimpleMutualTypeDecl) : Except String (List OldType) := do
  match types with
  | [] => pure []
  | declaration :: rest =>
      psKernelCheckNoMVarNoFVar declaration.type
      psKernelCheckLevelParams declaration.type value.levelParams
      let safety := if value.isUnsafe then PsKernelDefinitionSafety.unsafeDef else .safe
      let closed := psKernelMkCheckerSession environment value.levelParams safety depth maxNat
      let checked ← psKernelSessionCheck fuel closed declaration.type
      let _ ← psKernelSessionEnsureSort fuel checked.snd checked.fst
      let aligned ← psKernelOpenSimpleConstructorParams fuel parameters.session
        parameters.binders declaration.type
      let indices ← psKernelOpenSimpleHeaderIndices fuel aligned.session aligned.result
      match indices.result with
      | .sort other =>
          if !psKernelLevelEquivalent other level then
            throw "mutually inductive types must live in the same universe"
          pure (⟨declaration,indices⟩ :: (← frozenRemaining fuel environment value depth maxNat
            parameters level rest))
      | _ => throw "mutual inductive result must be a sort"

private def frozenHeader (fuel : Nat) (environment : PsKernelEnvironment)
    (value : PsKernelSimpleMutualInductiveDecl) (depth maxNat : Nat) : Except String OldHeader := do
  if psKernelNameHasDuplicates value.levelParams then throw "duplicate universe parameter"
  if psKernelNatLt (psKernelSimpleMutualTypeCount value.types) 2 then
    throw "mutual inductive admission requires at least two datatypes"
  let names := psKernelSimpleMutualNames value.types
  let allNames := psKernelMutualNameListAppend names
    (psKernelMutualNameListAppend (psKernelSimpleMutualRecNames value.types)
      (psKernelSimpleMutualCtorNames value.types))
  if !psKernelSimpleNameListUnique allNames then
    throw "duplicate inductive, constructor, or recursor name"
  psKernelCheckFreshInductiveNames allNames environment
  psKernelSimpleCheckUniformOccurrences names value.levelParams value.numParams
    (psKernelSimpleMutualCtorTypes value.types)
  match value.types with
  | [] => throw "empty mutual inductive declaration"
  | first :: remaining =>
      psKernelCheckNoMVarNoFVar first.type
      psKernelCheckLevelParams first.type value.levelParams
      let safety := if value.isUnsafe then PsKernelDefinitionSafety.unsafeDef else .safe
      let initial := psKernelMkCheckerSession environment value.levelParams safety depth maxNat
      let checked ← psKernelSessionCheck fuel initial first.type
      let sorted ← psKernelSessionEnsureSort fuel checked.snd checked.fst
      let parameters ← psKernelOpenSimpleHeaderParams fuel sorted.snd first.type value.numParams
      let indices ← psKernelOpenSimpleHeaderIndices fuel parameters.session parameters.result
      match indices.result with
      | .sort level => pure ⟨parameters,⟨first,indices⟩ ::
          (← frozenRemaining fuel environment value depth maxNat parameters level remaining),level⟩
      | _ => throw "simple inductive result must be a sort"

private def build (value : PsKernelSimpleMutualInductiveDecl) :
    IO (PsKernelExprV2PagedArena × PsKernelDagInductiveGroup) := do
  let mut arena := psKernelExprV2PagedEmpty
  let mut types := []
  for declaration in value.types do
    let (next,root) ← expect (psKernelExprV2PagedImportIntoChecked arena declaration.type)
    arena := next
    let mut ctors := []
    for ctor in declaration.ctors do
      let (next,root) ← expect (psKernelExprV2PagedImportIntoChecked arena ctor.type)
      arena := next
      ctors := ctors ++ [PsKernelDagConstructor.mk ctor.name root]
    types := types ++ [PsKernelDagInductive.mk declaration.name root ctors]
  pure (arena,⟨value.levelParams,value.numParams,types,value.isUnsafe⟩)

private def decode (arena : PsKernelExprV2PagedArena) (root : Nat) : IO PsKernelExpr := do
  let decoded ← expect (psKernelExprV2DecodeChecked arena)
  expect (psKernelExprV2DecodedRequire decoded root)
private def sameOpen (old : PsKernelOpenBindersResult)
    (actual : PsKernelExprV2OrdinaryOpenResult) : IO Bool := do
  if old.binders.length != actual.binders.length ||
      old.session.state.nextFresh != actual.state.nextFresh then return false
  if !psKernelExprEqual old.result (← decode actual.state.whnf.arena actual.result) then return false
  for (left,right) in old.binders.zip actual.binders do
    if !psKernelNameEq left.internalName right.internalName ||
        !psKernelNameEq left.userName right.userName ||
        !psKernelBinderInfoEq left.binderInfo right.binderInfo ||
        !psKernelExprEqual left.type (← decode actual.state.whnf.arena right.type) then return false
  pure true

private def compare (label : String) (fuel : Nat) (value : PsKernelSimpleMutualInductiveDecl)
    (environment : PsKernelEnvironment := psKernelEnvironmentEmpty) : IO Unit := do
  let (arena,group) ← build value
  let old := frozenHeader fuel environment value 0 psKernelLeanNatMaxSizeDefault
  let actual := psKernelExprV2MutualAnalyzeHeaderWithFuel fuel environment 0
    psKernelLeanNatMaxSizeDefault arena [] group
  match old,actual with
  | .error left,some (.error right) => require (label ++ "-exact-error") (left == right)
  | .ok left,some (.ok right) =>
      let mut equal ← sameOpen left.parameters right.parameters
      equal := equal && psKernelLevelEq left.resultLevel right.resultLevel &&
        left.types.length == right.types.length
      for (oldType,newType) in left.types.zip right.types do
        equal := equal && psKernelNameEq oldType.declaration.name newType.declaration.name &&
          (← sameOpen oldType.indices newType.indices)
        -- Every returned private ID must still denote the same term in the final arena.
        equal := equal && psKernelExprEqual oldType.indices.result
          (← decode right.arena newType.indices.result)
      require (label ++ "-complete-private-owner-parity") equal
  | _,none => throw (IO.userError ("direct mutual header declined: " ++ label))
  | _,_ => throw (IO.userError ("mutual header outcome mismatch: " ++ label))

private def group (ta tb : PsKernelExpr) (params : Nat := 0)
    (levels : List PsKernelName := []) : PsKernelSimpleMutualInductiveDecl :=
  ⟨levels,params,[⟨a,ta,[]⟩,⟨b,tb,[]⟩],false⟩

private def positives : List (String × PsKernelSimpleMutualInductiveDecl) :=
  [ ("two-enums",group s1 s1),
    ("shared-parameter",group (all "A" s1 s1) (all "B" s1 s1) 1),
    ("dependent-parameter",group (all "A" s1 (all "a" (.bvar 0) s1))
      (all "B" s1 (all "b" (.bvar 0) s1)) 2),
    ("different-indices",group (all "A" s1 (all "x" (.bvar 0) s1))
      (all "B" s1 (all "y" s1 s1)) 1),
    ("universe-parameters",group (all "A" (.sort (.param u)) (.sort (.param v)))
      (all "B" (.sort (.param u)) (.sort (.param v))) 1 [u,v]),
    ("later-index-freshness-isolation",⟨[],0,[⟨a,all "X" s1 s1,[]⟩,
      ⟨b,all "Y" s1 (all "y" (.bvar 0) s1),[]⟩,⟨c,all "Z" s1 s1,[]⟩],false⟩),
    ("beta-first",group (.app (.lam (nm "T") s2 (.bvar 0) .default) s1) s1),
    ("let-later",group s1 (.letE (nm "T") s2 s1 (.bvar 0) false)),
    ("metadata-index",group (.mdata 3 s1) (.mdata 4 s1)),
    ("unsafe-context",{ group s1 s1 with isUnsafe := true }),
    ("cross-family-uniform-occurrence",⟨[],1,
      [⟨a,all "A" s1 s1,[⟨nm "mkA",all "A" s1 (.app (.const b []) (.bvar 0))⟩]⟩,
       ⟨b,all "B" s1 s1,[]⟩],false⟩) ]

private def negatives : List (String × PsKernelSimpleMutualInductiveDecl) :=
  [ ("duplicate-level-before-count",⟨[u,u],0,[],false⟩),
    ("minimum-count-before-mvar",⟨[],0,[⟨a,.mvar a,[]⟩],false⟩),
    ("type-name-duplicate-before-mvar",⟨[],0,[⟨a,.mvar a,[]⟩,⟨a,s1,[]⟩],false⟩),
    ("recursor-name-collision",⟨[],0,[⟨a,s1,[]⟩,⟨psKernelSimpleRecName a,s1,[]⟩],false⟩),
    ("constructor-name-collision",⟨[],0,[⟨a,s1,[⟨b,.mvar a⟩]⟩,⟨b,s1,[]⟩],false⟩),
    ("uniform-before-first-static",⟨[],1,[⟨a,.mvar a,[⟨nm "bad",.const b []⟩]⟩,
      ⟨b,s1,[]⟩],false⟩),
    ("first-mvar",group (.mvar a) s1),
    ("later-mvar",group s1 (.mvar b)),
    ("later-fvar-before-level",group s1 (.app (.fvar a) (.sort (.param u)))),
    ("later-undeclared-level",group s1 (.sort (.param u))),
    ("later-illtyped",group s1 (.app s1 s1)),
    ("later-result-universe-mismatch",group s1 s2),
    ("later-parameter-type-mismatch",group (all "A" s1 s1) (all "B" s2 s1) 1),
    ("later-too-few-parameters",group (all "A" s1 s1) s1 1),
    ("later-not-sort-result",group s1 (all "A" s1 (.bvar 0))),
    ("first-not-sort-result",group (all "A" s1 (.bvar 0)) s1) ]

private def injectedScope : IO Unit := do
  let (arena,root) ← expect (psKernelExprV2PagedImportIntoChecked psKernelExprV2PagedEmpty s1)
  let value := PsKernelDagInductiveGroup.mk [] 0 [] false
  let context := psKernelExprV2MutualClosedContext psKernelEnvironmentEmpty value 0 0
  let shared := { psKernelExprV2CheckStateEmpty arena with nextFresh := 17 }
  let parameters := PsKernelExprV2OrdinaryOpenResult.mk context shared [] root
  let check := fun (_ : Nat) (_ : PsKernelExprV2CheckContext)
      (state : PsKernelExprV2CheckState) (_ : Nat) =>
    some (Except.ok ({ state with nextFresh := 999 },root))
  let whnf := fun (_ : Nat) (_ : PsKernelExprV2CheckContext)
      (state : PsKernelExprV2CheckState) (id : Nat) => some (Except.ok (state,id))
  let defeq := fun (_ : Nat) (_ : PsKernelExprV2CheckContext)
      (_ : PsKernelExprV2CheckState) (_ _ : Nat) => none
  match psKernelExprV2MutualRemainingPhasesWith check whnf defeq 16 context
      (psKernelExprV2MutualClosedState arena []) parameters root (.succ .zero) with
  | some (.ok indices) => require "injected-closed-freshness-discarded"
      (indices.state.nextFresh == 17 && indices.context.locals.isEmpty)
  | _ => throw (IO.userError "injected owner did not finish")

def main : IO Unit := do
  for (label,value) in positives do compare label 256 value
  for (label,value) in negatives do compare label 256 value
  for fuel in [0,1,2,4,16] do
    compare ("fuel-" ++ toString fuel) fuel
      (group (all "A" s1 s1) (all "B" s1 s1) 1)
  injectedScope
  IO.println "PSC1_MUTUAL_HEADER_NATIVE: PASS assertions=33 positive=11 negative=16 budgets=5 injected=1"
