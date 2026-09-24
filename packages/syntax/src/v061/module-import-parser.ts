import {SyntaxError} from '../source.js';
import {V061ParseContext} from './context.js';

export interface V061ModuleImportParseOptions {
  readonly allowSemicolon:boolean;
  readonly owner:'ProofScript'|'Lean subset';
}

function parseModuleName(context:V061ParseContext):{
  readonly name:string;
  readonly endLine:number;
} {
  const first=context.cursor.expectKind('identifier','module name');
  let name=first.text;
  let endLine=first.span.end.line;
  while(context.cursor.at('.')){
    context.cursor.consume();
    const part=context.cursor.expectKind(
      'identifier',
      'module name segment',
    );
    name+='.'+part.text;
    endLine=part.span.end.line;
  }
  return {name,endLine};
}

export function parseV061ModuleImports(
  context:V061ParseContext,
  options:V061ModuleImportParseOptions,
):readonly string[] {
  const imports:string[]=[];
  while(context.cursor.at('import')){
    const keyword=context.cursor.consume();
    const parsed=parseModuleName(context);
    let endLine=parsed.endLine;
    if(context.cursor.at(';')){
      if(!options.allowSemicolon){
        throw new SyntaxError(
          'PS_LEAN_SUBSET_IMPORT_SEMICOLON: Lean imports do not use semicolons',
          context.cursor.peek().span,
        );
      }
      endLine=context.cursor.consume().span.end.line;
    }
    if(
      !context.cursor.done
      &&context.cursor.peek().span.start.line===endLine
    ){
      throw new SyntaxError(
        'PS_MODULE_IMPORT_FORM: '+options.owner+
        ' currently supports exactly one module name per import line',
        keyword.span,
      );
    }
    imports.push(parsed.name);
  }
  return imports;
}
