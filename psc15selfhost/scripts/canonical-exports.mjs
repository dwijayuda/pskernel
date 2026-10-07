import { prepareCanonicalValueTypes, bindCanonicalValueMemory } from './canonical-memory.mjs';
import { inspectWasmCoreArtifact, requireWasmFunctionSignature, requireWasmMemory } from './wasm-core-signatures.mjs';

export const canonicalExportsContract='psc-canonical-closed-exports-sync-utf8/1';
const fail=code=>{throw new TypeError('PSC_CANONICAL_EXPORTS_'+code);};
function choices(values){
  if(!Array.isArray(values)||values.some(value=>typeof value!=='string'||!value.length)||
      new Set(values).size!==values.length)fail('CAPABILITY_POLICY');
  return new Set(values);
}
function binding(value){
  if(!value||typeof value!=='object'||Array.isArray(value)||
      Object.keys(value).some(key=>!['functionName','coreExport','postReturn'].includes(key))||
      typeof value.functionName!=='string'||typeof value.coreExport!=='string'||
      (value.postReturn!==undefined&&typeof value.postReturn!=='string'))fail('BINDING');
  return {functionName:value.functionName,coreExport:value.coreExport,postReturn:value.postReturn};
}
/** Bind a caller-pinned closed core module to a selected synchronous exported
 * InterfaceIR surface. No core imports, start function, resources or async
 * lifecycle are supported. All signatures/capabilities are checked first.
 * This implements a declared adapter profile, not source preservation.
 */
export function instantiateCanonicalExports({binary,expectedBinaryId,interfaceArtifact,expectedInterfaceId,
  interfaceName,bindings,memoryExport,reallocExport,pointerBits=32,grantedCapabilities=[],limits={}}){
  if(!limits||typeof limits!=='object'||Array.isArray(limits)||
      Object.keys(limits).some(key=>!['values','binary'].includes(key)))fail('LIMIT_POLICY');
  const grants=choices(grantedCapabilities);
  if(!Array.isArray(bindings)||bindings.length>1024)fail('BINDINGS');
  if(memoryExport!==undefined&&typeof memoryExport!=='string')fail('MEMORY_EXPORT');
  if(reallocExport!==undefined&&typeof reallocExport!=='string')fail('REALLOC_EXPORT');
  const plan=prepareCanonicalValueTypes({interfaceArtifact,expectedInterfaceId,interfaceName,pointerBits,limits:limits.values});
  if(!plan.exported||plan.hasWorldImports)fail('WORLD_PROFILE');
  if([...plan.requiredCapabilities,...plan.providedCapabilities].some(value=>!grants.has(value)))fail('CAPABILITY_DENIED');
  const inspection=inspectWasmCoreArtifact({binary,expectedBinaryId,limits:limits.binary});
  if(inspection.hasStart)fail('START_UNSUPPORTED');
  if(inspection.imports.length)fail('IMPORTS_UNSUPPORTED');
  const pointer=pointerBits===32?'i32':'i64';
  if(memoryExport!==undefined)requireWasmMemory(inspection,memoryExport,pointerBits);
  if(reallocExport!==undefined){
    if(memoryExport===undefined)fail('MEMORY_REQUIRED');
    requireWasmFunctionSignature(inspection,reallocExport,[pointer,pointer,pointer,pointer],[pointer]);
  }
  const selected=[],seen=new Set();
  for(const input of bindings){
    const entry=binding(input);
    if(seen.has(entry.functionName))fail('DUPLICATE_BINDING');seen.add(entry.functionName);
    const description=plan.describeFunction(entry.functionName);
    if(description.needsMemory&&memoryExport===undefined)fail('MEMORY_REQUIRED');
    if(description.needsRealloc&&reallocExport===undefined)fail('REALLOC_REQUIRED');
    requireWasmFunctionSignature(inspection,entry.coreExport,description.lift.parameters,description.lift.results);
    if(entry.postReturn!==undefined)requireWasmFunctionSignature(inspection,entry.postReturn,description.lift.results,[]);
    selected.push({...entry,description});
  }
  // Instantiate only the exact validated module after every binding is checked.
  // The closed profile has no start function or host imports. Engine/platform
  // allocation remains part of the caller's execution assumptions.
  const instance=new WebAssembly.Instance(inspection.module);
  const memory=memoryExport===undefined?undefined:instance.exports[memoryExport];
  const realloc=reallocExport===undefined?undefined:instance.exports[reallocExport];
  const codec=bindCanonicalValueMemory(plan,{memory,realloc});
  const exports=Object.create(null);
  let state='ready';
  for(const entry of selected){
    const callee=instance.exports[entry.coreExport];
    const postReturn=entry.postReturn===undefined?undefined:instance.exports[entry.postReturn];
    const invoke=(...args)=>{
      if(state!=='ready')fail(state==='trapped'?'INSTANCE_TRAPPED':'REENTRANT');
      if(args.length!==entry.description.arity)fail('ARITY');
      state='lowering';
      try{
        const flatArguments=codec.lowerArguments(entry.functionName,args);
        state='calling';
        const returned=Reflect.apply(callee,undefined,flatArguments);
        const flatResults=entry.description.hasResult?[returned]:[];
        state='lifting';
        const value=codec.liftResult(entry.functionName,flatResults);
        // Lift/copy results before post-return can release or overwrite them.
        // A trap skips remaining lifecycle work and poisons this adapter.
        if(postReturn!==undefined){
          state='post-return';Reflect.apply(postReturn,undefined,flatResults);
        }
        state='ready';return value;
      }catch(error){state='trapped';throw error;}
    };
    Object.defineProperty(exports,entry.functionName,{value:Object.freeze(invoke),enumerable:true});
  }
  return Object.freeze({contract:canonicalExportsContract,interfaceId:plan.interfaceId,binaryId:inspection.binaryId,
    exports:Object.freeze(exports),state:()=>state});
}
