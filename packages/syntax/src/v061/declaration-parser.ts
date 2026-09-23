import {SyntaxError} from '../source.js';
import type {V061Declaration,V061Module,V061Parameter} from './ast.js';
import {V061ParseContext,spanBetween} from './context.js';
import {V061ExpressionParser} from './expression-parser.js';

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
    const keyword=this.context.cursor.peek();
    if(keyword.text!=='const'&&keyword.text!=='def'&&keyword.text!=='function'){
      throw new SyntaxError("expected const, def, or function, got '"+keyword.text+"'",keyword.span);
    }
    this.context.cursor.consume();
    const kind=keyword.text as V061Declaration['kind'];
    const name=this.context.cursor.expectKind('identifier','declaration name');
    const params:V061Parameter[]=[];

    if(this.context.cursor.at('(')){
      if(kind==='const')throw new SyntaxError('const declarations cannot have parameters',this.context.cursor.peek().span);
      this.context.own('D-EXPLICIT-PARAMS');
      this.context.cursor.consume();
      if(!this.context.cursor.at(')')){
        while(true){
          const paramName=this.context.cursor.expectKind('identifier','parameter name');
          this.context.cursor.expect(':');
          const paramType=this.context.cursor.expectKind('identifier','parameter type');
          params.push({name:paramName.text,type:paramType.text,span:spanBetween(paramName,paramType)});
          if(!this.context.cursor.consumeIf(','))break;
        }
      }
      this.context.cursor.expect(')');
    }

    if(kind==='function'){
      this.context.own('D-FUNCTION-ALIAS');
      if(params.length===0)throw new SyntaxError('function requires at least one explicit parameter',name.span);
    }
    if(kind==='const')this.context.own('D-CONST-ALIAS');

    this.context.cursor.expect(':');
    const resultType=this.context.cursor.expectKind('identifier','result type');
    this.context.cursor.expect(':=');
    const body=this.expressions.parse();
    const semi=this.context.cursor.consumeIf(';');
    if(semi)this.context.own('D-DECL-SEMI');
    if(!semi&&!this.context.cursor.done){
      throw new SyntaxError("expected ';' between ProofScript declarations",this.context.cursor.peek().span);
    }

    return {
      kind,
      name:name.text,
      params,
      resultType:resultType.text,
      body,
      terminatedBySemicolon:semi!==undefined,
      span:{start:keyword.span.start,end:(semi??body).span.end},
    };
  }
}

export function parseV061Module(source:string):V061Module {
  return new V061DeclarationParser(source).parseModule();
}
