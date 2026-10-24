"""Static reconciliation of independently inspected exact-source artifacts."""
import argparse
import hashlib
import json
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--run', required=True)
parser.add_argument('--jobs', required=True)
parser.add_argument('--artifacts', required=True)
parser.add_argument('--canonical-artifact-id', type=int, required=True)
parser.add_argument('--observed-utc', required=True)
parser.add_argument('--output', required=True)
args = parser.parse_args()
root = Path('t05-evidence')
source = 'f5d97bafbd48adde29101ed44f45288ae53b9c87'
run_id = 40089243726
tree = '9e85b027cc0f8535efc475b490069f2012fd1435'

def read(path):
    return json.loads(Path(path).read_text())

def digest(path):
    path = Path(path)
    data = path.read_bytes()
    return {'file': path.name, 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()}

run, jobs, artifacts = read(args.run), read(args.jobs)['jobs'], read(args.artifacts)['artifacts']
assert (run['id'], run['head_sha'], run['run_attempt'], run['status'], run['conclusion']) == (
    run_id, source, 1, 'completed', 'success')
expected_jobs = {'native-header': 120858341284,
                 'generated-header (generated)': 120858822962,
                 'generated-header (canonical)': 120858823020}
assert len(jobs) == 3 and {j['name']: j['id'] for j in jobs} == expected_jobs
for job in jobs:
    assert (job['run_id'], job['head_sha'], job['run_attempt'], job['status'], job['conclusion']) == (
        run_id, source, 1, 'completed', 'success')
expected_artifacts = {'psc1-t05-header-native-attempt-1': 12558173561,
                      'psc1-t05-header-generated-attempt-1': 12558878274,
                      'psc1-t05-header-canonical-attempt-1': args.canonical_artifact_id}
assert len(artifacts) == 3 and {a['name']: a['id'] for a in artifacts} == expected_artifacts
for artifact in artifacts:
    assert artifact['workflow_run']['id'] == run_id
    assert artifact['workflow_run']['head_sha'] == source
    assert not artifact['expired']

native_path = root / '2026-10-24-t05-f5d9-native-artifact-review.json'
proof_path = root / '2026-10-24-t05-f5d97baf-native-proofs.json'
native, proof = read(native_path), read(proof_path)
for report in (native, proof):
    assert (report['sourceSha'], report['runId'], report['runAttempt'], report['jobId'],
            report['jobConclusion'], report['artifactId']) == (
        source, run_id, 1, 120858341284, 'success', 12558173561)
assert native['treeSha'] == tree and native['totalProofReports'] == 172
assert native['crcVerified'] and native['allFilesVerified'] == 49
assert native['copiedSourceGitBlobsVerified'] == 32
assert proof['orderedUniqueSourceReportsVerified'] and proof['allowedStandardAxiomsOnly']
assert proof['nativeGatesAllPassed'] and proof['noLocalLeanJavaScriptCompilerKernelOrTestExecution']

routes = {}
reports = [digest(native_path), digest(proof_path)]
for route, job_id, artifact_id, count in (
    ('generated', 120858822962, 12558878274, 223),
    ('canonical', 120858823020, args.canonical_artifact_id, 226)):
    path = root / f'2026-10-24-t05-f5d9-{route}-artifact-review.json'
    report = read(path)
    assert (report['sourceSha'], report['runId'], report['runAttempt'], report['route'],
            report['status'], report['jobId'], report['artifactId']) == (
        source, str(run_id), '1', route, 'pass', job_id, artifact_id)
    assert report['sourceTreeSha'] == tree
    assert report['fileCount'] == count and report['allZipMembersReadAndCrcChecked']
    assert report['copiedInputCount'] == 32 and report['allCopiedInputsMatchAuthenticatedGitBlobs']
    assert report['allRootLevelLogDigestsRecomputed']
    assert report['localProjectExecutionPerformed'] is False
    reports.append(digest(path))
    log_path = root / f'2026-10-24-t05-f5d9-{route}-terminal-log-review.json'
    if log_path.exists():
        reports.append(digest(log_path))
    routes[route] = {key: report[key] for key in (
        'jobId', 'artifactId', 'artifact', 'fileCount', 'copiedInputCount', 'leanClosure',
        'canonicalClosure', 'completeCompilation', 'headerMatrix', 'measurements',
        'originalReceiptDigest', 'runtimeConstraints', 'orderedActionsGates')}
assert routes['generated']['headerMatrix'] == routes['canonical']['headerMatrix']

output = {
    'schema': 'psc1-t05-header-exact-cohort-reconciliation-v1',
    'repository': 'dwijayuda/pskernel', 'sourceSha': source, 'treeSha': tree,
    'productionTreeSha': '6951c3237eaca9fcc1ec9c173028cb651a6afa0d',
    'runId': run_id, 'runAttempt': 1, 'runStatus': 'completed', 'runConclusion': 'success',
    'runUrl': run['html_url'], 'observedUtc': args.observed_utc,
    'nativeProofReports': 172, 'nativeNewProofReports': 64, 'nativeRetainedProofReports': 108,
    'nativeArtifactId': 12558173561, 'totalIndependentlyInspectedArtifactFiles': 498,
    'copiedInputsPerArtifact': 32, 'leanModulesPerRoute': 146,
    'headerAssertionsPerRoute': 1992, 'cacheAssertionsPerRoute': 1884,
    'sameSourceAndAttemptForAllJobs': True, 'noPriorAttemptPassInheritance': True,
    'routes': routes, 'evidenceFiles': reports,
    'terminalMetadataFiles': [digest(args.run), digest(args.jobs), digest(args.artifacts)],
    'allJobs': jobs, 'allArtifacts': artifacts,
    'scope': {'headerNarrowPass': True, 'fullOrdinaryAdmission': False,
              'publicOrdinaryRoutingChanged': False, 'publicFallbackUsedForHeaderMatrix': False,
              'arenaModelEstablishmentProved': False, 'concreteDecoderBridgeProved': False,
              'T05': 'OPEN', 'B': 'OPEN', 'C': 'FAIL', 'D': 'OPEN',
              'T01FQualificationSourceUnchanged': '0d9f062846d109c362210d441df5fd407ca2cdd7',
              'nextChangedSourceRequiresItsOwnCohort': True,
              'noGeneralSpeedupClaim': True, 'noLocalProjectExecution': True,
              'integrationAdvancedByThisReport': False},
}
Path(args.output).write_text(json.dumps(output, indent=2) + '\n')
print(json.dumps({'status': 'pass', 'source': source, 'run': run_id,
                  'attempt': 1, 'files': 498, 'output': digest(args.output)}))
