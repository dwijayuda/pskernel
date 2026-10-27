"""Authenticate completed paired programs, package them, and run unchanged workload gates in Linux Actions."""
import hashlib,io,json,os,pathlib,subprocess,sys,time,urllib.request,urllib.error,zipfile,importlib.util
ROOT=pathlib.Path(__file__).resolve().parents[1]
OUT=pathlib.Path(os.environ.get('RUNNER_TEMP','.'))/'qualified-cohorts'
SPECS={'nested':{'generated':12660560142,'canonical':12661140267},'flat':{'generated':12660911999,'canonical':12659249521}}
def digest(b):return {'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest()}
def write(p,x):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(x,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
class NoRedirect(urllib.request.HTTPRedirectHandler):
 def redirect_request(self,req,fp,code,msg,headers,newurl):return None
def get(route):
 req=urllib.request.Request('https://api.github.com/repos/dwijayuda/pskernel'+route,headers={'Authorization':'Bearer '+os.environ['GH_TOKEN'],'Accept':'application/vnd.github+json'})
 try:return urllib.request.build_opener(NoRedirect()).open(req,timeout=120).read()
 except urllib.error.HTTPError as error:
  assert error.code in (301,302,303,307,308);url=error.headers['Location'];assert url.startswith('https://');return urllib.request.urlopen(url,timeout=120).read()
def load_module():
 spec=importlib.util.spec_from_file_location('independent_audit',ROOT/'scripts/pskernel-paired-cohort-audit.py');module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);return module
def prepare():
 OUT.mkdir(parents=True,exist_ok=True);audit=load_module();rows=[];bindings={}
 def git_check(source,path,data):
  actual=subprocess.check_output(['git','show',source+':'+path],cwd=ROOT.parent)
  if data is not None:assert actual==data,(source,path)
  bindings[source+':'+path]=digest(actual);return actual
 for aid,pin in audit.PINS.items():
  metadata=json.loads(get('/actions/artifacts/'+str(aid)));run=json.loads(get('/actions/runs/'+str(metadata['workflow_run']['id'])))
  assert run['status']=='completed' and run['conclusion']=='success' and run['run_attempt']==1 and run['head_sha']==metadata['workflow_run']['head_sha']
  assert metadata['size_in_bytes']==pin[0] and metadata['digest']=='sha256:'+pin[1] and not metadata['expired']
  raw=get('/actions/artifacts/'+str(aid)+'/zip');assert digest(raw)=={'bytes':pin[0],'sha256':pin[1]};(OUT/f'{aid}.zip').write_bytes(raw)
  row=audit.audit(aid,OUT,git_check);rows.append(row)
 assert rows[0]['program']==rows[1]['program'] and rows[2]['program']==rows[3]['program']
 # The completed prior ABBA is used only as an authenticated fixture container.
 # Its censored timing observations are never used as passing qualification.
 aid=12651426975;raw=get('/actions/artifacts/'+str(aid)+'/zip');fixture_archive=audit.archive(raw,(16587898,'93fae7a049235b86216514ab8190eca58d8d4b3b0b227c2561d0410a21da02d8'))
 fixture=fixture_archive.read('fixture.json');runner=fixture_archive.read('runner.mjs')
 assert digest(fixture)=={'bytes':2791525,'sha256':'563d6ef138271a13039764257407ee8b66190bca02c8057489d3b1c45f51e71d'}
 assert digest(runner)=={'bytes':27140,'sha256':'d3672e6105a0ddf04b52774cb841df6f26e755d66915f6cf764929faaddf69a2'}
 assert runner==(ROOT/'scripts/pskernel-expr-v2-string-environment-smoke.mjs').read_bytes()
 fixture_json=json.loads(fixture);assert len(fixture_json['declarations'])==294 and len(fixture_json['metadata'])==377 and fixture_json['leanCommit']=='eb6cafb7290e8bd5f2937522d8d804f58f02bafc'
 for candidate,routes in SPECS.items():
  for route,aid in routes.items():
   z=zipfile.ZipFile(OUT/f'{aid}.zip');dest=OUT/(candidate+'-'+route);dest.mkdir();program=z.read('kernel.mjs')
   for name,data in [('kernel.mjs',program),('fixture.json',fixture),('runner.mjs',runner)]: (dest/name).write_bytes(data)
   package=dest/'package';package.mkdir()
   for name in ['kernel.js','kernel.ts','kernel.d.ts','kernel.js.map']:(package/name).write_bytes(z.read('production/'+name))
   (package/'package.json').write_text(json.dumps({'name':'@pskernel/core-qualified-'+candidate,'version':'0.0.0-experimental','private':True,'type':'module','exports':{'.':{'types':'./kernel.d.ts','default':'./kernel.js'}},'engines':{'node':'>=22'}},indent=2)+'\n')
   example=z.read('sources/psc1/scripts/pskernel-generated-smoke.mjs');(package/'example.mjs').write_bytes(example)
   (package/'README.md').write_text('# PSKernel-Core experimental qualified program\n\nRequires Node 22. Run `node example.mjs ./kernel.js`. The example executes this emitted kernel with independent positive and negative controls. No Lean executable or compiler is required at runtime. Import `* as kernel` from `./kernel.js`; the adjacent declaration file gives the exported API.\n\nThis is a source-bound experimental artifact, not a release or a proof of global kernel soundness. String/Arena qualification is recorded separately. Consult `provenance.json` for exact source and producer.\n',encoding='utf-8')
   if 'canonical-source.tar.gz' in z.namelist():(package/'canonical-source.tar.gz').write_bytes(z.read('canonical-source.tar.gz'))
   provenance=next(r for r in rows if r['artifact']==aid);write(package/'provenance.json',provenance)
   node=subprocess.check_output(['which','node'],text=True).strip()
   example_result=subprocess.run([node,'--max-old-space-size=2048','example.mjs','./kernel.js'],cwd=package,env={'PATH':''},capture_output=True,timeout=300)
   (package/'example.log').write_bytes(example_result.stdout+example_result.stderr);assert example_result.returncode==0
   manifest={str(p.relative_to(package)):digest(p.read_bytes()) for p in package.rglob('*') if p.is_file()};write(package/'files.json',manifest)
 write(OUT/'audit.json',{'source':os.environ['GITHUB_SHA'],'rows':rows,'actualGitBindings':bindings,'fixture':digest(fixture),'runner':digest(runner),'noProductionAdoption':True,'globalStatus':'B OPEN / C FAIL / D OPEN'})
 print('PSC1_PAIRED_COHORT_AUDIT: PASS native807and754 compiled1188and3391 bothRoutes retained21 exactGitBindings='+str(len(bindings)),flush=True)
def string(candidate,route,index):
 dest=OUT/(candidate+'-'+route);dest.mkdir(parents=True,exist_ok=True)
 # Downloaded package is placed directly in this directory by the workflow.
 identity=json.loads((dest/'package/provenance.json').read_text());assert identity['artifact']==SPECS[candidate][route]
 for p in ['kernel.mjs','fixture.json','runner.mjs']:assert (dest/p).is_file()
 assert digest((dest/'kernel.mjs').read_bytes())==identity['program']
 node=subprocess.check_output(['which','node'],text=True).strip();start=time.monotonic()
 with (dest/'generated.log').open('wb') as stream:
  result=subprocess.run(['/usr/bin/time','-f','peak_rss_kib=%M wall_seconds=%e exit_status=%x','-o',str(dest/'generated.memory'),'timeout','--signal=KILL','1500s','env','-i','PATH=',node,'--max-old-space-size=2048','runner.mjs','./kernel.mjs','fixture.json',str(index)],cwd=dest,stdout=stream,stderr=subprocess.STDOUT)
 log=(dest/'generated.log').read_text();prefix='PSC1_T01F_STRING_SHARD_JS: PASS ';receipts=[json.loads(l[len(prefix):]) for l in log.splitlines() if l.startswith(prefix)]
 complete=False
 if len(receipts)==1:
  r=receipts[0];assert r['assertions']==1400 and r['sampleIndex']==index and r['requests']==294 and r['metadata']==377 and r['fuel']==4096 and r['independentAdmission'] and not r['diagnosticTracing']
  for key,name in [('kernelSha256','kernel.mjs'),('fixtureSha256','fixture.json'),('harnessSha256','runner.mjs')]:assert r[key]==digest((dest/name).read_bytes())['sha256']
  assert log.count('PSC1_T01F_JS_ADMIT_BEGIN ')==294;complete=result.returncode==0
 record={'candidate':candidate,'route':route,'sampleIndex':index,'program':identity['program'],'source':identity['source'],'exitCode':result.returncode,'wallSeconds':time.monotonic()-start,'complete1400':complete,'executedAssertions':1400 if complete else None,'rightCensored':result.returncode in (124,137,-9),'deadlineSeconds':1500,'fuel':4096,'oldSpaceMiB':2048,'emptyPATH':True,'receipt':receipts[0] if receipts else None,'log':digest((dest/'generated.log').read_bytes()),'memory':(dest/'generated.memory').read_text()}
 write(dest/'qualification.json',record);print(json.dumps(record,ensure_ascii=False),flush=True);assert complete,'Unchanged complete String shard failed'
def main():
 assert os.environ.get('GITHUB_ACTIONS')=='true' and os.environ.get('RUNNER_OS')=='Linux','Execution and artifact generation require GitHub Linux Actions'
 if sys.argv[1]=='prepare':prepare()
 elif sys.argv[1]=='string':string(sys.argv[2],sys.argv[3],int(sys.argv[4]))
 else:raise ValueError('Unknown mode')
if __name__=='__main__':main()
