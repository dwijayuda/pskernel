import {SyntaxError,type SourceSpan} from '../source.js';
import type {V061StructureField} from './ast.js';
import {V061ParseContext} from './context.js';
import {parseV061Type} from './type-parser.js';

export interface V061FieldBody {
  readonly fields:readonly V061StructureField[];
  readonly span:SourceSpan;
}

export function parseV061FieldBody(
  context:V061ParseContext,
  feature:'E-STRUCT-BODY'|'E-CLASS-BODY',
):V061FieldBody {
  const open=context.cursor.expect('{');
  context.own(feature);
  const fields:V061StructureField[]=[];

  while(!context.cursor.at('}')){
    if(context.cursor.at('{')){
      const implicitOpen=context.cursor.consume();
      const name=context.cursor.expectKind('identifier','implicit field name');
      context.cursor.expect(':');
      const type=parseV061Type(context);
      context.cursor.expect('}');
      const semi=context.cursor.expect(';');
      fields.push({
        name:name.text,
        type,
        binderKind:'implicit',
        span:{start:implicitOpen.span.start,end:semi.span.end},
      });
      continue;
    }
    if(context.cursor.at('[')){
      const instanceOpen=context.cursor.consume();
      const name=context.cursor.expectKind('identifier','instance field name');
      context.cursor.expect(':');
      const type=parseV061Type(context);
      context.cursor.expect(']');
      const semi=context.cursor.expect(';');
      fields.push({
        name:name.text,
        type,
        binderKind:'instance',
        span:{start:instanceOpen.span.start,end:semi.span.end},
      });
      continue;
    }

    const name=context.cursor.expectKind('identifier','field name');
    context.cursor.expect(':');
    const type=parseV061Type(context);
    const semi=context.cursor.expect(';');
    fields.push({
      name:name.text,
      type,
      binderKind:'explicit',
      span:{start:name.span.start,end:semi.span.end},
    });
  }

  const close=context.cursor.expect('}');
  if(fields.length===0){
    throw new SyntaxError('field body requires at least one field',close.span);
  }
  return {fields,span:{start:open.span.start,end:close.span.end}};
}
