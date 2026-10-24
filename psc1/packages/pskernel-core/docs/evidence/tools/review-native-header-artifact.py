"""Static inspection of an Actions artifact; never executes project content."""
from pathlib import Path
from zipfile import ZipFile
import hashlib
import json
import re
import sys

archive, git_map, run, job, artifact, expected_zip_sha, output = sys.argv[1:]
archive = Path(archive)
git = json.loads(Path(git_map).read_text())
raw_zip = archive.read_bytes()
assert hashlib.sha256(raw_zip).hexdigest() == expected_zip_sha
allowed = {'propext', 'Classical.choice', 'Quot.sound'}
modules = [
    ('PsKernelOrdinaryHeaderStateProofs', 'header-state-proofs.log', 49),
    ('PsKernelOrdinaryOccurrenceProofs', 'occurrence-proofs.log', 15),
    ('PsKernelCacheScopeProofs', 'cache-scope-proofs.log', 60),
    ('PsKernelExprV2SessionProofs', 'session-proofs.log', 14),
    ('PsKernelScalarHashWorkerRegression', 'scalar-hash-native.log', 11),
    ('PsKernelClosedCacheAnalysisRegression', 'closed-cache-analysis-proofs.log', 7),
    ('PsKernelKnotFuelProofs', 'knot-fuel-proofs.log', 16),
]
header_markers = [
    'PSC1_ORDINARY_HEADER_NATIVE: PASS matrix=432 positiveDirect=10 crossFault=2 headerOnly=true',
    'PSC1_ORDINARY_OCCURRENCE_NATIVE: PASS heads=171 fuelCases=1026 wrappers=171 sharedOffsets=2',
    'PSC1_ORDINARY_ANNOTATIONS_NATIVE: PASS fuelCases=75 wrappers=15 invalidIDs=2',
    'PSC1_ORDINARY_HEADER_STATE_NATIVE: PASS sequences=3 propagated=24 forkFields=all boundaries=3',
    'PSC1_ORDINARY_HEADER_ORACLE: PASS accepted=4 rejected=2 headerOnly=true',
    'PSC1_ORDINARY_HEADER_REGRESSION: PASS headerOnly=true fullAdmission=false',
]
with ZipFile(archive) as z:
    assert z.testzip() is None
    names = [n for n in z.namelist() if not n.endswith('/')]
    assert len(names) == len(set(names)) == 49
    files = [{'path': n, 'bytes': len(z.read(n)), 'sha256': hashlib.sha256(z.read(n)).hexdigest()} for n in names]
    inventory = json.loads(z.read('source-inventory.json'))
    receipt = json.loads(z.read('native-receipt.json'))
    for r in [inventory, receipt]:
        assert r['sourceSha'] == git['sourceSha'] and r['runId'] == run and r['runAttempt'] == '1' and r['route'] == 'native'
    assert len(inventory['files']) == 32
    for item in inventory['files']:
        b = z.read('sources/' + item['path'])
        blob = hashlib.sha1(b'blob ' + str(len(b)).encode() + b'\0' + b).hexdigest()
        assert len(b) == item['bytes'] and hashlib.sha256(b).hexdigest() == item['sha256']
        assert blob == item['gitBlobSha'] == git['gitBlobs'][item['path']]
    reports = []
    for module, log, count in modules:
        source = z.read('sources/psc1/test/' + module + '.lean').decode()
        expected = re.findall(r'^#print axioms\s+(\S+)', source, re.M)
        expected = [n if '.' in n else module + '.' + n for n in expected]
        raw = z.read(log)
        actual = re.findall(r"'([^']+)' (?:depends on axioms:\s*\[([^\]]*)\]|does not depend on any axioms)", raw.decode(), re.S)
        assert len(expected) == len(set(expected)) == count
        assert [x[0] for x in actual] == expected
        assert not re.search(r'\berror:', raw.decode())
        dependencies = []
        for name, axioms in actual:
            deps = [a.strip() for a in axioms.split(',') if a.strip()]
            assert set(deps) <= allowed
            dependencies.append({'name': name, 'axioms': deps})
        recorded = next(x for x in receipt['proofs'] if x['module'] == module)
        assert recorded['names'] == expected and recorded['proofs'] == count
        assert recorded['logSha256'] == hashlib.sha256(raw).hexdigest()
        reports.append({'module': module, 'count': count, 'orderedUnique': True, 'sourceMatched': True,
                        'allowedAxiomsOnly': True, 'reports': dependencies, 'logSha256': hashlib.sha256(raw).hexdigest()})
    assert sum(x['count'] for x in reports) == receipt['totalProofs'] == 172
    assert receipt['newProofs'] == 64 and receipt['retainedProofs'] == 108
    assert receipt['headerOnly'] and not receipt['fullAdmission']
    assert z.read('header-native.log').decode().splitlines() == header_markers
    assert z.read('lean-githash.txt').decode().strip() == 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc'
    assert 'version 4.35.0' in z.read('lean-version.txt').decode()
    assert z.read('node-version.txt').decode().startswith('v22.')
    assert z.read('new-header-proof-status.log').decode().strip() == 'PSC1_T05_NEW_PROOF_RESULTS stateCount=0 stateLean=0 occurrenceCount=0 occurrenceLean=0'
    assert 'PSC1_V2_DAG_REGRESSION: PASS' in z.read('dag-native.log').decode()
    assert 'PSC1_V2_SESSION_OWNERS_OFFICIAL: PASS declarations=4 direct=7' in z.read('prefix-native.log').decode()
    result = {
        'schema': 'psc1-t05-native-independent-artifact-review-v1', 'sourceSha': git['sourceSha'], 'treeSha': git['treeSha'],
        'runId': int(run), 'runAttempt': 1, 'jobId': int(job), 'jobConclusion': 'success', 'artifactId': int(artifact),
        'archiveBytes': len(raw_zip), 'archiveSha256': expected_zip_sha, 'crcVerified': True,
        'allFilesVerified': len(files), 'copiedSourceGitBlobsVerified': 32,
        'fileInventory': files, 'proofs': reports, 'newProofReports': 64, 'totalProofReports': 172,
        'headerMarkers': header_markers,
        'retainedDagAndPrefixMarkers': {n: z.read(n).decode().splitlines() for n in ['dag-native.log', 'prefix-native.log']},
        'leanCommit': 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc', 'nodeVersion': z.read('node-version.txt').decode().strip(),
        'headerOnly': True, 'fullAdmission': False, 'publicRoutingChanged': False,
        'generatedRoutes': 'pending; not inferred from native success',
        'limits': ['Occurrence correspondence remains conditional on ArenaModel; replay-validator-to-model bridge is open.',
                   'No full T05 ordinary admission or whole-boundary qualification is claimed.'],
    }
dest = Path(output)
dest.write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps({'evidence': str(dest), 'bytes': dest.stat().st_size,
                  'sha256': hashlib.sha256(dest.read_bytes()).hexdigest(), 'verifiedFiles': 49,
                  'sourceGitBlobs': 32, 'proofReports': 172, 'strictHeaderMarkers': 6}))
