import Ps.KernelCore.API.DagMutualConstructorFields
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
  unless ok do throw (IO.userError ("PSC1_MUTUAL_FIELDS_FAIL " ++ label))
  IO.println ("PSC1_MUTUAL_FIELDS_ASSERT " ++ label)
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

private def sameFields (left : Except String PsKernelMutualOpenFieldsResult)
    (right : Option (Except String PsKernelExprV2MutualOpenFieldsResult)) : IO Bool := do
  match left,right with
  | .error a,some (.error b) => pure (a == b)
  | .ok a,some (.ok b) =>
      let arena := b.state.whnf.arena
      let mut equal := a.session.state.nextFresh == b.state.nextFresh &&
        a.session.context.localContext.decls.length == b.context.locals.length &&
        psKernelExprEqual a.result (← decode arena b.result) &&
        a.fields.length == b.fields.length && a.recursiveFields.length == b.recursiveFields.length
      for (x,y) in a.session.context.localContext.decls.zip b.context.locals do
        equal := equal && psKernelNameEq (psKernelLocalDeclName x) y.name &&
          psKernelNameEq (psKernelLocalDeclUserName x) y.userName &&
          psKernelExprEqual (psKernelLocalDeclType x) (← decode arena y.type)
      for (x,y) in a.fields.zip b.fields do
        equal := equal && (← sameBinder arena x y)
      for (x,y) in a.recursiveFields.zip b.recursiveFields do
        equal := equal && (← sameBinder arena x.field y.field) && x.target == y.target &&
          x.args.length == y.arguments.length && x.indices.length == y.indices.length
        for (v,w) in x.args.zip y.arguments do
          equal := equal && (← sameBinder arena v w)
        for (v,w) in x.indices.zip y.indices do
          equal := equal && psKernelExprEqual v (← decode arena w)
      pure equal
  | _,_ => pure false

private def fieldsMatrix (analysis : PsKernelExprV2MutualHeaderAnalysis)
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
  let tb := psKernelApplyArgs (.const b []) [parameter,parameter]
  let tc := psKernelApplyArgs (.const c []) [parameter,parameter,parameter]
  let funArg := all "x" parameter ta
  let terms := [ta,tb,tc,
    all "f" ta ta,all "f" tb ta,all "f" tc tb,
    all "f" funArg tc,
    all "f" (all "x" parameter (all "y" parameter tb)) ta,
    all "f" (.mdata 3 funArg) ta,
    all "f" (all "x" ta s1) ta,
    all "f" (.app ta s1) ta,
    all "f" (psKernelApplyArgs (.const b []) [parameter,ta]) ta,
    all "f" s1 ta,all "f" s2 ta,
    all "f" ta (all "g" tb tc),
    all "f" funArg (all "g" tc ta),
    .mdata 4 (all "f" ta ta),
    .letE (nm "z") s1 s1 (all "f" ta ta) false,
    .forallE (nm "f") ta (.app (.const b []) (.bvar 0)) .implicit,
    all "f" (.bvar 0) ta]
  for (term,i) in terms.zipIdx do
    let (owner,root) ← expect (psKernelExprV2PagedImportIntoChecked parentState.whnf.arena term)
    let state := psKernelExprV2CheckStateWithArena parentState owner
    for fuel in [0,1,8,256] do
      let left := psKernelOpenSimpleMutualConstructorFields fuel oldParent
        [a,b,c] shapes [] parameters.binders analysis.resultLevel term
      let right := psKernelExprV2MutualOpenConstructorFieldsWithFuel fuel parentContext state
        [a,b,c] analysis.types [] analysis.parameters.binders analysis.resultLevel root
      require ("frozen-original-fields-" ++ toString i ++ "-fuel-" ++ toString fuel)
        (← sameFields left right)
  let field := PsKernelExprV2OrdinaryOpenBinder.mk (nm "unused") (nm "unused") 0 .default
  let poisonCheck := fun (_fuel : Nat) (_context : PsKernelExprV2CheckContext)
      (_state : PsKernelExprV2CheckState) (_root : Nat) => some (Except.error "UNEXPECTED_CHECK")
  let poisonAnalyze := fun (_fuel : Nat) (_context : PsKernelExprV2CheckContext)
      (_state : PsKernelExprV2CheckState) (_targets : List PsKernelName)
      (_types : List PsKernelExprV2MutualTypeHeader) (_levels : List PsKernelLevel)
      (_params : List PsKernelExprV2OrdinaryOpenBinder) (_field : PsKernelExprV2OrdinaryOpenBinder)
      (_root : Nat) => some (Except.error "UNEXPECTED_ANALYZE")
  require "zero-precedes-lookup-and-all-callbacks"
    (match psKernelExprV2MutualOpenConstructorFieldsWorker 0 poisonCheck poisonCheck poisonAnalyze
        parentContext parentState [a,b,c] analysis.types [] analysis.parameters.binders
        analysis.resultLevel parentState.whnf.arena.size [field] [] with
     | some (.error error) => error == "mutual constructor field budget exhausted"
     | _ => false)
  require "missing-root-precedes-all-callbacks"
    (match psKernelExprV2MutualOpenConstructorFieldsWorker 1 poisonCheck poisonCheck poisonAnalyze
        parentContext parentState [a,b,c] analysis.types [] analysis.parameters.binders
        analysis.resultLevel parentState.whnf.arena.size [] [] with
     | some (.error error) => error != "UNEXPECTED_CHECK" && error != "UNEXPECTED_ANALYZE"
     | _ => false)

def main : IO Unit := do
  let (analysis,parameters,shapes) ← fixture
  fieldsMatrix analysis parameters shapes
  IO.println "PSC1_MUTUAL_FIELDS_NATIVE: PASS assertions=83 frozen=80 boundaries=2 header=1"
