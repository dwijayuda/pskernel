export type WasmValueType=
  |'i32'|'i64'|'f32'|'f64'|'externref';

export type WasmAbiValueType=
  |'bool'
  |'uint8'|'uint16'|'uint32'|'uint64'
  |'nat'|'int';

export interface WasmIrAbiSignature {
  readonly parameters:readonly WasmAbiValueType[];
  readonly result:WasmAbiValueType|null;
}

export function wasmAbiPhysicalType(
  type:WasmAbiValueType,
):WasmValueType {
  switch(type){
    case 'bool':
    case 'uint8':
    case 'uint16':
    case 'uint32':
      return 'i32';
    case 'uint64':
      return 'i64';
    case 'nat':
    case 'int':
      return 'externref';
  }
}

export interface WasmIrParameter {
  readonly name:string;
  readonly type:WasmValueType;
}

export type WasmIrExpr =
  | {readonly kind:'nop'}
  | {readonly kind:'i32.const';readonly value:number}
  | {
      readonly kind:'local';
      readonly name:string;
      readonly type:WasmValueType;
    }
  | {
      readonly kind:'call';
      readonly target:string;
      readonly args:readonly WasmIrExpr[];
      readonly result:WasmValueType|null;
    }
  | {
      readonly kind:'let';
      readonly name:string;
      readonly type:WasmValueType;
      readonly value:WasmIrExpr;
      readonly body:WasmIrExpr;
      readonly result:WasmValueType|null;
    }
  | {
      readonly kind:'if';
      readonly condition:WasmIrExpr;
      readonly thenBranch:WasmIrExpr;
      readonly elseBranch:WasmIrExpr;
      readonly result:WasmValueType|null;
    }
  | {
      readonly kind:'i32.unary';
      readonly operation:'eqz';
      readonly operand:WasmIrExpr;
    }
  | {
      readonly kind:'i32.binary';
      readonly operation:'and'|'or'|'eq'|'ne';
      readonly left:WasmIrExpr;
      readonly right:WasmIrExpr;
    };

export interface WasmIrFunction {
  readonly name:string;
  readonly parameters:readonly WasmIrParameter[];
  readonly result:WasmValueType|null;
  readonly abi:WasmIrAbiSignature;
  readonly body:WasmIrExpr;
  readonly exportName?:string;
}

export interface WasmIrModule {
  readonly kind:'proofscript-wasm-ir';
  readonly profile:
    |'proofscript-wasm32-mvp-js-v1'
    |'proofscript-wasm32-ref-js-v1';
  readonly functions:readonly WasmIrFunction[];
}
