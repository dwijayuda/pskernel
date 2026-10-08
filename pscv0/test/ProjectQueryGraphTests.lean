import Ps.Project.QueryGraph
import Ps.Foundation.Name

def psQueryTestName
    (value : String) : PsName :=
  PsName.str PsName.anonymous value

def psQueryTestA : PsName :=
  psQueryTestName "A"

def psQueryTestB : PsName :=
  psQueryTestName "B"

def psQueryPreviousSnapshot : PsQuerySnapshot :=
  {
    records := [
      {
        name := psQueryTestA
        sourceKey := "source-a-v1"
        interfaceFingerprint := psModuleInterfaceFingerprintV1 "iface-a-v1"
        dependencyInterfaces := []
      },
      {
        name := psQueryTestB
        sourceKey := "source-b-v1"
        interfaceFingerprint := psModuleInterfaceFingerprintV1 "iface-b-v1"
        dependencyInterfaces := [
          {
            name := psQueryTestA
            interfaceFingerprint := psModuleInterfaceFingerprintV1 "iface-a-v1"
          }
        ]
      }
    ]
  }

def psQueryInputA
    (sourceKey : String) :
    PsModuleQueryInput :=
  {
    name := psQueryTestA
    imports := []
    sourceKey := sourceKey
  }

def psQueryInputB
    (imports : List PsName) :
    PsModuleQueryInput :=
  {
    name := psQueryTestB
    imports := imports
    sourceKey := "source-b-v1"
  }

def psTestQueryUnchangedModuleIsGreen : Bool :=
  match
      psQueryEvaluateModule
        psQueryPreviousSnapshot
        psQuerySnapshotEmpty
        (psQueryInputA "source-a-v1") with
  | PsQueryDecision.green record =>
      psStringEq record.interfaceFingerprint.semanticKey "iface-a-v1"
  | PsQueryDecision.red _ =>
      false

def psTestQuerySourceChangeIsRed : Bool :=
  match
      psQueryEvaluateModule
        psQueryPreviousSnapshot
        psQuerySnapshotEmpty
        (psQueryInputA "source-a-v2") with
  | PsQueryDecision.red
      PsQueryInvalidation.sourceChanged =>
      true
  | _ =>
      false

def psTestQueryStableInterfaceStopsPropagation : Bool :=
  match
      psQueryCommitRebuilt
        psQuerySnapshotEmpty
        (psQueryInputA "source-a-v2")
        (psModuleInterfaceFingerprintV1 "iface-a-v1") with
  | Except.error _ =>
      false
  | Except.ok current =>
      match
          psQueryEvaluateModule
            psQueryPreviousSnapshot
            current
            (psQueryInputB [psQueryTestA]) with
      | PsQueryDecision.green record =>
          psStringEq record.interfaceFingerprint.semanticKey "iface-b-v1"
      | PsQueryDecision.red _ =>
          false

def psTestQueryChangedInterfaceInvalidatesDependent : Bool :=
  match
      psQueryCommitRebuilt
        psQuerySnapshotEmpty
        (psQueryInputA "source-a-v2")
        (psModuleInterfaceFingerprintV1 "iface-a-v2") with
  | Except.error _ =>
      false
  | Except.ok current =>
      match
          psQueryEvaluateModule
            psQueryPreviousSnapshot
            current
            (psQueryInputB [psQueryTestA]) with
      | PsQueryDecision.red
          (PsQueryInvalidation.dependencyInterfaceChanged
            dependency) =>
          psNameEq dependency psQueryTestA
      | _ =>
          false

def psTestQueryImportShapeInvalidates : Bool :=
  match
      psQueryEvaluateModule
        psQueryPreviousSnapshot
        psQuerySnapshotEmpty
        (psQueryInputB []) with
  | PsQueryDecision.red
      PsQueryInvalidation.importsChanged =>
      true
  | _ =>
      false

def psTestQueryMissingDependencyIsRed : Bool :=
  match
      psQueryEvaluateModule
        psQueryPreviousSnapshot
        psQuerySnapshotEmpty
        (psQueryInputB [psQueryTestA]) with
  | PsQueryDecision.red
      (PsQueryInvalidation.dependencyUnavailable
        dependency) =>
      psNameEq dependency psQueryTestA
  | _ =>
      false

def psTestQueryCommitRequiresDependencies : Bool :=
  match
      psQueryCommitRebuilt
        psQuerySnapshotEmpty
        (psQueryInputB [psQueryTestA])
        (psModuleInterfaceFingerprintV1 "iface-b-v2") with
  | Except.error
      (PsQueryGraphError.missingDependencyInterface
        owner
        dependency) =>
      psNameEq owner psQueryTestB
        && psNameEq dependency psQueryTestA
  | _ =>
      false

def psTestQueryDuplicateCommitRejected : Bool :=
  match
      psQueryCommitRebuilt
        psQuerySnapshotEmpty
        (psQueryInputA "source-a-v1")
        (psModuleInterfaceFingerprintV1 "iface-a-v1") with
  | Except.error _ =>
      false
  | Except.ok current =>
      match
          psQueryCommitRebuilt
            current
            (psQueryInputA "source-a-v1")
            (psModuleInterfaceFingerprintV1 "iface-a-v1") with
      | Except.error
          (PsQueryGraphError.duplicateRecord name) =>
          psNameEq name psQueryTestA
      | _ =>
          false

def psTestQueryInterfaceChangeDetection : Bool :=
  let unchanged :=
    psQueryInterfaceChanged
      psQueryPreviousSnapshot
      psQueryTestA
      (psModuleInterfaceFingerprintV1 "iface-a-v1");
  let changed :=
    psQueryInterfaceChanged
      psQueryPreviousSnapshot
      psQueryTestA
      (psModuleInterfaceFingerprintV1 "iface-a-v2");
  let missing :=
    psQueryInterfaceChanged
      psQueryPreviousSnapshot
      (psQueryTestName "Missing")
      (psModuleInterfaceFingerprintV1 "iface-new");
  if unchanged then
    false
  else if changed then
    missing
  else
    false

def psTestBehavioralModuleInterfaceIdentity : Bool :=
  let first :=
    psBehavioralModuleInterfaceV1
      "spec-v1"
      "effects-v1"
      "resources-v1"
      "assumptions-v1";
  let same :=
    psBehavioralModuleInterfaceV1
      "spec-v1"
      "effects-v1"
      "resources-v1"
      "assumptions-v1";
  let changed :=
    psBehavioralModuleInterfaceV1
      "spec-v2"
      "effects-v1"
      "resources-v1"
      "assumptions-v1";
  if psBehavioralModuleInterfaceEq first same then
    if psBehavioralModuleInterfaceEq first changed then
      false
    else
      true
  else
    false

structure PsProjectQueryNamedTest where
  name : String
  passed : Bool

def psProjectQueryTests :
    List PsProjectQueryNamedTest :=
  [
    {
      name := "unchanged module is green"
      passed := psTestQueryUnchangedModuleIsGreen
    },
    {
      name := "source change is red"
      passed := psTestQuerySourceChangeIsRed
    },
    {
      name := "stable interface stops propagation"
      passed := psTestQueryStableInterfaceStopsPropagation
    },
    {
      name := "changed interface invalidates dependent"
      passed := psTestQueryChangedInterfaceInvalidatesDependent
    },
    {
      name := "import shape invalidates"
      passed := psTestQueryImportShapeInvalidates
    },
    {
      name := "missing dependency is red"
      passed := psTestQueryMissingDependencyIsRed
    },
    {
      name := "commit requires dependency interfaces"
      passed := psTestQueryCommitRequiresDependencies
    },
    {
      name := "duplicate commit rejected"
      passed := psTestQueryDuplicateCommitRejected
    },
    {
      name := "interface change detection"
      passed := psTestQueryInterfaceChangeDetection
    },
    {
      name := "behavioral interface identity"
      passed := psTestBehavioralModuleInterfaceIdentity
    }
  ]

def psRunProjectQueryTests
    (tests : List PsProjectQueryNamedTest) :
    IO Bool :=
  match tests with
  | List.nil =>
      pure true
  | List.cons test rest => do
      if test.passed then
        IO.println
          (String.Internal.append
            "PSC1_PROJECT_QUERY_PASS: "
            test.name)
      else
        IO.println
          (String.Internal.append
            "PSC1_PROJECT_QUERY_FAIL: "
            test.name)
      let restPassed ←
        psRunProjectQueryTests rest
      pure
        (if test.passed then
          restPassed
        else
          false)

def main : IO Unit := do
  let passed ←
    psRunProjectQueryTests
      psProjectQueryTests
  if passed then
    IO.println
      "PSC1_PROJECT_QUERY_GRAPH_TESTS: PASS"
  else
    throw
      (IO.userError
        "PSC1_PROJECT_QUERY_GRAPH_TESTS: FAIL")
