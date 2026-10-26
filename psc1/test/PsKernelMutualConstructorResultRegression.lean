import Ps.KernelCore.API.DagMutualConstructorResult
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
  unless ok do throw (IO.userError ("PSC1_MUTUAL_RESULT_FAIL " ++ label))
  IO.println ("PSC1_MUTUAL_RESULT_ASSERT " ++ label)
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

private def containsMatrix (arena : PsKernelExprV2PagedArena) : IO Unit := do
  let ca := PsKernelExpr.const a []
  let cb := PsKernelExpr.const b []
  let cc := PsKernelExpr.const c []
  let co := PsKernelExpr.const other []
  let free := PsKernelExpr.fvar (nm "free")
  let terms := [ca,cb,cc,co,s1,free,.app co ca,
    .lam (nm "x") ca free .default,
    .forallE (nm "x") free cb .implicit,
    .letE (nm "x") free ca cb false,
    .mdata 5 ca,.proj a 0 s1,.proj other 0 cb,
    .bvar 0,.mvar a,.lit (.nat 3),.lit (.str "Aé€😀"),
    .app (.lam (nm "x") co (.mdata 3 cc) .default) cb]
  let targets := [[],[a],[b,c],[a,b,c],[a,a]]
  for (term,i) in terms.zipIdx do
    let (owner,root) ← expect (psKernelExprV2PagedImportIntoChecked arena term)
    for (names,j) in targets.zipIdx do
      let actual ← expect (psKernelExprV2MutualContainsConstOnCanonical owner names root)
      require ("all-family-occurrence-" ++ toString i ++ "-" ++ toString j)
        (actual == psKernelSimpleMutualContainsConst names term)
  require "zero-structural-budget-precedes-lookup"
    (match psKernelExprV2MutualContainsConstWithFuel 0 arena [a,b,c] (arena.size+1) with
     | .error error => error == "PSKERNEL_V2_MUTUAL_CONTAINS_CONST_FUEL"
     | _ => false)
  require "missing-occurrence-root-is-error"
    (match psKernelExprV2MutualContainsConstOnCanonical arena [a,b,c] arena.size with
     | .error _ => true
     | _ => false)

private def appMatrix (analysis : PsKernelExprV2MutualHeaderAnalysis)
    (parameters : PsKernelOpenBindersResult) (shapes : List PsKernelSimpleMutualTypeShape) : IO Unit := do
  let first ← match parameters.binders with
    | [] => throw (IO.userError "missing checked shared parameter")
    | first :: _ => pure first
  let param := PsKernelExpr.fvar first.internalName
  let wrong := PsKernelExpr.fvar (nm "wrong")
  let ca := PsKernelExpr.const a []
  let cb := PsKernelExpr.const b []
  let cc := PsKernelExpr.const c []
  let co := PsKernelExpr.const other []
  let app := psKernelApplyArgs
  let terms := [app ca [param],app cb [param,s1],app cc [param,s1,s2],
    app cb [param,wrong],app co [param],ca,
    app cb [param],app ca [param,s1],
    app (.const a [.zero]) [param],app ca [wrong],
    app ca [.mdata 0 param],app (.mdata 0 ca) [param],
    app cb [param,ca],app cb [param,.proj a 0 s1],
    app cb [param,.app co cc],app cb [param,.letE (nm "x") s1 cb s1 false],
    app wrong [param],app cc [param,s1],app cc [param,s1,s2,s1],
    app cb [param,.mdata 0 (.proj other 0 cc)]]
  for (term,i) in terms.zipIdx do
    let (owner,root) ← expect (psKernelExprV2PagedImportIntoChecked analysis.arena term)
    let old := psKernelSimpleMutualAppInfo [a,b,c] shapes [] parameters.binders term
    let actual ← expect (psKernelExprV2MutualAppInfoOnCanonical owner [a,b,c]
      analysis.types [] analysis.parameters.binders root)
    let mut equal := false
    match old,actual with
    | none,none => equal := true
    | some left,some right =>
        equal := left.target == right.target && left.indices.length == right.indices.length
        for (oldIndex,newIndex) in left.indices.zip right.indices do
          equal := equal && psKernelExprEqual oldIndex (← decode owner newIndex)
        let spine ← expect (psKernelExprV2TransformAppSpineOnCanonical owner root)
        equal := equal && right.indices == spine.snd.drop 1
    | _,_ => pure ()
    require ("cross-family-application-" ++ toString i) equal
  require "missing-application-root-is-error"
    (match psKernelExprV2MutualAppInfoOnCanonical analysis.arena [a,b,c]
        analysis.types [] analysis.parameters.binders analysis.arena.size with
     | .error _ => true
     | _ => false)

def main : IO Unit := do
  let (analysis,parameters,shapes) ← fixture
  containsMatrix analysis.arena
  appMatrix analysis parameters shapes
  IO.println "PSC1_MUTUAL_RESULT_NATIVE: PASS assertions=114 occurrence=90 application=20 boundary=3 headers=1"
