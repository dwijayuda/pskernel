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

function collectExprNames(
  expr:VerifiedIrExpr,
  out:Set<string>=new Set(),
):Set<string> {
  switch(expr.kind){
    case 'literal':
      return out;
    case 'var':
      out.add(expr.name);
      return out;
    case 'intrinsic':
      for(const arg of expr.args)collectExprNames(arg,out);
      return out;
    case 'call':
      collectExprNames(expr.fn,out);
      for(const arg of expr.args)collectExprNames(arg,out);
      return out;
    case 'lambda':
      for(const parameter of expr.parameters)out.add(parameter.name);
      collectExprNames(expr.body,out);
      return out;
    case 'let':
      out.add(expr.name);
      collectExprNames(expr.value,out);
      collectExprNames(expr.body,out);
      return out;
    case 'if':
      collectExprNames(expr.condition,out);
      collectExprNames(expr.thenBranch,out);
      collectExprNames(expr.elseBranch,out);
      return out;
    case 'record':
    case 'constructor':
      for(const field of expr.fields)collectExprNames(field.value,out);
      return out;
    case 'projection':
      collectExprNames(expr.target,out);
      return out;
    case 'match':
      collectExprNames(expr.scrutinee,out);
      for(const alternative of expr.alternatives){
        for(const binding of alternative.bindings)out.add(binding.name);
        collectExprNames(alternative.body,out);
      }
      return out;
  }
}

function freshMatchTemp(expr:VerifiedIrExpr):string {
  const used=collectExprNames(expr);
  let index=0;
  let candidate='__ps$match
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
      const left=emitVerifiedExpr(expr.args[0]!,brands,tags);
      const right=emitVerifiedExpr(expr.args[1]!,brands,tags);
      if(expr.operation==='nat.add')return '('+left+' + '+right+')';
      if(expr.operation==='nat.mul')return '('+left+' * '+right+')';
      if(expr.operation==='nat.le')return '('+left+' <= '+right+')';
      if(expr.operation==='nat.lt')return '('+left+' < '+right+')';
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
      if(expr.fields.length===0)return access;
      return access+'('+
        expr.fields.map((field)=>
          emitVerifiedExpr(field.value,brands,tags)
        ).join(', ')+')';
    }
    case 'match':{
      const tag=tags.get(expr.inductive);
      if(tag===undefined){
        throw new Error(
          "PS_TS_UNKNOWN_MATCH_INDUCTIVE: '"+expr.inductive+"'",
        );
      }
      const temp=freshMatchTemp(expr);
      const cases=expr.alternatives.map((alternative)=>{
        const body=emitVerifiedExpr(alternative.body,brands,tags);
        if(alternative.bindings.length===0){
          return 'case '+JSON.stringify(alternative.constructor)+
            ': return '+body+';';
        }
        const parameters=alternative.bindings.map(
          (binding)=>binding.name,
        ).join(', ');
        const args=alternative.bindings.map(
          (binding)=>temp+'.'+binding.field,
        ).join(', ');
        return 'case '+JSON.stringify(alternative.constructor)+
          ': return (('+parameters+') => '+body+')('+args+');';
      }).join(' ');
      return '(('+temp+') => { switch ('+temp+'['+tag+']) { '+
        cases+' } throw new Error("invalid ProofScript constructor tag"); })('+
        emitVerifiedExpr(expr.scrutinee,brands,tags)+')';
    }
  }
}
+index;
  while(used.has(candidate)){
    index+=1;
    candidate='__ps$match
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
      const left=emitVerifiedExpr(expr.args[0]!,brands,tags);
      const right=emitVerifiedExpr(expr.args[1]!,brands,tags);
      if(expr.operation==='nat.add')return '('+left+' + '+right+')';
      if(expr.operation==='nat.mul')return '('+left+' * '+right+')';
      if(expr.operation==='nat.le')return '('+left+' <= '+right+')';
      if(expr.operation==='nat.lt')return '('+left+' < '+right+')';
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
      if(expr.fields.length===0)return access;
      return access+'('+
        expr.fields.map((field)=>
          emitVerifiedExpr(field.value,brands,tags)
        ).join(', ')+')';
    }
  }
}
+index;
  }
  return candidate;
}

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
      const left=emitVerifiedExpr(expr.args[0]!,brands,tags);
      const right=emitVerifiedExpr(expr.args[1]!,brands,tags);
      if(expr.operation==='nat.add')return '('+left+' + '+right+')';
      if(expr.operation==='nat.mul')return '('+left+' * '+right+')';
      if(expr.operation==='nat.le')return '('+left+' <= '+right+')';
      if(expr.operation==='nat.lt')return '('+left+' < '+right+')';
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
      if(expr.fields.length===0)return access;
      return access+'('+
        expr.fields.map((field)=>
          emitVerifiedExpr(field.value,brands,tags)
        ).join(', ')+')';
    }
  }
}
