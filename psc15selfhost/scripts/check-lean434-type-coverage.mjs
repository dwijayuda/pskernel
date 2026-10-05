import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root=fileURLToPath(new URL('../',import.meta.url));
const auditRoot=path.join(root,'.lake','lean434-type-audit');
const manifestPath=path.join(auditRoot,'lean434-type-surfaces.json');
const policyPath=path.join(root,'LEAN434_TYPE_COVERAGE_POLICY.json');
const preludePath=path.join(auditRoot,'proofscript-prelude.json');
const stdlibRoot=path.join(root,'stdlib');
const quotientBootstrap=path.join(
  root,'packages','pskernel-core','src','Ps','KernelCore','Admission','Quot','Bootstrap.lean',
);

const manifest=JSON.parse(fs.readFileSync(manifestPath,'utf8'));
const policy=JSON.parse(fs.readFileSync(policyPath,'utf8'));
const prelude=JSON.parse(fs.readFileSync(preludePath,'utf8'));

assert.equal(manifest.leanVersion,policy.leanVersion);
assert.equal(manifest.leanCommit,policy.leanCommit);
assert.ok(Array.isArray(manifest.records));
assert.ok(Array.isArray(prelude));

const preludeNames=new Set(prelude.map(d=>d?.name).filter(n=>typeof n==='string'));

function walkLeanFiles(dir){
  const out=[];
  for(const entry of fs.readdirSync(dir,{withFileTypes:true})){
    const p=path.join(dir,entry.name);
    if(entry.isDirectory()) out.push(...walkLeanFiles(p));
    else if(entry.isFile()&&entry.name.endsWith('.lean')) out.push(p);
  }
  return out;
}

const stdlibNames=new Set();
const typeHead=/^\s*(?:public\s+)?(?:private\s+)?(?:protected\s+)?(?:inductive|structure|class|abbrev)\s+([A-Za-z_][A-Za-z0-9_'.]*)\b/gmu;
for(const file of walkLeanFiles(stdlibRoot)){
  const source=fs.readFileSync(file,'utf8');
  for(const match of source.matchAll(typeHead)){
    stdlibNames.add(match[1]);
  }
}

for(const name of policy.requiredCorePrelude){
  assert.ok(preludeNames.has(name),`required ProofScript core-prelude type missing: ${name}`);
}

function classification(record){
  if(record.internal||record.name.startsWith('_private.')) return 'lean-internal-private';
  if(preludeNames.has(record.name)) return 'proofscript-core-prelude';
  if(stdlibNames.has(record.name)) return 'proofscript-stdlib';
  if(record.surfaces.includes('Init')) return 'lean-init-library-only';
  if(record.surfaces.includes('Std')) return 'lean-std-library-only';
  if(record.surfaces.includes('Lean')) return 'lean-compiler-meta-only';
  throw new Error('unclassified Lean type: '+record.name);
}

const classified=manifest.records.map(record=>({...record,classification:classification(record)}));
const allowed=new Set(policy.classificationOrder);
for(const record of classified){
  assert.ok(allowed.has(record.classification),`unknown classification for ${record.name}`);
}
assert.equal(classified.length,manifest.unionTypeCount,'coverage must account for every Lean type');

const byName=new Map(classified.map(record=>[record.name,record]));
const handbook=[];
for(const entry of policy.handbookSurface){
  const leanRecord=byName.get(entry.name)??null;
  const actualCore=preludeNames.has(entry.name);
  const actualStdlib=stdlibNames.has(entry.name);
  let implementation;
  if(entry.owner==='kernel-sort'){
    implementation='kernel-sort';
  }else if(entry.owner==='kernel-logical-foundation'){
    assert.equal(entry.name,'Quot','unknown logical-foundation special type');
    implementation=fs.existsSync(quotientBootstrap)?'kernel-special':'missing';
  }else if(actualCore){
    implementation='core-prelude';
  }else if(actualStdlib){
    implementation='stdlib';
  }else{
    implementation='missing';
  }
  if(entry.status==='implemented'){
    if(entry.owner==='core-prelude') assert.equal(implementation,'core-prelude',`handbook type missing from core: ${entry.name}`);
    if(entry.owner==='stdlib') assert.equal(implementation,'stdlib',`handbook type missing from stdlib: ${entry.name}`);
    if(entry.owner==='kernel-sort') assert.equal(implementation,'kernel-sort');
  }
  if(entry.status==='special'){
    assert.equal(implementation,'kernel-special',`logical-foundation support missing: ${entry.name}`);
  }
  if(entry.status==='gap'){
    assert.equal(implementation,'missing',`documented gap changed; update policy: ${entry.name}`);
  }
  handbook.push({...entry,implementation,leanSurface:leanRecord?.surfaces??[]});
}

const interfaces=[];
for(const entry of policy.referencedInterfaces){
  const actualCore=preludeNames.has(entry.name);
  const actualStdlib=stdlibNames.has(entry.name);
  const implementation=actualCore?'core-prelude':actualStdlib?'stdlib':'missing';
  if(entry.status==='implemented'){
    assert.notEqual(implementation,'missing',`referenced interface missing: ${entry.name}`);
  }else if(entry.status==='gap'){
    assert.equal(implementation,'missing',`documented interface gap changed; update policy: ${entry.name}`);
  }
  interfaces.push({...entry,implementation,leanSurface:byName.get(entry.name)?.surfaces??[]});
}

const counts={};
for(const name of policy.classificationOrder) counts[name]=0;
for(const record of classified) counts[record.classification]++;

const report={
  schemaVersion:1,
  leanVersion:policy.leanVersion,
  leanCommit:policy.leanCommit,
  sourceCommit:manifest.sourceCommit,
  unionTypeCount:classified.length,
  classificationCounts:counts,
  proofscriptCorePreludeTypeCount:[...preludeNames].filter(n=>byName.has(n)).length,
  proofscriptStdlibLeanTypeCount:[...stdlibNames].filter(n=>byName.has(n)).length,
  handbook,
  referencedInterfaces:interfaces,
  records:classified,
};
fs.writeFileSync(path.join(auditRoot,'lean434-type-coverage.json'),JSON.stringify(report,null,2)+'\n');
fs.writeFileSync(path.join(auditRoot,'lean434-type-coverage-summary.json'),JSON.stringify({
  unionTypeCount:report.unionTypeCount,
  classificationCounts:report.classificationCounts,
  handbookGaps:handbook.filter(x=>x.implementation==='missing').map(x=>x.name),
  referencedInterfaceGaps:interfaces.filter(x=>x.implementation==='missing').map(x=>x.name),
},null,2)+'\n');
console.log('LEAN434_TYPE_COVERAGE: PASS '+JSON.stringify({
  unionTypeCount:report.unionTypeCount,
  classificationCounts:report.classificationCounts,
  handbookGaps:handbook.filter(x=>x.implementation==='missing').map(x=>x.name),
  referencedInterfaceGaps:interfaces.filter(x=>x.implementation==='missing').map(x=>x.name),
}));
