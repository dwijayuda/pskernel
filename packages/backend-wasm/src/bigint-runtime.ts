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

export function createProofScriptBigIntRuntime(
  imports:readonly WasmIrFunctionImport[],
  literals:readonly WasmBigIntLiteral[],
):WebAssembly.ModuleImports {
  const runtime:WebAssembly.ModuleImports={};
  for(const imported of imports){
    if(imported.name!=='literal'){
      throw new Error(
        "PS_WASM_BIGINT_IMPORT_UNSUPPORTED: '"+imported.name+"'",
      );
    }
    runtime.literal=(index:number)=>literalValue(literals,index);
  }
  return runtime;
}
