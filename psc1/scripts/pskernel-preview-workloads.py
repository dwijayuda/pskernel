"""Unchanged original baseline workloads; never converts strict failure to pass."""
import hashlib,io,json,os,pathlib,shutil,sys,zipfile,importlib.util,subprocess
assert os.environ.get('GITHUB_ACTIONS')=='true' and os.environ.get('RUNNER_OS')=='Linux'
ROOT=pathlib.Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('qualification',ROOT/'scripts/pskernel-cohort-qualification.py');q=importlib.util.module_from_spec(spec);spec.loader.exec_module(q)
OUT=q.OUT
PROGRAM={'bytes':10824302,'sha256':'1e6f22ae728c20306755c7be10118ccc40cd449e2c7e08872a153b5aa7a7f968'}
def digest(b):return {'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest()}
def archive(aid,pin):
 metadata=json.loads(q.get('/actions/artifacts/'+str(aid)));assert metadata['size_in_bytes']==pin['bytes'] and metadata['digest']=='sha256:'+pin['sha256'] and not metadata['expired']
 raw=q.get('/actions/artifacts/'+str(aid)+'/zip');assert digest(raw)==pin
 z=zipfile.ZipFile(io.BytesIO(raw));assert z.testzip() is None and len(z.namelist())==len(set(z.namelist()));return z
def prepare():
 OUT.mkdir()
 z=archive(12651426975,{'bytes':16587898,'sha256':'93fae7a049235b86216514ab8190eca58d8d4b3b0b227c2561d0410a21da02d8'})
 fixture=z.read('fixture.json');runner=z.read('runner.mjs')
 assert digest(fixture)=={'bytes':2791525,'sha256':'563d6ef138271a13039764257407ee8b66190bca02c8057489d3b1c45f51e71d'}
 assert digest(runner)=={'bytes':27140,'sha256':'d3672e6105a0ddf04b52774cb841df6f26e755d66915f6cf764929faaddf69a2'}
 assert runner==(ROOT/'scripts/pskernel-expr-v2-string-environment-smoke.mjs').read_bytes()
 rows=[]
 for route,aid,size,sha in [('generated',12705224166,1420126,'69013044b3538ff795f23eb4d0f6682904930901676c999e5d3819d6fe48206f'),
  ('canonical',12705848335,1575882,'f2d17909b4138297b1efb6ccef08022b0b8287c85691d17314207ca590f7cf28')]:
  z=archive(aid,{'bytes':size,'sha256':sha});files=json.loads(z.read('files.json'));assert set(files)==set(z.namelist())-{'files.json'}
  for name,pin in files.items():assert digest(z.read(name))==pin
  program=z.read('kernel.js');assert digest(program)==PROGRAM
  dest=OUT/('nested-'+route);dest.mkdir();(dest/'package').mkdir()
  for name,b in [('kernel.mjs',program),('fixture.json',fixture),('runner.mjs',runner)]: (dest/name).write_bytes(b)
  identity={'artifact':12660560142 if route=='generated' else 12661140267,'source':'e58ef33ad14b26dcc85231801b1322551cf34614','program':PROGRAM,'runtimePackageArtifact':aid}
  (dest/'package/provenance.json').write_text(json.dumps(identity)+'\n');rows.append({'route':route,'packageArtifact':aid,'packageArchive':{'bytes':size,'sha256':sha},'identity':identity})
 receipt={'format':'pskernel-preview-original-workload-inputs-v1','source':os.environ['GITHUB_SHA'],'run':os.environ['GITHUB_RUN_ID'],
  'rows':rows,'fixture':digest(fixture),'runner':digest(runner),'kernelSourceTree':'bbe353e649feed5b796adb164dcec36eaca915ab','originalPoliciesUnchanged':True}
 (OUT/'inputs.json').write_text(json.dumps(receipt,indent=2)+'\n');print(json.dumps(receipt),flush=True)
def ledger():
 work=pathlib.Path(os.environ['RUNNER_TEMP'])/'preview-workload-ledger';work.mkdir()
 artifacts=pathlib.Path(os.environ['RUNNER_TEMP'])/'preview-workload-results'
 strings=[]
 for p in sorted(artifacts.glob('pskernel-preview-string-*/qualification.json')):
  r=json.loads(p.read_text());assert r['complete1400'] and r['exitCode']==0 and r['deadlineSeconds']==1500 and r['fuel']==4096 and r['oldSpaceMiB']==2048 and r['emptyPATH']
  assert r['program']==PROGRAM and r['log']==digest((p.parent/'generated.log').read_bytes()) and r['memory']==(p.parent/'generated.memory').read_text()
  assert r['receipt']['assertions']==1400 and r['receipt']['requests']==294 and r['receipt']['metadata']==377 and not r['receipt']['diagnosticTracing']
  strings.append(r)
 assert len(strings)==12 and {(r['route'],r['sampleIndex']) for r in strings}=={(route,i) for route in ['generated','canonical'] for i in range(6)}
 freshpath=artifacts/'pskernel-preview-arena193/report.json';fresh=json.loads(freshpath.read_text())
 oldzip=archive(12705990238,{'bytes':388845,'sha256':'c662e8c5be5b6ecc3b718002be62545cbed85d55d7f50b7ad7275c65ed24f049'})
 old=json.loads(oldzip.read('report.json'));assert len(fresh['tests'])==fresh['total']==193 and fresh['excluded_cases']==[]
 assert fresh['kernel_module_sha256']==PROGRAM['sha256'] and fresh['kernel_fuel']==4096 and fresh['host_timeout_seconds_per_case']==60 and fresh['host_workers']==2 and fresh['node_heap_limit_mib']==2048
 assert fresh['counts']==old['counts'] and fresh['actual_matched_cases']==old['actual_matched_cases']==174 and not fresh['arena_comparison_complete']
 equal=0
 for a,b in zip(old['tests'],fresh['tests']):
  for key in ['index','label','name','classification','adaptation']:assert a[key]==b[key],(key,a.get('name'))
  if a['pskernel']['verdict']=='timeout':assert b['pskernel']['verdict']=='timeout';continue
  name=a['pskernel']['stdout'];oldpath=next(p for p in oldzip.namelist() if p.endswith('/'+name) or p==name)
  newbytes=(freshpath.parent/'case-logs'/b['pskernel']['stdout']).read_bytes();assert oldzip.read(oldpath)==newbytes,a['name'];equal+=1
 assert equal==176
 receipt={'format':'pskernel-preview-original-workload-ledger-v1','source':os.environ['GITHUB_SHA'],'run':os.environ['GITHUB_RUN_ID'],
  'program':PROGRAM,'stringAssertionsPerRoute':8400,'stringSamples':strings,'arenaTotal':193,'arenaStrictPass':False,'arenaStrictPasses':174,
  'arenaTimeouts':17,'safetyContractDifferences':2,'unchangedClassifications':193,'byteIdenticalCompletedSemanticEnvelopes':equal,
  'noNewFalseAcceptance':True,'baselineRegressionGate':True,'originalGlobalStatus':'B OPEN / C FAIL / D OPEN','fullPreviewQualified':False}
 (work/'ledger.json').write_text(json.dumps(receipt,indent=2)+'\n');shutil.copyfile(freshpath,work/'arena-report.json')
 print('PSKERNEL_PREVIEW_ORIGINAL_WORKLOAD_LEDGER: PASS '+json.dumps(receipt),flush=True)
if sys.argv[1]=='prepare':prepare()
elif sys.argv[1]=='string':q.string('nested',sys.argv[2],int(sys.argv[3]))
elif sys.argv[1]=='ledger':ledger()
else:raise ValueError('unknown mode')
