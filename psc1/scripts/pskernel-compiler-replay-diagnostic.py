"""Inventory and attempt replay of the actual portable compiler declaration closure.
Diagnostic completion is never compiler self-host qualification.
"""
import hashlib,io,json,os,pathlib,re,shutil,subprocess,time,urllib.request,urllib.error,zipfile
assert os.environ.get('GITHUB_ACTIONS')=='true' and os.environ.get('RUNNER_OS')=='Linux'
ROOT=pathlib.Path(__file__).resolve().parents[1];OUT=pathlib.Path(os.environ['RUNNER_TEMP'])/'compiler-replay';OUT.mkdir()
def digest(b):return {'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest()}
def write(name,value):(OUT/name).write_text(json.dumps(value,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
class NoRedirect(urllib.request.HTTPRedirectHandler):
 def redirect_request(self,req,fp,code,msg,headers,newurl):return None
def get(route):
 req=urllib.request.Request('https://api.github.com/repos/dwijayuda/pskernel'+route,headers={'Authorization':'Bearer '+os.environ['GH_TOKEN'],'Accept':'application/vnd.github+json'})
 try:return urllib.request.build_opener(NoRedirect()).open(req,timeout=120).read()
 except urllib.error.HTTPError as e:
  assert e.code in (301,302,303,307,308);return urllib.request.urlopen(e.headers['Location'],timeout=120).read()
def archive(aid,size,sha,name):
 meta=json.loads(get('/actions/artifacts/'+str(aid)));assert meta['size_in_bytes']==size and meta['digest']=='sha256:'+sha and not meta['expired']
 raw=get('/actions/artifacts/'+str(aid)+'/zip');assert digest(raw)=={'bytes':size,'sha256':sha};(OUT/name).write_bytes(raw);z=zipfile.ZipFile(io.BytesIO(raw));assert z.testzip() is None and len(z.namelist())==len(set(z.namelist()));return z
compiler_source='14dad2ce6eaef9fa71170f28650a5c626eca4a76'
c=archive(12606866673,2561674,'c28da8d4d57a5a59a1ff686b2ce671102b20073bd00bf32450fae37cf2ab8dec','compiler.zip');receipt=json.loads(c.read('compiler-receipt.json'))
for p,sha in receipt['files'].items():assert hashlib.sha256(c.read(p)).hexdigest()==sha
binary=c.read('psc1');assert digest(binary)['sha256']=='13635a423d1343e9a4770be0b7e02d859a6b845b221a0363d19bfdfab8e3cc1c'
exe=OUT/'psc1';exe.write_bytes(binary);exe.chmod(0o700)
packages=[str(p.relative_to(ROOT.parent)) for p in (ROOT/'packages').iterdir() if p.is_dir() and p.name!='pskernel-core']
subprocess.run(['git','diff','--exit-code',compiler_source,'HEAD','--',*packages,'psc1/host','psc1/stdlib','psc1/lakefile.lean','psc1/lake-manifest.json','psc1/lean-toolchain','psc1/psconfig.json'],cwd=ROOT.parent,check=True)
k=archive(12660560142,6386186,'5fced417f60833d95503b17cb2404cd9f644672552a8699851f8945a2a67582f','qualified-nested.zip')
m=json.loads(k.read('files.json'))
for p,d in m['files'].items():assert digest(k.read(p))==d
kernel=k.read('kernel.mjs');assert digest(kernel)['sha256']=='1e6f22ae728c20306755c7be10118ccc40cd449e2c7e08872a153b5aa7a7f968'
detached=OUT/'detached';(detached/'scripts').mkdir(parents=True);(detached/'npm-runtime').mkdir()
(detached/'kernel.mjs').write_bytes(kernel)
for p in ['scripts/pskernel-canonical-provider.mjs','npm-runtime/canonical-admissions-wire.mjs']:(detached/p).write_bytes((ROOT/p).read_bytes())
mapping=dict(re.findall(r'\["(\w+)", "([\w-]+)"\]',(ROOT/'scripts/workspace-layout.mjs').read_text()))
entry='packages/bootstrap/src/Ps/Bootstrap/SelfHost.lean';seen={}
def visit(path):
 if path in seen:return
 data=(ROOT/path).read_bytes();actual=subprocess.check_output(['git','show','HEAD:psc1/'+path],cwd=ROOT.parent);assert data==actual;seen[path]=digest(data)
 target=OUT/'source'/path;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
 for name in re.findall(r'^\s*import\s+([\w.]+)\s*;?\s*$',data.decode(),re.M):
  pieces=name.split('.');prefix='stdlib' if pieces[0]=='ProofScript' else 'packages/'+mapping[pieces[1]]+'/src';visit(prefix+'/'+name.replace('.','/')+'.lean')
visit(entry)
assert all(any(p.endswith(name) for p in seen) for name in ['/Ps/Compiler/Api.lean','/Ps/Elab/Declaration.lean','/Ps/BackendTs/Compiler.lean'])
write('inventory.json',{'source':os.environ['GITHUB_SHA'],'entry':entry,'modules':seen,'sourceCount':len(seen),'scope':'Actual portable compiler library closure; excludes the host IO CLI and its external provider. Compilation is not replay or a fixed-point proof.'})
start=time.monotonic()
with (OUT/'admissions.json').open('wb') as output,(OUT/'export.stderr').open('wb') as errors:
 result=subprocess.run(['timeout','--signal=KILL','1800s',str(exe),'admissions',entry],cwd=ROOT,stdout=output,stderr=errors)
record={'source':os.environ['GITHUB_SHA'],'run':os.environ['GITHUB_RUN_ID'],'entry':entry,'compilerSource':compiler_source,'compiler':digest(binary),'kernelSource':'e58ef33ad14b26dcc85231801b1322551cf34614','kernel':digest(kernel),'sourceCount':len(seen),'exportExitCode':result.returncode,'exportWallSeconds':time.monotonic()-start,'exportStdout':digest((OUT/'admissions.json').read_bytes()),'exportStderr':(OUT/'export.stderr').read_text(errors='replace'),'compilerDeclarationsCheckedByPSKernel':False,'compilerFixedPointEstablished':False,'backendPreservationProved':False,'selfHostQualified':False,'diagnosticOnly':True}
if result.returncode==0:
 admissions=json.loads((OUT/'admissions.json').read_text());assert admissions['format']=='proofscript-checked-admissions';record['declarationsExported']=len(admissions['admissions']);record['admissionVariantCounts']={}
 for row in admissions['admissions']:
  kind=row.get('kind',row.get('tag','unknown'));record['admissionVariantCounts'][kind]=record['admissionVariantCounts'].get(kind,0)+1
 node=shutil.which('node');assert node
 with (OUT/'admissions.json').open('rb') as source,(OUT/'replay.stdout').open('wb') as output,(OUT/'replay.stderr').open('wb') as errors:
  replay=subprocess.run(['timeout','--signal=KILL','1500s',node,'--max-old-space-size=2048','scripts/pskernel-canonical-provider.mjs','kernel.mjs'],cwd=detached,env={'PATH':''},stdin=source,stdout=output,stderr=errors)
 record['replayExitCode']=replay.returncode;record['replayStdout']=(OUT/'replay.stdout').read_text(errors='replace');record['replayStderr']=(OUT/'replay.stderr').read_text(errors='replace');record['replayEmptyPATH']=True;record['replayDeadlineSeconds']=1500;record['replayOldSpaceMiB']=2048
 write('receipt.json',record)
else:
 record['blockingStage']='actual compiler declaration export';write('receipt.json',record)
print('PSC1_COMPILER_REPLAY_DIAGNOSTIC_RECORDED '+json.dumps(record,ensure_ascii=False),flush=True)
