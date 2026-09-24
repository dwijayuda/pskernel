import {
  wasmAbiPhysicalType,
  type WasmIrExpr,
  type WasmIrModule,
  type WasmValueType,
} from './model.js';

const identifierPattern=/^[A-Za-z_$][A-Za-z0-9_$]*$/u;

function assertName(name:string,label:string):void {
  if(!identifierPattern.test(name)){
    throw new Error(
      "PS_WASM_IR_INVALID_"+label+": '"+name+"'",
    );
  }
}

interface FunctionSignature {
  readonly parameters:readonly WasmValueType[];
  readonly result:WasmValueType|null;
}

function expectType(
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
  functions:ReadonlyMap<string,FunctionSignature>,
):WasmValueType|null {
  switch(expr.kind){
    case 'nop':
      return null;
    case 'i32.const':
      if(!Number.isInteger(expr.value)){
        throw new Error('PS_WASM_IR_I32_CONST_NON_INTEGER');
      }
      if(expr.value<-2147483648||expr.value>4294967295){
        throw new Error('PS_WASM_IR_I32_CONST_RANGE');
      }
      return 'i32';
    case 'local':{
      assertName(expr.name,'LOCAL_NAME');
      const type=locals.get(expr.name);
      if(type===undefined){
        throw new Error(
          "PS_WASM_IR_UNKNOWN_LOCAL: '"+expr.name+"'",
        );
      }
      expectType(expr.type,type,'local '+expr.name);
      return type;
    }
    case 'call':{
      assertName(expr.target,'CALL_TARGET');
      const signature=functions.get(expr.target);
      if(signature===undefined){
        throw new Error(
          "PS_WASM_IR_UNKNOWN_FUNCTION: '"+expr.target+"'",
        );
      }
      if(expr.args.length!==signature.parameters.length){
        throw new Error(
          "PS_WASM_IR_CALL_ARITY: '"+expr.target+
          "' expected "+signature.parameters.length+
          ' argument(s)',
        );
      }
      expr.args.forEach((arg,index)=>{
        const actual=wasmIrExprType(
          arg,
          locals,
          functions,
        );
        expectType(
          actual,
          signature.parameters[index]!,
          'argument '+index+' of '+expr.target,
        );
      });
      expectType(
        expr.result,
        signature.result,
        'call '+expr.target,
      );
      return expr.result;
    }
    case 'let':{
      assertName(expr.name,'LET_NAME');
      const valueType=wasmIrExprType(
        expr.value,
        locals,
        functions,
      );
      expectType(valueType,expr.type,'let '+expr.name);
      const next=new Map(locals);
      next.set(expr.name,expr.type);
      const bodyType=wasmIrExprType(
        expr.body,
        next,
        functions,
      );
      expectType(
        bodyType,
        expr.result,
        'let body '+expr.name,
      );
      return expr.result;
    }
    case 'if':
      expectType(
        wasmIrExprType(expr.condition,locals,functions),
        'i32',
        'if condition',
      );
      expectType(
        wasmIrExprType(expr.thenBranch,locals,functions),
        expr.result,
        'if then branch',
      );
      expectType(
        wasmIrExprType(expr.elseBranch,locals,functions),
        expr.result,
        'if else branch',
      );
      return expr.result;
    case 'i32.unary':
      expectType(
        wasmIrExprType(expr.operand,locals,functions),
        'i32',
        expr.operation+' operand',
      );
      return 'i32';
    case 'i32.binary':
      expectType(
        wasmIrExprType(expr.left,locals,functions),
        'i32',
        expr.operation+' left operand',
      );
      expectType(
        wasmIrExprType(expr.right,locals,functions),
        'i32',
        expr.operation+' right operand',
      );
      return 'i32';
  }
}

function wasmExprUsesExternref(
  expr:WasmIrExpr,
):boolean {
  switch(expr.kind){
    case 'nop':
    case 'i32.const':
      return false;
    case 'local':
      return expr.type==='externref';
    case 'call':
      return expr.result==='externref'||
        expr.args.some(wasmExprUsesExternref);
    case 'let':
      return expr.type==='externref'||
        expr.result==='externref'||
        wasmExprUsesExternref(expr.value)||
        wasmExprUsesExternref(expr.body);
    case 'if':
      return expr.result==='externref'||
        wasmExprUsesExternref(expr.condition)||
        wasmExprUsesExternref(expr.thenBranch)||
        wasmExprUsesExternref(expr.elseBranch);
    case 'i32.unary':
      return wasmExprUsesExternref(expr.operand);
    case 'i32.binary':
      return wasmExprUsesExternref(expr.left)||
        wasmExprUsesExternref(expr.right);
  }
}

export function validateWasmIrModule(
  module:WasmIrModule,
):true {
  if(module.kind!=='proofscript-wasm-ir'){
    throw new Error('PS_WASM_IR_INVALID_MODULE_KIND');
  }
  if(
    module.profile!=='proofscript-wasm32-mvp-js-v1'&&
    module.profile!=='proofscript-wasm32-ref-js-v1'
  ){
    throw new Error('PS_WASM_IR_UNSUPPORTED_PROFILE');
  }

  const functions=
    new Map<string,FunctionSignature>();
  const exportNames=new Set<string>();

  for(const fn of module.functions){
    assertName(fn.name,'FUNCTION_NAME');
    if(functions.has(fn.name)){
      throw new Error(
        "PS_WASM_IR_DUPLICATE_FUNCTION: '"+fn.name+"'",
      );
    }

    const params=new Set<string>();
    for(const parameter of fn.parameters){
      assertName(parameter.name,'PARAMETER_NAME');
      if(params.has(parameter.name)){
        throw new Error(
          "PS_WASM_IR_DUPLICATE_PARAMETER: '"+
          parameter.name+"'",
        );
      }
      params.add(parameter.name);
    }

    if(fn.abi.parameters.length!==fn.parameters.length){
      throw new Error(
        "PS_WASM_IR_ABI_ARITY: '"+fn.name+
        "' ABI has "+fn.abi.parameters.length+
        ' parameter(s), physical function has '+
        fn.parameters.length,
      );
    }

    fn.parameters.forEach((parameter,index)=>{
      expectType(
        wasmAbiPhysicalType(
          fn.abi.parameters[index]!,
        ),
        parameter.type,
        'ABI parameter '+index+' of '+fn.name,
      );
    });
    expectType(
      fn.abi.result===null
        ?null
        :wasmAbiPhysicalType(fn.abi.result),
      fn.result,
      'ABI result of '+fn.name,
    );

    if(fn.exportName!==undefined){
      if(fn.exportName.length===0){
        throw new Error(
          'PS_WASM_IR_EMPTY_EXPORT_NAME',
        );
      }
      if(exportNames.has(fn.exportName)){
        throw new Error(
          "PS_WASM_IR_DUPLICATE_EXPORT: '"+
          fn.exportName+"'",
        );
      }
      exportNames.add(fn.exportName);
    }

    functions.set(fn.name,{
      parameters:fn.parameters.map(
        (item)=>item.type,
      ),
      result:fn.result,
    });
  }

  for(const fn of module.functions){
    const locals=new Map(
      fn.parameters.map(
        (parameter)=>[
          parameter.name,
          parameter.type,
        ] as const,
      ),
    );
    const bodyType=wasmIrExprType(
      fn.body,
      locals,
      functions,
    );
    expectType(
      bodyType,
      fn.result,
      'function '+fn.name,
    );

    if(
      module.profile===
        'proofscript-wasm32-mvp-js-v1'&&(
        fn.result==='externref'||
        fn.parameters.some(
          (parameter)=>
            parameter.type==='externref',
        )||
        wasmExprUsesExternref(fn.body)
      )
    ){
      throw new Error(
        'PS_WASM_IR_REFERENCE_TYPE_REQUIRES_REF_PROFILE: '+
        fn.name,
      );
    }
  }

  return true;
}
