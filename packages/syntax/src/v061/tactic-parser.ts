import {SyntaxError} from '../source.js';
import type {V061Expr,V061Tactic} from './ast.js';
import {V061ParseContext} from './context.js';
import type {V061ExpressionParser} from './expression-parser.js';

export function parseV061ByExpression(
  context:V061ParseContext,
  expressions:V061ExpressionParser,
):V061Expr {
  const first=context.cursor.expect('by');
  const tacticToken=context.cursor.peek();
  let tactic:V061Tactic;

  if(tacticToken.text==='exact'){
    context.cursor.consume();
    const proof=expressions.parse();
    tactic={
      kind:'exact',
      proof,
      span:{start:tacticToken.span.start,end:proof.span.end},
    };
  }else if(tacticToken.text==='assumption'){
    const token=context.cursor.consume();
    tactic={kind:'assumption',span:token.span};
  }else{
    throw new SyntaxError(
      "kernel-facing tactic subset supports only 'exact' and 'assumption', got '"+
      tacticToken.text+"'",
      tacticToken.span,
    );
  }

  return {
    kind:'by',
    tactic,
    span:{start:first.span.start,end:tactic.span.end},
  };
}
