import Ps.KernelCore.API.DagMutualRecursiveArgument
import Ps.KernelCore.Research.ExprV2PagedImport
import Ps.KernelCore.Core.ExprV2.Decode
import Lean

private def expect {α : Type} : Except String α → IO α
  | .ok value => pure value
  | .error error => throw (IO.userError error)
private def direct {α : Type} : Option (Except String α) → IO α
  | some result => expect result
  | none => throw (IO.userError "private header declined")
private def require (label : String) (ok : Bool) : IO Unit := do
  unless ok do throw (IO.userError ("PSC1_MUTUAL_RECURSIVE_FAIL " ++ label))
  IO.println ("PSC1_MUTUAL_RECURSIVE_ASSERT " ++ label)
private def nm (s : String) := PsKernelName.str .anonymous s
private def a := nm "ResultA"
private def b := nm "ResultB"
private def c := nm "ResultC"
private def other := nm "Other"
private def s1 := PsKernelExpr.sort (.succ .zero)
private def s2 := PsKernelExpr.sort (.succ (.succ .zero))
private def all (n : String) (domain body : PsKernelExpr) :=
  PsKernelExpr.forallE (nm n) domain body .default
private def rootType := all "P" s1 s1
private def secondType := all "P" s1 (all "i" s1 s1)
private def thirdType := all "P" s1 (all "i" s1 (all "j" s1 s1))

private def fixture : IO (PsKernelExprV2MutualHeaderAnalysis ×
    PsKernelOpenBindersResult × List PsKernelSimpleMutualTypeShape) := do
  let first := PsKernelSimpleMutualTypeDecl.mk a rootType []
  let second := PsKernelSimpleMutualTypeDecl.mk b secondType []
  let third := PsKernelSimpleMutualTypeDecl.mk c thirdType []
  let session := psKernelMkCheckerSession psKernelEnvironmentEmpty [] .safe
    0 psKernelLeanNatMaxSizeDefault
  let checked ← expect (psKernelSessionCheck 256 session first.type)
  let sorted ← expect (psKernelSessionEnsureSort 256 checked.snd checked.fst)
  let parameters ← expect (psKernelOpenSimpleHeaderParams 256 sorted.snd first.type 1)
  let indices ← expect (psKernelOpenSimpleHeaderIndices 256 parameters.session parameters.result)
  let remaining ← expect (psKernelOpenSimpleMutualRemainingTypesWorker [second,third]
    256 psKernelEnvironmentEmpty [] .safe 0 psKernelLeanNatMaxSizeDefault
    parameters.session parameters.binders (.succ .zero))
  let shapes := PsKernelSimpleMutualTypeShape.mk first indices.binders :: remaining
  let mut arena := psKernelExprV2PagedEmpty
  let mut types := []
  for declaration in [first,second,third] do
    let (next,root) ← expect (psKernelExprV2PagedImportIntoChecked arena declaration.type)
    arena := next
    types := types ++ [PsKernelDagInductive.mk declaration.name root []]
  let actual ← direct (psKernelExprV2MutualAnalyzeHeaderWithFuel 256 psKernelEnvironmentEmpty
    0 psKernelLeanNatMaxSizeDefault arena [] ⟨[],1,types,false⟩)
  require "checked-shared-header-parameter-names"
    (parameters.binders.length == actual.parameters.binders.length &&
      (parameters.binders.zip actual.parameters.binders).all
        (fun (x,y) => psKernelNameEq x.internalName y.internalName))
  pure (actual,parameters,shapes)

private def decode (arena : PsKernelExprV2PagedArena) (root : Nat) : IO PsKernelExpr := do
  let graph ← expect (psKernelExprV2DecodeChecked arena)
  expect (psKernelExprV2DecodedRequire graph root)

private def sameBinder (arena : PsKernelExprV2PagedArena)
    (left : PsKernelOpenBinder) (right : PsKernelExprV2OrdinaryOpenBinder) : IO Bool := do
  pure (psKernelNameEq left.internalName right.internalName &&
    psKernelNameEq left.userName right.userName &&
    psKernelBinderInfoEq left.binderInfo right.binderInfo &&
    psKernelExprEqual left.type (← decode arena right.type))

private def sameResult (left : Except String PsKernelMutualRecursiveArgumentResult)
    (right : Option (Except String PsKernelExprV2MutualRecursiveArgumentResult)) : IO Bool := do
  match left,right with
  | .error a,some (.error b) => pure (a == b)
  | .ok a,some (.ok b) =>
      let arena := b.state.whnf.arena
      let mut equal := a.session.state.nextFresh == b.state.nextFresh
      equal := equal && a.session.context.localContext.decls.length == b.context.locals.length
      for (x,y) in a.session.context.localContext.decls.zip b.context.locals do
        equal := equal && psKernelNameEq (psKernelLocalDeclName x) y.name &&
          psKernelNameEq (psKernelLocalDeclUserName x) y.userName &&
          psKernelExprEqual (psKernelLocalDeclType x) (← decode arena y.type)
      match a.recursiveInfo,b.recursiveInfo with
      | none,none => pure equal
      | some x,some y =>
          equal := equal && (← sameBinder arena x.field y.field) &&
            x.target == y.target && x.args.length == y.arguments.length &&
            x.indices.length == y.indices.length
          for (v,w) in x.args.zip y.arguments do
            equal := equal && (← sameBinder arena v w)
          for (v,w) in x.indices.zip y.indices do
            equal := equal && psKernelExprEqual v (← decode arena w)
          pure equal
      | _,_ => pure false
  | _,_ => pure false

private def recursiveMatrix (analysis : PsKernelExprV2MutualHeaderAnalysis)
    (parameters : PsKernelOpenBindersResult) (shapes : List PsKernelSimpleMutualTypeShape) : IO Unit := do
  let parameter ← match parameters.binders with
    | [] => throw (IO.userError "missing checked shared parameter")
    | first :: _ => pure (PsKernelExpr.fvar first.internalName)
  let decl := PsKernelSimpleMutualInductiveDecl.mk [] 1 (shapes.map (·.decl)) false
  let work := psKernelAddMutualInductiveInfos
    (psKernelMakeSimpleMutualBaseInfos [a,b,c] decl shapes) psKernelEnvironmentEmpty
  let oldParent := psKernelSessionWithEnvironment parameters.session work
  let parentContext := PsKernelExprV2CheckContext.mk
    (psKernelCheckerContextWithEnvironment analysis.parameters.context.scalar work)
    analysis.parameters.context.locals
  let references := analysis.types.map (fun h =>
    PsKernelExprV2DeclarationRef.mk h.declaration.name [] h.declaration.type none .inductiveDecl)
  let base := analysis.parameters.state
  let parentState := psKernelExprV2CheckStateWithWhnf base
    (PsKernelExprV2WhnfState.mk analysis.arena base.whnf.coreCache base.whnf.publicCache references)
  let ta := psKernelApplyArgs (.const a []) [parameter]
  let tb := psKernelApplyArgs (.const b []) [parameter,s1]
  let tc := psKernelApplyArgs (.const c []) [parameter,s1,s2]
  let nested := PsKernelExpr.app ta s1
  let terms := [ta,tb,tc,s1,parameter,
    .mdata 5 ta,.mdata 3 tb,
    .app (.lam (nm "z") s1 ta .default) s1,
    .letE (nm "z") s1 s1 tb false,
    all "x" s1 ta,all "x" s1 (all "y" s1 tb),
    all "x" (.mdata 7 s1) tc,
    all "x" ta s1,all "x" (.mdata 9 tb) ta,
    all "x" (.proj c 0 s1) ta,
    nested,.mdata 2 nested,
    psKernelApplyArgs (.const b []) [parameter,ta],
    .app (.const a [.zero]) parameter,
    .forallE (nm "x") s1 (psKernelApplyArgs (.const b []) [parameter,.bvar 0]) .implicit]
  for (term,i) in terms.zipIdx do
    let (owner,root) ← expect (psKernelExprV2PagedImportIntoChecked parentState.whnf.arena term)
    let state := psKernelExprV2CheckStateWithArena parentState owner
    let oldOpened := psKernelSessionWithLocal oldParent (nm "field") term .default
    let oldField := PsKernelOpenBinder.mk oldOpened.fst (nm "field") term .default
    let opened ← expect (psKernelExprV2CheckOpenBinder parentContext state (nm "field") root root .default)
    let field := PsKernelExprV2OrdinaryOpenBinder.mk opened.fresh (nm "field") root .default
    for fuel in [0,1,8,256] do
      let left := psKernelAnalyzeSimpleMutualRecursiveArgument fuel oldOpened.snd
        [a,b,c] shapes [] parameters.binders oldField term
      let right := psKernelExprV2MutualAnalyzeRecursiveArgumentWithFuel fuel
        opened.context opened.parent [a,b,c] analysis.types [] analysis.parameters.binders field root
      require ("frozen-original-recursive-" ++ toString i ++ "-fuel-" ++ toString fuel)
        (← sameResult left right)
    let poison := fun (_fuel : Nat) (_context : PsKernelExprV2CheckContext)
        (_state : PsKernelExprV2CheckState) (_root : Nat) =>
      some (Except.error "UNEXPECTED_WHNF")
    let attempted := psKernelExprV2MutualAnalyzeRecursiveArgumentWorker 1 0 poison
      opened.context opened.parent [a,b,c] analysis.types [] analysis.parameters.binders field root []
    if i < 3 then
      require ("structural-selection-precedes-poison-whnf-" ++ toString i)
        (match attempted with | some (.ok _) => true | _ => false)
    if i == 3 then
      require "structural-zero-precedes-even-valid-domain"
        (match psKernelExprV2MutualAnalyzeRecursiveArgumentWorker 0 256 poison
            opened.context opened.parent [a,b,c] analysis.types [] analysis.parameters.binders field root [] with
         | some (.error error) => error == "mutual recursive-argument budget exhausted"
         | _ => false)
      require "whnf-decline-propagates"
        ((psKernelExprV2MutualAnalyzeRecursiveArgumentWorker 1 8
          (fun _ _ _ _ => none) opened.context opened.parent [a,b,c] analysis.types []
          analysis.parameters.binders field root []).isNone)
      require "whnf-error-propagates"
        (match attempted with | some (.error error) => error == "UNEXPECTED_WHNF" | _ => false)
      require "missing-count-root-hard-error-before-whnf"
        (match psKernelExprV2MutualAnalyzeRecursiveArgumentWith poison 8 opened.context opened.parent
            [a,b,c] analysis.types [] analysis.parameters.binders field opened.parent.whnf.arena.size with
         | some (.error error) => error != "UNEXPECTED_WHNF"
         | _ => false)

def main : IO Unit := do
  let (analysis,parameters,shapes) ← fixture
  recursiveMatrix analysis parameters shapes
  IO.println "PSC1_MUTUAL_RECURSIVE_NATIVE: PASS assertions=88 frozen=80 direct=3 boundaries=4 header=1"
