// Regression for the observed native constructor-pattern projection defect.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
import {projectNativeReferences,validateNativeProjection} from './native-reference-projection.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const out=path.join(root,'dist/native-reference-projection-tests');fs.mkdirSync(out,{recursive:true});
const source=[
 '-- UTF8 before names: façade λ. A comment containing | empty must stay byte-identical.',
 'inductive NativeProjectionSample where',
 '  | empty : NativeProjectionSample',
 '  | item (payload : Nat) : NativeProjectionSample',
 '',
 'def bare (value : NativeProjectionSample) : Nat :=',
 '  match value with',
 '  | empty => 0',
 '  | item payload => payload',
 '',
 'def dotted (value : NativeProjectionSample) : Nat :=',
 '  match value with',
 '  | .empty => 0',
 '  | .item payload => payload',
 '',
 'def qualified (value : NativeProjectionSample) : Nat :=',
 '  match value with',
 '  | NativeProjectionSample.empty => 0',
 '  | NativeProjectionSample.item payload => payload',
 '',
 'def binder (item : Nat) : Nat := item',
 'def marker : String := "| item empty"',
 'def boolPattern (value : Bool) : Nat :=',
 '  match value with',
 '  | true => 1',
 '  | false => 0',
 'def wildcardPattern (value : Nat) : Nat :=',
 '  match value with',
 '  | _ => 42',
 ''
].join('\n');
const sources=[{module:'ProjectionFixture',bytes:Buffer.from(source)}];
const projected=projectNativeReferences({root,out,label:'first',sources});
assert.deepEqual(projected.observations[0].constructorDots.map(dot=>dot.name),['empty','item']);
const after=projected.modules.get('ProjectionFixture');
const second=projectNativeReferences({root,out,label:'second',
 sources:[{module:'ProjectionFixture',bytes:after}]});
assert.ok(second.modules.get('ProjectionFixture').equals(after));
assert.deepEqual(second.observations[0].constructorDots,[]);
const changed=structuredClone(projected.response);changed.modules[0].text+='\n-- unrelated byte change\n';
assert.throws(()=>validateNativeProjection(sources,changed));
const overlapping=structuredClone(projected.response);
overlapping.modules[0].constructorDots.splice(1,0,structuredClone(overlapping.modules[0].constructorDots[0]));
assert.throws(()=>validateNativeProjection(sources,overlapping));
function native(file,expected){
 const result=spawnSync('prlimit',['--as=4294967296','--stack=8388608','--','lake','env','lean',file],
  {cwd:root,encoding:'utf8',timeout:240000,maxBuffer:32*1024*1024,
   env:{...process.env,LEAN_MAIN_USE_THREAD:'0',LEAN_NUM_THREADS:'0',LEAN_STACK_SIZE_KB:'8192'}});
 fs.writeFileSync(file+'.process.json',JSON.stringify({status:result.status,signal:result.signal,
  error:result.error?String(result.error):null,stdout:result.stdout,stderr:result.stderr},null,2)+'\n');
 assert.equal(result.error,undefined);assert.equal(result.signal,null);assert.equal(result.status,expected,
  String(result.stdout)+'\n'+String(result.stderr));
 return result;
}
const beforeFile=path.join(out,'before.lean');fs.writeFileSync(beforeFile,source);
const refusal=native(beforeFile,1);
assert.match(refusal.stdout+refusal.stderr,/Invalid pattern|Redundant alternative|Unknown identifier/);
const afterFile=path.join(out,'after.lean');
fs.writeFileSync(afterFile,Buffer.concat([after,Buffer.from([
 '',
 'example : bare NativeProjectionSample.empty = 0 := rfl',
 'example : bare (NativeProjectionSample.item 42) = 42 := rfl',
 'example : dotted (NativeProjectionSample.item 42) = 42 := rfl',
 'example : qualified (NativeProjectionSample.item 42) = 42 := rfl',
 'example : binder 7 = 7 := rfl',
 'example : marker = "| item empty" := rfl',
 'example : boolPattern true = 1 := rfl',
 'example : boolPattern false = 0 := rfl',
 'example : wildcardPattern 9 = 42 := rfl',
 ''
].join('\n'))]));
native(afterFile,0);
const evidence={schema:'psc1-native-reference-projection-regression/1',status:'passed',
 projected:projected.evidence,idempotent:second.evidence,nativeOriginalRefused:true,
 nativeProjectedCompiled:true,nativeDefinitionalEqualities:9,malformedReportsRefused:2,
 actualPatternInsertions:2,allOtherSourceBytesPreserved:true,admissionAuthority:false};
fs.writeFileSync(path.join(out,'regression.json'),JSON.stringify(evidence,null,2)+'\n');
console.log('PSC1_NATIVE_REFERENCE_PROJECTION_REGRESSION: '+JSON.stringify(evidence));
