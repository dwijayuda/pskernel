import {
  validateVerifiedIrModule,
  type VerifiedIrExpr,
  type VerifiedIrModule,
  type VerifiedIrType,
} from '@proofscript/compiler-ir/verified';

function emitType(type:VerifiedIrType):string {
  switch(type.kind){
    case 'unknown':return 'unknown';
    case 'typeParameter':return type.name;
    case 'primitive':
      switch(type.name){
        case 'Nat':
        case 'Int':
          return 'bigint';
        case 'Bool':
          return 'boolean';
        case 'String':
          return 'string';
        case 'Unit':
          return 'undefined';
      }
    case 'named':
      return type.args.length===0
        ?type.name
        :type.name+'<'+type.args.map(emitType).join(', ')+'>';
    case 'function':
      return '('+
        type.parameters.map((parameter,index)=>
          '_arg'+index+': '+emitType(parameter)
        ).join(', ')+') => '+emitType(type.result);
  }
}

function emitLiteral(value:bigint|string|boolean|undefined):string {
  if(typeof value==='bigint')return String(value)+'n';
  if(value===undefined)return 'undefined';
  return JSON.stringify(value);
}

function emitExpr(expr:VerifiedIrExpr):string {
  switch(expr.kind){
    case 'literal':
      return emitLiteral(expr.value);
    case 'var':
      return expr.name;
    case 'intrinsic':{
      const left=emitExpr(expr.args[0]!);
      const right=emitExpr(expr.args[1]!);
      if(expr.operation==='nat.add')return '('+left+' + '+right+')';
      if(expr.operation==='nat.mul')return '('+left+' * '+right+')';
      return '((__ps_a: bigint, __ps_b: bigint) => '+
        '(__ps_a >= __ps_b ? __ps_a - __ps_b : 0n))('+
        left+', '+right+')';
    }
    case 'call':
      return emitExpr(expr.fn)+'('+
        expr.args.map(emitExpr).join(', ')+')';
    case 'lambda':
      return '('+
        expr.parameters.map((parameter)=>
          parameter.name+': '+emitType(parameter.type)
        ).join(', ')+') => '+emitExpr(expr.body);
    case 'let':
      return '(() => { const '+expr.name+' = '+emitExpr(expr.value)+
        '; return '+emitExpr(expr.body)+'; })()';
  }
}

export function emitVerifiedTypeScript(
  module:VerifiedIrModule,
):string {
  validateVerifiedIrModule(module);
  const lines=[
    '// generated from pskernel-admitted ProofScript checked core',
  ];

  for(const declaration of module.declarations){
    const generics=declaration.typeParameters.length===0
      ?''
      :'<'+declaration.typeParameters.map((item)=>item.name).join(', ')+'>';

    if(declaration.parameters.length===0){
      if(declaration.typeParameters.length>0){
        throw new Error(
          "PS_TS_GENERIC_VALUE_UNSUPPORTED: '"+declaration.name+
          "' has erased type parameters but no runtime parameters",
        );
      }
      lines.push(
        'export const '+declaration.name+': '+
        emitType(declaration.resultType)+' = '+
        emitExpr(declaration.body)+';',
      );
      continue;
    }

    const parameters=declaration.parameters.map((parameter)=>
      parameter.name+': '+emitType(parameter.type)
    ).join(', ');
    lines.push(
      'export function '+declaration.name+generics+
      '('+parameters+'): '+emitType(declaration.resultType)+
      ' { return '+emitExpr(declaration.body)+'; }',
    );
  }

  return lines.join('\n')+'\n';
}
