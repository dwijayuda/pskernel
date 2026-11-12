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
frontend = plans / 'PS0.LakeFrontend'
native = json.loads((frontend / 'native-census.json').read_text())
compile_choices = [c for c in native['commands'] if (c.get('declaration') or {}).get('sourceName') == 'compile']
assert len(compile_choices) == 1 and compile_choices[0]['kind'] == 'choice', compile_choices
original = (frontend / 'original.ps').read_text().splitlines()
generated = files['PS0.LakeFrontend'].read_text().splitlines()
assert len(original) == len(generated) and original[242].strip() == '| [] => pure ()'
assert generated[242].strip() == '| [] => pure(())', generated[242]
print('PS0_SELF_GRAMMAR_NATIVE_CHOICE', compile_choices[0]['kind'], generated[242].strip(), flush=True)
sysroot = Path(subprocess.check_output(['lean', '--print-prefix'], text=True).strip())
shutil.copytree(sysroot / 'include', compiled / 'include')
first_driver = compiled / 'bin/ps0project'
second = work / 'ps-built-stage-two'
outputs = {}
productions = {'function': 'PS0.StandardAdapters.ps0StandardFunction',
               'const': 'PS0.StandardAdapters.ps0StandardConst',
               'def': 'PS0.StandardAdapters.ps0StandardDef'}


def commands(census):
    for command in census:
        yield command
        yield from commands(command.get('nestedCommands', []))


def validate_outputs(build, label):
    outputs = {}
    for module, target in files.items():
        rel = Path(*module.split('.'))
        setup = json.loads((build / 'ir' / rel.with_suffix('.setup.json')).read_text())
        assert setup['options']['ps0.sourceGrammar'] is True
        assert setup['options']['interpreter.prefer_native'] is False
        olean = build / 'lib/lean' / rel.with_suffix('.olean')
        cfile = build / 'ir' / rel.with_suffix('.c')
        census = build / 'lib/lean' / rel.with_suffix('.ilean.ps0-source-census.json')
        observed = list(commands(json.loads(census.read_text())['commands']))
        plan = json.loads((plans / module / 'plan.json').read_text())
        declarations = [row['declaration'] for row in observed if row['declaration'] is not None]
        definitions = [row for row in declarations
                       if row['production'] in set(productions.values()) | {'Lean.Parser.Command.definition'}]
        expected = [(row['sourceName'], productions[row['targetKeyword']], 'mapped-ps') for row in plan['strategies']]
        assert [(row['sourceName'], row['production'], row['mode']) for row in definitions] == expected, module
        assert all(row['mode'] != 'native-compatible' for row in declarations), module
        for field, count in [('dataDeclaration', 'data_declarations'), ('initialization', 'initialization_commands')]:
            captures = [row[field] for row in observed if row.get(field) is not None]
            assert len(captures) == plan.get(count, 0) and all(row['mode'] == 'mapped-ps' for row in captures), (module, field)
        outputs[module] = dict(source=sha(target), c=sha(cfile), olean=sha(olean), census=sha(census),
                               definitions=len(definitions), data=plan.get('data_declarations', 0),
                               initializers=plan.get('initialization_commands', 0))
    (report / (label + '-outputs.json')).write_text(json.dumps(outputs, indent=2) + '\n')
    return outputs


run([*lake, '-KsourceGrammar=true', '-KprojectBuildDir=' + str(compiled), 'build', 'PS0Project:static', 'ps0project'])
outputs['first'] = validate_outputs(compiled, 'first')
print('PS0_SELF_GRAMMAR_FIRST: PASS', len(outputs['first']), sha(first_driver), flush=True)
run(['python3', 'tests/run-relocated-grammar.py'], env={
    **os.environ, 'PS0_PACKAGE_DRIVER': str(first_driver),
    'PS0_PACKAGE_METADATA': str(compiled / 'lib/lean'), 'PS0_PACKAGE_TAG': '-self-grammar-first',
})
verified_prefix = root / 'build' / ('relocated-grammar-' + os.environ['GITHUB_RUN_ID'] + '-self-grammar-first') / 'prefix'
ps_built_driver = verified_prefix / 'bin/ps0'
assert sha(ps_built_driver) == sha(first_driver)
probe = report / 'binders-census-reproduction'
probe.mkdir()
original = plans / 'PS0.Binders' / 'original.ps'
interpreted = probe / 'interpreted.ps'
text = original.read_text()
marker = 'public meta section\n'
assert text.count(marker) == 1
interpreted.write_text(text.replace(marker, 'set_option interpreter.prefer_native false\n' + marker))
self_env = {**os.environ, 'LEAN_PATH': str(verified_prefix / 'lib/lean')}
for label, candidate in [('exact', original), ('interpret-current-stage', interpreted)]:
    command = [str(ps_built_driver), 'census-source', str(candidate), 'PS0.Binders', str(probe / (label + '.json'))]
    completed = subprocess.run(['timeout', '--kill-after=5', '60', *command], env=self_env,
                               stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    (probe / (label + '.log')).write_text(completed.stdout)
    print('PS0_SELF_CENSUS_DIAGNOSIS', label, completed.returncode, completed.stdout[-4000:], flush=True)
    if completed.returncode:
        debug = subprocess.run(['timeout', '--kill-after=5', '90', 'gdb', '-q', '-batch',
                                '-ex', 'set pagination off', '-ex', 'run', '-ex', 'bt 45', '--args', *command],
                               env=self_env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        (probe / (label + '-gdb.log')).write_text(debug.stdout)
        print(debug.stdout[-16000:], flush=True)
