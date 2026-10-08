import Ps.KernelCore.API.Kernel

def psKernelContractOutcomeTag (outcome : PsKernelOutcome) : Nat :=
  match outcome with
  | PsKernelOutcome.accepted => 0
  | PsKernelOutcome.rejectedInvalid => 1
  | PsKernelOutcome.declinedUnsupported => 2
  | PsKernelOutcome.resourceExhausted => 3
  | PsKernelOutcome.internalError => 4

def psKernelContractResultTag {Value : Type} (result : Except PsKernelError Value) : Nat :=
  match result with
  | Except.ok _ => 0
  | Except.error error => psKernelContractOutcomeTag (psKernelErrorOutcome error)

def psKernelContractDiagnosticTests : Bool :=
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "already declared"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "application type mismatch"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "declaration has free variables"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "declaration has metavariables"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "deep recursion detected, use maxRecDepth to increase the limit"))) 3 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "definition type mismatch"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "duplicate inductive, constructor, or recursor name"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "duplicate mutual inductive, constructor, or recursor name"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "duplicate universe parameter"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "empty mutual inductive declaration"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "empty nested inductive declaration"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "expected function type"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "expected sort"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "failed to initialize quot module, Eq has an unexpected type"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "failed to initialize quot module, environment does not have Eq type"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "failed to initialize quot module, missing Eq constructor"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "failed to initialize quot module, quotient name is already declared"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "failed to initialize quot module, unexpected number of constructors for Eq type"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "failed to initialize quot module, unexpected number of universe params at Eq type"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "failed to initialize quot module, unexpected type for Eq constructor"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "failed to initialize quot module, unexpected universe params at Eq constructor"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "failed to restore nested inductive parameters"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "generated mutual recursor rule is not type preserving"))) 4 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "generated simple recursor rule count mismatch"))) 4 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "generated simple recursor rule is not type preserving"))) 4 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "ill-formed nested inductive parameter instantiation"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "incorrect number of universe levels"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "inductive declaration name is already declared"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "internal lazy-delta request for non-definition"))) 4 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "invalid empty mutual definition"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "invalid mutual definition, declaration is not tagged as unsafe/partial"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "invalid mutual definition, declarations must have the same safety annotation"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "invalid mutual definition, declarations must have the same universe level parameters"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "invalid mutual definition, duplicate declaration name"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "invalid occurrence of datatype being declared: it must be applied to the parameters and universe levels of the mutual declaration"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "invalid outer mutual inductive metadata"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "invalid projection index"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "invalid projection: constructor metadata missing"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "invalid projection: constructor parameter is not a forall"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "invalid projection: inductive must have exactly one constructor"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "invalid projection: inductive type is not fully applied"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "invalid projection: missing structure parameter"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "invalid projection: projected expression type is not an inductive application"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "invalid projection: proof structure depends on data field"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "invalid projection: proof structure field is not a proposition"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "invalid projection: structure name is not inductive"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "invalid projection: structure type mismatch"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "invalid reference to undefined universe level parameter"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "kernel defeq argument budget exhausted"))) 3 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "kernel defeq argument-list budget exhausted"))) 3 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "kernel defeq forall-spine budget exhausted"))) 3 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "kernel defeq lambda-spine budget exhausted"))) 3 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "kernel definitional equality budget exhausted"))) 3 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "kernel inference budget exhausted"))) 3 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "kernel lazy-delta budget exhausted"))) 3 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "kernel lazy-projection budget exhausted"))) 3 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "kernel projection field budget exhausted"))) 3 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "kernel projection parameter budget exhausted"))) 3 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "kernel recursor budget exhausted"))) 3 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "kernel reduction budget exhausted"))) 3 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "kernel structure eta budget exhausted"))) 3 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "kernel type checker does not support metavariables"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "let value type mismatch"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "loose bound variable in type checker"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "mutual constructor field budget exhausted"))) 3 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "mutual constructor has invalid return type"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "mutual constructor returns the wrong datatype"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "mutual inductive admission requires at least two datatypes"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "mutual inductive constructor field universe is too large"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "mutual inductive field has a non-positive recursive occurrence"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "mutual inductive result must be a sort"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "mutual minor index is out of bounds"))) 4 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "mutual motive index is out of bounds"))) 4 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "mutual recursive-argument budget exhausted"))) 3 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "mutual recursive-call target is out of bounds"))) 4 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "mutual recursor motive target is out of bounds"))) 4 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "mutual recursor rule count mismatch"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "mutually inductive types must live in the same universe"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "nested auxiliary recursor metadata is missing"))) 4 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "nested auxiliary recursor rename collides with an existing declaration"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "nested auxiliary recursor rename is missing"))) 4 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "nested auxiliary recursor rename missing during validation"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "nested auxiliary-name budget exhausted"))) 3 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "nested constructor parameter budget exhausted"))) 3 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "nested expression mapping budget exhausted"))) 3 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "nested family head is not a constant"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "nested family head is not an inductive datatype"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "nested family selection failed"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "nested or invalid mutual inductive occurrence is not supported"))) 2 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "nested outer constructor metadata is missing"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "nested outer constructor name is outside its inductive namespace"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "nested preprocessing constructor parameter mismatch"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "nested preprocessing queue budget exhausted"))) 3 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "nested restoration parameter budget exhausted"))) 3 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "nested rule comparison budget exhausted"))) 3 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "nested template does not contain exactly the fixed outer parameters"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "opaque value type mismatch"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "outer mutual inductive parameters are inconsistent"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "recursive argument index contains a recursive occurrence"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "recursive function argument contains a negative recursive occurrence"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "reserved prefix '_nested' occurs in nested inductive constructor"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "reserved prefix '_nested' occurs in nested inductive declaration"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "restored constructor missing during validation"))) 4 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "restored inductive missing during validation"))) 4 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "restored nested auxiliary recursor missing"))) 4 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "restored nested binders mix forall and lambda"))) 4 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "restored nested constructor metadata is missing"))) 4 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "restored nested inductive metadata is missing"))) 4 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "restored nested recursor metadata is missing"))) 4 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "restored nested recursor rule count mismatch"))) 4 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "restored nested recursor rule is not type preserving"))) 4 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "restored recursor missing during validation"))) 4 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "safe declaration uses partial constant"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "safe declaration uses unsafe constant"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "simple inductive admission does not yet support nested recursive occurrences"))) 2 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "simple inductive constructor admission budget exhausted"))) 3 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "simple inductive constructor field universe is too large"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "simple inductive constructor has fewer parameters than the datatype"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "simple inductive constructor must return the declared datatype with matching parameters and index arity"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "simple inductive constructor parameter budget exhausted"))) 3 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "simple inductive constructor parameter does not match the datatype parameter"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "simple inductive constructor return index contains a recursive occurrence"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "simple inductive declaration has fewer parameters than declared"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "simple inductive elimination budget exhausted"))) 3 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "simple inductive field budget exhausted"))) 3 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "simple inductive index budget exhausted"))) 3 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "simple inductive recursive-argument budget exhausted"))) 3 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "simple inductive result must be a sort"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "simple inductive uniform-occurrence budget exhausted"))) 3 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "the kernel refused a Nat numeral because its size exceeds the maximum"))) 3 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "the kernel refused to evaluate Nat.pow because the result would exceed the maximum numeral size"))) 3 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "theorem proof type mismatch"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "theorem type is not a proposition"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "transformed nested auxiliary recursor missing"))) 4 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "unknown constant"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "unknown free variable"))) 1 &&
  Nat.beq (psKernelContractOutcomeTag (psKernelErrorOutcome (psKernelErrorFromMessage "unknown provider failure"))) 4

def psKernelContractSort : PsKernelExpr := PsKernelExpr.sort PsKernelLevel.zero

def psKernelContractAxiom (name : String) : PsKernelDeclarationRequest :=
  PsKernelDeclarationRequest.axiomDecl
    (PsKernelAxiomInfo.mk
      (PsKernelConstantBase.mk (PsKernelName.str PsKernelName.anonymous name) List.nil psKernelContractSort) false)

def psKernelContractBadDefinition : PsKernelDeclarationRequest :=
  PsKernelDeclarationRequest.definitionDecl
    (PsKernelDefinitionInfo.mk
      (PsKernelConstantBase.mk (PsKernelName.str PsKernelName.anonymous "bad") List.nil psKernelContractSort)
      psKernelContractSort PsKernelReducibilityHints.opaqueHint PsKernelDefinitionSafety.safe)

def psKernelContractAdmissionTests : Bool :=
  match psKernelKernelSessionEmpty psKernelResourcePolicyDefault psKernelProviderDefault with
  | Except.error _ => false
  | Except.ok session =>
      let request := psKernelContractAxiom "A"
      match psKernelV1CheckDeclaration session request with
      | Except.error _ => false
      | Except.ok checked =>
          let forged := PsKernelCheckedDeclaration.mk psKernelContractBadDefinition checked.receipt
          match psKernelV1AdmitChecked session checked with
          | Except.error _ => false
          | Except.ok result =>
              Nat.beq (psKernelEnvironmentSize session.environment) 0 &&
              Nat.beq (psKernelEnvironmentSize result.session.environment) 1 &&
              Nat.beq checked.receipt.declarationsBefore 0 &&
              Nat.beq checked.receipt.declarationsAfter 1 &&
              Nat.beq (psKernelContractResultTag (psKernelV1AdmitChecked result.session checked)) 1 &&
              Nat.beq (psKernelContractResultTag (psKernelV1AdmitChecked session forged)) 1 &&
              Nat.beq (psKernelContractResultTag (psKernelV1AdmitDeclaration session
                (PsKernelDeclarationRequest.unsupported "future request"))) 2

def psKernelContractExpressionTests : Bool :=
  match psKernelKernelSessionEmpty psKernelResourcePolicyDefault psKernelProviderDefault with
  | Except.error _ => false
  | Except.ok session =>
      let invalidApp := PsKernelExpr.app
        (PsKernelExpr.lam PsKernelName.anonymous psKernelContractSort
          (PsKernelExpr.bvar 0) PsKernelBinderInfo.default)
        psKernelContractSort
      Nat.beq (psKernelContractResultTag (psKernelV1CheckExpression session List.nil
        PsKernelDefinitionSafety.safe psKernelContractSort)) 0 &&
      Nat.beq (psKernelContractResultTag (psKernelV1CheckExpression session List.nil
        PsKernelDefinitionSafety.safe invalidApp)) 1 &&
      Nat.beq (psKernelContractResultTag (psKernelV1Whnf session List.nil
        PsKernelDefinitionSafety.safe invalidApp)) 1 &&
      Nat.beq (psKernelContractResultTag (psKernelV1IsDefEq session List.nil
        PsKernelDefinitionSafety.safe invalidApp invalidApp)) 1 &&
      (match psKernelV1IsDefEq session List.nil PsKernelDefinitionSafety.safe
          psKernelContractSort psKernelContractSort with
       | Except.ok equal => equal
       | Except.error _ => false)

def psKernelContractResourceTests : Bool :=
  let empty := psKernelEnvironmentEmpty
  let zero := PsKernelKernelSession.mk empty
    (PsKernelResourcePolicy.mk 0 0 128 false 0) psKernelProviderDefault
  let cancelled := PsKernelKernelSession.mk empty
    (PsKernelResourcePolicy.mk 64 0 128 true 0) psKernelProviderDefault
  let limited := PsKernelKernelSession.mk empty
    (PsKernelResourcePolicy.mk 64 0 128 false 1) psKernelProviderDefault
  let countFailed := match psKernelV1AdmitDeclaration limited (psKernelContractAxiom "A") with
    | Except.error _ => false
    | Except.ok admitted =>
        match psKernelV1AdmitDeclaration admitted.session (psKernelContractAxiom "B") with
        | Except.ok _ => false
        | Except.error error =>
            match error with
            | PsKernelError.resourceExhausted resource _ =>
                match resource with
                | PsKernelResourceError.declarationLimit =>
                    Nat.beq (psKernelEnvironmentSize admitted.session.environment) 1
                | _ => false
            | _ => false
  Nat.beq (psKernelContractResultTag (psKernelV1CheckExpression zero List.nil
    PsKernelDefinitionSafety.safe psKernelContractSort)) 3 &&
  Nat.beq (psKernelContractResultTag (psKernelV1AdmitDeclaration cancelled (psKernelContractAxiom "A"))) 3 &&
  countFailed

def psKernelContractResourceMonotonicityTests : Bool :=
  let empty := psKernelEnvironmentEmpty
  let small := PsKernelKernelSession.mk empty
    (PsKernelResourcePolicy.mk 64 0 128 false 0)
    psKernelProviderDefault
  let larger := PsKernelKernelSession.mk empty
    (PsKernelResourcePolicy.mk 128 0 128 false 0)
    psKernelProviderDefault
  match
      psKernelV1CheckExpression
        small
        List.nil
        PsKernelDefinitionSafety.safe
        psKernelContractSort,
      psKernelV1CheckExpression
        larger
        List.nil
        PsKernelDefinitionSafety.safe
        psKernelContractSort with
  | Except.ok _, Except.ok _ =>
      true
  | _, _ =>
      false

def psKernelContractProviderTests : Bool :=
  let wrong := PsKernelProviderCapability.mk
    (PsKernelTargetIdentity.mk "KernelContract-v1" "4.35.0" "wrong") Option.none
  let session := PsKernelKernelSession.mk psKernelEnvironmentEmpty psKernelResourcePolicyDefault wrong
  Nat.beq (psKernelContractResultTag (psKernelKernelSessionEmpty psKernelResourcePolicyDefault wrong)) 2 &&
  Nat.beq (psKernelContractResultTag (psKernelV1CheckExpression session List.nil
    PsKernelDefinitionSafety.safe psKernelContractSort)) 2 &&
  Nat.beq (psKernelContractResultTag
    (psKernelV1EnvironmentOutcome (Except.error "provider malfunction"))) 4

def psKernelContractTests : Bool :=
  psKernelContractDiagnosticTests && psKernelContractAdmissionTests &&
    psKernelContractExpressionTests && psKernelContractResourceTests &&
    psKernelContractResourceMonotonicityTests && psKernelContractProviderTests
