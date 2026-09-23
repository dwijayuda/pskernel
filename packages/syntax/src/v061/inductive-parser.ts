import {SyntaxError} from '../source.js';
import type {
  V061InductiveConstructor,
  V061InductiveDeclaration,
  V061Parameter,
} from './ast.js';
import {V061ParseContext} from './context.js';
import {parseV061Type} from './type-parser.js';

function parseExplicitParameters(
  context:V061ParseContext,
):V061Parameter[] {
  const params:V061Parameter[]=[];
  const open=context.cursor.expect('(');
  context.own('D-EXPLICIT-PARAMS');

  if(context.cursor.at(')')){
    throw new SyntaxError(
      'explicit parameter list must contain at least one parameter',
      open.span,
    );
  }

  while(true){
    const name=context.cursor.expectKind('identifier','parameter name');
    context.cursor.expect(':');
    const type=parseV061Type(context);
    params.push({
      name:name.text,
      type,
      span:{start:name.span.start,end:type.span.end},
    });
    if(!context.cursor.consumeIf(','))break;
  }
  context.cursor.expect(')');
  return params;
}

function parseConstructor(
  context:V061ParseContext,
):V061InductiveConstructor {
  const bar=context.cursor.expect('|');
  const name=context.cursor.expectKind('identifier','constructor name');
  const params=context.cursor.at('(')?parseExplicitParameters(context):[];

  if(context.cursor.at(':')){
    throw new SyntaxError(
      'explicit constructor result types are not yet implemented by this parser milestone',
      context.cursor.peek().span,
    );
  }

  const semi=context.cursor.expect(';');
  return {
    name:name.text,
    params,
    span:{start:bar.span.start,end:semi.span.end},
  };
}

export function parseV061InductiveDeclaration(
  context:V061ParseContext,
):V061InductiveDeclaration {
  const first=context.cursor.expect('inductive');
  const name=context.cursor.expectKind('identifier','inductive name');
  const params=context.cursor.at('(')?parseExplicitParameters(context):[];
  const resultType=context.cursor.consumeIf(':')?parseV061Type(context):undefined;

  context.cursor.expect('where');
  context.cursor.expect('{');
  context.own('E-INDUCTIVE-BODY');

  const constructors:V061InductiveConstructor[]=[];
  while(!context.cursor.at('}')){
    constructors.push(parseConstructor(context));
  }
  const close=context.cursor.expect('}');
  if(constructors.length===0){
    throw new SyntaxError('inductive body requires at least one constructor',close.span);
  }

  const outerSemi=context.cursor.consumeIf(';');
  if(outerSemi)context.own('D-DECL-SEMI');

  return {
    kind:'inductive',
    name:name.text,
    params,
    ...(resultType===undefined?{}:{resultType}),
    constructors,
    terminatedBySemicolon:outerSemi!==undefined,
    span:{start:first.span.start,end:(outerSemi??close).span.end},
  };
}
