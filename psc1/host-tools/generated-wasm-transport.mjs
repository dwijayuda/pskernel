// Host-only typed transport for owned, import-free WebAssembly GC modules.
// This module has no parser, elaborator, IR transform, or code generator.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
export const WASM_HEX_PREFIX='psc1-wasm-hex/1:';
export const MAX_WIRE_BYTES=128*1024*1024;
const privateNames=new Set([
 '__psc1_service_string_new','__psc1_service_string_set','__psc1_service_string_finish',
 '__psc1_service_string_size','__psc1_service_string_byte','__psc1_service_nat_is_zero',
 '__psc1_service_nat_half','__psc1_service_nat_low','__psc1_service_nat_of_u32',
 '__psc1_service_nat_bit0','__psc1_service_nat_bit1','__psc1_service_int_sign',
 '__psc1_service_int_magnitude','__psc1_service_int_of_nat','__psc1_service_int_neg']);
export function decodeWasmHex(source){
 assert.equal(typeof source,'string');assert.ok(Buffer.byteLength(source)<=MAX_WIRE_BYTES);
 assert.ok(source.startsWith(WASM_HEX_PREFIX),'PSC1_WASM_SOURCE_ENCODING');
 const hex=source.slice(WASM_HEX_PREFIX.length);
 assert.ok(hex.length>0&&hex.length%2===0&&/^[0-9a-f]+$/.test(hex),'PSC1_WASM_SOURCE_HEX');
 const bytes=Buffer.from(hex,'hex');
 assert.ok(bytes.subarray(0,8).equals(Buffer.from([0,97,115,109,1,0,0,0])),'PSC1_WASM_SOURCE_HEADER');
 return bytes;
}
export function loadWasmApi(bytes,publicTypes,publicNames){
 const module=new WebAssembly.Module(bytes);
 assert.deepEqual(WebAssembly.Module.imports(module),[],'PSC1_WASM_NATIVE_DELEGATION_FORBIDDEN');
 const exports=WebAssembly.Module.exports(module);
 assert.ok(exports.every(e=>e.kind==='function'),'PSC1_WASM_TRANSPORT_EXPORT_KIND');
 assert.ok(exports.every(e=>publicNames.includes(e.name)||privateNames.has(e.name)),'PSC1_WASM_TRANSPORT_UNEXPECTED_EXPORT');
 assert.ok(publicNames.every(n=>exports.some(e=>e.name===n)),'PSC1_WASM_PUBLIC_API_MISSING');
 assert.equal(new Set(publicNames).size,publicNames.length);
 assert.equal(publicTypes.length,publicNames.length);
 const instance=new WebAssembly.Instance(module,{}),e=instance.exports;
 const type=t=>{assert.ok(Array.isArray(t)&&t.length===2&&t[0]==='primitive'&&['nat','int','bool','string','unit'].includes(t[1]),'PSC1_WASM_TRANSPORT_UNSUPPORTED_ABI');return t[1];};
 function natIn(value){
  assert.equal(typeof value,'bigint');assert.ok(value>=0n);
  const bits=value.toString(2);assert.ok(bits.length<=MAX_WIRE_BYTES*8);
  let out=e.__psc1_service_nat_of_u32(0);
  for(const bit of bits)out=bit==='1'?e.__psc1_service_nat_bit1(out):e.__psc1_service_nat_bit0(out);
  return out;
 }
 function natOut(value){
  let out=0n,place=1n,steps=0;
  while(!e.__psc1_service_nat_is_zero(value)){
   assert.ok(++steps<=MAX_WIRE_BYTES*8,'PSC1_WASM_NAT_WIRE_LIMIT');
   if(e.__psc1_service_nat_low(value))out+=place;
   value=e.__psc1_service_nat_half(value);place<<=1n;
  }
  return out;
 }
 function stringIn(value){
  assert.equal(typeof value,'string');assert.ok(Buffer.byteLength(value)<=MAX_WIRE_BYTES);
  const chars=Array.from(value),builder=e.__psc1_service_string_new(chars.length);
  for(let i=0;i<chars.length;i++){
   const cp=chars[i].codePointAt(0);assert.ok(cp<0xd800||cp>0xdfff,'PSC1_WASM_INVALID_UNICODE_SCALAR');
   e.__psc1_service_string_set(builder,i,cp);
  }
  return e.__psc1_service_string_finish(builder);
 }
 function stringOut(value){
  const length=e.__psc1_service_string_size(value)>>>0;
  assert.ok(length<=MAX_WIRE_BYTES,'PSC1_WASM_STRING_WIRE_LIMIT');
  const bytes=new Uint8Array(length);
  for(let i=0;i<length;i++)bytes[i]=e.__psc1_service_string_byte(value,i);
  return new TextDecoder('utf-8',{fatal:true,ignoreBOM:true}).decode(bytes);
 }
 function to(kind,value){
  if(kind==='nat')return natIn(value);
  if(kind==='string')return stringIn(value);
  if(kind==='bool'){assert.equal(typeof value,'boolean');return value?1:0;}
  if(kind==='unit')return undefined;
  assert.equal(typeof value,'bigint');
  const magnitude=natIn(value<0n?-value:value),positive=e.__psc1_service_int_of_nat(magnitude);
  return value<0n?e.__psc1_service_int_neg(positive):positive;
 }
 function from(kind,value){
  if(kind==='nat')return natOut(value);
  if(kind==='string')return stringOut(value);
  if(kind==='bool'){assert.ok(value===0||value===1);return value===1;}
  if(kind==='unit')return undefined;
  const sign=e.__psc1_service_int_sign(value),magnitude=natOut(e.__psc1_service_int_magnitude(value));
  assert.ok(sign===-1||sign===0||sign===1);assert.equal(sign===0,magnitude===0n);
  return sign<0?-magnitude:magnitude;
 }
 const api={};
 for(const name of publicNames){
  const signature=publicTypes.find(t=>t.name===name);assert.ok(signature);
  const parameters=signature.parameters.map(type),result=type(signature.result);
  const invoke=(...args)=>{assert.equal(args.length,parameters.length);return from(result,e[name](...args.map((a,i)=>to(parameters[i],a))));};
  Object.defineProperty(api,name,{enumerable:true,value:parameters.length===0?invoke():invoke});
 }
 return Object.freeze(api);
}
export function loadWasmArtifact(manifestFile){
 const m=JSON.parse(fs.readFileSync(manifestFile,'utf8'));
 assert.equal(m.target,'wasm-core');assert.equal(m.transport,'psc1-wasm-selfhost-gc/1');
 return loadWasmApi(fs.readFileSync(path.join(path.dirname(manifestFile),'module.wasm')),m.publicTypes,m.publicNames);
}
