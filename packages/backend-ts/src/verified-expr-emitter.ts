import type {
  VerifiedIrExpr,
} from '@proofscript/compiler-ir/verified';
import {
  emitVerifiedLiteral,
  emitVerifiedType,
} from './verified-type-emitter.js';
import type {
  BrandMap,
  TagMap,
} from './verified-symbols.js';
import {emitVerifiedMatch} from './verified-match-emitter.js';

export function emitVerifiedExpr(
  expr:VerifiedIrExpr,
  brands:BrandMap,
  tags:TagMap,
):string {
  switch(expr.kind){
    case 'literal':
      return emitVerifiedLiteral(expr.value);
    case 'var':
      return expr.name;
    case 'intrinsic':{
      if(expr.operation==='bool.not'){
        return '(!'+emitVerifiedExpr(expr.args[0]!,brands,tags)+')';
      }
      const left=emitVerifiedExpr(expr.args[0]!,brands,tags);
      const right=emitVerifiedExpr(expr.args[1]!,brands,tags);
      if(expr.operation==='nat.add')return '('+left+' + '+right+')';
      if(expr.operation==='nat.mul')return '('+left+' * '+right+')';
      if(expr.operation==='nat.div'){
        return '((__ps_a: bigint, __ps_b: bigint) => '+
          '(__ps_b === 0n ? 0n : __ps_a / __ps_b))('+
          left+', '+right+')';
      }
      if(expr.operation==='nat.mod'){
        return '((__ps_a: bigint, __ps_b: bigint) => '+
          '(__ps_b === 0n ? __ps_a : __ps_a % __ps_b))('+
          left+', '+right+')';
      }
      if(expr.operation==='nat.eq')return '('+left+' === '+right+')';
      if(expr.operation==='nat.ne')return '('+left+' !== '+right+')';
      if(expr.operation==='nat.le')return '('+left+' <= '+right+')';
      if(expr.operation==='nat.lt')return '('+left+' < '+right+')';
      if(expr.operation==='bool.and')return '('+left+' && '+right+')';
      if(expr.operation==='bool.or')return '('+left+' || '+right+')';
      if(expr.operation==='bool.eq')return '('+left+' === '+right+')';
      if(expr.operation==='bool.ne')return '('+left+' !== '+right+')';
      return '((__ps_a: bigint, __ps_b: bigint) => '+
        '(__ps_a >= __ps_b ? __ps_a - __ps_b : 0n))('+
        left+', '+right+')';
    }
    case 'call':
      return emitVerifiedExpr(expr.fn,brands,tags)+'('+
        expr.args.map((arg)=>
          emitVerifiedExpr(arg,brands,tags)
        ).join(', ')+')';
    case 'lambda':
      return '('+
        expr.parameters.map((parameter)=>
          parameter.name+': '+emitVerifiedType(parameter.type)
        ).join(', ')+') => '+
        emitVerifiedExpr(expr.body,brands,tags);
    case 'let':
      return '(() => { const '+expr.name+' = '+
        emitVerifiedExpr(expr.value,brands,tags)+
        '; return '+emitVerifiedExpr(expr.body,brands,tags)+'; })()';
    case 'if':
      return '('+emitVerifiedExpr(expr.condition,brands,tags)+' ? '+
        emitVerifiedExpr(expr.thenBranch,brands,tags)+' : '+
        emitVerifiedExpr(expr.elseBranch,brands,tags)+')';
    case 'record':{
      const brand=brands.get(expr.structure);
      if(brand===undefined){
        throw new Error(
          "PS_TS_UNKNOWN_STRUCTURE: '"+expr.structure+"'",
        );
      }
      const fields=expr.fields.map((field)=>
        field.name+': '+
        emitVerifiedExpr(field.value,brands,tags)
      );
      return '{ ['+brand+']: true'+
        (fields.length===0?'':', '+fields.join(', '))+' }';
    }
    case 'projection':
      return emitVerifiedExpr(expr.target,brands,tags)+'.'+expr.field;
    case 'constructor':{
      if(!tags.has(expr.inductive)){
        throw new Error(
          "PS_TS_UNKNOWN_INDUCTIVE: '"+expr.inductive+"'",
        );
      }
      const access=expr.inductive+
        '['+JSON.stringify(expr.constructor)+']';
      const typeArgs=expr.typeArgs??[];
      const generic=typeArgs.length===0
        ?''
        :'<'+typeArgs.map(emitVerifiedType).join(', ')+'>';
      if(typeArgs.length===0&&expr.fields.length===0)return access;
      return access+generic+'('+
        expr.fields.map((field)=>
          emitVerifiedExpr(field.value,brands,tags)
        ).join(', ')+')';
    }
    case 'match':
      return emitVerifiedMatch(
        expr,
        brands,
        tags,
        emitVerifiedExpr,
      );
  }
}
