import {SyntaxError} from '../source.js';
import type {V061StructureDeclaration,V061StructureField} from './ast.js';
import {V061ParseContext} from './context.js';
import {parseV061Type} from './type-parser.js';

export function parseV061StructureDeclaration(
  context:V061ParseContext,
):V061StructureDeclaration {
  const first=context.cursor.expect('structure');
  const name=context.cursor.expectKind('identifier','structure name');
  if(context.cursor.at('(')||context.cursor.at('{')||context.cursor.at('[')){
    throw new SyntaxError(
      'parameterized/implicit structure headers are not yet implemented by this parser milestone',
      context.cursor.peek().span,
    );
  }
  context.cursor.expect('where');
  context.cursor.expect('{');
  context.own('E-STRUCT-BODY');

  const fields:V061StructureField[]=[];
  while(!context.cursor.at('}')){
    if(context.cursor.at('{')){
      const open=context.cursor.consume();
      const fieldName=context.cursor.expectKind('identifier','implicit structure field name');
      context.cursor.expect(':');
      const type=parseV061Type(context);
      context.cursor.expect('}');
      const semi=context.cursor.expect(';');
      fields.push({
        name:fieldName.text,
        type,
        binderKind:'implicit',
        span:{start:open.span.start,end:semi.span.end},
      });
      continue;
    }

    if(context.cursor.at('[')){
      throw new SyntaxError(
        'instance structure fields require type-application parsing and are not yet implemented',
        context.cursor.peek().span,
      );
    }

    const fieldName=context.cursor.expectKind('identifier','structure field name');
    context.cursor.expect(':');
    const type=parseV061Type(context);
    const semi=context.cursor.expect(';');
    fields.push({
      name:fieldName.text,
      type,
      binderKind:'explicit',
      span:{start:fieldName.span.start,end:semi.span.end},
    });
  }
  const close=context.cursor.expect('}');
  if(fields.length===0){
    throw new SyntaxError('structure body requires at least one field in this milestone',close.span);
  }
  const outerSemi=context.cursor.consumeIf(';');
  if(outerSemi)context.own('D-DECL-SEMI');
  return {
    kind:'structure',
    name:name.text,
    fields,
    terminatedBySemicolon:outerSemi!==undefined,
    span:{start:first.span.start,end:(outerSemi??close).span.end},
  };
}
