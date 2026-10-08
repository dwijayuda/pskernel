import { artifactId, artifactKey, canonicalArtifact, canonicalBytes, verifyArtifact } from './artifact-evidence.mjs';
import { decodeComparatorJson } from './comparator-export.mjs';
import { decodeIrArtifact, irEncodingContract } from './ir-artifact.mjs';
import { decodeWasmIrArtifact, wasmIrEncodingContract } from './target-ir-artifact.mjs';
import { decodeInterfaceIrArtifact, interfaceIrEncodingContract } from './interface-ir-artifact.mjs';
import { prepareCanonicalValueTypes } from './canonical-memory.mjs';
import { inspectWasmCoreArtifact, requireWasmFunctionSignature } from './wasm-core-signatures.mjs';

export const wasmCanonicalSelectionContract='psc-wasm-canonical-selection/1';
export const wasmCanonicalRequestContract='psc-wasm-canonical-request/1';
export const wasmCanonicalBindingContract='psc-wasm-canonical-scalar-exports/1';
export const wasmCanonicalProjectionRelation='psc-specialized-ir-canonical-scalar-interface/1';
export const wasmCanonicalBinaryRelation='psc-wasm-canonical-scalar-export-signatures/1';
const fail=code=>{throw new Error('PSC_WASM_CANONICAL_ARTIFACT_'+code);};
const exact=(value,fields)=>{
  if(!value||typeof value!=='object'||Array.isArray(value)||
      Object.keys(value).sort().join(',')!==[...fields].sort().join(','))fail('SCHEMA');
};
const name=value=>typeof value==='string'&&/^[a-z][a-z0-9]*(?:-[a-z][a-z0-9]*)*(?![\s\S])/u.test(value);
const text=value=>typeof value==='string'&&value.length>0&&value.isWellFormed()&&Buffer.byteLength(value)<=4096;
const artifact=(bytes,domain,contract)=>({bytes:Buffer.from(bytes),identity:artifactId(bytes,domain,contract)});

export function decodeWasmCanonicalSelection(bytes){
  const value=decodeComparatorJson(bytes,{maxBytes:1024*1024,maxDepth:8,maxNodes:8192});
  exact(value,['schemaVersion','contract','wordBits','packageNamespace','packageName','worldName','interfaceName','exports']);
  if(value.schemaVersion!==1||value.contract!==wasmCanonicalSelectionContract||
      ![32,64].includes(value.wordBits)||
      ![value.packageNamespace,value.packageName,value.worldName,value.interfaceName].every(name)||
      value.worldName===value.interfaceName||!Array.isArray(value.exports)||
      value.exports.length<1||value.exports.length>1024)fail('SELECTION');
  const seen=new Set();
  for(const entry of value.exports){
    exact(entry,['sourceName','foreignName']);
    if(!text(entry.sourceName)||!name(entry.foreignName)||seen.has(entry.foreignName))fail('EXPORT_SELECTION');
    seen.add(entry.foreignName);Object.freeze(entry);
  }
  Object.freeze(value.exports);return Object.freeze(value);
}

function checked(input,domain,contract){
  if(!input||!(input.bytes instanceof Uint8Array))fail('ARTIFACT');
  verifyArtifact(input.bytes,input.identity);
  if(input.identity.domain!==domain||input.identity.contract!==contract)fail('INPUT_CONTRACT');
  return input;
}
/** Bounded constructor-independent request for the portable driver. The policy
 * identity is retained separately in the graph; this wire never supplies types.
 */
export function createPortableWasmCanonicalRequest(selectionArtifact){
  checked(selectionArtifact,'abi-policy',wasmCanonicalSelectionContract);
  const policy=decodeWasmCanonicalSelection(selectionArtifact.bytes);
  if(![policy.packageNamespace,policy.packageName,policy.worldName,policy.interfaceName,
      ...policy.exports.flatMap(entry=>[entry.sourceName,entry.foreignName])]
      .every(value=>Buffer.byteLength(value)<=4096))fail('REQUEST_RESOURCE');
  const wire=JSON.stringify([wasmCanonicalRequestContract,String(policy.wordBits),
    policy.packageNamespace,policy.packageName,policy.worldName,policy.interfaceName,
    policy.exports.map(({sourceName,foreignName})=>[sourceName,foreignName])]);
  if(Buffer.byteLength(wire)>1048576)fail('REQUEST_RESOURCE');
  return wire;
}

/** Snapshot a host-selected policy once; never retain caller-mutable bytes. */
export function captureWasmCanonicalSelection(input){
  if(!input||typeof input!=='object')fail('SELECTION_RESOURCE');
  const data=Object.getOwnPropertyDescriptor(input,'bytes'),id=Object.getOwnPropertyDescriptor(input,'identity');
  if(!data||!id||!Object.hasOwn(data,'value')||!Object.hasOwn(id,'value')||
      !(data.value instanceof Uint8Array)||data.value.byteLength>1048576)fail('SELECTION_RESOURCE');
  const identity={},fields=['algorithm','schemaVersion','domain','contract','byteLength','digest'];
  if(!id.value||typeof id.value!=='object'||Reflect.ownKeys(id.value).length!==fields.length||
      Reflect.ownKeys(id.value).some(key=>!fields.includes(key)))fail('ARTIFACT');
  for(const key of fields){
    const field=Object.getOwnPropertyDescriptor(id.value,key);
    if(!field||!Object.hasOwn(field,'value'))fail('ARTIFACT');
    identity[key]=field.value;
  }
  const selection={bytes:Buffer.from(data.value),identity:Object.freeze(identity)};
  return Object.freeze({selection,wire:createPortableWasmCanonicalRequest(selection)});
}

/** Both live generated and native transports check the same exact products. */
export function createWasmCanonicalProducts({selection,specializedIr,targetIr,binary,interfaceJson,bindingJson},limits={}){
  const maxBytes=limits.maxBytes??256*1024*1024;
  if(!Number.isSafeInteger(maxBytes)||maxBytes<0)fail('RESOURCE_POLICY');
  if(typeof interfaceJson!=='string'||typeof bindingJson!=='string'||
      Buffer.byteLength(interfaceJson)+Buffer.byteLength(bindingJson)>maxBytes)fail('PRODUCT_RESOURCE');
  const interfaceArtifact=artifact(Buffer.from(interfaceJson),'interface-ir',interfaceIrEncodingContract);
  const binding=artifact(Buffer.from(bindingJson),'abi-plan',wasmCanonicalBindingContract);
  const subject={selection,specializedIr,targetIr,binary,interfaceArtifact,binding};
  verifyWasmCanonicalProjection(subject,limits);
  const validation=verifyWasmCanonicalBinary(subject);
  return Object.freeze({selection:{bytes:Buffer.from(selection.bytes),identity:Object.freeze({...selection.identity})},
    interface:interfaceArtifact,binding,validation});
}

const fixed=Object.freeze({
  uint8:'u8',uint16:'u16',uint32:'u32',uint64:'u64',int8:'s8',int16:'s16',int32:'s32',int64:'s64',
  float:'f64',float32:'f32',bool:'bool',char:'char',
});
function scalar(type,wordBits){
  if(type[0]!=='primitive')fail('UNSUPPORTED_TYPE');
  const primitive=type[1],mapped=primitive==='usize'?'u'+wordBits:primitive==='isize'?'s'+wordBits:fixed[primitive];
  if(!mapped)fail('UNSUPPORTED_TYPE');
  return ['scalar',mapped];
}

/** Independent signature projection from exact source bytes. This decodes the
 * entire IR schema but does NOT replace strict type/scope/body validation.
 * Closed-IR replay and live source authority remain separate obligations.
 */
export function deriveWasmCanonicalArtifacts(specializedIr,selectionArtifact,limits={}){
  checked(specializedIr,'specialized-ir',irEncodingContract);
  checked(selectionArtifact,'abi-policy',wasmCanonicalSelectionContract);
  const policy=decodeWasmCanonicalSelection(selectionArtifact.bytes);
  const source=decodeIrArtifact(specializedIr.bytes,limits);
  if(source[1].length)fail('IMPORTS_UNSUPPORTED');
  const globals=new Set(),declarations=new Map();
  for(const declaration of [...source[2],...source[3],...source[4]]){
    if(globals.has(declaration[0]))fail('DUPLICATE_GLOBAL');globals.add(declaration[0]);
  }
  for(const declaration of source[4])declarations.set(declaration[0],declaration);
  const functions=policy.exports.map(({sourceName,foreignName})=>{
    const declaration=declarations.get(sourceName);if(!declaration)fail('MISSING_DECLARATION');
    if(declaration[1].length||declaration[2].length>16)fail('UNSUPPORTED_DECLARATION');
    const parameters=declaration[2].map((entry,index)=>['arg'+index,scalar(entry[1],policy.wordBits)]);
    const returned=declaration[3][0]==='primitive'&&declaration[3][1]==='unit'?['none']:
      ['some',scalar(declaration[3],policy.wordBits)];
    return [foreignName,parameters,returned,false,['component-model']];
  });
  const world=['psc-interface-ir-json/1','psc-foreign-interface/1',policy.packageNamespace,
    policy.packageName,policy.worldName,[[policy.interfaceName,[],functions,[],[]]],[],[policy.interfaceName]];
  const interfaceBytes=canonicalBytes(world);
  decodeInterfaceIrArtifact(interfaceBytes);
  const interfaceArtifact=artifact(interfaceBytes,'interface-ir',interfaceIrEncodingContract);
  const binding=canonicalArtifact({bindings:policy.exports.map(({sourceName,foreignName})=>({
    coreExport:foreignName,functionName:foreignName,sourceName})),
    contract:wasmCanonicalBindingContract,interfaceName:policy.interfaceName,
    runtimeSemantics:'psc-runtime-semantics/1',wordBits:policy.wordBits},'abi-plan',wasmCanonicalBindingContract);
  return Object.freeze({policy,interface:interfaceArtifact,binding,relation:wasmCanonicalProjectionRelation,
    authority:'adapter-data-not-source-authority',sourceInvariantsVerified:false,preservationVerified:false});
}

export function verifyWasmCanonicalProjection({specializedIr,selection,interfaceArtifact,binding},limits={}){
  checked(interfaceArtifact,'interface-ir',interfaceIrEncodingContract);
  checked(binding,'abi-plan',wasmCanonicalBindingContract);
  const derived=deriveWasmCanonicalArtifacts(specializedIr,selection,limits);
  if(artifactKey(derived.interface.identity)!==artifactKey(interfaceArtifact.identity)||
      artifactKey(derived.binding.identity)!==artifactKey(binding.identity))fail('PROJECTION_RELATION');
  return Object.freeze({relation:wasmCanonicalProjectionRelation,sourceId:specializedIr.identity,
    selectionId:selection.identity,interfaceId:interfaceArtifact.identity,bindingId:binding.identity,
    projectionChecked:true,sourceInvariantsVerified:false,preservationVerified:false});
}

/** Check closed binary exports without executing guest code. The engine checks
 * binary validity; signature agreement does not establish function behavior.
 */
export function verifyWasmCanonicalBinary({interfaceArtifact,binding,binary,targetIr},limits={}){
  checked(interfaceArtifact,'interface-ir',interfaceIrEncodingContract);
  checked(binding,'abi-plan',wasmCanonicalBindingContract);
  checked(binary,'wasm-binary','webassembly-core/1');
  const bound=decodeComparatorJson(binding.bytes,{maxBytes:1024*1024,maxDepth:8,maxNodes:8192});
  exact(bound,['bindings','contract','interfaceName','runtimeSemantics','wordBits']);
  if(bound.contract!==wasmCanonicalBindingContract||bound.runtimeSemantics!=='psc-runtime-semantics/1'||
      !name(bound.interfaceName)||![32,64].includes(bound.wordBits)||
      !Array.isArray(bound.bindings)||bound.bindings.length<1||bound.bindings.length>1024)fail('BINDING');
  const world=decodeInterfaceIrArtifact(interfaceArtifact.bytes);
  if(world.imports.length||world.interfaces.length!==1||world.exports.length!==1||
      world.exports[0]!==bound.interfaceName||world.interfaces[0].name!==bound.interfaceName)fail('WORLD');
  const api=world.interfaces[0];
  if(api.definitions.length||api.requiredCapabilities.length||api.providedCapabilities.length||
      api.functions.length!==bound.bindings.length)fail('SCALAR_PROFILE');
  const plan=prepareCanonicalValueTypes({interfaceArtifact,expectedInterfaceId:interfaceArtifact.identity,
    interfaceName:bound.interfaceName,limits:limits.values});
  const inspection=inspectWasmCoreArtifact({binary,expectedBinaryId:binary.identity,limits:limits.binary});
  if(inspection.hasStart||inspection.imports.length)fail('CLOSED_PROFILE');
  const exports=WebAssembly.Module.exports(inspection.module);
  let target;
  if(targetIr!==undefined){
    checked(targetIr,'wasm-ir',wasmIrEncodingContract);
    target=decodeWasmIrArtifact(targetIr.bytes,limits.ir);
    if(target[6].length!==bound.bindings.length)fail('TARGET_EXPORT_SURFACE');
    const names=target[4].map(fn=>fn[0]);
    if(new Set(names).size!==names.length)fail('TARGET_DUPLICATE_FUNCTION');
  }
  if(exports.length!==bound.bindings.length)fail('EXPORT_SURFACE');
  const selected=[];
  for(let i=0;i<bound.bindings.length;i++){
    const entry=bound.bindings[i],fn=api.functions[i];
    exact(entry,['sourceName','functionName','coreExport']);
    if(!text(entry.sourceName)||entry.functionName!==fn.name||entry.coreExport!==fn.name||
        exports[i].kind!=='function'||exports[i].name!==entry.coreExport)fail('EXPORT_SURFACE');
    if(fn.parameters.length>16||fn.parameters.some(item=>item.type.tag!=='scalar'||item.type.scalar==='string')||
        (fn.result!==null&&(fn.result.tag!=='scalar'||fn.result.scalar==='string')))fail('SCALAR_PROFILE');
    const description=plan.describeFunction(fn.name);
    if(description.needsMemory||description.needsRealloc)fail('SCALAR_PROFILE');
    const actual=requireWasmFunctionSignature(inspection,entry.coreExport,description.lift.parameters,description.lift.results);
    if(target){
      const exported=target[6][i],index=target[4].findIndex(fn=>fn[0]===entry.sourceName),fn=target[4][index];
      if(exported[0]!==entry.coreExport||exported[1]!==entry.sourceName||index<0||actual.index!==index||
          JSON.stringify(fn[2])!==JSON.stringify(description.lift.parameters.map(type=>[type]))||
          JSON.stringify(fn[3])!==JSON.stringify(description.lift.results.map(type=>[type])))fail('TARGET_SIGNATURE_RELATION');
    }
    selected.push(Object.freeze({functionName:entry.functionName,coreExport:entry.coreExport}));
  }
  return Object.freeze({relation:wasmCanonicalBinaryRelation,interfaceId:interfaceArtifact.identity,
    bindingId:binding.identity,binaryId:binary.identity,bindings:Object.freeze(selected),
    ...(targetIr?{targetIrId:targetIr.identity,targetSignaturesChecked:true}:{}),
    signaturesChecked:true,guestExecuted:false,preservationVerified:false});
}
