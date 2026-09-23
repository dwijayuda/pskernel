import {SyntaxError} from '../source.js';
import type {
  V061Declaration,
  V061Module,
  V061ValueDeclaration,
} from './ast.js';
import {V061ParseContext} from './context.js';
import {V061LeanSubsetExpressionParser} from './lean-subset-expression-parser.js';
import {parseV061LeanSubsetDeclaration} from './lean-subset-declaration-parser.js';
import {parseV061ParameterSequence} from './parameter-parser.js';
import {parseV061Type} from './type-parser.js';

export class V061LeanSubsetParser {
  readonly context:V061ParseContext;
  readonly expressions:V061LeanSubsetExpressionParser;

  constructor(source:string){
    this.context=new V061ParseContext(source);
    this.expressions=new V061LeanSubsetExpressionParser(this.context);
  }

  parseModule():V061Module {
    const declarations:V061Declaration[]=[];
    while(!this.context.cursor.done){
      declarations.push(this.parseDeclaration());
    }
    return {
      kind:'v061-module',
      declarations,
      featureIds:[...this.context.features],
    };
  }

  private parseDeclaration():V061Declaration {
    const token=this.context.cursor.peek();
    if(token.text!=='def'&&token.text!=='theorem'){
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

    if(this.context.cursor.at('where')){
      throw new SyntaxError(
        'PS_LEAN_SUBSET_UNSUPPORTED_WHERE: Lean where declarations are not in DS2.2',
        this.context.cursor.peek().span,
      );
    }
    if(this.context.cursor.at(';')){
      throw new SyntaxError(
        'PS_LEAN_SUBSET_DECL_SEMICOLON: canonical Lean declarations do not use a trailing semicolon',
        this.context.cursor.peek().span,
      );
    }

    return {
      kind,
      name:name.text,
      params,
      resultType,
      body,
      terminatedBySemicolon:false,
      span:{start:first.span.start,end:body.span.end},
    };
  }
}

export function parseV061LeanSubsetModule(source:string):V061Module {
  return new V061LeanSubsetParser(source).parseModule();
}
