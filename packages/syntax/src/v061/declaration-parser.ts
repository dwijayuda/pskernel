import {SyntaxError} from '../source.js';
import type {V061Declaration,V061Module,V061ValueDeclaration} from './ast.js';
import {V061ParseContext,spanBetween} from './context.js';
import {V061ExpressionParser} from './expression-parser.js';
import {parseV061Type} from './type-parser.js';
import {parseV061StructureDeclaration} from './structure-parser.js';
import {parseV061InductiveDeclaration} from './inductive-parser.js';
import {parseV061ClassDeclaration} from './class-parser.js';
import {parseV061ExplicitParameters} from './parameter-parser.js';
import {parseV061WhereBlock} from './where-parser.js';

export class V061DeclarationParser {
  readonly context:V061ParseContext;
  readonly expressions:V061ExpressionParser;

  constructor(source:string){
    this.context=new V061ParseContext(source);
    this.expressions=new V061ExpressionParser(this.context);
  }

  parseModule():V061Module {
    const declarations:V061Declaration[]=[];
    while(!this.context.cursor.done)declarations.push(this.parseDeclaration());
    return {kind:'v061-module',declarations,featureIds:[...this.context.features]};
  }

  private parseDeclaration():V061Declaration {
    if(this.context.cursor.at('structure')){
      return parseV061StructureDeclaration(this.context);
    }
    if(this.context.cursor.at('inductive')){
      return parseV061InductiveDeclaration(this.context);
    }
    if(this.context.cursor.at('class')){
      return parseV061ClassDeclaration(this.context);
    }
    return this.parseValueDeclaration();
  }

  private parseValueDeclaration():V061ValueDeclaration {
    const keyword=this.context.cursor.peek();
    if(keyword.text!=='const'&&keyword.text!=='def'&&keyword.text!=='function'){
      throw new SyntaxError("expected const, def, or function, got '"+keyword.text+"'",keyword.span);
    }
    this.context.cursor.consume();
    const kind=keyword.text as V061ValueDeclaration['kind'];
    const name=this.context.cursor.expectKind('identifier','declaration name');
    if(kind==='const'&&this.context.cursor.at('(')){
      throw new SyntaxError(
        'const declarations cannot have parameters',
        this.context.cursor.peek().span,
      );
    }
    const params=this.context.cursor.at('(')
      ? parseV061ExplicitParameters(this.context)
      : [];

    if(kind==='function'){
      this.context.own('D-FUNCTION-ALIAS');
      if(params.length===0)throw new SyntaxError('function requires at least one explicit parameter',name.span);
    }
    if(kind==='const')this.context.own('D-CONST-ALIAS');

    this.context.cursor.expect(':');
    const resultType=parseV061Type(this.context);
    this.context.cursor.expect(':=');
    const body=this.expressions.parse();
    const whereBlock=this.context.cursor.at('where')
      ? parseV061WhereBlock(this.context,this.expressions)
      : undefined;
    const semi=this.context.cursor.consumeIf(';');
    if(semi)this.context.own('D-DECL-SEMI');
    if(!semi&&!this.context.cursor.done){
      throw new SyntaxError("expected ';' between ProofScript declarations",this.context.cursor.peek().span);
    }

    return {
      kind,
      name:name.text,
      params,
      resultType,
      body,
      ...(whereBlock===undefined?{}:{whereDeclarations:whereBlock.declarations}),
      terminatedBySemicolon:semi!==undefined,
      span:{
        start:keyword.span.start,
        end:semi?.span.end??whereBlock?.span.end??body.span.end,
      },
    };
  }
}

export function parseV061Module(source:string):V061Module {
  return new V061DeclarationParser(source).parseModule();
}
