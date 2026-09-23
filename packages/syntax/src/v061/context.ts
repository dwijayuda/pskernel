import type {ProofScriptFeatureId} from '../features.js';
import {lex} from '../lexer.js';
import {TokenCursor} from '../parser-core.js';
import type {SourceSpan,Token} from '../source.js';
export interface Spanned {readonly span:SourceSpan}

export function spanBetween(first:Spanned,last:Spanned):SourceSpan {
  return {start:first.span.start,end:last.span.end};
}

export class V061ParseContext {
  readonly cursor:TokenCursor;
  readonly features:Set<ProofScriptFeatureId>;

  constructor(
    sourceOrTokens:string|readonly Token[],
    features?:Set<ProofScriptFeatureId>,
  ){
    this.cursor=new TokenCursor(
      typeof sourceOrTokens==='string'
        ?lex(sourceOrTokens)
        :sourceOrTokens,
    );
    this.features=features??new Set<ProofScriptFeatureId>();
  }

  own(feature:ProofScriptFeatureId):void{
    this.features.add(feature);
  }
}
