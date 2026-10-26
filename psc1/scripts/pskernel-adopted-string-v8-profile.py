"""GitHub Linux-only String sample5 observation; never full qualification."""
from pathlib import Path,PurePosixPath
import hashlib,importlib.util,io,json,os,re,shutil,stat,statistics,subprocess,time,zipfile

BASE={'rootVerified': True, 'bothActualJobsPass': True, 'source': '86d27f71dd1340d5f3d37a851f0ac85a40649b6a', 'run': 40304110450, 'productionTree': 'cada4884b4250a708dccadca42b8ef5bddbd04a3', 'native': {'source': '945d2c06b22c59e2bf4502e329403df62ae5915c', 'run': 40303319691, 'job': 121506227524, 'artifact': 12640944810, 'bytes': 999888, 'sha256': '582a93b1c52b424ab2578ae990e12b9ff6799fd680714e02154dc18eaa38685d', 'members': 412, 'proofs': 748}, 'routes': {'generated': {'artifact': 12642078456, 'job': 121508849440, 'bytes': 6178572, 'sha256': '4430461a46133e2014df1798b55cd0c912a16575cdd9025a9b14b502fbb4d8cc', 'members': 281, 'program': {'bytes': 10607234, 'sha256': '21cd36644cdb4baa0e0beb4cac1337f4ea6092c1c930b72a670ab0c2909765b0'}}, 'canonical': {'artifact': 12643381412, 'job': 121508849752, 'bytes': 6329114, 'sha256': 'a04f3944db8e117175f4e5df9e4f9300b58da91e666bbce84ba92cb9ddc4822a', 'members': 285, 'program': {'bytes': 10607234, 'sha256': '21cd36644cdb4baa0e0beb4cac1337f4ea6092c1c930b72a670ab0c2909765b0'}}}, 'bothCompleteProgramsByteIdentical': True, 'full193Qualified': False, 'performanceQualified': False}
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
  C.require(inputs['nativeSource']==pair['native']['source'] and inputs['nativeReports']==750 and inputs['all342NativeSourceSnapshotsMatchActualGit'],'Exact native-qualified cache source')
  tag='PSC1_PACKED_CACHE_JS: PASS '
  rows=[json.loads(s[len(tag):]) for s in z.read('packed-runtime.log').decode().splitlines() if s.startswith(tag)]
  C.require(len(rows)==1 and rows[0]['assertions']==len(rows[0]['labels'])==2400 and not rows[0]['performanceQualified'],'All2400 actual-original scalar analysis comparisons')
 else:C.require(inputs['nativeReports']==748 and inputs['all340NativeSourceSnapshotsMatchActualGit'],'Qualified corrected-Rebase comparison baseline')
 (out/('authenticated-'+variant+'-generated.zip')).write_bytes(raw)
 (out/(variant+'.mjs')).write_bytes(program)
 return {'source':pair['source'],'run':pair['run'],'artifact':pin['artifact'],'program':pin['program'],'productionTree':pair['productionTree']}

def main():
 C.require(os.environ.get('GITHUB_ACTIONS')=='true' and os.environ.get('RUNNER_OS')=='Linux','GitHub Linux execution only')
 C.require(subprocess.check_output(['git','rev-parse','HEAD:psc1/packages/pskernel-core/src'],cwd=ROOT.parent,text=True).strip()==BASE['productionTree'],'Exact adopted corrected production tree; no cache candidate')
 out=Path(os.environ['RUNNER_TEMP'])/'string-v8-profile';out.mkdir()
 identity=qualified_program(BASE,out,'baseline')
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
 report={'schema':'psc1-adopted-string-v8-profile-v1','source':os.environ['GITHUB_SHA'],'run':os.environ['GITHUB_RUN_ID'],'identity':identity,'role':'diagnostic sampling only; timings never performance qualification','sampleIndex':5,'sample':'Aé€😀','requests':294,'metadata':377,'fuel':4096,'nodeOldSpaceMiB':2048,'deadlineSeconds':1500,'emptyPATH':True,'node':version,'profiling':'V8 --prof; original program and runner bytes unchanged','fullKernel':False,'performanceQualified':False}
 log=out/'runtime.log';memory=out/'runtime.memory';started=time.monotonic()
 command=['/usr/bin/time','-f','wallSeconds=%e maxRssKiB=%M exit=%x','-o',str(memory),'/usr/bin/timeout','--signal=KILL','1500s',node,'--prof','--max-old-space-size=2048','--expose-gc','runner.mjs','baseline.mjs','fixture.json','5']
 with log.open('wb') as stream:execution=subprocess.run(command,cwd=out,env={'PATH':'','NODE_OPTIONS':''},stdout=stream,stderr=subprocess.STDOUT,check=False)
 elapsed=time.monotonic()-started;text=log.read_text();tag='PSC1_T01F_STRING_SHARD_JS: PASS ';receipts=[json.loads(line[len(tag):]) for line in text.splitlines() if line.startswith(tag)]
 complete=execution.returncode==0 and len(receipts)==1
 censored=execution.returncode in (137,-9,124) and elapsed>=1499
 if complete:
  receipt=receipts[0];C.require(receipt['assertions']==1400 and receipt['requests']==294 and receipt['metadata']==377 and receipt['fuel']==4096 and receipt['sampleIndex']==5 and receipt['independentAdmission'] and not receipt['diagnosticTracing'] and receipt['kernelSha256']==identity['program']['sha256'] and receipt['fixtureSha256']==hashlib.sha256(data).hexdigest() and receipt['harnessSha256']==hashlib.sha256(b).hexdigest(),'All unchanged1400 assertions and actual identities')
 C.require(complete or censored,'Unexpected profiled runtime failure; no correctness qualification')
 profiles=sorted(out.glob('isolate-*-v8.log'));C.require(len(profiles)==1 and profiles[0].stat().st_size>0,'Actual V8 tick log exists even for censored process')
 with (out/'profile-summary.txt').open('wb') as stream:analysis=subprocess.run([node,'--max-old-space-size=2048','--prof-process',profiles[0].name],cwd=out,stdout=stream,stderr=subprocess.STDOUT,timeout=180,check=False)
 report.update({'runtimeExitCode':execution.returncode,'observedWallSeconds':elapsed,'completed1400':complete,'rightCensoredAt1500':censored,'receipt':receipts[0] if len(receipts)==1 else None,'runtimeLog':C.digest(log.read_bytes()),'runtimeMemory':memory.read_text(),'tickLog':{'path':profiles[0].name,**C.digest(profiles[0].read_bytes())},'profileProcessorExitCode':analysis.returncode,'profileSummary':C.digest((out/'profile-summary.txt').read_bytes()),'timedOutWrapperRssIsNotNodePeak':censored})
 C.write(out/'report.json',report)
 C.require(analysis.returncode==0,'Actual Node V8 tick-log processing completed')
 files={str(p.relative_to(out)):C.digest(p.read_bytes()) for p in out.rglob('*') if p.is_file() and p.name!='files.json'}
 C.write(out/'files.json',{'source':os.environ['GITHUB_SHA'],'files':files})
 print('PSC1_ADOPTED_STRING_V8_PROFILE_COLLECTION: PASS '+json.dumps(report,separators=(',',':')))

if __name__=='__main__':main()
