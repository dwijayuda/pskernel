import assert from 'node:assert/strict';
import test from 'node:test';
import { execFileSync } from 'node:child_process';
import { canonicalArtifact, artifactId, artifactKey } from './artifact-evidence.mjs';
import { instantiateCanonicalExports } from './canonical-exports.mjs';
import { createCheckedBuildGraph } from './checked-build-evidence.mjs';
import { packObservedBuildArchive, verifyObservedBuildArchive } from './observed-build-archive.mjs';
import { deriveWasmCanonicalArtifacts, verifyWasmCanonicalProjection, verifyWasmCanonicalBinary,
  wasmCanonicalSelectionContract, wasmCanonicalBindingContract, createPortableWasmCanonicalRequest } from './wasm-canonical-artifact.mjs';

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
  const exported=[
    ...['u8','u16','u32','u64','s8','s16','s32','s64','word','sword','f32','f64'].map(name=>[name,'echo-'+name]),
    ['boolean','echo-bool'],['letter','echo-char'],['negative8','negative-eight'],
    ['negative16','negative-sixteen'],['done','done'],
  ];
  const selection=canonicalArtifact({schemaVersion:1,contract:wasmCanonicalSelectionContract,
    wordBits:bits,packageNamespace:'psc',packageName:'scalar',worldName:'world',interfaceName:'api',
    exports:exported.map(([source,foreignName])=>({sourceName:'Source.'+source,foreignName}))},
    'abi-policy',wasmCanonicalSelectionContract);
  const specializedIr=artifact(Buffer.from(packet.sourceJson),'specialized-ir','psc-runtime-ir-json/1');
  const binding=artifact(Buffer.from(packet.bindingJson),'abi-plan',wasmCanonicalBindingContract);
  const targetIr=artifact(Buffer.from(packet.targetJson),'wasm-ir','psc-wasm-ir-json/1');
  const subject={specializedIr,selection,interfaceArtifact,binding,binary,targetIr};
  const projection=verifyWasmCanonicalProjection(subject);
  const signatures=verifyWasmCanonicalBinary(subject);
  assert.equal(projection.projectionChecked,true);
  assert.equal(projection.sourceInvariantsVerified,false);
  assert.equal(signatures.signaturesChecked,true);
  assert.equal(signatures.targetSignaturesChecked,true);
  assert.equal(signatures.preservationVerified,false);
  assert.equal(signatures.guestExecuted,false);
  const bindings=signatures.bindings;
  const api=instantiateCanonicalExports({binary,expectedBinaryId:binary.identity,
    interfaceArtifact,expectedInterfaceId:interfaceArtifact.identity,
    interfaceName:plan.interfaceName,bindings});
  return {packet,plan,binary,api,subject};
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

test('independent projection rejects fresh hashes of mismatched signatures and selection',()=>{
  const {subject}=fixture(32);
  const world=JSON.parse(subject.interfaceArtifact.bytes);
  world[5][0][2][0][2]=['some',['scalar','u16']];
  const wrong=artifact(Buffer.from(JSON.stringify(world)),'interface-ir','psc-interface-ir-json/1');
  assert.throws(()=>verifyWasmCanonicalProjection({...subject,interfaceArtifact:wrong}),/PROJECTION_RELATION/);
  const binding=JSON.parse(subject.binding.bytes);binding.bindings[0].sourceName='Source.u16';
  const changed=canonicalArtifact(binding,'abi-plan',wasmCanonicalBindingContract);
  assert.throws(()=>verifyWasmCanonicalProjection({...subject,binding:changed}),/PROJECTION_RELATION/);
  const policy=JSON.parse(subject.selection.bytes);policy.wordBits=64;
  const selection=canonicalArtifact(policy,'abi-policy',wasmCanonicalSelectionContract);
  assert.throws(()=>verifyWasmCanonicalProjection({...subject,selection}),/PROJECTION_RELATION/);
  const raw=JSON.parse(subject.specializedIr.bytes);raw[4].push(raw[4][0]);
  const duplicated=artifact(Buffer.from(JSON.stringify(raw)),'specialized-ir','psc-runtime-ir-json/1');
  assert.throws(()=>deriveWasmCanonicalArtifacts(duplicated,subject.selection),/DUPLICATE_GLOBAL/);
});

test('signature agreement is explicitly narrower than body validity or preservation',()=>{
  const {subject}=fixture(32),raw=JSON.parse(subject.specializedIr.bytes);
  raw[4][0][4]=['literal',['bool',true]];
  const changed=artifact(Buffer.from(JSON.stringify(raw)),'specialized-ir','psc-runtime-ir-json/1');
  const projection=verifyWasmCanonicalProjection({...subject,specializedIr:changed});
  assert.equal(projection.projectionChecked,true);
  assert.equal(projection.sourceInvariantsVerified,false);
  assert.equal(projection.preservationVerified,false);
  const corrupt=Buffer.from(subject.binary.bytes);corrupt[0]=255;
  assert.throws(()=>verifyWasmCanonicalBinary({...subject,binary:artifact(corrupt,'wasm-binary','webassembly-core/1')}),/ENGINE_VALIDATION/);
});

test('observed build archive independently replays source projection and exact target/binary signatures',async()=>{
  const {subject,packet}=fixture(32);
  const evidence=createCheckedBuildGraph({sourceKind:'lean',sources:['scalar IR fixture'],
    admissions:'{"admissions":[],"format":"proofscript-checked-admissions","version":2}',
    directWasm:subject.binary.bytes,compilerBytes:Buffer.from('native fixture compiler'),
    compilerKind:'test-fixture',provider:{profile:'test-profile'},providerSecurity:{profile:'test-security'},
    kernelContract:{id:'test-kernel'},hostSources:[],runtime:{implementation:'node',version:process.version},
    irStages:{runtimeIr:packet.sourceJson,verifiedIr:packet.sourceJson,specializedIr:packet.sourceJson,wasmIr:packet.targetJson},
    wasmCanonical:{selection:subject.selection,interface:subject.interfaceArtifact,binding:subject.binding}});
  assert.equal(evidence.wasmCanonical.binding.identity.digest,subject.binding.identity.digest);
  assert.equal(evidence.executableArtifact.domain,'wasm-binary');
  const assumptions=new Set();
  for(const id of evidence.graph.executions){
    const execution=JSON.parse(evidence.artifacts.get(artifactKey(id)));
    const definition=JSON.parse(evidence.artifacts.get(artifactKey(execution.passDefinitionId)));
    for(const assumption of definition.assumptionIds)assumptions.add(assumption);
  }
  const archive=packObservedBuildArchive(evidence);
  const verified=await verifyObservedBuildArchive(archive.bytes,{
    expectedGraphId:evidence.identity,allowedAssumptions:[...assumptions]});
  assert.equal(verified.kind,'accepted',verified.reason);
  assert.equal(verified.wasmCanonicalProjections.length,1);
  assert.equal(verified.wasmCanonicalSignatures.length,1);
  assert.equal(verified.wasmCanonicalSignatures[0].targetSignaturesChecked,true);
  assert.equal(verified.preservationVerified,false);
  assert.equal(verified.releaseAccepted,false);
  const wrong=JSON.parse(subject.targetIr.bytes);wrong[6][0][1]='Source.u16';
  const targetIr=artifact(Buffer.from(JSON.stringify(wrong)),'wasm-ir','psc-wasm-ir-json/1');
  assert.throws(()=>verifyWasmCanonicalBinary({...subject,targetIr}),/TARGET_SIGNATURE_RELATION/);
});

for(const bits of [32,64])test('portable Canonical driver retains actual prepared-source stages with '+bits+'-bit words',()=>{
  const packet=JSON.parse(execFileSync('.lake/build/bin/pscv_wasm_canonical_exports_tests',
    ['--prepared'+bits],{encoding:'utf8',timeout:30000,maxBuffer:8*1024*1024}));
  const selection=canonicalArtifact({schemaVersion:1,contract:wasmCanonicalSelectionContract,
    wordBits:bits,packageNamespace:'psc',packageName:'prepared',worldName:'world',interfaceName:'api',
    exports:[{sourceName:'echoWord',foreignName:'echo-word'}]},'abi-policy',wasmCanonicalSelectionContract);
  assert.equal(packet.wire,createPortableWasmCanonicalRequest(selection));
  assert.equal(packet.runtimeIr,packet.verifiedIr);
  const subject={selection,
    specializedIr:artifact(Buffer.from(packet.specializedIr),'specialized-ir','psc-runtime-ir-json/1'),
    targetIr:artifact(Buffer.from(packet.wasmIr),'wasm-ir','psc-wasm-ir-json/1'),
    interfaceArtifact:artifact(Buffer.from(packet.interfaceJson),'interface-ir','psc-interface-ir-json/1'),
    binding:artifact(Buffer.from(packet.bindingJson),'abi-plan',wasmCanonicalBindingContract),
    binary:artifact(packet.binary,'wasm-binary','webassembly-core/1')};
  assert.equal(verifyWasmCanonicalProjection(subject).projectionChecked,true);
  const validated=verifyWasmCanonicalBinary(subject);
  assert.equal(validated.targetSignaturesChecked,true);
  const api=instantiateCanonicalExports({binary:subject.binary,expectedBinaryId:subject.binary.identity,
    interfaceArtifact:subject.interfaceArtifact,expectedInterfaceId:subject.interfaceArtifact.identity,
    interfaceName:'api',bindings:validated.bindings});
  const value=bits===32?4294967295:18446744073709551615n;
  assert.equal(api.exports['echo-word'](value),value);
  assert.deepEqual(Object.keys(api.exports),['echo-word']);
  assert.equal(validated.preservationVerified,false);
});

test('portable Canonical selection wire bounds every string independently',()=>{
  const make=foreignName=>canonicalArtifact({schemaVersion:1,contract:wasmCanonicalSelectionContract,
    wordBits:32,packageNamespace:'psc',packageName:'request',worldName:'world',interfaceName:'api',
    exports:[{sourceName:'selected',foreignName}]},'abi-policy',wasmCanonicalSelectionContract);
  assert.doesNotThrow(()=>createPortableWasmCanonicalRequest(make('a'.repeat(4096))));
  assert.throws(()=>createPortableWasmCanonicalRequest(make('a'.repeat(4097))),/REQUEST_RESOURCE/);
});
