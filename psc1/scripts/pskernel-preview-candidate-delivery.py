"""Package the qualified supervisor without passing a blocked preview gate."""
import hashlib,io,json,os,pathlib,re,shutil,subprocess,urllib.request,urllib.error,zipfile
assert os.environ.get('GITHUB_ACTIONS')=='true' and os.environ.get('RUNNER_OS')=='Linux'
ROOT=pathlib.Path(__file__).resolve().parents[1];OUT=pathlib.Path(os.environ['RUNNER_TEMP'])/'preview-candidate';OUT.mkdir()
TARGETS=json.loads((ROOT/'test/preview-candidate-inputs-20261029.json').read_text());assert TARGETS['mode']=='development-candidate'
PROGRAM={'bytes':10824302,'sha256':'1e6f22ae728c20306755c7be10118ccc40cd449e2c7e08872a153b5aa7a7f968'}
def digest(b):return {'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest()}
class NoRedirect(urllib.request.HTTPRedirectHandler):
 def redirect_request(self,req,fp,code,msg,headers,newurl):return None
def get(route):
 req=urllib.request.Request('https://api.github.com/repos/dwijayuda/pskernel'+route,headers={'Authorization':'Bearer '+os.environ['GH_TOKEN'],'Accept':'application/vnd.github+json'})
 try:return urllib.request.build_opener(NoRedirect()).open(req,timeout=120).read()
 except urllib.error.HTTPError as e:
  assert e.code in (301,302,303,307,308);return urllib.request.urlopen(e.headers['Location'],timeout=120).read()
runs={}
def load(spec):
 if spec['run'] not in runs:runs[spec['run']]=json.loads(get('/actions/runs/'+str(spec['run'])))
 run=runs[spec['run']];assert run['status']=='completed' and run['conclusion']==spec['conclusion'] and run['head_sha']==spec['source'] and run['run_attempt']==1
 metadata=json.loads(get('/actions/artifacts/'+str(spec['id'])));assert not metadata['expired'] and metadata['workflow_run']['head_sha']==spec['source'] and metadata['workflow_run']['id']==spec['run']
 raw=get('/actions/artifacts/'+str(spec['id'])+'/zip');assert digest(raw)==spec['archive'] and metadata['digest']=='sha256:'+spec['archive']['sha256'] and metadata['size_in_bytes']==len(raw)
 z=zipfile.ZipFile(io.BytesIO(raw));assert z.testzip() is None and len(z.namelist())==len(set(z.namelist()))
 for p in z.namelist():z.read(p)
 return z,raw
evidence=OUT/'evidence';evidence.mkdir();(evidence/'raw').mkdir()
supervisor,raw=load(TARGETS['supervisor']);(evidence/'raw/supervisor.zip').write_bytes(raw)
prefix=next(p.removesuffix('qualification.json') for p in supervisor.namelist() if p=='qualification.json' or p.endswith('/qualification.json'))
qualification=json.loads(supervisor.read(prefix+'qualification.json'));assert qualification['source']==TARGETS['supervisor']['source']
for p,pin in qualification['sources'].items():
 current=subprocess.check_output(['git','show',os.environ['GITHUB_SHA']+':'+p],cwd=ROOT.parent);assert digest(current)==pin and supervisor.read(prefix+'sources/'+p)==current
pins=supervisor.read(prefix+'pskernel-preview-axioms.json');assert digest(pins)==qualification['pins'] and pins==(ROOT/'scripts/pskernel-preview-axioms.json').read_bytes()
native,nativeRaw=load(TARGETS['native']);nativeReceipt=json.loads(native.read('receipt.json'));assert nativeReceipt['nativeReports']==814 and nativeReceipt['proofModules']==len(nativeReceipt['bindings'])==61
actual={};expected=set()
for p in native.namelist():
 if p.endswith('.log'):
  for name,axioms in re.findall(r"'([^']+)' (?:depends on axioms: \[([^\]]*)\]|does not depend on any axioms)",native.read(p).decode()):
   assert {a.strip() for a in axioms.split(',') if a.strip()} <= {'propext','Classical.choice','Quot.sound'}
   if name in actual:assert actual[name]==axioms
   actual[name]=axioms
for p,pin in nativeReceipt['bindings'].items():
 b=native.read('source/'+p);assert digest(b)==pin and subprocess.check_output(['git','show',os.environ['GITHUB_SHA']+':psc1/'+p],cwd=ROOT.parent)==b
 ns=[]
 for line in b.decode().splitlines():
  m=re.match(r'namespace\s+(\S+)',line)
  if m:ns.append(m[1])
  m=re.match(r'end(?:\s+(\S+))?\s*$',line)
  if m and ns:ns.pop()
  m=re.match(r'#print axioms\s+(\S+)',line)
  if m:expected.add(m[1] if m[1] in actual else '.'.join(ns+[m[1]]))
assert len(actual)==814 and set(actual)==expected
assert subprocess.check_output(['git','rev-parse','HEAD:psc1/packages/pskernel-core/src'],cwd=ROOT.parent,text=True).strip()=='bbe353e649feed5b796adb164dcec36eaca915ab'
strings=[];arena=None;arenaArchive=None
for spec in TARGETS['failedCampaignArtifacts']:
 z,raw=load(spec);(evidence/'raw'/(str(spec['id'])+'.zip')).write_bytes(raw)
 if spec['name'].startswith('pskernel-preview-string-'):
  r=json.loads(z.read('qualification.json'));assert r['program']==PROGRAM and r['fuel']==4096 and r['deadlineSeconds']==1500 and r['oldSpaceMiB']==2048 and r['emptyPATH']
  assert r['log']==digest(z.read('generated.log')) and r['memory']==z.read('generated.memory').decode()
  if r['complete1400']:assert r['exitCode']==0 and r['receipt']['assertions']==1400
  else:assert r['route']=='generated' and r['sampleIndex']==5 and r['exitCode']==137 and r['rightCensored'] and r['receipt'] is None and r['wallSeconds']>=1500
  strings.append(r)
 elif spec['name']=='pskernel-preview-arena193':arena=json.loads(z.read('report.json'));arenaArchive=z
assert len(strings)==12 and {(r['route'],r['sampleIndex']) for r in strings}=={(route,i) for route in ['generated','canonical'] for i in range(6)}
assert sum(r['complete1400'] for r in strings)==11 and arena['total']==len(arena['tests'])==193 and arena['actual_matched_cases']==174 and not arena['arena_comparison_complete']
assert arena['counts']['pskernel_timeout']==17 and arena['counts']['agreement_with_unsafe_or_partial_contract_difference']==2 and arena['excluded_cases']==[]
old,_=load(TARGETS['baselineArena']);previous=json.loads(old.read('report.json'));equal=0
for a,b in zip(previous['tests'],arena['tests']):
 assert all(a[k]==b[k] for k in ['index','name','label','classification','adaptation'])
 if a['pskernel']['verdict']=='timeout':continue
 p=a['pskernel']['stdout'];op=next(k for k in old.namelist() if k.endswith('/'+p) or k==p);assert old.read(op)==arenaArchive.read('case-logs/'+p);equal+=1
assert equal==176
ledger={'format':'pskernel-preview-candidate-limitations-v1','source':os.environ['GITHUB_SHA'],'run':os.environ['GITHUB_RUN_ID'],
 'fullPreviewQualified':False,'previewGateP5':'BLOCKED','previewGateP6':'OPEN: String deadline variability unresolved',
 'supervisorQualified':True,'program':PROGRAM,'nodeQualification':'22.23.4','stringSamples':strings,
 'confirmedStringAssertions':{'generated':7000,'canonical':8400},'plannedStringAssertionsPerRoute':8400,
 'censoredObservations':[{'route':'generated','sample':5,'deadlineSeconds':1500,'complete1400':False,'executedAssertions':None}],
 'arenaTotal':193,'arenaStrictPasses':174,'arenaTimeouts':17,'safetyContractDifferences':2,'strictArenaQualified':False,
 'byteIdenticalCompletedArenaEnvelopes':176,'all193ArenaClassificationsUnchanged':True,
 'globalStatus':'B OPEN / C FAIL / D OPEN','globalSoundnessProved':False,'compilerSelfHostQualified':False,'backendPreservationProved':False}
(evidence/'limitations.json').write_text(json.dumps(ledger,indent=2)+'\n');(evidence/'arena-report.json').write_text(json.dumps(arena,indent=2)+'\n')
(evidence/'native-814-evidence.zip').write_bytes(nativeRaw);(evidence/'supervisor-qualification.json').write_bytes(supervisor.read(prefix+'qualification.json'))
(evidence/'inputs.json').write_text(json.dumps(TARGETS,indent=2)+'\n')
node=shutil.which('node');assert node;routes=[]
for route in ['generated','canonical']:
 dest=OUT/route;dest.mkdir();base=prefix+route+'/'
 files=json.loads(supervisor.read(base+'files.json'));assert set(files)=={p.removeprefix(base) for p in supervisor.namelist() if p.startswith(base)}-{'files.json'}
 for name,pin in files.items():
  b=supervisor.read(base+name);assert digest(b)==pin and '/' not in name;(dest/name).write_bytes(b)
 assert digest((dest/'kernel.js').read_bytes())==PROGRAM
 controls=json.loads((dest/'preview-controls.json').read_text());assert controls['controls']==67 and len(controls['labels'])==len(set(controls['labels']))==67
 (dest/'limitations.json').write_text(json.dumps(ledger,indent=2)+'\n');(dest/'arena-report.json').write_text(json.dumps(arena,indent=2)+'\n');(dest/'native-814-evidence.zip').write_bytes(nativeRaw)
 for p in qualification['sources']:
  snapshot=dest/'preview-source'/p;snapshot.parent.mkdir(parents=True,exist_ok=True);snapshot.write_bytes(supervisor.read(prefix+'sources/'+p))
 readme=(ROOT/'packages/pskernel-core/docs/PREVIEW_RUNTIME_2026-10-29.md').read_text()
 (dest/'README.md').write_text('# Supervised PSKernel development candidate\n\nThis is a runnable development candidate, not completed Preview 1. The interface passes 67 supervision/ingress controls per route on Linux/Node 22.23.4. P5 remains BLOCKED: the fresh generated String sample 5 hit its unchanged 1500-second deadline; only 7000 generated assertions and all 8400 canonical assertions have complete fresh receipts. All original cases and this censored observation are retained in limitations.json. Strict Arena remains FAIL at 174/193, 17 timeouts and two safety differences.\n\n'+readme,encoding='utf-8')
 (dest/'SOURCE_BUILD.md').write_bytes((ROOT/'packages/pskernel-core/docs/QUALIFIED_RUNTIME_2026-10-27.md').read_bytes())
 (dest/'package.json').write_text(json.dumps({'name':'@pskernel/core-supervised-candidate','version':'0.0.0-candidate.20261029','private':True,'type':'module','engines':{'node':'22.x'},'os':['linux'],
  'exports':{'.':{'types':'./kernel.d.ts','default':'./kernel.js'}}},indent=2)+'\n')
 examples=[]
 for label,args,code,outcome in [('file-valid',['check-export.mjs','valid-example.ndjson'],0,'accepted'),('file-invalid',['check-export.mjs','invalid-example.ndjson'],1,'rejectedInvalid'),
  ('api',['api-example.mjs'],0,None),('checker',['example.mjs','./kernel.js'],0,None),('nested',['nested-example.mjs','./kernel.js'],0,None)]:
  r=subprocess.run([node,'--max-old-space-size=2048',*args],cwd=dest,env={'PATH':''},capture_output=True,timeout=600);log=r.stdout+r.stderr
  (dest/('delivery-'+label+'.log')).write_bytes(log);assert r.returncode==code
  if outcome:
   v=json.loads(r.stdout);assert v['outcome']==outcome and v['program']==PROGRAM and v['host']['workerReaped']
  else:assert b'PASS' in log
  examples.append({'label':label,'exitCode':r.returncode,'log':digest(log),'emptyPATH':True})
 receipt={'format':'pskernel-supervised-candidate-delivery-v1','source':os.environ['GITHUB_SHA'],'run':os.environ['GITHUB_RUN_ID'],'route':route,
  'program':PROGRAM,'supervisorSource':qualification['source'],'supervisorControls':67,'proofReportsPreserved':814,'proofModulesPreserved':61,
  'fullPreviewQualified':False,'P5':'BLOCKED','P6':'OPEN','candidateExamplesPassed':True,'examples':examples,'inputs':TARGETS}
 (dest/'candidate-provenance.json').write_text(json.dumps(receipt,indent=2)+'\n');routes.append(receipt)
 manifest={str(p.relative_to(dest)):digest(p.read_bytes()) for p in dest.rglob('*') if p.is_file() and str(p.relative_to(dest))!='files.json'}
 (dest/'files.json').write_text(json.dumps(manifest,indent=2)+'\n')
 print('PSKERNEL_SUPERVISED_CANDIDATE: PASS '+json.dumps(receipt),flush=True)
(evidence/'delivery.json').write_text(json.dumps({'source':os.environ['GITHUB_SHA'],'run':os.environ['GITHUB_RUN_ID'],'routes':routes,'nativeProofNames':sorted(actual),'fullPreviewQualified':False},indent=2)+'\n')
