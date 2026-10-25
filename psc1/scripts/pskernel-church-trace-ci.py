"""Ephemeral native-only trace of unchanged equality and WHNF outcomes."""
import argparse
import ast
import importlib.util
import json
import os
import pathlib
import subprocess

ROOT = pathlib.Path(__file__).resolve().parents[1]
CORE = ROOT / 'packages/pskernel-core/src/Ps/KernelCore/Checker/ExprV2'
HELPER = '''
private def psKernelChurchTraceRoot (state : PsKernelExprV2CheckState) (root : Nat) : String :=
  match psKernelExprV2PagedRequire state.whnf.arena root with
  | .error error => error
  | .ok entry =>
      let tag := match entry.node with
        | .app fn arg => s!"app({fn},{arg})"
        | .lam _ type body _ => s!"lam({type},{body})"
        | .forallE _ type body _ => s!"forall({type},{body})"
        | .fvar _ => "fvar"
        | .bvar index => s!"bvar({index})"
        | .const _ _ => "const"
        | .sort _ => "sort"
        | _ => "other"
      s!"{root}:{tag}:depth={entry.depth}:open={entry.hasFVar}"

@[noinline] private def psKernelChurchTrace {α : Type} (enabled : Bool)
    (message : Unit → String) (next : Unit → α) : α :=
  if enabled then
    dbg_trace message ()
    next ()
  else next ()

'''

def instrument(out):
    out.mkdir(parents=True, exist_ok=False)
    for name in ['DefEq.lean', 'WhnfOwned.lean']:
        path = CORE / name
        original = path.read_text()
        (out / (name + '.original')).write_text(original)
        # Helpers follow imports and precede declarations.
        lines = original.splitlines(keepends=True)
        last_import = max(i for i,line in enumerate(lines) if line.startswith('import '))
        lines.insert(last_import + 1, HELPER)
        modified = ''.join(lines)
        if name == 'WhnfOwned.lean':
            anchor = '        Option.some (Except.error "kernel reduction budget exhausted")'
            assert modified.count(anchor) == 2
            replacements = iter(['core-whnf-zero', 'public-whnf-zero'])
            modified = modified.replace(anchor, 'TRACE_ZERO_ANCHOR')
            for label in replacements:
                replacement = '        dbg_trace s!"PSC1_CHURCH_TRACE ' + label + ' arena={_state.whnf.arena.size} root={psKernelChurchTraceRoot _state _root}";\n' + anchor
                modified = modified.replace('TRACE_ZERO_ANCHOR', replacement, 1)
        else:
            start = modified.index('        let smaller :=')
            end = modified.index('\n/- Public helper', start)
            body = modified[start:end].rstrip('\n')
            wrapped = ('        psKernelChurchTrace (Nat.beq (Nat.mod remaining 256) 0)\n'
                '          (fun _ => s!"PSC1_CHURCH_TRACE defeq fuel={fuel} arena={state.whnf.arena.size} left={psKernelChurchTraceRoot state left} right={psKernelChurchTraceRoot state right}")\n'
                '          (fun _ =>\n' + '\n'.join('    ' + line for line in body.splitlines()) + ')\n')
            modified = modified[:start] + wrapped + modified[end:]
        path.write_text(modified)
        (out / (name + '.instrumented')).write_text(modified)
    subprocess.run(['git','diff','--','packages/pskernel-core/src'], cwd=ROOT, stdout=(out/'instrumentation.diff').open('w'), check=True)

def execute(out, native):
    spec = importlib.util.spec_from_file_location('church_ci', ROOT / 'scripts/pskernel-church-stage-ci.py')
    ci = importlib.util.module_from_spec(spec); spec.loader.exec_module(ci)
    try:
        text = ci.bounded(out, 'native-traced', [native, 'stages'], out, dict(os.environ, PATH='', NODE_OPTIONS=''))
        rows = [json.loads(line.split(' ',1)[1]) for line in text.splitlines() if line.startswith('PSC1_CHURCH_RESULT ')]
        assert len(rows) == 1 and rows[0]['verdict'] == 'resource_exhausted' and rows[0]['reason'] == 'kernel reduction budget exhausted'
        trace = (out / 'native-traced.stderr').read_text()
        assert 'PSC1_CHURCH_TRACE' in trace and '-whnf-zero' in trace
        baseline = json.loads((out.parent/'report.json').read_text())
        stages = [json.loads(line.split(' ',1)[1]) for line in text.splitlines() if line.startswith('PSC1_CHURCH_STAGE ')]
        assert [(x['stage'],x['status']) for x in stages] == [(x['stage'],x['status']) for x in baseline['stages']['native']]
        prefix = [json.loads(line.split(' ',1)[1]) for line in text.splitlines() if line.startswith('PSC1_CHURCH_PREFIX ')]
        assert len(prefix) == 1 and {k:str(v) for k,v in prefix[0].items()} == baseline['prefixes']['native']
        files = []
        for name in ['DefEq.lean','WhnfOwned.lean']:
            files.append({'path':str((CORE/name).relative_to(ROOT)),
                'original':ci.digest((out/(name+'.original')).read_bytes()),
                'instrumented':ci.digest((out/(name+'.instrumented')).read_bytes())})
        ci.write(out/'trace-report.json', {'sourceSha':os.environ['GITHUB_SHA'], 'runId':os.environ['GITHUB_RUN_ID'],
            'status':'pass','diagnosticOnly':True,'unchangedFuel':4096,'unchangedProcessLimitSeconds':60,
            'originalOutcomePreserved':True,'originalStagesPreserved':True,'originalPrefixPreserved':True,
            'result':rows[0],'sourceFiles':files,'trace':ci.digest(trace.encode())})
        print(trace)
    finally:
        for name in ['DefEq.lean','WhnfOwned.lean']:
            (CORE/name).write_bytes((out/(name+'.original')).read_bytes())
        subprocess.run(['git','diff','--exit-code','--','packages/pskernel-core/src'],cwd=ROOT,check=True)

if __name__ == '__main__':
    assert os.environ.get('GITHUB_ACTIONS') == 'true' and os.environ.get('RUNNER_OS') == 'Linux'
    parser = argparse.ArgumentParser()
    parser.add_argument('command',choices=['instrument','execute']); parser.add_argument('--out',type=pathlib.Path,required=True)
    parser.add_argument('--native'); args = parser.parse_args()
    if args.command == 'instrument': instrument(args.out.resolve())
    else: execute(args.out.resolve(),args.native)
