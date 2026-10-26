from pathlib import Path
import zipfile,json,hashlib,re
p=Path('review/hygiene945-native748.zip');z=zipfile.ZipFile(p);assert z.testzip() is None
assert len(z.namelist())==412 and p.stat().st_size==999888
assert hashlib.sha256(p.read_bytes()).hexdigest()=='582a93b1c52b424ab2578ae990e12b9ff6799fd680714e02154dc18eaa38685d'
m=json.loads(z.read('files.json'));assert m['source']=='945d2c06b22c59e2bf4502e329403df62ae5915c'
for n,pin in m['files'].items():
 b=z.read(n);assert len(b)==pin['bytes'] and hashlib.sha256(b).hexdigest()==pin['sha256'],n
pins={p['path']:p['sha'] for p in json.loads(Path('review/hygiene945-actual-git340.json').read_text())}
sources=[n for n in m['files'] if n.startswith('source/')];assert len(sources)==340
for n in sources:
 b=z.read(n);assert hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()==pins[n.removeprefix('source/')],n
proofs={}
for filename,namespace,count in [('nested-hygiene-proofs.log','PsKernelNestedParamHygieneProofs',10),('public-proofs.log','PsKernelMutualAdmissionPublicProofs',2),('public-retained-proofs.log','PsKernelOrdinaryAdmissionPublicProofs',8),('admission-proofs.log','PsKernelMutualAdmissionProofs',20),('recursor-proofs.log','PsKernelMutualRecursorValidationProofs',31),('proofs.log','PsKernelMutualConstructorLoopProofs',16),('generated-proofs.log','PsKernelMutualGeneratedProofs',15),('retained-constructor-proofs.log','PsKernelMutualConstructorAnalysisProofs',22),('retained-fields-proofs.log','PsKernelMutualConstructorFieldsProofs',18),('retained-recursive-proofs.log','PsKernelMutualRecursiveArgumentProofs',15),('retained-count-proofs.log','PsKernelExpandedSizeProofs',11),('header-proofs.log','PsKernelMutualHeaderProofs',17),('family-proofs.log','PsKernelMutualConstructorResultProofs',10)]:
 text=z.read(filename).decode();assert not any(x in text for x in ['error:','sorryAx','Lean.ofReduceBool','Lean.trustCompiler'])
 rows=re.findall(r"'("+namespace+r"\.[^']+)' (?:depends on axioms: \[([^\]]*)\]|does not depend on any axioms)",text)
 assert len(rows)==len({n for n,_ in rows})==count,(filename,rows)
 for n,axioms in rows:assert set(x.strip() for x in axioms.split(',') if x.strip())<={'propext','Classical.choice','Quot.sound'}
 proofs[filename]=[n for n,_ in rows]
assert len({n for reports in proofs.values() for n in reports})==195
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
assert len({name for values in proofs.values() for name in values})==748
controls={}
for filename,tag,count in [('nested-hygiene-native.log','PSC1_NESTED_PARAM_HYGIENE_ASSERT ',17),('public-native.log','PSC1_MUTUAL_PUBLIC_ASSERT ',12),('admission-native.log','PSC1_MUTUAL_ADMISSION_ASSERT ',240),('recursor-native.log','PSC1_MUTUAL_RECURSOR_ASSERT ',169),('native.log','PSC1_MUTUAL_LOOP_ASSERT ',52),('generated-native.log','PSC1_MUTUAL_GENERATED_ASSERT ',162),('retained-constructor-native.log','PSC1_MUTUAL_CONSTRUCTOR_ASSERT ',189),('retained-fields-native.log','PSC1_MUTUAL_FIELDS_ASSERT ',83),('retained-recursive-native.log','PSC1_MUTUAL_RECURSIVE_ASSERT ',88),('count-native.log','PSC1_EXPANDED_SIZE_ASSERT ',26),('header-native.log','PSC1_MUTUAL_HEADER_ASSERT ',49),('family-native.log','PSC1_MUTUAL_RESULT_ASSERT ',114)]:
 text=z.read(filename).decode();labels=[line[len(tag):] for line in text.splitlines() if line.startswith(tag)]
 assert len(labels)==len(set(labels))==count,(filename,labels)
 controls[filename]=labels
assert sum(map(len,controls.values()))==1201
assert len([s for s in controls['header-native.log'] if s.startswith('actual-retained-mutual-error-')])==16
header=z.read('source/psc1/packages/pskernel-core/src/Ps/KernelCore/API/DagMutualHeader.lean').decode()
assert 'else Except.error "duplicate mutual inductive, constructor, or recursor name"' in header
assert 'def psKernelExprV2MutualFirstHeaderFinish' in header and '"mutual inductive result must be a sort"' in header
assert 'match psKernelExprV2MutualFirstHeaderPhasesWith check whnf fuel context' in header
reg=z.read('source/psc1/test/PsKernelMutualHeaderRegression.lean').decode()
assert 'let original := psKernelAddSimpleMutualInductive 256' in reg
assert 'match original,actual with' in reg
assert 'Build completed successfully (201 jobs).' in z.read('build.log').decode()
assert z.read('production-delta.txt').decode().splitlines()==['psc1/packages/pskernel-core/src/Ps/KernelCore/Admission/Inductive/Nested/Rebase.lean']

diagnostic=json.loads(z.read('hygiene-diagnostic.json'))
assert diagnostic['source']==m['source'] and diagnostic['officialValidAccepted'] and diagnostic['officialFreeVariableRejected']
assert not diagnostic['observedCapturedFreeVariableAccepted'] and not diagnostic['publishedConstructorMatchesDifferentClosedInput']
assert diagnostic['nestedCollidingFreeVariable']=='rejectedInvalid: nested preprocessing: declaration has free variables'
assert diagnostic['nestedValid']==diagnostic['ordinaryValid']=='accepted'
original=Path('review/hygiene-original-Rebase.lean').read_bytes()
oldzip=zipfile.ZipFile('review/mutual4d-public738.zip')
path='psc1/packages/pskernel-core/src/Ps/KernelCore/Admission/Inductive/Nested/Rebase.lean'
assert oldzip.read('source/'+path)==original
assert z.read('source/'+path)==Path('review/hygiene-fixed-Rebase.lean').read_bytes()
assert z.read('source/psc1/test/PsKernelNestedParamHygieneProofs.lean')==Path('review/PsKernelNestedParamHygieneProofs.lean').read_bytes()
assert z.read('source/psc1/test/PsKernelNestedParamHygieneRegression.lean')==Path('review/PsKernelNestedParamHygieneRegression.lean').read_bytes()
record=dict({'source': '945d2c06b22c59e2bf4502e329403df62ae5915c', 'sourceTree': '0f09fa872e04b9ee27c9569a8e912190dc4ec7ed', 'run': 40303319691, 'attempt': 1, 'job': 121506227524, 'artifact': 12640944810, 'archiveBytes': 999888, 'members': 412, 'archiveSha256': '582a93b1c52b424ab2578ae990e12b9ff6799fd680714e02154dc18eaa38685d'},allManifestEntriesActuallyReadAndVerified=True,all340SourceSnapshotsMatchActualImmutableGitBlobs=True,
 productionBuildJobs=201,proofReportCount=748,proofModules=52,proofReports=proofs,nativeControlCount=1201,nativeLabels=controls,
 all561RetainedNamesAnd40ProofSourcesUnchanged=True,actualPinnedLeanDiagnostic=diagnostic,
 originalModuleByteMatchesQualifiedBaseline=True,onlyRebaseProductionChange=True,
 scope='Isolated correction of original nested constructor parameter free-variable capture. Exact original results on all closed inputs and original shape errors first proved. No global soundness/backend/performance qualification or adoption.',
 generatedQualification=False,integrationAdopted=False,performanceQualified=False)
Path('review/hygiene945-native748-actual-report.json').write_text(json.dumps(record,indent=2)+'\n')
print(json.dumps({k:record[k] for k in ['source','run','artifact','archiveSha256','proofReportCount','nativeControlCount','all340SourceSnapshotsMatchActualImmutableGitBlobs']}))
