"""Source-bound preview wrapper qualification. Execution is Linux Actions only."""
import hashlib,io,json,os,pathlib,shutil,subprocess,sys,urllib.request,urllib.error,zipfile
assert os.environ.get('GITHUB_ACTIONS')=='true' and os.environ.get('RUNNER_OS')=='Linux'
ROOT=pathlib.Path(__file__).resolve().parents[1]
OUT=pathlib.Path(os.environ['RUNNER_TEMP'])/'preview-supervisor'
PROGRAM='1e6f22ae728c20306755c7be10118ccc40cd449e2c7e08872a153b5aa7a7f968'
def digest(b):return {'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest()}
class NoRedirect(urllib.request.HTTPRedirectHandler):
 def redirect_request(self,req,fp,code,msg,headers,newurl):return None
def get(route):
 req=urllib.request.Request('https://api.github.com/repos/dwijayuda/pskernel'+route,headers={'Authorization':'Bearer '+os.environ['GH_TOKEN'],'Accept':'application/vnd.github+json'})
 try:return urllib.request.build_opener(NoRedirect()).open(req,timeout=120).read()
 except urllib.error.HTTPError as e:
  assert e.code in (301,302,303,307,308);return urllib.request.urlopen(e.headers['Location'],timeout=120).read()
def archive(aid,size,sha):
 metadata=json.loads(get('/actions/artifacts/'+str(aid)))
 assert metadata['size_in_bytes']==size and metadata['digest']=='sha256:'+sha and not metadata['expired']
 raw=get('/actions/artifacts/'+str(aid)+'/zip');assert digest(raw)=={'bytes':size,'sha256':sha}
 z=zipfile.ZipFile(io.BytesIO(raw));assert z.testzip() is None and len(z.namelist())==len(set(z.namelist()))
 files=json.loads(z.read('files.json'))
 if 'files' in files:files=files['files']
 assert set(files)==set(z.namelist())-{'files.json'}
 for name,pin in files.items():assert digest(z.read(name))==pin
 return z
def main():
 OUT.mkdir(exist_ok=True)
 pins=(ROOT/'scripts/pskernel-preview-axioms.json').read_bytes();obj=json.loads(pins)
 assert obj['format']=='pskernel-preview-axioms-v1' and set(obj['schemas'])=={'propext','Classical.choice','Quot.sound'}
 assert obj['leanCommit']=='eb6cafb7290e8bd5f2937522d8d804f58f02bafc'
 (OUT/'pskernel-preview-axioms.json').write_bytes(pins)
 sources={}
 for filename in ['pskernel-preview-supervisor.mjs','pskernel-preview-worker.mjs','pskernel-preview-policy.mjs','pskernel-check-export.mjs','pskernel-preview-controls.mjs','pskernel-arena-replay.mjs','pskernel-arena-replay-controls.mjs']:
  b=(ROOT/'scripts'/filename).read_bytes();sources['psc1/scripts/'+filename]=digest(b)
 for p in ['psc1/scripts/pskernel-preview-qualification.py','psc1/test/PsKernelPreviewAxiomSchemas.lean','.github/workflows/psc1-pskernel-preview-supervisor.yml']:
  sources[p]=digest((ROOT.parent/p).read_bytes())
 for p,pin in sources.items():
  actual=subprocess.check_output(['git','show',os.environ['GITHUB_SHA']+':'+p],cwd=ROOT.parent)
  assert digest(actual)==pin
  snapshot=OUT/'sources'/p;snapshot.parent.mkdir(parents=True,exist_ok=True);snapshot.write_bytes(actual)
 receipt={'format':'pskernel-preview-supervisor-qualification-v1','source':os.environ['GITHUB_SHA'],'run':os.environ['GITHUB_RUN_ID'],
  'pins':digest(pins),'sources':sources,'routes':[],'productionSourceTree':'bbe353e649feed5b796adb164dcec36eaca915ab',
  'globalStatus':'B OPEN / C FAIL / D OPEN','strictArenaPass':False,'fullPreviewQualified':False}
 node=shutil.which('node');assert node
 for route,aid,size,sha in [('generated',12705224166,1420126,'69013044b3538ff795f23eb4d0f6682904930901676c999e5d3819d6fe48206f'),
   ('canonical',12705848335,1575882,'f2d17909b4138297b1efb6ccef08022b0b8287c85691d17314207ca590f7cf28')]:
  z=archive(aid,size,sha);dest=OUT/route;dest.mkdir()
  for name in z.namelist():
   assert '/' not in name and name not in ('.','..')
   (dest/('baseline-files.json' if name=='files.json' else name)).write_bytes(z.read(name))
  assert digest((dest/'kernel.js').read_bytes())=={'bytes':10824302,'sha256':PROGRAM}
  for filename in ['pskernel-preview-supervisor.mjs','pskernel-preview-worker.mjs','pskernel-preview-policy.mjs','pskernel-arena-replay.mjs']:
   shutil.copyfile(ROOT/'scripts'/filename,dest/filename)
  shutil.copyfile(ROOT/'scripts/pskernel-check-export.mjs',dest/'check-export.mjs')
  (dest/'pskernel-preview-axioms.json').write_bytes(pins)
  log=dest/'preview-controls.log'
  with log.open('wb') as stream:
   r=subprocess.run([node,'--max-old-space-size=2048',str(ROOT/'scripts/pskernel-preview-controls.mjs'),str(dest)],env={'PATH':''},stdout=stream,stderr=subprocess.STDOUT,timeout=180)
  print(log.read_text(),flush=True);assert r.returncode==0
  controls=json.loads((dest/'preview-controls.json').read_text());assert controls['controls']==len(controls['labels'])==len(set(controls['labels'])) and controls['controls']>=55
  legacy=dest/'arena-controls.log'
  with legacy.open('wb') as stream:
   r=subprocess.run([node,'--max-old-space-size=2048',str(ROOT/'scripts/pskernel-arena-replay-controls.mjs'),str(dest/'kernel.js')],env={'PATH':''},stdout=stream,stderr=subprocess.STDOUT,timeout=600)
  assert r.returncode==0 and 'PSC1_ARENA_REPLAY_CONTROLS' in legacy.read_text()
  receipt['routes'].append({'route':route,'baselineArtifact':aid,'archive':{'bytes':size,'sha256':sha},'kernel':digest((dest/'kernel.js').read_bytes()),
    'controls':controls['controls'],'labels':controls['labels'],'controlLog':digest(log.read_bytes()),'retainedControlsLog':digest(legacy.read_bytes()),'emptyPATH':True})
  shutil.rmtree(dest/'controls')
  files={str(p.relative_to(dest)):digest(p.read_bytes()) for p in dest.rglob('*') if p.is_file() and p.name!='files.json'}
  (dest/'files.json').write_text(json.dumps(files,indent=2)+'\n')
 assert receipt['routes'][0]['labels']==receipt['routes'][1]['labels']
 (OUT/'qualification.json').write_text(json.dumps(receipt,indent=2)+'\n')
 print('PSKERNEL_PREVIEW_SUPERVISOR_QUALIFICATION: PASS '+json.dumps(receipt),flush=True)
if __name__=='__main__':main()
