// Native correspondence for the actual candidate module and its two generated
// projections. This proof gate precedes the costly retained-compiler build.
import assert from 'node:assert/strict';
import { readFile, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const dir=path.join(root,'dist/pscv0-bridge/authoring');
const wanted=process.argv[2];
assert(['4.34.0','4.35.0-rc4'].includes(wanted));
const sha=b=>createHash('sha256').update(b).digest('hex');
const run=args=>{
  const r=spawnSync('lake',['env','lean',...args],{cwd:root,encoding:'utf8',timeout:120000,maxBuffer:4*1024*1024});
  assert(!r.error&&r.status===0,String(r.error||r.stdout||r.stderr));return r.stdout+r.stderr;
};
const version=run(['--version']).trim();
assert(version.includes('version '+wanted+','));
if(wanted==='4.35.0-rc4')assert(version.includes('c29b6dda4f7c20e3eeaa717c4e565663c5cfa364'));
const receipt=JSON.parse(await readFile(path.join(dir,'receipt.json'),'utf8'));
assert.equal(receipt.sourceRevision,process.env.GITHUB_SHA);
assert.equal(receipt.sourcePath,'packages/syntax/src-ps/Ps/Syntax/Translate.ps');
assert.equal(sha(await readFile(path.join(root,receipt.sourcePath))),receipt.sourceSha256);
for(const [file,expected] of Object.entries(receipt.products)){
  assert(!file.includes('/')&&!file.includes('\\'));
  assert.equal(sha(await readFile(path.join(dir,file))),expected,'proof input drift: '+file);
}
const names=['psTranslateLeanToProofScript','psTranslateProofScriptToLean','psCanonicalizeLeanSource','psCanonicalizeProofScriptSource'];
const proofs=[];
for(const file of ['ReadableProof.lean','LoweredProof.lean']){
  const output=run([path.join(dir,file)]);
  for(const name of names)assert(output.includes("'migration_"+name+"' does not depend on any axioms"),output);
  assert(!output.includes('sorryAx'));
  await writeFile(path.join(dir,file+'.'+wanted+'.txt'),output);
  proofs.push({file,sha256:receipt.products[file],theorems:names.map(n=>'migration_'+n),axioms:[]});
  console.log(output.trim());
}
const report={schema:'psc0-pscv0-module-correspondence/1',source:process.env.GITHUB_SHA,run:process.env.GITHUB_RUN_ID,
  lean:version,module:receipt.module,authoritativePsSha256:receipt.sourceSha256,baselineGitBlob:receipt.baselineGitBlob,
  proofs,theoremCount:8,scope:'Both actual generated projections equal the four original translation APIs for every String input; not general compiler or backend correctness',
  fullCompilerBuilt:false,kernelRegenerated:false,newSelfhostFixedPoint:false};
await writeFile(path.join(dir,'proof-'+wanted+'.json'),JSON.stringify(report,null,2)+'\n');
console.log('PSCV0_AUTHORING_CORRESPONDENCE: PASS '+JSON.stringify(report));
