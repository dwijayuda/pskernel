"""Authenticate complete561 and the already passed exact official193 reference."""
import hashlib, importlib.util, io, json, os, pathlib, stat, subprocess, time, zipfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = '2f7ee0afc1cc2fbccdf47b4f140b5cf01eb05c89'
TREE = '65d5b9c3d0431a8b86961b6d1aec398f7169d223'
RUN = 40228598527
GENERATED_JOB_NAME = 'generated-header (generated)'
OFFICIAL_SOURCE = 'ecafaabf844babd76a5de57bdf12909845961fba'
OFFICIAL_RUN = 40218506579
OFFICIAL_ARTIFACT = 12608314252
OFFICIAL_SHA = '4c6bc6f6819ebe2adb032e23889833bde5eafb90003cc529b56f11e5cc5b5f8a'
spec = importlib.util.spec_from_file_location('authenticated_download', ROOT/'scripts/pskernel-church-stage-ci.py')
C = importlib.util.module_from_spec(spec)
spec.loader.exec_module(C)

def bundle(raw, count):
    z = zipfile.ZipFile(io.BytesIO(raw))
    infos = z.infolist()
    C.require(len(infos) == len({i.filename for i in infos}) == count and z.testzip() is None,
              'Exact unique CRC-checked archive members')
    for i in infos:
        p = pathlib.PurePosixPath(i.filename)
        C.require(not p.is_absolute() and '..' not in p.parts and p.as_posix() == i.filename
                  and '\\' not in i.filename and ':' not in i.filename and not i.is_dir()
                  and not stat.S_ISLNK(i.external_attr >> 16) and i.file_size <= 32_000_000,
                  'Safe bounded producer member')
    return z

def main():
    C.require(os.environ.get('GITHUB_ACTIONS') == 'true' and os.environ.get('RUNNER_OS') == 'Linux',
              'GitHub Linux only')
    repo = ROOT.parent
    C.require(subprocess.check_output(['git','rev-parse','HEAD'],cwd=repo,text=True).strip()
              == os.environ['GITHUB_SHA'], 'Exact workflow source')
    C.require(subprocess.check_output(['git','rev-parse','HEAD:psc1/packages/pskernel-core/src'],
              cwd=repo,text=True).strip() == TREE, 'Exact complete561 production tree')
    stable = ['psc1/packages/pskernel-core/src','psc1/scripts/pskernel-arena435-oracle.py',
              'psc1/scripts/pskernel-arena435-compare.py','psc1/scripts/pskernel-arena435-inspect.py',
              'psc1/scripts/pskernel-arena435-progress-controls.py','psc1/scripts/pskernel-arena-replay.mjs',
              'psc1/scripts/pskernel-arena-replay-controls.mjs','psc1/lean-toolchain',
              'psc1/scripts/pskernel-church-stage-ci.py']
    subprocess.run(['git','diff','--exit-code',SOURCE,'HEAD','--',*stable],cwd=repo,check=True)
    subprocess.run(['git','diff','--exit-code',OFFICIAL_SOURCE,'HEAD','--',
                    'psc1/scripts/pskernel-arena435-oracle.py','psc1/scripts/pskernel-arena435-inspect.py',
                    'psc1/lean-toolchain'],cwd=repo,check=True)
    official = json.loads(C.github('/actions/artifacts/'+str(OFFICIAL_ARTIFACT)))
    C.require(official['workflow_run']['id'] == OFFICIAL_RUN
              and official['workflow_run']['head_sha'] == OFFICIAL_SOURCE and not official['expired']
              and official['size_in_bytes'] == 114874 and official['digest'] == 'sha256:'+OFFICIAL_SHA,
              'Pinned already passed official archive')
    official_jobs = json.loads(C.github('/actions/runs/'+str(OFFICIAL_RUN)+'/jobs?per_page=100'))['jobs']
    reference = [j for j in official_jobs if j['name'] == 'official-arena-reference']
    C.require(len(reference) == 1 and reference[0]['conclusion'] == 'success', 'Actual official producer PASS')
    raw = C.github('/actions/artifacts/'+str(OFFICIAL_ARTIFACT)+'/zip')
    C.require(C.digest(raw) == {'bytes':114874,'sha256':OFFICIAL_SHA}, 'Actual complete official archive')
    z = bundle(raw,199)
    report = json.loads(z.read('report.json'))
    C.require(report['total'] == len(report['tests']) == 193 and report['excluded_cases'] == []
              and report['official_reference_complete'] and report['historical_label_drift'] == 0
              and report['archive_sha256'] == '98a69742b538296c5f413d0527dfeef8c4d1815fe64b12c8623cd33de63bee0d'
              and report['target_lean']['githash'] == 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc',
              'All193 original bodies and pinned official reference')
    for item in report['controls'] + report['tests']:
        observation = item.get('official',item)
        C.require(hashlib.sha256(z.read('case-logs/'+observation['log'])).hexdigest()
                  == observation['output_sha256'], 'Actual official output digest')
    out = pathlib.Path(os.environ['RUNNER_TEMP'])/'arena435-independent'
    out.mkdir(parents=True,exist_ok=True)
    oracle = pathlib.Path(os.environ['RUNNER_TEMP'])/'arena435-official'
    oracle.mkdir()
    for entry in z.infolist():
        target = oracle/entry.filename
        target.parent.mkdir(parents=True,exist_ok=True)
        target.write_bytes(z.read(entry.filename))
    (out/'authenticated-official.zip').write_bytes(raw)
    deadline = time.monotonic()+3600
    while True:
        run = json.loads(C.github('/actions/runs/'+str(RUN)))
        C.require(run['head_sha'] == SOURCE and run['run_attempt'] == 1, 'Exact complete561 source/attempt')
        if run['status'] == 'completed':
            C.require(run['conclusion'] == 'success', 'All native/generated/canonical561 must pass')
            break
        C.require(time.monotonic() < deadline, 'Bounded wait for complete561 qualification')
        print('Awaiting exact complete561 producer; no Arena replay started',flush=True)
        time.sleep(30)
    jobs = json.loads(C.github('/actions/runs/'+str(RUN)+'/jobs?per_page=100'))['jobs']
    C.require(len(jobs) == 3 and all(j['conclusion'] == 'success' for j in jobs)
              and any(j['name'] == GENERATED_JOB_NAME for j in jobs), 'All3 actual complete jobs PASS')
    generated_job, = [j for j in jobs if j['name'] == GENERATED_JOB_NAME]
    C.require(generated_job['head_sha'] == SOURCE, 'Exact generated producer source')
    artifacts = json.loads(C.github('/actions/runs/'+str(RUN)+'/artifacts?per_page=100'))['artifacts']
    artifact, = [a for a in artifacts if a['name'] == 'psc1-t05-header-generated-attempt-1']
    C.require(not artifact['expired'] and artifact['workflow_run']['head_sha'] == SOURCE
              and artifact['workflow_run']['id'] == RUN and artifact['digest'].startswith('sha256:'),
              'Exact source-bound generated artifact')
    raw = C.github('/actions/artifacts/'+str(artifact['id'])+'/zip')
    C.require(len(raw) == artifact['size_in_bytes'] and
              hashlib.sha256(raw).hexdigest() == artifact['digest'][7:], 'Actual raw producer digest')
    z = bundle(raw,448)
    kernel = z.read('detached/kernel.mjs')
    C.require(kernel == z.read('production/kernel.js'), 'Complete detached/production program identity')
    receipt = json.loads(z.read('quot-owner/route-receipt.json'))
    C.require(receipt['sourceSha'] == SOURCE and receipt['runId'] == str(RUN)
              and receipt['attempt'] == '1' and receipt['status'] == 'pass'
              and receipt['route'] == 'generated' and receipt['nativeProofs'] == 561
              and receipt['proofModules'] == 40 and receipt['productionTree'] == TREE
              and receipt['kernel'] == C.digest(kernel) and receipt['fuel'] == 4096
              and receipt['oldSpaceMiB'] == 2048 and receipt['emptyPATH'] is True
              and receipt['summary']['assertions'] == 17, 'Actual complete561 route receipt')
    for key,member in [('retainedCompleteRoute','quot/route-receipt.json'),
                       ('runtimeLog','quot-owner/runtime.log'),('runtimeMemory','quot-owner/runtime.memory')]:
        C.require(C.digest(z.read(member)) == receipt[key], 'Exact physical route evidence '+member)
    for name in ['pskernel-arena-replay.mjs','pskernel-arena435-oracle.py']:
        C.require(z.read('unary/sources/psc1/scripts/'+name) == (ROOT/'scripts'/name).read_bytes(),
                  'Exact original replay/oracle source')
    target = ROOT/'dist/arena435/kernel.js'
    target.parent.mkdir(parents=True,exist_ok=True)
    target.write_bytes(kernel)
    (out/'authenticated-producer.zip').write_bytes(raw)
    record = {'schema':'psc1-quot561-arena-kernel-v1','workflowSourceSha':os.environ['GITHUB_SHA'],
              'workflowRunId':os.environ['GITHUB_RUN_ID'],'kernelSourceSha':SOURCE,'productionTree':TREE,
              'producerRun':RUN,'producerJob':generated_job['id'],'producerArtifact':artifact['id'],
              'producerArchive':C.digest(raw),'kernel':C.digest(kernel),'nativeReports':561,'proofModules':40,
              'officialReferenceSource':OFFICIAL_SOURCE,'officialReferenceRun':OFFICIAL_RUN,
              'officialReferenceArtifact':OFFICIAL_ARTIFACT,'officialReferenceArchiveSha256':OFFICIAL_SHA,
              'all3SourceCohortJobsPass':True,'sameProductionAndReplaySources':True,
              'fullArenaQualified':False,'performanceQualified':False}
    C.write(out/'kernel-provenance.json',record)
    print('PSC1_QUOT561_ARENA_AUTHENTICATED: PASS '+json.dumps(record,separators=(',',':')))

if __name__ == '__main__':
    main()
