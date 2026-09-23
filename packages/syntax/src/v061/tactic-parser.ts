import {SyntaxError} from '../source.js';
import type {V061Expr,V061Tactic} from './ast.js';
import {V061ParseContext} from './context.js';
import type {V061ExpressionParser} from './expression-parser.js';

const TACTIC_HEADS=new Set([
  'exact','assumption','apply','refine','constructor','cases','induction','intro',
]);

function isTacticHead(text:string):boolean {
  return TACTIC_HEADS.has(text);
}

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

  if(tacticToken.text==='constructor'){
    const token=context.cursor.consume();
    return {kind:'constructor',span:token.span};
  }

  if(tacticToken.text==='cases'){
    const first=context.cursor.consume();
    const target=context.cursor.expectKind('identifier','cases target');
    return {
      kind:'cases',
      target:target.text,
      span:{start:first.span.start,end:target.span.end},
    };
  }

  if(tacticToken.text==='induction'){
    const first=context.cursor.consume();
    const target=context.cursor.expectKind('identifier','induction target');
    return {
      kind:'induction',
      target:target.text,
      span:{start:first.span.start,end:target.span.end},
    };
  }

  if(tacticToken.text==='apply'){
    const first=context.cursor.consume();
    const proof=expressions.parse();
    return {
      kind:'apply',
      proof,
      span:{start:first.span.start,end:proof.span.end},
    };
  }

  if(tacticToken.text==='refine'){
    const first=context.cursor.consume();
    const proof=expressions.parse();
    return {
      kind:'refine',
      proof,
      span:{start:first.span.start,end:proof.span.end},
    };
  }

  if(tacticToken.text==='intro'){
    const first=context.cursor.consume();
    const name=context.cursor.expectKind('identifier','intro name');
    return {
      kind:'intro',
      name:name.text,
      span:{start:first.span.start,end:name.span.end},
    };
  }

  throw new SyntaxError(
    "kernel-facing tactic subset supports 'exact', 'assumption', 'apply', 'refine', 'constructor', 'cases', 'induction', and 'intro', got '"+
    tacticToken.text+"'",
    tacticToken.span,
  );
}

export function parseV061ByExpression(
  context:V061ParseContext,
  expressions:V061ExpressionParser,
):V061Expr {
  const first=context.cursor.expect('by');
  const tactics:V061Tactic[]=[parseTactic(context,expressions)];

  while(
    context.cursor.at(';')
    &&isTacticHead(context.cursor.peek(1).text)
  ){
    context.cursor.consume();
    tactics.push(parseTactic(context,expressions));
  }

  const last=tactics[tactics.length-1]!;
  return {
    kind:'by',
    tactics,
    span:{start:first.span.start,end:last.span.end},
  };
}
