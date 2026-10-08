import assert from 'node:assert/strict';
import test from 'node:test';
import { artifactId } from './artifact-evidence.mjs';
import { inspectWasmCoreArtifact, requireWasmFunctionSignature, requireWasmMemory } from './wasm-core-signatures.mjs';
import { wasmFunctionExports } from './wasm-function-diagnostics.mjs';

const u32=value=>{const result=[];do{let byte=value%128;value=Math.floor(value/128);if(value)byte|=128;result.push(byte);}while(value);return result;};
const name=value=>{const bytes=[...Buffer.from(value)];return [...u32(bytes.length),...bytes];};
const section=(id,data)=>[id,...u32(data.length),...data];
const header=[0,97,115,109,1,0,0,0];
const binary=bytes=>({bytes:Buffer.from(bytes),identity:artifactId(Buffer.from(bytes),'wasm-binary','webassembly-core/1')});
const inspect=(value,limits)=>inspectWasmCoreArtifact({binary:value,expectedBinaryId:value.identity,limits});
const echo=binary([...header,...section(1,[1,96,1,126,1,126]),...section(3,[1,0]),
  ...section(7,[1,...name('echo'),0,0]),...section(10,[1,4,0,32,0,11])]);

test('pinned numeric signatures are read from the same validated module that executes',()=>{
  const value=inspect(echo);
  assert.deepEqual(requireWasmFunctionSignature(value,'echo',['i64'],['i64']).parameters,['i64']);
  const instance=new WebAssembly.Instance(value.module);
  assert.equal(instance.exports.echo(-1n),-1n);
  assert.throws(()=>requireWasmFunctionSignature(value,'echo',['i32'],['i64']),/SIGNATURE_MISMATCH/);
  assert.throws(()=>requireWasmFunctionSignature({...value},'echo',['i64'],['i64']),/INSPECTION_HANDLE/);
  assert.ok(Object.isFrozen(value.functionExports[0].parameters));
});

test('imports offset function indices and inspection does not run an imported start function',()=>{
  const input=binary([...header,...section(1,[2,96,0,0,96,1,127,1,127]),
    ...section(2,[1,...name('host'),...name('observe'),0,0]),...section(3,[1,1]),
    ...section(5,[1,0,1]),...section(7,[2,...name('echo'),0,1,...name('memory'),2,0]),
    ...section(8,[0]),...section(10,[1,4,0,32,0,11])]);
  let calls=0;
  const value=inspect(input);
  assert.equal(calls,0);assert.equal(value.hasStart,true);
  assert.deepEqual(value.imports[0].parameters,[]);
  assert.equal(requireWasmFunctionSignature(value,'echo',['i32'],['i32']).index,1);
  assert.equal(requireWasmMemory(value,'memory',32).minimum,'1');
  assert.throws(()=>requireWasmMemory(value,'memory',64),/MEMORY_MISMATCH/);
  const instance=new WebAssembly.Instance(value.module,{host:{observe(){calls++;}}});
  assert.equal(calls,1);assert.equal(instance.exports.echo(17),17);
});

test('Core 3 recursive groups retain GC type indices before numeric functions',()=>{
  const input=binary([...header,...section(1,[1,78,2,95,0,96,1,127,1,127]),
    ...section(3,[1,1]),...section(7,[1,...name('echo'),0,0]),...section(10,[1,4,0,32,0,11])]);
  const value=inspect(input);
  assert.deepEqual(requireWasmFunctionSignature(value,'echo',['i32'],['i32']).results,['i32']);
  assert.equal(new WebAssembly.Instance(value.module).exports.echo(31),31);
});

test('name inspection preserves Unicode BOM bytes and reference exports cannot match a numeric ABI',()=>{
  const input=binary([...header,...section(1,[1,96,1,111,1,111]),
    ...section(3,[1,0]),...section(7,[1,...name('\uFEFFecho'),0,0]),...section(10,[1,4,0,32,0,11])]);
  const value=inspect(input);
  assert.equal(value.functionExports[0].name,'\uFEFFecho');
  assert.deepEqual(wasmFunctionExports(input.bytes).get(0),['\uFEFFecho']);
  assert.throws(()=>requireWasmFunctionSignature(value,'\uFEFFecho',['i32'],['i32']),/SIGNATURE_MISMATCH/);
  assert.throws(()=>requireWasmFunctionSignature(value,'\uFEFFecho',['externref'],['externref']),/EXPECTED_NUMERIC_SIGNATURE/);
});

test('identity, engine validity, metadata budgets and unsupported shared limits fail closed',()=>{
  assert.throws(()=>inspect(echo,{maxBytes:1}),/BYTE_LIMIT/);
  assert.throws(()=>inspect(echo,{maxEntries:0}),/ENTRY_LIMIT/);
  const changed={bytes:Buffer.from(echo.bytes),identity:echo.identity};changed.bytes[0]=1;
  assert.throws(()=>inspect(changed));
  assert.throws(()=>inspect(binary([0,97,115,109,1,0,0,0,1,255])),/ENGINE_VALIDATION/);
  const shared=binary([...header,...section(5,[1,3,1,1]),...section(7,[1,...name('memory'),2,0])]);
  assert.throws(()=>inspect(shared),/UNSUPPORTED_LIMITS/);
});
