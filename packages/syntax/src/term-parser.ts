import type {ProofScriptFeatureId} from './features.js';
import {ParserError,TokenCursor} from './parser-core.js';
import type {SourceSpan,Token} from './source.js';
import {lex} from './lexer.js';

export type TermExpr =
  | {readonly kind:'atom';readonly token:Token;readonly span:SourceSpan}
  | {readonly kind:'group';readonly value:TermExpr;readonly span:SourceSpan}
  | {readonly kind:'tuple';readonly items:readonly TermExpr[];readonly span:SourceSpan}
  | {readonly kind:'application';readonly fn:TermExpr;readonly args:readonly TermExpr[];readonly span:SourceSpan}
  | {readonly kind:'ascription';readonly value:TermExpr;readonly type?:TermExpr;readonly span:SourceSpan}
  | {
      readonly kind:'postfix';
      readonly feature:ProofScriptFeatureId;
      readonly fn:TermExpr;
      readonly args:readonly TermExpr[];
      readonly emptyArgumentList:boolean;
      readonly span:SourceSpan;
    };

export interface ParsedTerm {
  readonly expr:TermExpr;
  readonly featureIds:readonly ProofScriptFeatureId[];
}

export interface TermPostfixExtension {
  readonly feature:ProofScriptFeatureId;
  tryParse(parser:TermParser,current:ParsedTerm):ParsedTerm|undefined;
}

function mergeFeatureIds(...groups:readonly (readonly ProofScriptFeatureId[])[]):ProofScriptFeatureId[]{
  const out=new Set<ProofScriptFeatureId>();
  for(const group of groups)for(const feature of group)out.add(feature);
  return [...out];
}

export class TermParser {
  readonly cursor:TokenCursor;

  constructor(
    tokens:readonly Token[],
    readonly postfixExtensions:readonly TermPostfixExtension[]=[],
  ){
    this.cursor=new TokenCursor(tokens);
  }

  parseExpression():ParsedTerm {
    return this.parseApplication();
  }

  parseWhole():ParsedTerm {
    const parsed=this.parseExpression();
    if(!this.cursor.done){
      const token=this.cursor.peek();
      throw new ParserError('PS_UNKNOWN_FEATURE',`term subset stopped before '${token.text}'`,token.span);
    }
    return parsed;
  }

  private parseApplication():ParsedTerm {
    const head=this.parsePostfix();
    const args:TermExpr[]=[];
    const featureGroups:(readonly ProofScriptFeatureId[])[]=[head.featureIds];

    while(this.startsApplicationArgument(this.cursor.peek())){
      const arg=this.parsePostfix();
      args.push(arg.expr);
      featureGroups.push(arg.featureIds);
    }

    if(args.length===0)return head;
    return {
      expr:{
        kind:'application',
        fn:head.expr,
        args,
        span:{start:head.expr.span.start,end:args[args.length-1]!.span.end},
      },
      featureIds:mergeFeatureIds(...featureGroups),
    };
  }

  private startsApplicationArgument(token:Token):boolean {
    if(token.leadingTrivia.length===0)return false;
    return token.kind==='identifier'||token.kind==='number'||token.kind==='string'||token.text==='(';
  }

  private parsePostfix():ParsedTerm {
    let result=this.parseAtom();

    while(true){
      let next:ParsedTerm|undefined;
      for(const extension of this.postfixExtensions){
        const mark=this.cursor.mark();
        const candidate=extension.tryParse(this,result);
        if(candidate){
          if(this.cursor.position===mark){
            throw new Error(`postfix extension ${extension.feature} returned a node without consuming input`);
          }
          next=candidate;
          break;
        }
        if(this.cursor.position!==mark){
          throw new Error(`postfix extension ${extension.feature} consumed input before deferring`);
        }
      }
      if(!next)return result;
      result=next;
    }
  }

  private parseAtom():ParsedTerm {
    const token=this.cursor.peek();
    if(token.kind==='identifier'||token.kind==='number'||token.kind==='string'){
      this.cursor.consume();
      return {expr:{kind:'atom',token,span:token.span},featureIds:[]};
    }

    if(token.text==='('){
      const open=this.cursor.consume();
      if(this.cursor.at(')')){
        throw new ParserError(
          'PS_UNKNOWN_FEATURE',
          'empty grouping is not a term in the inherited parser subset',
          open.span,
        );
      }

      const first=this.parseExpression();

      if(this.cursor.consumeIf(':')){
        const typeTerm=this.cursor.at(')')?undefined:this.parseExpression();
        const close=this.cursor.expect(')');
        const span={start:open.span.start,end:close.span.end};
        return {
          expr:typeTerm
            ? {kind:'ascription',value:first.expr,type:typeTerm.expr,span}
            : {kind:'ascription',value:first.expr,span},
          featureIds:typeTerm
            ? mergeFeatureIds(first.featureIds,typeTerm.featureIds)
            : [...first.featureIds],
        };
      }

      const items:TermExpr[]=[first.expr];
      const featureGroups:(readonly ProofScriptFeatureId[])[]=[first.featureIds];

      while(this.cursor.consumeIf(',')){
        const next=this.parseExpression();
        items.push(next.expr);
        featureGroups.push(next.featureIds);
      }

      const close=this.cursor.expect(')');
      const span={start:open.span.start,end:close.span.end};
      return {
        expr:items.length===1
          ? {kind:'group',value:items[0]!,span}
          : {kind:'tuple',items,span},
        featureIds:mergeFeatureIds(...featureGroups),
      };
    }

    throw new ParserError(
      'PS_UNKNOWN_FEATURE',
      `inherited term subset cannot parse term starting with '${token.text}'`,
      token.span,
    );
  }
}

export function parseTermSubset(source:string):TermExpr {
  return new TermParser(lex(source)).parseWhole().expr;
}
