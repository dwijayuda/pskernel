import {SyntaxError} from '../source.js';
import type {V061Expr,V061RecordField} from './ast.js';
import {V061ParseContext} from './context.js';
import {parseV061Type} from './type-parser.js';

export type ParseV061Expression=()=>V061Expr;

export function parseV061RecordExpression(
  context:V061ParseContext,
  parseExpression:ParseV061Expression,
):V061Expr {
  const open=context.cursor.expect('{');
  if(context.cursor.at('}')){
    throw new SyntaxError('record value requires at least one field',context.cursor.peek().span);
  }

  const fields:V061RecordField[]=[];
  while(true){
    const name=context.cursor.expectKind('identifier','record field name');
    context.cursor.expect(':=');
    const value=parseExpression();
    fields.push({
      name:name.text,
      value,
      span:{start:name.span.start,end:value.span.end},
    });
    if(!context.cursor.consumeIf(','))break;
  }

  context.cursor.expect(':');
  const type=parseV061Type(context);
  const close=context.cursor.expect('}');
  return {
    kind:'record',
    fields,
    type,
    span:{start:open.span.start,end:close.span.end},
  };
}
