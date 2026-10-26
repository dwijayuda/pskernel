import Ps.KernelCore.API.Dag
import Lean

private def nm (s : String) := PsKernelName.str .anonymous s
private def s1 := PsKernelExpr.sort (.succ .zero)
private def all (n : String) (a b : PsKernelExpr) := PsKernelExpr.forallE (nm n) a b .default
private def name := nm "NestedHygieneProbe"
private def ctorName := PsKernelName.str name "mk"
private def capturedName := PsKernelName.num (psKernelSimpleInternalName "nestedCtorParam") 0
private def make (malformed : Bool) : PsKernelSimpleInductiveDecl :=
  ⟨[],name,all "A" s1 s1,[⟨ctorName,all "A" s1
    (all "x" (if malformed then .fvar capturedName else .bvar 0)
      (.app (.const name []) (.bvar 1)))⟩],false,1⟩
private def officialName : PsKernelName → Lean.Name
  | .anonymous => .anonymous
  | .str p s => .str (officialName p) s
  | .num p n => .num (officialName p) n
private def officialDeclaration (malformed : Bool) : Lean.Declaration :=
  let n := officialName name
  let u := Lean.Expr.sort (.succ .zero)
  let domain := if malformed then Lean.Expr.fvar (Lean.FVarId.mk (officialName capturedName)) else .bvar 0
  let header : Lean.Expr := .forallE `A u u .default
  let constructorType : Lean.Expr := .forallE `A u (.forallE `x domain (.app (.const n []) (.bvar 1)) .default) .default
  let ctorValue : Lean.Constructor := { name := officialName ctorName, type := constructorType }
  let declaration : Lean.InductiveType := { name := n, type := header, ctors := [ctorValue] }
  .inductDecl [] 1 [declaration] false
private def verdict {α : Type} : Except PsKernelError α → String
  | .ok _ => "accepted"
  | .error (.rejectedInvalid e) => "rejectedInvalid: " ++ e
  | .error _ => "other-error"

def main : IO Unit := do
  let .ok session := psKernelKernelSessionEmpty psKernelResourcePolicyDefault psKernelProviderDefault
    | throw (IO.userError "session fixture")
  Lean.initSearchPath (← Lean.findSysroot)
  let official ← Lean.importModules #[{module := `Init}] {}
  let goodOfficial := official.addDeclCore 0 0 (officialDeclaration false) none true
  let badOfficial := official.addDeclCore 0 0 (officialDeclaration true) none true
  let ordinaryGood := psKernelV1AdmitDeclaration session (.ordinaryInductive (make false))
  let ordinaryBad := psKernelV1AdmitDeclaration session (.ordinaryInductive (make true))
  let nestedGood := psKernelV1AdmitDeclaration session (.nestedInductive
    ⟨[],1,[⟨name,(make false).type,(make false).ctors⟩],false⟩)
  let nestedBad := psKernelV1AdmitDeclaration session (.nestedInductive
    ⟨[],1,[⟨name,(make true).type,(make true).ctors⟩],false⟩)
  unless goodOfficial.isOk && !badOfficial.isOk && ordinaryGood.isOk && !ordinaryBad.isOk && nestedGood.isOk do
    throw (IO.userError "positive/negative oracle controls did not establish the probe")
  let captured := nestedBad.isOk
  let publishedMatchesCorrected := match nestedBad with
    | .error _ => false
    | .ok result => match psKernelEnvironmentFind result.session.environment ctorName with
      | some (.ctorInfo info) => match (make false).ctors with
        | [] => false
        | c :: _ => psKernelExprEqual info.base.type c.type
      | _ => false
  let report := Lean.Json.mkObj [
    ("schema","psc1-original-nested-hygiene-diagnostic-v1"),
    ("source",Lean.toJson ((← IO.getEnv "GITHUB_SHA").getD "")),
    ("pinnedLean","eb6cafb7290e8bd5f2937522d8d804f58f02bafc"),
    ("officialValidAccepted",Lean.toJson goodOfficial.isOk),
    ("officialFreeVariableRejected",Lean.toJson (!badOfficial.isOk)),
    ("ordinaryValid",Lean.toJson (verdict ordinaryGood)),
    ("ordinaryFreeVariable",Lean.toJson (verdict ordinaryBad)),
    ("nestedValid",Lean.toJson (verdict nestedGood)),
    ("nestedCollidingFreeVariable",Lean.toJson (verdict nestedBad)),
    ("observedCapturedFreeVariableAccepted",Lean.toJson captured),
    ("publishedConstructorMatchesDifferentClosedInput",Lean.toJson publishedMatchesCorrected),
    ("diagnosticOnly",Lean.toJson true),("kernelQualified",Lean.toJson false)]
  let some directory ← IO.getEnv "RUNNER_TEMP" | throw (IO.userError "RUNNER_TEMP missing")
  let target := System.FilePath.mk directory / "nested-hygiene"
  IO.FS.createDirAll target
  IO.FS.writeFile (target / "diagnostic.json") (report.pretty ++ "\n")
  IO.println ("PSC1_NESTED_HYGIENE_DIAGNOSTIC: " ++ report.compress)

  unless !captured && !publishedMatchesCorrected do
    throw (IO.userError "nested constructor parameter capture regression")
  let expected := "rejectedInvalid: nested preprocessing: declaration has free variables"
  unless verdict nestedBad == expected do throw (IO.userError "exact nested capture rejection changed")
  IO.println "PSC1_NESTED_PARAM_HYGIENE_ASSERT actual-Lean-and-original-public-closure-parity"
  IO.println "PSC1_NESTED_PARAM_HYGIENE_ASSERT exact-rejection-and-no-publication"
  let f := PsKernelExpr.fvar capturedName
  let wrappers : List (String × PsKernelExpr) := [
    ("leaf",f),("app-fn",.app f s1),("app-arg",.app s1 f),
    ("lambda-domain",.lam (nm "x") f s1 .default),
    ("lambda-body",.lam (nm "x") s1 f .default),
    ("forall-domain",all "x" f s1),("forall-body",all "x" s1 f),
    ("let-domain",.letE (nm "x") f s1 s1 false),
    ("let-value",.letE (nm "x") s1 f s1 false),
    ("let-body",.letE (nm "x") s1 s1 f false),
    ("metadata",.mdata 7 f),("projection",.proj (nm "Q") 0 f)]
  for (label,type) in wrappers do
    unless psKernelSimpleNestedCtorParamCapture type 1 do
      throw (IO.userError ("missed capture at " ++ label))
    IO.println ("PSC1_NESTED_PARAM_HYGIENE_ASSERT capture-" ++ label)
  let paramNamespace :=  psKernelSimpleInternalName "nestedCtorParam"
  unless !psKernelSimpleNestedCtorParamCapture (.fvar (.num paramNamespace 1)) 1 &&
      psKernelSimpleNestedCtorParamCapture (.fvar (.num paramNamespace 1)) 2 &&
      !psKernelSimpleNestedCtorParamCapture (.fvar (.num paramNamespace 1000000000000000000)) 1 &&
      !psKernelSimpleNestedCtorParamCapture (.fvar (nm "other")) 1 &&
      !psKernelSimpleNestedCtorParamCapture f 0 do
    throw (IO.userError "parameter namespace/index scope changed")
  IO.println "PSC1_NESTED_PARAM_HYGIENE_ASSERT exact-namespace-arbitrary-indices-zero-fastpath"
  let shape := psKernelSimpleNestedOpenConstructorParams f 1
  unless (match shape with | .error "nested preprocessing constructor parameter mismatch" => true | _ => false) do
    throw (IO.userError "original parameter shape error no longer first")
  IO.println "PSC1_NESTED_PARAM_HYGIENE_ASSERT original-shape-error-precedes-capture-guard"
  let inputOwner := PsKernelDagGeneratedState.mk psKernelExprV2PagedEmpty psKernelExprV2DecodedEmpty []
  let .ok header := psKernelDagGeneratedImport (make true).type inputOwner
    | throw (IO.userError "graph header fixture")
  let c :: _ := (make true).ctors | throw (IO.userError "constructor fixture")
  let .ok ctorImported := psKernelDagGeneratedImport c.type header.fst
    | throw (IO.userError "graph constructor fixture")
  let request := PsKernelDagDeclarationRequest.nestedInductive
    ⟨[],1,[⟨name,header.snd,[⟨ctorName,ctorImported.snd⟩]⟩],false⟩
  let dag := psKernelV1RunDag session [] .safe ctorImported.fst.arena [.admit request]
  unless verdict dag == expected && psKernelEnvironmentSize session.environment == 0 do
    throw (IO.userError "public DAG closure/atomicity mismatch")
  IO.println "PSC1_NESTED_PARAM_HYGIENE_ASSERT public-DAG-original-fallback-rejects-atomically"
  IO.println "PSC1_NESTED_PARAM_HYGIENE_NATIVE: PASS controls=17 actualPinnedLean=true validInputsAccepted=true"
