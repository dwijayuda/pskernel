import {SyntaxError} from '../source.js';
import type {V061StructureDeclaration} from './ast.js';
import {V061ParseContext} from './context.js';
import {parseV061FieldBody} from './field-parser.js';

export function parseV061StructureDeclaration(
  context:V061ParseContext,
):V061StructureDeclaration {
  const first=context.cursor.expect('structure');
  const name=context.cursor.expectKind('identifier','structure name');
  if(context.cursor.at('(')||context.cursor.at('{')||context.cursor.at('[')){
    throw new SyntaxError(
      'parameterized structure headers are not yet implemented by this parser milestone',
      context.cursor.peek().span,
    );
  }
  context.cursor.expect('where');
  const body=parseV061FieldBody(context,'E-STRUCT-BODY');
  const outerSemi=context.cursor.consumeIf(';');
  if(outerSemi)context.own('D-DECL-SEMI');
  return {
    kind:'structure',
    name:name.text,
    fields:body.fields,
    terminatedBySemicolon:outerSemi!==undefined,
    span:{start:first.span.start,end:outerSemi?.span.end??body.span.end},
  };
}
