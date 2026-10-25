"""Source-bound Church stage diagnosis. Runs only in GitHub Linux Actions."""
import argparse
import hashlib
import importlib.util
import io
import json
import os
import pathlib
import re
import shutil
import stat
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import zipfile

REPO = 'dwijayuda/pskernel'
BASE = 'dbd9db47bd8ef184583bcd5ae3feb38f3ce612c5'
PRODUCER_RUN = 40191895625
ARTIFACT = 12599457242
ZIP_SHA = '86b06d46315edadbbccafef6f2c3f92dee027cd67cd0c3539520d19981251d9c'
KERNEL_SHA = '281995846a8499c2da42a512893c0ceb86bacfa1e80d7d272300937aee6498aa'
INPUT_SHA = '443428491e773dc131b1655bf72312517ddc29010112bb8bb241a48ab55c51c1'
BODY_SHA = '85526c244d94e9710a6be432164c054c742d8f7c1d3ca0d8580d0874f7815a47'
ROOT = pathlib.Path(__file__).resolve().parents[1]


def require(ok, message):
    if not ok: raise RuntimeError(message)


def digest(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def write(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n')


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *args): return None


def github(path):
    request = urllib.request.Request('https://api.github.com/repos/' + REPO + path,
        headers={'Authorization': 'Bearer ' + os.environ['GH_TOKEN'],
                 'Accept': 'application/vnd.github+json', 'User-Agent': 'psc1-church-stage-audit'})
    opener = urllib.request.build_opener(NoRedirect)
    try:
        with opener.open(request, timeout=30) as response: raw = response.read(8_000_001)
    except urllib.error.HTTPError as error:
        require(error.code in [301, 302, 303, 307, 308], 'GitHub API read failed')
        location = error.headers.get('Location', '')
        parsed = urllib.parse.urlsplit(location)
        require(parsed.scheme == 'https' and parsed.hostname and not parsed.username and not parsed.password
                and parsed.port in [None, 443] and (parsed.hostname.endswith('.blob.core.windows.net')
                or parsed.hostname.endswith('.githubusercontent.com')), 'Unexpected signed artifact host')
        # A fresh request prevents forwarding the GitHub token to artifact storage.
        with opener.open(urllib.request.Request(location), timeout=30) as response: raw = response.read(8_000_001)
    require(len(raw) <= 8_000_000, 'Bounded API body exceeded')
    return raw


def prepare(out, archive):
    out.mkdir(parents=True, exist_ok=False)
    repo = ROOT.parent
    require(subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=repo, text=True).strip() == os.environ['GITHUB_SHA'], 'Exact source checkout')
    subprocess.run(['git', 'diff', '--exit-code', BASE, 'HEAD', '--',
        'psc1/packages/pskernel-core/src', 'psc1/kernel-lakefile.lean', 'psc1/lean-toolchain',
        'psc1/scripts/pskernel-arena-replay.mjs'], cwd=repo, check=True)
    run = json.loads(github('/actions/runs/' + str(PRODUCER_RUN)))
    artifact = json.loads(github('/actions/artifacts/' + str(ARTIFACT)))
    require(run['head_sha'] == BASE and run['status'] == 'completed' and run['conclusion'] == 'success'
            and run['run_attempt'] == 1, 'Authentic complete compiler/kernel producer')
    require(artifact['workflow_run']['id'] == PRODUCER_RUN and artifact['workflow_run']['head_sha'] == BASE
            and artifact['digest'] == 'sha256:' + ZIP_SHA and artifact['size_in_bytes'] == 2848152
            and not artifact['expired'], 'Exact generated artifact metadata')
    raw = github('/actions/artifacts/' + str(ARTIFACT) + '/zip')
    require(digest(raw) == {'bytes': 2848152, 'sha256': ZIP_SHA}, 'Actual raw artifact ZIP digest')
    (out / 'producer.zip').write_bytes(raw)
    write(out / 'producer-run.json', run); write(out / 'producer-artifact.json', artifact)
    with zipfile.ZipFile(io.BytesIO(raw)) as z:
        infos = z.infolist()
        require(len(infos) == 361 and len({i.filename for i in infos}) == 361 and z.testzip() is None, '361 unique CRC-valid producer members')
        for info in infos:
            path = pathlib.PurePosixPath(info.filename)
            require(not path.is_absolute() and '..' not in path.parts and path.as_posix() == info.filename
                    and '\\' not in info.filename and ':' not in info.filename and not info.is_dir()
                    and not stat.S_ISLNK(info.external_attr >> 16) and info.file_size <= 32_000_000, 'Safe bounded artifact members')
        kernel = z.read('detached/kernel.mjs')
        require(digest(kernel) == {'bytes': 10298226, 'sha256': KERNEL_SHA}, 'Exact executed complete kernel')
        require(z.read('production/kernel.js') == kernel, 'Detached/production kernel equality')
    detached = out / 'detached'; detached.mkdir(); (detached / 'kernel.mjs').write_bytes(kernel)
    spec = importlib.util.spec_from_file_location('church_oracle', ROOT / 'scripts/pskernel-arena435-oracle.py')
    oracle = importlib.util.module_from_spec(spec); spec.loader.exec_module(oracle)
    case, = [item for item in oracle.read_archive(archive) if item[1] == 'perf/church-numerals.ndjson']
    adapted, provenance = oracle.adapt_header(case[2])
    require(hashlib.sha256(adapted).hexdigest() == INPUT_SHA
            and hashlib.sha256(adapted.partition(b'\n')[2]).hexdigest() == BODY_SHA, 'Unchanged original Church declaration body')
    (out / 'input.ndjson').write_bytes(adapted)
    shutil.copyfile(out / 'input.ndjson', detached / 'input.ndjson')
    subprocess.run([sys.executable, str(ROOT / 'scripts/pskernel-church-fixture.py'),
        str(out / 'input.ndjson'), str(ROOT / 'test/PsKernelChurchSource.lean'), '--verify'], check=True)
    driver = (ROOT / 'scripts/pskernel-arena-replay.mjs').read_text()
    anchor = "    const result=accepted(get('psKernelV1RunDag')(session,nil,S.safe,arena,list(commands)),'kernel-admission');"
    require(driver.count(anchor) == 1, 'Single byte-exact production admission boundary')
    modified = "import {runChurchStages} from './pskernel-church-stages.mjs';\n" + driver.replace(anchor,
        "    return runChurchStages(kernel,{arena,commands,session,nil,safety:S.safe,list,array,request:order[3].request});")
    (detached / 'diagnostic-transport.mjs').write_text(modified)
    shutil.copyfile(ROOT / 'scripts/pskernel-arena-replay.mjs', detached / 'pskernel-arena-replay.mjs')
    shutil.copyfile(ROOT / 'scripts/pskernel-church-stages.mjs', detached / 'pskernel-church-stages.mjs')
    (detached / 'staged-runner.mjs').write_text("import {readFileSync} from 'node:fs';\nimport * as kernel from './kernel.mjs';\nimport {replayText} from './diagnostic-transport.mjs';\nreplayText(kernel,readFileSync('input.ndjson','utf8'));\n")
    paths = ['psc1/test/PsKernelChurchSource.lean', 'psc1/test/PsKernelChurchStageProbe.lean',
             'psc1/scripts/pskernel-church-fixture.py', 'psc1/scripts/pskernel-church-stage-ci.py',
             'psc1/scripts/pskernel-church-stages.mjs', 'psc1/scripts/pskernel-church-trace-ci.py', 'psc1/scripts/pskernel-arena-replay.mjs',
             '.github/workflows/psc1-pskernel-church-stages.yml', 'psc1/kernel-lakefile.lean',
             'psc1/lean-toolchain', 'psc1/packages/pskernel-core/src/Ps/KernelCore/API/DagAdmission.lean']
    sources = []
    for name in paths:
        raw = (repo / name).read_bytes(); target = out / 'sources' / name
        target.parent.mkdir(parents=True, exist_ok=True); target.write_bytes(raw)
        sources.append({'path': name, **digest(raw)})
    write(out / 'source.json', {'sourceSha': os.environ['GITHUB_SHA'], 'runId': os.environ['GITHUB_RUN_ID'],
        'runAttempt': os.environ['GITHUB_RUN_ATTEMPT'], 'productionSource': BASE,
        'input': digest(adapted), 'bodySha256': BODY_SHA, 'adaptation': provenance,
        'files': sources, 'generatedKernel': digest(kernel), 'producerZip': digest((out / 'producer.zip').read_bytes())})
    print('PSC1_CHURCH_PREPARE: PASS originalBody=true producerAuthenticated=true sources=11')


def bounded(out, label, command, cwd, env):
    log = out / (label + '.stdout'); err = out / (label + '.stderr'); timing = out / (label + '.time')
    start = time.monotonic()
    with log.open('wb') as stdout, err.open('wb') as stderr:
        process = subprocess.Popen(['/usr/bin/time', '-f', 'peak_rss_kib=%M wall_seconds=%e exit_status=%x',
            '-o', str(timing)] + command, cwd=cwd, env=env, stdout=stdout, stderr=stderr, start_new_session=True)
        try: status = process.wait(timeout=60)
        except subprocess.TimeoutExpired:
            import signal
            os.killpg(process.pid, signal.SIGKILL); process.wait()
            write(out / (label + '.status.json'), {'timedOut': True, 'seconds': time.monotonic()-start})
            raise RuntimeError('Unchanged60-second process limit reached: ' + label)
    write(out / (label + '.status.json'), {'timedOut': False, 'exitCode': status, 'seconds': time.monotonic()-start})
    require(status == 0, 'Process failed: ' + label)
    return log.read_text()


def execute(out, node, native):
    require(pathlib.Path(node).is_absolute() and pathlib.Path(native).is_absolute(), 'Exact runtime executables')
    detached = out / 'detached'; env = dict(os.environ, PATH='', NODE_OPTIONS='')
    results = {}; stages = {}; prefixes = {}
    for runtime in ['native', 'generated']:
        for mode in ['baseline', 'stages']:
            label = runtime + '-' + mode
            command = [native, mode] if runtime == 'native' else [node, '--max-old-space-size=2048'] + (
                ['pskernel-arena-replay.mjs', 'kernel.mjs', 'input.ndjson'] if mode == 'baseline' else ['staged-runner.mjs'])
            text = bounded(out, label, command, detached, env)
            marker = 'PSC1_ARENA_REPLAY ' if label == 'generated-baseline' else 'PSC1_CHURCH_RESULT '
            records = [json.loads(line[len(marker):]) for line in text.splitlines() if line.startswith(marker)]
            require(len(records) == 1, 'Single actual result envelope: ' + label)
            result = records[0]
            require(result['verdict'] == 'resource_exhausted', 'Retain actual historical exhaustion: ' + label)
            reason = result['reason']
            if label == 'generated-baseline': reason = json.loads(reason)['message']
            results[label] = {'verdict': result['verdict'], 'reason': reason, 'stdout': digest(text.encode())}
            if mode == 'stages':
                trace = [json.loads(line[len('PSC1_CHURCH_STAGE '):]) for line in text.splitlines() if line.startswith('PSC1_CHURCH_STAGE ')]
                order = ['header', 'is-prop', 'body-static', 'body-check', 'final-defeq']
                require(trace and [row['stage'] for row in trace] == order[:len(trace)]
                        and all(row['status'] == 'ok' for row in trace[:-1]) and trace[-1]['status'] == 'error', 'Ordered first failing production stage')
                stages[runtime] = trace
                prefix, = [json.loads(line[len('PSC1_CHURCH_PREFIX '):]) for line in text.splitlines() if line.startswith('PSC1_CHURCH_PREFIX ')]
                prefixes[runtime] = {k: str(v) for k,v in prefix.items()}
    require(len({row['reason'] for row in results.values()}) == 1, 'Native/generated staged/original exact diagnostic equality')
    require(stages['native'][-1]['stage'] == stages['generated'][-1]['stage'], 'Same first failing native/generated stage')
    require(prefixes['native'] == prefixes['generated'], 'Same actual admitted prefix and owned arena sizes')
    report = {'schema': 'psc1-church-stage-diagnosis-v1', 'sourceSha': os.environ['GITHUB_SHA'],
        'runId': os.environ['GITHUB_RUN_ID'], 'runAttempt': os.environ['GITHUB_RUN_ATTEMPT'],
        'status': 'pass', 'inputSha256': INPUT_SHA, 'bodySha256': BODY_SHA,
        'fuel': 4096, 'processLimitSeconds': 60, 'generatedOldSpaceMiB': 2048,
        'results': results, 'stages': stages, 'prefixes': prefixes,
        'firstFailingStage': stages['native'][-1]['stage'], 'optimizationAdopted': False,
        'fullKernel': False, 'performanceQualified': False}
    write(out / 'report.json', report)
    print('PSC1_CHURCH_STAGE_DIAGNOSIS: PASS ' + json.dumps(report,separators=(',',':')))


if __name__ == '__main__':
    require(os.environ.get('GITHUB_ACTIONS') == 'true' and os.environ.get('RUNNER_OS') == 'Linux', 'GitHub Linux only')
    parser = argparse.ArgumentParser(); parser.add_argument('command', choices=['prepare','execute'])
    parser.add_argument('--out', type=pathlib.Path, required=True); parser.add_argument('--archive', type=pathlib.Path)
    parser.add_argument('--node'); parser.add_argument('--native'); args = parser.parse_args()
    if args.command == 'prepare': prepare(args.out.resolve(), args.archive.resolve())
    else: execute(args.out.resolve(), args.node, args.native)
