import type {
  WasmAbiValueType,
} from '@proofscript/wasm-ir';

export type ProofScriptWasmHostValue=
  |boolean
  |number
  |bigint
  |undefined;

export interface ProofScriptWasmExecutableArtifact {
  readonly binary:Uint8Array;
  readonly exports:readonly {
    readonly name:string;
    readonly parameters:readonly WasmAbiValueType[];
    readonly result:WasmAbiValueType|null;
  }[];
}

export interface ProofScriptWasmHostInstance {
  readonly raw:WebAssembly.Instance;
  readonly exports:Readonly<Record<
    string,
    (...args:ProofScriptWasmHostValue[])=>ProofScriptWasmHostValue
  >>;
}

function requireUnsignedNumber(
  value:ProofScriptWasmHostValue,
  bits:8|16|32,
):number {
  if(typeof value!=='number'||!Number.isInteger(value)){
    throw new TypeError(
      'PS_WASM_JS_ABI_UINT'+bits+'_TYPE: expected an integer number',
    );
  }
  const maximum=bits===8?0xff:bits===16?0xffff:0xffffffff;
  if(value<0||value>maximum){
    throw new RangeError(
      'PS_WASM_JS_ABI_UINT'+bits+'_RANGE: expected 0..'+maximum,
    );
  }
  return bits===32?value|0:value;
}

function toRaw(
  type:WasmAbiValueType,
  value:ProofScriptWasmHostValue,
):number|bigint {
  switch(type){
    case 'bool':
      if(typeof value!=='boolean'){
        throw new TypeError(
          'PS_WASM_JS_ABI_BOOL_TYPE: expected boolean',
        );
      }
      return value?1:0;
    case 'uint8':
      return requireUnsignedNumber(value,8);
    case 'uint16':
      return requireUnsignedNumber(value,16);
    case 'uint32':
      return requireUnsignedNumber(value,32);
    case 'uint64':
      if(typeof value!=='bigint'){
        throw new TypeError(
          'PS_WASM_JS_ABI_UINT64_TYPE: expected bigint',
        );
      }
      if(value<0n||value>0xffffffffffffffffn){
        throw new RangeError(
          'PS_WASM_JS_ABI_UINT64_RANGE: expected 0..18446744073709551615',
        );
      }
      return BigInt.asIntN(64,value);
  }
}

function fromRaw(
  type:WasmAbiValueType,
  value:unknown,
):ProofScriptWasmHostValue {
  switch(type){
    case 'bool':
      return (value as number)!==0;
    case 'uint8':
      return (value as number)&0xff;
    case 'uint16':
      return (value as number)&0xffff;
    case 'uint32':
      return (value as number)>>>0;
    case 'uint64':
      return BigInt.asUintN(64,value as bigint);
  }
}

export function instantiateProofScriptWasm(
  artifact:ProofScriptWasmExecutableArtifact,
  imports:WebAssembly.Imports={},
):ProofScriptWasmHostInstance {
  const raw=new WebAssembly.Instance(
    new WebAssembly.Module(artifact.binary),
    imports,
  );
  const exports:Record<
    string,
    (...args:ProofScriptWasmHostValue[])=>ProofScriptWasmHostValue
  >={};

  for(const signature of artifact.exports){
    const rawExport=raw.exports[signature.name];
    if(typeof rawExport!=='function'){
      throw new Error(
        "PS_WASM_JS_ABI_MISSING_EXPORT: '"+signature.name+"'",
      );
    }
    exports[signature.name]=(...args)=>{
      if(args.length!==signature.parameters.length){
        throw new TypeError(
          "PS_WASM_JS_ABI_ARITY: '"+signature.name+"' expected "+
          signature.parameters.length+' argument(s)',
        );
      }
      const rawArgs=signature.parameters.map(
        (type,index)=>toRaw(type,args[index]),
      );
      const result=(rawExport as (
        ...values:(number|bigint)[]
      )=>unknown)(...rawArgs);
      return signature.result===null
        ?undefined
        :fromRaw(signature.result,result);
    };
  }

  return {raw,exports};
}
