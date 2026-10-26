"""Independent GitHub artifact/Git audit. No producer code/compiler/kernel execution."""
from pathlib import Path
import os,json,hashlib,zipfile,io,subprocess,sys,importlib.util
PAIR={'rootVerified': True, 'bothActualJobsPass': True, 'source': '2ca1b7ecff8632c710d5aa21aa9ff4174aa3979c', 'run': 40307831396, 'productionTree': '95eb4b321befe5f9458b5ef64c876a0c0fcca1d9', 'native': {'source': 'f675f3c286c966c4d2f37c5e565052f107613e24', 'run': 40306586749, 'job': 121517088553, 'artifact': 12643406416, 'bytes': 1005234, 'sha256': 'ed8c06513686eb938a4092d645fe611664d42b1942d71d8f9fa6321cba1f471f', 'members': 415, 'proofs': 750}, 'routes': {'generated': {'artifact': 12645061364, 'job': 121521257011, 'bytes': 6198563, 'sha256': '3ffe4e3fdc40512d65158579e35e4b5d367ea7fd14beb551af5ba5cceceeb46f', 'members': 286, 'program': {'bytes': 10614366, 'sha256': '2cea5560f2f04f1ba871b277ccc1eb80d0e317c24a4afb74ac2d8a49b59a7067'}}, 'canonical': {'artifact': 12645159674, 'job': 121521257213, 'bytes': 6349380, 'sha256': '483cadc11e8a43701a5f2512eaec68a91035a136747b9382ddd0a6f5cb3810b9', 'members': 290, 'program': {'bytes': 10614366, 'sha256': '2cea5560f2f04f1ba871b277ccc1eb80d0e317c24a4afb74ac2d8a49b59a7067'}}}, 'bothCompleteProgramsByteIdentical': True, 'full193Qualified': False, 'performanceQualified': False}
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
n=getpin(PAIR['native']['source'],PAIR['native']['run'],PAIR['native'],'review/packedf675-native750.zip')
manifest=json.loads(n.read('files.json'));assert manifest['source']==PAIR['native']['source']
pins=[]
for name in manifest['files']:
 if name.startswith('source/'):
  path=name.removeprefix('source/');pins.append({'path':path,'sha':gitpin(path)})
assert len(pins)==342
dump('review/packedf675-actual-git342.json',pins)
getpin('4d6272807b3b168ab2d222ce942f92f7d7792cb8',40244424044,{'source': '4d6272807b3b168ab2d222ce942f92f7d7792cb8', 'run': 40244424044, 'job': 121322877883, 'artifact': 12617842824, 'bytes': 969954, 'sha256': 'b2cfa1f927d0dd768029814fdf9ad7555713ab336015fdd34a3ce37a7c6131bf', 'members': 405, 'proofs': 738},'review/mutual4d-public738.zip')
getpin('945d2c06b22c59e2bf4502e329403df62ae5915c',40303319691,{'source': '945d2c06b22c59e2bf4502e329403df62ae5915c', 'run': 40303319691, 'job': 121506227524, 'artifact': 12640944810, 'bytes': 999888, 'sha256': '582a93b1c52b424ab2578ae990e12b9ff6799fd680714e02154dc18eaa38685d', 'members': 412, 'proofs': 748},'review/hygiene945-native748.zip')
old=zipfile.ZipFile('review/mutual4d-public738.zip')
module='psc1/packages/pskernel-core/src/Ps/KernelCore/Admission/Inductive/Nested/Rebase.lean'
Path('review/hygiene-original-Rebase.lean').write_bytes(old.read('source/'+module))
Path('review/hygiene-fixed-Rebase.lean').write_bytes((repo/module).read_bytes())
for filename in ['PsKernelNestedParamHygieneProofs.lean','PsKernelNestedParamHygieneRegression.lean']:
 Path('review/'+filename).write_bytes((repo/'psc1/test'/filename).read_bytes())
Path('review/packed-cache-wired-CacheAnalysis.lean').write_bytes((repo/'psc1/packages/pskernel-core/src/Ps/KernelCore/Runtime/Acceleration/CacheAnalysis.lean').read_bytes())
for filename in ['PsKernelClosedCacheAnalysisRegression.lean','PsKernelEmptySemanticCacheProofs.lean']:
 Path('review/packed-wired-'+filename).write_bytes((repo/'psc1/test'/filename).read_bytes())
Path('review/packed-cache-component-fragment.lean').write_text('/- Experimental scalar result:65521 marks a free variable; every actual hash\n   is strictly below65521. The original recursive Prod worker and all public\n   consumers remain byte-preserved. No host cache or equality authority is added.\n   This helper is unused until exact refinement, portability and real timing pass. -/\ndef psKernelExprClosedCachePackedWorker\n    (expr : PsKernelExpr) :\n    Nat :=\n  match expr with\n  | PsKernelExpr.bvar index =>\n      (psKernelCacheMix 21 index)\n  | PsKernelExpr.fvar _ =>\n      psKernelCacheHashModulus\n  | PsKernelExpr.mvar name =>\n              (psKernelCacheMix 23 (psKernelCacheNameHash name))\n  | PsKernelExpr.sort level =>\n              (psKernelCacheMix 24 (psKernelCacheLevelHash level))\n  | PsKernelExpr.const name levels =>\n              (psKernelCacheMix\n          (psKernelCacheMix 25 (psKernelCacheNameHash name))\n          (psKernelCacheLevelListHash levels))\n  | PsKernelExpr.app fn arg =>\n      let fnAnalysis := psKernelExprClosedCachePackedWorker fn;\n      if Nat.beq fnAnalysis psKernelCacheHashModulus then\n        psKernelCacheHashModulus\n      else\n        let argAnalysis := psKernelExprClosedCachePackedWorker arg;\n        if Nat.beq argAnalysis psKernelCacheHashModulus then\n          psKernelCacheHashModulus\n        else\n                      (psKernelCacheMix\n              (psKernelCacheMix 26 fnAnalysis)\n              argAnalysis)\n  | PsKernelExpr.lam _ type body _ =>\n      let typeAnalysis := psKernelExprClosedCachePackedWorker type;\n      if Nat.beq typeAnalysis psKernelCacheHashModulus then\n        psKernelCacheHashModulus\n      else\n        let bodyAnalysis := psKernelExprClosedCachePackedWorker body;\n        if Nat.beq bodyAnalysis psKernelCacheHashModulus then\n          psKernelCacheHashModulus\n        else\n                      (psKernelCacheMix\n              (psKernelCacheMix 27 typeAnalysis)\n              bodyAnalysis)\n  | PsKernelExpr.forallE _ type body _ =>\n      let typeAnalysis := psKernelExprClosedCachePackedWorker type;\n      if Nat.beq typeAnalysis psKernelCacheHashModulus then\n        psKernelCacheHashModulus\n      else\n        let bodyAnalysis := psKernelExprClosedCachePackedWorker body;\n        if Nat.beq bodyAnalysis psKernelCacheHashModulus then\n          psKernelCacheHashModulus\n        else\n                      (psKernelCacheMix\n              (psKernelCacheMix 28 typeAnalysis)\n              bodyAnalysis)\n  | PsKernelExpr.letE _ type value body nondep =>\n      let typeAnalysis := psKernelExprClosedCachePackedWorker type;\n      if Nat.beq typeAnalysis psKernelCacheHashModulus then\n        psKernelCacheHashModulus\n      else\n        let valueAnalysis := psKernelExprClosedCachePackedWorker value;\n        if Nat.beq valueAnalysis psKernelCacheHashModulus then\n          psKernelCacheHashModulus\n        else\n          let bodyAnalysis := psKernelExprClosedCachePackedWorker body;\n          if Nat.beq bodyAnalysis psKernelCacheHashModulus then\n            psKernelCacheHashModulus\n          else\n            let flag := if nondep then 1 else 0;\n                          (psKernelCacheMix\n                (psKernelCacheMix\n                  (psKernelCacheMix\n                    (psKernelCacheMix 29 typeAnalysis)\n                    valueAnalysis)\n                  bodyAnalysis)\n                flag)\n  | PsKernelExpr.lit literal =>\n              (psKernelCacheMix 30 (psKernelCacheLiteralHash literal))\n  | PsKernelExpr.mdata metadata body =>\n      let bodyAnalysis := psKernelExprClosedCachePackedWorker body;\n      if Nat.beq bodyAnalysis psKernelCacheHashModulus then\n        psKernelCacheHashModulus\n      else\n                  (psKernelCacheMix\n            (psKernelCacheMix 31 metadata)\n            bodyAnalysis)\n  | PsKernelExpr.proj typeName index body =>\n      let bodyAnalysis := psKernelExprClosedCachePackedWorker body;\n      if Nat.beq bodyAnalysis psKernelCacheHashModulus then\n        psKernelCacheHashModulus\n      else\n                  (psKernelCacheMix\n            (psKernelCacheMix\n              (psKernelCacheMix 32 (psKernelCacheNameHash typeName))\n              index)\n            bodyAnalysis)\n\ndef psKernelExprClosedCachePackedDecode (value : Nat) : Prod Nat Bool :=\n  if Nat.beq value psKernelCacheHashModulus then\n    Prod.mk 0 true\n  else\n    Prod.mk value false\n\ndef psKernelExprClosedCachePackedAnalysis (expr : PsKernelExpr) : Prod Nat Bool :=\n  psKernelExprClosedCachePackedDecode (psKernelExprClosedCachePackedWorker expr)\n\n')
subprocess.run([sys.executable,str(scripts/'pskernel-packed-native-root-audit.py')],check=True)
nativeReport=json.loads(Path('review/packedf675-native750-actual-report.json').read_text())
assert nativeReport['proofReportCount']==750 and nativeReport['nativeControlCount']==1201
core=subprocess.check_output(['git','ls-tree','-r','HEAD','psc1/packages/pskernel-core/src'],cwd=repo,text=True)
srcPins=[]
for line in core.splitlines():
 meta,path=line.split('\t',1);mode,kind,sha=meta.split();assert kind=='blob'
 srcPins.append({'path':path,'sha':sha})
dump('review/packed-actual-src-blobs.json',srcPins)
routeReports={};programs={}
for route,pin in PAIR['routes'].items():
 job,=[j for j in jobs if j['id']==pin['job'] and j['name']=='complete-routes ('+route+')']
 filename='review/packed2ca-full-'+route+'.zip'
 z=getpin(PAIR['source'],PAIR['run'],pin,filename)
 assert z.read('authenticated-native750.zip')==Path('review/packedf675-native750.zip').read_bytes()
 compiler=z.read('authenticated-compiler.zip')
 assert len(compiler)==2561674 and hashlib.sha256(compiler).hexdigest()=='c28da8d4d57a5a59a1ff686b2ce671102b20073bd00bf32450fae37cf2ab8dec'
 Path('review/lazy-perf-12606866673.zip').write_bytes(compiler)
 inputs=json.loads(z.read('inputs.json'));snapshotPins=[{'path':p['path'],'sha':gitpin(p['path'])} for p in inputs['snapshots']]
 assert len(snapshotPins)==48
 snapshotFile='review/'+route+'-actual-git.json';dump(snapshotFile,snapshotPins)
 logs=C.github('/actions/jobs/'+str(pin['job'])+'/logs').decode()
 markers=[line for line in logs.splitlines() if any('Z '+s in line for s in ['PSC1_MUTUAL_COMPLETE_JS_ALL: PASS','PSC1_MUTUAL_PUBLIC_JS_ALL: PASS','PSC1_MUTUAL_RETAINED_RUNTIME_ALL: PASS','PSC1_NESTED_PARAM_HYGIENE_COMPLETE: PASS','PSC1_PACKED_CACHE_ACTUAL_ORIGINAL: PASS'])]
 assert len(markers)==5
 collector='review/'+route+'-actual-collector.log';Path(collector).write_text('\n'.join(markers)+'\n')
 cfg={**pin,'source':PAIR['source'],'run':PAIR['run'],'route':route,'local':filename,'gitSnapshots':snapshotFile,'collector':collector,'coherentPairPassed':True,'report':'review/'+route+'-root-report.json'}
 cfgpath='review/'+route+'-pin.json';dump(cfgpath,cfg)
 subprocess.run([sys.executable,str(scripts/'pskernel-packed-full-root-audit.py'),cfgpath],check=True)
 routeReports[route]=json.loads(Path(cfg['report']).read_text());programs[route]=z.read('kernel.mjs')
assert set(programs)=={'generated','canonical'} and programs['generated']==programs['canonical']
baseline=json.loads((repo/'psc1/test/packed-cache-retained-249-manifest.json').read_text())
assert len(baseline['bindings'])==249 and len(baseline['intentionalNativeQualifiedChanges'])==6
bindings=[]
for spec in baseline['bindings']:
 path=spec['path'];wanted=baseline['intentionalNativeQualifiedChanges'].get(path,spec['gitBlobSha']);actual=gitpin(path)
 assert actual==wanted,(path,'retained249binding')
 bindings.append({'path':path,'sha':actual,'intentionalNativeQualifiedChange':path in baseline['intentionalNativeQualifiedChanges']})
assert sum(not x['intentionalNativeQualifiedChange'] for x in bindings)==243
record={'status':'pass','producerSource':PAIR['source'],'producerRun':PAIR['run'],'auditSource':os.environ['GITHUB_SHA'],'auditRun':os.environ['GITHUB_RUN_ID'],'productionTree':PAIR['productionTree'],'sourceExecution':'none;artifact and Git inspection only','nativeReports':750,'proofModules':53,'nativeControls':1201,'generatedNativeEqualControlsPerRoute':870,'actualOriginalScalarComparisonsPerRoute':2400,'retainedHarnessesPerRoute':21,'bothActualJobsPass':True,'bothCompleteProgramsByteIdentical':True,'program':PAIR['routes']['generated']['program'],'all342NativeSourceSnapshotsGitVerified':True,'all48SnapshotsAnd169LeanFilesGitVerifiedPerRoute':True,'all169CanonicalPsFilesAndClosureDigestVerified':True,'all249AuditedBindingsVerified':True,'unchangedBindings':243,'explicitNativeQualifiedChangedBindings':6,'bindings':bindings,'routeSummaries':{route:{k:r[k] for k in ['artifact','archiveSha256','members','allManifestEntriesActuallyReadAndVerified','allActualGitSnapshotsVerified','privateControlMemory','canonicalClosure']} for route,r in routeReports.items()},'full193Qualified':False,'globalSoundness':False,'backendPreservationProof':False,'performanceQualified':False,'integrationAdopted':False}
dump('audit.json',record)
print('PSC1_PACKED_PAIRED_INDEPENDENT_AUDIT: PASS nativeReports=750 nativeControls=1201 routeControls=870 originalAnalysisComparisons=2400 retainedHarnesses=21 auditedBindings=249')
