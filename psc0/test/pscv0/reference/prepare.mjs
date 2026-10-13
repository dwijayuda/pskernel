// Reuse successful generated bridge evidence for the 4.35.0-only proof lane.
// Do not execute downloaded JS, regenerate a compiler, or change the theorem.
import assert from 'node:assert/strict';
import { readFile, writeFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../../..');
const dir=path.join(root,'dist/pscv0-bridge');
const hash=x=>createHash('sha256').update(x).digest('hex');
const report=JSON.parse(await readFile(path.join(dir,'build-report.json'),'utf8'));
const origin='1ed94be7b1d3c49f11e302464478be76fa299172';
assert.equal(report.source,origin);
assert.equal(report.builder,'retained self-hosted JavaScript PSC0 compiler');
assert.equal(report.referenceSha256,'a419955383fd3e35d873f82c939ecf3a92dc65b162cc9d0d3cadf5b853a0f4b0');
assert.equal(hash(await readFile(path.join(dir,'index.js'))),report.bridgeJsSha256);
assert.equal(hash(await readFile(path.join(dir,'index.ts'))),report.bridgeTypeScriptSha256);
assert.equal(hash(await readFile(path.join(dir,'bridge.admissions.json'))),report.admissionsSha256);
for(const source of report.closure){
  assert(source.path.startsWith('packages/syntax/src/')||source.path.startsWith('packages/foundation/src/'));
  assert(!source.path.split(/[\\/]/u).includes('..'));
  assert.equal(hash(await readFile(path.join(root,source.path))),source.rawSha256,'source differs from generated bridge: '+source.path);
}
const tap=await readFile(path.join(dir,'tests-linux.tap'),'utf8');
for(const [key,value] of [['tests',38],['pass',38],['fail',0],['cancelled',0],['skipped',0]]){
  const matches=[...tap.matchAll(new RegExp('^# '+key+' ([0-9]+)$','gm'))];
  assert.equal(matches.length,1,'missing or duplicate test summary: '+key);
  assert.equal(Number(matches[0][1]),value,'unexpected '+key+' count');
}
const runtime=JSON.parse(await readFile(path.join(dir,'runtime-report-linux.json'),'utf8'));
assert.equal(runtime.source,origin);assert.equal(runtime.bridgeJsSha256,report.bridgeJsSha256);
assert.equal(runtime.fixtureKernelAdmitted,true);assert.equal(runtime.firstErrorAndValueBehavior,true);
const original=await readFile(path.join(dir,'reference.lean'),'utf8');
const statement='theorem pscv0_do_correspondence (a b : Except String Nat) :\n    referenceProgram a b = loweredProgram a b := by\n';
const parts=original.split(statement);assert.equal(parts.length,2,'correspondence statement changed');
const oldProof='  rfl\n\n#print axioms pscv0_do_correspondence\n';
const caseProof='  cases a <;> cases b <;> rfl\n\n#print axioms pscv0_do_correspondence\n';
assert(parts[1]===oldProof||parts[1]===caseProof,'unexpected proof body');
const checked=parts[0]+statement+caseProof;
await writeFile(path.join(dir,'reference-cases.lean'),checked);
const evidence={schema:'pscv0-retained-bridge-reference-preparation/1',source:process.env.GITHUB_SHA,generatedBridgeSource:origin,generatedBridgeRun:38098425773,generatedBridgeArtifact:11686899111,bridgeJsSha256:report.bridgeJsSha256,bridgeTypeScriptSha256:report.bridgeTypeScriptSha256,builderJsSha256:report.builderJsSha256,closureModules:report.closure.length,portableSourcesUnchangedSinceGeneration:true,linuxTests:38,originalReferenceSha256:hash(original),checkedReferenceSha256:hash(checked),unchangedFunctionsAndStatementSha256:hash(parts[0]+statement),proofBody:'cases a <;> cases b <;> rfl',compilerRegenerated:false,kernelRegenerated:false,leanProofHasNotYetRun:true};
await writeFile(path.join(dir,'reference-preparation.json'),JSON.stringify(evidence,null,2)+'\n');
console.log('PSCV0_RETAINED_REFERENCE_PREPARED: '+JSON.stringify(evidence));
