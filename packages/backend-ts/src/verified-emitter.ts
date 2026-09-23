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

function emitLiteral(
  value:bigint|string|boolean|undefined,
):string {
  if(typeof value==='bigint')return String(value)+'n';
  if(value===undefined)return 'undefined';
  return JSON.stringify(value);
}

type BrandMap=ReadonlyMap<string,string>;

function emitExpr(
  expr:VerifiedIrExpr,
  brands:BrandMap,
):string {
  switch(expr.kind){
    case 'literal':
      return emitLiteral(expr.value);
    case 'var':
      return expr.name;
    case 'intrinsic':{
      const left=emitExpr(expr.args[0]!,brands);
      const right=emitExpr(expr.args[1]!,brands);
      if(expr.operation==='nat.add')return '('+left+' + '+right+')';
      if(expr.operation==='nat.mul')return '('+left+' * '+right+')';
      if(expr.operation==='nat.le')return '('+left+' <= '+right+')';
      if(expr.operation==='nat.lt')return '('+left+' < '+right+')';
      return '((__ps_a: bigint, __ps_b: bigint) => '+
        '(__ps_a >= __ps_b ? __ps_a - __ps_b : 0n))('+
        left+', '+right+')';
    }
    case 'call':
      return emitExpr(expr.fn,brands)+'('+
        expr.args.map((arg)=>emitExpr(arg,brands)).join(', ')+')';
    case 'lambda':
      return '('+
        expr.parameters.map((parameter)=>
          parameter.name+': '+emitType(parameter.type)
        ).join(', ')+') => '+emitExpr(expr.body,brands);
    case 'let':
      return '(() => { const '+expr.name+' = '+
        emitExpr(expr.value,brands)+'; return '+
        emitExpr(expr.body,brands)+'; })()';
    case 'if':
      return '('+emitExpr(expr.condition,brands)+' ? '+
        emitExpr(expr.thenBranch,brands)+' : '+
        emitExpr(expr.elseBranch,brands)+')';
    case 'record':{
      const brand=brands.get(expr.structure);
      if(brand===undefined){
        throw new Error(
          "PS_TS_UNKNOWN_STRUCTURE: '"+expr.structure+"'",
        );
      }
      const fields=expr.fields.map((field)=>
        field.name+': '+emitExpr(field.value,brands)
      );
      return '{ ['+brand+']: true'+
        (fields.length===0?'':', '+fields.join(', '))+
        ' }';
    }
    case 'projection':
      return emitExpr(expr.target,brands)+'.'+expr.field;
  }
}

function buildBrandMap(
  module:VerifiedIrModule,
):ReadonlyMap<string,string> {
  const used=new Set(module.declarations.map((item)=>item.name));
  for(const structure of module.structures??[]){
    used.add(structure.name);
  }
  const result=new Map<string,string>();
  let index=0;
  for(const structure of module.structures??[]){
    let candidate='__ps$brand$'+index++;
    while(used.has(candidate))candidate+='_';
    used.add(candidate);
    result.set(structure.name,candidate);
  }
  return result;
}

function emitStructures(
  module:VerifiedIrModule,
  brands:BrandMap,
):string[] {
  const lines:string[]=[];
  for(const structure of module.structures??[]){
    const brand=brands.get(structure.name);
    if(brand===undefined){
      throw new Error(
        "PS_TS_STRUCTURE_BRAND_MISSING: '"+structure.name+"'",
      );
    }
    lines.push(
      'const '+brand+': unique symbol = Symbol('+
      JSON.stringify('ProofScript.'+structure.name)+');',
    );
    lines.push(
      'export interface '+structure.name+' { '+
      'readonly ['+brand+']: true; '+
      structure.fields.map((field)=>
        'readonly '+field.name+': '+emitType(field.type)+';'
      ).join(' ')+
      ' }',
    );
  }
  return lines;
}

export function emitVerifiedTypeScript(
  module:VerifiedIrModule,
):string {
  validateVerifiedIrModule(module);
  const brands=buildBrandMap(module);
  const lines=[
    '// generated from pskernel-admitted ProofScript checked core',
    ...emitStructures(module,brands),
  ];

  for(const declaration of module.declarations){
    const generics=declaration.typeParameters.length===0
      ?''
      :'<'+declaration.typeParameters
        .map((item)=>item.name).join(', ')+'>';

    if(declaration.parameters.length===0){
      if(declaration.typeParameters.length>0){
        throw new Error(
          "PS_TS_GENERIC_VALUE_UNSUPPORTED: '"+
          declaration.name+
          "' has erased type parameters but no runtime parameters",
        );
      }
      lines.push(
        'export const '+declaration.name+': '+
        emitType(declaration.resultType)+' = '+
        emitExpr(declaration.body,brands)+';',
      );
      continue;
    }

    const parameters=declaration.parameters.map((parameter)=>
      parameter.name+': '+emitType(parameter.type)
    ).join(', ');
    lines.push(
      'export function '+declaration.name+generics+
      '('+parameters+'): '+emitType(declaration.resultType)+
      ' { return '+emitExpr(declaration.body,brands)+'; }',
    );
  }

  return lines.join('\n')+'\n';
}
