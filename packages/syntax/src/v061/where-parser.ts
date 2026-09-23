import {SyntaxError,type SourceSpan} from '../source.js';
import type {V061WhereDeclaration} from './ast.js';
import {V061ParseContext} from './context.js';
import type {V061ExpressionParser} from './expression-parser.js';
import {parseV061ExplicitParameters} from './parameter-parser.js';
import {parseV061Type} from './type-parser.js';

export interface V061WhereBlock {
  readonly declarations:readonly V061WhereDeclaration[];
  readonly span:SourceSpan;
}

export function parseV061WhereBlock(
  context:V061ParseContext,
  expressions:V061ExpressionParser,
):V061WhereBlock {
  const first=context.cursor.expect('where');
  context.cursor.expect('{');
  context.own('E-WHERE-BODY');

  const declarations:V061WhereDeclaration[]=[];
  while(!context.cursor.at('}')){
    const name=context.cursor.expectKind('identifier','where declaration name');
    const params=context.cursor.at('(')?parseV061ExplicitParameters(context):[];
    context.cursor.expect(':');
    const resultType=parseV061Type(context);
    context.cursor.expect(':=');
    const body=expressions.parse();
    if(context.cursor.at('where')){
      throw new SyntaxError(
        'nested where blocks are not yet implemented by this parser milestone',
        context.cursor.peek().span,
      );
    }
    const semi=context.cursor.expect(';');
    context.own('D-DECL-SEMI');
    declarations.push({
      name:name.text,
      params,
      resultType,
      body,
      span:{start:name.span.start,end:semi.span.end},
    });
  }

  const close=context.cursor.expect('}');
  if(declarations.length===0){
    throw new SyntaxError('where body requires at least one local declaration',close.span);
  }
  return {
    declarations,
    span:{start:first.span.start,end:close.span.end},
  };
}
