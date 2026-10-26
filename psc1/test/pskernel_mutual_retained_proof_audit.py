"""Run only in GitHub Linux Actions: preserve and recheck the exact561 proofs."""
from pathlib import Path
import json,subprocess,re,os

assert os.environ.get('GITHUB_ACTIONS')=='true','GitHub Actions execution only'
out=Path(os.environ['RUNNER_TEMP'])/'t09-cache-scan4'/'retained561'
out.mkdir(parents=True,exist_ok=True)
manifest=json.loads(Path('test/retained-561-proof-manifest.json').read_text())
modules=manifest['modules'];assert len(modules)==40
expected=set(manifest['expectedNames']);assert len(expected)==561
texts={}
for module in modules:
 path='psc1/test/'+module+'.lean'
 raw=Path('test',module+'.lean').read_bytes()
 original=subprocess.check_output(['git','show',manifest['qualifiedSource']+':'+path])
 if module in {'PsKernelCacheScopeProofs': ('      exact psKernelExprV2WhnfCacheFindWorker_eq_before\n        (List.cons first rest) arena source hash', '      exact (PsKernelCacheScan4Proofs.whnf_curried_wrapper_preserves_all_inputs_and_exact_errors\n        (List.cons first rest) arena source hash).trans\n          (psKernelExprV2WhnfCacheFindWorker_eq_before (List.cons first rest) arena source hash)'), 'PsKernelEmptySemanticCacheProofs': ('      | cons entry rest => rfl\n  | some index => rfl', '      | cons entry rest =>\n          simp only [psKernelSemanticExprMapGet, Frozen.psKernelSemanticExprMapGet,\n            PsKernelCacheScan4Proofs.map_scan_four_preserves_every_expression_list_and_order]\n  | some index =>\n      simp only [psKernelSemanticExprMapGet, Frozen.psKernelSemanticExprMapGet,\n        PsKernelCacheScan4Proofs.map_scan_four_preserves_every_expression_list_and_order]')}:
  oldBody,newBody={'PsKernelCacheScopeProofs': ('      exact psKernelExprV2WhnfCacheFindWorker_eq_before\n        (List.cons first rest) arena source hash', '      exact (PsKernelCacheScan4Proofs.whnf_curried_wrapper_preserves_all_inputs_and_exact_errors\n        (List.cons first rest) arena source hash).trans\n          (psKernelExprV2WhnfCacheFindWorker_eq_before (List.cons first rest) arena source hash)'), 'PsKernelEmptySemanticCacheProofs': ('      | cons entry rest => rfl\n  | some index => rfl', '      | cons entry rest =>\n          simp only [psKernelSemanticExprMapGet, Frozen.psKernelSemanticExprMapGet,\n            PsKernelCacheScan4Proofs.map_scan_four_preserves_every_expression_list_and_order]\n  | some index =>\n      simp only [psKernelSemanticExprMapGet, Frozen.psKernelSemanticExprMapGet,\n        PsKernelCacheScan4Proofs.map_scan_four_preserves_every_expression_list_and_order]')}[module]
  before=original.decode();assert before.count(oldBody)==1
  expectedRaw=('import PsKernelCacheScan4Proofs\n'+before.replace(oldBody,newBody)).encode()
  assert raw==expectedRaw,(path,'only exact import+proof-body repair allowed; statements unchanged')
 else:assert raw==original,path
 texts[module]=raw.decode()
pending=set(modules);order=[]
while pending:
 ready=sorted(m for m in pending if not (set(re.findall(r'^import\s+(\S+)',texts[m],re.M))&pending))
 assert ready,pending
 order+=ready;pending-=set(ready)
all_names=[];reports={}
for module in order:
 target=Path('.lake/build/lib/lean',module+'.olean')
 result=subprocess.run(['lake','-f','kernel-lakefile.lean','env','lean','-o',str(target),'test/'+module+'.lean'],capture_output=True,text=True,timeout=300)
 text=result.stdout+result.stderr
 (out/(module+'.log')).write_text(text)
 print(text,end='',flush=True)
 assert result.returncode==0,(module,result.returncode)
 assert not any(token in text for token in ['error:','sorryAx','Lean.ofReduceBool','Lean.trustCompiler']),module
 rows=re.findall(r"'([^']+)' (?:depends on axioms: \[([^\]]*)\]|does not depend on any axioms)",text)
 names=[name for name,_ in rows]
 assert len(names)==len(set(names)) and set(names)==set(modules[module]),(module,names)
 for name,axioms in rows:
  assert set(x.strip() for x in axioms.split(',') if x.strip())<={'propext','Classical.choice','Quot.sound'},(name,axioms)
 all_names+=names;reports[module]=names
assert len(all_names)==len(set(all_names))==561 and set(all_names)==expected
record={'source':os.environ['GITHUB_SHA'],'qualifiedBaseline':manifest['qualifiedSource'],'all40ProofSourceFilesByteIdenticalToQualifiedBaseline':False,'all38OtherProofSourceFilesByteIdenticalToQualifiedBaseline':True,'twoExactCacheWrapperProofBodyRepairsOnly':True,'all561TheoremStatementsAndNamesUnchanged':True,'all561NamesExactlyRetainedAndKernelChecked':True,'reports':reports,'totalUniqueWithPrivate175AndNewPublic2':738,'globalSoundness':False}
(out/'receipt.json').write_text(json.dumps(record,indent=2)+'\n')
print('PSC1_MUTUAL_PUBLIC_RETAINED_PROOFS_PASS retained561=561 totalUnique=738 modules=51')
