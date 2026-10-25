"""Bounded native prototype; leaves tracked production sources unchanged."""
import argparse
import importlib.util
import json
import os
import pathlib
import re
import subprocess

ROOT = pathlib.Path(__file__).resolve().parents[1]
PATH = ROOT / 'packages/pskernel-core/src/Ps/KernelCore/Checker/ExprV2/DefEq/FullShape.lean'
MODULE = "import Ps.KernelCore.Checker.ExprV2.CheckState\n\n/- A read-only structural plan for equal unary free-variable heads.\n   No semantic cache, local binding, reduction callback, or arena is changed. -/\nstructure PsKernelExprV2UnarySpinePlan where\n  left : Nat\n  right : Nat\n  skipped : Nat\n\ndef psKernelExprV2UnarySpineView\n    (arena : PsKernelExprV2PagedArena) (left right : Nat) : Option (Nat × Nat) :=\n  match psKernelExprV2PagedFind arena left, psKernelExprV2PagedFind arena right with\n  | some l, some r =>\n      match l.node, r.node with\n      | .app lf la, .app rf ra =>\n          if Nat.beq lf rf then\n            match psKernelExprV2PagedFind arena lf with\n            | some head =>\n                match head.node with\n                | .fvar _ => some (la, ra)\n                | _ => none\n            | none => none\n          else none\n      | _, _ => none\n  | _, _ => none\n\ndef psKernelExprV2UnarySpinePlanWithFuel (fuel : Nat)\n    (arena : PsKernelExprV2PagedArena) (left right : Nat) :\n    Option PsKernelExprV2UnarySpinePlan :=\n  match fuel with\n  | 0 => none\n  | remaining + 1 =>\n      match psKernelExprV2UnarySpineView arena left right with\n      | none => some ⟨left, right, 0⟩\n      | some (la, ra) =>\n          match psKernelExprV2UnarySpinePlanWithFuel remaining arena la ra with\n          | none => none\n          | some plan => some ⟨plan.left, plan.right, plan.skipped + 1⟩\n\ndef psKernelExprV2UnarySpineContext (count : Nat)\n    (context : PsKernelExprV2CheckContext) : Except String PsKernelExprV2CheckContext :=\n  match count with\n  | 0 => .ok context\n  | remaining + 1 =>\n      match psKernelExprV2CheckContextEnterRecDepth context with\n      | .error error => .error error\n      | .ok next => psKernelExprV2UnarySpineContext remaining next\n\ndef psKernelExprV2TryUnarySpineWith\n    (defeq : PsKernelExprV2CheckContext → PsKernelExprV2CheckState → Nat → Nat →\n      Option (Except String (PsKernelExprV2CheckState × Bool)))\n    (context : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)\n    (left right : Nat) : Option (Except String (PsKernelExprV2CheckState × Bool)) :=\n  match psKernelExprV2PagedFind state.whnf.arena left, psKernelExprV2PagedFind state.whnf.arena right with\n  | some l, some r =>\n      match psKernelExprV2UnarySpinePlanWithFuel (Nat.succ (Nat.add l.depth r.depth))\n          state.whnf.arena left right with\n      | none => none\n      | some plan =>\n          if Nat.ble 2 plan.skipped then\n            match psKernelExprV2UnarySpineContext (Nat.sub plan.skipped 1) context with\n            | .error _ => none\n            | .ok next => defeq next state plan.left plan.right\n          else none\n  | _, _ => none\n"
PROOFS = "import Lean\nimport PsKernelChurchSource\n\ntheorem psKernelUnaryPlanZero (arena : PsKernelExprV2PagedArena) (left right : Nat) :\n    psKernelExprV2UnarySpinePlanWithFuel 0 arena left right = none := rfl\n\ntheorem psKernelUnaryPlanStops (fuel : Nat) (arena : PsKernelExprV2PagedArena)\n    (left right : Nat) (h : psKernelExprV2UnarySpineView arena left right = none) :\n    psKernelExprV2UnarySpinePlanWithFuel (fuel + 1) arena left right =\n      some ⟨left, right, 0⟩ := by\n  simp [psKernelExprV2UnarySpinePlanWithFuel, h]\n\ntheorem psKernelUnaryPlanPreserves\n    (fuel : Nat) (arena : PsKernelExprV2PagedArena) (left right : Nat)\n    (plan : PsKernelExprV2UnarySpinePlan)\n    (found : psKernelExprV2UnarySpinePlanWithFuel fuel arena left right = some plan)\n    (R : Nat → Nat → Prop)\n    (congruence : ∀ l r la ra, psKernelExprV2UnarySpineView arena l r = some (la, ra) →\n      R la ra → R l r)\n    (residual : R plan.left plan.right) : R left right := by\n  induction fuel generalizing left right plan with\n  | zero => simp [psKernelExprV2UnarySpinePlanWithFuel] at found\n  | succ fuel ih =>\n      cases view : psKernelExprV2UnarySpineView arena left right with\n      | none =>\n          simp [psKernelExprV2UnarySpinePlanWithFuel, view] at found\n          cases found\n          exact residual\n      | some pair =>\n          rcases pair with ⟨la, ra⟩\n          cases tail : psKernelExprV2UnarySpinePlanWithFuel fuel arena la ra with\n          | none => simp [psKernelExprV2UnarySpinePlanWithFuel, view, tail] at found\n          | some next =>\n              simp [psKernelExprV2UnarySpinePlanWithFuel, view, tail] at found\n              cases found\n              exact congruence left right la ra view (ih la ra next tail residual)\n\ntheorem psKernelUnaryPlanSkippedBound\n    (fuel : Nat) (arena : PsKernelExprV2PagedArena) (left right : Nat)\n    (plan : PsKernelExprV2UnarySpinePlan)\n    (found : psKernelExprV2UnarySpinePlanWithFuel fuel arena left right = some plan) :\n    plan.skipped < fuel := by\n  induction fuel generalizing left right plan with\n  | zero => simp [psKernelExprV2UnarySpinePlanWithFuel] at found\n  | succ fuel ih =>\n      cases view : psKernelExprV2UnarySpineView arena left right with\n      | none =>\n          simp [psKernelExprV2UnarySpinePlanWithFuel, view] at found\n          cases found\n          exact Nat.zero_lt_succ fuel\n      | some pair =>\n          rcases pair with ⟨la, ra⟩\n          cases tail : psKernelExprV2UnarySpinePlanWithFuel fuel arena la ra with\n          | none => simp [psKernelExprV2UnarySpinePlanWithFuel, view, tail] at found\n          | some next =>\n              simp [psKernelExprV2UnarySpinePlanWithFuel, view, tail] at found\n              cases found\n              exact Nat.succ_lt_succ (ih la ra next tail)\n\ntheorem psKernelUnaryViewHasSharedHead\n    (arena : PsKernelExprV2PagedArena) (left right la ra : Nat)\n    (found : psKernelExprV2UnarySpineView arena left right = some (la, ra)) :\n    ∃ fn name,\n      (psKernelExprV2PagedFind arena left).map PsKernelExprV2Entry.node = some (.app fn la) ∧\n      (psKernelExprV2PagedFind arena right).map PsKernelExprV2Entry.node = some (.app fn ra) ∧\n      (psKernelExprV2PagedFind arena fn).map PsKernelExprV2Entry.node = some (.fvar name) := by\n  unfold psKernelExprV2UnarySpineView at found\n  repeat' (split at found <;> simp_all)\n\ntheorem psKernelUnaryPlanExpressionCongruence\n    (fuel : Nat) (arena : PsKernelExprV2PagedArena) (left right : Nat)\n    (plan : PsKernelExprV2UnarySpinePlan)\n    (found : psKernelExprV2UnarySpinePlanWithFuel fuel arena left right = some plan)\n    (meaning : Nat → PsKernelExpr) (R : PsKernelExpr → PsKernelExpr → Prop)\n    (apps : ∀ id fn arg,\n      (psKernelExprV2PagedFind arena id).map PsKernelExprV2Entry.node = some (.app fn arg) →\n      meaning id = .app (meaning fn) (meaning arg))\n    (congruence : ∀ fn a b, R a b → R (.app fn a) (.app fn b))\n    (residual : R (meaning plan.left) (meaning plan.right)) :\n    R (meaning left) (meaning right) := by\n  apply psKernelUnaryPlanPreserves fuel arena left right plan found\n    (fun l r => R (meaning l) (meaning r)) ?_ residual\n  intro l r la ra view hypothesis\n  obtain ⟨fn, name, hl, hr, _⟩ := psKernelUnaryViewHasSharedHead arena l r la ra view\n  rw [apps l fn la hl, apps r fn ra hr]\n  exact congruence (meaning fn) (meaning la) (meaning ra) hypothesis\n\ntheorem psKernelUnaryContextZero (context : PsKernelExprV2CheckContext) :\n    psKernelExprV2UnarySpineContext 0 context = .ok context := rfl\n\ntheorem psKernelUnaryPlanTerminates\n    (fuel : Nat) (arena : PsKernelExprV2PagedArena) (left right : Nat)\n    (rank : Nat → Nat)\n    (descends : ∀ l r la ra, psKernelExprV2UnarySpineView arena l r = some (la, ra) →\n      rank la + rank ra < rank l + rank r)\n    (bound : rank left + rank right < fuel) :\n    ∃ plan, psKernelExprV2UnarySpinePlanWithFuel fuel arena left right = some plan := by\n  induction fuel generalizing left right with\n  | zero => omega\n  | succ fuel ih =>\n      cases view : psKernelExprV2UnarySpineView arena left right with\n      | none =>\n          exact ⟨⟨left, right, 0⟩, by simp [psKernelExprV2UnarySpinePlanWithFuel, view]⟩\n      | some pair =>\n          rcases pair with ⟨la, ra⟩\n          have decrease := descends left right la ra view\n          have nextBound : rank la + rank ra < fuel := by omega\n          obtain ⟨plan, found⟩ := ih la ra nextBound\n          exact ⟨⟨plan.left, plan.right, plan.skipped + 1⟩,\n            by simp [psKernelExprV2UnarySpinePlanWithFuel, view, found]⟩\n\ntheorem psKernelUnaryCallbackOwner\n    (defeq : PsKernelExprV2CheckContext → PsKernelExprV2CheckState → Nat → Nat →\n      Option (Except String (PsKernelExprV2CheckState × Bool)))\n    (context next : PsKernelExprV2CheckContext) (state : PsKernelExprV2CheckState)\n    (left right : Nat) (l r : PsKernelExprV2Entry) (plan : PsKernelExprV2UnarySpinePlan)\n    (hl : psKernelExprV2PagedFind state.whnf.arena left = some l)\n    (hr : psKernelExprV2PagedFind state.whnf.arena right = some r)\n    (hp : psKernelExprV2UnarySpinePlanWithFuel (Nat.succ (Nat.add l.depth r.depth))\n      state.whnf.arena left right = some plan)\n    (hs : Nat.ble 2 plan.skipped = true)\n    (hc : psKernelExprV2UnarySpineContext (Nat.sub plan.skipped 1) context = .ok next) :\n    psKernelExprV2TryUnarySpineWith defeq context state left right =\n      defeq next state plan.left plan.right := by\n  simp [psKernelExprV2TryUnarySpineWith, hl, hr, hp, hs, hc]\n\n#print axioms psKernelUnaryPlanZero\n#print axioms psKernelUnaryPlanStops\n#print axioms psKernelUnaryPlanPreserves\n#print axioms psKernelUnaryPlanSkippedBound\n#print axioms psKernelUnaryViewHasSharedHead\n#print axioms psKernelUnaryPlanExpressionCongruence\n#print axioms psKernelUnaryContextZero\n#print axioms psKernelUnaryPlanTerminates\n#print axioms psKernelUnaryCallbackOwner\n"
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
    (out/'UnarySpineProofs.lean').write_text(PROOFS)
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
        proof_command=['lake','-f','.church-stage-lakefile.lean','env','lean',str(out/'UnarySpineProofs.lean')]
        with (out/'proof.log').open('w') as handle:
            status=subprocess.run(proof_command,cwd=ROOT,stdout=handle,stderr=subprocess.STDOUT).returncode
        proof_log=(out/'proof.log').read_text();print(proof_log,flush=True)
        assert status==0
        expected=re.findall(r'(?m)^#print axioms (\\S+)\\s*
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
,PROOFS)
        found=re.findall(r"'([^']+)' (?:depends on axioms:\\s*\\[([^\\]]*)\\]|does not depend on any axioms)",proof_log)
        assert len(expected)==9 and [name for name,_ in found]==expected
        assert not any(token in proof_log for token in ['sorryAx','Lean.ofReduceBool','Lean.trustCompiler'])
        for _,used in found:
            assert {a.strip() for a in used.split(',') if a.strip()} <= {'propext','Classical.choice','Quot.sound'}
        ci.write(out/'proof-receipt.json',{'status':'pass','count':9,'names':expected,
            'source':ci.digest((out/'UnarySpineProofs.lean').read_bytes()),'log':ci.digest((out/'proof.log').read_bytes())})
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
