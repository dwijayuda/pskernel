"""Independent read-only audit of actual frozen-kernel A-B-B-A artifacts."""
import hashlib
import importlib.util
import json
import os
import pathlib
import re
import statistics
import subprocess
import sys
import time

spec=importlib.util.spec_from_file_location('retained_auditor',pathlib.Path(__file__).resolve().parents[1]/'psc1-t05-audit/audit.py')
A=importlib.util.module_from_spec(spec);spec.loader.exec_module(A)
OUT=pathlib.Path(os.environ['PSC1_AUDIT_OUTPUT']);OUT.mkdir(parents=True,exist_ok=True)
CFG=json.loads(pathlib.Path(sys.argv[1]).read_text())
SOURCE=CFG['sourceSha'];RUN=CFG['runId'];ATTEMPT=CFG['runAttempt']
BASE='f091db586dcbe4a31905d6edf1c8c7957082527d'
TREE='bccb72769d4f20def35f2064363fbc94fcc7e54a'
CASES=[
 ('good','perf/repeated-subproblem.ndjson','16ad35530b3f5590d5160ad6ee5fb421b8f9629e49e340fc73016ef965785533'),
 ('good','perf/church-numerals.ndjson','85526c244d94e9710a6be432164c054c742d8f7c1d3ca0d8580d0874f7815a47'),
 ('good','init-prelude.ndjson','db35e7676c622a5da904e9cff32c761a05e389672dc5a8a5a344e1f31d378d08'),
 ('bad','bugs/proj-of-stuck-prop.ndjson','9930c5f92d12cca0ed0d4e132a2b3c7520fb2b1520de66c3bc24fdeb5895402f')]
REQUIRED={'kernel.js','kernel.ts','kernel.d.ts','kernel.js.map','bootstrap-manifest.json',
 'raw-abi.log','dag-smoke.log','paged-smoke.log','arena-controls.log','native-receipt.json',
 'native-source-audit.json','native-proofs.log','compiler-receipt.json','authentic-source.log',
 'canonical-source.log','generated-build.log','producer-tools.json','bootstrap-shared.mjs',
 'research-kernel.mjs','research-build.log'}
REPORT={'schema':'psc1-lazy-transform-abba-independent-v1','sourceSha':SOURCE,'runId':RUN,'runAttempt':ATTEMPT,
 'baselineSha':BASE,'productionTree':TREE,'sourceExecution':'none; static Git/artifact reads only',
 'status':'in_progress','errors':[],'performanceQualified':False,'fullKernel':False}
def sha(raw):return hashlib.sha256(raw).hexdigest()
def obj(files,name):return json.loads(files[name])
def require(ok,message):A.require(ok,message)
def same(x,y,message):A.same(x,y,message)
def wait():
 deadline=time.monotonic()+75*60
 while True:
  run=A.api('actions/runs/'+str(RUN))
  same(run['head_sha'],SOURCE,'exact performance source')
  same(run['run_attempt'],ATTEMPT,'exact performance attempt')
  same(run['path'],'.github/workflows/psc1-pskernel-transform-delay-abba.yml','exact comparison workflow')
  if run['status']=='completed':
   same(run['conclusion'],'success','complete comparison cohort')
   return run
  require(time.monotonic()<deadline,'bounded audit wait')
  print('PSC1_UNARY_ABBA_AUDIT_WAIT '+str(RUN),flush=True);time.sleep(45)
def main():
 require(os.environ.get('GITHUB_ACTIONS')=='true' and os.environ.get('RUNNER_OS')=='Linux','GitHub Linux audit only')
 same(subprocess.check_output(['git','-C',str(A.SOURCE_ROOT),'rev-parse','HEAD'],text=True).strip(),SOURCE,'exact performance source checkout')
 same(subprocess.check_output(['git','-C',str(A.SOURCE_ROOT),'rev-parse','HEAD:psc1/packages/pskernel-core/src'],text=True).strip(),TREE,'qualified implementation tree')
 REPORT['retainedSources']=A.unary_source_authentication()
 REPORT['sources']=A.lazy_source_authentication()
 wait()
 jobs=A.pages('actions/runs/'+str(RUN)+'/attempts/'+str(ATTEMPT)+'/jobs','jobs')
 same(sorted(j['name'] for j in jobs),sorted(['native','compiler','generated (baseline)','generated (candidate)','abba']),'five complete authentic jobs')
 require(all(j['status']=='completed' and j['conclusion']=='success' for j in jobs),'all producer and observation commands succeed')
 all_artifacts=A.pages('actions/runs/'+str(RUN)+'/artifacts','artifacts')
 names={k:'psc1-transform-delay-'+k+'-attempt-'+str(ATTEMPT) for k in ['native-preflight','compiler','baseline','candidate','abba']}
 files={};archives={}
 for key,name in names.items():
  selected=[a for a in all_artifacts if a['name']==name]
  require(len(selected)==1 and not selected[0]['expired'],'one live attempt-bound artifact: '+key)
  artifact=selected[0]
  same(artifact['workflow_run']['id'],RUN,'artifact producer run')
  same(artifact['workflow_run']['head_sha'],SOURCE,'artifact source commit')
  raw=A.request('actions/artifacts/'+str(artifact['id'])+'/zip')
  same(len(raw),artifact['size_in_bytes'],'actual archive length')
  same('sha256:'+sha(raw),artifact['digest'],'actual/API archive digest')
  files[key]=A.unzip(raw)
  archives[key]={'id':artifact['id'],**A.digest(raw),'members':len(files[key])}
 REPORT['archives']=archives
 native=files['native-preflight'];n=obj(native,'native-receipt.json')
 for key,value in [('sourceSha',SOURCE),('baselineSha',BASE),('runId',str(RUN)),('runAttempt',str(ATTEMPT)),('proofs',10)]:
  same(n[key],value,'native proof identity/count')
 same(sha(native['proofs.log']),n['proofLogSha256'],'actual ten-report log')
 same(sha(native['source-audit.json']),n['sourceAuditSha256'],'actual source audit bytes')
 reports=re.findall(r"'([^']+)' (?:depends on axioms:\s*\[([^\]]*)\]|does not depend on any axioms)",native['proofs.log'].decode())
 same([name for name,_ in reports],A.UNARY_PROOF_NAMES+[A.LAZY_NAME],'actual ten local proof statements')
 require(not any(x in native['proofs.log'].decode() for x in ['sorryAx','Lean.ofReduceBool','Lean.trustCompiler']),'no unfinished or trusted-computation dependency')
 for _,used in reports:require({x.strip() for x in used.split(',') if x.strip()}<={'propext','Classical.choice','Quot.sound'},'standard axioms only')
 inventory=obj(native,'unary/source-inventory.json')
 paths=list(A.UNARY_PINS)+['psc1/scripts/pskernel-transform-lazy-qualification.py',A.LAZY_PROOF,
  'psc1/scripts/pskernel-unary-spine-qualification.py',A.WORKFLOW,'psc1/scripts/pskernel-validator-qualification.py',
  'psc1/scripts/pskernel-arena-replay.mjs','psc1/scripts/pskernel-arena435-oracle.py','psc1/kernel-lakefile.lean','psc1/lean-toolchain']
 rows=[{'path':p,**A.digest(A.git_bytes(p))} for p in paths]
 expected_inventory={'schema':'psc1-unary-source-v1','sourceSha':SOURCE,'runId':str(RUN),'runAttempt':str(ATTEMPT),
  'productionTree':TREE,'baselineSource':'dbd9db47bd8ef184583bcd5ae3feb38f3ce612c5',
  'baselineProductionTree':'e567685e5c441a5b0a78d8241f7bae151b48b5ca','productionChanges':A.UNARY_DELTA,'files':rows,'fuel':4096}
 same(inventory,expected_inventory,'complete exact retained native snapshot inventory')
 lazy_paths=list(A.LAZY_PINS)+['psc1/scripts/pskernel-transform-lazy-qualification.py',
  '.github/workflows/psc1-pskernel-transform-lazy-native.yml','psc1/kernel-lakefile.lean','psc1/lean-toolchain',A.WORKFLOW]
 lazy_rows=[{'path':p,**A.digest(A.git_bytes(p))} for p in lazy_paths]
 lazy_source={'schema':'psc1-transform-lazy-source-v1','sourceSha':SOURCE,'runId':str(RUN),'attempt':str(ATTEMPT),
  'baselineSha':BASE,'productionTree':TREE,'productionChanges':[A.LAZY_PATH],'exactLetMotionOnly':True,
  'originalFuelAndMemoSemantics':True,'sourceSnapshots':lazy_rows,
  'predecessor':A.digest(A.lazy_normalize(A.git_bytes(A.LAZY_PATH))),'qualificationComplete':False,
  'performanceQualified':False,'adopted':False}
 same(obj(native,'lazy/source.json'),lazy_source,'complete exact lazy source inventory')
 same(native['lazy/predecessor-Transform.lean'],A.lazy_normalize(A.git_bytes(A.LAZY_PATH)),'actual frozen predecessor bytes')
 for folder,source_rows in [('unary',rows),('lazy',lazy_rows)]:
  for row in source_rows:
   raw=native[folder+'/sources/'+row['path']]
   same(raw,A.git_bytes(row['path']),'all actual archived source bytes equal immutable Git')
   same(A.digest(raw),{'bytes':row['bytes'],'sha256':row['sha256']},'actual archived source digest')
 expected_native={'source-audit.json','native-build.log','proofs.log','native-receipt.json',
  'unary/source-inventory.json','lazy/source.json','lazy/predecessor-Transform.lean'}|{'unary/sources/'+p for p in paths}|{'lazy/sources/'+p for p in lazy_paths}
 same(set(native),expected_native,'exact complete native archive membership including every hidden snapshot')
 same(len(native),31,'exact31 actual native members')
 REPORT['sourceSnapshotCoverage']={'nativeArchivedSourceFiles':len(rows)+len(lazy_rows),
  'declaredSourceFiles':len(rows)+len(lazy_rows),'distinctGitInputs':len(set(paths+lazy_paths)),
  'allDeclaredSnapshotsPresentIncludingHiddenFiles':True,'supplementRequired':False}
 audit_paths=list(dict.fromkeys(paths+lazy_paths+['psc1/scripts/pskernel-expr-v2-transform-delay-smoke.mjs',
  '.github/workflows/psc1-pskernel-transform-delay-abba.yml','psc1/scripts/pskernel-transform-delay-abba.py']))
 expected_audit={'schema':'psc1-transform-delay-source-v1','sourceSha':SOURCE,'baselineSha':BASE,'runId':str(RUN),'runAttempt':str(ATTEMPT),
  'baselineProductionTree':'62d48691ff7d9680878cf668862017d1061f2ebd','productionTree':TREE,'productionChanges':[A.LAZY_PATH],
  'retainedPositiveUnaryCongruenceShortcut':True,'exactBindingMovesOnly':True,'transformWorkerConstructionDeferred':True,
  'sourceFiles':{p:sha(A.git_bytes(p)) for p in audit_paths},'fullQualification':False,'performanceQualified':False}
 same(obj(native,'source-audit.json'),expected_audit,'entire independently reconstructed one-path native source audit')
 expected_native_receipt={'schema':'psc1-transform-delay-native-v1','sourceSha':SOURCE,'baselineSha':BASE,'runId':str(RUN),
  'runAttempt':str(ATTEMPT),'proofs':10,'names':A.UNARY_PROOF_NAMES+[A.LAZY_NAME],
  'proofLogSha256':sha(native['proofs.log']),'sourceAuditSha256':sha(native['source-audit.json']),
  'fullQualification':False,'performanceQualified':False}
 same(n,expected_native_receipt,'entire independent ten-report native receipt')
 compiler=files['compiler'];c=obj(compiler,'compiler-receipt.json')
 same(c['sourceSha'],SOURCE,'common compiler source')
 same(c['baselineSha'],BASE,'frozen baseline')
 same(sha(compiler['psc1']),c['compilerSha256'],'actual single compiler binary')
 same(sha(compiler['native-receipt.json']),c['nativeReceiptSha256'],'compiler/native provenance')
 for name,expected in c['files'].items():same(sha(compiler[name]),expected,'common compiler actual input '+name)
 same(set(compiler),set(c['files'])|{'compiler-receipt.json'}|{p for p in expected_native if p.startswith(('unary/','lazy/'))},'exact complete compiler archive membership')
 same(len(compiler),40,'exact40 actual compiler members')
 for name,raw in native.items():same(compiler[name],raw,'native/compiler evidence copy '+name)
 producer={}
 for variant in ['baseline','candidate']:
  p=files[variant];r=obj(p,'receipt.json');producer[variant]=r
  if variant=='baseline':same(A.digest(p['kernel.js']),{'bytes':10319156,'sha256':'39e06dc5d7c7c7800411354b66eed46d57318e147f98499264392f67dc819ec7'},'actual frozen qualified f091 kernel bytes')
  same(set(p),REQUIRED|{'receipt.json'},'complete exact20-file producer plus receipt')
  same(set(r['files']),REQUIRED,'declared producer inventory')
  for name,expected in r['files'].items():same(sha(p[name]),expected,'actual producer file '+variant+'/'+name)
  for key,value in [('sourceSha',SOURCE),('baselineSha',BASE),('kernelSourceSha',BASE if variant=='baseline' else SOURCE),('compilerSourceSha',SOURCE),('compilerSha256',sha(compiler['psc1'])),('runId',str(RUN)),('runAttempt',str(ATTEMPT))]:
   same(r[key],value,'producer identity and shared binary')
  same(p['compiler-receipt.json'],compiler['compiler-receipt.json'],'producer compiler receipt')
  same(p['native-receipt.json'],native['native-receipt.json'],'producer local proof receipt')
  same(p['native-proofs.log'],native['proofs.log'],'producer actual local proof log')
  same(p['native-source-audit.json'],native['source-audit.json'],'producer source audit')
  tools=obj(p,'producer-tools.json')
  same(tools['leanGitHash'],'eb6cafb7290e8bd5f2937522d8d804f58f02bafc','pinned producer Lean')
  require(tools['nodeVersion'].startswith('v22.'),'Node22 producer')
  same(tools['typescriptVersion'],'Version 7.0.2','pinned TypeScript')
  same(tools['compilerSourceSha'],SOURCE,'actual shared compiler source')
  same(tools['workflowSha256'],sha(A.git_bytes('.github/workflows/psc1-pskernel-transform-delay-abba.yml')),'actual workflow bytes')
  same(tools['driverSha256'],sha(A.git_bytes('psc1/scripts/pskernel-transform-delay-abba.py')),'actual observation driver bytes')
  bootstrap=tools['bootstrap']
  same(bootstrap['sourceGitBlob'],'734db05bccdd777f3cb1fa95aa9904e36caa9926','frozen bootstrap entry')
  same(bootstrap['sourceSha256'],sha(A.git_bytes('psc1/scripts/bootstrap-project.mjs')),'actual bootstrap source')
  same(bootstrap['adapterSha256'],sha(p['bootstrap-shared.mjs']),'actual shared-translator adapter')
  same(bootstrap['translatorSha256'],sha(compiler['psc1']),'same actual translator')
  same(bootstrap['translatorSourceSha'],SOURCE,'shared translator source')
  same(bootstrap['replacementCount'],4,'exact adapter boundary changes')
  for file,marker in [('raw-abi.log','PSC1_TRANSFORM_DELAY_RAW_JS: PASS assertions=23 exports=3 stagedArrows=11'),
      ('dag-smoke.log','PSC1_V2_DAG_JS: PASS'),('paged-smoke.log','PSC1_EXPR_V2_JS_SMOKE: PASS'),
      ('arena-controls.log','PSC1_ARENA_REPLAY_CONTROLS: PASS count=138')]:
   same(p[file].decode().splitlines().count(marker),1,'actual retained complete control '+marker)
 pair=files['abba'];report=obj(pair,'results/report.json')
 for variant in ['baseline','candidate']:
  for name,raw in files[variant].items():same(pair[variant+'/'+name],raw,'independent producer/pair equality')
 manifest=obj(pair,'results/sha256.json')
 same({p for p in pair if p.startswith('results/')},{'results/'+row['path'] for row in manifest}|{'results/sha256.json'},'complete result file manifest')
 for row in manifest:same(sha(pair['results/'+row['path']]),row['sha256'],'actual raw observation digest')
 same(set(pair),{'abba.log'}|{'results/'+row['path'] for row in manifest}|{'results/sha256.json'}|{v+'/'+p for v in ['baseline','candidate'] for p in files[v]},'complete exact comparison artifact membership')
 for key,value in [('schema','psc1-lazy-transform-abba-v1'),('sourceSha',SOURCE),('baselineSha',BASE),('runId',str(RUN)),('runAttempt',str(ATTEMPT)),('sequence',['A','B','B','A']),('freshProcessEachCase',True),('kernelFuel',4096),('hostWallSeconds',60),('nodeOldSpaceMiB',2048),('runtimePathEmpty',True),('diagnosticsComplete',True),('errors',[]),('performanceQualified',False)]:
  same(report[key],value,'actual observation identity/resources/scope')
 same(report['producerReceipts'],producer,'actual two producer receipts')
 for key,path in [('driverSha256','psc1/scripts/pskernel-transform-delay-abba.py'),('comparisonDriverSha256','psc1/scripts/pskernel-arena435-compare.py'),('oracleSha256','psc1/scripts/pskernel-arena435-oracle.py'),('replaySha256','psc1/scripts/pskernel-arena-replay.mjs')]:
  same(report[key],sha(A.git_bytes(path)),'exact original driver source')
 same(len(report['records']),16,'all sixteen actual observations')
 for position,r in enumerate(report['records']):
  round_index,index=divmod(position,4);variant=['baseline','candidate','candidate','baseline'][round_index]
  label,name,body=CASES[index]
  for key,value in [('round',round_index),('variant',variant),('index',index),('label',label),('name',name),('bodySha256',body)]:
   same(r[key],value,'fixed original case/round')
  same(obj(pair,'results/round-'+str(round_index)+'/case-'+str(index)+'/record.json'),r,'actual per-process record')
  inp=pair['results/input-'+str(index)+'.ndjson']
  same(sha(inp.partition(b'\n')[2]),body,'unchanged original declaration body')
  for key in ['original_body_sha256','adapted_body_sha256']:same(r['adaptation'][key],body,'original/adapted body identity')
  same(r['adaptation']['body_bytes_identical'],True,'header-only adaptation')
  ref=r['reference'];same(ref['verdict'],'accepted' if label=='good' else 'rejected','independent official verdict')
  raw_ref=pair['results/'+ref['log']];same(sha(raw_ref),ref['output_sha256'],'actual official reference log')
  require(('Lean default kernel accepts the solution' if label=='good' else 'Lean default kernel rejects the solution') in raw_ref.decode(),'official kernel marker')
  observed=r['observed']
  prefix='results/round-'+str(round_index)+'/case-'+str(index)+'/'
  if observed['verdict']=='timeout':
   same(observed['timeout_seconds'],60,'unchanged actual timeout')
   same(observed['stage'],'host-wall-time','actual censored host outcome')
   same(observed['returncode'],-9,'actual timed-out process killed')
   stderr=pair[prefix+observed['stderr']].decode()
   progress=[json.loads(line.split(' ',1)[1]) for line in stderr.splitlines() if line.startswith('PSC1_ARENA_PROGRESS ')]
   same(len(progress),observed['progress_snapshots'],'actual censored progress count')
   same(observed['invalid_progress_snapshots'],0,'all censored progress snapshots valid')
   require(progress and all(p.get('format')=='psc1-arena-progress-v2' for p in progress),'actual current progress envelopes')
   normalized={k:v for k,v in progress[-1].items() if k!='format'}
   same(normalized,observed['last_progress'],'actual last censored progress record')
   same(normalized.get('coreInvoked'),True,'actual kernel entry before host timeout')
   same(normalized.get('fuel'),'4096','unchanged censored fuel')
   same(normalized.get('sourceSha256'),sha(inp),'actual censored input identity')
  else:
   same(observed.get('coreInvoked'),True,'real kernel entered')
  if observed['verdict']!='timeout':
   envelope=A.one_json_line(pair[prefix+observed['stdout']].decode(),'PSC1_ARENA_REPLAY ')
   for key,value in envelope.items():same(observed.get(key),value,'actual process result envelope')
   measurement=pair[prefix+observed['time_log']].decode()
   same(int(re.search(r'Maximum resident set size \(kbytes\): (\d+)',measurement)[1]),observed['peak_rss_kib'],'actual peak RSS')
   require('--max-old-space-size=2048' in measurement,'actual unchanged V8 old-space setting')
  if index==1:
   same(observed['verdict'],'accepted','retained complete Church acceptance in both variants')
   same(observed['metadataValidated'],True,'complete regenerated Church metadata in both variants')
   same(observed['officialReplaySkipsUnsafeOrPartial'],False,'unchanged replay policy')
  if index in [0,3]:same(observed['verdict'],ref['verdict'],'retained completed semantic result')
 for index,(_,name,_) in enumerate(CASES):
  groups={v:[r['observed'] for r in report['records'] if r['name']==name and r['variant']==v] for v in ['baseline','candidate']}
  complete={v:[o for o in rows if o.get('verdict')!='timeout' and o.get('stage') not in ['host-heap','host-stack-or-allocation']] for v,rows in groups.items()}
  semantic_keys=('format','sourceSha256','verdict','stage','reason','fuel','coreInvoked','records',
   'metadataCounts','metadataCoverage','sourceMutualBlockMetadata','sourceMutualBlockMetadataRole',
   'exportedDeclarations','admissionCommands','arenaNodes','containsUnsafeOrPartial','metadataValidated',
   'officialReplaySkipsUnsafeOrPartial')
  shared_keys=('format','sourceSha256','fuel','coreInvoked','records','admissionCommands','arenaNodes',
   'containsUnsafeOrPartial','exportedDeclarations')
  for left in complete['baseline']:
   for right in complete['candidate']:
    keys=semantic_keys
    same({k:left.get(k) for k in keys},{k:right.get(k) for k in keys},'independent complete result comparison')
  bounded=all(len(rows)==2 for rows in complete.values())
  verdicts=[o.get('verdict') for rows in complete.values() for o in rows]
  comparable=bounded and len(set(verdicts))==1 and all(v in ('accepted','rejected','malformed') for v in verdicts)
  elapsed={v:[o['elapsed_seconds'] for o in rows] for v,rows in groups.items()}
  rss={v:[o['peak_rss_kib'] for o in rows if 'peak_rss_kib' in o] for v,rows in groups.items()}
  ratio=statistics.median(elapsed['candidate'])/statistics.median(elapsed['baseline']) if comparable else None
  memory=statistics.median(rss['candidate'])/statistics.median(rss['baseline']) if comparable and all(len(x)==2 for x in rss.values()) else None
  expected={'name':name,'verdicts':{v:[o['verdict'] for o in rows] for v,rows in groups.items()},
   'elapsedSeconds':elapsed,'peakRssKiB':rss,'uncensoredPair':bounded,'performanceComparable':comparable,
   'retainedChurchAcceptance':index==1,'candidateMedianTimeRatio':ratio,'candidateMedianRssRatio':memory,
   'timeRegressionOver10Percent':ratio is not None and ratio>1.10,'rssRegressionOver15Percent':memory is not None and memory>1.15}
  same(report['summaries'][index],expected,'independently recomputed paired medians/flags')
 REPORT.update({'status':'pass','nativeReports':10,'observations':16,'sameCompilerBinary':True,
  'originalChurchAcceptanceRetained':True,'summaries':report['summaries'],'performanceQualified':False})
if __name__=='__main__':
 code=0
 try:main()
 except Exception as error:REPORT['status']='fail';REPORT['errors'].append(str(error));code=1
 finally:
  raw=json.dumps(REPORT,indent=2)+'\n';(OUT/'audit.json').write_text(raw)
  print('PSC1_UNARY_ABBA_INDEPENDENT: '+REPORT['status'].upper()+' '+json.dumps(REPORT,separators=(',',':')),flush=True)
 sys.exit(code)
