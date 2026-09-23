import {SyntaxError} from '../source.js';
import type {
  V061ExpressionParser,
} from './expression-parser.js';
import type {V061InstanceDeclaration} from './ast.js';
import {V061ParseContext} from './context.js';
import {parseV061ParameterSequence} from './parameter-parser.js';
import {parseV061Type} from './type-parser.js';

export function parseV061InstanceDeclaration(
  context:V061ParseContext,
  expressions:V061ExpressionParser,
):V061InstanceDeclaration {
  const first=context.cursor.expect('instance');
  const nameToken=context.cursor.atKind('identifier')
    ?context.cursor.consume()
    :undefined;
  const anonymous=nameToken===undefined;
  const name=nameToken?.text??'__ps_inst_'+first.span.start.offset;
  const params=parseV061ParameterSequence(context);

  context.cursor.expect(':');
  const resultType=parseV061Type(context);
  context.cursor.expect(':=');
  const body=expressions.parse();
  const semi=context.cursor.consumeIf(';');
  if(semi)context.own('D-DECL-SEMI');
  if(!semi&&!context.cursor.done){
    throw new SyntaxError(
      "expected ';' between ProofScript declarations",
      context.cursor.peek().span,
    );
  }

  return {
    kind:'instance',
    name,
    anonymous,
    params:params.params,
    resultType,
    body,
    terminatedBySemicolon:semi!==undefined,
    span:{
      start:first.span.start,
      end:semi?.span.end??body.span.end,
    },
  };
}
