import type {
  WasmIrExpr,
  WasmValueType,
} from './model.js';

const identifierPattern=
  /^[A-Za-z_$][A-Za-z0-9_$]*$/u;

export function assertWasmIrName(
  name:string,
  label:string,
):void {
  if(!identifierPattern.test(name)){
    throw new Error(
      "PS_WASM_IR_INVALID_"+label+
      ": '"+name+"'",
    );
  }
}

export interface WasmIrFunctionSignature {
  readonly parameters:readonly WasmValueType[];
  readonly result:WasmValueType|null;
}

export function expectWasmIrType(
  actual:WasmValueType|null,
  expected:WasmValueType|null,
  label:string,
):void {
  if(actual!==expected){
    throw new Error(
      'PS_WASM_IR_TYPE_MISMATCH: '+label+
      ' expected '+String(expected)+
      ' but got '+String(actual),
    );
  }
}

export function wasmIrExprType(
  expr:WasmIrExpr,
  locals:ReadonlyMap<string,WasmValueType>,
  functions:ReadonlyMap<
    string,
    WasmIrFunctionSignature
  >,
):WasmValueType|null {
  switch(expr.kind){
    case 'nop':
      return null;

    case 'i32.const':
      if(!Number.isInteger(expr.value)){
        throw new Error(
          'PS_WASM_IR_I32_CONST_NON_INTEGER',
        );
      }
      if(
        expr.value<-2147483648||
        expr.value>4294967295
      ){
        throw new Error(
          'PS_WASM_IR_I32_CONST_RANGE',
        );
      }
      return 'i32';

    case 'local':{
      assertWasmIrName(
        expr.name,
        'LOCAL_NAME',
      );
      const type=locals.get(expr.name);
      if(type===undefined){
        throw new Error(
          "PS_WASM_IR_UNKNOWN_LOCAL: '"+
          expr.name+"'",
        );
      }
      expectWasmIrType(
        expr.type,
        type,
        'local '+expr.name,
      );
      return type;
    }

    case 'call':{
      assertWasmIrName(
        expr.target,
        'CALL_TARGET',
      );
      const signature=
        functions.get(expr.target);
      if(signature===undefined){
        throw new Error(
          "PS_WASM_IR_UNKNOWN_FUNCTION: '"+
          expr.target+"'",
        );
      }
      if(
        expr.args.length!==
          signature.parameters.length
      ){
        throw new Error(
          "PS_WASM_IR_CALL_ARITY: '"+
          expr.target+"' expected "+
          signature.parameters.length+
          ' argument(s)',
        );
      }
      expr.args.forEach((arg,index)=>{
        expectWasmIrType(
          wasmIrExprType(
            arg,
            locals,
            functions,
          ),
          signature.parameters[index]!,
          'argument '+index+
          ' of '+expr.target,
        );
      });
      expectWasmIrType(
        expr.result,
        signature.result,
        'call '+expr.target,
      );
      return expr.result;
    }

    case 'let':{
      assertWasmIrName(
        expr.name,
        'LET_NAME',
      );
      const valueType=wasmIrExprType(
        expr.value,
        locals,
        functions,
      );
      expectWasmIrType(
        valueType,
        expr.type,
        'let '+expr.name,
      );
      const next=new Map(locals);
      next.set(expr.name,expr.type);
      const bodyType=wasmIrExprType(
        expr.body,
        next,
        functions,
      );
      expectWasmIrType(
        bodyType,
        expr.result,
        'let body '+expr.name,
      );
      return expr.result;
    }

    case 'if':
      expectWasmIrType(
        wasmIrExprType(
          expr.condition,
          locals,
          functions,
        ),
        'i32',
        'if condition',
      );
      expectWasmIrType(
        wasmIrExprType(
          expr.thenBranch,
          locals,
          functions,
        ),
        expr.result,
        'if then branch',
      );
      expectWasmIrType(
        wasmIrExprType(
          expr.elseBranch,
          locals,
          functions,
        ),
        expr.result,
        'if else branch',
      );
      return expr.result;

    case 'i32.unary':
      expectWasmIrType(
        wasmIrExprType(
          expr.operand,
          locals,
          functions,
        ),
        'i32',
        expr.operation+' operand',
      );
      return 'i32';

    case 'i32.binary':
      expectWasmIrType(
        wasmIrExprType(
          expr.left,
          locals,
          functions,
        ),
        'i32',
        expr.operation+' left operand',
      );
      expectWasmIrType(
        wasmIrExprType(
          expr.right,
          locals,
          functions,
        ),
        'i32',
        expr.operation+' right operand',
      );
      return 'i32';
  }
}
