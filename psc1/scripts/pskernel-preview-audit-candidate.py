"""Static independent review of candidate archives and nested raw evidence."""
import hashlib,io,json,pathlib,re,sys,urllib.request,zipfile
metadataPath=pathlib.Path(sys.argv[1]).resolve();root=metadataPath.parent
metadata=json.loads(metadataPath.read_text())
def digest(b):return {'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest()}
def archive(b):
 z=zipfile.ZipFile(io.BytesIO(b));assert z.testzip() is None and len(z.namelist())==len(set(z.namelist()))
 for p in z.namelist():
  assert not p.startswith('/') and '..' not in pathlib.PurePosixPath(p).parts
  z.read(p)
 return z
items={}
for a in metadata:
 b=(root/(str(a['id'])+'.zip')).read_bytes();assert digest(b)=={'bytes':a['size_in_bytes'],'sha256':a['digest'].removeprefix('sha256:')}
 items[a['name']]=(a,archive(b))
emeta,evidence=items['pskernel-supervised-candidate-evidence'];delivery=json.loads(evidence.read('delivery.json'));targets=json.loads(evidence.read('inputs.json'))
assert delivery['source']==emeta['workflow_run']['head_sha'] and int(delivery['run'])==emeta['workflow_run']['id'] and not delivery['fullPreviewQualified']
for spec in [targets['supervisor'],*targets['failedCampaignArtifacts']]:
 path='raw/supervisor.zip' if spec is targets['supervisor'] else 'raw/'+str(spec['id'])+'.zip'
 b=evidence.read(path);assert digest(b)==spec['archive'];archive(b)
native=evidence.read('native-814-evidence.zip');assert digest(native)==targets['native']['archive'];nz=archive(native)
receipt=json.loads(nz.read('receipt.json'));assert receipt['nativeReports']==814 and receipt['proofModules']==len(receipt['bindings'])==61
actual={}
for p in nz.namelist():
 if p.endswith('.log'):
  for n,ax in re.findall(r"'([^']+)' (?:depends on axioms: \[([^\]]*)\]|does not depend on any axioms)",nz.read(p).decode()):
   assert {a.strip() for a in ax.split(',') if a.strip()}<={'propext','Classical.choice','Quot.sound'}
   if n in actual:assert actual[n]==ax
   actual[n]=ax
assert len(actual)==814 and sorted(actual)==delivery['nativeProofNames']
for p,pin in receipt['bindings'].items():assert digest(nz.read('source/'+p))==pin
lim=json.loads(evidence.read('limitations.json'));assert not lim['fullPreviewQualified'] and lim['previewGateP5']=='BLOCKED' and lim['confirmedStringAssertions']=={'generated':7000,'canonical':8400}
assert lim['arenaTotal']==193 and lim['arenaStrictPasses']==174 and lim['arenaTimeouts']==17 and lim['safetyContractDifferences']==2 and lim['byteIdenticalCompletedArenaEnvelopes']==176 and not lim['strictArenaQualified']
assert len(lim['stringSamples'])==12 and sum(r['complete1400'] for r in lim['stringSamples'])==11 and len(lim['censoredObservations'])==1
q=json.loads(evidence.read('supervisor-qualification.json'));sources={}
for p,pin in q['sources'].items():
 b=urllib.request.urlopen('https://raw.githubusercontent.com/dwijayuda/pskernel/'+delivery['source']+'/'+p,timeout=60).read();assert digest(b)==pin;sources[p]=b
rows=[]
for route in ['generated','canonical']:
 a,z=items['pskernel-supervised-candidate-'+route];m=json.loads(z.read('files.json'));assert set(m)==set(z.namelist())-{'files.json'}
 for p,pin in m.items():assert digest(z.read(p))==pin
 r=json.loads(z.read('candidate-provenance.json'));assert r['source']==delivery['source'] and int(r['run'])==emeta['workflow_run']['id'] and r['route']==route
 assert r['supervisorControls']==67 and r['proofReportsPreserved']==814 and r['proofModulesPreserved']==61 and not r['fullPreviewQualified'] and r['P5']=='BLOCKED'
 assert digest(z.read('kernel.js'))==r['program']==lim['program'] and z.read('native-814-evidence.zip')==native
 assert json.loads(z.read('limitations.json'))==lim and z.read('arena-report.json')==evidence.read('arena-report.json')
 assert json.loads(z.read('package.json'))['private'] and 'not completed Preview 1' in z.read('README.md').decode()
 for p,b in sources.items():
  assert z.read('preview-source/'+p)==b
  name='check-export.mjs' if p.endswith('/pskernel-check-export.mjs') else pathlib.PurePosixPath(p).name
  if name in z.namelist():assert z.read(name)==b
 controls=json.loads(z.read('preview-controls.json'));assert controls['controls']==len(controls['labels'])==len(set(controls['labels']))==67
 for x in r['examples']:
  log=z.read('delivery-'+x['label']+'.log');assert digest(log)==x['log'] and x['emptyPATH']
  if x['label'].startswith('file-'):
   result=json.loads(log);assert result['outcome']==('accepted' if x['label']=='file-valid' else 'rejectedInvalid') and result['program']==r['program'] and result['host']['workerReaped']
   assert x['exitCode']==(0 if x['label']=='file-valid' else 1)
  else:assert x['exitCode']==0 and b'PASS' in log
 rows.append({'route':route,'artifact':a['id'],'archive':{'bytes':a['size_in_bytes'],'sha256':a['digest'].removeprefix('sha256:')},'members':len(z.namelist()),'manifestFiles':len(m),'kernel':r['program']})
summary={'run':int(delivery['run']),'source':delivery['source'],'evidenceArtifact':emeta['id'],'evidenceMembers':len(evidence.namelist()),'rows':rows,'sourceBindings':len(sources),
 'preservedProofReports':814,'preservedProofModules':61,'supervisorControlsPerRoute':67,'examplesPerRoute':5,'P5':'BLOCKED','fullPreviewQualified':False}
(root/('preview-candidate-static-audit-'+str(delivery['run'])+'.json')).write_text(json.dumps(summary,indent=2)+'\n');print(json.dumps(summary,indent=2))
