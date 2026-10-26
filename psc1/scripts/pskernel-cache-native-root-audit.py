from pathlib import Path
import zipfile,json,hashlib,re
p=Path('review/cache7ac-native742.zip');z=zipfile.ZipFile(p);assert z.testzip() is None
assert len(z.namelist())==409 and p.stat().st_size==996349
assert hashlib.sha256(p.read_bytes()).hexdigest()=='9dd28cff98f35ab12cf509195182e8cae6e429255e2ee45777098e761ef30c40'
m=json.loads(z.read('files.json'));assert m['source']=='7ac867ce6a4e2003f5e8a94b8f8e1b5deb970166'
for n,pin in m['files'].items():
 b=z.read(n);assert len(b)==pin['bytes'] and hashlib.sha256(b).hexdigest()==pin['sha256'],n
pins={p['path']:p['sha'] for p in json.loads(Path('review/cache7ac-actual-git339.json').read_text())}
sources=[n for n in m['files'] if n.startswith('source/')];assert len(sources)==339
for n in sources:
 b=z.read(n);assert hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()==pins[n.removeprefix('source/')],n
proofs={}
for filename,namespace,count in [('cache4-proofs.log','PsKernelCacheScan4Proofs',4),('public-proofs.log','PsKernelMutualAdmissionPublicProofs',2),('public-retained-proofs.log','PsKernelOrdinaryAdmissionPublicProofs',8),('admission-proofs.log','PsKernelMutualAdmissionProofs',20),('recursor-proofs.log','PsKernelMutualRecursorValidationProofs',31),('proofs.log','PsKernelMutualConstructorLoopProofs',16),('generated-proofs.log','PsKernelMutualGeneratedProofs',15),('retained-constructor-proofs.log','PsKernelMutualConstructorAnalysisProofs',22),('retained-fields-proofs.log','PsKernelMutualConstructorFieldsProofs',18),('retained-recursive-proofs.log','PsKernelMutualRecursiveArgumentProofs',15),('retained-count-proofs.log','PsKernelExpandedSizeProofs',11),('header-proofs.log','PsKernelMutualHeaderProofs',17),('family-proofs.log','PsKernelMutualConstructorResultProofs',10)]:
 text=z.read(filename).decode();assert not any(x in text for x in ['error:','sorryAx','Lean.ofReduceBool','Lean.trustCompiler'])
 rows=re.findall(r"'("+namespace+r"\.[^']+)' (?:depends on axioms: \[([^\]]*)\]|does not depend on any axioms)",text)
 assert len(rows)==len({n for n,_ in rows})==count,(filename,rows)
 for n,axioms in rows:assert set(x.strip() for x in axioms.split(',') if x.strip())<={'propext','Classical.choice','Quot.sound'}
 proofs[filename]=[n for n,_ in rows]
assert len({n for reports in proofs.values() for n in reports})==189
retained=json.loads(z.read('retained561/receipt.json'))
assert retained['source']==m['source'] and retained['all38OtherProofSourceFilesByteIdenticalToQualifiedBaseline'] and retained['twoExactCacheWrapperProofBodyRepairsOnly'] and retained['all561TheoremStatementsAndNamesUnchanged'] and retained['all561NamesExactlyRetainedAndKernelChecked']
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
assert len({name for values in proofs.values() for name in values})==742
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
assert z.read('production-delta.txt').decode().splitlines()==['psc1/packages/pskernel-core/src/Ps/KernelCore/Checker/ExprV2/WhnfState.lean','psc1/packages/pskernel-core/src/Ps/KernelCore/Runtime/Acceleration/Cache.lean','psc1/packages/pskernel-core/src/Ps/KernelCore/Runtime/Acceleration/CacheAnalysis.lean']
baseline=zipfile.ZipFile('review/mutual4d-public738.zip')
for path,start,oldEnd,newEnd in [
 ('psc1/packages/pskernel-core/src/Ps/KernelCore/Runtime/Acceleration/Cache.lean','def psKernelExprMapGetIn\n','def psKernelExprMapGet\n','/- Scan at most four'),
 ('psc1/packages/pskernel-core/src/Ps/KernelCore/Checker/ExprV2/WhnfState.lean','def psKernelExprV2WhnfCacheFindWorker\n','/-\nKeep the existing generated curried entry point.','/- Scan at most four')]:
 before=baseline.read('source/'+path).decode();after=z.read('source/'+path).decode()
 assert before[before.index(start):before.index(oldEnd,before.index(start))]==after[after.index(start):after.index(newEnd,after.index(start))],path
for filename in ['PsKernelCacheScopeProofs.lean','PsKernelEmptySemanticCacheProofs.lean']:
 before=baseline.read('source/psc1/test/'+filename).decode()
 after=z.read('source/psc1/test/'+filename).decode()
 assert after==Path('review/cache4-'+filename).read_text()
 if filename=='PsKernelCacheScopeProofs.lean':
  oldBody='      exact psKernelExprV2WhnfCacheFindWorker_eq_before\n        (List.cons first rest) arena source hash'
  newBody='      exact (PsKernelCacheScan4Proofs.whnf_curried_wrapper_preserves_all_inputs_and_exact_errors\n        (List.cons first rest) arena source hash).trans\n          (psKernelExprV2WhnfCacheFindWorker_eq_before (List.cons first rest) arena source hash)'
 else:
  oldBody='      | cons entry rest => rfl\n  | some index => rfl'
  newBody='      | cons entry rest =>\n          simp only [psKernelSemanticExprMapGet, Frozen.psKernelSemanticExprMapGet,\n            PsKernelCacheScan4Proofs.map_scan_four_preserves_every_expression_list_and_order]\n  | some index =>\n      simp only [psKernelSemanticExprMapGet, Frozen.psKernelSemanticExprMapGet,\n        PsKernelCacheScan4Proofs.map_scan_four_preserves_every_expression_list_and_order]'
 assert after.removeprefix('import PsKernelCacheScan4Proofs\n').replace(newBody,oldBody)==before,filename
record={'source':m['source'],'sourceTree':'60c042b8bd0a05d7c0a2b79b867afdea169de3d5','run':40252352368,'attempt':1,'job':121346796474,'artifact':12621138409,'archiveBytes':p.stat().st_size,'members':409,'archiveSha256':hashlib.sha256(p.read_bytes()).hexdigest(),'all408ManifestEntriesActuallyReadAndVerified':True,'all339SourceSnapshotsMatchActualImmutableGitBlobs':True,'productionBuildJobs':201,'proofReportCount':742,'proofModules':52,'proofReports':proofs,'nativeControlCount':1184,'nativeLabels':controls,'all16NegativeHeaderErrorsComparedToActualRetainedMutualAdmission':True,'priorCopiedReferenceHeaderErrorClaimsSuperseded':True,'scope':'Separate cache scan4 experiment:742unique reports including4universal actual original-worker/wrapper refinements,all1184retainedcontrols. No generated program or performance qualification. Corrected duplicate bundle and first non-sort errors now match actual retained mutual admission; public route on isolated candidate only; not integrated. Existing ArenaModel/private memo premises remain explicit.','generatedQualification':False,'fullPrivateMutualAdmission':True,'candidatePublicMutualAdmission':True,'cacheScan4UniversalRefinementReports':4,'all561RetainedTheoremStatementsAndNamesUnchanged':True,'legacyProofSourceRepairs':2,'performanceQualified':False,'integrationAdopted':False,'globalSoundness':False,'backendPreservationProof':False}
record.update({'productionSrcTree':'c4a5fa4dc72f81d4c28a45e0772d9cd7788b3ae5','originalMapAndWhnfWorkerBytesActuallyPreserved':True,'bothLegacyProofRepairsActuallyInvertToExactOriginalFiles':True,'scope':'Separate cache scan4 native experiment;742unique reports including4all-input actual-original worker and wrapper equalities;1184retainedcontrols. All561retainedtheorem statements/names unchanged. No generated-program or performance qualification.'})
Path('review/cache7ac-native742-actual-report.json').write_text(json.dumps(record,indent=2)+'\n')
print(json.dumps({k:record[k] for k in ['source','run','artifact','archiveSha256','proofReportCount','nativeControlCount','all339SourceSnapshotsMatchActualImmutableGitBlobs','all16NegativeHeaderErrorsComparedToActualRetainedMutualAdmission']}))
