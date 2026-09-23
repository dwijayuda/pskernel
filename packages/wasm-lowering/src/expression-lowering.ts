import type {
  VerifiedIrExpr,
} from '@proofscript/compiler-ir/verified';
import type {
  WasmIrExpr,
} from '@proofscript/wasm-ir';
import {
  WasmLoweringError,
  unsupported,
} from './errors.js';
import {
  expressionRuntimeType,
} from './expression-type.js';
import {
  wasmResultType,
  wasmValueType,
  type RuntimeType,
  type RuntimeValueType,
  type Signature,
} from './type-lowering.js';

function requireType(
  actual:RuntimeType,
  expected:RuntimeType,
  label:string,
):void {
  if(actual!==expected){
    throw new WasmLoweringError(
      'PS_WASM_TYPE_MISMATCH',
      label+' expected '+String(expected)+' but got '+String(actual),
    );
  }
}

function lowerLocal(
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
      return local;
  }
}

export function lowerRuntimeExpr(
  expr:VerifiedIrExpr,
  expected:RuntimeType,
  locals:ReadonlyMap<string,RuntimeType>,
  signatures:ReadonlyMap<string,Signature>,
):WasmIrExpr {
  requireType(
    expressionRuntimeType(expr,locals,signatures),
    expected,
    'expression',
  );

  switch(expr.kind){
    case 'literal':
      if(typeof expr.value==='boolean'){
        return {kind:'i32.const',value:expr.value?1:0};
      }
      if(expr.value===undefined)return {kind:'nop'};
      return unsupported(
        'PS_WASM_UNSUPPORTED_LITERAL',
        'literal is outside the W1 Bool/Unit subset',
      );

    case 'var':{
      const type=locals.get(expr.name);
      if(type===undefined||type===null){
        return unsupported(
          'PS_WASM_UNKNOWN_RUNTIME_LOCAL',
          "runtime local '"+expr.name+"' is unavailable",
        );
      }
      return lowerLocal(expr.name,type);
    }

    case 'intrinsic':
      switch(expr.operation){
        case 'bool.not':
          return {
            kind:'i32.unary',
            operation:'eqz',
            operand:lowerRuntimeExpr(
              expr.args[0]!,
              'bool',
              locals,
              signatures,
            ),
          };

        case 'bool.and':
        case 'bool.or':
        case 'bool.eq':
        case 'bool.ne':{
          const operation={
            'bool.and':'and',
            'bool.or':'or',
            'bool.eq':'eq',
            'bool.ne':'ne',
          } as const;
          return {
            kind:'i32.binary',
            operation:operation[expr.operation],
            left:lowerRuntimeExpr(
              expr.args[0]!,
              'bool',
              locals,
              signatures,
            ),
            right:lowerRuntimeExpr(
              expr.args[1]!,
              'bool',
              locals,
              signatures,
            ),
          };
        }

        default:
          return unsupported(
            'PS_WASM_UNSUPPORTED_INTRINSIC',
            "intrinsic '"+expr.operation+"' is not supported in W1",
          );
      }

    case 'call':{
      if(expr.fn.kind!=='var'){
        return unsupported(
          'PS_WASM_UNSUPPORTED_INDIRECT_CALL',
          'W1 supports direct first-order call targets only',
        );
      }
      const signature=signatures.get(expr.fn.name);
      if(signature===undefined){
        return unsupported(
          'PS_WASM_UNKNOWN_CALL_TARGET',
          "unknown call target '"+expr.fn.name+"'",
        );
      }
      if(expr.args.length!==signature.parameters.length){
        throw new WasmLoweringError(
          'PS_WASM_CALL_ARITY',
          "call '"+expr.fn.name+"' has the wrong number of arguments",
        );
      }
      return {
        kind:'call',
        target:expr.fn.name,
        args:expr.args.map((arg,index)=>
          lowerRuntimeExpr(
            arg,
            signature.parameters[index]!,
            locals,
            signatures,
          )
        ),
        result:wasmResultType(signature.result),
      };
    }

    case 'let':{
      const valueType=expressionRuntimeType(
        expr.value,
        locals,
        signatures,
      );
      if(valueType===null){
        return unsupported(
          'PS_WASM_UNSUPPORTED_UNIT_LOCAL',
          'Unit-valued let bindings are not lowered in W1',
        );
      }
      const next=new Map(locals);
      next.set(expr.name,valueType);
      return {
        kind:'let',
        name:expr.name,
        type:wasmValueType(valueType),
        value:lowerRuntimeExpr(
          expr.value,
          valueType,
          locals,
          signatures,
        ),
        body:lowerRuntimeExpr(
          expr.body,
          expected,
          next,
          signatures,
        ),
        result:wasmResultType(expected),
      };
    }

    case 'if':
      return {
        kind:'if',
        condition:lowerRuntimeExpr(
          expr.condition,
          'bool',
          locals,
          signatures,
        ),
        thenBranch:lowerRuntimeExpr(
          expr.thenBranch,
          expected,
          locals,
          signatures,
        ),
        elseBranch:lowerRuntimeExpr(
          expr.elseBranch,
          expected,
          locals,
          signatures,
        ),
        result:wasmResultType(expected),
      };

    case 'lambda':
      return unsupported(
        'PS_WASM_UNSUPPORTED_LAMBDA',
        'lambdas require function-reference/closure lowering',
      );

    case 'record':
    case 'projection':
      return unsupported(
        'PS_WASM_UNSUPPORTED_STRUCTURE',
        'structures require the Wasm GC/layout checkpoint',
      );

    case 'constructor':
    case 'match':
      return unsupported(
        'PS_WASM_UNSUPPORTED_ADT',
        'inductive runtime values require the Wasm GC/layout checkpoint',
      );
  }
}
