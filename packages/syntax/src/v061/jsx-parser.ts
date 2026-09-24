import {SyntaxError} from '../source.js';
import type {SourcePosition,SourceSpan,Token} from '../source.js';
import type {V061Expr} from './ast.js';
import type {V061ParseContext} from './context.js';

const INTERNAL_ELEMENT='$psx.element';
const INTERNAL_FRAGMENT='$psx.fragment';
const INTERNAL_ATTR='$psx.attr';
const INTERNAL_TEXT='$psx.text';
const INTERNAL_CHILD='$psx.child';

interface ExpressionParserLike {
  parse(minPrecedence?:number):V061Expr;
}

function stringExpr(value:string,span:SourceSpan):V061Expr {
  return {kind:'string',value,span};
}

function internalCall(
  callee:string,
  args:readonly V061Expr[],
  span:SourceSpan,
):V061Expr {
  return {kind:'call',callee,args,span};
}

function jsxText(
  context:V061ParseContext,
  start:SourcePosition,
  end:SourcePosition,
):V061Expr|undefined {
  if(end.offset<=start.offset)return undefined;
  const source=context.sourceText;
  if(source===undefined){
    throw new Error(
      'PS_JSX_SOURCE_REQUIRED: JSX parsing requires original source text',
    );
  }
  const value=source.slice(start.offset,end.offset);
  if(value.length===0)return undefined;
  const span={start,end};
  return internalCall(
    INTERNAL_TEXT,
    [stringExpr(value,span)],
    span,
  );
}

function isComponentTag(tag:string):boolean {
  const first=Array.from(tag)[0]??'';
  return first.toLocaleUpperCase()===first
    &&first.toLocaleLowerCase()!==first;
}

function parseAttributeValue(
  context:V061ParseContext,
  expressions:ExpressionParserLike,
):V061Expr {
  const token=context.cursor.peek();
  if(token.kind==='string'){
    context.cursor.consume();
    return stringExpr(token.value??'',token.span);
  }
  if(token.text==='{'){
    context.cursor.consume();
    const value=expressions.parse();
    context.cursor.expect('}');
    return value;
  }
  throw new SyntaxError(
    "PS_JSX_ATTRIBUTE_VALUE: expected string or '{expression}', got '"+
      token.text+"'",
    token.span,
  );
}

function parseAttributes(
  context:V061ParseContext,
  expressions:ExpressionParserLike,
):V061Expr[] {
  const out:V061Expr[]=[];
  while(
    !context.cursor.at('>')
    &&!(
      context.cursor.at('/')
      &&context.cursor.peek(1).text==='>'
    )
  ){
    const name=context.cursor.expectKind('identifier','JSX attribute name');
    if(!context.cursor.consumeIf('=')){
      throw new SyntaxError(
        "PS_JSX_ATTRIBUTE_VALUE: JSX attribute '"+name.text+
          "' requires an explicit value in PSX1",
        context.cursor.peek().span,
      );
    }
    const value=parseAttributeValue(context,expressions);
    out.push(internalCall(
      INTERNAL_ATTR,
      [stringExpr(name.text,name.span),value],
      {start:name.span.start,end:value.span.end},
    ));
  }
  return out;
}

function atClosingTag(context:V061ParseContext):boolean {
  return context.cursor.at('<')&&context.cursor.peek(1).text==='/';
}

function parseChildren(
  context:V061ParseContext,
  expressions:ExpressionParserLike,
  contentStart:SourcePosition,
):{readonly children:readonly V061Expr[];readonly closeStart:Token} {
  const children:V061Expr[]=[];
  let rawStart=contentStart;
  while(!context.cursor.done){
    const token=context.cursor.peek();
    if(atClosingTag(context)){
      const text=jsxText(context,rawStart,token.span.start);
      if(text!==undefined)children.push(text);
      return {children,closeStart:token};
    }
    if(token.text==='<'){
      const text=jsxText(context,rawStart,token.span.start);
      if(text!==undefined)children.push(text);
      const nested=parseV061JsxExpression(context,expressions);
      children.push(nested);
      rawStart=nested.span.end;
      continue;
    }
    if(token.text==='{'){
      const text=jsxText(context,rawStart,token.span.start);
      if(text!==undefined)children.push(text);
      const open=context.cursor.consume();
      const value=expressions.parse();
      const close=context.cursor.expect('}');
      children.push(internalCall(
        INTERNAL_CHILD,
        [value],
        {start:open.span.start,end:close.span.end},
      ));
      rawStart=close.span.end;
      continue;
    }
    context.cursor.consume();
  }
  throw new SyntaxError(
    'PS_JSX_UNCLOSED: expected a closing JSX tag',
    context.cursor.peek().span,
  );
}

function expectMatchingClose(
  context:V061ParseContext,
  expected:string|undefined,
):Token {
  context.cursor.expect('<');
  context.cursor.expect('/');
  if(expected===undefined){
    return context.cursor.expect('>');
  }
  const actual=context.cursor.expectKind('identifier','closing JSX tag');
  if(actual.text!==expected){
    throw new SyntaxError(
      "PS_JSX_CLOSE_MISMATCH: expected closing tag '</"+expected+
        ">', got '</"+actual.text+">'",
      actual.span,
    );
  }
  return context.cursor.expect('>');
}

export function isInternalPsxCall(expr:V061Expr):boolean {
  return expr.kind==='call'&&expr.callee.startsWith('$psx.');
}

export function parseV061JsxExpression(
  context:V061ParseContext,
  expressions:ExpressionParserLike,
):V061Expr {
  if(!context.jsxEnabled){
    throw new SyntaxError(
      'PS_JSX_DISABLED: JSX syntax is available only in .psx files',
      context.cursor.peek().span,
    );
  }
  context.own('E-JSX');
  const open=context.cursor.expect('<');

  if(context.cursor.at('>')){
    const openEnd=context.cursor.consume();
    const parsed=parseChildren(context,expressions,openEnd.span.end);
    const close=expectMatchingClose(context,undefined);
    return internalCall(
      INTERNAL_FRAGMENT,
      parsed.children,
      {start:open.span.start,end:close.span.end},
    );
  }

  const tag=context.cursor.expectKind('identifier','JSX tag name');
  const attrs=parseAttributes(context,expressions);
  if(context.cursor.at('/')&&context.cursor.peek(1).text==='>'){
    context.cursor.consume();
    const close=context.cursor.expect('>');
    return internalCall(
      INTERNAL_ELEMENT,
      [
        stringExpr(tag.text,tag.span),
        stringExpr(isComponentTag(tag.text)?'component':'intrinsic',tag.span),
        ...attrs,
      ],
      {start:open.span.start,end:close.span.end},
    );
  }

  const openEnd=context.cursor.expect('>');
  const parsed=parseChildren(context,expressions,openEnd.span.end);
  const close=expectMatchingClose(context,tag.text);
  return internalCall(
    INTERNAL_ELEMENT,
    [
      stringExpr(tag.text,tag.span),
      stringExpr(isComponentTag(tag.text)?'component':'intrinsic',tag.span),
      ...attrs,
      ...parsed.children,
    ],
    {start:open.span.start,end:close.span.end},
  );
}
