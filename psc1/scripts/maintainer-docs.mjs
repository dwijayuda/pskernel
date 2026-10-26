// Documentation consistency only. This script grants no runtime or qualification authority.
import fs from 'node:fs';
import assert from 'node:assert/strict';
const contract=JSON.parse(fs.readFileSync('NPM_DISTRIBUTION_CONTRACT.json'));
const provider=JSON.parse(fs.readFileSync('BACKEND_PROVIDER_CONTRACT.json'));
const receipt=JSON.parse(fs.readFileSync('docs/PSC1_CHECKED_DISPATCH_QUALIFICATION_2026-10-26.json'));
const active=contract.activeMilestone;
assert.deepEqual(active.checkedTargets,receipt.scope.checkedTargets);
assert.deepEqual(active.compilerTargetMapping,receipt.scope.compilerTargetMapping);
assert.equal(receipt.exactCandidateReplay.conclusion,'success');
assert.equal(receipt.exactCandidateReplay.run,40250645368);
assert.equal(receipt.sourceRun.status,'passed');
assert.equal(receipt.root.sha256,'d4a0e963375366ac9b417dd1e9eb5372168c25c5230d3ce69f694274daa87043');
assert.ok(!active.status.includes('pending'));
assert.ok(!provider.generatedHostDispatch.platformQualification.startsWith('pending'));
assert.equal(active.fullCrossPlatformRelease,false);
assert.equal(provider.generatedHostDispatch.publicationAuthority,'single-use checked core host');
const consumers={
  "js": "No additional SDK",
  "ts": "Optional TypeScript 7.0.2 + pinned Linux x64 dependency",
  "rust": "Optional Rust consumer .6 + exact Rust 1.90.0 SDK",
  "wasm-core": "Existing GC core; no additional SDK",
  "wasm-component": "Optional pinned wasm-tools; closed Bool ABI",
  "python": "Optional provider + bundled Python 3.14.8",
  "php": "Optional provider + bundled PHP 8.5.12/GMP"
};
const rows=active.checkedTargets.map(t=>'| `'+t+'` | `'+(active.compilerTargetMapping[t]??t)+'` | '+consumers[t]+' |').join('\n');
const sources=[
  [
    "capture",
    "host/src/Ps/Host/SourceSnapshot.lean",
    "psHostCaptureProject",
    "Capture exact dependency-ordered source bytes"
  ],
  [
    "parse",
    "packages/compiler/src/Ps/Compiler/Api.lean",
    "psCompilerParseSource",
    "Choose one grammar and produce shared syntax"
  ],
  [
    "elaborate",
    "packages/elab/src/Ps/Elab/Declaration.lean",
    "psElabModuleWithOrigins",
    "Resolve and type declarations with actual ownership"
  ],
  [
    "encode",
    "packages/compiler/src/Ps/Compiler/Api.lean",
    "psCompilerPrepareElaboratedWithOutput",
    "Encode canonical logical admissions"
  ],
  [
    "admit",
    "host/src/Ps/Host/LeanChecked.lean",
    "psHostLeanCheckPrepared",
    "Require official independent logical acceptance"
  ],
  [
    "erase",
    "packages/compiler/src/Ps/Compiler/Api.lean",
    "psCompilerVerifiedIrFromPrepared",
    "Erase from the same prepared declarations"
  ],
  [
    "validate",
    "packages/compiler-ir/src/Ps/CompilerIr/Validate.lean",
    "psStrictValidateModule",
    "Validate executable IR"
  ],
  [
    "plan",
    "packages/backend-common/src/Ps/BackendCommon/Plan.lean",
    "psBackendClosedPlanDetailed",
    "Specialize the closed public target plan"
  ],
  [
    "emit",
    "host/src/Ps/Host/DirectBackend.lean",
    "jsSource",
    "Lower, validate and print JS"
  ],
  [
    "publish",
    "host-tools/artifacts.mjs",
    "export function publish(",
    "Seal and publish the native bundle"
  ],
  [
    "runtime-needs",
    "packages/backend-wasm/src/Ps/BackendWasm/Lower/RuntimeNeeds.lean",
    "psWasmModuleUsesNat",
    "Select Wasm runtime dependencies"
  ]
];
const links=sources.slice(0,-1).map(([id,file,symbol,description])=>{
 const lines=fs.readFileSync(file,'utf8').split('\n');
 const i=lines.findIndex(l=>l.startsWith('def '+symbol)||l.startsWith('private def '+symbol)||l.startsWith(symbol));
 assert.ok(i>=0,'missing documented symbol '+file+':'+symbol);
 return '| '+id+' | ['+symbol+'](../../'+file+'#L'+(i+1)+') | '+description+' |';
}).join('\n');
function block(file,name,content){
 let text=fs.readFileSync(file,'utf8');
 const start='<!-- '+name+':start -->',end='<!-- '+name+':end -->';
 assert.equal(text.split(start).length,2);assert.equal(text.split(end).length,2);
 const a=text.indexOf(start)+start.length,b=text.indexOf(end);
 const expected='\n'+content+'\n';
 if(process.argv.includes('--write')){text=text.slice(0,a)+expected+text.slice(b);fs.writeFileSync(file,text);}
 assert.equal(text.slice(a,b),expected,'documentation drift: '+file+'; regenerate in Linux CI with --write');
}
block('docs/PSC1_CAPABILITIES.md','generated-capabilities','| Requested target | Compiler target | Explicit output consumer |\n| --- | --- | --- |\n'+rows);
block('docs/guides/compilation-walkthrough.md','generated-pass-links','| Step | Source entry | Responsibility |\n| --- | --- | --- |\n'+links);
const architecture=fs.readFileSync('ARCHITECTURE.md','utf8');
assert.ok(!architecture.includes('current slim checked API publishes JS;'));
assert.ok(architecture.includes('seven checked output'));
const exercise=fs.readFileSync('docs/development/maintainer-exercise.md','utf8');
assert.ok(exercise.includes('human trial remains pending'));
assert.ok(exercise.includes('without AI'));
fs.mkdirSync('dist/maintainability',{recursive:true});
const result={schema:'psc1-maintainer-documentation/1',testedCommit:process.env.GITHUB_SHA,status:'passed',checkedTargets:active.checkedTargets,sourceEntries:sources.length,qualifiedInstalledPackageCommit:receipt.candidateProducer.sourceCommit,qualifiedPackageSourceDistinctFromDevelopment:true,humanUsability:'pending-independent-human-trial'};
fs.writeFileSync('dist/maintainability/documentation.json',JSON.stringify(result,null,2)+'\n');
console.log('PSC1_MAINTAINER_DOCS: '+JSON.stringify(result));
