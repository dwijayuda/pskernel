import { artifactKey, verifyArtifact } from './artifact-evidence.mjs';

export const wasmCoreSignaturesContract='psc-wasm-core-signatures/1';
const fail=code=>{throw new TypeError('PSC_WASM_SIGNATURE_'+code);};
const numeric=new Set(['i32','i64','f32','f64']);
const valtypes=new Map([[0x7f,'i32'],[0x7e,'i64'],[0x7d,'f32'],[0x7c,'f64'],[0x7b,'v128']]);
const defaults={maxBytes:64*1024*1024,maxEntries:250000,maxNameBytes:4096};
const inspections=new WeakMap();
class Reader{
  constructor(bytes,budget,limits){this.bytes=bytes;this.at=0;this.budget=budget;this.limits=limits;}
  byte(){if(this.at>=this.bytes.length)fail('TRUNCATED');return this.bytes[this.at++];}
  take(count){if(!Number.isSafeInteger(count)||count<0||count>this.bytes.length-this.at)fail('LENGTH');
    const result=this.bytes.subarray(this.at,this.at+count);this.at+=count;return result;}
  unsigned(bits){
    let result=0n;const count=Math.ceil(bits/7);
    for(let i=0;i<count;i++){
      const byte=this.byte(),payload=byte&127;result|=BigInt(payload)<<BigInt(7*i);
      if(!(byte&128)){if(result>=(1n<<BigInt(bits)))fail('INTEGER_RANGE');return result;}
    }
    fail('INTEGER_LENGTH');
  }
  u32(){return Number(this.unsigned(32));}
  heap(){
    const first=this.bytes[this.at];
    if(first>=0x69&&first<=0x74){this.at++;return 'abstract-'+first.toString(16);}
    // Positive signed-33 type index. Abstract negative codes use the form above.
    let result=0n;
    for(let i=0;i<5;i++){
      const byte=this.byte();result|=BigInt(byte&127)<<BigInt(7*i);
      if(!(byte&128)){
        if(byte&64)result-=1n<<BigInt(7*(i+1));
        if(result<0n||result>4294967295n)fail('HEAP_TYPE');
        return 'type-'+result;
      }
    }
    fail('HEAP_TYPE');
  }
  value(){
    const code=this.byte();
    if(valtypes.has(code))return valtypes.get(code);
    if(code===0x63||code===0x64)return (code===0x63?'ref-null:':'ref:')+this.heap();
    if(code>=0x69&&code<=0x74)return 'ref-null:abstract-'+code.toString(16);
    fail('UNSUPPORTED_VALUE_TYPE');
  }
  count(){const count=this.u32();if(count>this.budget.remaining)fail('ENTRY_LIMIT');this.budget.remaining-=count;return count;}
  vector(read){const result=[],count=this.count();for(let i=0;i<count;i++)result.push(read());return result;}
  name(){
    const size=this.u32();if(size>this.limits.maxNameBytes)fail('NAME_LIMIT');
    try{return new TextDecoder('utf-8',{fatal:true,ignoreBOM:true}).decode(this.take(size));}
    catch{fail('NAME_ENCODING');}
  }
  section(){return new Reader(this.take(this.u32()),this.budget,this.limits);}
  done(){if(this.at!==this.bytes.length)fail('TRAILING_BYTES');}
  limitsType(){
    const flags=this.byte();
    if(![0,1,4,5].includes(flags))fail('UNSUPPORTED_LIMITS');
    const minimum=this.unsigned(64),maximum=flags&1?this.unsigned(64):null;
    return Object.freeze({pointerBits:flags&4?64:32,minimum:minimum.toString(),maximum:maximum?.toString()??null});
  }
}
function subtype(reader){
  let code=reader.byte();
  if(code===0x4f||code===0x50){reader.vector(()=>reader.u32());code=reader.byte();}
  const field=()=>{
    if([0x77,0x78].includes(reader.bytes[reader.at]))reader.byte();else reader.value();
    if(reader.byte()>1)fail('MUTABILITY');
  };
  if(code===0x60)return Object.freeze({parameters:Object.freeze(reader.vector(()=>reader.value())),
    results:Object.freeze(reader.vector(()=>reader.value()))});
  if(code===0x5f){reader.vector(field);return null;}
  if(code===0x5e){field();return null;}
  fail('UNSUPPORTED_COMPOSITE_TYPE');
}

/** Pin exact bytes, compile/validate them without instantiation, then inspect
 * Core 3.0 function signatures and memory index metadata. This is not an
 * independent instruction validator, source proof or host-effect sandbox.
 */
export function inspectWasmCoreArtifact({binary,expectedBinaryId,limits={}}){
  const bound={...defaults,...limits};
  if(Object.keys(bound).some(key=>!Object.hasOwn(defaults,key))||
      Object.values(bound).some(value=>!Number.isSafeInteger(value)||value<0))fail('LIMIT_POLICY');
  if(expectedBinaryId?.domain!=='wasm-binary'||expectedBinaryId.contract!=='webassembly-core/1'||
      artifactKey(binary?.identity)!==artifactKey(expectedBinaryId))fail('BINARY_ID');
  if(!(binary.bytes instanceof Uint8Array)||binary.bytes.length>bound.maxBytes)fail('BYTE_LIMIT');
  const bytes=Buffer.from(binary.bytes);verifyArtifact(bytes,expectedBinaryId);
  // The engine owns complete binary/instruction/type validation. No import,
  // start function, memory allocation or guest instruction is executed here.
  let module;try{module=new WebAssembly.Module(bytes);}catch{fail('ENGINE_VALIDATION');}
  const reader=new Reader(bytes,{remaining:bound.maxEntries},bound);
  if(!reader.take(8).equals(Buffer.from([0,97,115,109,1,0,0,0])))fail('HEADER');
  const types=[],functions=[],memories=[],imports=[],exports=[];
  let hasStart=false;
  while(reader.at<bytes.length){
    const id=reader.byte(),section=reader.section();
    if(id===1){
      const groups=section.count();
      for(let i=0;i<groups;i++){
        if(section.bytes[section.at]===0x4e){
          section.byte();const count=section.count();
          for(let j=0;j<count;j++)types.push(subtype(section));
        }else types.push(subtype(section));
      }
    }else if(id===2){
      const count=section.count();
      for(let i=0;i<count;i++){
        const moduleName=section.name(),name=section.name(),kind=section.byte();
        if(kind===0){
          const typeIndex=section.u32(),index=functions.length;
          functions.push(typeIndex);imports.push({module:moduleName,name,kind:'function',index,typeIndex});
        }else if(kind===1){
          section.value();section.limitsType();imports.push({module:moduleName,name,kind:'table'});
        }else if(kind===2){
          const type=section.limitsType(),index=memories.length;
          memories.push(type);imports.push({module:moduleName,name,kind:'memory',index,...type});
        }else if(kind===3){
          section.value();if(section.byte()>1)fail('MUTABILITY');imports.push({module:moduleName,name,kind:'global'});
        }else if(kind===4){
          if(section.byte()!==0)fail('TAG_ATTRIBUTE');section.u32();imports.push({module:moduleName,name,kind:'tag'});
        }else fail('IMPORT_KIND');
      }
    }else if(id===3){for(const index of section.vector(()=>section.u32()))functions.push(index);}
    else if(id===5){for(const type of section.vector(()=>section.limitsType()))memories.push(type);}
    else if(id===7){
      const count=section.count();
      for(let i=0;i<count;i++)exports.push({name:section.name(),kind:section.byte(),index:section.u32()});
    }else if(id===8){hasStart=true;section.u32();}
    else section.take(section.bytes.length-section.at);
    section.done();
  }
  const signature=index=>{
    const result=types[functions[index]];if(!result)fail('FUNCTION_TYPE_INDEX');return result;
  };
  const functionExports=new Map(),memoryExports=new Map();
  for(const entry of exports){
    if(entry.kind===0)functionExports.set(entry.name,Object.freeze({name:entry.name,index:entry.index,...signature(entry.index)}));
    if(entry.kind===2){
      const type=memories[entry.index];if(!type)fail('MEMORY_INDEX');
      memoryExports.set(entry.name,Object.freeze({name:entry.name,index:entry.index,...type}));
    }
  }
  const imported=imports.map(entry=>Object.freeze(entry.kind==='function'?{...entry,...signature(entry.index)}:entry));
  const result=Object.freeze({contract:wasmCoreSignaturesContract,module,
    binaryId:Object.freeze({...expectedBinaryId}),hasStart,imports:Object.freeze(imported),
    functionExports:Object.freeze([...functionExports.values()]),memoryExports:Object.freeze([...memoryExports.values()])});
  inspections.set(result,{functionExports,memoryExports});
  return result;
}
export function requireWasmFunctionSignature(inspection,name,parameters,results){
  const state=inspections.get(inspection);if(!state)fail('INSPECTION_HANDLE');
  if(!Array.isArray(parameters)||!Array.isArray(results)||
      [...parameters,...results].some(type=>!numeric.has(type)))fail('EXPECTED_NUMERIC_SIGNATURE');
  const found=state.functionExports.get(name);
  if(!found||found.parameters.length!==parameters.length||found.results.length!==results.length||
      found.parameters.some((type,i)=>type!==parameters[i])||found.results.some((type,i)=>type!==results[i]))fail('SIGNATURE_MISMATCH');
  return found;
}
export function requireWasmMemory(inspection,name,pointerBits){
  const state=inspections.get(inspection);if(!state)fail('INSPECTION_HANDLE');
  const found=state.memoryExports.get(name);
  if(!found||found.pointerBits!==pointerBits)fail('MEMORY_MISMATCH');
  return found;
}
