import {SyntaxError} from '../source.js';
import type {V061Expr,V061Tactic} from './ast.js';
import {V061ParseContext} from './context.js';
export interface V061TacticExpressionParser {
  parse(minPrecedence?:number):V061Expr;
}

const TACTIC_HEADS=new Set([
  'exact','exact?','assumption','apply','refine','constructor','cases','induction','rw','simp','intro',
]);

function isTacticHead(text:string):boolean {
  return TACTIC_HEADS.has(text);
}

function parseTactic(
  context:V061ParseContext,
  expressions:V061TacticExpressionParser,
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

  if(tacticToken.text==='exact?'){
    const token=context.cursor.consume();
    return {kind:'exactSearch',span:token.span};
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

  if(tacticToken.text==='rw'){
    const first=context.cursor.consume();
    context.cursor.expect('[');
    const symm=context.cursor.at('<-')||context.cursor.at('←');
    if(symm)context.cursor.consume();
    const proof=expressions.parse();
    const close=context.cursor.expect(']');
    return {
      kind:'rw',
      proof,
      symm,
      span:{start:first.span.start,end:close.span.end},
    };
  }

  if(tacticToken.text==='simp'){
    const first=context.cursor.consume();
    context.cursor.expect('only');
    context.cursor.expect('[');
    const rules:Extract<V061Tactic,{kind:'simp'}>['rules'][number][]=[];
    while(!context.cursor.at(']')){
      const ruleStart=context.cursor.peek().span.start;
      const symm=context.cursor.at('<-')||context.cursor.at('←');
      if(symm)context.cursor.consume();
      const proof=expressions.parse();
      rules.push({
        proof,
        symm,
        span:{start:ruleStart,end:proof.span.end},
      });
      if(!context.cursor.consumeIf(','))break;
    }
    if(rules.length===0){
      throw new SyntaxError(
        'bounded simp only requires at least one explicit rule',
        context.cursor.peek().span,
      );
    }
    const close=context.cursor.expect(']');
    return {
      kind:'simp',
      rules,
      span:{start:first.span.start,end:close.span.end},
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
    "kernel-facing tactic subset supports 'exact', bounded 'exact?', 'assumption', 'apply', 'refine', 'constructor', 'cases', 'induction', 'rw', 'simp only', and 'intro', got '"+
    tacticToken.text+"'",
    tacticToken.span,
  );
}

export function parseV061ByExpression(
  context:V061ParseContext,
  expressions:V061TacticExpressionParser,
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
