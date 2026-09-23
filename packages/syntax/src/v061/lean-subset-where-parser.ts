import {SyntaxError,type Token} from '../source.js';
import type {
  V061WhereDeclaration,
} from './ast.js';
import {V061ParseContext} from './context.js';
import {V061LeanSubsetExpressionParser} from './lean-subset-expression-parser.js';
import {parseV061ParameterSequence} from './parameter-parser.js';
import {parseV061Type} from './type-parser.js';

const TOP_LEVEL_COMMANDS=new Set([
  'def','theorem','structure','class','instance','inductive',
]);

function requireExplicitParams(
  params:ReturnType<typeof parseV061ParameterSequence>['params'],
):void {
  const unsupported=params.find(
    (parameter)=>(parameter.binderInfo??'default')!=='default',
  );
  if(unsupported!==undefined){
    throw new SyntaxError(
      'PS_LEAN_SUBSET_WHERE_BINDER: canonical ProofScript where declarations '+
      'currently use explicit binders only',
      unsupported.span,
    );
  }
}

function syntheticEof(previous:Token):Token {
  return {
    kind:'eof',
    text:'<eof>',
    span:{start:previous.span.end,end:previous.span.end},
    leadingTrivia:[],
    adjacentToPrevious:true,
  };
}

function isTopLevelStart(token:Token):boolean {
  return token.span.start.column===1
    &&TOP_LEVEL_COMMANDS.has(token.text);
}

function isCanonicalWhereLocalStart(
  token:Token,
  bodyStartLine:number,
):boolean {
  return token.kind==='identifier'
    &&token.span.start.column===3
    &&token.span.start.line>bodyStartLine;
}

function findBodyEnd(
  context:V061ParseContext,
  start:number,
):number {
  const tokens=context.cursor.tokens;
  const first=tokens[start];
  if(first===undefined||first.kind==='eof')return start;
  for(let index=start+1;index<tokens.length;index+=1){
    const token=tokens[index]!;
    if(token.kind==='eof')return index;
    if(isTopLevelStart(token))return index;
    if(isCanonicalWhereLocalStart(token,first.span.start.line)){
      return index;
    }
  }
  return tokens.length-1;
}

function parseBoundedBody(
  context:V061ParseContext,
):ReturnType<V061LeanSubsetExpressionParser['parse']> {
  const start=context.cursor.position;
  const end=findBodyEnd(context,start);
  if(end<=start){
    throw new SyntaxError(
      'PS_LEAN_SUBSET_WHERE_BODY: expected local declaration body',
      context.cursor.peek().span,
    );
  }
  const slice=context.cursor.tokens.slice(start,end);
  const eof=syntheticEof(slice[slice.length-1]!);
  const subContext=new V061ParseContext(
    [...slice,eof],
    context.features,
  );
  const parser=new V061LeanSubsetExpressionParser(subContext);
  const body=parser.parse();
  if(!subContext.cursor.done){
    throw new SyntaxError(
      'PS_LEAN_SUBSET_WHERE_BODY: unsupported tokens in local declaration body',
      subContext.cursor.peek().span,
    );
  }
  for(let index=start;index<end;index+=1)context.cursor.consume();
  return body;
}

export function parseV061LeanSubsetWhereDeclarations(
  context:V061ParseContext,
):readonly V061WhereDeclaration[] {
  context.cursor.expect('where');
  const declarations:V061WhereDeclaration[]=[];
  while(
    !context.cursor.done
    &&!isTopLevelStart(context.cursor.peek())
  ){
    const name=context.cursor.expectKind(
      'identifier',
      'Lean where declaration name',
    );
    if(name.span.start.column!==3){
      throw new SyntaxError(
        'PS_LEAN_SUBSET_WHERE_LAYOUT: canonical where declarations must use '+
        'two-space indentation',
        name.span,
      );
    }
    const {params}=parseV061ParameterSequence(context);
    requireExplicitParams(params);
    context.cursor.expect(':');
    const resultType=parseV061Type(context);
    context.cursor.expect(':=');
    const body=parseBoundedBody(context);
    declarations.push({
      name:name.text,
      params,
      resultType,
      body,
      span:{start:name.span.start,end:body.span.end},
    });
  }
  if(declarations.length===0){
    throw new SyntaxError(
      'PS_LEAN_SUBSET_WHERE: where requires at least one local declaration',
      context.cursor.peek().span,
    );
  }
  return declarations;
}
