import Ps.KernelCore.API.DagNestedPreprocess
import Ps.KernelCore.API.Kernel
import Ps.KernelCore.Core.ExprV2.Decode
import Ps.KernelCore.Research.ExprV2PagedImport
import Lean

private def expect {α : Type} : Except String α → IO α
  | .ok x => pure x
  | .error e => throw (IO.userError e)
private def acceptPublic {α : Type} : Except PsKernelError α → IO α
  | .ok x => pure x
  | .error _ => throw (IO.userError "fixture public admission failed")
private def require (label : String) (value : Bool) : IO Unit := do
  unless value do throw (IO.userError ("PSC1_NESTED_PREPROCESS_FAIL " ++ label))
  IO.println ("PSC1_NESTED_PREPROCESS_ASSERT " ++ label)
private def nm (s : String) := PsKernelName.str .anonymous s
private def s1 := PsKernelExpr.sort (.succ .zero)
private def all (n : String) (domain body : PsKernelExpr) := PsKernelExpr.forallE (nm n) domain body .default
private def sameExprs (a b : List PsKernelExpr) : Bool :=
  a.length == b.length && (a.zip b).all (fun p => psKernelExprEqual p.1 p.2)
private def sameTypes (a b : List PsKernelSimpleMutualTypeDecl) : Bool :=
  a.length == b.length && (a.zip b).all (fun p =>
    psKernelNameEq p.1.name p.2.name && psKernelExprEqual p.1.type p.2.type &&
    p.1.ctors.length == p.2.ctors.length && (p.1.ctors.zip p.2.ctors).all (fun c =>
      psKernelNameEq c.1.name c.2.name && psKernelExprEqual c.1.type c.2.type))
private def sameFamilies (a b : List PsKernelSimpleNestedAuxFamily) : Bool :=
  a.length == b.length && (a.zip b).all (fun p =>
    psKernelNameEq p.1.auxName p.2.auxName && psKernelNameEq p.1.outerName p.2.outerName &&
    p.1.outerLevels.length == p.2.outerLevels.length &&
    (p.1.outerLevels.zip p.2.outerLevels).all (fun l => psKernelLevelEq l.1 l.2) &&
    sameExprs p.1.fixedParams p.2.fixedParams && psKernelExprEqual p.1.nestedTemplate p.2.nestedTemplate &&
    p.1.ctorMap.length == p.2.ctorMap.length && (p.1.ctorMap.zip p.2.ctorMap).all (fun c =>
      psKernelNameEq c.1.auxCtor c.2.auxCtor && psKernelNameEq c.1.outerCtor c.2.outerCtor))
private def sameProcessed (a b : PsKernelSimpleNestedProcessQueueResult) : Bool :=
  sameTypes a.types b.types && sameFamilies a.state.aux b.state.aux &&
  a.state.fresh == b.state.fresh && sameTypes a.state.created b.state.created
private def build (decl : PsKernelSimpleMutualInductiveDecl) :
    IO (PsKernelExprV2PagedArena × PsKernelDagInductiveGroup) := do
  let mut arena := psKernelExprV2PagedEmpty
  let mut types := []
  for t in decl.types do
    let (next,root) ← expect (psKernelExprV2PagedImportIntoChecked arena t.type)
    arena := next
    let mut ctors := []
    for c in t.ctors do
      let (next,root) ← expect (psKernelExprV2PagedImportIntoChecked arena c.type)
      arena := next
      ctors := ctors ++ [PsKernelDagConstructor.mk c.name root]
    types := types ++ [PsKernelDagInductive.mk t.name root ctors]
  pure (arena,⟨decl.levelParams,decl.numParams,types,decl.isUnsafe⟩)
private def originalPrefix (fuel : Nat) (environment : PsKernelEnvironment)
    (decl : PsKernelSimpleMutualInductiveDecl) : Except String PsKernelOpenBindersResult := do
  psKernelSimpleNestedCheckReserved decl
  psKernelSimpleCheckUniformOccurrences (psKernelSimpleMutualNames decl.types)
    decl.levelParams decl.numParams (psKernelSimpleMutualCtorTypes decl.types)
  match decl.types with
  | [] => throw "empty nested inductive declaration"
  | first :: _ =>
      let safety := if decl.isUnsafe then PsKernelDefinitionSafety.unsafeDef else .safe
      let initial := psKernelMkCheckerSession environment decl.levelParams safety 0 psKernelLeanNatMaxSizeDefault
      let checked ← psKernelSessionCheck fuel initial first.type
      let sorted ← psKernelSessionEnsureSort fuel checked.snd checked.fst
      psKernelOpenSimpleHeaderParams fuel sorted.snd first.type decl.numParams
private def compare (label : String) (session : PsKernelKernelSession)
    (decl : PsKernelSimpleMutualInductiveDecl) (expectAux : Bool) : IO Unit := do
  let (arena,value) ← build decl
  let input ← expect (psKernelExprV2DecodeChecked arena)
  let owner ← expect (psKernelDagGeneratedFromSession session arena input)
  let params ← expect (originalPrefix 256 session.environment decl)
  let original ← expect (psKernelSimpleNestedProcessQueue 256 session.environment decl.levelParams
    (psKernelSimpleMutualNames decl.types) params.binders decl.numParams decl.types [] ⟨[],1,[]⟩)
  let some attempted := psKernelExprV2NestedPreprocessWithFuel 256 session.environment 0
    psKernelLeanNatMaxSizeDefault input owner value | throw (IO.userError "private preprocessing declined")
  let actual ← expect attempted
  require (label ++ "-whole-plan-parity") (sameProcessed original actual.processed)
  require (label ++ "-exact-auxiliary-presence") (actual.processed.state.aux.isEmpty == !expectAux)
  require (label ++ "-synchronized-append-only-owner")
    (owner.arena.size ≤ actual.owner.arena.size && actual.owner.built.size == actual.owner.arena.size)
  for root in List.range input.size do
    let old ← expect (psKernelExprV2DecodedRequire input root)
    let new ← expect (psKernelExprV2DecodedRequire actual.owner.built root)
    unless psKernelExprEqual old new do throw (IO.userError "original input prefix changed")
  require (label ++ "-all-original-input-roots-retained") true
  let oldCount := psKernelEnvironmentSize session.environment
  discard (acceptPublic (psKernelV1AdmitDeclaration session (.nestedInductive decl)))
  require (label ++ "-actual-original-complete-admission-accepts")
    (psKernelEnvironmentSize session.environment == oldCount)

def main : IO Unit := do
  let mut failed := false
  try require "forced-failure" false catch _ => failed := true
  require "harness-rejection-active" failed
  let empty ← acceptPublic (psKernelKernelSessionEmpty psKernelResourcePolicyDefault psKernelProviderDefault)
  let enumName := nm "NestedPlanEnum"
  compare "no-aux-enum" empty ⟨[],0,[⟨enumName,s1,[⟨PsKernelName.str enumName "mk",.const enumName []⟩]⟩],false⟩ false
  let boxName := nm "NestedPlanBox"
  let box : PsKernelSimpleInductiveDecl := ⟨[],boxName,all "A" s1 s1,
    [⟨PsKernelName.str boxName "mk",all "A" s1
      (all "value" (.bvar 0) (.app (.const boxName []) (.bvar 1)))⟩],false,1⟩
  let boxed ← acceptPublic (psKernelV1AdmitDeclaration empty (.ordinaryInductive box))
  let name := nm "NestedPlanOwner"
  let self := PsKernelExpr.const name []
  let nested := PsKernelExpr.app (.const boxName []) self
  let single : PsKernelSimpleMutualInductiveDecl := ⟨[],0,[⟨name,s1,
    [⟨PsKernelName.str name "mk",all "child" nested self⟩]⟩],false⟩
  compare "genuine-nested-box" boxed.session single true
  let repeated : PsKernelSimpleMutualInductiveDecl := {single with types := [⟨name,s1,
    [⟨PsKernelName.str name "left",all "child" nested self⟩,
     ⟨PsKernelName.str name "right",all "child" nested self⟩]⟩]}
  compare "repeated-template-reuses-family" boxed.session repeated true
  let deep := PsKernelExpr.app (.const boxName []) nested
  let twice : PsKernelSimpleMutualInductiveDecl := {single with types := [⟨name,s1,
    [⟨PsKernelName.str name "mk",all "child" deep self⟩]⟩]}
  compare "nested-discovery-queue" boxed.session twice true
  IO.println "PSC1_NESTED_PREPROCESS_NATIVE: PASS privateOnly=true publicRouteChanged=false"
