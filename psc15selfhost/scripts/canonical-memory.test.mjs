import assert from 'node:assert/strict';
import test from 'node:test';
import { execFileSync } from 'node:child_process';
import { resolve } from 'node:path';
import { artifactId } from './artifact-evidence.mjs';
import { createCanonicalMemoryCodec, prepareCanonicalValueTypes, bindCanonicalValueMemory } from './canonical-memory.mjs';

const executable=resolve('.lake/build/bin/pscv_canonical_abi_tests'+(process.platform==='win32'?'.exe':''));
const [world,layouts32,layouts64,plans32,plans64]=JSON.parse(execFileSync(executable,['--memory-fixture'],{encoding:'utf8',timeout:30000}));
const artifact=value=>{const bytes=Buffer.from(JSON.stringify(value));return {bytes,identity:artifactId(bytes,'interface-ir','psc-interface-ir-json/1')};};
const source=artifact(world);
function setup({pointerBits=32,limits={},grow=false,realloc:override,sourceArtifact=source}={}){
  const memory=new WebAssembly.Memory({initial:2,maximum:8});
  let next=1024, calls=0;
  const realloc=override??((old,size,alignment,length)=>{
    calls++;
    assert.equal(old,pointerBits===32?0:0n);assert.equal(size,pointerBits===32?0:0n);
    if(grow)memory.grow(1);
    assert.equal(typeof alignment,pointerBits===32?'number':'bigint');
    const boundary=Number(alignment), pointer=Math.ceil(next/boundary)*boundary;next=pointer+Number(length);
    return pointerBits===32?pointer:BigInt(pointer);
  });
  const codec=createCanonicalMemoryCodec({interfaceArtifact:sourceArtifact,expectedInterfaceId:sourceArtifact.identity,
    interfaceName:'values',pointerBits,memory,realloc,limits});
  return {memory,codec,calls:()=>calls};
}

test('independent host layouts agree with the portable planner for both pointer widths',()=>{
  for(const [pointerBits,layouts] of [[32,layouts32],[64,layouts64]]){
    const {codec}=setup({pointerBits});
    for(const [name,value] of layouts){
      const actual=codec.layout(name);
      assert.deepEqual([actual.alignment,actual.byteSize,actual.flatCount,actual.flatPrefix,
        actual.fieldOffsets,actual.payloadOffset,actual.needsMemory,actual.needsHandleTable],value,name);
    }
  }
});

test('actual Wasm memory stores aggregates, nested UTF-8/list data, variants and wide integers',()=>{
  for(const pointerBits of [32,64]){
    const {codec,memory}=setup({pointerBits,grow:true});
    const value={name:'\uFEFFλ🙂',data:[0,127,255],constructor:(1n<<64n)-1n,status:{tag:'some',value:42n}};
    codec.store('message',value,64);
    const result=codec.load('message',64);
    assert.equal(Object.getPrototypeOf(result),null);assert.equal(result.name,value.name);
    assert.deepEqual(result.data,value.data);assert.equal(result.constructor,value.constructor);
    assert.deepEqual(result.status,value.status);assert.ok(memory.buffer.byteLength>2*65536);
    codec.store('pair',[1,0x0102030405060708n,0xabcd],256);
    const bytes=new Uint8Array(memory.buffer);
    assert.deepEqual([...bytes.slice(264,272)],[8,7,6,5,4,3,2,1]);
    assert.deepEqual(codec.load('pair',256),[1,0x0102030405060708n,0xabcd]);
    codec.store('outcome',{tag:'error',value:4294967295},320);
    assert.deepEqual(codec.load('outcome',320),{tag:'error',value:4294967295});
    codec.store('outcome',{tag:'ok',value:'ok'},320);
    assert.deepEqual(codec.load('outcome',320),{tag:'ok',value:'ok'});
    codec.store('maybe',{tag:'none'},400);
    assert.deepEqual(codec.load('maybe',400),{tag:'none'});
    codec.store('choice','second',432);assert.equal(codec.load('choice',432),'second');
  }
});

test('value validation snapshots data before allocation or writes',()=>{
  const {codec,memory,calls}=setup();
  new Uint8Array(memory.buffer).fill(77,0,128);
  const before=Buffer.from(new Uint8Array(memory.buffer,0,128));
  let observed=0;
  const bad={name:'ok',data:[1],constructor:1n,status:{tag:'some',value:-1n}};
  assert.throws(()=>codec.store('message',bad,0),/INTEGER/);
  assert.equal(calls(),0);assert.deepEqual(Buffer.from(memory.buffer,0,128),before);
  Object.defineProperty(bad,'status',{get(){observed++;return {tag:'none'};}});
  assert.throws(()=>codec.store('message',bad,0),/DATA_PROPERTY/);
  assert.equal(observed,0);assert.equal(calls(),0);
  assert.throws(()=>codec.store('bytes',[,1],0),/ARRAY/);
  assert.throws(()=>codec.store('text','\uD800',0),/STRING/);
});

test('memory loads enforce alignment, bounds, UTF-8, characters and discriminants',()=>{
  const {codec,memory}=setup(),view=new DataView(memory.buffer);
  assert.throws(()=>codec.load('wide',1),/MEMORY_RANGE/);
  assert.throws(()=>codec.load('wide',memory.buffer.byteLength),/MEMORY_RANGE/);
  view.setUint32(0,512,true);view.setUint32(4,2,true);
  new Uint8Array(memory.buffer,512,2).set([0xc0,0x80]);
  assert.throws(()=>codec.load('text',0),/UTF8/);
  view.setUint32(0,0xd800,true);assert.throws(()=>codec.load('letter',0),/CHAR/);
  view.setUint8(0,2);assert.throws(()=>codec.load('choice',0),/VARIANT_TAG/);
  view.setUint8(0,255);assert.equal(codec.load('boolean',0),true);
  view.setUint32(0,0,true);view.setUint32(4,0xffffffff,true);
  assert.throws(()=>codec.load('bytes',0),/NODE_LIMIT|BYTE_LIMIT/);
});

test('memory64 pointers cannot silently lose precision',()=>{
  const {codec,memory}=setup({pointerBits:64}),view=new DataView(memory.buffer);
  view.setBigUint64(0,1n<<63n,true);view.setBigUint64(8,1n,true);
  assert.throws(()=>codec.load('text',0),/MEMORY_RANGE/);
});

test('signed integers and float signed zero/NaN preserve the selected value profile',()=>{
  const {codec,memory}=setup();
  codec.store('signed',-32768,0);assert.equal(codec.load('signed',0),-32768);
  codec.store('single',-0,4);assert.ok(Object.is(codec.load('single',4),-0));
  codec.store('single',NaN,4);assert.ok(Number.isNaN(codec.load('single',4)));
  assert.equal(new DataView(memory.buffer).getUint32(4,true),0x7fc00000);
  assert.throws(()=>codec.store('single',1/3,4),/FLOAT/);
  codec.store('letter','🙂',8);assert.equal(codec.load('letter',8),'🙂');
});

test('consumer identity, value budgets and allocator contracts fail closed',()=>{
  const memory=new WebAssembly.Memory({initial:1});
  assert.throws(()=>createCanonicalMemoryCodec({interfaceArtifact:source,expectedInterfaceId:artifact(['wrong']).identity,
    interfaceName:'values',memory}),/INTERFACE_ID/);
  const bounded=setup({limits:{maxNodes:3,maxBytes:32}});
  assert.throws(()=>bounded.codec.store('bytes',[1,2,3,4],0),/ARRAY|NODE_LIMIT/);
  assert.equal(bounded.calls(),0);
  assert.throws(()=>setup({realloc:()=>1}).codec.store('wide-list',[1n],0),/MEMORY_RANGE/);
  assert.throws(()=>setup({realloc:()=>9999999}).codec.store('text','a',0),/MEMORY_RANGE/);
  const noAllocator=createCanonicalMemoryCodec({interfaceArtifact:source,expectedInterfaceId:source.identity,interfaceName:'values',memory});
  assert.throws(()=>noAllocator.store('text','a',0),/REALLOC_REQUIRED/);
  const shared=new WebAssembly.Memory({initial:1,maximum:1,shared:true});
  assert.throws(()=>createCanonicalMemoryCodec({interfaceArtifact:source,expectedInterfaceId:source.identity,interfaceName:'values',memory:shared}),/SHARED_MEMORY/);
});

test('cyclic definitions and handles cannot become raw value codecs',()=>{
  const changed=structuredClone(world);
  changed[5][0][1].push(['loop',['alias',['named','loop']]]);
  assert.throws(()=>setup({sourceArtifact:artifact(changed)}),/TYPE_GRAPH/);
  const handles=structuredClone(world);
  handles[5][0][1].push(['file',['resource']],['handle',['alias',['own','file']]]);
  const {codec}=setup({sourceArtifact:artifact(handles)});
  assert.throws(()=>codec.store('handle',1,0),/HANDLE_TABLE_REQUIRED/);
});

test('memory64 realloc uses four i64 arguments against an actual Wasm function',()=>{
  const bytes=new Uint8Array([0,97,115,109,1,0,0,0,
    1,9,1,96,4,126,126,126,126,1,126,3,2,1,0,
    7,11,1,7,114,101,97,108,108,111,99,0,0,10,7,1,5,0,66,128,8,11]);
  const instance=new WebAssembly.Instance(new WebAssembly.Module(bytes));
  const {codec}=setup({pointerBits:64,realloc:instance.exports.realloc});
  codec.store('text','abc',0);assert.equal(codec.load('text',0),'abc');
});

test('core integer values use the Wasm JS signed bit representation',()=>{
  const {codec}=setup();
  const echo=new WebAssembly.Instance(new WebAssembly.Module(new Uint8Array([
    0,97,115,109,1,0,0,0,1,6,1,96,1,126,1,126,3,2,1,0,
    7,8,1,4,101,99,104,111,0,0,10,6,1,4,0,32,0,11]))).exports.echo;
  const core=codec.lowerValue('wide',(1n<<64n)-1n);
  assert.deepEqual(core,[-1n]);
  assert.equal(codec.liftValue('wide',[echo(...core)]),(1n<<64n)-1n);
  assert.deepEqual(codec.lowerValue('signed',-32768),[-32768]);
  assert.equal(codec.liftValue('signed',[0x12348000]),-32768);
  assert.equal(codec.liftValue('boolean',[-1]),true);
  assert.throws(()=>codec.liftValue('wide',[1]),/CORE_I64/);
  assert.throws(()=>codec.liftValue('signed',[4294967295]),/CORE_I32/);
});

test('variant joins use bit reinterpretation and zero extension, then discard unused payloads',()=>{
  const {codec}=setup();
  assert.deepEqual(codec.lowerValue('mixed',{tag:'narrow',value:-0}),[0,2147483648n]);
  assert.deepEqual(codec.lowerValue('mixed',{tag:'wide',value:-0}),[1,-(1n<<63n)]);
  assert.deepEqual(codec.lowerValue('mixed',{tag:'count',value:4294967295}),[2,4294967295n]);
  assert.deepEqual(codec.lowerValue('mixed',{tag:'absent'}),[3,0n]);
  assert.ok(Object.is(codec.liftValue('mixed',[0,2147483648n]).value,-0));
  assert.ok(Object.is(codec.liftValue('mixed',[1,-(1n<<63n)]).value,-0));
  assert.deepEqual(codec.liftValue('mixed',[3,-1n]),{tag:'absent'});
  assert.deepEqual(codec.liftValue('mixed',[2,-1n]),{tag:'count',value:4294967295});
  assert.throws(()=>codec.liftValue('mixed',[4,0n]),/VARIANT_TAG/);
});

test('flat and indirect aggregate paths share memory/value semantics',()=>{
  for(const pointerBits of [32,64]){
    const {codec}=setup({pointerBits});
    const pair=[7,99n,65535];
    const direct=codec.lowerValue('pair',pair);
    assert.deepEqual(direct,pair);assert.deepEqual(codec.liftValue('pair',direct),pair);
    const indirect=codec.lowerValue('pair',pair,{maxFlat:1});
    assert.equal(indirect.length,1);
    assert.deepEqual(codec.liftValue('pair',indirect,{maxFlat:1}),pair);
    assert.deepEqual(codec.lowerValue('pair',pair,{maxFlat:1,outPointer:256}),[]);
    assert.deepEqual(codec.load('pair',256),pair);
    const bulk=Array.from({length:17},(_,i)=>i);
    const pointer=codec.lowerValue('bulk',bulk);
    assert.equal(pointer.length,1);assert.deepEqual(codec.liftValue('bulk',pointer),bulk);
    const text=codec.lowerValue('text','λ🙂');
    assert.equal(text.length,2);assert.equal(codec.liftValue('text',text),'λ🙂');
    const list=codec.lowerValue('bytes',[0,127,255]);
    assert.deepEqual(codec.liftValue('bytes',list),[0,127,255]);
    assert.throws(()=>codec.lowerValue('pair',pair,{outPointer:256}),/UNEXPECTED_OUT_POINTER/);
    assert.throws(()=>codec.liftValue('pair',direct,{maxFlat:2}),/FLAT_LIMIT/);
  }
});

test('pure function plans agree with portable lift/lower signatures before memory attachment',()=>{
  for(const [pointerBits,plans] of [[32,plans32],[64,plans64]]){
    const prepared=prepareCanonicalValueTypes({interfaceArtifact:source,expectedInterfaceId:source.identity,
      interfaceName:'values',pointerBits});
    for(const [name,direction,parameters,results] of plans){
      const plan=prepared.describeFunction(name);
      assert.deepEqual(plan[direction].parameters,parameters);
      assert.deepEqual(plan[direction].results,results);
    }
    assert.throws(()=>bindCanonicalValueMemory({...prepared}),/PREPARED_INTERFACE/);
    const codec=bindCanonicalValueMemory(prepared);
    assert.deepEqual(codec.lowerArguments('count',[]),[]);
    assert.equal(codec.liftResult('count',[42]),42);
    assert.throws(()=>codec.lowerArguments('echo-text',['x']),/REALLOC_REQUIRED/);
  }
});
