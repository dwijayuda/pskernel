#!/usr/bin/env python3
"""Reproduce the migrated compiler's binder-module crash with exact artifacts."""
from pathlib import Path
import hashlib
import json
import os
import shutil
import subprocess

ROOT = Path.cwd()
WORK = ROOT / 'build' / ('binder-self-debug-' + os.environ['GITHUB_RUN_ID'])
WORK.mkdir(parents=True, exist_ok=False)
stage = Path(os.environ['GITHUB_WORKSPACE']) / 'stage-one'
driver = stage / 'migrated-ps0'
driver.chmod(0o755)
baseline = json.loads((stage / 'migration.json').read_text())
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
assert sha(driver) == baseline['driver_sha256']
assert baseline['source_commit'] == os.environ['PS0_SOURCE_SHA']
sdk = Path(subprocess.check_output(['lean', '--print-prefix'], text=True).strip())
source = WORK / 'src'

def run(args, label, env=None):
    r = subprocess.run([str(x) for x in args], text=True, stdout=subprocess.PIPE,
                       stderr=subprocess.STDOUT, env=env, timeout=600)
    (WORK / (label + '.log')).write_text(r.stdout)
    print(label + ': exit=' + str(r.returncode), flush=True)
    print(r.stdout, end='', flush=True)
    return r

for module in ['HostCategories', 'Binders']:
    target = source / 'PS0' / (module + '.ps')
    r = run(['lake', 'exe', 'ps0', 'convert-native', ROOT / 'PS0' / (module + '.lean'), target], 'convert-' + module)
    assert r.returncode == 0

def build(compiler, label):
    out = WORK / label
    shutil.copytree(sdk / 'include', out / 'include')
    command = ['lake', '-R', '-f', 'lakefile.project.lean', '-KsourceRoot=' + str(source),
               '-Kroots=PS0,DebugMain', '-KrootModule=DebugMain',
               '-KmoduleNames=PS0.HostCategories,PS0.Binders', '-Kbootstrap=true',
               '-Kdriver=' + str(compiler), '-KprojectBuildDir=' + str(out), 'build', 'PS0.Binders']
    return out, run(command, label)

sdk_driver = ROOT / '.lake/build/bin/ps0'
sdk_out, sdk_result = build(sdk_driver, 'sdk-driver')
assert sdk_result.returncode == 0
migrated_out, migrated_result = build(driver, 'migrated-default')
setup_path = migrated_out / 'ir/PS0/Binders.setup.json'
assert setup_path.is_file(), migrated_result.stdout
setup = json.loads(setup_path.read_text())
false_setup = WORK / 'interpreted.setup.json'
options = setup.setdefault('options', {})
assert isinstance(options, dict), options
options['interpreter.prefer_native'] = False
false_setup.write_text(json.dumps(setup))
env = {**os.environ, 'LEAN_SYSROOT': str(sdk),
       'LEAN_PATH': os.pathsep.join([str(migrated_out / 'lib/lean'), str(ROOT / '.lake/build/lib/lean')])}

def invocation(label, setup_file):
    out = WORK / label
    out.mkdir()
    return [driver, source / 'PS0/Binders.ps', '--setup', setup_file,
            '-o', out / 'Binders.olean', '-i', out / 'Binders.ilean', '-c', out / 'Binders.c', '--json']

gdb = run(['gdb', '--batch', '-ex', 'set pagination off', '-ex', 'run', '-ex', 'bt 40',
           '--args', *invocation('gdb-default', setup_path)], 'gdb', env)
interpreted = run(invocation('interpreted', false_setup), 'interpreted', env)
comparison = {}
for suffix, original in [('c', sdk_out / 'ir/PS0/Binders.c'),
                         ('olean', sdk_out / 'lib/lean/PS0/Binders.olean')]:
    target = WORK / 'interpreted' / ('Binders.' + suffix)
    comparison[suffix] = sha(original) == sha(target) if original.exists() and target.exists() else None
result = {
    'source': os.environ['PS0_SOURCE_SHA'], 'artifact_run': 42511359592,
    'driver_sha256': sha(driver), 'sdk_driver_exit': sdk_result.returncode,
    'migrated_driver_exit': migrated_result.returncode,
    'interpreted_exit': interpreted.returncode, 'interpreted_matches_sdk': comparison,
    'gdb_signal': 'Program received signal' in gdb.stdout,
    'binders_source_sha256': sha(ROOT / 'PS0/Binders.lean'),
    'scope': 'focused diagnosis; not a compiler fixed-point qualification',
}
(WORK / 'diagnostic.json').write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps(result, indent=2), flush=True)
print('PS0_BINDER_SELF_REBUILD_DIAGNOSTIC: recorded', flush=True)
