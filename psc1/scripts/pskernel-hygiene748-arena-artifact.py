"""GitHub-only full193 producer authentication; populated from verified pair pins."""
import hashlib,importlib.util,io,json,os,pathlib,stat,subprocess,zipfile

PAIR={'rootVerified': True, 'bothActualJobsPass': True, 'source': '86d27f71dd1340d5f3d37a851f0ac85a40649b6a', 'run': 40304110450, 'productionTree': 'cada4884b4250a708dccadca42b8ef5bddbd04a3', 'native': {'source': '945d2c06b22c59e2bf4502e329403df62ae5915c', 'run': 40303319691, 'job': 121506227524, 'artifact': 12640944810, 'bytes': 999888, 'sha256': '582a93b1c52b424ab2578ae990e12b9ff6799fd680714e02154dc18eaa38685d', 'members': 412, 'proofs': 748}, 'routes': {'generated': {'artifact': 12642078456, 'job': 121508849440, 'bytes': 6178572, 'sha256': '4430461a46133e2014df1798b55cd0c912a16575cdd9025a9b14b502fbb4d8cc', 'members': 281, 'program': {'bytes': 10607234, 'sha256': '21cd36644cdb4baa0e0beb4cac1337f4ea6092c1c930b72a670ab0c2909765b0'}}, 'canonical': {'artifact': 12643381412, 'job': 121508849752, 'bytes': 6329114, 'sha256': 'a04f3944db8e117175f4e5df9e4f9300b58da91e666bbce84ba92cb9ddc4822a', 'members': 285, 'program': {'bytes': 10607234, 'sha256': '21cd36644cdb4baa0e0beb4cac1337f4ea6092c1c930b72a670ab0c2909765b0'}}}, 'bothCompleteProgramsByteIdentical': True, 'full193Qualified': False, 'performanceQualified': False}
ROOT=pathlib.Path(__file__).resolve().parents[1]
SOURCE=PAIR['source'];RUN=PAIR['run'];TREE=PAIR['productionTree']
OFFICIAL_SOURCE='aed07022222c8330b17636c3f894874058bfe571'
OFFICIAL_RUN=40233314029;OFFICIAL_ARTIFACT=12613649899
OFFICIAL_SHA='9b5f2eadc47c3926af35b1c765f770d7fd473ca429f95ae8e9e3401825064d2f'
spec=importlib.util.spec_from_file_location('authenticated_download',ROOT/'scripts/pskernel-church-stage-ci.py')
C=importlib.util.module_from_spec(spec);spec.loader.exec_module(C)

def bundle(raw,count):
 z=zipfile.ZipFile(io.BytesIO(raw));infos=z.infolist()
 C.require(len(infos)==len({i.filename for i in infos})==count and z.testzip() is None,'Exact unique CRC-checked producer members')
 for i in infos:
  p=pathlib.PurePosixPath(i.filename)
  C.require(not p.is_absolute() and '..' not in p.parts and p.as_posix()==i.filename and '\\' not in i.filename and ':' not in i.filename and not i.is_dir() and not stat.S_ISLNK(i.external_attr>>16) and i.file_size<=32_000_000,'Safe bounded producer member')
 return z

def authenticated_artifact(source,run,pin):
 a=json.loads(C.github('/actions/artifacts/'+str(pin['artifact'])))
 C.require(a['workflow_run']['id']==run and a['workflow_run']['head_sha']==source and not a['expired'] and a['size_in_bytes']==pin['bytes'] and a['digest']=='sha256:'+pin['sha256'],'Exact source-bound artifact identity')
 raw=C.github('/actions/artifacts/'+str(pin['artifact'])+'/zip')
 C.require(C.digest(raw)=={'bytes':pin['bytes'],'sha256':pin['sha256']},'Actual complete producer archive digest')
 return raw,bundle(raw,pin['members'])

def check_full_route(z,route,pin):
 manifest=json.loads(z.read('files.json'));C.require(manifest['source']==SOURCE,'Actual source-bound file manifest')
 for name,h in manifest['files'].items():C.require(C.digest(z.read(name))==h,'Actual producer member '+name)
 C.require(len(manifest['files'])==pin['members']-1,'Every producer member covered')
 inputs=json.loads(z.read('inputs.json'))
 C.require(inputs['source']==SOURCE and inputs['run']==str(RUN) and inputs['route']==route and inputs['nativeReports']==748 and inputs['nativeAssertions']==1184 and inputs['generatedAssertions']==853 and inputs['nativeSource']==PAIR['native']['source'] and inputs['nativeRun']==PAIR['native']['run'] and inputs['all340NativeSourceSnapshotsMatchActualGit'],'Exact public source/native/route identity')
 kernel=z.read('kernel.mjs');C.require(kernel==z.read('production/kernel.js') and C.digest(kernel)==pin['program'],'Exact complete detached and production program')
 labels=json.loads(z.read('native-labels.json'));C.require(sum(map(len,labels.values()))==853,'Exact new native label inventory')
 total=0;runtime=z.read('runtime.log').decode()
 for prefix,names in labels.items():
  if prefix=='PSC1_MUTUAL_PUBLIC':continue
  marker=prefix+'_JS: PASS ';rows=[json.loads(line[len(marker):]) for line in runtime.splitlines() if line.startswith(marker)]
  C.require(len(rows)==1,'Exact runtime receipt '+prefix);r=rows[0]
  C.require(r['assertions']==len(r['labels'])==len(set(r['labels']))==len(names) and r['labels']==names and r['kernel']==pin['program'] and not r['fullKernel'] and not r['performanceQualified'],'All exact source/native private controls '+prefix)
  total+=r['assertions']
 C.require(total==841,'All complete/private841 controls')
 public=[json.loads(line) for line in z.read('public-runtime.log').decode().splitlines() if line.startswith('{') and json.loads(line).get('schema')=='psc1-mutual-admission-public-v1']
 C.require(len(public)==1 and public[0]['assertions']==12 and public[0]['assertionLabels']==labels['PSC1_MUTUAL_PUBLIC'] and public[0]['mutualAdmission'] and public[0]['publicRoutingChanged'],'All12 public controls')
 legacy=json.loads(z.read('retained-runtime/receipt.json'));C.require(legacy['source']==SOURCE and legacy['kernel']==pin['program'] and legacy['all21QualifiedRetainedHarnessesUnchangedAndPassed'] and len(legacy['harnesses'])==21 and legacy['emptyPATH'] and legacy['oldSpaceMiB']==2048,'All21 retained complete-program harnesses')
 for item in legacy['harnesses']:
  C.require(item['exitCode']==0 and item['sourceBytesAndDigestExact'] and item['qualifiedBaselineBytesExact'],'Retained source and exit status')
  name=pathlib.PurePosixPath(item['path']).name
  C.require(z.read('retained-runtime/'+name)==(ROOT/'scripts'/name).read_bytes(),'Exact replayed legacy harness source')
  log=z.read('retained-runtime/'+pathlib.PurePosixPath(name).stem+'.log')
  C.require(C.digest(log)=={'bytes':item['logBytes'],'sha256':item['logSha256']} and any(line.startswith(item['passMarker']) for line in log.decode().splitlines()),'Actual legacy harness log and PASS marker')
 for snapshot in inputs['snapshots']:
  raw=z.read('sources/'+snapshot['path'])
  C.require(C.digest(raw)=={'bytes':snapshot['bytes'],'sha256':snapshot['sha256']} and raw==subprocess.check_output(['git','show','HEAD:'+snapshot['path']],cwd=ROOT.parent),'Actual snapshot agrees with current Git '+snapshot['path'])
 closure=json.loads(z.read('lean-source-manifest.json'));C.require(closure['source']==SOURCE and len(closure['files'])==169,'Complete actual169 Lean closure')
 for item in closure['files']:
  raw=z.read('lean-source/'+item['path'])
  C.require(C.digest(raw)=={'bytes':item['bytes'],'sha256':item['sha256']} and raw==subprocess.check_output(['git','show','HEAD:psc1/'+item['path']],cwd=ROOT.parent),'Actual whole-program Lean source '+item['path'])
 tag='PSC1_NESTED_PARAM_HYGIENE_JS: PASS '
 rows=[json.loads(line[len(tag):]) for line in z.read('hygiene-runtime.log').decode().splitlines() if line.startswith(tag)]
 C.require(len(rows)==1,'Exact capture regression receipt')
 r=rows[0];labels=json.loads(z.read('hygiene-native-labels.json'))
 C.require(r['assertions']==len(r['labels'])==len(set(r['labels']))==17 and r['labels']==labels and r['validInputsAccepted'] and r['publicDagRejects'] and not r['fullKernel'] and not r['performanceQualified'],'All17 native-equal capture controls')
 C.require(inputs['nestedCaptureReports']==10 and inputs['nestedCaptureControls']==17,'Exact capture native qualification')
 return kernel

def main():
 C.require(os.environ.get('GITHUB_ACTIONS')=='true' and os.environ.get('RUNNER_OS')=='Linux','GitHub Linux only')
 repo=ROOT.parent
 C.require(subprocess.check_output(['git','rev-parse','HEAD'],cwd=repo,text=True).strip()==os.environ['GITHUB_SHA'],'Exact workflow source')
 C.require(subprocess.check_output(['git','rev-parse','HEAD:psc1/packages/pskernel-core/src'],cwd=repo,text=True).strip()==TREE,'Exact qualified public-mutual production tree')
 stable=['psc1/packages/pskernel-core/src','psc1/scripts/pskernel-arena435-oracle.py','psc1/scripts/pskernel-arena435-compare.py','psc1/scripts/pskernel-arena435-inspect.py','psc1/scripts/pskernel-arena435-progress-controls.py','psc1/scripts/pskernel-arena-replay.mjs','psc1/scripts/pskernel-arena-replay-controls.mjs','psc1/scripts/pskernel-church-stage-ci.py','psc1/lean-toolchain']
 subprocess.run(['git','diff','--exit-code',SOURCE,'HEAD','--',*stable],cwd=repo,check=True)
 subprocess.run(['git','diff','--exit-code',OFFICIAL_SOURCE,'HEAD','--','psc1/scripts/pskernel-arena435-oracle.py','psc1/scripts/pskernel-arena435-inspect.py','psc1/lean-toolchain'],cwd=repo,check=True)
 official=json.loads(C.github('/actions/artifacts/'+str(OFFICIAL_ARTIFACT)))
 C.require(official['workflow_run']['id']==OFFICIAL_RUN and official['workflow_run']['head_sha']==OFFICIAL_SOURCE and not official['expired'] and official['size_in_bytes']==114919 and official['digest']=='sha256:'+OFFICIAL_SHA,'Pinned actual fresh official193 archive')
 official_jobs=json.loads(C.github('/actions/runs/'+str(OFFICIAL_RUN)+'/jobs?per_page=100'))['jobs']
 reference=[j for j in official_jobs if j['name']=='official-arena-reference']
 C.require(len(reference)==1 and reference[0]['conclusion']=='success','Actual official reference job PASS')
 raw=C.github('/actions/artifacts/'+str(OFFICIAL_ARTIFACT)+'/zip')
 C.require(C.digest(raw)=={'bytes':114919,'sha256':OFFICIAL_SHA},'Actual unchanged official archive digest')
 official_zip=bundle(raw,199);report=json.loads(official_zip.read('report.json'))
 C.require(report['total']==len(report['tests'])==193 and report['excluded_cases']==[] and report['official_reference_complete'] and report['historical_label_drift']==0 and report['archive_sha256']=='98a69742b538296c5f413d0527dfeef8c4d1815fe64b12c8623cd33de63bee0d' and report['target_lean']['githash']=='eb6cafb7290e8bd5f2937522d8d804f58f02bafc','All193 exact bodies and official Lean pin')
 for item in report['controls']+report['tests']:
  observation=item.get('official',item)
  C.require(hashlib.sha256(official_zip.read('case-logs/'+observation['log'])).hexdigest()==observation['output_sha256'],'Actual official raw case output digest')
 out=pathlib.Path(os.environ['RUNNER_TEMP'])/'arena435-independent';out.mkdir(parents=True,exist_ok=True)
 oracle=pathlib.Path(os.environ['RUNNER_TEMP'])/'arena435-official';oracle.mkdir()
 for entry in official_zip.infolist():
  target=oracle/entry.filename;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(official_zip.read(entry.filename))
 (out/'authenticated-official.zip').write_bytes(raw)
 run=json.loads(C.github('/actions/runs/'+str(RUN)))
 C.require(run['head_sha']==SOURCE and run['run_attempt']==1 and run['status']=='completed' and run['conclusion']=='success','Both exact coherent full routes must pass before any193 replay')
 jobs=json.loads(C.github('/actions/runs/'+str(RUN)+'/jobs?per_page=100'))['jobs']
 C.require(len(jobs)==2 and all(j['conclusion']=='success' and j['head_sha']==SOURCE for j in jobs),'Both actual full-route jobs PASS')
 nativeRaw,native=authenticated_artifact(PAIR['native']['source'],PAIR['native']['run'],PAIR['native'])
 nativeRun=json.loads(C.github('/actions/runs/'+str(PAIR['native']['run'])))
 C.require(nativeRun['head_sha']==PAIR['native']['source'] and nativeRun['conclusion']=='success','Exact native748 cohort PASS')
 (out/'authenticated-native748.zip').write_bytes(nativeRaw)
 kernels={}
 for route,pin in PAIR['routes'].items():
  job=[j for j in jobs if j['id']==pin['job'] and j['name']=='complete-routes ('+route+')']
  C.require(len(job)==1,'Actual pinned full route job '+route)
  raw,z=authenticated_artifact(SOURCE,RUN,pin)
  C.require(z.read('authenticated-native748.zip')==nativeRaw,'Exact matching same production native cohort')
  kernels[route]=check_full_route(z,route,pin)
  (out/('authenticated-'+route+'.zip')).write_bytes(raw)
 C.require(set(kernels)=={'generated','canonical'},'Both whole production program routes')
 target=ROOT/'dist/arena435/kernel.js';target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(kernels['generated'])
 record={'schema':'psc1-nested-hygiene748-arena-kernel-v1','workflowSourceSha':os.environ['GITHUB_SHA'],'workflowRunId':os.environ['GITHUB_RUN_ID'],'kernelSourceSha':SOURCE,'productionTree':TREE,'producerRun':RUN,'producerJob':PAIR['routes']['generated']['job'],'producerArtifact':PAIR['routes']['generated']['artifact'],'kernel':C.digest(kernels['generated']),'nativeReports':748,'proofModules':52,'newRuntimeControlsPerRoute':870,'retainedHarnessesPerRoute':21,'bothFullRoutesPass':True,'matchingIndependentNative748Pass':True,'officialReferenceSource':OFFICIAL_SOURCE,'officialReferenceRun':OFFICIAL_RUN,'officialReferenceArtifact':OFFICIAL_ARTIFACT,'officialReferenceArchiveSha256':OFFICIAL_SHA,'sameProductionAndReplaySources':True,'fullArenaQualified':False,'performanceQualified':False}
 C.write(out/'kernel-provenance.json',record)
 print('PSC1_HYGIENE748_ARENA_AUTHENTICATED: PASS '+json.dumps(record,separators=(',',':')))

if __name__=='__main__':main()
