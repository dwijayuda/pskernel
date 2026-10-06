import Ps.Project.QueryGraphV2

def queryV2Name (text : String) : PsName := PsName.str PsName.anonymous text
def queryV2Stamp (stage : PsQueryStage) (artifact semantic : String) : PsQueryStageFingerprint :=
  PsQueryStageFingerprint.mk stage artifact "fixture-interface/1" semantic
def queryV2Dependency (artifact semantic : String) : PsQueryStageDependency :=
  PsQueryStageDependency.mk (queryV2Name "Dependency") (queryV2Stamp PsQueryStage.certifiedBehavioral artifact semantic)
def queryV2Request : PsQueryStageRequest :=
  PsQueryStageRequest.mk (queryV2Name "Main") PsQueryStage.target "source" "compiler" "context" "budget" "flags"
    [queryV2Dependency "dependency-v1" "meaning"]
def queryV2Record : PsQueryStageRecord :=
  PsQueryStageRecord.mk queryV2Request (queryV2Stamp PsQueryStage.target "output" "output-meaning") "pass-execution"
def queryV2Rule : PsQueryReuseRule :=
  PsQueryReuseRule.mk PsQueryStage.target PsQueryStage.certifiedBehavioral "fixture-interface/1" "rule-artifact" "checker"
def queryV2CandidateCount (rules : List PsQueryReuseRule) (request : PsQueryStageRequest) (count : Nat) : Bool :=
  match psQueryPlanStage rules [queryV2Record] request with
  | .rebuild _ => false
  | .validateCandidate candidate => Nat.beq (psListLength candidate.semanticReuse) count
def queryV2Rebuilds (request : PsQueryStageRequest) : Bool :=
  match psQueryPlanStage [queryV2Rule] [queryV2Record] request with
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
      | [obligation] => obligation.previous.artifactKey == "dependency-v1" && obligation.current.artifactKey == "dependency-v2" && obligation.rule.ruleArtifactKey == "rule-artifact"
      | _ => false
    | _ => false;
  let cases : List (String × Bool) := [
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
