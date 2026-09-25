import {SyntaxError} from '../source.js';
import type {
  V061Declaration,
  V061Module,
} from './ast.js';
import {V061ParseContext} from './context.js';
import {V061LeanSubsetExpressionParser} from './lean-subset-expression-parser.js';
import {parseV061LeanSubsetDeclaration} from './lean-subset-declaration-parser.js';
import {parseV061ParameterSequence} from './parameter-parser.js';
import {parseV061Type} from './type-parser.js';
import {parseV061LeanSubsetWhereDeclarations} from './lean-subset-where-parser.js';
import {parseV061ModuleImports} from './module-import-parser.js';

export class V061LeanSubsetParser {
  readonly context:V061ParseContext;
  readonly expressions:V061LeanSubsetExpressionParser;

  constructor(source:string){
    this.context=new V061ParseContext(source);
    this.expressions=new V061LeanSubsetExpressionParser(this.context);
  }

  parseModule():V061Module {
    const imports=parseV061ModuleImports(this.context,{
      allowSemicolon:false,
      owner:'Lean subset',
    });
    const declarations:V061Declaration[]=[];
    const namespacePath:string[]=[];
    while(!this.context.cursor.done){
      if(this.context.cursor.at('namespace')){
        this.context.cursor.consume();
        const name=this.context.cursor.expectKind(
          'identifier',
          'Lean namespace name',
        );
        namespacePath.push(...name.text.split('.'));
        continue;
      }
      if(
        this.context.cursor.at('end')
        &&this.context.cursor.peek(1).kind==='identifier'
      ){
        const endToken=this.context.cursor.consume();
        const name=this.context.cursor.consume();
        const parts=name.text.split('.');
        const start=namespacePath.length-parts.length;
        const matches=start>=0&&parts.every(
          (part,index)=>namespacePath[start+index]===part,
        );
        if(!matches){
          throw new SyntaxError(
            "PS_LEAN_SUBSET_NAMESPACE_END: 'end "+name.text+
            "' does not close the active namespace '"+
            namespacePath.join('.')+"'",
            endToken.span,
          );
        }
        namespacePath.splice(start,parts.length);
        continue;
      }

      const declaration=this.parseDeclaration();
      const qualifiedName=[...namespacePath,declaration.name]
        .filter((part)=>part.length>0)
        .join('.');
      declarations.push({
        ...declaration,
        name:qualifiedName,
        ...(namespacePath.length===0
          ?{}
          :{namespacePath:[...namespacePath]}),
      });
    }
    if(namespacePath.length!==0){
      throw new SyntaxError(
        "PS_LEAN_SUBSET_NAMESPACE_UNCLOSED: namespace '"+
        namespacePath.join('.')+"' is not closed",
        this.context.cursor.peek().span,
      );
    }
    return {
      kind:'v061-module',
      ...(imports.length===0?{}:{imports}),
      declarations,
      featureIds:[...this.context.features],
    };
  }

  private parseDeclaration():V061Declaration {
    const token=this.context.cursor.peek();
    const partial=token.text==='partial';
    if(partial){
      const partialToken=this.context.cursor.consume();
      if(!this.context.cursor.at('def')){
        throw new SyntaxError(
          "PS_LEAN_SUBSET_PARTIAL: 'partial' currently modifies 'def' only",
          partialToken.span,
        );
      }
    }
    if(!this.context.cursor.at('def')&&!this.context.cursor.at('theorem')){
      return parseV061LeanSubsetDeclaration(
        this.context,
        this.expressions,
      );
    }

    const first=this.context.cursor.consume();
    const kind=first.text as 'def'|'theorem';
    const name=this.context.cursor.expectKind(
      'identifier',
      'Lean declaration name',
    );
    const {params}=parseV061ParameterSequence(this.context);
    this.context.cursor.expect(':');
    const resultType=parseV061Type(this.context);
    this.context.cursor.expect(':=');
    const body=this.expressions.parse();

    const whereDeclarations=this.context.cursor.at('where')
      ?parseV061LeanSubsetWhereDeclarations(this.context)
      :undefined;
    if(this.context.cursor.at(';')){
      throw new SyntaxError(
        'PS_LEAN_SUBSET_DECL_SEMICOLON: canonical Lean declarations do not use a trailing semicolon',
        this.context.cursor.peek().span,
      );
    }

    return {
      kind,
      ...(partial?{partial:true}:{}),
      name:name.text,
      params,
      resultType,
      body,
      ...(whereDeclarations===undefined?{}:{whereDeclarations}),
      terminatedBySemicolon:false,
      span:{
        start:first.span.start,
        end:whereDeclarations?.[whereDeclarations.length-1]?.span.end
          ??body.span.end,
      },
    };
  }
}

export function parseV061LeanSubsetModule(source:string):V061Module {
  return new V061LeanSubsetParser(source).parseModule();
}
