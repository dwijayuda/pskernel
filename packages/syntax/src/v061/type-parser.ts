import {SyntaxError,type SourceSpan,type Token} from '../source.js';
import {V061ParseContext} from './context.js';

export type V061TypeExpr =
  | {readonly kind:'named';readonly name:string;readonly span:SourceSpan}
  | {
      readonly kind:'application';
      readonly fn:V061TypeExpr;
      readonly args:readonly V061TypeExpr[];
      readonly span:SourceSpan;
    }
  | {
      readonly kind:'arrow';
      readonly domain:V061TypeExpr;
      readonly codomain:V061TypeExpr;
      readonly span:SourceSpan;
    }
  | {readonly kind:'group';readonly value:V061TypeExpr;readonly span:SourceSpan};

export function parseV061Type(context:V061ParseContext):V061TypeExpr {
  const domain=parseApplicationType(context);
  if(context.cursor.at('->')||context.cursor.at('→')){
    context.cursor.consume();
    const codomain=parseV061Type(context);
    return {
      kind:'arrow',
      domain,
      codomain,
      span:{start:domain.span.start,end:codomain.span.end},
    };
  }
  return domain;
}

function canStartAtomicType(token:Token):boolean {
  return token.kind==='identifier'||token.text==='(';
}

function appendApplication(
  fn:V061TypeExpr,
  args:readonly V061TypeExpr[],
):V061TypeExpr {
  const allArgs=fn.kind==='application'?[...fn.args,...args]:[...args];
  const root=fn.kind==='application'?fn.fn:fn;
  const last=allArgs[allArgs.length-1]!;
  return {
    kind:'application',
    fn:root,
    args:allArgs,
    span:{start:root.span.start,end:last.span.end},
  };
}

function parseApplicationType(context:V061ParseContext):V061TypeExpr {
  let current=parseAtomicType(context);

  while(true){
    const next=context.cursor.peek();
    if(next.text==='('&&next.adjacentToPrevious){
      context.own('D-CALL');
      context.cursor.consume();
      if(context.cursor.at(')')){
        throw new SyntaxError(
          'empty decorated application is not supported in type syntax',
          context.cursor.peek().span,
        );
      }
      const args:V061TypeExpr[]=[];
      while(true){
        args.push(parseV061Type(context));
        if(!context.cursor.consumeIf(','))break;
      }
      context.cursor.expect(')');
      current=appendApplication(current,args);
      continue;
    }

    if(canStartAtomicType(next)&&next.leadingTrivia.length>0){
      const arg=parseAtomicType(context);
      current=appendApplication(current,[arg]);
      continue;
    }
    break;
  }
  return current;
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
    return {
      kind:'group',
      value,
      span:{start:open.span.start,end:close.span.end},
    };
  }
  throw new SyntaxError("expected type, got '"+token.text+"'",token.span);
}

export function lowerV061TypeToLean(
  type:V061TypeExpr,
  parentPrecedence=0,
):string {
  switch(type.kind){
    case 'named':
      return type.name;
    case 'group':
      return '('+lowerV061TypeToLean(type.value)+')';
    case 'application':{
      const precedence=70;
      const rendered=lowerV061TypeToLean(type.fn,precedence)+' '+
        type.args.map((arg)=>lowerV061TypeToLean(arg,precedence+1)).join(' ');
      return precedence<parentPrecedence?'('+rendered+')':rendered;
    }
    case 'arrow':{
      const precedence=25;
      const rendered=lowerV061TypeToLean(type.domain,precedence+1)+' -> '+
        lowerV061TypeToLean(type.codomain,precedence);
      return precedence<parentPrecedence?'('+rendered+')':rendered;
    }
  }
}
