"""Source-bound qualification of explicit Quot owners across sessions."""
import hashlib,json,os,pathlib,re,shutil,subprocess,sys
ROOT=pathlib.Path(__file__).resolve().parents[1]
REPO=ROOT.parent
BASE='79031362b401f85d3c7f324cc3aa7dbf91c1bf0e'
TREE='65d5b9c3d0431a8b86961b6d1aec398f7169d223'
PROD='psc1/packages/pskernel-core/src'
DELTA=["psc1/packages/pskernel-core/src/Ps/KernelCore/API/Dag.lean","psc1/packages/pskernel-core/src/Ps/KernelCore/API/DagAdmission.lean","psc1/packages/pskernel-core/src/Ps/KernelCore/API/DagGenerated.lean","psc1/packages/pskernel-core/src/Ps/KernelCore/API/DagQuotAdmission.lean","psc1/packages/pskernel-core/src/Ps/KernelCore/Admission/Quot/Admission.lean"]
PINS = {'psc1/packages/pskernel-core/src/Ps/KernelCore/API/Dag.lean': {'bytes': 26014, 'sha256': '80a8d48df35f9b9b8a045cb6cab932262bf38afea9b065fa04b3231a1e3412f5'}, 'psc1/packages/pskernel-core/src/Ps/KernelCore/API/DagGenerated.lean': {'bytes': 31020, 'sha256': '47defc0dba315bb98e862fb28d74b209e58610fe2e8be459777e7cc6f7de67d3'}, 'psc1/test/PsKernelQuotSessionOwnerProofs.lean': {'bytes': 7202, 'sha256': '9b819e4c23a98993bc986e10a2720263ace028ed642a33e4a57adc982d8c67fd'}, 'psc1/test/PsKernelQuotSessionOwnerRegression.lean': {'bytes': 6245, 'sha256': '21b9dbb299539e7478733d8301054baac36a182ef2f6f985b087d0d28c98dd8a'}, 'psc1/scripts/pskernel-quot-session-owner-smoke.mjs': {'bytes': 34104, 'sha256': '1444d083a9cd7c1a39846ed3d8146e033607ce80f52fd1dfb496fed6689763e6'}, 'psc1/packages/pskernel-core/src/Ps/KernelCore/API/DagQuotAdmission.lean': {'bytes': 12993, 'sha256': '624697322e578ef620a9a5bbf68f67a46e27c45e240ef29de76296892794c16b'}}
MODULE='PsKernelQuotSessionOwnerProofs'
NAMES=["preflight_error_precedes_prepare","prepare_error_publishes_no_owner","decline_discards_prepared_owner_and_restarts_original","hard_rejection_never_invokes_original_admission","success_keeps_exact_prepared_owner_for_atomic_publication","declaration_limit_precedes_generated_header_import","initialized_preparation_is_exact_identity","missing_eq_preparation_is_exact_identity","wrong_eq_kind_does_not_import","explicit_public_quot_routes_to_owned_worker"]
def require(ok,message):
 if not ok:raise RuntimeError(message)
def digest(raw):return {'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()}
def write(path,value):path.write_text(json.dumps(value,indent=2)+'\n')
def read(path):return json.loads(path.read_text())
def git(*args):return subprocess.check_output(['git',*args],cwd=REPO)
def identity():return {'sourceSha':os.environ['GITHUB_SHA'],'runId':os.environ['GITHUB_RUN_ID'],'attempt':os.environ['GITHUB_RUN_ATTEMPT']}
def source(out):
 out.mkdir(parents=True,exist_ok=True)
 require(git('rev-parse','HEAD').decode().strip()==identity()['sourceSha'],'Exact checkout')
 require(git('rev-parse','HEAD:'+PROD).decode().strip()==TREE,'Complete reviewed production tree')
 require(git('diff','--name-only',BASE,'HEAD','--',PROD).decode().splitlines()==DELTA,'Exact five-path combined quotient change')
 rows=[]
 for path in list(PINS)+['psc1/scripts/pskernel-quot-session-owner-qualification.py',
  '.github/workflows/psc1-pskernel-t05-header.yml','psc1/kernel-lakefile.lean','psc1/lean-toolchain']:
  raw=(REPO/path).read_bytes();require(raw==git('show','HEAD:'+path),'Worktree/Git identity '+path)
  if path in PINS:require(digest(raw)==PINS[path],'Exact reviewed source '+path)
  dest=out/'sources'/path;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(raw)
  rows.append({'path':path,**digest(raw)})
 dag=PROD+'/Ps/KernelCore/API/Dag.lean';actual=(REPO/dag).read_text()
 begin=actual.index('/- Publish the four checked live Quot headers')
 end=actual.index('def psKernelDagRunOwnedCommandWithSource\n',begin)
 restored=actual[:begin]+actual[end:]
 added='      | PsKernelDagDeclarationRequest.quot =>\n          psKernelDagRunQuotOwnedWith psKernelDagGeneratedPrepareQuot psKernelDagTryAdmitQuot\n            input execution levelParams safety arena built\n'
 require(restored.count(added)==1,'One explicit Quot owned route')
 require(restored.replace(added,'',1)==git('show',BASE+':'+dag).decode(),'All other public DAG code byte-identical')
 generated=PROD+'/Ps/KernelCore/API/DagGenerated.lean'
 actual=(REPO/generated).read_text()
 require(actual[:actual.index('\n/- Explicit Quot commands')]==git('show',BASE+':'+generated).decode(),
  'All original checked metadata import code byte-identical')
 proof=(ROOT/'test/PsKernelQuotSessionOwnerProofs.lean').read_text()
 require('sorry' not in proof and not re.search(r'(?m)^\s*(axiom|unsafe|partial|opaque)\b',proof),'No proof escape')
 write(out/'source.json',{'schema':'psc1-quot-session-owner-source-v1',**identity(),'baseSource':BASE,
  'productionTree':TREE,'productionChanges':DELTA,'sourceSnapshots':rows,
  'allOtherPublicDagAndMetadataCodeUnchanged':True,'fullKernel':False,'adopted':False})
 print('PSC1_QUOT_SESSION_OWNER_SOURCE: PASS')
def proof_reports(raw):
 text=raw.decode()
 require(not any(x in text for x in ['sorryAx','Lean.ofReduceBool','Lean.trustCompiler']),'No unapproved dependency')
 require(not re.search(r'\.lean:\d+:\d+: error:',text),'No proof diagnostic')
 rows=re.findall(r"'([^']+)' (?:depends on axioms:\s*\[([^\]]*)\]|does not depend on any axioms)",text)
 require([name for name,_ in rows]==[MODULE+'.'+name for name in NAMES],'Ten ordered actual reports')
 for name,used in rows:require({x.strip() for x in used.split(',') if x.strip()}<={'propext','Classical.choice','Quot.sound'},'Allowed axioms '+name)
 return [name for name,_ in rows]
def native(out):
 source(out)
 names=proof_reports((out/'proofs.log').read_bytes())
 labels=[x[len('PSC1_QUOT_SESSION_OWNER_ASSERT '):] for x in (out/'regression.log').read_text().splitlines() if x.startswith('PSC1_QUOT_SESSION_OWNER_ASSERT ')]
 require(len(labels)==17 and (out/'regression.log').read_text().splitlines()[-1]=='PSC1_QUOT_SESSION_OWNER_PASS','Actual17 owning-session controls')
 retained=read(out.parent/'quot/native-receipt.json')
 require(retained['status']=='pass' and retained['totalProofs']==551 and retained['proofModules']==39,'Complete retained551')
 require(retained['productionTree']==TREE and all(retained[k]==v for k,v in identity().items()),'Same complete source')
 all_names=retained['names']+names
 require(len(all_names)==len(set(all_names))==561,'561 distinct actual reports')
 write(out/'native-receipt.json',{'schema':'psc1-quot-session-owner-native-v1',**identity(),'status':'pass',
  'productionTree':TREE,'productionChanges':DELTA,'retainedProofs':551,'newProofs':10,'totalProofs':561,'proofModules':40,
  'names':all_names,'sourceInventory':digest((out/'source.json').read_bytes()),
  'logs':{path:digest((out/path).read_bytes()) for path in ['proofs.log','regression.log']},
  'retainedReceipt':digest((out.parent/'quot/native-receipt.json').read_bytes()),
  'runtimeAssertions':labels,'fullKernel':False,'performanceQualified':False,'adopted':False})
 print('PSC1_QUOT_SESSION_OWNER_NATIVE561: PASS')
def route(out,native_root,node):
 source(out)
 native=native_root/'quot-owner';receipt=read(native/'native-receipt.json')
 require(receipt['status']=='pass' and receipt['totalProofs']==561 and receipt['proofModules']==40,'Complete actual native561')
 require(receipt['productionTree']==TREE and all(receipt[k]==v for k,v in identity().items()),'Exact same source/run')
 proof_reports((native/'proofs.log').read_bytes())
 for path,pin in receipt['logs'].items():require(digest((native/path).read_bytes())==pin,'Actual native log '+path)
 for row in read(native/'source.json')['sourceSnapshots']:
  raw=(native/'sources'/row['path']).read_bytes()
  require(digest(raw)=={'bytes':row['bytes'],'sha256':row['sha256']} and raw==(REPO/row['path']).read_bytes(),'Actual native/route source equality')
 retained=read(out.parent/'quot/route-receipt.json')
 require(retained['status']=='pass' and retained['nativeProofs']==551,'Complete retained generated551 route')
 detached=out.parent/'detached';kernel=detached/'kernel.mjs'
 provenance=read(out.parent/'provenance.json')
 require(provenance['sourceSha']==identity()['sourceSha'] and provenance['kernel']==digest(kernel.read_bytes()),'Whole actual complete program')
 require(provenance['fuel']==4096 and provenance['oldSpaceMiB']==2048 and provenance['emptyPATH'] is True,'Unchanged runtime policy')
 helper=ROOT/'scripts/pskernel-quot-session-owner-smoke.mjs';shutil.copyfile(helper,detached/helper.name)
 command=['/usr/bin/time','-f','peak_rss_kib=%M wall_seconds=%e exit_status=%x','-o',str(out/'runtime.memory'),
  'timeout','--signal=KILL','1500s','env','-i','PATH=',node,'--max-old-space-size=2048',helper.name,'kernel.mjs']
 with (out/'runtime.log').open('wb') as log:
  completed=subprocess.run(command,cwd=detached,stdout=log,stderr=subprocess.STDOUT)
 require(completed.returncode==0,'Actual bounded complete generated session-owner controls')
 text=(out/'runtime.log').read_text();marker='PSC1_QUOT_SESSION_OWNER_JS: PASS '
 summary,=[json.loads(x[len(marker):]) for x in text.splitlines() if x.startswith(marker)]
 require(summary['assertions']==len(summary['labels'])==len(set(summary['labels']))==17,'Actual17 distinct complete controls')
 require(all(summary[k] is True for k in ['originalInputNamespace','preexistingEqDirect','atomicPublication','completeOriginalRestartOnDecline']),'Full owning protocol')
 require(summary['fuel']=='4096' and summary['fullKernel'] is False and summary['performanceQualified'] is False,'Exact local scope')
 require(sum(x.startswith('PSC1_V2_QUOT_OWNER_JS_PASS owners=4 cases=10 checks=180 whnf=180 defeq=180 invalidChecks=90 admissions=17 plans=10 repairs=5 private=13 independentPositive=10 independentNegative=7 assertions=') for x in text.splitlines())==1,'All retained differential Quot controls')
 require(re.fullmatch(r'peak_rss_kib=\d+ wall_seconds=\d+(?:\.\d+)? exit_status=0\s*',(out/'runtime.memory').read_text()) is not None,'Actual successful time/RSS')
 write(out/'route-receipt.json',{'schema':'psc1-quot-session-owner-route-v1',**identity(),'status':'pass','route':retained['route'],
  'productionTree':TREE,'productionChanges':DELTA,'nativeProofs':561,'proofModules':40,'kernel':provenance['kernel'],
  'retainedCompleteRoute':digest((out.parent/'quot/route-receipt.json').read_bytes()),
  'nativeCohortReceipt':digest((native/'native-receipt.json').read_bytes()),'summary':summary,
  'runtimeLog':digest((out/'runtime.log').read_bytes()),'runtimeMemory':digest((out/'runtime.memory').read_bytes()),
  'fuel':4096,'oldSpaceMiB':2048,'emptyPATH':True,'fullKernel':False,'performanceQualified':False,'adopted':False})
 print('PSC1_QUOT_SESSION_OWNER_ROUTE561: PASS route='+retained['route'])
if __name__=='__main__':
 require(os.environ.get('GITHUB_ACTIONS')=='true' and os.environ.get('RUNNER_OS')=='Linux','GitHub Linux only')
 mode=sys.argv[1];out=pathlib.Path(sys.argv[2])
 if mode=='source':source(out)
 elif mode=='native':native(out)
 elif mode=='route':route(out,pathlib.Path(sys.argv[3]),sys.argv[4])
 else:raise RuntimeError('Unknown mode')
