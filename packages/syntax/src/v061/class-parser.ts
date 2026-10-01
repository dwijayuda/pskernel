import type {V061ClassDeclaration} from './ast.js';
import {V061ParseContext} from './context.js';
import {parseV061FieldBody} from './field-parser.js';
import {parseV061ExplicitParameters} from './parameter-parser.js';

export function parseV061ClassDeclaration(
  context:V061ParseContext,
):V061ClassDeclaration {
  const first=context.cursor.expect('class');
  const name=context.cursor.expectKind('identifier','class name');
  const params=context.cursor.at('(')?parseV061ExplicitParameters(context):[];
  context.cursor.expect('where');
  const body=parseV061FieldBody(context,'E-CLASS-BODY');
  const outerSemi=context.cursor.consumeIf(';');
  if(outerSemi)context.own('D-DECL-SEMI');
  return {
    kind:'class',
    name:name.text,
    params,
    fields:body.fields,
    terminatedBySemicolon:outerSemi!==undefined,
    span:{start:first.span.start,end:outerSemi?.span.end??body.span.end},
  };
}
