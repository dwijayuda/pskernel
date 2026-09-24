import {
  PROOFSCRIPT_BIGINT_RUNTIME_MODULE,
  type WasmBigIntLiteral,
  type WasmIrExpr,
  type WasmIrFunctionImport,
} from '@proofscript/wasm-ir';
import {WasmLoweringError} from './errors.js';

const BIGINT_LITERAL_IMPORT='ps$bigint$literal';

export type WasmNatIntrinsicOperation=
  |'nat.add'|'nat.sub'|'nat.mul'|'nat.div'|'nat.mod'
  |'nat.eq'|'nat.ne'|'nat.le'|'nat.lt';

function natRuntimeImport(
  operation:WasmNatIntrinsicOperation,
):WasmIrFunctionImport {
  const name=operation.replace('nat.','nat_');
  const comparison=
    operation==='nat.eq'||
    operation==='nat.ne'||
    operation==='nat.le'||
    operation==='nat.lt';
  return {
    internalName:'ps$bigintexport interface WasmRuntimeSupport {
  readonly imports:Map<string,WasmIrFunctionImport>;
  readonly bigintLiterals:WasmBigIntLiteral[];
  readonly bigintLiteralIndices:Map<string,number>;
}

export function createWasmRuntimeSupport():WasmRuntimeSupport {
  return {
    imports:new Map(),
    bigintLiterals:[],
    bigintLiteralIndices:new Map(),
  };
}

function requireLiteralImport(
  support:WasmRuntimeSupport,
):void {
  if(support.imports.has(BIGINT_LITERAL_IMPORT))return;
  support.imports.set(BIGINT_LITERAL_IMPORT,{
    internalName:BIGINT_LITERAL_IMPORT,
    module:PROOFSCRIPT_BIGINT_RUNTIME_MODULE,
    name:'literal',
    parameters:['i32'],
    result:'externref',
  });
}

export function lowerNatIntrinsic(
  operation:WasmNatIntrinsicOperation,
  left:WasmIrExpr,
  right:WasmIrExpr,
  support:WasmRuntimeSupport,
):WasmIrExpr {
  const imported=natRuntimeImport(operation);
  if(!support.imports.has(imported.internalName)){
    support.imports.set(imported.internalName,imported);
  }
  return {
    kind:'call',
    target:imported.internalName,
    args:[left,right],
    result:imported.result,
  };
}

export function lowerNatLiteral(
  value:bigint,
  support:WasmRuntimeSupport,
):WasmIrExpr {
  if(value<0n){
    throw new WasmLoweringError(
      'PS_WASM_NAT_LITERAL_NEGATIVE',
      'Nat literal cannot be negative',
    );
  }
  requireLiteralImport(support);
  const decimal=value.toString();
  const key='nat:'+decimal;
  let index=support.bigintLiteralIndices.get(key);
  if(index===undefined){
    index=support.bigintLiterals.length;
    if(index>0x7fffffff){
      throw new WasmLoweringError(
        'PS_WASM_BIGINT_LITERAL_TABLE_LIMIT',
        'BigInt literal table exceeds i32 index range',
      );
    }
    support.bigintLiteralIndices.set(key,index);
    support.bigintLiterals.push({kind:'nat',decimal});
  }
  return {
    kind:'call',
    target:BIGINT_LITERAL_IMPORT,
    args:[{kind:'i32.const',value:index}],
    result:'externref',
  };
}
+name,
    module:PROOFSCRIPT_BIGINT_RUNTIME_MODULE,
    name,
    parameters:['externref','externref'],
    result:comparison?'i32':'externref',
  };
}

export interface WasmRuntimeSupport {
  readonly imports:Map<string,WasmIrFunctionImport>;
  readonly bigintLiterals:WasmBigIntLiteral[];
  readonly bigintLiteralIndices:Map<string,number>;
}

export function createWasmRuntimeSupport():WasmRuntimeSupport {
  return {
    imports:new Map(),
    bigintLiterals:[],
    bigintLiteralIndices:new Map(),
  };
}

function requireLiteralImport(
  support:WasmRuntimeSupport,
):void {
  if(support.imports.has(BIGINT_LITERAL_IMPORT))return;
  support.imports.set(BIGINT_LITERAL_IMPORT,{
    internalName:BIGINT_LITERAL_IMPORT,
    module:PROOFSCRIPT_BIGINT_RUNTIME_MODULE,
    name:'literal',
    parameters:['i32'],
    result:'externref',
  });
}

export function lowerNatLiteral(
  value:bigint,
  support:WasmRuntimeSupport,
):WasmIrExpr {
  if(value<0n){
    throw new WasmLoweringError(
      'PS_WASM_NAT_LITERAL_NEGATIVE',
      'Nat literal cannot be negative',
    );
  }
  requireLiteralImport(support);
  const decimal=value.toString();
  const key='nat:'+decimal;
  let index=support.bigintLiteralIndices.get(key);
  if(index===undefined){
    index=support.bigintLiterals.length;
    if(index>0x7fffffff){
      throw new WasmLoweringError(
        'PS_WASM_BIGINT_LITERAL_TABLE_LIMIT',
        'BigInt literal table exceeds i32 index range',
      );
    }
    support.bigintLiteralIndices.set(key,index);
    support.bigintLiterals.push({kind:'nat',decimal});
  }
  return {
    kind:'call',
    target:BIGINT_LITERAL_IMPORT,
    args:[{kind:'i32.const',value:index}],
    result:'externref',
  };
}
