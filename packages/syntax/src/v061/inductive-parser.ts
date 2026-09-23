import {SyntaxError} from '../source.js';
import type {
  V061InductiveConstructor,
  V061InductiveDeclaration,
} from './ast.js';
import {V061ParseContext} from './context.js';
import {parseV061Type} from './type-parser.js';
import {parseV061ExplicitParameters} from './parameter-parser.js';

function parseConstructor(
  context:V061ParseContext,
):V061InductiveConstructor {
  const bar=context.cursor.expect('|');
  const name=context.cursor.expectKind('identifier','constructor name');
  const params=context.cursor.at('(')?parseV061ExplicitParameters(context):[];

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
  const params=context.cursor.at('(')?parseV061ExplicitParameters(context):[];
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
