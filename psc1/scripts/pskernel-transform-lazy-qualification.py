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
 require(git('diff','--name-only',BASE,'HEAD','--',PROD).decode().splitlines()==["psc1/packages/pskernel-core/src/Ps/KernelCore/API/DagAdmission.lean","psc1/packages/pskernel-core/src/Ps/KernelCore/API/DagQuotAdmission.lean","psc1/packages/pskernel-core/src/Ps/KernelCore/Admission/Quot/Admission.lean","psc1/packages/pskernel-core/src/Ps/KernelCore/Core/ExprV2/Transform.lean"],'Exact retained transform plus separately qualified quotient delta')
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
 paths=list(PINS)+['psc1/scripts/pskernel-transform-lazy-qualification.py','.github/workflows/psc1-pskernel-transform-lazy-native.yml','psc1/kernel-lakefile.lean','psc1/lean-toolchain','.github/workflows/psc1-pskernel-t05-header.yml']
 snapshots=[]
 for path in paths:
  raw=(ROOT.parent/path).read_bytes();target=out/'sources'/path;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(raw)
  snapshots.append({'path':path,**digest(raw)})
 (out/'predecessor-Transform.lean').write_bytes(before.encode())
 write(out/'source.json',{'schema':'psc1-transform-lazy-source-v1','sourceSha':os.environ['GITHUB_SHA'],'runId':os.environ['GITHUB_RUN_ID'],
  'attempt':os.environ['GITHUB_RUN_ATTEMPT'],'baselineSha':BASE,'productionTree':git('rev-parse','HEAD:'+PROD).decode().strip(),
  'productionChanges':["psc1/packages/pskernel-core/src/Ps/KernelCore/API/DagAdmission.lean","psc1/packages/pskernel-core/src/Ps/KernelCore/API/DagQuotAdmission.lean","psc1/packages/pskernel-core/src/Ps/KernelCore/Admission/Quot/Admission.lean","psc1/packages/pskernel-core/src/Ps/KernelCore/Core/ExprV2/Transform.lean"],'exactLetMotionScope':PATH,'additionalQuotAdmissionChangesSeparatelyQualified':True,'exactLetMotionOnly':True,'originalFuelAndMemoSemantics':True,'sourceSnapshots':snapshots,
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

def cohort(out):
 one=json.loads((out/'native-receipt.json').read_text())
 retained=json.loads((out.parent/'unary/native-receipt.json').read_text())
 validator=json.loads((out.parent/'validator/native-receipt.json').read_text())
 for row in [one,retained,validator]:
  require(row['sourceSha']==os.environ['GITHUB_SHA'] and str(row['runId'])==os.environ['GITHUB_RUN_ID'],'Exact same-source native cohort')
 require(one['proofs']==1 and one['allFuelAndInputsExactEquality'] and retained['totalProofs']==541
  and validator['totalProofs']==532 and retained['productionTree']==git('rev-parse','HEAD:'+PROD).decode().strip(),'Actual542 cohort')
 names=[n for row in validator['proofs'] for n in row['names']]+retained['names']+['psKernelTransformLazyPreservesAllInputs']
 require(len(names)==len(set(names))==542,'542 unique actual native reports')
 write(out/'cohort-native-receipt.json',{'schema':'psc1-transform-lazy-cohort-native-v1','sourceSha':os.environ['GITHUB_SHA'],
  'runId':os.environ['GITHUB_RUN_ID'],'attempt':os.environ['GITHUB_RUN_ATTEMPT'],'totalProofs':542,'proofModules':38,
  'retainedProofs':541,'additionalProofs':1,'productionTree':retained['productionTree'],'names':names,
  'retainedReceipt':digest((out.parent/'unary/native-receipt.json').read_bytes()),'localReceipt':digest((out/'native-receipt.json').read_bytes()),
  'fullKernel':False,'performanceQualified':False,'adopted':False})
 print('PSC1_TRANSFORM_LAZY_COHORT_NATIVE542: PASS actualUniqueReports=542')
def route(out,native_root):
 native=native_root/'lazy';receipt=json.loads((native/'cohort-native-receipt.json').read_text())
 retained=json.loads((out.parent/'unary/route-receipt.json').read_text())
 require(receipt['sourceSha']==retained['sourceSha']==os.environ['GITHUB_SHA']
  and str(receipt['runId'])==str(retained['runId'])==os.environ['GITHUB_RUN_ID'],'Same-source native and complete route')
 require(receipt['totalProofs']==542 and receipt['proofModules']==38 and retained['nativeProofs']==541
  and retained['status']=='pass' and receipt['productionTree']==retained['productionTree'],'Complete retained route plus actual local refinement')
 require(receipt['retainedReceipt']==digest((native_root/'unary/native-receipt.json').read_bytes())
  and receipt['localReceipt']==digest((native/'native-receipt.json').read_bytes()),'Actual retained/local receipt bytes')
 write(out/'cohort-route-receipt.json',{'schema':'psc1-transform-lazy-cohort-route-v1','sourceSha':os.environ['GITHUB_SHA'],
  'runId':os.environ['GITHUB_RUN_ID'],'attempt':os.environ['GITHUB_RUN_ATTEMPT'],'status':'pass','route':retained['route'],
  'nativeProofs':542,'proofModules':38,'productionTree':retained['productionTree'],
  'retainedCompleteRoute':digest((out.parent/'unary/route-receipt.json').read_bytes()),
  'nativeCohortReceipt':digest((native/'cohort-native-receipt.json').read_bytes()),'kernel':retained['kernel'],
  'originalFuelAndMemoSemantics':True,'transformWorkerConstructionDeferred':True,
  'retainedLiftAndCountSourceBytesMatch':True,'fullKernel':False,'performanceQualified':False,'adopted':False})
 print('PSC1_TRANSFORM_LAZY_COHORT_ROUTE542: PASS route='+retained['route'])

if __name__=='__main__':
 require(os.environ.get('GITHUB_ACTIONS')=='true' and os.environ.get('RUNNER_OS')=='Linux','GitHub Linux only')
 command=sys.argv[1];out=pathlib.Path(sys.argv[2]) if len(sys.argv)>2 else pathlib.Path(os.environ['RUNNER_TEMP'])/'transform-lazy'
 if command=='source':source(out)
 elif command=='proofs':proofs(out)
 elif command=='cohort':cohort(out)
 elif command=='route':route(out,pathlib.Path(sys.argv[3]))
 else:raise RuntimeError('Unknown command')
