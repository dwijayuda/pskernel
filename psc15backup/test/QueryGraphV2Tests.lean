import Ps.Project.QueryGraphV2

def queryV2Name (text : String) : PsName := PsName.str PsName.anonymous text
def queryV2Stamp (stage : PsQueryStage) (artifact semantic : String) : PsQueryStageFingerprint :=
  PsQueryStageFingerprint.mk
    stage
    artifact
    psCertifiedModuleInterfaceFingerprintContract
    semantic
def queryV2Dependency (artifact semantic : String) : PsQueryStageDependency :=
  PsQueryStageDependency.mk (queryV2Name "Dependency") (queryV2Stamp PsQueryStage.certifiedBehavioral artifact semantic)
def queryV2Request : PsQueryStageRequest :=
  PsQueryStageRequest.mk (queryV2Name "Main") PsQueryStage.target "source" "compiler" "context" "budget" "flags"
    [queryV2Dependency "dependency-v1" "meaning"]
def queryV2Record : PsQueryStageRecord :=
  PsQueryStageRecord.mk queryV2Request (queryV2Stamp PsQueryStage.target "output" "output-meaning") "pass-execution"
def queryV2Rule : PsQueryReuseRule :=
  psCertifiedModuleInterfaceReuseRule
    PsQueryStage.target
    "rule-artifact"
def queryV2CandidateCount (rules : List PsQueryReuseRule) (request : PsQueryStageRequest) (count : Nat) : Bool :=
  match psQueryPlanStage rules [queryV2Record] request with
  | .rebuild _ => false
  | .validateCandidate candidate => Nat.beq (psListLength candidate.semanticReuse) count
def queryV2Rebuilds (request : PsQueryStageRequest) : Bool :=
  match psQueryPlanStage [queryV2Rule] [queryV2Record] request with
  | .rebuild _ => true
  | .validateCandidate _ => false


def queryBoundContext : PsQueryBoundContext :=
  PsQueryBoundContext.mk "profile" "extensions" "action" "definition" "query" "requiresRevalidation" "trustedImplementation"

def queryBoundCandidate (context : PsQueryBoundContext) : Bool :=
  match psQueryPlanBoundStage [] (PsQueryBoundRecord.mk queryBoundContext queryV2Record) context queryV2Request with
  | .rebuild _ => false
  | .validateCandidate candidate => psStringEq candidate.context.buildActionKey "action"

def queryBoundRejectsPass (context : PsQueryBoundContext) : Bool :=
  match psQueryPlanBoundStage [] (PsQueryBoundRecord.mk context queryV2Record) context queryV2Request with
  | .rebuild _ => true
  | .validateCandidate _ => false

def main : IO Unit := do
  let changedBytes := { queryV2Request with dependencies := [queryV2Dependency "dependency-v2" "meaning"] };
  let noRule := match psQueryPlanStage [] [queryV2Record] changedBytes with
    | .rebuild .reuseRuleUnavailable => true
    | _ => false;
  let duplicate := match psQueryPlanStage [] [queryV2Record, queryV2Record] queryV2Request with
    | .rebuild .duplicateRecord => true
    | _ => false;
  let preservedSubject := match psQueryPlanStage [queryV2Rule] [queryV2Record] changedBytes with
    | .validateCandidate candidate => match candidate.semanticReuse with
      | [obligation] => obligation.previous.artifactKey == "dependency-v1" && obligation.current.artifactKey == "dependency-v2" && obligation.rule.ruleArtifactKey == "rule-artifact" &&
        obligation.rule.checkerId == psExactBehavioralInterfaceReuseChecker
      | _ => false
    | _ => false;
  let cases : List (String × Bool) := [
    ("V5 exact context still requires validation", queryBoundCandidate queryBoundContext),
    ("V5 environment change rebuilds", !queryBoundCandidate { queryBoundContext with profileEnvironmentKey := "changed" }),
    ("V5 extension change rebuilds", !queryBoundCandidate { queryBoundContext with extensionSetKey := "changed" }),
    ("V5 action change rebuilds", !queryBoundCandidate { queryBoundContext with buildActionKey := "changed" }),
    ("V5 query input change rebuilds", !queryBoundCandidate { queryBoundContext with queryKey := "changed" }),
    ("V5 definition change rebuilds", !queryBoundCandidate { queryBoundContext with passDefinitionKey := "changed" }),
    ("V5 trust expansion cannot reuse", queryBoundRejectsPass { queryBoundContext with authorityEffect := "trustExpanding" }),
    ("V5 unknown effect cannot reuse", queryBoundRejectsPass { queryBoundContext with authorityEffect := "unknown" }),
    ("V5 unassured cannot reuse", queryBoundRejectsPass { queryBoundContext with assuranceClass := "unassured" }),
    ("V5 malformed context cannot reuse", queryBoundRejectsPass { queryBoundContext with profileEnvironmentKey := "" }),
    ("unchanged dependencies still require validation", queryV2CandidateCount [] queryV2Request 0),
    ("changed artifact same certified interface needs rule", noRule),
    ("semantic reuse creates exact replay obligation", queryV2CandidateCount [queryV2Rule] changedBytes 1 && preservedSubject),
    ("behavioral change invalidates", queryV2Rebuilds { queryV2Request with dependencies := [queryV2Dependency "dependency-v2" "changed-spec"] }),
    ("source change invalidates", queryV2Rebuilds { queryV2Request with sourceKey := "source-v2" }),
    ("implementation change invalidates", queryV2Rebuilds { queryV2Request with implementationKey := "compiler-v2" }),
    ("semantic context change invalidates", queryV2Rebuilds { queryV2Request with semanticContextKey := "context-v2" }),
    ("resource policy change invalidates", queryV2Rebuilds { queryV2Request with resourcePolicyKey := "budget-v2" }),
    ("target parameters change invalidates", queryV2Rebuilds { queryV2Request with parametersKey := "flags-v2" }),
    ("missing or reordered dependency invalidates", queryV2Rebuilds { queryV2Request with dependencies := [] }),
    ("duplicate previous record rejected", duplicate),
    ("duplicate dependency rejected", queryV2Rebuilds { queryV2Request with dependencies := [queryV2Dependency "a" "meaning", queryV2Dependency "b" "meaning"] }),
    ("empty implementation identity rejected", queryV2Rebuilds { queryV2Request with implementationKey := "" })
  ];
  for entry in cases do
    if !entry.2 then throw (IO.userError ("PSC_QUERY_V2: FAIL " ++ entry.1));
  IO.println ("PSC_QUERY_V2: PASS (" ++ toString cases.length ++ " cases)")
