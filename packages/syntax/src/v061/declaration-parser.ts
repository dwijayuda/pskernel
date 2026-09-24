import {SyntaxError} from '../source.js';
import type {V061Declaration,V061Module,V061ValueDeclaration} from './ast.js';
import {V061ParseContext,spanBetween,type V061ParseOptions} from './context.js';
import {V061ExpressionParser} from './expression-parser.js';
import {parseV061Type} from './type-parser.js';
import {parseV061StructureDeclaration} from './structure-parser.js';
import {parseV061InductiveDeclaration} from './inductive-parser.js';
import {parseV061ClassDeclaration} from './class-parser.js';
import {parseV061ParameterSequence} from './parameter-parser.js';
import {parseV061WhereBlock} from './where-parser.js';
import {parseV061InstanceDeclaration} from './instance-parser.js';
import {parseV061ModuleImports} from './module-import-parser.js';
import {parseV061ExternalDeclaration} from './external-parser.js';

export class V061DeclarationParser {
  readonly context:V061ParseContext;
  readonly expressions:V061ExpressionParser;

  constructor(source:string,options:V061ParseOptions={}){
    this.context=new V061ParseContext(source,undefined,options);
    this.expressions=new V061ExpressionParser(this.context);
  }

  parseModule():V061Module {
    const imports=parseV061ModuleImports(this.context,{
      allowSemicolon:true,
      owner:'ProofScript',
    });
    const declarations:V061Declaration[]=[];
    while(!this.context.cursor.done){
      declarations.push(this.parseDeclaration());
    }
    return {
      kind:'v061-module',
      ...(imports.length===0?{}:{imports}),
      declarations,
      featureIds:[...this.context.features],
    };
  }

  private parseDeclaration():V061Declaration {
    if(this.context.cursor.at('extern')){
      return parseV061ExternalDeclaration(this.context);
    }
    if(this.context.cursor.at('structure')){
      return parseV061StructureDeclaration(this.context);
    }
    if(this.context.cursor.at('inductive')){
      return parseV061InductiveDeclaration(this.context);
    }
    if(this.context.cursor.at('class')){
      return parseV061ClassDeclaration(this.context);
    }
    if(this.context.cursor.at('instance')){
      return parseV061InstanceDeclaration(
        this.context,
        this.expressions,
      );
    }
    return this.parseValueDeclaration();
  }

  private parseValueDeclaration():V061ValueDeclaration {
    const keyword=this.context.cursor.peek();
    if(keyword.text!=='const'&&keyword.text!=='def'&&keyword.text!=='function'&&keyword.text!=='theorem'){
      throw new SyntaxError(
        "expected const, def, function, or theorem, got '"+keyword.text+"'",
        keyword.span,
      );
    }
    this.context.cursor.consume();
    const kind=keyword.text as V061ValueDeclaration['kind'];
    const name=this.context.cursor.expectKind('identifier','declaration name');
    if(
      kind==='const'
      &&(
        this.context.cursor.at('(')
        ||this.context.cursor.at('{')
        ||this.context.cursor.at('[')
      )
    ){
      throw new SyntaxError(
        'const declarations cannot have parameters',
        this.context.cursor.peek().span,
      );
    }
    const parsedParams=kind==='const'
      ? {params:[],explicitGroups:0}
      : parseV061ParameterSequence(this.context);
    const params=parsedParams.params;

    if(kind==='function'){
      this.context.own('D-FUNCTION-ALIAS');
      if(parsedParams.explicitGroups===0){
        throw new SyntaxError(
          'function requires at least one D-EXPLICIT-PARAMS group',
          name.span,
        );
      }
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

export function parseV061Module(
  source:string,
  options:V061ParseOptions={},
):V061Module {
  return new V061DeclarationParser(source,options).parseModule();
}

export function parseV061PsxModule(source:string):V061Module {
  return parseV061Module(source,{jsx:true});
}
