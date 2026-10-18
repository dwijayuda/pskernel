// Reference-only qualification: verify and prove the retained generated fixture.
// This script never executes downloaded JavaScript or regenerates a compiler.
import assert from 'node:assert/strict';
import { readFile, writeFile } from 'node:fs/promises';
import { execFileSync, spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const dir=path.join(root,'dist/pscv0-bridge');
const windows=path.join(root,'dist/pscv0-windows');
const reference=path.join(root,'test/pscv0/reference');
const origin='1ed94be7b1d3c49f11e302464478be76fa299172';
const upstream='eb6cafb7290e8bd5f2937522d8d804f58f02bafc';
const hash=x=>createHash('sha256').update(x).digest('hex');
const readJson=async file=>JSON.parse(await readFile(file,'utf8'));
const runRecord=await readJson(path.join(dir,'origin-run.json'));
const jobsRecord=await readJson(path.join(dir,'origin-jobs.json'));
assert.equal(runRecord.id,38098425773);
assert.equal(runRecord.head_sha,origin);
assert.equal(runRecord.head_branch,'psc0/pscv0-readable-selfhost-v1');
assert.equal(runRecord.status,'completed');
assert.equal(runRecord.run_attempt,1);
assert.equal(runRecord.conclusion,'failure'); // The historical failed 4.35.0 job stays failed.
for(const [id,name] of [[114349106754,'bridge'],[114351167496,'windows']]) {
  const matches=jobsRecord.jobs.filter(j=>j.id===id);
  assert.equal(matches.length,1,'missing origin job');
  assert.equal(matches[0].name,name);assert.equal(matches[0].conclusion,'success');
  assert.equal(matches[0].run_id,38098425773);
}
const build=await readJson(path.join(dir,'build-report.json'));
const windowsReport=await readJson(path.join(windows,'runtime-report-win32.json'));
const windowsTap=await readFile(path.join(windows,'tests-windows.tap'),'utf8');
for(const [key,value] of [['tests',38],['pass',38],['fail',0],['cancelled',0],['skipped',0]]) {
  const matches=[...windowsTap.matchAll(new RegExp('^# '+key+' ([0-9]+)$','gm'))];
  assert.equal(matches.length,1,'missing Windows summary: '+key);
  assert.equal(Number(matches[0][1]),value,'unexpected Windows '+key);
}
assert.equal(windowsReport.source,origin);assert.equal(windowsReport.platform,'win32');
assert.equal(windowsReport.bridgeJsSha256,build.bridgeJsSha256);
assert.equal(windowsReport.fixtureKernelAdmitted,true);
assert.equal(windowsReport.firstErrorAndValueBehavior,true);
const preparation=execFileSync(process.execPath,[path.join(reference,'prepare.mjs')],{cwd:root,encoding:'utf8',timeout:30000,maxBuffer:2*1024*1024});
process.stdout.write(preparation);
const prepared=await readJson(path.join(dir,'reference-preparation.json'));
const linuxReport=await readJson(path.join(dir,'runtime-report-linux.json'));
assert.equal(linuxReport.fixtureAdmissionSha256,windowsReport.fixtureAdmissionSha256,'platform admission mismatch');
assert.equal((await readFile(path.join(reference,'lean-toolchain'),'utf8')).trim(),'leanprover/lean4:v4.35.0');
function lean(args) {
  const result=spawnSync('lean',args,{cwd:reference,encoding:'utf8',timeout:120000,maxBuffer:4*1024*1024});
  if(result.error)throw result.error;
  return {status:result.status,text:result.stdout+result.stderr};
}
const version=lean(['--version']);assert.equal(version.status,0);
assert(version.text.includes('4.35.0')&&version.text.includes(upstream.slice(0,7)),'wrong reference Lean binary');
await writeFile(path.join(dir,'lean-version.txt'),version.text);
const file=path.join(dir,'reference-cases.lean');
const input=await readFile(file,'utf8');
assert.equal(hash(input),prepared.checkedReferenceSha256);
const checked=lean([file]);await writeFile(path.join(dir,'reference-proof.txt'),checked.text);
process.stdout.write(version.text+checked.text);
assert.equal(checked.status,0,'the actual generated fixture equality failed');
assert.match(checked.text,/pscv0_do_correspondence[^\n]*does not depend on any axioms/u,'fixture proof has unaccounted assumptions');
const marker='theorem pscv0_do_correspondence (a b : Except String Nat) :\n';
const split=input.split(marker);assert.equal(split.length,2);
// A known-false ground instance confirms that the reference lane is checking
// proof terms, not just accepting arbitrary generated text or a success flag.
const falseSource=split[0]+'theorem pscv0_reference_negative :\n    referenceProgram (Except.ok 0) (Except.ok 0) = Except.error "not a successful result" := by\n  rfl\n';
const falseFile=path.join(dir,'reference-negative.lean');
await writeFile(falseFile,falseSource);
const refusal=lean([falseFile]);await writeFile(path.join(dir,'reference-negative.txt'),refusal.text);
assert.equal(refusal.status,1,'known-false equation did not produce Lean checking failure');
assert.match(refusal.text,/rfl/,'negative control failed outside its proof');
const rechecked=lean([file]);assert.equal(rechecked.status,0,'reference environment failed after negative control');
assert.equal(rechecked.text,checked.text,'reference proof evidence changed');
const report={schema:'pscv0-lean435-generated-fixture-qualification/1',source:process.env.GITHUB_SHA,run:Number(process.env.GITHUB_RUN_ID),generatedBridgeSource:origin,generatedBridgeRun:38098425773,generatedBridgeArtifact:11686899111,windowsArtifact:11686158753,upstreamLeanCommit:upstream,leanVersion:version.text.trim(),bridgeJsSha256:build.bridgeJsSha256,bridgeTypeScriptSha256:build.bridgeTypeScriptSha256,builderJsSha256:build.builderJsSha256,closureModules:build.closure.length,portableSourcesCheckedAgainstBuild:true,linuxTests:38,windowsTests:38,fixtureCount:linuxReport.fixtureCount,fixtureAdmissionsSha256:linuxReport.fixtureAdmissionSha256,fixtureKernelAdmitted:true,referenceInputSha256:hash(input),unchangedFunctionsAndStatementSha256:prepared.unchangedFunctionsAndStatementSha256,referenceOutputSha256:hash(checked.text),fixtureTheorem:'pscv0_do_correspondence',fixtureTheoremAxioms:[],negativeProofRefused:true,positiveProofRechecked:true,scope:'equality of the two generated fixture functions for all Except inputs; not a general compiler theorem',downloadedJavaScriptExecuted:false,compilerRegenerated:false,kernelRegenerated:false,newFullSelfhostFixedPoint:false,fullPscv0Conformance:false};
await writeFile(path.join(dir,'reference-qualification.json'),JSON.stringify(report,null,2)+'\n');
console.log('PSCV0_4.35.0_RETAINED_BRIDGE: PASS '+JSON.stringify(report));
