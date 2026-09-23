import {SyntaxError,type SourceSpan} from '../source.js';
import {V061ParseContext} from './context.js';

export type V061TypeExpr =
  | {readonly kind:'named';readonly name:string;readonly span:SourceSpan}
  | {readonly kind:'arrow';readonly domain:V061TypeExpr;readonly codomain:V061TypeExpr;readonly span:SourceSpan}
  | {readonly kind:'group';readonly value:V061TypeExpr;readonly span:SourceSpan};

export function parseV061Type(context:V061ParseContext):V061TypeExpr {
  const domain=parseAtomicType(context);
  if(context.cursor.at('->')||context.cursor.at('→')){
    context.cursor.consume();
    const codomain=parseV061Type(context);
    return {kind:'arrow',domain,codomain,span:{start:domain.span.start,end:codomain.span.end}};
  }
  return domain;
}

function parseAtomicType(context:V061ParseContext):V061TypeExpr {
  const token=context.cursor.peek();
  if(token.kind==='identifier'){
    context.cursor.consume();
    return {kind:'named',name:token.text,span:token.span};
  }
  if(token.text==='('){
    const open=context.cursor.consume();
    const value=parseV061Type(context);
    const close=context.cursor.expect(')');
    return {kind:'group',value,span:{start:open.span.start,end:close.span.end}};
  }
  throw new SyntaxError("expected type, got '"+token.text+"'",token.span);
}

export function lowerV061TypeToLean(type:V061TypeExpr,parentPrecedence=0):string {
  switch(type.kind){
    case 'named':return type.name;
    case 'group':return '('+lowerV061TypeToLean(type.value)+')';
    case 'arrow':{
      const precedence=25;
      const rendered=lowerV061TypeToLean(type.domain,precedence+1)+' -> '+lowerV061TypeToLean(type.codomain,precedence);
      return precedence<parentPrecedence?'('+rendered+')':rendered;
    }
  }
}
