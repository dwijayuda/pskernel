import Ps.KernelCore.API.DagMutualConstructorAnalysis
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
  unless ok do throw (IO.userError ("PSC1_MUTUAL_CONSTRUCTOR_FAIL " ++ label))
  IO.println ("PSC1_MUTUAL_CONSTRUCTOR_ASSERT " ++ label)
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

private def sameConstructor (left : Except String PsKernelAddMutualConstructorsResult)
    (right : Option (Except String PsKernelExprV2MutualConstructorAnalysis)) : IO Bool := do
  match left,right with
  | .error a,some (.error b) => pure (a == b)
  | .ok a,some (.ok b) =>
      let x ← match a.shapes with
        | [shape] => pure shape
        | _ => throw (IO.userError "expected exactly one original constructor shape")
      let y := b.shape
      let arena := b.state.whnf.arena
      let mut equal := x.owner == y.owner && psKernelNameEq x.ctor.name y.ctor.name &&
        psKernelExprEqual x.ctor.type (← decode arena y.ctor.type) &&
        x.fields.length == y.fields.length && x.recursiveFields.length == y.recursiveFields.length &&
        x.resultIndices.length == y.resultIndices.length
      for (v,w) in x.fields.zip y.fields do equal := equal && (← sameBinder arena v w)
      for (v,w) in x.resultIndices.zip y.resultIndices do
        equal := equal && psKernelExprEqual v (← decode arena w)
      for (v,w) in x.recursiveFields.zip y.recursiveFields do
        equal := equal && (← sameBinder arena v.field w.field) && v.target == w.target &&
          v.args.length == w.arguments.length && v.indices.length == w.indices.length
        for (z,t) in v.args.zip w.arguments do equal := equal && (← sameBinder arena z t)
        for (z,t) in v.indices.zip w.indices do
          equal := equal && psKernelExprEqual z (← decode arena t)
      pure equal
  | _,_ => pure false

private def constructorMatrix (analysis : PsKernelExprV2MutualHeaderAnalysis)
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
  let ap := fun n => psKernelApplyArgs (.const a []) [.bvar n]
  let bp := fun n => psKernelApplyArgs (.const b []) [.bvar n,.bvar n]
  let cp := fun n => psKernelApplyArgs (.const c []) [.bvar n,.bvar n,.bvar n]
  let close := fun body => all "P" s1 body
  let terms := [close (ap 0),close (bp 0),close (cp 0),
    close (all "f" (ap 0) (ap 1)),close (all "f" (bp 0) (ap 1)),
    close (all "f" (cp 0) (bp 1)),
    close (all "f" (all "x" (.bvar 0) (ap 1)) (cp 1)),
    close (all "f" (all "x" (.bvar 0) (all "y" (.bvar 1) (bp 2))) (ap 1)),
    close (all "f" (.mdata 3 (all "x" (.bvar 0) (ap 1))) (ap 1)),
    close (all "f" (all "x" (ap 0) (.bvar 1)) (ap 1)),
    close (all "f" (.app (ap 0) s1) (ap 1)),
    close (all "f" s1 (ap 1)),close (all "f" s2 (ap 1)),
    close (all "f" (ap 0) (all "g" (bp 1) (cp 2))),
    .mdata 4 (close (ap 0)),
    .letE (nm "z") s1 s1 (close (ap 0)) false,
    .app (.lam (nm "T") s2 (.bvar 0) .default) (close (ap 0)),
    .mvar (nm "hole"),.fvar (nm "unbound"),
    all "P" s1 (PsKernelExpr.const a [.param (nm "undeclared")])]
  for (term,i) in terms.zipIdx do
    let (ownerArena,root) ← expect (psKernelExprV2PagedImportIntoChecked parentState.whnf.arena term)
    let state := psKernelExprV2CheckStateWithArena parentState ownerArena
    let ctor := PsKernelSimpleConstructorDecl.mk (nm ("ctor" ++ toString i)) term
    let dag := PsKernelDagConstructor.mk ctor.name root
    for (shape,owner) in shapes.zipIdx do
      for fuel in [0,8,256] do
        let left := psKernelAddSimpleMutualConstructorsForTypeWorker [ctor] fuel .safe
          analysis.resultLevel [] parameters.binders [a,b,c] shapes shape owner
          parameters.session work 0
        let right := psKernelExprV2MutualAnalyzeConstructorWithFuel fuel parentContext state
          [a,b,c] analysis.types owner [] analysis.parameters.binders analysis.resultLevel dag
        require ("frozen-original-constructor-" ++ toString i ++ "-owner-" ++ toString owner ++
          "-fuel-" ++ toString fuel) (← sameConstructor left right)
        if i < 3 && fuel == 256 && owner == i then
          require ("checked-correct-owner-" ++ toString owner)
            (match right with | some (.ok _) => true | _ => false)
        if i < 3 && fuel == 256 && owner == (i+1)%3 then
          require ("checked-wrong-owner-" ++ toString i)
            (match right with | some (.error error) => error == "mutual constructor returns the wrong datatype" | _ => false)
  let poison := fun (_fuel : Nat) (_context : PsKernelExprV2CheckContext)
      (_state : PsKernelExprV2CheckState) (_root : Nat) => some (Except.error "UNEXPECTED_CHECK")
  let never := fun (_fuel : Nat) (_context : PsKernelExprV2CheckContext)
      (_state : PsKernelExprV2CheckState) (_left _right : Nat) => none
  let missing := PsKernelDagConstructor.mk (nm "missing") parentState.whnf.arena.size
  require "missing-static-root-precedes-closed-check"
    (match psKernelExprV2MutualAnalyzeConstructorWith poison poison never 256
        parentContext parentState [a,b,c] analysis.types 0 [] analysis.parameters.binders
        analysis.resultLevel missing with
     | some (.error error) => error != "UNEXPECTED_CHECK"
     | _ => false)
  let invalidRoot ← expect (psKernelExprV2PagedImportIntoChecked parentState.whnf.arena s1)
  require "invalid-result-before-owner-comparison"
    (match psKernelExprV2MutualValidateConstructorResult invalidRoot.fst [a,b,c]
        analysis.types 999 [] analysis.parameters.binders invalidRoot.snd with
     | .error error => error == "mutual constructor has invalid return type"
     | _ => false)

def main : IO Unit := do
  let (analysis,parameters,shapes) ← fixture
  constructorMatrix analysis parameters shapes
  IO.println "PSC1_MUTUAL_CONSTRUCTOR_NATIVE: PASS assertions=189 frozen=180 correct=3 wrong=3 boundaries=2 header=1"
