import type {ProofScriptFeatureId} from './features.js';
import {lex} from './lexer.js';
import {decideDCallOpen} from './d-call.js';
import {ParserError,TokenCursor,type OverlayDecision} from './parser-core.js';
import type {SourceSpan,Token} from './source.js';

export type DCallExpr =
  | {readonly kind:'atom';readonly token:Token;readonly span:SourceSpan}
  | {readonly kind:'group';readonly value:DCallExpr;readonly span:SourceSpan}
  | {readonly kind:'tuple';readonly items:readonly DCallExpr[];readonly span:SourceSpan}
  | {readonly kind:'call';readonly feature:'D-CALL';readonly fn:DCallExpr;readonly args:readonly DCallExpr[];readonly emptyArgumentList:boolean;readonly span:SourceSpan};

export interface LoweringResult {
  readonly leanText:string;
  readonly relation:'SyntaxEq'|'NormalizedSyntaxEq'|'ElabEq';
  readonly featureIds:readonly ProofScriptFeatureId[];
  readonly sourceMapStatus:'synthetic-only'|'diagnostic-mapped'|'proof-tracked';
}

interface ParseExprResult {readonly expr:DCallExpr;readonly hasOwnedCall:boolean}

class DCallParser {
  readonly cursor:TokenCursor;
  constructor(tokens:readonly Token[]){this.cursor=new TokenCursor(tokens);}

  parseExpression():ParseExprResult {
    let result=this.parseAtom();
    while(true){
      const decision=decideDCallOpen(this.cursor.peek());
      if(decision.kind==='defer')break;
      result={expr:this.parseCallSuffix(result.expr),hasOwnedCall:true};
    }
    return result;
  }

  private parseAtom():ParseExprResult {
    const token=this.cursor.peek();
    if(token.kind==='identifier'||token.kind==='number'||token.kind==='string'){
      this.cursor.consume();
      return {expr:{kind:'atom',token,span:token.span},hasOwnedCall:false};
    }
    if(token.text==='('){
      const open=this.cursor.consume();
      if(this.cursor.at(')'))throw new ParserError('PS_UNKNOWN_FEATURE','empty grouping is only valid as a D-CALL argument list, not as an expression',open.span);
      const first=this.parseExpression();
      const items:DCallExpr[]=[first.expr];
      let hasOwnedCall=first.hasOwnedCall;
      while(this.cursor.consumeIf(',')){
        const next=this.parseExpression();
        items.push(next.expr);hasOwnedCall ||= next.hasOwnedCall;
      }
      const close=this.cursor.expect(')');
      const span={start:open.span.start,end:close.span.end};
      return items.length===1
        ? {expr:{kind:'group',value:items[0]!,span},hasOwnedCall}
        : {expr:{kind:'tuple',items,span},hasOwnedCall};
    }
    throw new ParserError('PS_UNKNOWN_FEATURE',`D-CALL MVP cannot parse term starting with '${token.text}'`,token.span);
  }

  private parseCallSuffix(fn:DCallExpr):DCallExpr {
    const open=this.cursor.peek();
    if(decideDCallOpen(open).kind!=='proofscript')throw new Error('parseCallSuffix requires a D-CALL-owned opening parenthesis');
    this.cursor.consume();
    const args:DCallExpr[]=[];
    if(!this.cursor.at(')')){
      args.push(this.parseExpression().expr);
      while(this.cursor.consumeIf(','))args.push(this.parseExpression().expr);
    }
    const close=this.cursor.expect(')');
    return {kind:'call',feature:'D-CALL',fn,args,emptyArgumentList:args.length===0,span:{start:fn.span.start,end:close.span.end}};
  }
}

export function parseDCallOverlay(source:string):OverlayDecision<DCallExpr>{
  const parser=new DCallParser(lex(source));
  let parsed:ParseExprResult;
  try{parsed=parser.parseExpression();}
  catch(error){
    if(error instanceof ParserError&&parser.cursor.position===0)return {kind:'defer'};
    throw error;
  }
  if(!parsed.hasOwnedCall||!parser.cursor.done)return {kind:'defer'};
  return {kind:'proofscript',feature:'D-CALL',node:parsed.expr};
}

function lowerExpr(expr:DCallExpr,asArgument=false):string{
  switch(expr.kind){
    case 'atom':return expr.token.text;
    case 'group':return `(${lowerExpr(expr.value)})`;
    case 'tuple':return `(${expr.items.map(x=>lowerExpr(x)).join(', ')})`;
    case 'call':{
      const fn=lowerExpr(expr.fn);
      const body=expr.emptyArgumentList
        ? `${fn} ()`
        : `${fn} ${expr.args.map(x=>lowerExpr(x,true)).join(' ')}`;
      return asArgument?`(${body})`:body;
    }
  }
}

export function lowerDCall(node:DCallExpr):LoweringResult{
  const ids=new Set<ProofScriptFeatureId>();
  const visit=(x:DCallExpr):void=>{
    if(x.kind==='call'){ids.add('D-CALL');visit(x.fn);for(const arg of x.args)visit(arg);}
    else if(x.kind==='group')visit(x.value);
    else if(x.kind==='tuple')for(const item of x.items)visit(item);
  };
  visit(node);
  return {leanText:lowerExpr(node),relation:'SyntaxEq',featureIds:[...ids],sourceMapStatus:'synthetic-only'};
}

export function lowerDCallSource(source:string):OverlayDecision<LoweringResult>{
  const parsed=parseDCallOverlay(source);
  return parsed.kind==='defer'?parsed:{kind:'proofscript',feature:'D-CALL',node:lowerDCall(parsed.node)};
}
