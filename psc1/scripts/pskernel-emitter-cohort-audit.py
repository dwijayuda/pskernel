"""Static independent qualification audit. Does not execute any compiler or kernel."""
import hashlib,io,json,pathlib,re,statistics,tarfile,zipfile,subprocess,os
PINS={12660560142:(6386186,'5fced417f60833d95503b17cb2404cd9f644672552a8699851f8945a2a67582f'),12661140267:(6544178,'05f7dbcadb3b313cc5479199c8bcc6bd0d1196bb8e1851c2b2c174e41765ebfd'),12660911999:(12623656,'3aa38960c46f68068aa9557bcf2caf2ff9758f2833808ebc66422cea6675b1c4'),12659249521:(12774305,'d3b9d3e3b2dba85c282bbd7755e04d904a96be1a2a5066bb041314378bb3d2b5')}
def sha(b):return hashlib.sha256(b).hexdigest()
def archive(raw,pin=None):
 if pin:assert (len(raw),sha(raw))==pin
 z=zipfile.ZipFile(io.BytesIO(raw));names=z.namelist();assert len(names)==len(set(names)) and z.testzip() is None
 for p in names:
  q=pathlib.PurePosixPath(p);assert not q.is_absolute() and '..' not in q.parts and '\\' not in p and ':' not in p
 if 'files.json' in names:
  m=json.loads(z.read('files.json'));assert set(m['files'])==set(names)-{'files.json'}
  for p,v in m['files'].items():
   b=z.read(p);assert (len(b),sha(b))==(v['bytes'],v['sha256']),p
 return z
def records(z,p):
 out=[]
 for line in z.read(p).decode().splitlines():
  if ': PASS ' in line:
   tail=line.split(': PASS ',1)[1]
   if tail.startswith('{'):out.append(json.loads(tail))
  elif line.startswith('{'):out.append(json.loads(line))
 return out
def tar(z,p):
 t=tarfile.open(fileobj=io.BytesIO(z.read(p)),mode='r:gz');out={}
 for m in t.getmembers():
  assert not m.name.startswith('/') and '..' not in pathlib.PurePosixPath(m.name).parts
  if m.isdir():continue
  assert m.isfile();out[m.name.removeprefix('./')]=t.extractfile(m).read()
 return out
def audit(aid,root,git_check):
 raw=(root/f'{aid}.zip').read_bytes();z=archive(raw,PINS[aid]);inputs=json.loads(z.read('inputs.json'));source=inputs['source'];count=inputs['nativeReports'];nested=count==807
 native=archive(z.read(f'authenticated-native{count}.zip'),(1071202,'775b35eec81d674fce3b667b72b64e91140541fa3f53b4261a24de1b0c9300c2') if nested else (1008722,'90a31bc9e100904566718ddc01ef4194f72f3243a1f4db9dfa03e0dee6006444'))
 native_source=json.loads(native.read('files.json'))['source'];assert native_source==inputs['nativeSource']
 actual={};proof_modules=set()
 for p in native.namelist():
  if p.endswith('proofs.log') or p.startswith('retained561/') and p.endswith('.log'):
   text=native.read(p).decode();assert 'error:' not in text
   for name,axioms in re.findall(r"'([^']+)' (?:depends on axioms: \[([^\]]*)\]|does not depend on any axioms)",text):
    allowed=set(x.strip() for x in axioms.split(',') if x.strip());assert allowed<={'propext','Classical.choice','Quot.sound'},(p,name,allowed)
    if name in actual:assert actual[name]==sorted(allowed)
    actual[name]=sorted(allowed)
 assert len(actual)==count
 expected=set()
 for p in native.namelist():
  if not p.startswith('source/') or not p.endswith('.lean'):continue
  ns=[];names=[]
  for line in native.read(p).decode().splitlines():
   m=re.match(r'namespace\s+(\S+)',line)
   if m:ns.append(m[1])
   if re.match(r'end(?:\s+\S+)?\s*$',line) and ns:ns.pop()
   m=re.match(r'#print axioms\s+(\S+)',line)
   if m:
    name=m[1];name=name if name in actual else '.'.join(ns+[name]);names.append(name)
  # Additional diagnostic source files are retained but not selected proof roots.
  if names and all(x in actual for x in names):expected.update(names);proof_modules.add(p)
 assert expected==set(actual) and len(proof_modules)==(60 if nested else 53),(len(proof_modules),len(expected))
 retained=json.loads(native.read('source/psc1/test/retained-561-proof-manifest.json'));assert len(retained['modules'])==40 and len(retained['expectedNames'])==561
 assert set(retained['expectedNames'])<=expected
 for module in retained['modules']:
  path='psc1/test/'+module+'.lean';git_check(retained['qualifiedSource'],path,native.read('source/'+path))
 native_controls=[]
 for p in native.namelist():
  if p.endswith('native.log'):
   labels=[line for line in native.read(p).decode().splitlines() if re.match(r'PSC1_\S+_ASSERT ',line)]
   assert len(labels)==len(set(labels)),p;native_controls+=labels
 assert len(native_controls)==(1795 if nested else 3722),len(native_controls)
 bindings={}
 for p in native.namelist():
  if p.startswith('source/'):bindings[(native_source,p[7:])]=native.read(p)
 assert len(bindings)==(364 if nested else 342)
 for p in z.namelist():
  if p.startswith('sources/'):bindings[(source,p[8:])]=z.read(p)
  if p.startswith('lean-source/'):bindings[(source,'psc1/'+p[12:])]=z.read(p)
 for (s,p),b in bindings.items():git_check(s,p,b)
 lean=json.loads(z.read('lean-source-manifest.json'));assert lean['source']==source
 files={x['path']:z.read('lean-source/'+x['path']) for x in lean['files']};assert len(files)==(177 if nested else 169)
 t=tar(z,'lean-source.tar.gz');assert files==t
 packages=dict(re.findall(r'\["(\w+)", "([\w-]+)"\]',z.read('sources/psc1/scripts/workspace-layout.mjs').decode()));visited=set()
 def visit(p):
  if p in visited:return
  visited.add(p);assert p in files,p
  for name in re.findall(r'^\s*import\s+([\w.]+)\s*;?\s*$',files[p].decode(),re.M):
   parts=name.split('.');prefix='stdlib' if parts[0]=='ProofScript' else 'packages/'+packages[parts[1]]+'/src';visit(prefix+'/'+name.replace('.','/')+'.lean')
 visit(lean['entry']);assert visited==set(files)
 canonical=None
 if inputs['route']=='canonical':
  c=json.loads(z.read('canonical-manifest.json'));ps=tar(z,'canonical-source.tar.gz');paths=sorted(p[:-5]+'.ps' for p in files);assert c['generated']==paths and c['sourceCount']==len(files)
  assert {p for p in ps if p.endswith('.ps')}==set(paths)
  h=hashlib.sha256(b'proofscript-bootstrap-closure-v2\0'+c['entry'].encode()+b'\0')
  for p in paths:h.update(p.encode()+b'\0'+ps[p]+b'\0')
  assert h.hexdigest()==c['closureSha256'];canonical=h.hexdigest()
 program=z.read('kernel.mjs');assert program==z.read('production/kernel.js');mapping=json.loads(z.read('production/kernel.js.map'));assert mapping['version']==3 and mapping['sources']==['kernel.ts'];assert z.read('production/kernel.ts') and z.read('production/kernel.d.ts')
 compiler=archive(z.read('authenticated-compiler.zip'));cr=json.loads(compiler.read('compiler-receipt.json'))
 for p,v in cr['files'].items():assert sha(compiler.read(p))==v
 assert sha(compiler.read('psc1'))==inputs.get('retainedCompilerSha256',inputs['compilerSha256'])=='13635a423d1343e9a4770be0b7e02d859a6b845b221a0363d19bfdfab8e3cc1c'
 if 'retainedCompilerSha256' in inputs:
  assert inputs['compilerSource']==source and sha(z.read('modified-psc1'))==inputs['compilerSha256']
  assert not inputs['allCompilerBuildSourcesUnchanged'] and inputs['explicitCompilerChange']=='packages/backend-ts/src/Ps/BackendTs/Module.lean'
  git_check(source,'psc1/packages/backend-ts/src/Ps/BackendTs/Module.lean',z.read('actual-emitter.lean'))
  git_check(source,'psc1/scripts/pskernel-saturated-fixture-smoke.mjs',z.read('pskernel-saturated-fixture-smoke.mjs'))
  nativeGeneric=[l for l in z.read('saturated-native.log').decode().splitlines() if l.startswith('PSC1_SATURATED_TAIL_ASSERT ')]
  assert len(nativeGeneric)==len(set(nativeGeneric))==21 and 'PSC1_BACKEND_TS_TESTS: PASS' in z.read('retained-backend-tests.log').decode()
  generic,=records(z,'saturated-runtime.log');assert generic['assertions']==129 and generic['actualGenericCurriedReference'] and generic['constantStackMillionSteps']
  text=program.decode()
  for kind in ['Map','PairSet']:
   fn='psKernelExpr'+kind+'IndexBucketWorker';body=text.split('export function '+fn+'(',1)[1].split('\nexport function ',1)[0]
   assert 'while (true)' in body and '__ps$wrap' not in body and '__ps$invoke' not in body
 bindingpath='sources/psc1/test/'+('nested-public' if nested else 'flat-bucket')+'-retained-249-manifest.json';retained249=json.loads(z.read(bindingpath));assert len(retained249['bindings'])==249
 for spec in retained249['bindings']:
  p=spec['path'];b=files.get(p.removeprefix('psc1/'))
  if b is None:b=next((v for (s,path),v in bindings.items() if path==p),None)
  if b is None:
   # Any audited input outside archived snapshots must be read from the exact Git commit.
   b=git_check(source,p,None)
  actual_blob=hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest();assert actual_blob==retained249['intentionalNativeQualifiedChanges'].get(p,spec['gitBlobSha']),p
 labels={}
 for p in native.namelist():
  if p.endswith('native.log'):
   for line in native.read(p).decode().splitlines():
    m=re.match(r'(PSC1_\S+)_ASSERT (.*)',line)
    if m:labels.setdefault(m[1],[]).append(m[2])
 compiled=[];runtime=[]
 for p in z.namelist():
  if '/' not in p and (p.endswith('runtime.log') or p=='public-runtime.log'):
   for rec in records(z,p):
    values=rec.get('labels',rec.get('assertionLabels'))
    if values is not None:
     assert len(values)==len(set(values))==rec['assertions'];matches=[k for k,v in labels.items() if v==values]
     if p=='nested-public-runtime.log':matches=[x for x in matches if x=='PSC1_NESTED_PUBLIC']
     if p=='public-runtime.log':matches=[x for x in matches if x=='PSC1_MUTUAL_PUBLIC']
     assert len(matches)==1,(p,matches)
     assert not rec.get('fullKernel',False) and not rec.get('performanceQualified',False);compiled+=values;runtime.append({'log':p,'controls':len(values),'nativeTag':matches[0]})
 assert len(compiled)==(1188 if nested else 3391),len(compiled)
 legacy=json.loads(z.read('sources/psc1/test/retained-21-generated-helper-manifest.json'));receipt=json.loads(z.read('retained-runtime/receipt.json'));assert len(legacy['helpers'])==len(receipt['harnesses'])==21
 assert receipt['source']==source and receipt['kernel']=={'bytes':len(program),'sha256':sha(program)} and receipt['emptyPATH'] and receipt['oldSpaceMiB']==2048
 for spec,row in zip(legacy['helpers'],receipt['harnesses']):
  name=pathlib.PurePosixPath(spec['path']).name;b=z.read('retained-runtime/'+name);assert (len(b),sha(b))==(spec['bytes'],spec['sha256']);git_check(legacy['source'],spec['path'],b)
  log=z.read('retained-runtime/'+name[:-4]+'.log');assert (len(log),sha(log))==(row['logBytes'],row['logSha256']) and row['exitCode']==0
  assert any(l.startswith(spec['requiredFinalPassPrefix']) for l in log.decode().splitlines())
 assert inputs['privateRuntimeFuel']==256 and inputs['publicRuntimeFuel']==4096 and inputs['runtimeDeadlineSeconds']==600 and inputs['oldSpaceMiB']==2048 and inputs['emptyPATH']
 micro=None;wrappers=None
 if not nested:
  baseline=archive(z.read('authenticated-baseline748-generated.zip'));assert baseline.read('kernel.mjs')==z.read('reference-kernel.mjs') and sha(z.read('reference-kernel.mjs'))=='21cd36644cdb4baa0e0beb4cac1337f4ea6092c1c930b72a670ab0c2909765b0'
  line,=[l for l in z.read('flat-bucket-runtime.log').decode().splitlines() if l.startswith('PSC1_FLAT_BUCKET_MICRO: ')];micro=json.loads(line.split(': ',1)[1]);micro['candidateOverBaselineMedian']={k:statistics.median(x['milliseconds'] for x in micro['rows'] if x['kind']==k and x['variant']=='B')/statistics.median(x['milliseconds'] for x in micro['rows'] if x['kind']==k and x['variant']=='A') for k in ['map','pair']}
  text=program.decode();wrappers={}
  for kind in ['Map','PairSet']:
   if 'retainedCompilerSha256' in inputs:
    fn='psKernelExpr'+kind+'IndexBucketWorker';body=text.split('export function '+fn+'(',1)[1].split('\nexport function ',1)[0];assert 'while (true)' in body and '__ps$wrap' not in body and '__ps$invoke' not in body;wrappers[kind]={'wrapperCalls':0,'loop':True,'mechanismComplete':True}
   else:
    fn='psKernelExpr'+kind+'IndexBucketWorker_$psc0SH_0';body=text.split('function* __ps$impl$'+fn+'(',1)[1].split('__ps$implementations.set('+fn,1)[0];wrappers[kind]={'wrapperCalls':body.count('__ps$wrap('),'recursiveHelperReferences':body.count(fn),'mechanismComplete':False};assert body.count('__ps$wrap(')>0
 return {'artifact':aid,'archiveBytes':len(raw),'archiveSha256':sha(raw),'members':len(z.namelist()),'manifestDigests':len(z.namelist())-1,'source':source,'route':inputs['route'],'nativeProofReports':count,'nativeProofModules':len(proof_modules),'nativeControls':len(native_controls),'nativeGitSources':364 if nested else 342,'archiveGitBindings':len(bindings),'completeLeanModules':len(files),'canonicalClosureSha256':canonical,'program':{'bytes':len(program),'sha256':sha(program)},'compiledControls':len(compiled),'runtimeCohorts':runtime,'retainedHarnesses':21,'actualAuditedGitBindings':249,'resourcePolicyPreserved':True,'focusedMicro':micro,'emittedWorkerReview':wrappers,'productionAdopted':False,'wholeWorkloadPerformanceQualified':False,'globalSoundnessProved':False}
def main():
 root=pathlib.Path(__file__).parent;cache={};receipt=json.loads((root/'actual-git-bindings.json').read_text())['bindings']
 def check(s,p,b):
  key=s+'/'+p
  if b is None:
   import urllib.request
   b=urllib.request.urlopen('https://raw.githubusercontent.com/dwijayuda/pskernel/'+key,timeout=60).read()
  if key in receipt:assert sha(b)==receipt[key]
  else:
   import urllib.request
   assert b==urllib.request.urlopen('https://raw.githubusercontent.com/dwijayuda/pskernel/'+key,timeout=60).read()
  cache[key]=sha(b);return b
 rows=[]
 for aid in PINS:
  row=audit(aid,root,check);rows.append(row);print(json.dumps({k:v for k,v in row.items() if k not in ['runtimeCohorts','focusedMicro']},ensure_ascii=False))
 assert rows[0]['program']==rows[1]['program'] and rows[2]['program']==rows[3]['program']
 (root/'paired-audit-result.json').write_text(json.dumps({'rows':rows,'independentlyReadGitBindings':len(cache)},indent=2),encoding='utf-8')
if __name__=='__main__':main()
