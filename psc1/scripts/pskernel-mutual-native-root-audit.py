from pathlib import Path
import zipfile,json,hashlib,re
p=Path('review/mutual4d-public738.zip');z=zipfile.ZipFile(p);assert z.testzip() is None
assert len(z.namelist())==405 and p.stat().st_size==969954
assert hashlib.sha256(p.read_bytes()).hexdigest()=='b2cfa1f927d0dd768029814fdf9ad7555713ab336015fdd34a3ce37a7c6131bf'
m=json.loads(z.read('files.json'));assert m['source']=='4d6272807b3b168ab2d222ce942f92f7d7792cb8'
for n,pin in m['files'].items():
 b=z.read(n);assert len(b)==pin['bytes'] and hashlib.sha256(b).hexdigest()==pin['sha256'],n
pins={p['path']:p['sha'] for p in json.loads(Path('review/mutual4d-public-actual-tree-blobs.json').read_text())}
sources=[n for n in m['files'] if n.startswith('source/')];assert len(sources)==336
for n in sources:
 b=z.read(n);assert hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()==pins[n.removeprefix('source/')],n
proofs={}
for filename,namespace,count in [('public-proofs.log','PsKernelMutualAdmissionPublicProofs',2),('public-retained-proofs.log','PsKernelOrdinaryAdmissionPublicProofs',8),('admission-proofs.log','PsKernelMutualAdmissionProofs',20),('recursor-proofs.log','PsKernelMutualRecursorValidationProofs',31),('proofs.log','PsKernelMutualConstructorLoopProofs',16),('generated-proofs.log','PsKernelMutualGeneratedProofs',15),('retained-constructor-proofs.log','PsKernelMutualConstructorAnalysisProofs',22),('retained-fields-proofs.log','PsKernelMutualConstructorFieldsProofs',18),('retained-recursive-proofs.log','PsKernelMutualRecursiveArgumentProofs',15),('retained-count-proofs.log','PsKernelExpandedSizeProofs',11),('header-proofs.log','PsKernelMutualHeaderProofs',17),('family-proofs.log','PsKernelMutualConstructorResultProofs',10)]:
 text=z.read(filename).decode();assert not any(x in text for x in ['error:','sorryAx','Lean.ofReduceBool','Lean.trustCompiler'])
 rows=re.findall(r"'("+namespace+r"\.[^']+)' (?:depends on axioms: \[([^\]]*)\]|does not depend on any axioms)",text)
 assert len(rows)==len({n for n,_ in rows})==count,(filename,rows)
 for n,axioms in rows:assert set(x.strip() for x in axioms.split(',') if x.strip())<={'propext','Classical.choice','Quot.sound'}
 proofs[filename]=[n for n,_ in rows]
assert len({n for reports in proofs.values() for n in reports})==185
retained=json.loads(z.read('retained561/receipt.json'))
assert retained['source']==m['source'] and retained['all40ProofSourceFilesByteIdenticalToQualifiedBaseline'] and retained['all561NamesExactlyRetainedAndKernelChecked']
manifest561=json.loads(z.read('source/psc1/test/retained-561-proof-manifest.json'))
assert len(manifest561['modules'])==40 and len(manifest561['expectedNames'])==561
expected=set(manifest561['expectedNames']);actual=[]
for module,names in manifest561['modules'].items():
 text=z.read('retained561/'+module+'.log').decode()
 assert not any(x in text for x in ['error:','sorryAx','Lean.ofReduceBool','Lean.trustCompiler'])
 rows=re.findall(r"'([^']+)' (?:depends on axioms: \[([^\]]*)\]|does not depend on any axioms)",text)
 assert len(rows)==len({name for name,_ in rows})==len(names) and {name for name,_ in rows}==set(names)
 for name,axioms in rows:assert set(x.strip() for x in axioms.split(',') if x.strip())<={'propext','Classical.choice','Quot.sound'}
 proofs['retained561/'+module+'.log']=[name for name,_ in rows];actual+=[name for name,_ in rows]
assert len(actual)==len(set(actual))==561 and set(actual)==expected
assert len({name for values in proofs.values() for name in values})==738
controls={}
for filename,tag,count in [('public-native.log','PSC1_MUTUAL_PUBLIC_ASSERT ',12),('admission-native.log','PSC1_MUTUAL_ADMISSION_ASSERT ',240),('recursor-native.log','PSC1_MUTUAL_RECURSOR_ASSERT ',169),('native.log','PSC1_MUTUAL_LOOP_ASSERT ',52),('generated-native.log','PSC1_MUTUAL_GENERATED_ASSERT ',162),('retained-constructor-native.log','PSC1_MUTUAL_CONSTRUCTOR_ASSERT ',189),('retained-fields-native.log','PSC1_MUTUAL_FIELDS_ASSERT ',83),('retained-recursive-native.log','PSC1_MUTUAL_RECURSIVE_ASSERT ',88),('count-native.log','PSC1_EXPANDED_SIZE_ASSERT ',26),('header-native.log','PSC1_MUTUAL_HEADER_ASSERT ',49),('family-native.log','PSC1_MUTUAL_RESULT_ASSERT ',114)]:
 text=z.read(filename).decode();labels=[line[len(tag):] for line in text.splitlines() if line.startswith(tag)]
 assert len(labels)==len(set(labels))==count,(filename,labels)
 controls[filename]=labels
assert sum(map(len,controls.values()))==1184
assert len([s for s in controls['header-native.log'] if s.startswith('actual-retained-mutual-error-')])==16
header=z.read('source/psc1/packages/pskernel-core/src/Ps/KernelCore/API/DagMutualHeader.lean').decode()
assert 'else Except.error "duplicate mutual inductive, constructor, or recursor name"' in header
assert 'def psKernelExprV2MutualFirstHeaderFinish' in header and '"mutual inductive result must be a sort"' in header
assert 'match psKernelExprV2MutualFirstHeaderPhasesWith check whnf fuel context' in header
reg=z.read('source/psc1/test/PsKernelMutualHeaderRegression.lean').decode()
assert 'let original := psKernelAddSimpleMutualInductive 256' in reg
assert 'match original,actual with' in reg
assert 'Build completed successfully (201 jobs).' in z.read('build.log').decode()
assert z.read('production-delta.txt').decode().splitlines()==['psc1/packages/pskernel-core/src/Ps/KernelCore/API/Dag.lean']
record={'source':m['source'],'sourceTree':'7380ab91c137afb21b465715d667364ed7ace842','run':40244424044,'attempt':1,'job':121322877883,'artifact':12617842824,'archiveBytes':p.stat().st_size,'members':405,'archiveSha256':hashlib.sha256(p.read_bytes()).hexdigest(),'all404ManifestEntriesActuallyReadAndVerified':True,'all336SourceSnapshotsMatchActualImmutableGitBlobs':True,'productionBuildJobs':201,'proofReportCount':738,'proofModules':51,'proofReports':proofs,'nativeControlCount':1184,'nativeLabels':controls,'all16NegativeHeaderErrorsComparedToActualRetainedMutualAdmission':True,'priorCopiedReferenceHeaderErrorClaimsSuperseded':True,'scope':'Candidate public mutual route with738unique kernel-checked reports and1184controls including168whole original admission comparisons. Corrected duplicate bundle and first non-sort errors now match actual retained mutual admission; public route on isolated candidate only; not integrated. Existing ArenaModel/private memo premises remain explicit.','generatedQualification':False,'fullPrivateMutualAdmission':True,'candidatePublicMutualAdmission':True,'integrationAdopted':False,'globalSoundness':False,'backendPreservationProof':False}
Path('review/mutual4d-public738-actual-report.json').write_text(json.dumps(record,indent=2)+'\n')
print(json.dumps({k:record[k] for k in ['source','run','artifact','archiveSha256','proofReportCount','nativeControlCount','all336SourceSnapshotsMatchActualImmutableGitBlobs','all16NegativeHeaderErrorsComparedToActualRetainedMutualAdmission']}))
