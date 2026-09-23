import {SyntaxError} from '../source.js';
import type {V061Expr,V061Tactic} from './ast.js';
import {V061ParseContext} from './context.js';
import type {V061ExpressionParser} from './expression-parser.js';

function parseTactic(
  context:V061ParseContext,
  expressions:V061ExpressionParser,
):V061Tactic {
  const tacticToken=context.cursor.peek();

  if(tacticToken.text==='exact'){
    context.cursor.consume();
    const proof=expressions.parse();
    return {
      kind:'exact',
      proof,
      span:{start:tacticToken.span.start,end:proof.span.end},
    };
  }

  if(tacticToken.text==='assumption'){
    const token=context.cursor.consume();
    return {kind:'assumption',span:token.span};
  }

  if(tacticToken.text==='intro'){
    const first=context.cursor.consume();
    const name=context.cursor.expectKind('identifier','intro name');
    context.cursor.expect(';');
    const next=parseTactic(context,expressions);
    return {
      kind:'intro',
      name:name.text,
      next,
      span:{start:first.span.start,end:next.span.end},
    };
  }

  throw new SyntaxError(
    "kernel-facing tactic subset supports 'exact', 'assumption', and 'intro', got '"+
    tacticToken.text+"'",
    tacticToken.span,
  );
}

export function parseV061ByExpression(
  context:V061ParseContext,
  expressions:V061ExpressionParser,
):V061Expr {
  const first=context.cursor.expect('by');
  const tactic=parseTactic(context,expressions);
  return {
    kind:'by',
    tactic,
    span:{start:first.span.start,end:tactic.span.end},
  };
}
