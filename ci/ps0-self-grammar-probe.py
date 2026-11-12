#!/usr/bin/env python3
# Copyright (c) 2026 Dwijayuda. All rights reserved.
# Released under Apache 2.0 license as described in the file LICENSE.
"""Build the compiler's own PS0 modules from PS grammar against the pinned SDK."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess

root = Path.cwd()
work = root / 'build/self-grammar-probe'
work.mkdir(parents=True)
driver = root / '.lake/build/bin/ps0'
source = work / 'src'
native = work / 'native-metadata'
compiled = work / 'ps-built'
report = work / 'evidence'
report.mkdir()
plans = report / 'plans'
plans.mkdir()


def run(command, *, env=None):
    print('PS0_SELF_GRAMMAR_COMMAND', command, flush=True)
    subprocess.run(command, env=env, check=True)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


run([driver, 'convert-native-tree', root / 'PS0', source / 'PS0'])
for name in ['PS0', 'PS0Main']:
    run([driver, 'convert-native', root / (name + '.lean'), source / (name + '.ps')])
files = {'.'.join(p.relative_to(source).with_suffix('').parts): p for p in sorted(source.rglob('*.ps'))}
assert 'PS0.HostCategories' in files and 'PS0.SourceGrammar' in files and len(files) >= 19
lake = ['lake', '-R', '-f', 'lakefile.project.lean', '-KsourceRoot=' + str(source),
        '-Kbootstrap=true', '-Kroots=PS0,PS0Main', '-KrootModule=PS0Main', '-Kdriver=' + str(driver),
        '-KmoduleNames=' + ','.join(sorted(files))]
run([*lake, '-KprojectBuildDir=' + str(native), 'build', 'PS0Project'])
self_env = {**os.environ, 'LEAN_PATH': str(native / 'lib/lean')}
for module, target in files.items():
    module_plan = plans / module
    module_plan.mkdir()
    original, census, plan = [module_plan / file for file in ['original.ps', 'native-census.json', 'plan.json']]
    shutil.copy2(target, original)
    run([driver, 'census-source', original, module, census], env=self_env)
    run(['python3', 'tests/migrate-compiler-heads.py', census, original, target, '--plan', plan, '--allow-empty'])
    planned = json.loads(plan.read_text())
    assert planned['line_count_preserved'] and planned['result_sha256'] == sha(target)
    shutil.copy2(target, module_plan / 'converted.ps')
assert not list(source.rglob('*.lean'))
run([*lake, '-KsourceGrammar=true', '-KprojectBuildDir=' + str(compiled), 'build', 'PS0Project:static', 'ps0project'])
outputs = {}
for module, target in files.items():
    rel = Path(*module.split('.'))
    setup = json.loads((compiled / 'ir' / rel.with_suffix('.setup.json')).read_text())
    assert setup['options']['ps0.sourceGrammar'] is True and setup['options']['interpreter.prefer_native'] is False
    olean = compiled / 'lib/lean' / rel.with_suffix('.olean')
    cfile = compiled / 'ir' / rel.with_suffix('.c')
    census = compiled / 'lib/lean' / rel.with_suffix('.ilean.ps0-source-census.json')
    assert olean.is_file() and cfile.is_file() and census.is_file()
    outputs[module] = dict(source=sha(target), c=sha(cfile), olean=sha(olean), census=sha(census))
run(['python3', 'tests/run-relocated-grammar.py'], env={
    **os.environ, 'PS0_PACKAGE_DRIVER': str(compiled / 'bin/ps0project'),
    'PS0_PACKAGE_METADATA': str(compiled / 'lib/lean'), 'PS0_PACKAGE_TAG': '-self-grammar',
})
(report / 'qualification.json').write_text(json.dumps({
    'source': os.environ['PS0_SOURCE_SHA'], 'modules': outputs,
    'linked_driver_sha256': sha(compiled / 'bin/ps0project'),
    'scope': 'PS0-owned sources under PS grammar using pinned native SDK dependencies',
}, indent=2) + '\n')
print('PS0_SELF_GRAMMAR: PASS', len(outputs), flush=True)
