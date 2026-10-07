import assert from 'node:assert/strict';
import test from 'node:test';
import { artifactId } from './artifact-evidence.mjs';
import { instantiateCanonicalExports } from './canonical-exports.mjs';
const u32=value=>{const out=[];do{let byte=value%128;value=Math.floor(value/128);if(value)byte|=128;out.push(byte);}while(value);return out;};
const name=value=>{const bytes=[...Buffer.from(value)];return [...u32(bytes.length),...bytes];};
const section=(id,data)=>[id,...u32(data.length),...data];
const body=bytes=>[...u32(bytes.length),...bytes];
const scalar=value=>['scalar',value],result=value=>['some',scalar(value)];
const fn=(name,parameters,returned)=>[name,parameters,returned,false,['component-model']];
const world=['psc-interface-ir-json/1','psc-foreign-interface/1','psc','binding','world',[
  ['api',[],[
    fn('echo-wide',[['x',scalar('u64')]],result('u64')),
    fn('echo-text',[['x',scalar('string')]],result('string')),
    fn('count',[],result('u32')),fn('trap',[],result('u32')),fn('bad-text',[],result('string')),
    fn('last',Array.from({length:17},(_,i)=>['x'+i,scalar('u8')]),result('u8')),
  ],['io'],['io']]
],[],['api']];
const artifact=(bytes,domain,contract)=>({bytes:Buffer.from(bytes),identity:artifactId(Buffer.from(bytes),domain,contract)});
const interfaceArtifact=artifact(Buffer.from(JSON.stringify(world)),'interface-ir','psc-interface-ir-json/1');
const header=[0,97,115,109,1,0,0,0];
function moduleBytes(trapPost=false){
  const types=[6,96,1,126,1,126,96,2,127,127,1,127,96,0,1,127,
    96,4,127,127,127,127,1,127,96,1,127,0,96,1,127,1,127];
  const names=['wide','text','count','trap','realloc','post','bad','last'];
  const exported=[9,...names.flatMap((value,index)=>[...name(value),0,index]),...name('memory'),2,0];
  const bodies=[
    [0,32,0,11],
    [0,65,0,32,0,54,2,0,65,4,32,1,54,2,0,65,0,11],
    [0,35,0,11],[0,0,11],[0,65,128,8,11],
    trapPost?[0,0,11]:[0,35,0,65,1,106,36,0,65,128,8,65,0,58,0,0,11],
    [0,65,255,255,3,11],[0,32,0,45,0,16,11],
  ];
  return [...header,...section(1,types),...section(3,[8,0,1,2,2,3,4,2,5]),
    ...section(5,[1,0,1]),...section(6,[1,127,1,65,0,11]),...section(7,exported),
    ...section(10,[bodies.length,...bodies.flatMap(body)])];
}
const binary=artifact(moduleBytes(),'wasm-binary','webassembly-core/1');
const bindings=[
  {functionName:'echo-wide',coreExport:'wide'},
  {functionName:'echo-text',coreExport:'text',postReturn:'post'},
  {functionName:'count',coreExport:'count'},{functionName:'trap',coreExport:'trap'},
  {functionName:'bad-text',coreExport:'bad',postReturn:'post'},
  {functionName:'last',coreExport:'last'},
];
const options={binary,expectedBinaryId:binary.identity,interfaceArtifact,expectedInterfaceId:interfaceArtifact.identity,
  interfaceName:'api',bindings,memoryExport:'memory',reallocExport:'realloc',grantedCapabilities:['io']};
const instantiate=overrides=>instantiateCanonicalExports({...options,...overrides});

test('actual closed Wasm exports lift values and copy results before post-return',()=>{
  const runtime=instantiate();
  assert.equal(runtime.exports['echo-wide']((1n<<64n)-1n),(1n<<64n)-1n);
  assert.equal(runtime.exports.count(),0);
  assert.equal(runtime.exports['echo-text']('λ🙂'),'λ🙂');
  assert.equal(runtime.exports.count(),1);
  assert.equal(runtime.exports['echo-text']('next'),'next');
  assert.equal(runtime.exports.count(),2);
  assert.equal(runtime.exports.last(...Array.from({length:17},(_,i)=>i)),16);
  assert.equal(runtime.state(),'ready');
  assert.equal(Object.getPrototypeOf(runtime.exports),null);
});

test('all signatures, capabilities, memory and allocator requirements are checked before binding',()=>{
  assert.throws(()=>instantiate({grantedCapabilities:[]}),/CAPABILITY_DENIED/);
  assert.throws(()=>instantiate({bindings:[{functionName:'echo-wide',coreExport:'count'}]}),/SIGNATURE_MISMATCH/);
  assert.throws(()=>instantiate({bindings:[{functionName:'echo-text',coreExport:'text',postReturn:'count'}]}),/SIGNATURE_MISMATCH/);
  assert.throws(()=>instantiate({reallocExport:undefined}),/REALLOC_REQUIRED/);
  assert.throws(()=>instantiate({reallocExport:undefined,memoryExport:undefined}),/MEMORY_REQUIRED/);
  assert.throws(()=>instantiate({pointerBits:64,reallocExport:undefined,bindings:[bindings[0]]}),/MEMORY_MISMATCH/);
  assert.throws(()=>instantiate({bindings:[bindings[0],bindings[0]]}),/DUPLICATE_BINDING/);
});

test('numeric bindings do not require an unused memory or allocator',()=>{
  const runtime=instantiate({bindings:[bindings[0]],memoryExport:undefined,reallocExport:undefined});
  assert.equal(runtime.exports['echo-wide'](42n),42n);
  assert.throws(()=>runtime.exports['echo-wide'](),/ARITY/);
  assert.equal(runtime.state(),'ready');
});

test('callee, result-lifting and post-return failures trap the adapter instance',()=>{
  const trapped=instantiate();assert.throws(()=>trapped.exports.trap(),WebAssembly.RuntimeError);
  assert.equal(trapped.state(),'trapped');assert.throws(()=>trapped.exports.count(),/INSTANCE_TRAPPED/);
  const badResult=instantiate();assert.throws(()=>badResult.exports['bad-text'](),/MEMORY_RANGE/);
  assert.equal(badResult.state(),'trapped');
  const bad=artifact(moduleBytes(true),'wasm-binary','webassembly-core/1');
  const badPost=instantiate({binary:bad,expectedBinaryId:bad.identity});
  assert.throws(()=>badPost.exports['echo-text']('copied'),WebAssembly.RuntimeError);
  assert.equal(badPost.state(),'trapped');
});

test('start functions and core imports are outside the closed binding profile',()=>{
  const start=artifact([...header,...section(1,[1,96,0,0]),...section(3,[1,0]),
    ...section(8,[0]),...section(10,[1,2,0,11])],'wasm-binary','webassembly-core/1');
  assert.throws(()=>instantiate({binary:start,expectedBinaryId:start.identity}),/START_UNSUPPORTED/);
  const imported=artifact([...header,...section(1,[1,96,0,0]),
    ...section(2,[1,...name('host'),...name('call'),0,0])],'wasm-binary','webassembly-core/1');
  assert.throws(()=>instantiate({binary:imported,expectedBinaryId:imported.identity}),/IMPORTS_UNSUPPORTED/);
});

test('unsupported foreign lifetimes and async profiles reject without being promoted to core handles',()=>{
  const withWorld=value=>{
    const source=artifact(Buffer.from(JSON.stringify(value)),'interface-ir','psc-interface-ir-json/1');
    return {interfaceArtifact:source,expectedInterfaceId:source.identity};
  };
  const asyncWorld=structuredClone(world);asyncWorld[5][0][2][0][3]=true;
  assert.throws(()=>instantiate({...withWorld(asyncWorld),bindings:[bindings[0]]}),/FUNCTION_PROFILE/);
  const handles=structuredClone(world);handles[5][0][1].push(['file',['resource']]);
  handles[5][0][2][0][1][0][1]=['own','file'];
  assert.throws(()=>instantiate({...withWorld(handles),bindings:[bindings[0]]}),/HANDLE_TABLE_REQUIRED/);
  const imports=structuredClone(world);imports[6]=['api'];
  assert.throws(()=>instantiate(withWorld(imports)),/WORLD_PROFILE/);
});
