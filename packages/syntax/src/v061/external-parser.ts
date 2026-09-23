import {SyntaxError} from '../source.js';
import type {V061ExternalDeclaration} from './ast.js';
import {V061ParseContext} from './context.js';
import {parseV061ExplicitParameters} from './parameter-parser.js';
import {parseV061Type} from './type-parser.js';

export function parseV061ExternalDeclaration(
  context:V061ParseContext,
):V061ExternalDeclaration {
  const first=context.cursor.expect('extern');
  context.own('D-EXTERN-FFI');
  context.cursor.expect('function');
  const name=context.cursor.expectKind('identifier','external function name');
  const params=parseV061ExplicitParameters(context);

  context.cursor.expect(':');
  const resultType=parseV061Type(context);
  context.cursor.expect('from');
  const sourceToken=context.cursor.expectKind('string','ESM module source');
  const source=sourceToken.value;
  if(source===undefined||source.length===0){
    throw new SyntaxError(
      'external ESM module source must be a non-empty string',
      sourceToken.span,
    );
  }
  context.cursor.expect('import');
  const importedName=context.cursor.expectKind(
    'identifier',
    'named ESM import',
  );
  const semi=context.cursor.consumeIf(';');
  if(semi)context.own('D-DECL-SEMI');
  if(!semi&&!context.cursor.done){
    throw new SyntaxError(
      "expected ';' between ProofScript declarations",
      context.cursor.peek().span,
    );
  }

  return {
    kind:'external',
    name:name.text,
    params,
    resultType,
    binding:{
      source,
      importedName:importedName.text,
    },
    terminatedBySemicolon:semi!==undefined,
    span:{
      start:first.span.start,
      end:semi?.span.end??importedName.span.end,
    },
  };
}
