// Audit the actual native dependency closure instead of misreporting a theorem
// about an existing parser as axiom-free. Refactoring algebra must be axiom-free;
// concrete API equalities must add NO assumptions beyond their pinned baseline.
import assert from 'node:assert/strict';
import { readFile, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const dir=path.resolve(process.argv[3]||path.join(root,'dist/pscv0-bridge/authoring'));
const wanted=process.argv[2];
assert(['4.34.0','4.35.0-rc4'].includes(wanted));
const sha=b=>createHash('sha256').update(b).digest('hex');
const run=args=>{
  const r=spawnSync('lake',['env','lean',...args],{cwd:root,encoding:'utf8',timeout:120000,maxBuffer:4*1024*1024});
  assert(!r.error&&r.status===0,String(r.error||r.stdout||r.stderr));return r.stdout+r.stderr;
};
function axioms(output,name){
  const matches=[...output.matchAll(/^'([^']+)' (?:does not depend on any axioms|depends on axioms:\s*\[([^\]]*)\])/gm)].filter(m=>m[1]===name);
  assert.equal(matches.length,1,'missing/duplicate axiom audit: '+name);
  return (matches[0][2]||'').split(',').map(s=>s.trim()).filter(Boolean).sort();
}
const version=run(['--version']).trim();
assert(version.includes('version '+wanted+','));
if(wanted==='4.35.0-rc4')assert(version.includes('c29b6dda4f7c20e3eeaa717c4e565663c5cfa364'));
const receipt=JSON.parse(await readFile(path.join(dir,'receipt.json'),'utf8'));
assert.equal(receipt.sourceRevision,process.env.GITHUB_SHA);
assert.equal(receipt.sourcePath,'packages/syntax/src-ps/Ps/Syntax/Translate.ps');
assert.equal(sha(await readFile(path.join(root,receipt.sourcePath))),receipt.sourceSha256);
const baselineBytes=await readFile(path.join(root,'packages/syntax/src/Ps/Syntax/Translate.lean'));
assert.equal(sha(baselineBytes),receipt.baselineSha256);
assert.equal(createHash('sha1').update('blob '+baselineBytes.length+'\0').update(baselineBytes).digest('hex'),'eafd7159b14a251fe11ffdbfb1e2482bcc773c9b');
for(const [file,expected] of Object.entries(receipt.products)){
  assert(!file.includes('/')&&!file.includes('\\'));
  assert.equal(sha(await readFile(path.join(dir,file))),expected,'proof input drift: '+file);
}
const names=['psTranslateLeanToProofScript','psTranslateProofScriptToLean','psCanonicalizeLeanSource','psCanonicalizeProofScriptSource'];
const prerequisiteNames=['PsTranslationError','psParseLeanSource','psParseProofScriptSource','psPrintLeanModule','psPrintProofScriptModule',...names];
const dependencyFile=path.join(dir,'DependencyAxioms.lean');
await writeFile(dependencyFile,'import Ps.Syntax.Translate\n\n'+prerequisiteNames.map(n=>'#print axioms '+n).join('\n')+'\n');
const dependencyOutput=run([dependencyFile]);
await writeFile(path.join(dir,'dependency-axioms-'+wanted+'.txt'),dependencyOutput);
const baseline=Object.fromEntries(prerequisiteNames.map(n=>[n,axioms(dependencyOutput,n)]));
assert.deepEqual(baseline.PsTranslationError,[]);
for(const name of prerequisiteNames.slice(1))assert.deepEqual(baseline[name],['propext'],'unexpected prerequisite assumptions: '+name);
console.log('PSCV0_ORIGINAL_DEPENDENCY_AUDIT:\n'+dependencyOutput.trim());
const algebraFile=path.join(root,'test/pscv0/reference/TranslationAlgebra.lean');
const algebra=await readFile(algebraFile,'utf8');
const algebraNames=['pscv0_translation_do_algebra','pscv0_translation_match_algebra'];
const proofs=[];
for(const file of ['ReadableProof.lean','LoweredProof.lean']){
  const source=await readFile(path.join(dir,file),'utf8');
  const probes=[...names,...names.map(n=>'old_'+n),'psTranslationMapError'];
  const audit=source+'\n'+algebra+'\n'+probes.map(n=>'#print axioms '+n).join('\n')+
    '\ntheorem pscv0_baseline_reflexive (source : String) :\n'+
    '    old_psTranslateLeanToProofScript source = old_psTranslateLeanToProofScript source := rfl\n'+
    '#print axioms pscv0_baseline_reflexive\n';
  const auditName=file.replace('.lean','.audit.lean');
  await writeFile(path.join(dir,auditName),audit);
  const output=run([path.join(dir,auditName)]);
  await writeFile(path.join(dir,file+'.'+wanted+'.txt'),output);
  console.log(output.trim());
  const audited=Object.fromEntries([...names,...names.map(n=>'old_'+n),...names.map(n=>'migration_'+n),
    ...algebraNames,'psTranslationMapError','pscv0_baseline_reflexive'].map(n=>[n,axioms(output,n)]));
  assert.deepEqual(audited.psTranslationMapError,[],'error adapter introduced assumptions');
  for(const name of algebraNames)assert.deepEqual(audited[name],[],'refactoring algebra must be axiom-free');
  for(const name of names){
    for(const symbol of [name,'old_'+name,'migration_'+name])assert.deepEqual(audited[symbol],baseline[name],'new dependency in '+symbol);
  }
  assert.deepEqual(audited.pscv0_baseline_reflexive,baseline.psTranslateLeanToProofScript);
  proofs.push({file,sha256:receipt.products[file],auditSource:auditName,auditSha256:sha(audit),
    theorems:names.map(n=>'migration_'+n),axioms:audited,newAxioms:[],proofsClosed:true});
}
const report={schema:'psc0-pscv0-module-correspondence/2',source:process.env.GITHUB_SHA,run:process.env.GITHUB_RUN_ID,
  lean:version,module:receipt.module,surfaceOrigin:receipt.surfaceSeed,authoritativePsSha256:receipt.sourceSha256,
  baselineGitBlob:receipt.baselineGitBlob,baselineAxioms:baseline,concreteTheoremAxioms:['propext'],
  axiomPolicy:'exact-baseline-closure-plus-zero-axiom-refactoring-algebra/1',newAxioms:[],
  algebra:{source:'test/pscv0/reference/TranslationAlgebra.lean',sha256:sha(algebra),theorems:algebraNames,axioms:[]},
  proofs,theoremCount:8,algebraTheoremCount:2,
  scope:'Both generated projections equal the four original translation APIs for every String input relative to unchanged original dependencies; not a general compiler/backend theorem',
  fullCompilerBuilt:false,kernelRegenerated:false,newSelfhostFixedPoint:false};
await writeFile(path.join(dir,'proof-'+wanted+'.json'),JSON.stringify(report,null,2)+'\n');
console.log('PSCV0_AUTHORING_CORRESPONDENCE: PASS '+JSON.stringify(report));
