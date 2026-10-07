import assert from 'node:assert/strict';
import test from 'node:test';
import { execFileSync } from 'node:child_process';
import { artifactId } from './artifact-evidence.mjs';
import { instantiateCanonicalExports } from './canonical-exports.mjs';

const artifact=(bytes,domain,contract)=>({bytes:Buffer.from(bytes),identity:artifactId(Buffer.from(bytes),domain,contract)});
function fixture(bits){
  const packet=JSON.parse(execFileSync('.lake/build/bin/pscv_wasm_canonical_exports_tests',
    ['--fixture'+bits],{encoding:'utf8',timeout:30000,maxBuffer:2**20}));
  const binary=artifact(packet.binary,'wasm-binary','webassembly-core/1');
  const interfaceArtifact=artifact(Buffer.from(packet.interfaceJson),'interface-ir','psc-interface-ir-json/1');
  const plan=JSON.parse(packet.bindingJson);
  assert.equal(plan.contract,'psc-wasm-canonical-scalar-exports/1');
  assert.equal(plan.runtimeSemantics,'psc-runtime-semantics/1');
  assert.equal(plan.wordBits,bits);
  const bindings=plan.bindings.map(({functionName,coreExport,sourceName})=>{
    assert.equal(coreExport,functionName);
    assert.ok(sourceName.startsWith('Source.'));
    return {functionName,coreExport};
  });
  const api=instantiateCanonicalExports({binary,expectedBinaryId:binary.identity,
    interfaceArtifact,expectedInterfaceId:interfaceArtifact.identity,
    interfaceName:plan.interfaceName,bindings});
  return {packet,plan,binary,api};
}

for(const bits of [32,64])test('compiler-selected Canonical scalar exports execute with '+bits+'-bit words',()=>{
  const {packet,binary,plan,api}=fixture(bits);
  const world=JSON.parse(packet.interfaceJson),functions=world[5][0][2];
  assert.deepEqual(functions.map(fn=>fn[0]),plan.bindings.map(binding=>binding.functionName));
  assert.deepEqual(WebAssembly.Module.exports(new WebAssembly.Module(binary.bytes)).map(entry=>entry.name),
    plan.bindings.map(binding=>binding.coreExport));
  assert.ok(!Object.hasOwn(api.exports,'Source.hidden'));
  const scalarResults=Object.fromEntries(functions.map(fn=>[fn[0],fn[2]]));
  assert.deepEqual(scalarResults['echo-word'],['some',['scalar',bits===32?'u32':'u64']]);
  assert.deepEqual(scalarResults['echo-sword'],['some',['scalar',bits===32?'s32':'s64']]);
  const cases=[
    ['echo-u8',255],['echo-u16',65535],['echo-u32',4294967295],['echo-u64',18446744073709551615n],
    ['echo-s8',-128],['echo-s16',-32768],['echo-s32',-2147483648],['echo-s64',-9223372036854775808n],
    ['echo-word',bits===32?4294967295:18446744073709551615n],
    ['echo-sword',bits===32?-2147483648:-9223372036854775808n],
    ['echo-f32',-0],['echo-f64',-0],['echo-bool',true],['echo-char','😀']
  ];
  for(const [name,value] of cases)assert.ok(Object.is(api.exports[name](value),value),name);
  assert.equal(api.exports['echo-f32'](Math.fround(1/3)),Math.fround(1/3));
  assert.equal(api.exports['echo-f64'](Infinity),Infinity);
  assert.ok(Number.isNaN(api.exports['echo-f32'](NaN)));
  assert.equal(api.exports['negative-eight'](-1),true);
  assert.equal(api.exports['negative-eight'](127),false);
  assert.equal(api.exports['negative-sixteen'](-32768),true);
  assert.equal(api.exports['negative-sixteen'](32767),false);
  assert.equal(api.exports.done(),undefined);
  assert.equal(api.state(),'ready');
});

test('compiler artifact boundaries reject invalid caller scalar values',()=>{
  const {api}=fixture(32);
  assert.throws(()=>api.exports['echo-u8'](256),/PSC_CANONICAL_MEMORY_/);
  assert.equal(api.state(),'trapped');
  assert.throws(()=>api.exports.done(),/INSTANCE_TRAPPED/);
});
