"""Bind quotient ID admission to unchanged retained gates and actual archives."""
import hashlib,json,os,pathlib,re,shutil,subprocess,sys
ROOT=pathlib.Path(__file__).resolve().parents[1]
REPO=ROOT.parent
BASE='79031362b401f85d3c7f324cc3aa7dbf91c1bf0e'
TREE='65d5b9c3d0431a8b86961b6d1aec398f7169d223'
PROD='psc1/packages/pskernel-core/src'
DELTA = ['psc1/packages/pskernel-core/src/Ps/KernelCore/API/Dag.lean', 'psc1/packages/pskernel-core/src/Ps/KernelCore/API/DagAdmission.lean', 'psc1/packages/pskernel-core/src/Ps/KernelCore/API/DagGenerated.lean', 'psc1/packages/pskernel-core/src/Ps/KernelCore/API/DagQuotAdmission.lean', 'psc1/packages/pskernel-core/src/Ps/KernelCore/Admission/Quot/Admission.lean']
PINS = {'psc1/packages/pskernel-core/src/Ps/KernelCore/Admission/Quot/Admission.lean': {'bytes': 3326, 'sha256': '528860b30e49a78930ab497b72900dba1afc047d2989964e6d88316b8cbebd68'}, 'psc1/packages/pskernel-core/src/Ps/KernelCore/API/DagQuotAdmission.lean': {'bytes': 12993, 'sha256': '624697322e578ef620a9a5bbf68f67a46e27c45e240ef29de76296892794c16b'}, 'psc1/packages/pskernel-core/src/Ps/KernelCore/API/DagAdmission.lean': {'bytes': 23775, 'sha256': 'be61803c61760b15d3f6674b0174d93692858a788f182676282e4b0a0a13980a'}, 'psc1/kernel-lakefile.lean': {'bytes': 17834, 'sha256': '2d8397ccfbd42bffa0a1cd64af2d3863494b7011f144800b8bbfb41cd59ba461'}, 'psc1/test/PsKernelQuotAdmissionProofs.lean': {'bytes': 15698, 'sha256': '9ed76158b819bfccf856c7e46f199a796dd7e5c015e364ffb5bfcc629483a3cd'}, 'psc1/test/PsKernelQuotAdmissionRegression.lean': {'bytes': 5011, 'sha256': '3ebdac6dde2d600f4c370a6d9e558a5d9477f6adfc5acb15f01c1cac110963c6'}, 'psc1/test/PsKernelExprV2QuotOwnerRegression.lean': {'bytes': 37053, 'sha256': 'b967ec021389288500a2a5db9ea6c71cb4675971bec6815b8011984bcccc4cf1'}, 'psc1/scripts/pskernel-expr-v2-quot-owner-smoke.mjs': {'bytes': 28065, 'sha256': 'fc77b937698a47e39cbcb5917fa2dce3167009b99b17d099f11ef6a9ce5233fa'}}
ALLOWED={'propext','Classical.choice','Quot.sound'}
PROOFS=['match_shape_correspondence','eq_shape_correspondence','refl_shape_correspondence','initialized_returns_exact_environment',
'declined_check_does_not_install','failed_check_does_not_install','shared_install_preserves_frozen_admission','missing_owner_declines','wrong_owner_declines']
def require(ok,message):
 if not ok:raise RuntimeError(message)
def digest(raw):return {'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()}
def read(path):return json.loads(path.read_text())
def write(path,value):path.write_text(json.dumps(value,indent=2)+'\n')
def git(*args):return subprocess.check_output(['git',*args],cwd=REPO)
def identity():return {'sourceSha':os.environ['GITHUB_SHA'],'runId':os.environ['GITHUB_RUN_ID'],'attempt':os.environ['GITHUB_RUN_ATTEMPT']}
def source(out):
 out.mkdir(parents=True,exist_ok=True)
 require(git('rev-parse','HEAD').decode().strip()==identity()['sourceSha'],'Exact checkout')
 require(git('rev-parse','HEAD:'+PROD).decode().strip()==TREE,'Exact complete production tree')
 require(git('diff','--name-only',BASE,'HEAD','--',PROD).decode().splitlines()==DELTA,'Exact five-path combined quotient change')
 paths=list(PINS)+['psc1/scripts/pskernel-quot-admission-qualification.py',
  'psc1/scripts/pskernel-transform-lazy-qualification.py','psc1/scripts/pskernel-unary-spine-qualification.py',
  'psc1/scripts/pskernel-validator-qualification.py','.github/workflows/psc1-pskernel-t05-header.yml',
  'psc1/lean-toolchain']
 rows=[]
 for name in paths:
  raw=(REPO/name).read_bytes()
  require(raw==git('show','HEAD:'+name),'Worktree/Git identity '+name)
  if name in PINS:require(digest(raw)==PINS[name],'Reviewed exact bytes '+name)
  path=out/'sources'/name;path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(raw)
  rows.append({'path':name,**digest(raw)})
 old=git('show',BASE+':'+PROD+'/Ps/KernelCore/Admission/Quot/Admission.lean').decode()
 frozen=old[old.index('def psKernelAddQuot'):].replace('def psKernelAddQuot','private def frozenAddQuot',1)
 proof=(ROOT/'test/PsKernelQuotAdmissionProofs.lean').read_text()
 require(frozen in proof,'Byte-exact frozen complete admission reference')
 require('sorry' not in proof and not re.search(r'(?m)^\s*(axiom|unsafe|partial|opaque)\b',proof),'No new trust')
 old_dag=git('show',BASE+':'+PROD+'/Ps/KernelCore/API/DagAdmission.lean').decode()
 added='      | PsKernelDagDeclarationRequest.quot =>\n          match declaration with\n          | PsKernelDeclarationRequest.quot =>\n              psKernelDagTryAdmitQuot environment arena declarations\n          | _ => Option.none\n'
 current=(REPO/PROD/'Ps/KernelCore/API/DagAdmission.lean').read_text()
 require(current.count(added)==1 and current.replace(added,'',1).replace('import Ps.KernelCore.API.DagQuotAdmission\n','',1)==old_dag,
  'Exact Quot routing addition; all other admission code unchanged')
 lake=(ROOT/'kernel-lakefile.lean').read_text()
 old_lake=git('show',BASE+':psc1/kernel-lakefile.lean').decode()
 require(lake.replace('    `Ps.KernelCore.API.DagQuotAdmission,\n','',1)==old_lake,'Exact additional native module root only')
 write(out/'source.json',{'schema':'psc1-quot-admission-source-v1',**identity(),'baseSource':BASE,
  'productionTree':TREE,'productionChanges':DELTA,'sourceSnapshots':rows,'fullKernel':False,'adopted':False})
 print('PSC1_QUOT_ADMISSION_SOURCE: PASS')
def proof_reports(text):
 require('sorryAx' not in text and 'Lean.ofReduceBool' not in text and 'Lean.trustCompiler' not in text,'No unapproved dependency')
 require(not re.search(r'\.lean:\d+:\d+: error:',text),'No proof diagnostics')
 rows=re.findall(r"'(PsKernelQuotAdmissionProofs\.[^']+)' (?:depends on axioms:\s*\[([^\]]*)\]|does not depend on any axioms)",text)
 require([name for name,_ in rows]==['PsKernelQuotAdmissionProofs.'+name for name in PROOFS],'Nine ordered actual reports')
 for name,used in rows:require({x.strip() for x in used.split(',') if x.strip()}<=ALLOWED,'Allowed axioms '+name)
 return [name for name,_ in rows]
def native(out):
 source(out)
 names=proof_reports((out/'proofs.log').read_text())
 require((out/'regression.log').read_text().splitlines()[-1]=='PSC1_QUOT_ADMISSION_PASS','Actual direct/public negative controls')
 require(any(x.startswith('PSC1_V2_QUOT_OWNER_PASS owners=4 cases=10 checks=180 whnf=180 defeq=180 invalidChecks=90 admissions=17 plans=10 repairs=5 private=13 officialPositive=10 officialNegative=7') for x in (out/'retained-quot-owner.log').read_text().splitlines()),'Retained official positive and negative suite')
 retained=read(out.parent/'lazy/cohort-native-receipt.json')
 require(retained['totalProofs']==542 and retained['proofModules']==38 and retained['productionTree']==TREE,'All retained542')
 require(all(str(retained[k])==v for k,v in identity().items()),'Same source native542 identity')
 all_names=retained['names']+names
 require(len(all_names)==len(set(all_names))==551,'551 distinct actual reports')
 write(out/'native-receipt.json',{'schema':'psc1-quot-admission-native-v1',**identity(),'status':'pass',
  'productionTree':TREE,'productionChanges':DELTA,'retainedProofs':542,'newProofs':9,
  'totalProofs':551,'proofModules':39,'names':all_names,
  'sourceInventory':digest((out/'source.json').read_bytes()),
  'logs':{name:digest((out/name).read_bytes()) for name in ['proofs.log','regression.log','retained-quot-owner.log']},
  'retainedReceipt':digest((out.parent/'lazy/cohort-native-receipt.json').read_bytes()),
  'fullKernel':False,'globalSoundnessProved':False,'performanceQualified':False,'adopted':False})
 print('PSC1_QUOT_ADMISSION_NATIVE551: PASS')
def route(out,native_root,node):
 source(out)
 native=native_root/'quot'
 receipt=read(native/'native-receipt.json')
 require(receipt['status']=='pass' and receipt['totalProofs']==551 and receipt['proofModules']==39 and receipt['productionTree']==TREE,'Complete native551')
 require(all(receipt[k]==v for k,v in identity().items()),'Exact source/run/attempt')
 proof_reports((native/'proofs.log').read_text())
 for name,pin in receipt['logs'].items():require(digest((native/name).read_bytes())==pin,'Actual native log '+name)
 for row in read(native/'source.json')['sourceSnapshots']:
  raw=(native/'sources'/row['path']).read_bytes()
  require(digest(raw)=={'bytes':row['bytes'],'sha256':row['sha256']} and raw==(REPO/row['path']).read_bytes(),'Native/runtime source equality')
 retained=read(out.parent/'lazy/cohort-route-receipt.json')
 require(retained['status']=='pass' and retained['nativeProofs']==542 and retained['proofModules']==38,'Complete retained route542')
 detached=out.parent/'detached';kernel=detached/'kernel.mjs'
 provenance=read(out.parent/'provenance.json')
 require(provenance['sourceSha']==identity()['sourceSha'] and provenance['kernel']==digest(kernel.read_bytes()),'Complete program provenance')
 require(provenance['fuel']==4096 and provenance['oldSpaceMiB']==2048 and provenance['emptyPATH'] is True,'Unchanged runtime policy')
 helper=ROOT/'scripts/pskernel-expr-v2-quot-owner-smoke.mjs'
 shutil.copyfile(helper,detached/helper.name)
 command=['/usr/bin/time','-f','peak_rss_kib=%M wall_seconds=%e exit_status=%x','-o',str(out/'runtime.memory'),
  'timeout','--signal=KILL','1500s','env','-i','PATH=',node,'--max-old-space-size=2048',helper.name,'kernel.mjs']
 with (out/'runtime.log').open('wb') as log:
  completed=subprocess.run(command,cwd=detached,stdout=log,stderr=subprocess.STDOUT)
 require(completed.returncode==0,'Actual bounded generated Quot controls')
 text=(out/'runtime.log').read_text()
 summary,=[x for x in text.splitlines() if x.startswith('PSC1_V2_QUOT_OWNER_JS_PASS ')]
 require(summary.startswith('PSC1_V2_QUOT_OWNER_JS_PASS owners=4 cases=10 checks=180 whnf=180 defeq=180 invalidChecks=90 admissions=17 plans=10 repairs=5 private=13 independentPositive=10 independentNegative=7 assertions='),'Full retained runtime suite plus direct Quot controls')
 require(re.fullmatch(r'peak_rss_kib=\d+ wall_seconds=\d+(?:\.\d+)? exit_status=0\s*',(out/'runtime.memory').read_text()) is not None,'Actual time/RSS')
 write(out/'route-receipt.json',{'schema':'psc1-quot-admission-route-v1',**identity(),'status':'pass','route':retained['route'],
  'productionTree':TREE,'productionChanges':DELTA,'nativeProofs':551,'proofModules':39,'kernel':provenance['kernel'],
  'retainedCompleteRoute':digest((out.parent/'lazy/cohort-route-receipt.json').read_bytes()),
  'nativeCohortReceipt':digest((native/'native-receipt.json').read_bytes()),
  'runtimeLog':digest((out/'runtime.log').read_bytes()),'runtimeMemory':digest((out/'runtime.memory').read_bytes()),
  'summary':summary,'fuel':4096,'oldSpaceMiB':2048,'emptyPATH':True,'fullKernel':False,'performanceQualified':False,'adopted':False})
 print('PSC1_QUOT_ADMISSION_ROUTE551: PASS route='+retained['route'])
if __name__=='__main__':
 require(os.environ.get('GITHUB_ACTIONS')=='true' and os.environ.get('RUNNER_OS')=='Linux','GitHub Linux only')
 command=sys.argv[1];out=pathlib.Path(sys.argv[2])
 if command=='source':source(out)
 elif command=='native':native(out)
 elif command=='route':route(out,pathlib.Path(sys.argv[3]),sys.argv[4])
 else:raise RuntimeError('Unknown command')
