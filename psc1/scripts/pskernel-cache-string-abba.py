"""GitHub Linux-only String sample5 observation; never full qualification."""
from pathlib import Path,PurePosixPath
import hashlib,importlib.util,io,json,os,re,shutil,stat,statistics,subprocess,time,zipfile

PAIR={'rootVerified': True, 'bothActualJobsPass': True, 'source': '8c077fa9f10a0370b70ad9e6d0c3d7d87df77d35', 'run': 40252766388, 'productionTree': 'c4a5fa4dc72f81d4c28a45e0772d9cd7788b3ae5', 'native': {'source': '7ac867ce6a4e2003f5e8a94b8f8e1b5deb970166', 'run': 40252352368, 'job': 121346796474, 'artifact': 12621138409, 'bytes': 996349, 'sha256': '9dd28cff98f35ab12cf509195182e8cae6e429255e2ee45777098e761ef30c40', 'members': 409, 'proofs': 742}, 'routes': {'generated': {'artifact': 12621583441, 'job': 121348037780, 'bytes': 6189162, 'sha256': 'c8cabb33db8a8f56c5a5a6e1c8d1fb91f7ef692a8d0a7043094f8c8571462bcc', 'members': 282, 'program': {'bytes': 10632560, 'sha256': '8c4a337157a88bf8ddd199d7562c7eb7a3a4f96a852368bcc615dc9022828cfe'}}, 'canonical': {'artifact': 12621953805, 'job': 121348037399, 'bytes': 6340008, 'sha256': '8f74927a96f059d48d748c402e21f5d6eaf336649d3e0e14f667a513b7c5935a', 'members': 286, 'program': {'bytes': 10632560, 'sha256': '8c4a337157a88bf8ddd199d7562c7eb7a3a4f96a852368bcc615dc9022828cfe'}}}, 'bothCompleteProgramsByteIdentical': True, 'full193Qualified': False, 'performanceQualified': False, 'cacheAdopted': False, 'actual249BindingsVerified': True, 'unchangedAuditedInputs': 242, 'nativeQualifiedAuditedChanges': 7, 'actualOriginalWorkerControlsPerRoute': 2097}
BASE={'rootVerified': True, 'bothActualJobsPass': True, 'source': '2708d07d5827b8aca72497a1ea3de989700b6996', 'run': 40246049646, 'productionTree': '7471f228b9bbc1eb5b9c0b78b85bf326aac72929', 'native': {'source': '4d6272807b3b168ab2d222ce942f92f7d7792cb8', 'run': 40244424044, 'job': 121322877883, 'artifact': 12617842824, 'bytes': 969954, 'sha256': 'b2cfa1f927d0dd768029814fdf9ad7555713ab336015fdd34a3ce37a7c6131bf', 'members': 405, 'proofs': 738}, 'routes': {'generated': {'artifact': 12619111746, 'job': 121327719585, 'bytes': 6117258, 'sha256': '5eb867f62c8637d98f1f73b8ec419aa9c108b80c441a8a1fac346bff8791b761', 'members': 274, 'program': {'bytes': 10601802, 'sha256': '9e81e1323aefacb71f3db71eb8698922e747160b051eff8ef82e1daa61679e9d'}}, 'canonical': {'artifact': 12620165966, 'job': 121327719432, 'bytes': 6267493, 'sha256': 'c6e636e1a9d81db4cc54cae48b6f3bf1db3a292b31dbedc56c6f60beb071b37a', 'members': 278, 'program': {'bytes': 10601802, 'sha256': '9e81e1323aefacb71f3db71eb8698922e747160b051eff8ef82e1daa61679e9d'}}}, 'bothCompleteProgramsByteIdentical': True, 'full193Qualified': False, 'performanceQualified': False}
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('artifact_common',ROOT/'scripts/pskernel-church-stage-ci.py')
C=importlib.util.module_from_spec(spec);spec.loader.exec_module(C)

def archive(source,run,pin):
 a=json.loads(C.github('/actions/artifacts/'+str(pin['artifact'])))
 C.require(a['workflow_run']['id']==run and a['workflow_run']['head_sha']==source and not a['expired'] and a['size_in_bytes']==pin['bytes'] and a['digest']=='sha256:'+pin['sha256'],'Pinned actual source-bound artifact')
 raw=C.github('/actions/artifacts/'+str(pin['artifact'])+'/zip')
 C.require(C.digest(raw)=={'bytes':pin['bytes'],'sha256':pin['sha256']},'Actual archive digest')
 z=zipfile.ZipFile(io.BytesIO(raw));items=z.infolist()
 C.require(len(items)==len({i.filename for i in items})==pin['members'] and z.testzip() is None,'Unique actual archive members and CRC')
 for i in items:
  p=PurePosixPath(i.filename)
  C.require(not p.is_absolute() and '..' not in p.parts and not i.is_dir() and not stat.S_ISLNK(i.external_attr>>16) and '\\' not in i.filename and i.file_size<=32_000_000,'Safe bounded member')
 return raw,z

def qualified_program(pair,out,variant):
 run=json.loads(C.github('/actions/runs/'+str(pair['run'])))
 C.require(run['head_sha']==pair['source'] and run['status']=='completed' and run['conclusion']=='success' and run['run_attempt']==1,'Exact coherent producer run PASS before runtime')
 jobs=json.loads(C.github('/actions/runs/'+str(pair['run'])+'/jobs?per_page=100'))['jobs']
 C.require(len(jobs)==2 and all(j['conclusion']=='success' for j in jobs),'Both full-route jobs PASS')
 pin=pair['routes']['generated']
 C.require(any(j['id']==pin['job'] and j['name']=='complete-routes (generated)' for j in jobs),'Exact generated job')
 raw,z=archive(pair['source'],pair['run'],pin);m=json.loads(z.read('files.json'))
 C.require(m['source']==pair['source'] and len(m['files'])==pin['members']-1,'Source-bound complete file manifest')
 for name,digest in m['files'].items():C.require(C.digest(z.read(name))==digest,'Actual archive member '+name)
 program=z.read('kernel.mjs');C.require(program==z.read('production/kernel.js') and C.digest(program)==pin['program'],'Actual qualified whole program')
 inputs=json.loads(z.read('inputs.json'));C.require(inputs['source']==pair['source'] and inputs['run']==str(pair['run']) and inputs['route']=='generated' and inputs['generatedAssertions']==853,'Exact producer controls and route')
 legacy=json.loads(z.read('retained-runtime/receipt.json'));C.require(legacy['all21QualifiedRetainedHarnessesUnchangedAndPassed'] and len(legacy['harnesses'])==21 and legacy['kernel']==pin['program'],'All21 qualified retained harnesses')
 if variant=='candidate':
  C.require(inputs['nativeSource']==pair['native']['source'] and inputs['nativeReports']==742 and inputs['all339NativeSourceSnapshotsMatchActualGit'],'Exact native-qualified cache source')
  tag='PSC1_CACHE_SCAN4_JS: PASS '
  rows=[json.loads(s[len(tag):]) for s in z.read('cache4-runtime.log').decode().splitlines() if s.startswith(tag)]
  C.require(len(rows)==1 and rows[0]['assertions']==len(rows[0]['labels'])==2097 and not rows[0]['performanceQualified'],'All2097 actual-original worker comparisons')
 else:C.require(inputs['nativeReports']==738 and inputs['all336NativeSourceSnapshotsMatchActualGit'],'Qualified public-mutual comparison baseline')
 (out/('authenticated-'+variant+'-generated.zip')).write_bytes(raw)
 (out/(variant+'.mjs')).write_bytes(program)
 return {'source':pair['source'],'run':pair['run'],'artifact':pin['artifact'],'program':pin['program'],'productionTree':pair['productionTree']}

def main():
 C.require(os.environ.get('GITHUB_ACTIONS')=='true' and os.environ.get('RUNNER_OS')=='Linux','GitHub Linux execution only')
 C.require(PAIR['rootVerified'] and PAIR['bothActualJobsPass'] and BASE['rootVerified'] and BASE['bothActualJobsPass'],'Both pairs independently root-verified before setup')
 C.require(subprocess.check_output(['git','rev-parse','HEAD:psc1/packages/pskernel-core/src'],cwd=ROOT.parent,text=True).strip()==PAIR['productionTree'],'Exact candidate production tree')
 out=Path(os.environ['RUNNER_TEMP'])/'cache-string-abba';out.mkdir()
 identity={v:qualified_program(p,out,v) for v,p in [('baseline',BASE),('candidate',PAIR)]}
 fixturePin={'artifact':12620904633,'bytes':3781052,'sha256':'6e9b9d7d5b14a5640163fc27dac8952bfc5d62fb605121cf8e5efe03ce659639','members':69}
 jobs=json.loads(C.github('/actions/runs/40251383616/jobs?per_page=100'))['jobs']
 C.require(any(j['id']==121343853332 and j['conclusion']=='success' for j in jobs),'Original authentic fixture producer job PASS')
 raw,z=archive('ff1aa23dc2c95785f5349dd7b7a022dac893f5ac',40251383616,fixturePin)
 data=z.read('_temp/psc1-t01f-generated/fixture.json')
 C.require(C.digest(data)=={'bytes':2791525,'sha256':'563d6ef138271a13039764257407ee8b66190bca02c8057489d3b1c45f51e71d'},'Exact authentic fixture bytes')
 f=json.loads(data);C.require(f['format']=='psc1-authentic-string435-v1' and f['leanCommit']=='eb6cafb7290e8bd5f2937522d8d804f58f02bafc' and len(f['declarations'])==294 and len(f['metadata'])==377 and f['samples']==['','a','é','€','😀','Aé€😀'],'All authentic declarations, metadata and samples')
 (out/'fixture.json').write_bytes(data);(out/'authenticated-fixture.zip').write_bytes(raw)
 runner=ROOT/'scripts/pskernel-expr-v2-string-environment-smoke.mjs';b=runner.read_bytes()
 C.require(C.digest(b)=={'bytes':27140,'sha256':'d3672e6105a0ddf04b52774cb841df6f26e755d66915f6cf764929faaddf69a2'} and b==subprocess.check_output(['git','show','2708d07d5827b8aca72497a1ea3de989700b6996:psc1/scripts/pskernel-expr-v2-string-environment-smoke.mjs'],cwd=ROOT.parent),'Unchanged qualified String runner')
 (out/'runner.mjs').write_bytes(b)
 node=str(Path(shutil.which('node')).resolve());version=subprocess.check_output([node,'--version'],text=True).strip();C.require(version.startswith('v22.'),'Node22')
 report={'schema':'psc1-cache-string-sample5-abba-v1','workflowSource':os.environ['GITHUB_SHA'],'workflowRun':os.environ['GITHUB_RUN_ID'],'role':'same-runner fresh-process diagnostic; not full String/performance qualification','identity':identity,'order':['baseline','candidate','candidate','baseline'],'sampleIndex':5,'sample':'Aé€😀','fuel':4096,'nodeOldSpaceMiB':2048,'deadlineSecondsPerProcess':1500,'emptyPATH':True,'requests':294,'metadata':377,'assertionsPerCompletedProcess':1400,'node':version,'observations':[],'fullKernel':False,'performanceQualified':False}
 for index,variant in enumerate(report['order']):
  log=out/(str(index)+'-'+variant+'.log');memory=out/(str(index)+'-'+variant+'.memory')
  print('PSC1_CACHE_STRING_ABBA_BEGIN '+json.dumps({'index':index,'variant':variant}),flush=True)
  command=['/usr/bin/time','-f','wallSeconds=%e maxRssKiB=%M exit=%x','-o',str(memory),'/usr/bin/timeout','--signal=KILL','1500s',node,'--max-old-space-size=2048','--expose-gc','runner.mjs',variant+'.mjs','fixture.json','5']
  started=time.monotonic()
  # All executables are absolute; the actual detached Node has empty PATH.
  with log.open('wb') as stream:r=subprocess.run(command,cwd=out,env={'PATH':'','NODE_OPTIONS':''},stdout=stream,stderr=subprocess.STDOUT,check=False)
  text=log.read_text();tag='PSC1_T01F_STRING_SHARD_JS: PASS ';rows=[json.loads(s[len(tag):]) for s in text.splitlines() if s.startswith(tag)]
  complete=r.returncode==0 and len(rows)==1
  if complete:
   receipt=rows[0];C.require(receipt['assertions']==1400 and receipt['requests']==294 and receipt['metadata']==377 and receipt['fuel']==4096 and receipt['sampleIndex']==5 and receipt['sample']=='Aé€😀' and receipt['samples']==receipt['executedSamples']==1 and receipt['independentAdmission'] and not receipt['diagnosticTracing'] and receipt['kernelSha256']==identity[variant]['program']['sha256'] and receipt['fixtureSha256']==hashlib.sha256(data).hexdigest() and receipt['harnessSha256']==hashlib.sha256(b).hexdigest(),'All unchanged selected sample assertions and exact identities')
  elapsed=time.monotonic()-started
  observation={'index':index,'variant':variant,'exitCode':r.returncode,'wallSeconds':elapsed,'complete1400':complete,'timedOut':r.returncode in (137,-9,124) and elapsed>=1499,'log':C.digest(log.read_bytes()),'memory':memory.read_text() if memory.exists() else '', 'receipt':rows[0] if len(rows)==1 else None}
  report['observations'].append(observation);C.write(out/'report.json',report)
  print('PSC1_CACHE_STRING_ABBA_END '+json.dumps(observation,separators=(',',':')),flush=True)
  C.require(complete or observation['timedOut'],'Unexpected String failure or omitted completion receipt')
 report['allFourSelectedSampleProcessesPass']=all(r['complete1400'] for r in report['observations'])
 if report['allFourSelectedSampleProcessesPass']:
  medians={v:statistics.median(r['wallSeconds'] for r in report['observations'] if r['variant']==v) for v in ['baseline','candidate']}
  report['sameRunnerDiagnosticMediansSeconds']=medians
  report['sameRunnerDiagnosticBaselineOverCandidateRatio']=medians['baseline']/medians['candidate']
 C.write(out/'report.json',report)
 files={str(p.relative_to(out)):C.digest(p.read_bytes()) for p in out.rglob('*') if p.is_file() and p.name!='files.json'}
 C.write(out/'files.json',{'source':os.environ['GITHUB_SHA'],'files':files})
 print('PSC1_CACHE_STRING_ABBA_COLLECTION: PASS '+json.dumps({'allFourSelectedSampleProcessesPass':report['allFourSelectedSampleProcessesPass'],'performanceQualified':False}))

if __name__=='__main__':main()
