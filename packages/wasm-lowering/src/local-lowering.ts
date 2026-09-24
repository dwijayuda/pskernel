import type {WasmIrExpr} from '@proofscript/wasm-ir';
import {
  wasmValueType,
  type RuntimeValueType,
} from './type-lowering.js';

export function lowerRuntimeLocal(
  name:string,
  type:RuntimeValueType,
):WasmIrExpr {
  const local:WasmIrExpr={
    kind:'local',
    name,
    type:wasmValueType(type),
  };
  switch(type){
    case 'bool':
      return {
        kind:'i32.binary',
        operation:'ne',
        left:local,
        right:{kind:'i32.const',value:0},
      };
    case 'uint8':
      return {
        kind:'i32.binary',
        operation:'and',
        left:local,
        right:{kind:'i32.const',value:0xff},
      };
    case 'uint16':
      return {
        kind:'i32.binary',
        operation:'and',
        left:local,
        right:{kind:'i32.const',value:0xffff},
      };
    case 'uint32':
    case 'uint64':
    case 'nat':
      return local;
  }
}
