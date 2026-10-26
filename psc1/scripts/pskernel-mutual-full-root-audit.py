"""Static archive/Git/log audit only. Never executes a compiler or kernel."""
from pathlib import Path,PurePosixPath
import json,zipfile,hashlib,re,tarfile,io,sys
pin=json.loads(Path(sys.argv[1]).read_text())
p=Path(pin['local']);raw=p.read_bytes()
assert len(raw)==pin['bytes'] and hashlib.sha256(raw).hexdigest()==pin['sha256']
z=zipfile.ZipFile(io.BytesIO(raw));assert z.testzip() is None
assert len(z.namelist())==len(set(z.namelist()))==pin['members']
assert all(not PurePosixPath(n).is_absolute() and '..' not in PurePosixPath(n).parts for n in z.namelist())
m=json.loads(z.read('files.json'));assert m['source']==pin['source'] and len(m['files'])==pin['members']-1
for n,h in m['files'].items():
 b=z.read(n);assert len(b)==h['bytes'] and hashlib.sha256(b).hexdigest()==h['sha256'],n
for member,local in [('authenticated-native738.zip','review/mutual4d-public738.zip'),('authenticated-compiler.zip','review/lazy-perf-12606866673.zip')]:
 assert z.read(member)==Path(local).read_bytes(),member
inputs=json.loads(z.read('inputs.json'))
assert inputs['source']==pin['source'] and inputs['run']==str(pin['run']) and inputs['route']==pin['route']
assert inputs['nativeSource']=='4d6272807b3b168ab2d222ce942f92f7d7792cb8' and inputs['nativeRun']==40244424044
assert inputs['nativeReports']==738 and inputs['nativeAssertions']==1184 and inputs['generatedAssertions']==853
assert inputs['all336NativeSourceSnapshotsMatchActualGit'] and inputs['allCompilerBuildSourcesUnchanged']
git={x['path']:x['sha'] for x in json.loads(Path(pin['gitSnapshots']).read_text())}
assert len(git)==len(inputs['snapshots'])
for item in inputs['snapshots']:
 b=z.read('sources/'+item['path'])
 assert len(b)==item['bytes'] and hashlib.sha256(b).hexdigest()==item['sha256']
 assert hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()==git[item['path']],item['path']

native=zipfile.ZipFile('review/mutual4d-public738.zip');labels={}
for filename,tag,count in [('public-native.log','PSC1_MUTUAL_PUBLIC_ASSERT ',12),('admission-native.log','PSC1_MUTUAL_ADMISSION_ASSERT ',240),('native.log','PSC1_MUTUAL_LOOP_ASSERT ',52),('retained-constructor-native.log','PSC1_MUTUAL_CONSTRUCTOR_ASSERT ',189),('retained-fields-native.log','PSC1_MUTUAL_FIELDS_ASSERT ',83),('retained-recursive-native.log','PSC1_MUTUAL_RECURSIVE_ASSERT ',88),('count-native.log','PSC1_EXPANDED_SIZE_ASSERT ',26),('header-native.log','PSC1_MUTUAL_HEADER_ASSERT ',49),('family-native.log','PSC1_MUTUAL_RESULT_ASSERT ',114)]:
 text=native.read(filename).decode();names=[line[len(tag):] for line in text.splitlines() if line.startswith(tag)]
 assert len(names)==len(set(names))==count
 labels[tag.split('_ASSERT')[0]]=names
assert sum(map(len,labels.values()))==853 and json.loads(z.read('native-labels.json'))==labels
program=z.read('kernel.mjs');assert program==z.read('production/kernel.js')
programHash={'bytes':len(program),'sha256':hashlib.sha256(program).hexdigest()}
assert programHash==pin['program']
mapping=json.loads(z.read('production/kernel.js.map'))
assert mapping['version']==3 and mapping['sources'] and mapping['mappings']
assert z.read('production/kernel.ts') and z.read('production/kernel.d.ts')
assert all(token in program for token in [b'psKernelExprV2MutualAdmitWithFuel',b'psKernelDagRunOwnedCommandWithSource',b'psKernelExprV2MutualFirstHeaderFinish'])
runtime=z.read('runtime.log').decode();receipts={}
for prefix,names in labels.items():
 if prefix=='PSC1_MUTUAL_PUBLIC':continue
 marker=prefix+'_JS: PASS '
 r,=[json.loads(line[len(marker):]) for line in runtime.splitlines() if line.startswith(marker)]
 assert r['assertions']==len(r['labels'])==len(set(r['labels']))==len(names) and r['labels']==names
 assert r['kernel']==programHash and r['fullAdmission']==(prefix=='PSC1_MUTUAL_ADMISSION')
 assert not r['fullKernel'] and not r['performanceQualified']
 if prefix=='PSC1_MUTUAL_ADMISSION':assert r['privateOnly'] and not r['publicRoute'] and r['completeComparisons']==168
 receipts[prefix]=r
assert sum(r['assertions'] for r in receipts.values())==841
public=z.read('public-runtime.log').decode()
r,=[json.loads(line) for line in public.splitlines() if line.startswith('{') and json.loads(line).get('schema')=='psc1-mutual-admission-public-v1']
assert r['assertions']==12 and r['assertionLabels']==labels['PSC1_MUTUAL_PUBLIC']
assert r['publicRoutingChanged'] and r['mutualAdmission'] and not r['fullKernel'] and not r['performanceQualified']
assert 'PSC1_MUTUAL_PUBLIC_JS: PASS assertions=12 publicRoutingChanged=true mutualAdmission=true' in public
memory=z.read('runtime.memory').decode()
assert 'exit_status=0' in memory and float(re.search(r'wall_seconds=([0-9.]+)',memory)[1])<600

sourcePins={x['path']:x['sha'] for x in json.loads(Path('review/mutual-public7471-actual-src-blobs.json').read_text())}
closure=json.loads(z.read('lean-source-manifest.json'))
assert closure['source']==pin['source'] and closure['entry']=='packages/pskernel-core/src/Ps/KernelCore/SelfHost.lean'
sourceFiles={x['path']:x for x in closure['files']};assert len(sourceFiles)==len(closure['files'])==169
for name,h in sourceFiles.items():
 b=z.read('lean-source/'+name);assert len(b)==h['bytes'] and hashlib.sha256(b).hexdigest()==h['sha256']
 assert hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()==sourcePins['psc1/'+name],name
visited=set()
def visit(name):
 if name in visited:return
 visited.add(name)
 for imported in re.findall(r'^(?:public\s+)?import\s+(\S+)',z.read('lean-source/'+name).decode(),re.M):
  assert imported.startswith('Ps.KernelCore.'),imported
  path='packages/pskernel-core/src/'+imported.replace('.','/')+'.lean'
  assert path in sourceFiles,path
  visit(path)
visit(closure['entry']);assert visited==set(sourceFiles)
tar=tarfile.open(fileobj=io.BytesIO(z.read('lean-source.tar.gz')),mode='r:gz')
tarFiles={i.name.removeprefix('./'):tar.extractfile(i).read() for i in tar.getmembers() if i.isfile()}
assert set(tarFiles)==set(sourceFiles)
for name,b in tarFiles.items():assert b==z.read('lean-source/'+name)
assert 'PSC2_CHECK: PASS (2046 declarations)' in z.read('complete-lean-check.log').decode()
canonicalRecord=None
if pin['route']=='canonical':
 canon=json.loads(z.read('canonical-manifest.json'))
 expectedPs={name.removesuffix('.lean')+'.ps' for name in sourceFiles}
 assert canon['entry']==closure['entry'].removesuffix('.lean')+'.ps'
 assert canon['generation']=='bootstrap' and canon['sourceCount']==169
 assert len(canon['generated'])==len(set(canon['generated']))==169 and set(canon['generated'])==expectedPs
 assert canon['generated']==sorted(canon['generated'])
 tar=tarfile.open(fileobj=io.BytesIO(z.read('canonical-source.tar.gz')),mode='r:gz')
 psFiles={i.name.removeprefix('./'):tar.extractfile(i).read() for i in tar.getmembers() if i.isfile()}
 assert set(psFiles)==expectedPs|{'.proofscript-bootstrap.json'}
 assert psFiles['.proofscript-bootstrap.json']==z.read('canonical-manifest.json')
 digest=hashlib.sha256(b'proofscript-bootstrap-closure-v2\0'+canon['entry'].encode()+b'\0')
 for name in canon['generated']:
  b=psFiles[name];assert b.decode().encode()==b
  digest.update(name.encode()+b'\0'+b+b'\0')
 assert digest.hexdigest()==canon['closureSha256']
 assert z.read('lake-translate-adapter.sh')==z.read('sources/psc1/scripts/pskernel-authenticated-translate-lake.sh')
 assert 'PSC2_CHECK: PASS (2046 declarations)' in z.read('complete-canonical-check.log').decode()
 canonicalRecord={'actual169PsFilesAndManifestRead':True,'exact169ModulePsClosure':True,'actualCanonicalClosureDigestRecomputed':digest.hexdigest(),'strictAuthenticatedCompilerTranslationAdapterGitBound':True,'actual2046CanonicalDeclarationsChecked':True}

legacy=json.loads(z.read('retained-runtime/receipt.json'))
assert legacy['source']==pin['source'] and legacy['kernel']==programHash
assert legacy['all21QualifiedRetainedHarnessesUnchangedAndPassed'] and legacy['emptyPATH'] and legacy['oldSpaceMiB']==2048
assert not legacy['fullKernel'] and not legacy['performanceQualified']
manifest21=json.loads(z.read('sources/psc1/test/retained-21-generated-helper-manifest.json'))
assert manifest21['source']==legacy['baseline']=='2f7ee0afc1cc2fbccdf47b4f140b5cf01eb05c89'
assert len(legacy['harnesses'])==len(manifest21['helpers'])==21
for spec,item in zip(manifest21['helpers'],legacy['harnesses']):
 path=spec['path'];assert item['path']==path and item['sourceBytesAndDigestExact'] and item['qualifiedBaselineBytesExact'] and item['exitCode']==0
 basename=PurePosixPath(path).name;b=z.read('retained-runtime/'+basename)
 assert b==z.read('sources/'+path) and len(b)==spec['bytes'] and hashlib.sha256(b).hexdigest()==spec['sha256']
 log=z.read('retained-runtime/'+PurePosixPath(basename).stem+'.log')
 assert len(log)==item['logBytes'] and hashlib.sha256(log).hexdigest()==item['logSha256']
 assert item['passMarker']==spec['requiredFinalPassPrefix'] and any(line.startswith(item['passMarker']) for line in log.decode().splitlines())

collector=Path(pin['collector']).read_text()
for marker in ['PSC1_MUTUAL_COMPLETE_JS_ALL: PASS controls=841 completeComparisons=168 actualOriginalErrors=16','PSC1_MUTUAL_PUBLIC_JS_ALL: PASS newNativeEqual=853 completeComparisons=168 publicControls=12','PSC1_MUTUAL_RETAINED_RUNTIME_ALL: PASS unchangedHarnesses=21']:
 assert 'Z '+marker in collector,marker
record={'source':pin['source'],'productionTree':'7471f228b9bbc1eb5b9c0b78b85bf326aac72929','run':pin['run'],'job':pin['job'],'artifact':pin['artifact'],'route':pin['route'],'archiveBytes':len(raw),'archiveSha256':pin['sha256'],'members':pin['members'],'allManifestEntriesActuallyReadAndVerified':len(m['files']),'allActualGitSnapshotsVerified':len(git),'all169LeanClosureFilesMatchActualImmutableGitBlobs':True,'exact169ModuleImportClosureReconstructed':True,'sourceTarByteMatchesAllIndividualSources':True,'nestedNative738AndCompilerArchivesByteMatchActualRootReadOriginals':True,'program':programHash,'newNativeEqualControls':853,'allPrivate841AndPublic12LabelsEqualActualNative':True,'actualOriginalComparisons':168,'all21RetainedHarnessSourcesAndLogsReadAndVerified':True,'separateActualGitHubCollectorMarkersVerified':True,'privateControlMemory':memory.strip(),'publicControlReceipt':r,'retainedRuntimeReceipt':legacy,'coherentPairPassed':pin['coherentPairPassed'],'scope':'Complete public-mutual generated/canonical route evidence; producer sibling status is explicit. Independent global soundness/backend preservation, full193 and String qualification are not implied.','integrationAdopted':False,'full193Qualified':False,'StringQualification':False,'globalSoundness':False,'performanceQualified':False}
record['validWholeProgramSourceMapV3']=True
record['canonicalClosure']=canonicalRecord
Path(pin['report']).write_text(json.dumps(record,indent=2)+'\n')
print(json.dumps({k:record[k] for k in ['source','route','artifact','program','newNativeEqualControls','all21RetainedHarnessSourcesAndLogsReadAndVerified','all169LeanClosureFilesMatchActualImmutableGitBlobs','coherentPairPassed']}))
