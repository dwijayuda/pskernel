import {
  PROOFSCRIPT_BIGINT_RUNTIME_MODULE,
  type WasmIrFunctionImport,
} from './model.js';

export function validateBigIntImport(
  imported:WasmIrFunctionImport,
):void {
  if(imported.module!==PROOFSCRIPT_BIGINT_RUNTIME_MODULE){
    throw new Error('PS_WASM_IR_INTERNAL_IMPORT_MODULE');
  }

  let parameters:readonly ('i32'|'externref')[];
  let result:'i32'|'externref';
  switch(imported.name){
    case 'literal':
      parameters=['i32'];
      result='externref';
      break;
    case 'nat_add':
    case 'nat_sub':
    case 'nat_mul':
    case 'nat_div':
    case 'nat_mod':
      parameters=['externref','externref'];
      result='externref';
      break;
    case 'nat_eq':
    case 'nat_ne':
    case 'nat_le':
    case 'nat_lt':
      parameters=['externref','externref'];
      result='i32';
      break;
    default:
      throw new Error(
        "PS_WASM_IR_BIGINT_IMPORT_UNSUPPORTED: '"+imported.name+"'",
      );
  }

  if(
    imported.parameters.length!==parameters.length||
    imported.parameters.some(
      (parameter,index)=>parameter!==parameters[index],
    )||
    imported.result!==result
  ){
    throw new Error(
      'PS_WASM_IR_BIGINT_IMPORT_SIGNATURE: '+imported.name,
    );
  }
}
