// Explicit synchronous core-Wasm String ABI. Instantiate only separately checked
// PSC1 artifacts; these bindings do not admit arbitrary bytecode or sandbox Node.
import {createTypedIo} from './typed-io.mjs';
const limit=16*1024*1024;
function range(memory,pointer,length){
 if(!Number.isInteger(pointer)||!Number.isInteger(length))throw Error('PSC1_WASM_STRING_RANGE');
 pointer>>>=0;length>>>=0;
 if(pointer>memory.buffer.byteLength||length>memory.buffer.byteLength-pointer)throw Error('PSC1_WASM_STRING_RANGE');
 return new Uint8Array(memory.buffer,pointer,length);
}
function decode(memory,pointer,length){
 try{return new TextDecoder('utf-8',{fatal:true,ignoreBOM:true}).decode(range(memory,pointer,length));}
 catch(e){if(e instanceof TypeError)throw Error('PSC1_WASM_STRING_INVALID_UTF8',{cause:e});throw e;}
}
function encode(memory,realloc,text){
 if(typeof text!=='string'||!text.isWellFormed())throw Error('PSC1_WASM_STRING_INVALID_INPUT');
 const size=Buffer.byteLength(text);
 if(size>limit-64)throw Error('PSC1_WASM_STRING_TOO_LARGE');
 const pointer=realloc(0,0,1,size);
 range(memory,pointer,size).set(new TextEncoder().encode(text));
 return [pointer,size];
}
export function bindWasmStrings(instance,schema){
 const exports=instance.exports,memory=exports.memory,realloc=exports.cabi_realloc;
 if(!(memory instanceof WebAssembly.Memory)||typeof realloc!=='function'||memory.buffer.byteLength!==limit)
  throw Error('PSC1_WASM_STRING_ABI_MISMATCH');
 let active=false,poisoned=false;
 return Object.freeze({
  call(name,...args){
   if(poisoned)throw Error('PSC1_WASM_STRING_INSTANCE_POISONED');
   if(active)throw Error('PSC1_WASM_STRING_REENTRY');
   const signature=schema[name],fn=exports[name];
   if(!signature||typeof fn!=='function'||args.length!==signature.parameters.length)
    throw Error('PSC1_WASM_STRING_SIGNATURE_MISMATCH');
   const flat=[];
   active=true;let started=false;
   try{
    for(let i=0;i<args.length;i++){
     const type=signature.parameters[i],value=args[i];
     if(type==='string')flat.push(...encode(memory,realloc,value));
     else if(type==='bool'&&typeof value==='boolean')flat.push(Number(value));
     else throw Error('PSC1_WASM_STRING_ARGUMENT_TYPE');
    }
    started=true;const result=fn(...flat);
    if(signature.result==='bool'){
     if(result!==0&&result!==1)throw Error('PSC1_WASM_STRING_BOOL_RESULT');
     return result===1;
    }
    if(signature.result!=='string')throw Error('PSC1_WASM_STRING_RESULT_TYPE');
    const record=new DataView(range(memory,result,8).buffer,result>>>0,8);
    return decode(memory,record.getUint32(0,true),record.getUint32(4,true));
   }catch(error){if(started||error instanceof WebAssembly.RuntimeError)poisoned=true;throw error;}
   finally{if(!poisoned)exports.cabi_post_return(0);active=false;}
  }
 });
}
export async function withWasmTypedIo(config,loadModule,schema,useProgram){
 if(config?.abi!=='psc1-wasm-core-linux-string-io/1')throw Error('PSC1_IO_UNSUPPORTED_ABI');
 if(config.maxFileBytes>2*1024*1024||config.maxLineBytes>2*1024*1024)
  throw Error('PSC1_IO_CONFIGURATION: Wasm IO supports at most 2097152 payload bytes');
 const io=createTypedIo({...config,abi:'psc1-node-linux-string-io/1'});
 try{
  const module=await loadModule();
  const imports=WebAssembly.Module.imports(module);
  if(imports.length!==1||imports[0].module!=='psc1:io'||imports[0].name!=='dispatch'||imports[0].kind!=='function')
   throw Error('PSC1_WASM_IO_IMPORT_MISMATCH');
  let instance;
  const dispatch=(pointer,length,result)=>{
   if(!instance)throw Error('PSC1_WASM_IO_EARLY_DISPATCH');
   const memory=instance.exports.memory;
   range(memory,result,8);
   const response=io.execute(decode(memory,pointer,length));
   const [data,size]=encode(memory,instance.exports.cabi_realloc,response);
   const record=new DataView(memory.buffer,result>>>0,8);
   record.setUint32(0,data,true);record.setUint32(4,size,true);
  };
  instance=new WebAssembly.Instance(module,{'psc1:io':{dispatch}});
  return await useProgram(bindWasmStrings(instance,schema));
 }finally{io.close();}
}
