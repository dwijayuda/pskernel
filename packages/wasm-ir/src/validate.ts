import {
  PROOFSCRIPT_BIGINT_RUNTIME_MODULE,
  wasmAbiPhysicalType,
  type WasmBigIntLiteral,
  type WasmIrExpr,
  type WasmIrFunctionImport,
  type WasmIrModule,
} from './model.js';
import {
  assertWasmIrName,
  expectWasmIrType,
  wasmIrExprType,
  type WasmIrFunctionSignature,
} from './expr-type.js';

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
        expr.args.some(
          wasmExprUsesExternref,
        );
    case 'let':
      return expr.type==='externref'||
        expr.result==='externref'||
        wasmExprUsesExternref(
          expr.value,
        )||
        wasmExprUsesExternref(
          expr.body,
        );
    case 'if':
      return expr.result==='externref'||
        wasmExprUsesExternref(
          expr.condition,
        )||
        wasmExprUsesExternref(
          expr.thenBranch,
        )||
        wasmExprUsesExternref(
          expr.elseBranch,
        );
    case 'i32.unary':
      return wasmExprUsesExternref(
        expr.operand,
      );
    case 'i32.binary':
    case 'i64.binary':
      return wasmExprUsesExternref(expr.left)||
        wasmExprUsesExternref(expr.right);
  }
}

function validateBigIntLiteral(
  literal:WasmBigIntLiteral,
):void {
  const pattern=literal.kind==='nat'
    ?/^(?:0|[1-9]\d*)$/u
    :/^(?:0|-?[1-9]\d*)$/u;
  if(!pattern.test(literal.decimal)){
    throw new Error(
      'PS_WASM_IR_BIGINT_LITERAL_CANONICAL: '+
      literal.kind+' '+literal.decimal,
    );
  }
}

function validateBigIntImport(
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

export function validateWasmIrModule(
  module:WasmIrModule,
):true {
  if(
    module.kind!=='proofscript-wasm-ir'
  ){
    throw new Error(
      'PS_WASM_IR_INVALID_MODULE_KIND',
    );
  }
  if(
    module.profile!==
      'proofscript-wasm32-mvp-js-v1'&&
    module.profile!==
      'proofscript-wasm32-ref-js-v1'
  ){
    throw new Error(
      'PS_WASM_IR_UNSUPPORTED_PROFILE',
    );
  }

  const functions=
    new Map<
      string,
      WasmIrFunctionSignature
    >();
  const exportNames=new Set<string>();

  for(const imported of module.imports??[]){
    assertWasmIrName(imported.internalName,'IMPORT_NAME');
    validateBigIntImport(imported);
    if(functions.has(imported.internalName)){
      throw new Error(
        "PS_WASM_IR_DUPLICATE_FUNCTION: '"+
        imported.internalName+"'",
      );
    }
    functions.set(imported.internalName,{
      parameters:imported.parameters,
      result:imported.result,
    });
    if(
      module.profile==='proofscript-wasm32-mvp-js-v1'&&(
        imported.result==='externref'||
        imported.parameters.includes('externref')
      )
    ){
      throw new Error(
        'PS_WASM_IR_REFERENCE_TYPE_REQUIRES_REF_PROFILE: '+
        imported.internalName,
      );
    }
  }

  const literalKeys=new Set<string>();
  for(const literal of module.bigintLiterals??[]){
    validateBigIntLiteral(literal);
    const key=literal.kind+':'+literal.decimal;
    if(literalKeys.has(key)){
      throw new Error(
        'PS_WASM_IR_DUPLICATE_BIGINT_LITERAL: '+key,
      );
    }
    literalKeys.add(key);
  }
  if(
    module.profile==='proofscript-wasm32-mvp-js-v1'&&
    (module.bigintLiterals?.length??0)>0
  ){
    throw new Error(
      'PS_WASM_IR_REFERENCE_TYPE_REQUIRES_REF_PROFILE: bigint literals',
    );
  }

  for(const fn of module.functions){
    assertWasmIrName(
      fn.name,
      'FUNCTION_NAME',
    );
    if(functions.has(fn.name)){
      throw new Error(
        "PS_WASM_IR_DUPLICATE_FUNCTION: '"+
        fn.name+"'",
      );
    }

    const params=new Set<string>();
    for(const parameter of fn.parameters){
      assertWasmIrName(
        parameter.name,
        'PARAMETER_NAME',
      );
      if(params.has(parameter.name)){
        throw new Error(
          "PS_WASM_IR_DUPLICATE_PARAMETER: '"+
          parameter.name+"'",
        );
      }
      params.add(parameter.name);
    }

    if(
      fn.abi.parameters.length!==
        fn.parameters.length
    ){
      throw new Error(
        "PS_WASM_IR_ABI_ARITY: '"+
        fn.name+"' ABI has "+
        fn.abi.parameters.length+
        ' parameter(s), physical function has '+
        fn.parameters.length,
      );
    }

    fn.parameters.forEach(
      (parameter,index)=>{
        expectWasmIrType(
          wasmAbiPhysicalType(
            fn.abi.parameters[index]!,
          ),
          parameter.type,
          'ABI parameter '+index+
          ' of '+fn.name,
        );
      },
    );

    expectWasmIrType(
      fn.abi.result===null
        ?null
        :wasmAbiPhysicalType(
          fn.abi.result,
        ),
      fn.result,
      'ABI result of '+fn.name,
    );

    if(fn.exportName!==undefined){
      if(fn.exportName.length===0){
        throw new Error(
          'PS_WASM_IR_EMPTY_EXPORT_NAME',
        );
      }
      if(
        exportNames.has(fn.exportName)
      ){
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
    expectWasmIrType(
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
