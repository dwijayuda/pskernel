import Ps.Foundation.Name
import Ps.Foundation.List
import Ps.Project.ModuleInterface

inductive PsQueryStage where
  | source | parsed | elaboratedPublic | checkedStructural | certifiedBehavioral
  | assumptions | runtime | verifiedIr | specializedIr | target

def psQueryStageName (stage : PsQueryStage) : String :=
  match stage with
  | .source => "source"
  | .parsed => "parsed"
  | .elaboratedPublic => "elaborated-public"
  | .checkedStructural => "checked-structural"
  | .certifiedBehavioral => "certified-behavioral"
  | .assumptions => "assumptions"
  | .runtime => "runtime"
  | .verifiedIr => "verified-ir"
  | .specializedIr => "specialized-ir"
  | .target => "target"

def psQueryStageEq (left right : PsQueryStage) : Bool :=
  psStringEq (psQueryStageName left) (psQueryStageName right)

-- Artifact keys are host-verified canonical identities. This portable planner
-- compares projections; it never treats strings as proof or re-hashes bytes.
structure PsQueryStageFingerprint where
  stage : PsQueryStage
  artifactKey : String
  fingerprintContract : String
  semanticKey : String

structure PsQueryStageDependency where
  moduleName : PsName
  fingerprint : PsQueryStageFingerprint

structure PsQueryStageRequest where
  moduleName : PsName
  stage : PsQueryStage
  sourceKey : String
  implementationKey : String
  semanticContextKey : String
  resourcePolicyKey : String
  parametersKey : String
  dependencies : List PsQueryStageDependency

structure PsQueryStageRecord where
  request : PsQueryStageRequest
  output : PsQueryStageFingerprint
  passExecutionKey : String

-- Rules are selected by the consumer, never by a cached record. Their names
-- describe replay obligations, not checked evidence or a minted capability.
structure PsQueryReuseRule where
  consumerStage : PsQueryStage
  dependencyStage : PsQueryStage
  fingerprintContract : String
  ruleArtifactKey : String
  checkerId : String

structure PsQueryReuseObligation where
  dependencyName : PsName
  previous : PsQueryStageFingerprint
  current : PsQueryStageFingerprint
  rule : PsQueryReuseRule

structure PsQueryReuseCandidate where
  previous : PsQueryStageRecord
  current : PsQueryStageRequest
  semanticReuse : List PsQueryReuseObligation

inductive PsQueryStageReason where
  | malformedInput | duplicateRecord | missingPrevious | sourceChanged
  | implementationChanged | semanticContextChanged | resourcePolicyChanged
  | parametersChanged | importsChanged | fingerprintChanged | reuseRuleUnavailable

inductive PsQueryStageDecision where
  | rebuild (reason : PsQueryStageReason)
  | validateCandidate (candidate : PsQueryReuseCandidate)

def psQueryV2Nonempty (value : String) : Bool :=
  if psStringEq value "" then false else true

def psQueryFingerprintValid (value : PsQueryStageFingerprint) : Bool :=
  if psQueryV2Nonempty value.artifactKey then
    if psQueryV2Nonempty value.fingerprintContract then psQueryV2Nonempty value.semanticKey else false
  else false

def psQueryDependencyKeyEq (left right : PsQueryStageDependency) : Bool :=
  if psNameEq left.moduleName right.moduleName then psQueryStageEq left.fingerprint.stage right.fingerprint.stage else false

def psQueryDependencyContains (value : PsQueryStageDependency) (values : List PsQueryStageDependency) : Bool :=
  match values with
  | List.nil => false
  | List.cons other rest =>
      if psQueryDependencyKeyEq value other then true else psQueryDependencyContains value rest

def psQueryDependenciesValid (values : List PsQueryStageDependency) : Bool :=
  match values with
  | List.nil => true
  | List.cons value rest =>
      if psQueryFingerprintValid value.fingerprint then
        if psQueryDependencyContains value rest then false else psQueryDependenciesValid rest
      else false

def psQueryRequestValid (value : PsQueryStageRequest) : Bool :=
  if psQueryV2Nonempty value.sourceKey then
    if psQueryV2Nonempty value.implementationKey then
      if psQueryV2Nonempty value.semanticContextKey then
        if psQueryV2Nonempty value.resourcePolicyKey then
          if psQueryV2Nonempty value.parametersKey then psQueryDependenciesValid value.dependencies else false
        else false
      else false
    else false
  else false

def psQueryStageKeyEq (left right : PsQueryStageRequest) : Bool :=
  if psNameEq left.moduleName right.moduleName then psQueryStageEq left.stage right.stage else false

def psQueryRecordContains (request : PsQueryStageRequest) (records : List PsQueryStageRecord) : Bool :=
  match records with
  | List.nil => false
  | List.cons record rest =>
      if psQueryStageKeyEq request record.request then true else psQueryRecordContains request rest

def psQueryRecordsValid (records : List PsQueryStageRecord) : Except PsQueryStageReason Unit :=
  match records with
  | List.nil => Except.ok Unit.unit
  | List.cons record rest =>
      if psQueryRequestValid record.request then
        if psQueryFingerprintValid record.output then
          if psQueryStageEq record.output.stage record.request.stage then
            if psQueryV2Nonempty record.passExecutionKey then
              if psQueryRecordContains record.request rest then Except.error PsQueryStageReason.duplicateRecord
              else psQueryRecordsValid rest
            else Except.error PsQueryStageReason.malformedInput
          else Except.error PsQueryStageReason.malformedInput
        else Except.error PsQueryStageReason.malformedInput
      else Except.error PsQueryStageReason.malformedInput

def psQueryFindStageRecord (request : PsQueryStageRequest) (records : List PsQueryStageRecord) : Option PsQueryStageRecord :=
  match records with
  | List.nil => Option.none
  | List.cons record rest =>
      if psQueryStageKeyEq request record.request then Option.some record else psQueryFindStageRecord request rest

def psQueryReuseRuleMatches (consumer : PsQueryStage) (dependency : PsQueryStageFingerprint) (rule : PsQueryReuseRule) : Bool :=
  if psQueryStageEq consumer rule.consumerStage then
    if psQueryStageEq dependency.stage rule.dependencyStage then
      if psStringEq dependency.fingerprintContract rule.fingerprintContract then
        if psQueryV2Nonempty rule.ruleArtifactKey then psQueryV2Nonempty rule.checkerId else false
      else false
    else false
  else false

def psQueryFindReuseRule (consumer : PsQueryStage) (dependency : PsQueryStageFingerprint)
    (rules : List PsQueryReuseRule) : Option PsQueryReuseRule :=
  match rules with
  | List.nil => Option.none
  | List.cons rule rest =>
      if psQueryReuseRuleMatches consumer dependency rule then Option.some rule
      else psQueryFindReuseRule consumer dependency rest

def psQueryDependencyReuse (consumer : PsQueryStage) (rules : List PsQueryReuseRule)
    (previous current : PsQueryStageDependency) : Except PsQueryStageReason (Option PsQueryReuseObligation) :=
  if psQueryDependencyKeyEq previous current then
    if psStringEq previous.fingerprint.fingerprintContract current.fingerprint.fingerprintContract then
      if psStringEq previous.fingerprint.semanticKey current.fingerprint.semanticKey then
        if psStringEq previous.fingerprint.artifactKey current.fingerprint.artifactKey then Except.ok Option.none
        else
          match psQueryFindReuseRule consumer current.fingerprint rules with
          | Option.none => Except.error PsQueryStageReason.reuseRuleUnavailable
          | Option.some rule => Except.ok (Option.some (PsQueryReuseObligation.mk current.moduleName previous.fingerprint current.fingerprint rule))
      else Except.error PsQueryStageReason.fingerprintChanged
    else Except.error PsQueryStageReason.fingerprintChanged
  else Except.error PsQueryStageReason.importsChanged

def psQueryDependencyReuseList (consumer : PsQueryStage) (rules : List PsQueryReuseRule)
    (previous : List PsQueryStageDependency) : List PsQueryStageDependency -> Except PsQueryStageReason (List PsQueryReuseObligation) :=
  match previous with
  | List.nil =>
      fun (current : List PsQueryStageDependency) =>
        if psListIsEmpty current then Except.ok List.nil else Except.error PsQueryStageReason.importsChanged
  | List.cons old rest =>
      let smaller := psQueryDependencyReuseList consumer rules rest;
      fun (current : List PsQueryStageDependency) =>
        match current with
        | List.nil => Except.error PsQueryStageReason.importsChanged
        | List.cons value values =>
            match psQueryDependencyReuse consumer rules old value with
            | Except.error reason => Except.error reason
            | Except.ok obligation =>
                match smaller values with
                | Except.error reason => Except.error reason
                | Except.ok obligations =>
                    match obligation with
                    | Option.none => Except.ok obligations
                    | Option.some required => Except.ok (List.cons required obligations)

def psQueryStageCompare (rules : List PsQueryReuseRule) (previous : PsQueryStageRecord)
    (current : PsQueryStageRequest) : PsQueryStageDecision :=
  if psStringEq previous.request.sourceKey current.sourceKey then
    if psStringEq previous.request.implementationKey current.implementationKey then
      if psStringEq previous.request.semanticContextKey current.semanticContextKey then
        if psStringEq previous.request.resourcePolicyKey current.resourcePolicyKey then
          if psStringEq previous.request.parametersKey current.parametersKey then
            match psQueryDependencyReuseList current.stage rules previous.request.dependencies current.dependencies with
            | Except.error reason => PsQueryStageDecision.rebuild reason
            | Except.ok obligations => PsQueryStageDecision.validateCandidate (PsQueryReuseCandidate.mk previous current obligations)
          else PsQueryStageDecision.rebuild PsQueryStageReason.parametersChanged
        else PsQueryStageDecision.rebuild PsQueryStageReason.resourcePolicyChanged
      else PsQueryStageDecision.rebuild PsQueryStageReason.semanticContextChanged
    else PsQueryStageDecision.rebuild PsQueryStageReason.implementationChanged
  else PsQueryStageDecision.rebuild PsQueryStageReason.sourceChanged

-- No green/accepted constructor exists. Even byte-identical dependency inputs
-- require fresh output/pass-artifact validation at the untrusted cache boundary.
-- A semantic candidate additionally requires every exact reuse-rule subject.
def psQueryPlanStage (rules : List PsQueryReuseRule) (previous : List PsQueryStageRecord)
    (current : PsQueryStageRequest) : PsQueryStageDecision :=
  if psQueryRequestValid current then
    match psQueryRecordsValid previous with
    | Except.error reason => PsQueryStageDecision.rebuild reason
    | Except.ok _ =>
        match psQueryFindStageRecord current previous with
        | Option.none => PsQueryStageDecision.rebuild PsQueryStageReason.missingPrevious
        | Option.some record => psQueryStageCompare rules record current
  else PsQueryStageDecision.rebuild PsQueryStageReason.malformedInput


def psCertifiedModuleInterfaceFingerprintContract : String :=
  "psc-certified-module-interface/1"

def psExactBehavioralInterfaceReuseChecker : String :=
  "psc-exact-behavioral-interface-reuse/1"

def psCertifiedModuleInterfaceReuseRule
    (consumerStage : PsQueryStage)
    (ruleArtifactKey : String) :
    PsQueryReuseRule :=
  PsQueryReuseRule.mk
    consumerStage
    PsQueryStage.certifiedBehavioral
    psCertifiedModuleInterfaceFingerprintContract
    ruleArtifactKey
    psExactBehavioralInterfaceReuseChecker


-- V5 identity gate around the existing stage planner. Each key is supplied by
-- the host after canonical artifact verification. The action/query keys bind
-- exact input coverage; a changed action needs a fresh execution/validation.
structure PsQueryBoundContext where
  profileEnvironmentKey : String
  extensionSetKey : String
  buildActionKey : String
  passDefinitionKey : String
  queryKey : String
  authorityEffect : String
  assuranceClass : String

structure PsQueryBoundRecord where
  context : PsQueryBoundContext
  record : PsQueryStageRecord

structure PsQueryBoundCandidate where
  context : PsQueryBoundContext
  candidate : PsQueryReuseCandidate

inductive PsQueryBoundDecision where
  | rebuild (reason : String)
  | validateCandidate (candidate : PsQueryBoundCandidate)

def psQueryBoundContextValid (context : PsQueryBoundContext) : Bool :=
  if psQueryV2Nonempty context.profileEnvironmentKey then
    if psQueryV2Nonempty context.extensionSetKey then
      if psQueryV2Nonempty context.buildActionKey then
        if psQueryV2Nonempty context.passDefinitionKey then
          if psQueryV2Nonempty context.queryKey then
            if psQueryV2Nonempty context.authorityEffect then
              psQueryV2Nonempty context.assuranceClass
            else false
          else false
        else false
      else false
    else false
  else false

def psQueryBoundContextEq (left right : PsQueryBoundContext) : Bool :=
  if psStringEq left.profileEnvironmentKey right.profileEnvironmentKey then
    if psStringEq left.extensionSetKey right.extensionSetKey then
      if psStringEq left.buildActionKey right.buildActionKey then
        if psStringEq left.passDefinitionKey right.passDefinitionKey then
          if psStringEq left.queryKey right.queryKey then
            if psStringEq left.authorityEffect right.authorityEffect then
              psStringEq left.assuranceClass right.assuranceClass
            else false
          else false
        else false
      else false
    else false
  else false

-- The portable planner accepts only known effect/assurance classes. Even a
-- proof/validator label never mints a capability or bypasses host replay.
def psQueryBoundEffectAllowsCandidate (effect : String) : Bool :=
  if psStringEq effect "none" then true
  else if psStringEq effect "requiresRevalidation" then true
  else if psStringEq effect "preservesByProof" then true
  else psStringEq effect "preservesByValidator"

def psQueryBoundAssuranceAllowsCandidate (assurance : String) : Bool :=
  if psStringEq assurance "trustedImplementation" then true
  else if psStringEq assurance "proofPreserved" then true
  else if psStringEq assurance "certificateValidated" then true
  else if psStringEq assurance "translationValidated" then true
  else if psStringEq assurance "targetAcceptedOnly" then true
  else psStringEq assurance "differentialOnly"

def psQueryPlanBoundStage
    (rules : List PsQueryReuseRule)
    (previous : PsQueryBoundRecord)
    (context : PsQueryBoundContext)
    (current : PsQueryStageRequest) :
    PsQueryBoundDecision :=
  if psQueryBoundContextValid context then
    if psQueryBoundContextValid previous.context then
      if psQueryBoundContextEq previous.context context then
        if psQueryBoundEffectAllowsCandidate context.authorityEffect then
          if psQueryBoundAssuranceAllowsCandidate context.assuranceClass then
            match psQueryPlanStage rules (List.cons previous.record List.nil) current with
            | PsQueryStageDecision.rebuild _ =>
                PsQueryBoundDecision.rebuild "stage-dependency-changed"
            | PsQueryStageDecision.validateCandidate candidate =>
                PsQueryBoundDecision.validateCandidate (PsQueryBoundCandidate.mk context candidate)
          else PsQueryBoundDecision.rebuild "unassured-or-unknown-pass"
        else PsQueryBoundDecision.rebuild "trust-expanding-or-unknown-effect"
      else PsQueryBoundDecision.rebuild "profile-extension-action-query-changed"
    else PsQueryBoundDecision.rebuild "malformed-previous-context"
  else PsQueryBoundDecision.rebuild "malformed-current-context"
