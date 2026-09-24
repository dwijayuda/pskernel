import type {
  WasmBigIntLiteral,
  WasmIrFunctionImport,
} from '@proofscript/wasm-ir';

function literalValue(
  literals:readonly WasmBigIntLiteral[],
  index:number,
):bigint {
  if(!Number.isInteger(index)||index<0||index>=literals.length){
    throw new RangeError(
      'PS_WASM_BIGINT_LITERAL_INDEX: invalid literal index '+index,
    );
  }
  const literal=literals[index]!;
  const value=BigInt(literal.decimal);
  if(literal.kind==='nat'&&value<0n){
    throw new RangeError(
      'PS_WASM_BIGINT_NAT_LITERAL_RANGE: negative Nat literal',
    );
  }
  return value;
}

function requireNat(
  value:unknown,
  operation:string,
  position:string,
):bigint {
  if(typeof value!=='bigint'){
    throw new TypeError(
      'PS_WASM_BIGINT_NAT_TYPE: '+operation+' '+position+
      ' expected bigint',
    );
  }
  if(value<0n){
    throw new RangeError(
      'PS_WASM_BIGINT_NAT_RANGE: '+operation+' '+position+
      ' expected non-negative bigint',
    );
  }
  return value;
}

function natBinary(
  operation:string,
  implementation:(left:bigint,right:bigint)=>bigint,
):(left:unknown,right:unknown)=>bigint {
  return (left,right)=>{
    const a=requireNat(left,operation,'left');
    const b=requireNat(right,operation,'right');
    return requireNat(
      implementation(a,b),
      operation,
      'result',
    );
  };
}

function natCompare(
  operation:string,
  implementation:(left:bigint,right:bigint)=>boolean,
):(left:unknown,right:unknown)=>number {
  return (left,right)=>{
    const a=requireNat(left,operation,'left');
    const b=requireNat(right,operation,'right');
    return implementation(a,b)?1:0;
  };
}

export function createProofScriptBigIntRuntime(
  imports:readonly WasmIrFunctionImport[],
  literals:readonly WasmBigIntLiteral[],
):WebAssembly.ModuleImports {
  const runtime:WebAssembly.ModuleImports={};
  for(const imported of imports){
    switch(imported.name){
      case 'literal':
        runtime.literal=(index:number)=>literalValue(literals,index);
        break;
      case 'nat_add':
        runtime.nat_add=natBinary(
          imported.name,
          (left,right)=>left+right,
        );
        break;
      case 'nat_sub':
        runtime.nat_sub=natBinary(
          imported.name,
          (left,right)=>left>=right?left-right:0n,
        );
        break;
      case 'nat_mul':
        runtime.nat_mul=natBinary(
          imported.name,
          (left,right)=>left*right,
        );
        break;
      case 'nat_div':
        runtime.nat_div=natBinary(
          imported.name,
          (left,right)=>right===0n?0n:left/right,
        );
        break;
      case 'nat_mod':
        runtime.nat_mod=natBinary(
          imported.name,
          (left,right)=>right===0n?left:left%right,
        );
        break;
      case 'nat_eq':
        runtime.nat_eq=natCompare(
          imported.name,
          (left,right)=>left===right,
        );
        break;
      case 'nat_ne':
        runtime.nat_ne=natCompare(
          imported.name,
          (left,right)=>left!==right,
        );
        break;
      case 'nat_le':
        runtime.nat_le=natCompare(
          imported.name,
          (left,right)=>left<=right,
        );
        break;
      case 'nat_lt':
        runtime.nat_lt=natCompare(
          imported.name,
          (left,right)=>left<right,
        );
        break;
      default:
        throw new Error(
          "PS_WASM_BIGINT_IMPORT_UNSUPPORTED: '"+imported.name+"'",
        );
    }
  }
  return runtime;
}
