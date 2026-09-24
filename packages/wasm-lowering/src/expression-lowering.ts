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
import {lowerRuntimeLocal} from './local-lowering.js';
import {
  lowerNatIntrinsic,
  lowerNatLiteral,
  type WasmRuntimeSupport,
} from './runtime-support.js';

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

function lowerUIntAdd(
  operation:'uint8.add'|'uint16.add'|'uint32.add'|'uint64.add',
  args:readonly VerifiedIrExpr[],
  locals:ReadonlyMap<string,RuntimeType>,
  signatures:ReadonlyMap<string,Signature>,
  support:WasmRuntimeSupport,
):WasmIrExpr {
  const type=operation.slice(0,-4) as RuntimeValueType;
  const left=lowerRuntimeExpr(args[0]!,type,locals,signatures,support),
    right=lowerRuntimeExpr(args[1]!,type,locals,signatures,support);
  if(type==='uint64'){
    return {kind:'i64.binary',operation:'add',left,right};
  }
  const added:WasmIrExpr={kind:'i32.binary',operation:'add',left,right};
  if(type==='uint32')return added;
  return {
    kind:'i32.binary',
    operation:'and',
    left:added,
    right:{kind:'i32.const',value:type==='uint8'?0xff:0xffff},
  };
}
export function lowerRuntimeExpr(
  expr:VerifiedIrExpr,
  expected:RuntimeType,
  locals:ReadonlyMap<string,RuntimeType>,
  signatures:ReadonlyMap<string,Signature>,
  support:WasmRuntimeSupport,
):WasmIrExpr {
  const actualType=
    expr.kind==='literal'&&
    typeof expr.value==='bigint'&&
    expected==='nat'
      ?'nat'
      :expressionRuntimeType(expr,locals,signatures);
  requireType(actualType,expected,'expression');

  switch(expr.kind){
    case 'literal':
      if(typeof expr.value==='boolean'){
        return {kind:'i32.const',value:expr.value?1:0};
      }
      if(expr.value===undefined)return {kind:'nop'};
      if(typeof expr.value==='bigint'&&expected==='nat'){
        return lowerNatLiteral(expr.value,support);
      }
      return unsupported(
        'PS_WASM_UNSUPPORTED_LITERAL',
        'literal is outside the supported runtime subset',
      );

    case 'var':{
      const type=locals.get(expr.name);
      if(type===undefined||type===null){
        return unsupported(
          'PS_WASM_UNKNOWN_RUNTIME_LOCAL',
          "runtime local '"+expr.name+"' is unavailable",
        );
      }
      return lowerRuntimeLocal(expr.name,type);
    }

    case 'intrinsic':
      switch(expr.operation){
        case 'nat.add':
        case 'nat.sub':
        case 'nat.mul':
        case 'nat.div':
        case 'nat.mod':
        case 'nat.eq':
        case 'nat.ne':
        case 'nat.le':
        case 'nat.lt':{
          const left=lowerRuntimeExpr(expr.args[0]!,'nat',locals,signatures,support);
          const right=lowerRuntimeExpr(expr.args[1]!,'nat',locals,signatures,support);
          return lowerNatIntrinsic(expr.operation,left,right,support);
        }

        case 'bool.not':
          return {
            kind:'i32.unary',
            operation:'eqz',
            operand:lowerRuntimeExpr(
              expr.args[0]!,
              'bool',
              locals,
              signatures,
              support,
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
              support,
            ),
            right:lowerRuntimeExpr(
              expr.args[1]!,
              'bool',
              locals,
              signatures,
              support,
            ),
          };
        }

        case 'uint8.add':
        case 'uint16.add':
        case 'uint32.add':
        case 'uint64.add':
          return lowerUIntAdd(
            expr.operation,
            expr.args,
            locals,
            signatures,
            support,
          );

        default:
          return unsupported(
            'PS_WASM_UNSUPPORTED_INTRINSIC',
            "intrinsic '"+expr.operation+"' is not supported in W2",
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
            support,
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
          support,
        ),
        body:lowerRuntimeExpr(
          expr.body,
          expected,
          next,
          signatures,
          support,
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
          support,
        ),
        thenBranch:lowerRuntimeExpr(
          expr.thenBranch,
          expected,
          locals,
          signatures,
          support,
        ),
        elseBranch:lowerRuntimeExpr(
          expr.elseBranch,
          expected,
          locals,
          signatures,
          support,
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