"""Exact-source preflight for lazy transform-worker closure allocation."""
import hashlib
import json
import os
import pathlib
import re
import subprocess
import sys
ROOT=pathlib.Path(__file__).resolve().parents[1]
BASE='f091db586dcbe4a31905d6edf1c8c7957082527d'
PROD='psc1/packages/pskernel-core/src'
PATH=PROD+'/Ps/KernelCore/Core/ExprV2/Transform.lean'
PINS={PATH:{'bytes':16680,'sha256':'2e6ef5ba46eedfc9317a871ef56854a30ee55502bf7f73c07b41d0af2825cd55'},
 'psc1/test/PsKernelTransformLazyProofs.lean':{'bytes':3561,'sha256':'a45275e5ef37d0c49dd70ae06cfdd28760351d61ef54895604f10a5a18efbdee'}}
def require(ok,message):
 if not ok:raise RuntimeError(message)
def digest(raw):return {'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()}
def git(*args):return subprocess.check_output(['git',*args],cwd=ROOT.parent)
def write(path,value):path.write_text(json.dumps(value,indent=2)+'\n')
def source(out):
 out.mkdir(parents=True,exist_ok=True)
 require(git('rev-parse','HEAD').decode().strip()==os.environ['GITHUB_SHA'],'Exact workflow source')
 require(git('rev-parse',BASE+':'+PROD).decode().strip()=='62d48691ff7d9680878cf668862017d1061f2ebd','Qualified predecessor production tree')
 require(git('diff','--name-only',BASE,'HEAD','--',PROD).decode().splitlines()==[PATH],'Exactly one production path')
 before=git('show',BASE+':'+PATH).decode()
 expected=before.replace('  | Nat.succ remaining =>\n      let smaller := psKernelExprV2TransformWithFuel remaining;\n      fun (operation : PsKernelExprV2Transform)','  | Nat.succ remaining =>\n      fun (operation : PsKernelExprV2Transform)')
 expected=expected.replace('                    | Option.none =>\n                        let children := psKernelExprV2TransformChildren entry.node depth;','                    | Option.none =>\n                        let smaller := psKernelExprV2TransformWithFuel remaining;\n                        let children := psKernelExprV2TransformChildren entry.node depth;')
 expected=expected.replace('Memo keys include source, binder offset and effective budget; all memo state','The recursive worker is formed only after root, memo and leaf guards require\nchild traversal. This changes closure allocation only: the original fuel,\nresult, arena and memo behavior are preserved for every input.\nMemo keys include source, binder offset and effective budget; all memo state')
 require((ROOT.parent/PATH).read_bytes()==expected.encode(),'Exact let motion and explanatory comment only')
 reference=before[before.index('def psKernelExprV2TransformWithFuel\n'):before.index('\ndef psKernelExprV2TransformReferences\n')].replace('psKernelExprV2TransformWithFuel','psKernelTransformEagerReference')
 proof=(ROOT/'test/PsKernelTransformLazyProofs.lean').read_text()
 require(reference in proof,'Byte-exact predecessor worker reference')
 require(not re.search(r'(?m)^\s*(?:axiom|unsafe|partial|opaque)\b',proof) and 'sorry' not in proof,'No new trust or partial proof')
 for path,pin in PINS.items():require(digest((ROOT.parent/path).read_bytes())==pin,'Exact candidate/proof pin: '+path)
 paths=list(PINS)+['psc1/scripts/pskernel-transform-lazy-qualification.py','.github/workflows/psc1-pskernel-transform-lazy-native.yml','psc1/kernel-lakefile.lean','psc1/lean-toolchain']
 snapshots=[]
 for path in paths:
  raw=(ROOT.parent/path).read_bytes();target=out/'sources'/path;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(raw)
  snapshots.append({'path':path,**digest(raw)})
 (out/'predecessor-Transform.lean').write_bytes(before.encode())
 write(out/'source.json',{'schema':'psc1-transform-lazy-source-v1','sourceSha':os.environ['GITHUB_SHA'],'runId':os.environ['GITHUB_RUN_ID'],
  'attempt':os.environ['GITHUB_RUN_ATTEMPT'],'baselineSha':BASE,'productionTree':git('rev-parse','HEAD:'+PROD).decode().strip(),
  'productionChanges':[PATH],'exactLetMotionOnly':True,'originalFuelAndMemoSemantics':True,'sourceSnapshots':snapshots,
  'predecessor':digest(before.encode()),'qualificationComplete':False,'performanceQualified':False,'adopted':False})
 print('PSC1_TRANSFORM_LAZY_SOURCE: PASS exactLetMotionOnly=true')
def proofs(out):
 log=(out/'proofs.log').read_text()
 reports=re.findall(r"'([^']+)' (?:depends on axioms:\s*\[([^\]]*)\]|does not depend on any axioms)",log)
 require([n for n,_ in reports]==['psKernelTransformLazyPreservesAllInputs'],'Actual exact ordered proof report')
 for name,raw in reports:require({a.strip() for a in raw.split(',') if a.strip()}<={'propext','Classical.choice','Quot.sound'},'Standard axioms only')
 require(not any(s in log for s in ['sorryAx','Lean.ofReduceBool','Lean.trustCompiler']),'No trusted reduction or unfinished proof')
 write(out/'native-receipt.json',{'schema':'psc1-transform-lazy-native-v1','sourceSha':os.environ['GITHUB_SHA'],
  'runId':os.environ['GITHUB_RUN_ID'],'attempt':os.environ['GITHUB_RUN_ATTEMPT'],'proofs':1,'allFuelAndInputsExactEquality':True,
  'proofLog':digest((out/'proofs.log').read_bytes()),'fullQualification':False,'performanceQualified':False,'adopted':False})
 print('PSC1_TRANSFORM_LAZY_NATIVE: PASS allFuelAndInputsExactEquality=true proofs=1')
if __name__=='__main__':
 require(os.environ.get('GITHUB_ACTIONS')=='true' and os.environ.get('RUNNER_OS')=='Linux','GitHub Linux only')
 command=sys.argv[1];out=pathlib.Path(os.environ['RUNNER_TEMP'])/'transform-lazy'
 if command=='source':source(out)
 elif command=='proofs':proofs(out)
 else:raise RuntimeError('Unknown command')
