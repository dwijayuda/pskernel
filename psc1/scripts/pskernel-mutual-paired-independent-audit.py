"""Independent GitHub artifact/Git audit. No producer code/compiler/kernel execution."""
from pathlib import Path
import os,json,hashlib,zipfile,io,subprocess,sys,importlib.util
PAIR={'rootVerified': True, 'bothActualJobsPass': True, 'source': '2708d07d5827b8aca72497a1ea3de989700b6996', 'run': 40246049646, 'productionTree': '7471f228b9bbc1eb5b9c0b78b85bf326aac72929', 'native': {'source': '4d6272807b3b168ab2d222ce942f92f7d7792cb8', 'run': 40244424044, 'job': 121322877883, 'artifact': 12617842824, 'bytes': 969954, 'sha256': 'b2cfa1f927d0dd768029814fdf9ad7555713ab336015fdd34a3ce37a7c6131bf', 'members': 405, 'proofs': 738}, 'routes': {'generated': {'artifact': 12619111746, 'job': 121327719585, 'bytes': 6117258, 'sha256': '5eb867f62c8637d98f1f73b8ec419aa9c108b80c441a8a1fac346bff8791b761', 'members': 274, 'program': {'bytes': 10601802, 'sha256': '9e81e1323aefacb71f3db71eb8698922e747160b051eff8ef82e1daa61679e9d'}}, 'canonical': {'artifact': 12620165966, 'job': 121327719432, 'bytes': 6267493, 'sha256': 'c6e636e1a9d81db4cc54cae48b6f3bf1db3a292b31dbedc56c6f60beb071b37a', 'members': 278, 'program': {'bytes': 10601802, 'sha256': '9e81e1323aefacb71f3db71eb8698922e747160b051eff8ef82e1daa61679e9d'}}}, 'bothCompleteProgramsByteIdentical': True, 'full193Qualified': False, 'performanceQualified': False}
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
n=getpin(PAIR['native']['source'],PAIR['native']['run'],PAIR['native'],'review/mutual4d-public738.zip')
manifest=json.loads(n.read('files.json'));assert manifest['source']==PAIR['native']['source']
pins=[]
for name in manifest['files']:
 if name.startswith('source/'):
  path=name.removeprefix('source/');pins.append({'path':path,'sha':gitpin(path)})
assert len(pins)==336
dump('review/mutual4d-public-actual-tree-blobs.json',pins)
subprocess.run([sys.executable,str(scripts/'pskernel-mutual-native-root-audit.py')],check=True)
nativeReport=json.loads(Path('review/mutual4d-public738-actual-report.json').read_text())
assert nativeReport['proofReportCount']==738 and nativeReport['nativeControlCount']==1184
core=subprocess.check_output(['git','ls-tree','-r','HEAD','psc1/packages/pskernel-core/src'],cwd=repo,text=True)
srcPins=[]
for line in core.splitlines():
 meta,path=line.split('\t',1);mode,kind,sha=meta.split();assert kind=='blob'
 srcPins.append({'path':path,'sha':sha})
dump('review/mutual-public7471-actual-src-blobs.json',srcPins)
routeReports={};programs={}
for route,pin in PAIR['routes'].items():
 job,=[j for j in jobs if j['id']==pin['job'] and j['name']=='complete-routes ('+route+')']
 filename='review/mutual2708-full-'+route+'.zip'
 z=getpin(PAIR['source'],PAIR['run'],pin,filename)
 assert z.read('authenticated-native738.zip')==Path('review/mutual4d-public738.zip').read_bytes()
 compiler=z.read('authenticated-compiler.zip')
 assert len(compiler)==2561674 and hashlib.sha256(compiler).hexdigest()=='c28da8d4d57a5a59a1ff686b2ce671102b20073bd00bf32450fae37cf2ab8dec'
 Path('review/lazy-perf-12606866673.zip').write_bytes(compiler)
 inputs=json.loads(z.read('inputs.json'));snapshotPins=[{'path':p['path'],'sha':gitpin(p['path'])} for p in inputs['snapshots']]
 assert len(snapshotPins)==43
 snapshotFile='review/'+route+'-actual-git.json';dump(snapshotFile,snapshotPins)
 logs=C.github('/actions/jobs/'+str(pin['job'])+'/logs').decode()
 markers=[line for line in logs.splitlines() if any('Z '+s in line for s in ['PSC1_MUTUAL_COMPLETE_JS_ALL: PASS','PSC1_MUTUAL_PUBLIC_JS_ALL: PASS','PSC1_MUTUAL_RETAINED_RUNTIME_ALL: PASS'])]
 assert len(markers)==3
 collector='review/'+route+'-actual-collector.log';Path(collector).write_text('\n'.join(markers)+'\n')
 cfg={**pin,'source':PAIR['source'],'run':PAIR['run'],'route':route,'local':filename,'gitSnapshots':snapshotFile,'collector':collector,'coherentPairPassed':True,'report':'review/'+route+'-root-report.json'}
 cfgpath='review/'+route+'-pin.json';dump(cfgpath,cfg)
 subprocess.run([sys.executable,str(scripts/'pskernel-mutual-full-root-audit.py'),cfgpath],check=True)
 routeReports[route]=json.loads(Path(cfg['report']).read_text());programs[route]=z.read('kernel.mjs')
assert set(programs)=={'generated','canonical'} and programs['generated']==programs['canonical']
baseline=json.loads((repo/'psc1/test/retained-249-audited-input-manifest.json').read_text())
assert len(baseline['bindings'])==249 and len(baseline['intentionalNativeQualifiedChanges'])==2
bindings=[]
for spec in baseline['bindings']:
 path=spec['path'];wanted=baseline['intentionalNativeQualifiedChanges'].get(path,spec['gitBlobSha']);actual=gitpin(path)
 assert actual==wanted,(path,'retained249binding')
 bindings.append({'path':path,'sha':actual,'intentionalNativeQualifiedChange':path in baseline['intentionalNativeQualifiedChanges']})
assert sum(not x['intentionalNativeQualifiedChange'] for x in bindings)==247
record={'status':'pass','producerSource':PAIR['source'],'producerRun':PAIR['run'],'auditSource':os.environ['GITHUB_SHA'],'auditRun':os.environ['GITHUB_RUN_ID'],'productionTree':PAIR['productionTree'],'sourceExecution':'none;artifact and Git inspection only','nativeReports':738,'proofModules':51,'nativeControls':1184,'generatedNativeEqualControlsPerRoute':853,'retainedHarnessesPerRoute':21,'bothActualJobsPass':True,'bothCompleteProgramsByteIdentical':True,'program':PAIR['routes']['generated']['program'],'all336NativeSourceSnapshotsGitVerified':True,'all43SnapshotsAnd169LeanFilesGitVerifiedPerRoute':True,'all169CanonicalPsFilesAndClosureDigestVerified':True,'all249AuditedBindingsVerified':True,'unchangedBindings':247,'explicitNativeQualifiedChangedBindings':2,'bindings':bindings,'routeSummaries':{route:{k:r[k] for k in ['artifact','archiveSha256','members','allManifestEntriesActuallyReadAndVerified','allActualGitSnapshotsVerified','privateControlMemory','canonicalClosure']} for route,r in routeReports.items()},'full193Qualified':False,'globalSoundness':False,'backendPreservationProof':False,'performanceQualified':False,'integrationAdopted':False}
dump('audit.json',record)
print('PSC1_MUTUAL_PAIRED_INDEPENDENT_AUDIT: PASS nativeReports=738 nativeControls=1184 routeControls=853 retainedHarnesses=21 auditedBindings=249')
