"""Independent GitHub artifact/Git audit. No producer code/compiler/kernel execution."""
from pathlib import Path
import os,json,hashlib,zipfile,io,subprocess,sys,importlib.util
PAIR={'rootVerified': True, 'bothActualJobsPass': True, 'source': '86d27f71dd1340d5f3d37a851f0ac85a40649b6a', 'run': 40304110450, 'productionTree': 'cada4884b4250a708dccadca42b8ef5bddbd04a3', 'native': {'source': '945d2c06b22c59e2bf4502e329403df62ae5915c', 'run': 40303319691, 'job': 121506227524, 'artifact': 12640944810, 'bytes': 999888, 'sha256': '582a93b1c52b424ab2578ae990e12b9ff6799fd680714e02154dc18eaa38685d', 'members': 412, 'proofs': 748}, 'routes': {'generated': {'artifact': 12642078456, 'job': 121508849440, 'bytes': 6178572, 'sha256': '4430461a46133e2014df1798b55cd0c912a16575cdd9025a9b14b502fbb4d8cc', 'members': 281, 'program': {'bytes': 10607234, 'sha256': '21cd36644cdb4baa0e0beb4cac1337f4ea6092c1c930b72a670ab0c2909765b0'}}, 'canonical': {'artifact': 12643381412, 'job': 121508849752, 'bytes': 6329114, 'sha256': 'a04f3944db8e117175f4e5df9e4f9300b58da91e666bbce84ba92cb9ddc4822a', 'members': 285, 'program': {'bytes': 10607234, 'sha256': '21cd36644cdb4baa0e0beb4cac1337f4ea6092c1c930b72a670ab0c2909765b0'}}}, 'bothCompleteProgramsByteIdentical': True, 'full193Qualified': False, 'performanceQualified': False}
repo=Path(os.environ['GITHUB_WORKSPACE']);scripts=repo/'psc1/scripts'
assert os.environ.get('GITHUB_ACTIONS')=='true' and os.environ.get('RUNNER_OS')=='Linux'
assert subprocess.check_output(['git','rev-parse','HEAD'],cwd=repo,text=True).strip()==os.environ['GITHUB_SHA']
assert subprocess.check_output(['git','rev-parse','HEAD:psc1/packages/pskernel-core/src'],cwd=repo,text=True).strip()==PAIR['productionTree']
spec=importlib.util.spec_from_file_location('download',scripts/'pskernel-church-stage-ci.py')
C=importlib.util.module_from_spec(spec);spec.loader.exec_module(C)
out=Path(os.environ['RUNNER_TEMP'])/'mutual-independent-audit';(out/'review').mkdir(parents=True)
os.chdir(out)
def dump(path,value):Path(path).write_text(json.dumps(value,indent=2)+'\n')
def getpin(source,run,pin,path):
 metadata=json.loads(C.github('/actions/artifacts/'+str(pin['artifact'])))
 assert metadata['workflow_run']['head_sha']==source and metadata['workflow_run']['id']==run and not metadata['expired']
 assert metadata['size_in_bytes']==pin['bytes'] and metadata['digest']=='sha256:'+pin['sha256']
 data=C.github('/actions/artifacts/'+str(pin['artifact'])+'/zip')
 assert len(data)==pin['bytes'] and hashlib.sha256(data).hexdigest()==pin['sha256']
 z=zipfile.ZipFile(io.BytesIO(data));assert z.testzip() is None and len(z.namelist())==len(set(z.namelist()))==pin['members']
 Path(path).write_bytes(data);return z
def gitpin(path):return subprocess.check_output(['git','rev-parse','HEAD:'+path],cwd=repo,text=True).strip()
run=json.loads(C.github('/actions/runs/'+str(PAIR['run'])))
assert run['head_sha']==PAIR['source'] and run['run_attempt']==1 and run['status']=='completed' and run['conclusion']=='success'
jobs=json.loads(C.github('/actions/runs/'+str(PAIR['run'])+'/jobs?per_page=100'))['jobs']
assert len(jobs)==2 and all(j['conclusion']=='success' and j['head_sha']==PAIR['source'] for j in jobs)
nativeRun=json.loads(C.github('/actions/runs/'+str(PAIR['native']['run'])))
assert nativeRun['head_sha']==PAIR['native']['source'] and nativeRun['run_attempt']==1 and nativeRun['conclusion']=='success'
n=getpin(PAIR['native']['source'],PAIR['native']['run'],PAIR['native'],'review/hygiene945-native748.zip')
manifest=json.loads(n.read('files.json'));assert manifest['source']==PAIR['native']['source']
pins=[]
for name in manifest['files']:
 if name.startswith('source/'):
  path=name.removeprefix('source/');pins.append({'path':path,'sha':gitpin(path)})
assert len(pins)==340
dump('review/hygiene945-actual-git340.json',pins)
getpin('4d6272807b3b168ab2d222ce942f92f7d7792cb8',40244424044,{'source': '4d6272807b3b168ab2d222ce942f92f7d7792cb8', 'run': 40244424044, 'job': 121322877883, 'artifact': 12617842824, 'bytes': 969954, 'sha256': 'b2cfa1f927d0dd768029814fdf9ad7555713ab336015fdd34a3ce37a7c6131bf', 'members': 405, 'proofs': 738},'review/mutual4d-public738.zip')
old=zipfile.ZipFile('review/mutual4d-public738.zip')
module='psc1/packages/pskernel-core/src/Ps/KernelCore/Admission/Inductive/Nested/Rebase.lean'
Path('review/hygiene-original-Rebase.lean').write_bytes(old.read('source/'+module))
Path('review/hygiene-fixed-Rebase.lean').write_bytes((repo/module).read_bytes())
for filename in ['PsKernelNestedParamHygieneProofs.lean','PsKernelNestedParamHygieneRegression.lean']:
 Path('review/'+filename).write_bytes((repo/'psc1/test'/filename).read_bytes())
subprocess.run([sys.executable,str(scripts/'pskernel-hygiene-native-root-audit.py')],check=True)
nativeReport=json.loads(Path('review/hygiene945-native748-actual-report.json').read_text())
assert nativeReport['proofReportCount']==748 and nativeReport['nativeControlCount']==1201
core=subprocess.check_output(['git','ls-tree','-r','HEAD','psc1/packages/pskernel-core/src'],cwd=repo,text=True)
srcPins=[]
for line in core.splitlines():
 meta,path=line.split('\t',1);mode,kind,sha=meta.split();assert kind=='blob'
 srcPins.append({'path':path,'sha':sha})
dump('review/hygiene-actual-src-blobs.json',srcPins)
routeReports={};programs={}
for route,pin in PAIR['routes'].items():
 job,=[j for j in jobs if j['id']==pin['job'] and j['name']=='complete-routes ('+route+')']
 filename='review/hygiene-full-'+route+'.zip'
 z=getpin(PAIR['source'],PAIR['run'],pin,filename)
 assert z.read('authenticated-native748.zip')==Path('review/hygiene945-native748.zip').read_bytes()
 compiler=z.read('authenticated-compiler.zip')
 assert len(compiler)==2561674 and hashlib.sha256(compiler).hexdigest()=='c28da8d4d57a5a59a1ff686b2ce671102b20073bd00bf32450fae37cf2ab8dec'
 Path('review/lazy-perf-12606866673.zip').write_bytes(compiler)
 inputs=json.loads(z.read('inputs.json'));snapshotPins=[{'path':p['path'],'sha':gitpin(p['path'])} for p in inputs['snapshots']]
 assert len(snapshotPins)==46
 snapshotFile='review/'+route+'-actual-git.json';dump(snapshotFile,snapshotPins)
 logs=C.github('/actions/jobs/'+str(pin['job'])+'/logs').decode()
 markers=[line for line in logs.splitlines() if any('Z '+s in line for s in ['PSC1_MUTUAL_COMPLETE_JS_ALL: PASS','PSC1_MUTUAL_PUBLIC_JS_ALL: PASS','PSC1_MUTUAL_RETAINED_RUNTIME_ALL: PASS','PSC1_NESTED_PARAM_HYGIENE_COMPLETE: PASS'])]
 assert len(markers)==4
 collector='review/'+route+'-actual-collector.log';Path(collector).write_text('\n'.join(markers)+'\n')
 cfg={**pin,'source':PAIR['source'],'run':PAIR['run'],'route':route,'local':filename,'gitSnapshots':snapshotFile,'collector':collector,'coherentPairPassed':True,'report':'review/'+route+'-root-report.json'}
 cfgpath='review/'+route+'-pin.json';dump(cfgpath,cfg)
 subprocess.run([sys.executable,str(scripts/'pskernel-hygiene-full-root-audit.py'),cfgpath],check=True)
 routeReports[route]=json.loads(Path(cfg['report']).read_text());programs[route]=z.read('kernel.mjs')
assert set(programs)=={'generated','canonical'} and programs['generated']==programs['canonical']
baseline=json.loads((repo/'psc1/test/nested-param-hygiene-retained-249-manifest.json').read_text())
assert len(baseline['bindings'])==249 and len(baseline['intentionalNativeQualifiedChanges'])==3
bindings=[]
for spec in baseline['bindings']:
 path=spec['path'];wanted=baseline['intentionalNativeQualifiedChanges'].get(path,spec['gitBlobSha']);actual=gitpin(path)
 assert actual==wanted,(path,'retained249binding')
 bindings.append({'path':path,'sha':actual,'intentionalNativeQualifiedChange':path in baseline['intentionalNativeQualifiedChanges']})
assert sum(not x['intentionalNativeQualifiedChange'] for x in bindings)==246
record={'status':'pass','producerSource':PAIR['source'],'producerRun':PAIR['run'],'auditSource':os.environ['GITHUB_SHA'],'auditRun':os.environ['GITHUB_RUN_ID'],'productionTree':PAIR['productionTree'],'sourceExecution':'none;artifact and Git inspection only','nativeReports':748,'proofModules':52,'nativeControls':1201,'generatedNativeEqualControlsPerRoute':870,'retainedHarnessesPerRoute':21,'bothActualJobsPass':True,'bothCompleteProgramsByteIdentical':True,'program':PAIR['routes']['generated']['program'],'all340NativeSourceSnapshotsGitVerified':True,'all46SnapshotsAnd169LeanFilesGitVerifiedPerRoute':True,'all169CanonicalPsFilesAndClosureDigestVerified':True,'all249AuditedBindingsVerified':True,'unchangedBindings':246,'explicitNativeQualifiedChangedBindings':3,'bindings':bindings,'routeSummaries':{route:{k:r[k] for k in ['artifact','archiveSha256','members','allManifestEntriesActuallyReadAndVerified','allActualGitSnapshotsVerified','privateControlMemory','canonicalClosure']} for route,r in routeReports.items()},'full193Qualified':False,'globalSoundness':False,'backendPreservationProof':False,'performanceQualified':False,'integrationAdopted':False}
dump('audit.json',record)
print('PSC1_HYGIENE_PAIRED_INDEPENDENT_AUDIT: PASS nativeReports=748 nativeControls=1201 routeControls=870 retainedHarnesses=21 auditedBindings=249')
