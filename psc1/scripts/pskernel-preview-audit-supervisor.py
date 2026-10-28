"""Static inspection of downloaded Linux CI archives. Executes no checked code."""
import hashlib,json,pathlib,re,sys,urllib.request,zipfile
metadataPath=pathlib.Path(sys.argv[1]).resolve();root=metadataPath.parent
a=json.loads(metadataPath.read_text())[0]
raw=(root/(str(a['id'])+'.zip')).read_bytes()
def digest(b):return {'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest()}
assert digest(raw)=={'bytes':a['size_in_bytes'],'sha256':a['digest'].removeprefix('sha256:')}
z=zipfile.ZipFile(root/(str(a['id'])+'.zip'));assert z.testzip() is None and len(z.namelist())==len(set(z.namelist()))
for p in z.namelist():z.read(p)
prefix=next(p.removesuffix('qualification.json') for p in z.namelist() if p=='qualification.json' or p.endswith('/qualification.json'))
r=json.loads(z.read(prefix+'qualification.json'));assert r['source']==a['workflow_run']['head_sha'] and int(r['run'])==a['workflow_run']['id']
pins=z.read(prefix+'pskernel-preview-axioms.json');assert digest(pins)==r['pins'];p=json.loads(pins)
assert p['leanCommit']=='eb6cafb7290e8bd5f2937522d8d804f58f02bafc' and set(p['schemas'])=={'propext','Classical.choice','Quot.sound'}
assert r['productionSourceTree']=='bbe353e649feed5b796adb164dcec36eaca915ab' and r['globalStatus']=='B OPEN / C FAIL / D OPEN' and not r['strictArenaPass'] and not r['fullPreviewQualified']
source_bytes={}
for path,pin in r['sources'].items():
 b=urllib.request.urlopen('https://raw.githubusercontent.com/dwijayuda/pskernel/'+r['source']+'/'+path,timeout=60).read()
 assert digest(b)==pin;source_bytes[path]=b
 if prefix+'sources/'+path in z.namelist():assert z.read(prefix+'sources/'+path)==b
rows=[]
for row in r['routes']:
 route=row['route'];base=prefix+route+'/'
 manifest=json.loads(z.read(base+'files.json'));assert set(manifest)=={p.removeprefix(base) for p in z.namelist() if p.startswith(base)}-{'files.json'}
 for name,pin in manifest.items():assert digest(z.read(base+name))==pin,name
 program=z.read(base+'kernel.js');assert digest(program)==row['kernel']=={'bytes':10824302,'sha256':'1e6f22ae728c20306755c7be10118ccc40cd449e2c7e08872a153b5aa7a7f968'}
 assert z.read(base+'pskernel-preview-axioms.json')==pins
 for path,b in source_bytes.items():
  filename='check-export.mjs' if path.endswith('/pskernel-check-export.mjs') else pathlib.PurePosixPath(path).name
  if base+filename in z.namelist():assert z.read(base+filename)==b
 controls=json.loads(z.read(base+'preview-controls.json'));log=z.read(base+'preview-controls.log');legacy=z.read(base+'arena-controls.log')
 assert digest(log)==row['controlLog'] and digest(legacy)==row['retainedControlsLog']
 labels=[line.removeprefix('PSKERNEL_PREVIEW_CONTROL ') for line in log.decode().splitlines() if line.startswith('PSKERNEL_PREVIEW_CONTROL ')]
 assert labels==row['labels']==controls['labels'] and len(labels)==len(set(labels))==controls['controls']==row['controls']
 assert 'PSKERNEL_PREVIEW_CONTROLS: PASS '+json.dumps({'controls':len(labels)},separators=(',',':')) in log.decode()
 assert re.search(r'^PSC1_ARENA_REPLAY_CONTROLS: PASS count=\d+$',legacy.decode(),re.M)
 for name in ['positive','negative']:
  v=controls[name];assert v['host']['workerReaped'] and v['host']['exitCode']==0 and v['program']==row['kernel'] and v['assumptionPolicy']['sha256']==r['pins']['sha256']
  assert v['checking']['coreInvoked'] and v['outcome']==('accepted' if name=='positive' else 'rejectedInvalid')
  assert v['checking']['metadataValidated']==(name=='positive') and not v['logicalSoundnessProved'] and not v['strictArenaCompatibility']
 assert controls['emptyPATH'] and controls['oldSpaceMiB']==2048 and controls['faultFixturesAreTrustedTestInputs']
 rows.append({'route':route,'controls':len(labels),'manifestFiles':len(manifest),'kernel':digest(program)})
assert len(rows)==2 and rows[0]['kernel']==rows[1]['kernel']
summary={'artifact':a['id'],'archive':digest(raw),'members':len(z.namelist()),'source':r['source'],'sourceBindings':len(source_bytes),'pins':r['pins'],'rows':rows,'fullPreviewQualified':False}
(root/('preview-static-audit-'+str(a['id'])+'.json')).write_text(json.dumps(summary,indent=2)+'\n')
print(json.dumps(summary,indent=2))
