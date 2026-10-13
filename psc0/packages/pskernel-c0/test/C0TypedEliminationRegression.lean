import Ps.KernelCore.Architecture.Work

/-!
CDE-8B: positive and negative typed elimination against REAL checked,
atomically admitted ordinary inductives, not synthetic recursor metadata.
The candidate never provides a proof or authorizes admission.
-/

def c0TypedName (s : String) : PsKernelName := .str .anonymous s

def c0TypedPropName : PsKernelName := c0TypedName "C0VerifiedUnitProp"
def c0TypedPropCtor : PsKernelName := .str c0TypedPropName "intro"
def c0TypedBoxName : PsKernelName := c0TypedName "C0VerifiedPairBox"
def c0TypedBoxCtor : PsKernelName := .str c0TypedBoxName "mk"

def c0TypedPropDecl : PsKernelSimpleInductiveDecl := {
  levelParams := []
  name := c0TypedPropName
  type := .sort .zero
  ctors := [
    { name := c0TypedPropCtor, type := .const c0TypedPropName [] }
  ]
  isUnsafe := false
  numParams := 0
}

/-- A nonrecursive Type-valued structure with two nonrecursive fields. -/
def c0TypedBoxDecl : PsKernelSimpleInductiveDecl := {
  levelParams := []
  name := c0TypedBoxName
  type := .sort (.succ .zero)
  ctors := [
    {
      name := c0TypedBoxCtor
      type := .forallE (c0TypedName "fieldA") (.sort .zero)
        (.forallE (c0TypedName "fieldB") (.sort .zero)
          (.const c0TypedBoxName []) .default) .default
    }
  ]
  isUnsafe := false
  numParams := 0
}

def c0TypedEvenName : PsKernelName := c0TypedName "C0VerifiedEven"
def c0TypedOddName : PsKernelName := c0TypedName "C0VerifiedOdd"

def c0TypedMutualDecl : PsKernelSimpleMutualInductiveDecl := {
  levelParams := []
  numParams := 0
  types := [
    {
      name := c0TypedEvenName
      type := .sort (.succ .zero)
      ctors := [
        { name := .str c0TypedEvenName "zero"
          type := .const c0TypedEvenName [] },
        { name := .str c0TypedEvenName "step"
          type := .forallE .anonymous (.const c0TypedOddName [])
            (.const c0TypedEvenName []) .default }
      ]
    },
    {
      name := c0TypedOddName
      type := .sort (.succ .zero)
      ctors := [
        { name := .str c0TypedOddName "step"
          type := .forallE .anonymous (.const c0TypedEvenName [])
            (.const c0TypedOddName []) .default }
      ]
    }
  ]
  isUnsafe := false
}

def c0TypedNestedName : PsKernelName := c0TypedName "C0NestedDispatch"
def c0TypedNestedDecl : PsKernelSimpleMutualInductiveDecl := {
  levelParams := []
  numParams := 0
  types := [{
    name := c0TypedNestedName
    type := .sort (.succ .zero)
    ctors := [{
      name := .str c0TypedNestedName "mk"
      type := .const c0TypedNestedName []
    }]
  }]
  isUnsafe := false
}

/-- Source-exact Eq and Eq.refl types used by the checked quotient
    bootstrap. The inductive has two uniform parameters (α, a) and one
    index b, making the generated ordinary recursor a K-family. -/
def c0TypedEqUniverse : PsKernelName := c0TypedName "u"
def c0TypedEqCtor : PsKernelName := .str psKernelEqName "refl"
def c0TypedEqDecl : PsKernelSimpleInductiveDecl := {
  levelParams := [c0TypedEqUniverse]
  name := psKernelEqName
  type := psKernelExpectedEqType c0TypedEqUniverse
  ctors := [
    { name := c0TypedEqCtor
      type := psKernelExpectedEqReflType c0TypedEqUniverse }
  ]
  isUnsafe := false
  numParams := 2
}

def c0TypedExpectRecursor
    (environment : PsKernelEnvironment)
    (inductiveName : PsKernelName)
    (expectedK : Bool) : IO Unit := do
  let recName := psKernelSimpleRecName inductiveName
  match psKernelEnvironmentFind environment recName with
  | some (.recInfo info) =>
      if info.k != expectedK || info.isUnsafe then
        throw (IO.userError "admitted source recursor K/safety metadata mismatch")
  | _ =>
      throw (IO.userError "checked inductive admission did not generate recursor")

def main : IO Unit := do
  let source := psKernelMkCheckerSession psKernelEnvironmentEmpty []
    .safe 8192 psKernelLeanNatMaxSizeDefault
  let some begin := psKernelC0ArchitectureBegin source
    | throw (IO.userError "verified typed test failed to begin work")
  -- Source admission checks declaration headers, constructor shapes,
  -- recursor types, universes and iota rules before publishing an env.
  let propWork ← match psKernelC0ArchitectureAdmit 8192 begin
      (.ordinaryInductive c0TypedPropDecl) with
    | .error reason =>
        throw (IO.userError ("checked unit Prop admission failed: " ++ reason))
    | .ok next => pure next
  c0TypedExpectRecursor propWork.checker.context.environment
    c0TypedPropName true

  let proofLocal := c0TypedName "verifiedProof"
  let proofLocals := psKernelLocalContextAddLocal
    propWork.checker.context.localContext
    proofLocal proofLocal (.const c0TypedPropName []) .default
  let proofSession : PsKernelCheckerSession := {
    propWork.checker with
    context := { propWork.checker.context with localContext := proofLocals }
  }
  let proofWork : PsKernelC0ArchitectureWork := {
    propWork with checker := proofSession
  }
  let expectedK : PsKernelExpr := .const c0TypedPropCtor []
  match psKernelC0ArchitecturePreviewTypedMajor 8192 proofWork
      (psKernelSimpleRecName c0TypedPropName) (.fvar proofLocal) with
  | .error reason =>
      throw (IO.userError ("real checked K observation failed: " ++ reason))
  | .ok (observation, _) =>
      if !observation.changed ||
          !psKernelExprEqual observation.sourceResult expectedK then
        throw (IO.userError "verified unit proposition K did not reduce to constructor")
  -- A proof outside its local typing context must not be synthesized.
  match psKernelC0ArchitecturePreviewTypedMajor 8192 propWork
      (psKernelSimpleRecName c0TypedPropName) (.fvar proofLocal) with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "unbound proposition proof was accepted by K")

  let boxWork ← match psKernelC0ArchitectureAdmit 8192 propWork
      (.ordinaryInductive c0TypedBoxDecl) with
    | .error reason =>
        throw (IO.userError ("checked structure admission failed: " ++ reason))
    | .ok next => pure next
  c0TypedExpectRecursor boxWork.checker.context.environment
    c0TypedBoxName false
  if !psKernelEnvironmentIsNonRecStructure
      boxWork.checker.context.environment c0TypedBoxName then
    throw (IO.userError "checked Box not recognized as a nonrecursive structure")

  let boxLocal := c0TypedName "verifiedBox"
  let boxLocals := psKernelLocalContextAddLocal
    boxWork.checker.context.localContext
    boxLocal boxLocal (.const c0TypedBoxName []) .default
  let boxSession : PsKernelCheckerSession := {
    boxWork.checker with
    context := { boxWork.checker.context with localContext := boxLocals }
  }
  let boxScoped : PsKernelC0ArchitectureWork := {
    boxWork with checker := boxSession
  }
  let boxTerm : PsKernelExpr := .fvar boxLocal
  let expectedEta : PsKernelExpr :=
    .app (.app (.const c0TypedBoxCtor [])
      (.proj c0TypedBoxName 0 boxTerm))
      (.proj c0TypedBoxName 1 boxTerm)
  match psKernelC0ArchitecturePreviewTypedMajor 8192 boxScoped
      (psKernelSimpleRecName c0TypedBoxName) boxTerm with
  | .error reason =>
      throw (IO.userError ("real checked structure eta failed: " ++ reason))
  | .ok (observation, _) =>
      if !observation.changed ||
          !psKernelExprEqual observation.sourceResult expectedEta then
        throw (IO.userError "verified structure eta reconstructed wrong fields")
  -- Require the produced eta constructor term to be well typed by the
  -- independent source checker, not merely equivalent syntax.
  match psKernelSessionInfer 8192 boxSession expectedEta with
  | .error reason =>
      throw (IO.userError ("source inference rejected generated eta: " ++ reason))
  | .ok (ty, _) =>
      if !psKernelExprEqual ty (.const c0TypedBoxName []) then
        throw (IO.userError "typed eta constructor has unexpected type")
  match psKernelSessionIsDefEq 8192 boxSession expectedEta boxTerm with
  | .error reason =>
      throw (IO.userError ("source DefEq failed on structure eta: " ++ reason))
  | .ok (equal, _) =>
      if !equal then
        throw (IO.userError "source DefEq did not justify verified structure eta")

  -- A major belonging to a different verified inductive must not be
  -- converted by the K branch based merely on constructor names.
  match psKernelC0ArchitecturePreviewTypedMajor 8192 boxScoped
      (psKernelSimpleRecName c0TypedPropName) boxTerm with
  | .error reason =>
      throw (IO.userError ("cross-family typed observation failed: " ++ reason))
  | .ok (observation, _) =>
      if observation.changed ||
          !psKernelExprEqual observation.sourceResult boxTerm then
        throw (IO.userError "K converted major of the wrong inductive family")

  -- The same validated, atomic work transaction must handle generated
  -- mutual recursors and the nested-family dispatcher—not just ordinary
  -- inductives. These use real source admission, never synthetic metadata.
  let mutualWork ← match psKernelC0ArchitectureAdmit 32768 boxWork
      (.mutualInductive c0TypedMutualDecl) with
    | .error reason =>
        throw (IO.userError ("checked mutual admission failed: " ++ reason))
    | .ok next => pure next
  c0TypedExpectRecursor mutualWork.checker.context.environment
    c0TypedEvenName false
  c0TypedExpectRecursor mutualWork.checker.context.environment
    c0TypedOddName false
  let some (.ctorInfo evenCtorInfo) :=
      psKernelEnvironmentFind mutualWork.checker.context.environment
        (.str c0TypedEvenName "zero")
    | throw (IO.userError "checked mutual ctor was not published")
  if !psKernelNameEq evenCtorInfo.induct c0TypedEvenName then
    throw (IO.userError "checked mutual ctor lost family ownership")
  let nestedWork ← match psKernelC0ArchitectureAdmit 32768 mutualWork
      (.nestedInductive c0TypedNestedDecl) with
    | .error reason =>
        throw (IO.userError ("checked nested dispatch failed: " ++ reason))
    | .ok next => pure next
  let some (.inductInfo _) :=
      psKernelEnvironmentFind nestedWork.checker.context.environment
        c0TypedNestedName
    | throw (IO.userError "nested family dispatch did not publish checked type")
  c0TypedExpectRecursor nestedWork.checker.context.environment
    c0TypedNestedName false
  -- A nested-dispatch singleton is not evidence for arbitrary genuine
  -- nested inductives. This test proves source checked interface wiring.
  -- Quot requires the *source-checked* Eq and Eq.refl signatures;
  -- a boolean initialization flag or unchecked declaration stub must not
  -- be used as an admission shortcut.
  let eqWork ← match psKernelC0ArchitectureAdmit 32768 nestedWork
      (.ordinaryInductive c0TypedEqDecl) with
    | .error reason =>
        throw (IO.userError ("checked Eq admission failed: " ++ reason))
    | .ok next => pure next
  c0TypedExpectRecursor eqWork.checker.context.environment psKernelEqName true
  match psKernelCheckEqForQuot eqWork.checker.context.environment with
  | .error reason =>
      throw (IO.userError ("source Eq/Quot shape rejected: " ++ reason))
  | .ok _ => pure ()
  let quotWork ← match psKernelC0ArchitectureAdmit 32768 eqWork .quotient with
    | .error reason =>
        throw (IO.userError ("checked quotient bootstrap failed: " ++ reason))
    | .ok next => pure next
  if !quotWork.checker.context.environment.quotInitialized then
    throw (IO.userError "checked quotient environment flag not set")
  for name in [psKernelQuotName, psKernelQuotMkName,
      psKernelQuotLiftName, psKernelQuotIndName] do
    match psKernelEnvironmentFind quotWork.checker.context.environment name with
    | some (.quotInfo _) => pure ()
    | _ =>
        throw (IO.userError "checked quotient constant was not published")
  -- Indexed K on a *source-admitted Eq*. The proof is a neutral local
  -- variable; only source type inference + DefEq of the candidate refl type
  -- may justify replacing it with Eq.refl.
  let alpha : PsKernelExpr := .sort .zero
  let p : PsKernelExpr := .const c0TypedPropName []
  let eqHead : PsKernelExpr := .const psKernelEqName [.succ .zero]
  let reflexiveEq := psKernelApplyArgs eqHead [alpha, p, p]
  let eqProofName := c0TypedName "verifiedEqProof"
  let eqLocals := psKernelLocalContextAddLocal
    quotWork.checker.context.localContext eqProofName eqProofName
    reflexiveEq .default
  let eqSession : PsKernelCheckerSession := {
    quotWork.checker with
    context := { quotWork.checker.context with localContext := eqLocals }
  }
  let eqScoped : PsKernelC0ArchitectureWork := {
    quotWork with checker := eqSession
  }
  let expectedRefl := psKernelApplyArgs
    (.const c0TypedEqCtor [.succ .zero]) [alpha, p]
  match psKernelC0ArchitecturePreviewTypedMajor 32768 eqScoped
      (psKernelSimpleRecName psKernelEqName) (.fvar eqProofName) with
  | .error reason =>
      throw (IO.userError ("checked dependent K failed: " ++ reason))
  | .ok (observation, _) =>
      if !observation.changed ||
          !psKernelExprEqual observation.sourceResult expectedRefl then
        throw (IO.userError "real indexed K failed to use verified Eq.refl")
  -- A non-reflexive index is not definitionally equal to the refl type.
  -- Even if a local context hypothetically contains such a proof, source
  -- K must refuse the candidate constructor instead of accepting by name.
  let otherProposition : PsKernelExpr :=
    .forallE (c0TypedName "h") p p .default
  let unequalEq := psKernelApplyArgs eqHead [alpha, p, otherProposition]
  let unequalProofName := c0TypedName "unequalEqProof"
  let unequalLocals := psKernelLocalContextAddLocal
    quotWork.checker.context.localContext unequalProofName unequalProofName
    unequalEq .default
  let unequalSession : PsKernelCheckerSession := {
    quotWork.checker with
    context := { quotWork.checker.context with localContext := unequalLocals }
  }
  let unequalWork : PsKernelC0ArchitectureWork := {
    quotWork with checker := unequalSession
  }
  match psKernelC0ArchitecturePreviewTypedMajor 32768 unequalWork
      (psKernelSimpleRecName psKernelEqName) (.fvar unequalProofName) with
  | .error reason =>
      throw (IO.userError ("indexed K negative typecheck failed: " ++ reason))
  | .ok (observation, _) =>
      if observation.changed ||
          !psKernelExprEqual observation.sourceResult (.fvar unequalProofName) then
        throw (IO.userError "K rewrote non-definitionally-equal Eq indices")
  -- Quot initialization must be idempotent without changing the
  -- independently checked declaration count.
  let quotientAgain ← match psKernelC0ArchitectureAdmit 32768 quotWork .quotient with
    | .error reason =>
        throw (IO.userError ("idempotent checked Quot bootstrap failed: " ++ reason))
    | .ok next => pure next
  if psKernelEnvironmentSize quotientAgain.checker.context.environment !=
      psKernelEnvironmentSize quotWork.checker.context.environment then
    throw (IO.userError "idempotent Quot changed admitted declarations")

  -- Duplicate admission, invalid declaration and ill-typed source terms
  -- must not mutate an accepted environment or promote candidate values.
  match psKernelC0ArchitectureAdmit 8192 boxWork
      (.ordinaryInductive c0TypedBoxDecl) with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "duplicate verified structure was admitted")
  match psKernelC0ArchitectureCheckWork 8192 boxWork
      (.app (.sort .zero) (.sort .zero)) with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "typed observer approved invalid checking")
  match psKernelC0ArchitectureAdmit 8192 boxWork .quotient with
  | .error _ => pure ()
  | .ok _ =>
      throw (IO.userError "quotient bootstrap accepted without checked Eq")
  IO.println "C0_TYPED verified_k_prop_source_admission=pass"
  IO.println "C0_TYPED verified_structure_eta_source_infer_defeq=pass"
  IO.println "C0_TYPED checked_mutual_nested_source_admission=pass"
  IO.println "C0_TYPED checked_eq_quot_bootstrap_and_idempotence=pass"
  IO.println "C0_TYPED indexed_k_defeq_side_conditions=pass"
  IO.println "C0_TYPED checked_declaration_atomicity_and_source_authority=pass"
