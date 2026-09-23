import type {ProofScriptFeatureId} from '../features.js';
import {lex} from '../lexer.js';
import {TokenCursor} from '../parser-core.js';
import type {SourceSpan,Token} from '../source.js';
import type {V061Expr} from './ast.js';

export type Spanned=Token|V061Expr;

export function spanBetween(first:Spanned,last:Spanned):SourceSpan {
  return {start:first.span.start,end:last.span.end};
}

export class V061ParseContext {
  readonly cursor:TokenCursor;
  readonly features=new Set<ProofScriptFeatureId>();

  constructor(source:string){
    this.cursor=new TokenCursor(lex(source));
  }

  own(feature:ProofScriptFeatureId):void{
    this.features.add(feature);
  }
}
