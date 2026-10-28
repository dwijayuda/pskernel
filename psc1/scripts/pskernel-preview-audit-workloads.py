"""Static audit only. Never executes a compiler, kernel or workload."""
import hashlib,json,pathlib,re,sys,zipfile
metadataPath=pathlib.Path(sys.argv[1]).resolve();root=metadataPath.parent
rows=json.loads(metadataPath.read_text());archives={}
allow_failed='--allow-failed' in sys.argv
def digest(b):return {'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest()}
for a in rows:
 raw=(root/(str(a['id'])+'.zip')).read_bytes();assert digest(raw)=={'bytes':a['size_in_bytes'],'sha256':a['digest'].removeprefix('sha256:')}
 z=zipfile.ZipFile(root/(str(a['id'])+'.zip'));assert z.testzip() is None and len(z.namelist())==len(set(z.namelist()))
 for p in z.namelist():z.read(p)
 archives[a['name']]=(a,z)
program={'bytes':10824302,'sha256':'1e6f22ae728c20306755c7be10118ccc40cd449e2c7e08872a153b5aa7a7f968'}
strings=[]
for name,(a,z) in archives.items():
 if not name.startswith('pskernel-preview-string-'):continue
 assert set(z.namelist())=={'qualification.json','generated.log','generated.memory'}
 r=json.loads(z.read('qualification.json'));log=z.read('generated.log');mem=z.read('generated.memory').decode()
 assert r['deadlineSeconds']==1500 and r['fuel']==4096 and r['oldSpaceMiB']==2048 and r['emptyPATH']
 assert r['source']=='e58ef33ad14b26dcc85231801b1322551cf34614' and r['program']==program and r['log']==digest(log) and r['memory']==mem
 receipts=[json.loads(l.removeprefix('PSC1_T01F_STRING_SHARD_JS: PASS ')) for l in log.decode().splitlines() if l.startswith('PSC1_T01F_STRING_SHARD_JS: PASS ')]
 if not r['complete1400']:
  assert allow_failed and r['route'] in ('generated','canonical') and r['sampleIndex']==5 and r['exitCode']==137 and r['rightCensored'] and r['receipt'] is None and receipts==[] and r['wallSeconds']>=1500
  strings.append(r);continue
 assert r['exitCode']==0 and not r['rightCensored']
 assert receipts==[r['receipt']];x=r['receipt']
 assert x['assertions']==1400 and x['sampleIndex']==r['sampleIndex'] and x['requests']==294 and x['metadata']==377 and x['fuel']==4096 and x['independentAdmission'] and not x['diagnosticTracing']
 assert log.count(b'PSC1_T01F_JS_ADMIT_BEGIN ')==294 and x['kernelSha256']==program['sha256']
 assert x['fixtureSha256']=='563d6ef138271a13039764257407ee8b66190bca02c8057489d3b1c45f51e71d' and x['harnessSha256']=='d3672e6105a0ddf04b52774cb841df6f26e755d66915f6cf764929faaddf69a2'
 assert re.search(r'peak_rss_kib=\d+ wall_seconds=[0-9.]+ exit_status=0',mem)
 strings.append(r)
assert len(strings)==12 and {(r['route'],r['sampleIndex']) for r in strings}=={(route,i) for route in ['generated','canonical'] for i in range(6)}
for route in ['generated','canonical']:
 a,z=archives['pskernel-preview-original-'+route]
 assert digest(z.read('kernel.mjs'))==program and digest(z.read('fixture.json'))=={'bytes':2791525,'sha256':'563d6ef138271a13039764257407ee8b66190bca02c8057489d3b1c45f51e71d'}
 assert digest(z.read('runner.mjs'))=={'bytes':27140,'sha256':'d3672e6105a0ddf04b52774cb841df6f26e755d66915f6cf764929faaddf69a2'}
 identity=json.loads(z.read('package/provenance.json'));assert identity['program']==program and identity['source']=='e58ef33ad14b26dcc85231801b1322551cf34614'
_,official=archives['pskernel-preview-official193'];o=json.loads(official.read('report.json'))
assert len(o['tests'])==193 and all(t['adaptation']['body_bytes_identical'] for t in o['tests'])
for t in o['tests']:
 p='case-logs/'+t['official']['log'];assert hashlib.sha256(official.read(p)).hexdigest()==t['official']['output_sha256']
_,arena=archives['pskernel-preview-arena193'];a=json.loads(arena.read('report.json'));assert a['total']==len(a['tests'])==193 and a['actual_matched_cases']==174 and not a['arena_comparison_complete']
assert a['kernel_module_sha256']==program['sha256'] and a['kernel_fuel']==4096 and a['host_timeout_seconds_per_case']==60 and a['node_heap_limit_mib']==2048 and a['host_workers']==2 and a['excluded_cases']==[]
old=zipfile.ZipFile(root/'12705990238.zip');baseline=json.loads(old.read('report.json'));complete=0
for x,y,ref in zip(baseline['tests'],a['tests'],o['tests']):
 assert all(x[k]==y[k] for k in ['index','name','label','classification','adaptation'])
 assert y['official']['verdict']==ref['official']['verdict']
 if x['pskernel']['verdict']=='timeout':continue
 p=x['pskernel']['stdout'];op=next(k for k in old.namelist() if k.endswith('/'+p) or k==p);assert old.read(op)==arena.read('case-logs/'+p);complete+=1
assert complete==176
if not allow_failed:
 ledgerMetadata,ledgerZip=archives['pskernel-preview-original-workload-ledger'];ledger=json.loads(ledgerZip.read('ledger.json'))
 assert ledger['baselineRegressionGate'] and ledger['noNewFalseAcceptance'] and not ledger['arenaStrictPass'] and ledger['arenaTotal']==193 and ledger['byteIdenticalCompletedSemanticEnvelopes']==176
 assert {(r['route'],r['sampleIndex']):r for r in ledger['stringSamples']}=={(r['route'],r['sampleIndex']):r for r in strings}
summary={'run':rows[0]['workflow_run']['id'],'source':rows[0]['workflow_run']['head_sha'],'archives':len(archives),'program':program,'plannedAssertionsPerRoute':8400,
 'completedAssertions':{route:sum(1400 for r in strings if r['route']==route and r['complete1400']) for route in ['generated','canonical']},
 'censoredSamples':[{'route':r['route'],'sample':r['sampleIndex'],'deadline':1500,'executedAssertions':None} for r in strings if not r['complete1400']],
 'stringSample5Seconds':{route:next(r['wallSeconds'] for r in strings if r['route']==route and r['sampleIndex']==5) for route in ['generated','canonical']},
 'cases':193,'strictPasses':174,'timeouts':17,'safetyDifferences':2,'identicalCompletedEnvelopes':176,'originalStrictPass':False,'baselineRegressionGate':not allow_failed}
(root/('preview-workload-static-audit-'+str(summary['run'])+'.json')).write_text(json.dumps(summary,indent=2)+'\n')
print(json.dumps(summary,indent=2))
