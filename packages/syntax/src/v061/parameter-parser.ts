import type {V061Parameter} from './ast.js';
import {V061ParseContext} from './context.js';
import {parseV061Type} from './type-parser.js';

export function parseV061ExplicitParameters(
  context:V061ParseContext,
):V061Parameter[] {
  const params:V061Parameter[]=[];
  const open=context.cursor.expect('(');
  context.own('D-EXPLICIT-PARAMS');

  if(context.cursor.at(')')){
    throw new Error(
      'D-EXPLICIT-PARAMS requires at least one explicit binding at offset '+
      open.span.start.offset,
    );
  }

  while(true){
    const name=context.cursor.expectKind('identifier','parameter name');
    context.cursor.expect(':');
    const type=parseV061Type(context);
    params.push({
      name:name.text,
      type,
      span:{start:name.span.start,end:type.span.end},
    });
    if(!context.cursor.consumeIf(','))break;
  }
  context.cursor.expect(')');
  return params;
}
