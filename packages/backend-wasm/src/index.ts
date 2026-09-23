import binaryen from 'binaryen';
import {
  validateWasmIrModule,
  type WasmIrExpr,
  type WasmIrFunction,
  type WasmIrModule,
  type WasmValueType,
} from '@proofscript/wasm-ir';

export const BINARYEN_VERSION='132.0.0' as const;
export const PROOFSCRIPT_WASM_BINARYEN_FEATURES=
  binaryen.Features.MVP;

export interface WasmEmitOptions {
  readonly optimize?:boolean;
}

export interface WasmEmitResult {
  readonly binary:Uint8Array;
  readonly text:string;
  readonly optimized:boolean;
  readonly binaryenVersion:typeof BINARYEN_VERSION;
  readonly profile:WasmIrModule['profile'];
}

function binaryenType(type:WasmValueType):number {
  switch(type){
    case 'i32':return binaryen.i32;
    case 'i64':return binaryen.i64;
    case 'f32':return binaryen.f32;
    case 'f64':return binaryen.f64;
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
            "PS_WASM_EMIT_UNKNOWN_LOCAL: '"+expr.name+"'",
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
          throw new Error('PS_WASM_EMIT_LOCAL_ALLOCATION_MISSING');
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
          case 'and':return module.i32.and(left,right);
          case 'or':return module.i32.or(left,right);
          case 'eq':return module.i32.eq(left,right);
          case 'ne':return module.i32.ne(left,right);
        }
      }
    }
  };

  return {
    locals:allocation.types.map(binaryenType),
    body:emit(fn.body,parameterIndices),
  };
}

export function emitBinaryenWasm(
  input:WasmIrModule,
  options:WasmEmitOptions={},
):WasmEmitResult {
  validateWasmIrModule(input);
  const module=new binaryen.Module();
  module.setFeatures(PROOFSCRIPT_WASM_BINARYEN_FEATURES);

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
    throw new Error('PS_WASM_BINARYEN_VALIDATION_FAILED');
  }

  if(options.optimize===true){
    module.optimize();
    if(!module.validate()){
      throw new Error('PS_WASM_BINARYEN_POST_OPT_VALIDATION_FAILED');
    }
  }

  return {
    binary:module.emitBinary(),
    text:module.emitText(),
    optimized:options.optimize===true,
    binaryenVersion:BINARYEN_VERSION,
    profile:input.profile,
  };
}
