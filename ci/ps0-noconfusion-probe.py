#!/usr/bin/env python3
# Copyright (c) 2026 Dwijayuda. All rights reserved.
# Released under Apache 2.0 license as described in the file LICENSE.
"""Profile one unresolved PS module in the exact retained Lake graph."""
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import time

from compiler_build_checkpoint import graph_run_id, verify

root = Path.cwd()
driver = root / '.lake/build/bin/ps0'
evidence = root / 'build/noconfusion-probe'
evidence.mkdir(parents=True, exist_ok=True)
checkpoint = verify(root, root / 'build/compiler-checkpoint.json', source='b75a583592dc8bbe9046fd6e93784d8ef0365580',
                    phase='compiler', run_id='43039426271', driver=driver)
state = checkpoint['state']
assert state['compiler_part'] == 'early'
assert graph_run_id(state) == '42885813901'
work = root / state['work']
module = 'Lean.Meta.Constructions.NoConfusion'
target = work / 'src/Lean/Meta/Constructions/NoConfusion.ps'
build = work / 'artifacts'
inventory = json.loads((root / 'build/compiler-evidence/input-inventory.json').read_text())['inputs']
assert len(inventory) == 2569 and inventory[module]['ps'] == str(target)
shutil.copy2(target, evidence / target.name)
original = Path(subprocess.check_output(['lean', '--print-prefix'], text=True).strip()) / 'src/lean/Lean/Meta/Constructions/NoConfusion.lean'
baseline_start = time.monotonic()
baseline = subprocess.run(['timeout', '120', 'lean', str(original)],
                          stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
(evidence / 'native-sdk.log').write_text(baseline.stdout)
print('PS0_NOCONFUSION_NATIVE_SDK', baseline.returncode, round(time.monotonic() - baseline_start, 2), flush=True)
command = ['lake', '-R', '-f', 'lakefile.project.lean', '-KsourceRoot=' + str(work / 'src'),
           '-Kbootstrap=true', '-KsourceGrammar=true',
           '-Kroots=Init,Std,Lean,Lake,LeanChecker,LeanExport,LeanIR,Leanc,LakeMain,PS0,PS0Main',
           '-KrootModule=PS0Main', '-Kdriver=' + str(driver), '-KmoduleNames=' + ','.join(sorted(inventory)),
           '-KlinkMap=' + str(root / 'build/compiler-evidence/compiler-link.map'),
           '-KprojectBuildDir=' + str(build), 'build', '+' + module + ':c.o']


def target_pids():
    for command_line in Path('/proc').glob('[0-9]*/cmdline'):
        try:
            args = command_line.read_bytes().split(b'\0')
        except (FileNotFoundError, ProcessLookupError, PermissionError):
            continue
        if args and args[0] == os.fsencode(driver) and os.fsencode(target) in args and b'--setup' in args:
            yield command_line.parent.name


def candidate_check(pid):
    candidate = Path(os.environ['PS0_PARSER_CANDIDATE'])
    setup = build / 'ir/Lean/Meta/Constructions/NoConfusion.setup.json'
    assert setup.is_file(), setup
    command_environment = dict(os.environ)
    for item in (Path('/proc') / pid / 'environ').read_bytes().split(b'\0'):
        key, separator, value = item.partition(b'=')
        if separator and key in [b'LEAN_PATH', b'LEAN_SYSROOT', b'LEAN_SRC_PATH']:
            command_environment[os.fsdecode(key)] = os.fsdecode(value)
    raw = original.read_bytes()
    ps_lines = target.read_bytes().splitlines(keepends=True)
    plan = json.loads((root / 'build/compiler-evidence/current-source-plans' / module / 'plan.json').read_text())
    assert len(raw.splitlines()) == len(ps_lines) and plan['line_count_preserved']
    starts = [(raw[:d['keywordRange']['start']].count(b'\n'), d['sourceName']) for d in plan['strategies']]
    assert starts[0] == (28, 'mkNoConfusionCtorArg') and starts[1][0] == 52
    prefix = evidence / 'prefix.ps'
    prefix.write_bytes(b''.join(ps_lines[:starts[1][0]]))
    outputs = {'-o': evidence / 'NoConfusion.olean', '-i': evidence / 'NoConfusion.ilean', '-c': evidence / 'NoConfusion.c'}
    checks = [('prefix', prefix, 18, []),
              ('module', target, 240, [str(item) for pair in outputs.items() for item in pair])]
    for label, source, seconds, options in checks:
        started = time.monotonic()
        result = subprocess.run(['timeout', '--kill-after=3', str(seconds), str(candidate), str(source),
                                 '--setup', str(setup), '--json', *options], env=command_environment,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        (evidence / (label + '.log')).write_text(result.stdout)
        print('PS0_NOCONFUSION_CANDIDATE', label, result.returncode, round(time.monotonic() - started, 2), flush=True)
        if result.returncode:
            print(result.stdout[-16000:], flush=True)
            result.check_returncode()
    for output in outputs.values():
        assert output.stat().st_size > 0, output
    shutil.copy2(setup, evidence / setup.name)
    subprocess.run(['sha256sum', str(candidate), str(target), *(str(output) for output in outputs.values())], check=True)

print('PS0_NOCONFUSION_PROBE_START', module, 'verified_files', len(checkpoint['files']), flush=True)
with (evidence / 'lake.log').open('w') as log:
    process = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
    try:
        for _ in range(90):
            if process.poll() is not None:
                raise RuntimeError('Original Lake process finished before the candidate diagnosis: ' + str(process.returncode))
            pids = list(target_pids())
            if pids:
                candidate_check(pids[0])
                break
            time.sleep(2)
        else:
            raise RuntimeError('NoConfusion module process did not start')
    finally:
        if process.poll() is None:
            os.killpg(process.pid, signal.SIGTERM)
            try:
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait()
