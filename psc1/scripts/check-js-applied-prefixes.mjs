import assert from 'node:assert/strict';import fs from 'node:fs';
import {readOwnedCompilerSources} from '../host-tools/compiler-source-inputs.mjs';
import {generatedTarget} from '../host-tools/generated-target-profiles.mjs';
function eager(name,body){return new RegExp('let\\s+\\w+(?:(?!:=)[\\s\\S])*:=\\s*'+name+'\\b[^;]*;\\s*fun\\b').test(body);}
const problems=[];let scanned=0;
for(const row of readOwnedCompilerSources(generatedTarget('js').entry)){
 if(!row.module.startsWith('Ps.BackendJs.'))continue;
 for(const block of row.text.split(/(?=^def )/m)){
  const match=/^def\s+([A-Za-z0-9_]+)/.exec(block);if(!match)continue;scanned++;
  if(eager(match[1],block))problems.push({module:row.module,name:match[1]});
 }
}
const original=fs.readFileSync('test/JsAppliedPrefixReference.lean','utf8');
for(const name of ["psVerifiedIrIntDecimalMagnitudeWithFuel","psJsTypeSupportedWithPolicyAndFuel","psJsLowerExprWithPolicyAndFuel","psJsValidationAppendNames","psJsValidationAddBindings","psJsValidateExprWithFuel","psJsTailDrop","psJsTailEtaSuffix","psJsTailCaptureBindings","psJsTailRewriteWithFuel","psJsPrintDeclarationsObservedWith"])assert.ok(eager(name,original),'must reject retained original '+name);
console.log('PSC1_JS_OWNED_PREFIX_SCAN: '+JSON.stringify({scanned,problems,originalsRejected:11}));
assert.deepEqual(problems,[],'owned JS eager recursive prefix regressed');
