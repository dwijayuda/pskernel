"""Package only source-qualified programs; retain failed global gates explicitly."""
import hashlib,io,json,os,pathlib,shutil,subprocess,urllib.request,urllib.error,zipfile
assert os.environ.get('GITHUB_ACTIONS')=='true' and os.environ.get('RUNNER_OS')=='Linux'
ROOT=pathlib.Path(__file__).resolve().parents[1];OUT=pathlib.Path(os.environ['RUNNER_TEMP'])/'runtime-delivery';OUT.mkdir()
def digest(b):return {'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest()}
class NoRedirect(urllib.request.HTTPRedirectHandler):
 def redirect_request(self,req,fp,code,msg,headers,newurl):return None
def get(route):
 req=urllib.request.Request('https://api.github.com/repos/dwijayuda/pskernel'+route,headers={'Authorization':'Bearer '+os.environ['GH_TOKEN'],'Accept':'application/vnd.github+json'})
 try:return urllib.request.build_opener(NoRedirect()).open(req,timeout=120).read()
 except urllib.error.HTTPError as error:
  assert error.code in (301,302,303,307,308);return urllib.request.urlopen(error.headers['Location'],timeout=120).read()
def archive(aid,pin):
 raw=get('/actions/artifacts/'+str(aid)+'/zip');assert digest(raw)==pin
 z=zipfile.ZipFile(io.BytesIO(raw));assert z.testzip() is None and len(z.namelist())==len(set(z.namelist()));return z
evidence=OUT/'evidence';evidence.mkdir();rows=[];arena=[]
for a in json.loads((ROOT/'test/runtime-delivery-targets-20261027.json').read_text()):
 pin={'bytes':a['size_in_bytes'],'sha256':a['digest'].removeprefix('sha256:')};z=archive(a['id'],pin)
 if 'cohort-string' in a['name']:
  r=json.loads(z.read('qualification.json'));assert r['log']==digest(z.read('generated.log'));assert r['memory']==z.read('generated.memory').decode()
  if r['complete1400']:
   prefix='PSC1_T01F_STRING_SHARD_JS: PASS ';actual,=[json.loads(l[len(prefix):]) for l in z.read('generated.log').decode().splitlines() if l.startswith(prefix)];assert actual==r['receipt'] and actual['assertions']==1400 and actual['fuel']==4096 and actual['requests']==294 and actual['metadata']==377 and actual['diagnosticTracing']==False
  rows.append({'artifact':a['id'],'archive':pin,'receipt':r})
 else:
  r=json.loads(z.read('report.json'));assert r['total']==len(r['tests'])==193 and r['kernel_fuel']==4096 and r['host_timeout_seconds_per_case']==60 and r['node_heap_limit_mib']==2048 and r['host_workers']==2 and r['excluded_cases']==[]
  assert r['counts']['pskernel_timeout']==17 and r['counts']['agreement_with_unsafe_or_partial_contract_difference']==2 and r['actual_matched_cases']==174 and not r['arena_comparison_complete']
  arena.append({'artifact':a['id'],'archive':pin,'report':r})
 assert all(t['adaptation']['body_bytes_identical'] for x in arena for t in x['report']['tests'])
for route in ['generated','canonical']:
 selected=[x['receipt'] for x in rows if x['receipt']['candidate']=='nested' and x['receipt']['route']==route]
 assert len(selected)==6 and {r['sampleIndex'] for r in selected}==set(range(6)) and all(r['complete1400'] and r['exitCode']==0 for r in selected)
 assert sum(r['receipt']['assertions'] for r in selected)==8400
assert len(rows)==24 and len(arena)==2
failed=[x['receipt'] for x in rows if not x['receipt']['complete1400']];assert len(failed)==1 and failed[0]['candidate']=='flat' and failed[0]['route']=='canonical' and failed[0]['sampleIndex']==5 and failed[0]['rightCensored'] and failed[0]['deadlineSeconds']==1500
audit=archive(12704671927,{'bytes':64069,'sha256':'483b58d8d515d4ee78af5986fca31d8fa1f202a78d76a192c4c45aa3fd5121ed'});independent=json.loads(audit.read('audit.json'));assert len(independent['actualGitBindings'])==1210
(evidence/'independent-paired-audit.json').write_bytes(audit.read('audit.json'))
(evidence/'full-workload-receipts.json').write_text(json.dumps({'qualificationRun':40436829581,'strings':rows,'arena':arena,'globalStatus':'B OPEN / C FAIL / D OPEN','productionAdopted':False,'wholeKernelSpeedupEstablished':False},indent=2,ensure_ascii=False)+'\n')
node=shutil.which('node');assert node
for route,aid,size,sha in [('generated',12660560142,6386186,'5fced417f60833d95503b17cb2404cd9f644672552a8699851f8945a2a67582f'),('canonical',12661140267,6544178,'05f7dbcadb3b313cc5479199c8bcc6bd0d1196bb8e1851c2b2c174e41765ebfd')]:
 z=archive(aid,{'bytes':size,'sha256':sha});manifest=json.loads(z.read('files.json'))
 for name,pin in manifest['files'].items():assert digest(z.read(name))==pin
 dest=OUT/route;dest.mkdir()
 for name in ['kernel.js','kernel.ts','kernel.d.ts','kernel.js.map']:(dest/name).write_bytes(z.read('production/'+name))
 assert digest((dest/'kernel.js').read_bytes())=={'bytes':10824302,'sha256':'1e6f22ae728c20306755c7be10118ccc40cd449e2c7e08872a153b5aa7a7f968'}
 (dest/'example.mjs').write_bytes(z.read('sources/psc1/scripts/pskernel-generated-smoke.mjs'))
 (dest/'nested-example.mjs').write_bytes(z.read('pskernel-nested-public-complete-smoke.mjs'))
 (dest/'api-example.mjs').write_bytes((ROOT/'scripts/pskernel-public-api-example.mjs').read_bytes())
 (dest/'README.md').write_bytes((ROOT/'packages/pskernel-core/docs/QUALIFIED_RUNTIME_2026-10-27.md').read_bytes())
 (dest/'lean-source.tar.gz').write_bytes(z.read('lean-source.tar.gz'))
 if 'canonical-source.tar.gz' in z.namelist():(dest/'canonical-source.tar.gz').write_bytes(z.read('canonical-source.tar.gz'))
 (dest/'package.json').write_text(json.dumps({'name':'@pskernel/core-nested-experimental','version':'0.0.0-20261027','private':True,'type':'module','exports':{'.':{'types':'./kernel.d.ts','default':'./kernel.js'}},'engines':{'node':'>=22'}},indent=2)+'\n')
 checks=[]
 for example,arguments,prefix in [('api-example.mjs',[],'PSKERNEL_PUBLIC_API_EXAMPLE: PASS '),('example.mjs',['./kernel.js'],'PSKERNEL_GENERATED_SMOKE: PASS'),('nested-example.mjs',['./kernel.js'],'PSC1_NESTED_PUBLIC_COMPLETE_JS: PASS ')]:
  r=subprocess.run([node,'--max-old-space-size=2048',example,*arguments],cwd=dest,env={'PATH':''},capture_output=True,timeout=600);log=r.stdout+r.stderr;(dest/(example+'.log')).write_bytes(log);assert r.returncode==0 and any(l.startswith(prefix) for l in log.decode().splitlines())
  checks.append({'example':example,'exitCode':r.returncode,'log':digest(log),'emptyPATH':True,'oldSpaceMiB':2048})
 record={'producerSource':'e58ef33ad14b26dcc85231801b1322551cf34614','producerRun':40337754189,'producerArtifact':aid,'route':route,'deliverySource':os.environ['GITHUB_SHA'],'deliveryRun':os.environ['GITHUB_RUN_ID'],'kernel':digest((dest/'kernel.js').read_bytes()),'nativeReports':807,'compiledControls':1188,'retainedHarnesses':21,'fullStringAssertions':8400,'arenaStrictPass':False,'arenaTimeouts':17,'safetyContractDifferences':2,'globalStatus':'B OPEN / C FAIL / D OPEN','logicalSoundnessProved':False,'backendPreservationProved':False,'compilerSelfHostQualified':False,'examples':checks}
 (dest/'provenance.json').write_text(json.dumps(record,indent=2)+'\n');files={p.name:digest(p.read_bytes()) for p in dest.iterdir() if p.is_file()};(dest/'files.json').write_text(json.dumps(files,indent=2)+'\n')
 print('PSC1_USABLE_NESTED_PACKAGE: PASS '+json.dumps(record),flush=True)
