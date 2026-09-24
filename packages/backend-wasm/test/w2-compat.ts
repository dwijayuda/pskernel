import binaryen from 'binaryen';
import type {
  WasmIrExpr,
  WasmIrFunction,
  WasmIrModule,
  WasmValueType,
} from '@proofscript/wasm-ir';

/**
 * Frozen executable model of the W2 emitter at
 * 0a7b08c699c867d20a598a15588a71bf237595bb.
 *
 * Keep this independent of the production emitter so W3 changes cannot
 * silently redefine the byte-compatibility oracle.
 */
function binaryenType(type:WasmValueType):number {
  switch(type){
    case 'i32':return binaryen.i32;
    case 'i64':return binaryen.i64;
    case 'f32':return binaryen.f32;
    case 'f64':return binaryen.f64;
    case 'externref':return binaryen.externref;
  }
}

interface LocalAllocation {
  readonly indices:ReadonlyMap<WasmIrExpr,number>;
  readonly types:readonly WasmValueType[];
}

function allocateLocals(
  expr:WasmIrExpr,
  parameterCount:number,
):LocalAllocation {
  const indices=new Map<WasmIrExpr,number>();
  const types:WasmValueType[]=[];

  const visit=(node:WasmIrExpr):void=>{
    switch(node.kind){
      case 'nop':
      case 'i32.const':
      case 'local':
        return;
      case 'call':
        for(const arg of node.args)visit(arg);
        return;
      case 'let':
        visit(node.value);
        indices.set(node,parameterCount+types.length);
        types.push(node.type);
        visit(node.body);
        return;
      case 'if':
        visit(node.condition);
        visit(node.thenBranch);
        visit(node.elseBranch);
        return;
      case 'i32.unary':
        visit(node.operand);
        return;
      case 'i32.binary':
      case 'i64.binary':
        visit(node.left);
        visit(node.right);
        return;
    }
  };
  visit(expr);
  return {indices,types};
}

function emitFunctionBody(
  module:binaryen.Module,
  fn:WasmIrFunction,
):{
  readonly locals:readonly number[];
  readonly body:number;
} {
  const allocation=allocateLocals(fn.body,fn.parameters.length);
  const parameterIndices=new Map(
    fn.parameters.map((parameter,index)=>[parameter.name,index] as const),
  );

  const emit=(
    expr:WasmIrExpr,
    env:ReadonlyMap<string,number>,
  ):number=>{
    switch(expr.kind){
      case 'nop':
        return module.nop();
      case 'i32.const':
        return module.i32.const(expr.value);
      case 'local':{
        const index=env.get(expr.name);
        if(index===undefined){
          throw new Error(
            "W2 compatibility oracle missing local '"+expr.name+"'",
          );
        }
        return module.local.get(index,binaryenType(expr.type));
      }
      case 'call':
        return module.call(
          expr.target,
          expr.args.map((arg)=>emit(arg,env)),
          expr.result===null?binaryen.none:binaryenType(expr.result),
        );
      case 'let':{
        const index=allocation.indices.get(expr);
        if(index===undefined){
          throw new Error('W2 compatibility oracle missing let allocation');
        }
        const next=new Map(env);
        next.set(expr.name,index);
        return module.block(
          null,
          [
            module.local.set(index,emit(expr.value,env)),
            emit(expr.body,next),
          ],
          expr.result===null?binaryen.none:binaryenType(expr.result),
        );
      }
      case 'if':
        return module.if(
          emit(expr.condition,env),
          emit(expr.thenBranch,env),
          emit(expr.elseBranch,env),
        );
      case 'i32.unary':
        return module.i32.eqz(emit(expr.operand,env));
      case 'i32.binary':{
        const left=emit(expr.left,env);
        const right=emit(expr.right,env);
        switch(expr.operation){
          case 'add':return module.i32.add(left,right);
          case 'and':return module.i32.and(left,right);
          case 'or':return module.i32.or(left,right);
          case 'eq':return module.i32.eq(left,right);
          case 'ne':return module.i32.ne(left,right);
        }
      }
      case 'i64.binary':
        return module.i64.add(
          emit(expr.left,env),
          emit(expr.right,env),
        );
    }
  };

  return {
    locals:allocation.types.map(binaryenType),
    body:emit(fn.body,parameterIndices),
  };
}

export function emitFrozenW2Bytes(input:WasmIrModule):Uint8Array {
  if(input.profile!=='proofscript-wasm32-mvp-js-v1'){
    throw new Error('W2 compatibility oracle only accepts MVP profile');
  }
  if((input.imports?.length??0)!==0||(input.bigintLiterals?.length??0)!==0){
    throw new Error('W2 compatibility oracle does not accept W3 runtime data');
  }

  const module=new binaryen.Module();
  module.setFeatures(binaryen.Features.MVP);

  for(const fn of input.functions){
    const emitted=emitFunctionBody(module,fn);
    module.addFunction(
      fn.name,
      binaryen.createType(fn.parameters.map((item)=>binaryenType(item.type))),
      fn.result===null?binaryen.none:binaryenType(fn.result),
      [...emitted.locals],
      emitted.body,
    );
    if(fn.exportName!==undefined){
      module.addFunctionExport(fn.name,fn.exportName);
    }
  }

  if(!module.validate()){
    throw new Error('W2 compatibility oracle produced invalid module');
  }
  return module.emitBinary();
}
