import Ps.KernelCore.API.DagNestedHeader
import Ps.KernelCore.Core.ExprV2.Decode
import Ps.KernelCore.Research.ExprV2PagedImport
import Lean

private def expect {α : Type} : Except String α → IO α
  | .ok value => pure value
  | .error error => throw (IO.userError error)
private def require (label : String) (value : Bool) : IO Unit := do
  unless value do throw (IO.userError ("PSC1_NESTED_HEADER_FAIL " ++ label))
  IO.println ("PSC1_NESTED_HEADER_ASSERT " ++ label)
private def nm (s : String) := PsKernelName.str .anonymous s
private def s1 := PsKernelExpr.sort (.succ .zero)
private def all (domain body : PsKernelExpr) := PsKernelExpr.forallE (nm "A") domain body .default
private def group (type : PsKernelExpr) (params : Nat := 0) : PsKernelSimpleMutualInductiveDecl :=
  ⟨[],params,[⟨nm "NestedInitial",type,[]⟩],false⟩

-- Literal original prefix, stopping exactly before NestedProcessQueue. Negative
-- cases also compare the complete retained original function, preventing a
-- copied error-string reference from silently becoming the only oracle.
private def originalPrefix (fuel : Nat) (decl : PsKernelSimpleMutualInductiveDecl) :
    Except String PsKernelOpenBindersResult := do
  psKernelSimpleNestedCheckReserved decl
  psKernelSimpleCheckUniformOccurrences (psKernelSimpleMutualNames decl.types)
    decl.levelParams decl.numParams (psKernelSimpleMutualCtorTypes decl.types)
  match decl.types with
  | [] => throw "empty nested inductive declaration"
  | first :: _ =>
      let safety := if decl.isUnsafe then PsKernelDefinitionSafety.unsafeDef else .safe
      let session := psKernelMkCheckerSession psKernelEnvironmentEmpty decl.levelParams
        safety 0 psKernelLeanNatMaxSizeDefault
      let checked ← psKernelSessionCheck fuel session first.type
      let sorted ← psKernelSessionEnsureSort fuel checked.snd checked.fst
      psKernelOpenSimpleHeaderParams fuel sorted.snd first.type decl.numParams

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
private def decode (arena : PsKernelExprV2PagedArena) (root : Nat) : IO PsKernelExpr := do
  let decoded ← expect (psKernelExprV2DecodeChecked arena)
  expect (psKernelExprV2DecodedRequire decoded root)
private def sameOpen (old : PsKernelOpenBindersResult) (new : PsKernelExprV2OrdinaryOpenResult) : IO Bool := do
  if old.binders.length != new.binders.length || old.session.state.nextFresh != new.state.nextFresh then return false
  if !psKernelExprEqual old.result (← decode new.state.whnf.arena new.result) then return false
  for (a,b) in old.binders.zip new.binders do
    if !psKernelNameEq a.internalName b.internalName || !psKernelNameEq a.userName b.userName ||
        !psKernelBinderInfoEq a.binderInfo b.binderInfo ||
        !psKernelExprEqual a.type (← decode new.state.whnf.arena b.type) then return false
  pure true
private def compare (label : String) (fuel : Nat) (decl : PsKernelSimpleMutualInductiveDecl) : IO Unit := do
  let (arena,value) ← build decl
  let input ← expect (psKernelExprV2DecodeChecked arena)
  let actual := psKernelExprV2NestedAnalyzeHeaderWithFuel fuel psKernelEnvironmentEmpty 0
    psKernelLeanNatMaxSizeDefault input arena [] value
  match originalPrefix fuel decl,actual with
  | .ok old,some (.ok new) =>
      require (label ++ "-prefix-owner-parity") (← sameOpen old new.parameters)
  | .error old,some (.error new) =>
      require (label ++ "-prefix-exact-error") (old == new)
      match psKernelAddSimpleNestedInductive fuel psKernelEnvironmentEmpty decl 0 psKernelLeanNatMaxSizeDefault with
      | .error retained => require (label ++ "-actual-original-error") (retained == new)
      | .ok _ => throw (IO.userError ("actual original unexpectedly accepted " ++ label))
  | _,none => throw (IO.userError ("private nested header declined " ++ label))
  | _,_ => throw (IO.userError ("nested header outcome mismatch " ++ label))

def main : IO Unit := do
  let mut rejected := false
  try require "forced-failure" false catch _ => rejected := true
  require "harness-rejection-active" rejected
  compare "plain-sort" 256 (group s1)
  compare "parameter" 256 (group (all s1 s1) 1)
  compare "dependent-parameters" 256 (group (all s1 (all (.bvar 0) s1)) 2)
  compare "index-not-opened" 256 (group (all s1 (.bvar 0)) 1)
  compare "zero-parameters-do-not-open-indices" 256 (group (all s1 (.bvar 0)))
  compare "metadata" 256 (group (.mdata 7 s1))
  compare "beta" 256 (group (.app (.lam (nm "T") (.sort (.succ (.succ .zero))) (.bvar 0) .default) s1))
  compare "let" 256 (group (.letE (nm "T") (.sort (.succ (.succ .zero))) s1 (.bvar 0) false))
  compare "unsafe" 256 {group s1 with isUnsafe := true}
  compare "later-header-not-checked" 256 ⟨[],0,[⟨nm "First",s1,[]⟩,⟨nm "Second",.mvar (nm "bad"),[]⟩],false⟩
  compare "duplicate-names-not-guarded-here" 256 ⟨[],0,[⟨nm "Same",s1,[]⟩,⟨nm "Same",s1,[]⟩],false⟩
  compare "duplicate-levels-not-guarded-here" 256 {group s1 with levelParams := [nm "u",nm "u"]}
  compare "empty" 256 ⟨[],0,[],false⟩
  compare "mvar" 256 (group (.mvar (nm "m")))
  compare "fvar" 256 (group (.fvar (nm "f")))
  compare "too-many-parameters" 256 (group s1 1)
  compare "zero-fuel" 0 (group s1)
  compare "reserved-type-name" 256 ⟨[],0,[⟨PsKernelName.str psKernelSimpleNestedPrefix "User",s1,[]⟩],false⟩
  compare "reserved-type-expression-before-mvar" 256 (group (.app (.const psKernelSimpleNestedPrefix []) (.mvar (nm "m"))))
  compare "reserved-ctor-name" 256 ⟨[],0,[⟨nm "T",s1,[⟨PsKernelName.str psKernelSimpleNestedPrefix "mk",s1⟩]⟩],false⟩
  compare "reserved-ctor-expression" 256 ⟨[],0,[⟨nm "T",s1,[⟨nm "mk",.proj psKernelSimpleNestedPrefix 0 s1⟩]⟩],false⟩
  compare "uniform-before-first-mvar" 256 ⟨[],1,[⟨nm "T",.mvar (nm "m"),[⟨nm "mk",.const (nm "T") []⟩]⟩],false⟩
  let (arena,value) ← build (group s1)
  let input ← expect (psKernelExprV2DecodeChecked arena)
  let declined := psKernelExprV2NestedAnalyzeHeaderWith (fun _ _ _ _ => none) (fun _ _ _ _ => none)
    256 psKernelEnvironmentEmpty 0 psKernelLeanNatMaxSizeDefault input arena [] value
  require "injected-decline-remains-decline" declined.isNone
  let error := psKernelExprV2NestedAnalyzeHeaderWith (fun _ _ _ _ => some (.error "injected"))
    (fun _ _ _ _ => none) 256 psKernelEnvironmentEmpty 0 psKernelLeanNatMaxSizeDefault input arena [] value
  require "injected-error-no-fallback" (match error with | some (.error "injected") => true | _ => false)
  IO.println "PSC1_NESTED_HEADER_NATIVE: PASS privateOnly=true publicRouteChanged=false"
