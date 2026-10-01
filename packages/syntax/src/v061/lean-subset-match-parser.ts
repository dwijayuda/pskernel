import {SyntaxError} from '../source.js';
import type {
  V061Expr,
  V061MatchAlternative,
} from './ast.js';
import {V061ParseContext} from './context.js';
import {parseV061Pattern} from './pattern-parser.js';

export type ParseLeanSubsetExpression=()=>V061Expr;

export function parseV061LeanSubsetMatch(
  context:V061ParseContext,
  parseExpression:ParseLeanSubsetExpression,
):V061Expr {
  const first=context.cursor.expect('match');
  const scrutinee=parseExpression();
  context.cursor.expect('with');
  const alternatives:V061MatchAlternative[]=[];
  while(context.cursor.at('|')){
    const bar=context.cursor.consume();
    const pattern=parseV061Pattern(context);
    context.cursor.expect('=>');
    const body=parseExpression();
    alternatives.push({
      pattern,
      body,
      span:{start:bar.span.start,end:body.span.end},
    });
  }
  if(alternatives.length===0){
    throw new SyntaxError(
      'PS_LEAN_SUBSET_MATCH: match requires at least one alternative',
      context.cursor.peek().span,
    );
  }
  return {
    kind:'match',
    scrutinee,
    alternatives,
    span:{
      start:first.span.start,
      end:alternatives[alternatives.length-1]!.span.end,
    },
  };
}
