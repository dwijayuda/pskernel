import type {
  VerifiedIrExpr,
} from '@proofscript/compiler-ir/verified';
import type {
  BrandMap,
  TagMap,
} from './verified-symbols.js';

export type VerifiedExprEmitter=(
  expr:VerifiedIrExpr,
  brands:BrandMap,
  tags:TagMap,
)=>string;

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
  let candidate='__ps$match$'+index;
  while(used.has(candidate)){
    index+=1;
    candidate='__ps$match$'+index;
  }
  return candidate;
}

export function emitVerifiedMatch(
  expr:Extract<VerifiedIrExpr,{kind:'match'}>,
  brands:BrandMap,
  tags:TagMap,
  emit:VerifiedExprEmitter,
):string {
  const tag=tags.get(expr.inductive);
  if(tag===undefined){
    throw new Error(
      "PS_TS_UNKNOWN_MATCH_INDUCTIVE: '"+expr.inductive+"'",
    );
  }

  const temp=freshMatchTemp(expr);
  const cases=expr.alternatives.map((alternative)=>{
    const body=emit(alternative.body,brands,tags);
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
    emit(expr.scrutinee,brands,tags)+')';
}
