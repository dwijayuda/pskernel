import {SyntaxError,type SourceSpan,type Token} from '../source.js';
import {V061ParseContext,spanBetween} from './context.js';
import {v061BinaryPrecedence} from './operators.js';
import {startsV061DependentArrow} from './type-parser-lookahead.js';

export type V061TypeExpr =
  | {readonly kind:'nat';readonly text:string;readonly span:SourceSpan}
  | {readonly kind:'bool';readonly value:boolean;readonly span:SourceSpan}
  | {readonly kind:'named';readonly name:string;readonly span:SourceSpan}
  | {
      readonly kind:'application';
      readonly fn:V061TypeExpr;
      readonly args:readonly V061TypeExpr[];
      readonly span:SourceSpan;
    }
  | {
      readonly kind:'unary';
      readonly operator:'!';
      readonly operand:V061TypeExpr;
      readonly span:SourceSpan;
    }
  | {
      readonly kind:'binary';
      readonly operator:
        |'+'|'-'|'*'|'/'|'%'
        |'<'|'<='|'>'|'>='
        |'=='|'!='|'&&'|'||';
      readonly left:V061TypeExpr;
      readonly right:V061TypeExpr;
      readonly span:SourceSpan;
    }
  | {
      readonly kind:'equality';
      readonly left:V061TypeExpr;
      readonly right:V061TypeExpr;
      readonly span:SourceSpan;
    }
  | {
      readonly kind:'dependentArrow';
      readonly name:string;
      readonly domain:V061TypeExpr;
      readonly codomain:V061TypeExpr;
      readonly span:SourceSpan;
    }
  | {
      readonly kind:'arrow';
      readonly domain:V061TypeExpr;
      readonly codomain:V061TypeExpr;
      readonly span:SourceSpan;
    }
  | {
      readonly kind:'group';
      readonly value:V061TypeExpr;
      readonly ascribedType?:V061TypeExpr;
      readonly span:SourceSpan;
    };

export interface V061TypeParseOptions {
  readonly stopAtLineBreak?:boolean;
  readonly stopWords?:readonly string[];
}

const TYPE_APPLICATION_STOP_WORDS=new Set([
  'where','with','then','else','by',
]);

function crossesLineBoundary(
  current:V061TypeExpr,
  next:Token,
  options:V061TypeParseOptions,
):boolean {
  return options.stopAtLineBreak===true
    &&next.span.start.line>current.span.end.line;
}

export function parseV061Type(
  context:V061ParseContext,
  options:V061TypeParseOptions={},
):V061TypeExpr {
  if(startsV061DependentArrow(context)){
    const open=context.cursor.consume();
    const name=context.cursor.expectKind('identifier','dependent binder name');
    context.cursor.expect(':');
    const domain=parseV061Type(context,options);
    context.cursor.expect(')');
    if(!(context.cursor.at('->')||context.cursor.at('→'))){
      throw new SyntaxError(
        'dependent type binder requires -> or → after the binder',
        context.cursor.peek().span,
      );
    }
    context.cursor.consume();
    const codomain=parseV061Type(context,options);
    return {
      kind:'dependentArrow',
      name:name.text,
      domain,
      codomain,
      span:{start:open.span.start,end:codomain.span.end},
    };
  }

  const domain=parseEqualityType(context,options);
  if(
    (context.cursor.at('->')||context.cursor.at('→'))
    &&!crossesLineBoundary(domain,context.cursor.peek(),options)
  ){
    context.cursor.consume();
    const codomain=parseV061Type(context,options);
    return {
      kind:'arrow',
      domain,
      codomain,
      span:{start:domain.span.start,end:codomain.span.end},
    };
  }
  return domain;
}

const TYPE_TERM_BINARY_OPERATORS=new Set([
  '+','-','*','/','%','<','<=','>','>=','==','!=','&&','||',
]);

function parseTypeTermBinary(
  context:V061ParseContext,
  minPrecedence=0,
  options:V061TypeParseOptions={},
):V061TypeExpr {
  let left=parsePrefixType(context,options);
  while(true){
    const token=context.cursor.peek();
    if(crossesLineBoundary(left,token,options))break;
    if(!TYPE_TERM_BINARY_OPERATORS.has(token.text))break;
    const precedence=v061BinaryPrecedence(token.text);
    if(precedence===undefined||precedence<minPrecedence)break;
    context.cursor.consume();
    const right=parseTypeTermBinary(context,precedence+1,options);
    left={
      kind:'binary',
      operator:token.text as
        |'+'|'-'|'*'|'/'|'%'
        |'<'|'<='|'>'|'>='
        |'=='|'!='|'&&'|'||',
      left,
      right,
      span:spanBetween(left,right),
    };
  }
  return left;
}

function parseEqualityType(
  context:V061ParseContext,
  options:V061TypeParseOptions,
):V061TypeExpr {
  const left=parseTypeTermBinary(context,0,options);
  if(
    !context.cursor.at('=')
    ||crossesLineBoundary(left,context.cursor.peek(),options)
  )return left;
  context.cursor.consume();
  const right=parseTypeTermBinary(context,0,options);
  if(context.cursor.at('=')){
    throw new SyntaxError(
      'propositional equality is non-associative; parenthesize nested equality',
      context.cursor.peek().span,
    );
  }
  return {
    kind:'equality',
    left,
    right,
    span:{start:left.span.start,end:right.span.end},
  };
}

function parsePrefixType(
  context:V061ParseContext,
  options:V061TypeParseOptions,
):V061TypeExpr {
  if(context.cursor.at('!')){
    const first=context.cursor.consume();
    const operand=parsePrefixType(context,options);
    return {
      kind:'unary',
      operator:'!',
      operand,
      span:spanBetween(first,operand),
    };
  }
  return parseApplicationType(context,options);
}

function canStartAtomicType(
  token:Token,
  options:V061TypeParseOptions,
):boolean {
  if(TYPE_APPLICATION_STOP_WORDS.has(token.text))return false;
  if(options.stopWords?.includes(token.text)===true)return false;
  return token.kind==='identifier'||token.kind==='number'||token.text==='(';
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

function parseApplicationType(
  context:V061ParseContext,
  options:V061TypeParseOptions,
):V061TypeExpr {
  let current=parseAtomicType(context,options);

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
        args.push(parseV061Type(context,options));
        if(!context.cursor.consumeIf(','))break;
      }
      context.cursor.expect(')');
      current=appendApplication(current,args);
      continue;
    }

    if(
      canStartAtomicType(next,options)
      &&next.leadingTrivia.length>0
      &&!crossesLineBoundary(current,next,options)
    ){
      const arg=parseAtomicType(context,options);
      current=appendApplication(current,[arg]);
      continue;
    }
    break;
  }
  return current;
}

function parseAtomicType(
  context:V061ParseContext,
  options:V061TypeParseOptions,
):V061TypeExpr {
  const token=context.cursor.peek();
  if(token.kind==='number'){
    context.cursor.consume();
    return {kind:'nat',text:token.text,span:token.span};
  }
  if(token.text==='true'||token.text==='false'){
    context.cursor.consume();
    return {kind:'bool',value:token.text==='true',span:token.span};
  }
  if(token.kind==='identifier'){
    context.cursor.consume();
    return {kind:'named',name:token.text,span:token.span};
  }
  if(token.text==='('){
    const open=context.cursor.consume();
    const value=parseV061Type(context,options);
    const ascribedType=context.cursor.consumeIf(':')
      ?parseV061Type(context,options)
      :undefined;
    const close=context.cursor.expect(')');
    return {
      kind:'group',
      value,
      ...(ascribedType===undefined?{}:{ascribedType}),
      span:{start:open.span.start,end:close.span.end},
    };
  }
  throw new SyntaxError("expected type, got '"+token.text+"'",token.span);
}
