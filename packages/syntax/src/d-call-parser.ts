import type {ProofScriptFeatureId} from './features.js';
import {lex} from './lexer.js';
import {decideDCallOpen} from './d-call.js';
import {ParserError,type OverlayDecision} from './parser-core.js';
import {
  TermParser,
  type ParsedTerm,
  type TermExpr,
  type TermPostfixExtension,
} from './term-parser.js';

export type DCallExpr = TermExpr;

export interface LoweringResult {
  readonly leanText:string;
  readonly relation:'SyntaxEq'|'NormalizedSyntaxEq'|'ElabEq';
  readonly featureIds:readonly ProofScriptFeatureId[];
  readonly sourceMapStatus:'synthetic-only'|'diagnostic-mapped'|'proof-tracked';
}

const dCallExtension:TermPostfixExtension={
  feature:'D-CALL',

  tryParse(parser:TermParser,current:ParsedTerm):ParsedTerm|undefined{
    const open=parser.cursor.peek();
    if(decideDCallOpen(open).kind!=='proofscript')return undefined;

    parser.cursor.consume();
    const args:TermExpr[]=[];
    const featureIds=new Set<ProofScriptFeatureId>(current.featureIds);
    featureIds.add('D-CALL');

    if(!parser.cursor.at(')')){
      const first=parser.parseExpression();
      args.push(first.expr);
      for(const feature of first.featureIds)featureIds.add(feature);

      while(parser.cursor.consumeIf(',')){
        const next=parser.parseExpression();
        args.push(next.expr);
        for(const feature of next.featureIds)featureIds.add(feature);
      }
    }

    const close=parser.cursor.expect(')');
    return {
      expr:{
        kind:'postfix',
        feature:'D-CALL',
        fn:current.expr,
        args,
        emptyArgumentList:args.length===0,
        span:{start:current.expr.span.start,end:close.span.end},
      },
      featureIds:[...featureIds],
    };
  },
};

export function parseDCallOverlay(source:string):OverlayDecision<DCallExpr>{
  const parser=new TermParser(lex(source),[dCallExtension]);
  let parsed:ParsedTerm;
  try{parsed=parser.parseExpression();}
  catch(error){
    if(error instanceof ParserError&&parser.cursor.position===0)return {kind:'defer'};
    throw error;
  }

  if(!parsed.featureIds.includes('D-CALL')||!parser.cursor.done)return {kind:'defer'};
  return {kind:'proofscript',feature:'D-CALL',node:parsed.expr};
}

function lowerExpr(expr:TermExpr,asArgument=false):string{
  switch(expr.kind){
    case 'atom':
      return expr.token.text;
    case 'group':
      return `(${lowerExpr(expr.value)})`;
    case 'tuple':
      return `(${expr.items.map(x=>lowerExpr(x)).join(', ')})`;
    case 'application':{
      const body=`${lowerExpr(expr.fn)} ${expr.args.map(x=>lowerExpr(x,true)).join(' ')}`;
      return asArgument?`(${body})`:body;
    }
    case 'postfix':{
      if(expr.feature!=='D-CALL'){
        throw new Error(`D-CALL lowering cannot lower postfix feature ${expr.feature}`);
      }
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

  const visit=(expr:TermExpr):void=>{
    if(expr.kind==='postfix'){
      ids.add(expr.feature);
      visit(expr.fn);
      for(const arg of expr.args)visit(arg);
    }else if(expr.kind==='application'){
      visit(expr.fn);
      for(const arg of expr.args)visit(arg);
    }else if(expr.kind==='group'){
      visit(expr.value);
    }else if(expr.kind==='tuple'){
      for(const item of expr.items)visit(item);
    }
  };

  visit(node);
  return {
    leanText:lowerExpr(node),
    relation:'SyntaxEq',
    featureIds:[...ids],
    sourceMapStatus:'synthetic-only',
  };
}

export function lowerDCallSource(source:string):OverlayDecision<LoweringResult>{
  const parsed=parseDCallOverlay(source);
  return parsed.kind==='defer'
    ? parsed
    : {kind:'proofscript',feature:'D-CALL',node:lowerDCall(parsed.node)};
}
