import type {ProofScriptFeatureId} from './features.js';
import {SyntaxError,type SourceSpan,type Token} from './source.js';

export type OverlayDecision<T> =
  | {readonly kind:'proofscript';readonly feature:ProofScriptFeatureId;readonly node:T}
  | {readonly kind:'defer'};

export type ProofScriptErrorCode =
  | 'PS_UNKNOWN_FEATURE'
  | 'PS_UNREGISTERED_EXCEPTION'
  | 'PS_AMBIGUOUS_OWNERSHIP'
  | 'PS_CONST_WITH_PARAMS'
  | 'PS_FUNCTION_WITHOUT_PARAMS'
  | 'PS_IF_REQUIRES_PARENS'
  | 'PS_BRANCH_REQUIRES_SINGLE_TERM'
  | 'PS_PATTERN_CALL_SYNTAX_NOT_ADMITTED'
  | 'PS_VERSION_MISMATCH';

export class ParserError extends SyntaxError {
  constructor(readonly code:ProofScriptErrorCode,message:string,span:SourceSpan){
    super(message,span);
    this.name='ProofScriptParserError';
  }
}

export function spanFromTokens(first:Token,last:Token):SourceSpan {
  return {start:first.span.start,end:last.span.end};
}

export class TokenCursor {
  private index=0;
  constructor(readonly tokens:readonly Token[]) {
    if(tokens.length===0||tokens[tokens.length-1]?.kind!=='eof') throw new Error('TokenCursor requires an eof-terminated token stream');
  }
  get position():number{return this.index;}
  get done():boolean{return this.peek().kind==='eof';}
  peek(offset=0):Token{return this.tokens[Math.min(this.index+offset,this.tokens.length-1)]!;}
  at(text:string):boolean{return this.peek().text===text;}
  atKind(kind:Token['kind']):boolean{return this.peek().kind===kind;}
  mark():number{return this.index;}
  reset(mark:number):void{
    if(!Number.isSafeInteger(mark)||mark<0||mark>=this.tokens.length)throw new RangeError('invalid token cursor mark');
    this.index=mark;
  }
  consume():Token{const token=this.peek();if(token.kind!=='eof')this.index+=1;return token;}
  consumeIf(text:string):Token|undefined{return this.at(text)?this.consume():undefined;}
  expect(text:string):Token{
    const token=this.peek();
    if(token.text!==text)throw new SyntaxError(`expected '${text}', got '${token.text}'`,token.span);
    return this.consume();
  }
  expectKind(kind:Token['kind'],label=kind):Token{
    const token=this.peek();
    if(token.kind!==kind)throw new SyntaxError(`expected ${label}, got '${token.text}'`,token.span);
    return this.consume();
  }
}
