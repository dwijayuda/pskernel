"""Bounded native prototype; leaves tracked production sources unchanged."""
import argparse
import importlib.util
import json
import os
import pathlib
import subprocess

ROOT = pathlib.Path(__file__).resolve().parents[1]
PATH = ROOT / 'packages/pskernel-core/src/Ps/KernelCore/Checker/ExprV2/DefEq/FullShape.lean'
MODULE = "import Ps.KernelCore.Checker.ExprV2.CheckState\n\n/- A read-only structural plan for equal unary free-variable heads.\n   No semantic cache, local binding, reduction callback, or arena is changed. -/\nstructure PsKernelExprV2UnarySpinePlan where\n  left : Nat\n  right : Nat\n  skipped : Nat\n\ndef psKernelExprV2UnarySpineView\n    (arena : PsKernelExprV2PagedArena) (left right : Nat) : Option (Nat × Nat) :=\n  match psKernelExprV2PagedFind arena left, psKernelExprV2PagedFind arena right with\n  | some l, some r =>\n      match l.node, r.node with\n      | .app lf la, .app rf ra =>\n          if Nat.beq lf rf then\n            match psKernelExprV2PagedFind arena lf with\n            | some head =>\n                match head.node with\n                | .fvar _ => some (la, ra)\n                | _ => none\n            | none => none\n          else none\n      | _, _ => none\n  | _, _ => none\n\ndef psKernelExprV2UnarySpinePlanWithFuel (fuel : Nat)\n    (arena : PsKernelExprV2PagedArena) (left right : Nat) :\n    Option PsKernelExprV2UnarySpinePlan :=\n  match fuel with\n  | 0 => none\n  | remaining + 1 =>\n      match psKernelExprV2UnarySpineView arena left right with\n      | none => some ⟨left, right, 0⟩\n      | some (la, ra) =>\n          match psKernelExprV2UnarySpinePlanWithFuel remaining arena la ra with\n          | none => none\n          | some plan => some ⟨plan.left, plan.right, plan.skipped + 1⟩\n\ndef psKernelExprV2UnarySpineContext (count : Nat)\n    (context : PsKernelExprV2CheckContext) : Except String PsKernelExprV2CheckContext :=\n  match count with\n  | 0 => .ok context\n  | remaining + 1 =>\n      match psKernelExprV2CheckContextEnterRecDepth context with\n      | .error error => .error error\n      | .ok next => psKernelExprV2UnarySpineContext remaining next\n\ndef psKernelExprV2TryUnarySpineWith\n    (defeq : PsKernelExprV2CheckContext → PsKernelExprV2CheckState → Nat → Nat →\n      Option (Except String (PsKernelExprV2CheckState × Bool)))\n    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)\n    (left right : Nat) : Option (Except String (PsKernelExprV2CheckState × Bool)) :=\n  match psKernelExprV2PagedFind state.whnf.arena left, psKernelExprV2PagedFind state.whnf.arena right with\n  | some l, some r =>\n      match psKernelExprV2UnarySpinePlanWithFuel (Nat.succ (Nat.add l.depth r.depth))\n          state.whnf.arena left right with\n      | none => none\n      | some plan =>\n          if Nat.ble 2 plan.skipped then\n            match psKernelExprV2UnarySpineContext (Nat.sub plan.skipped 1) context with\n            | .error _ => none\n            | .ok next => defeq next state plan.left plan.right\n          else none\n  | _, _ => none\n"
WRAPPER = """
def psKernelExprV2DefEqFullShapeAppWith
    (defeq : PsKernelExprV2CheckContext -> PsKernelExprV2CheckState -> Nat -> Nat ->
      Option (Except String (Prod PsKernelExprV2CheckState Bool)))
    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)
    (left right : Nat) :
    Option (Except String (Prod PsKernelExprV2CheckState Bool)) :=
  match psKernelExprV2TryUnarySpineWith defeq context state left right with
  | some (.ok (next, true)) => some (.ok (next, true))
  | _ => psKernelExprV2DefEqFullShapeAppOriginalWith defeq context state left right

"""

def instrument(out):
    out.mkdir(parents=True,exist_ok=False)
    original=PATH.read_text(); (out/'FullShape.lean.original').write_text(original)
    helper=MODULE.partition('\n')[2]
    anchor='def psKernelExprV2DefEqFullShapeAppWith\n'
    assert original.count(anchor)==1
    modified=original.replace(anchor,helper+'\ndef psKernelExprV2DefEqFullShapeAppOriginalWith\n',1)
    anchor='def psKernelExprV2DefEqFullShapeEtaOwnedWith\n'
    assert modified.count(anchor)==1
    modified=modified.replace(anchor,WRAPPER+anchor,1)
    PATH.write_text(modified); (out/'FullShape.lean.candidate').write_text(modified)
    subprocess.run(['git','diff','--','packages/pskernel-core/src'],cwd=ROOT,stdout=(out/'candidate.diff').open('w'),check=True)

def execute(out,native):
    spec=importlib.util.spec_from_file_location('ci',ROOT/'scripts/pskernel-church-stage-ci.py')
    ci=importlib.util.module_from_spec(spec); spec.loader.exec_module(ci)
    try:
        results={}
        for mode in ['baseline','stages']:
            text=ci.bounded(out,'candidate-native-'+mode,[native,mode],out,dict(os.environ,PATH='',NODE_OPTIONS=''))
            rows=[json.loads(line.split(' ',1)[1]) for line in text.splitlines() if line.startswith('PSC1_CHURCH_RESULT ')]
            assert len(rows)==1 and rows[0]['verdict']=='accepted' and rows[0]['fuel']==4096
            results[mode]=rows[0]
            if mode=='stages':
                stages=[json.loads(line.split(' ',1)[1]) for line in text.splitlines() if line.startswith('PSC1_CHURCH_STAGE ')]
                assert [x['stage'] for x in stages]==['header','is-prop','body-static','body-check','final-defeq']
                assert all(x['status']=='ok' for x in stages)
                prefix=[json.loads(line.split(' ',1)[1]) for line in text.splitlines() if line.startswith('PSC1_CHURCH_PREFIX ')]
                baseline=json.loads((out.parent/'report.json').read_text())
                assert len(prefix)==1 and {k:str(v) for k,v in prefix[0].items()}==baseline['prefixes']['native']
        ci.write(out/'candidate-report.json',{'schema':'psc1-unary-spine-native-prototype-v1',
            'sourceSha':os.environ['GITHUB_SHA'],'runId':os.environ['GITHUB_RUN_ID'],'status':'pass',
            'diagnosticOnly':True,'productionAdopted':False,'generatedQualified':False,'fuel':4096,
            'unchangedProcessLimitSeconds':60,'results':results,'stages':stages,
            'originalSource':ci.digest((out/'FullShape.lean.original').read_bytes()),
            'candidateSource':ci.digest((out/'FullShape.lean.candidate').read_bytes())})
        print('PSC1_UNARY_SPINE_NATIVE_PROTOTYPE: PASS '+json.dumps(results))
    finally:
        PATH.write_bytes((out/'FullShape.lean.original').read_bytes())
        subprocess.run(['git','diff','--exit-code','--','packages/pskernel-core/src'],cwd=ROOT,check=True)

if __name__=='__main__':
    assert os.environ.get('GITHUB_ACTIONS')=='true' and os.environ.get('RUNNER_OS')=='Linux'
    p=argparse.ArgumentParser();p.add_argument('command',choices=['instrument','execute']);p.add_argument('--out',type=pathlib.Path,required=True);p.add_argument('--native')
    args=p.parse_args()
    if args.command=='instrument':instrument(args.out.resolve())
    else:execute(args.out.resolve(),args.native)
