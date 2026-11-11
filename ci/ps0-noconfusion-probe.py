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


print('PS0_NOCONFUSION_PROBE_START', module, 'verified_files', len(checkpoint['files']), flush=True)
start = time.monotonic()
samples = []
with (evidence / 'lake.log').open('w') as log:
    process = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
    try:
        for _ in range(8):
            try:
                process.wait(timeout=30)
                break
            except subprocess.TimeoutExpired:
                pids = list(target_pids())
                sample = {'elapsed_seconds': int(time.monotonic() - start), 'target_processes': pids}
                samples.append(sample)
                print('PS0_NOCONFUSION_PROBE_SAMPLE', json.dumps(sample), flush=True)
                if pids and shutil.which('gdb') and len(samples) in [2, 4, 8]:
                    for pid in pids:
                        result = subprocess.run(['sudo', '-n', 'timeout', '30', 'gdb', '-nx', '-batch',
                            '-ex', 'set pagination off', '-ex', 'thread apply all bt 45', '-p', pid],
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
                        (evidence / ('stack-' + str(len(samples)) + '-' + pid + '.log')).write_text(result.stdout)
                        print('PS0_NOCONFUSION_STACK', pid, result.returncode, flush=True)
                        relevant = [line for line in result.stdout.splitlines() if any(s in line for s in ('PS0', 'Parser', 'Elab', 'Compiler', 'futex', 'wait'))]
                        print('\n'.join(relevant[-120:]), flush=True)
    finally:
        if process.poll() is None:
            os.killpg(process.pid, signal.SIGTERM)
            try:
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait()
status = {'schema': 'ps0-noconfusion-exact-lake-probe/1', 'module': module,
          'source': 'b75a583592dc8bbe9046fd6e93784d8ef0365580', 'checkpoint_artifact': 13870203959,
          'native_sdk_exit': baseline.returncode, 'lake_exit': process.returncode,
          'elapsed_seconds': int(time.monotonic() - start), 'samples': samples}
(evidence / 'probe.json').write_text(json.dumps(status, indent=2) + '\n')
print('PS0_NOCONFUSION_PROBE_RESULT', json.dumps(status), flush=True)
print((evidence / 'lake.log').read_text()[-10000:], flush=True)
raise SystemExit(0 if process.returncode == 0 else 1)
