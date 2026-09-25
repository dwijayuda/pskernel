import {SyntaxError} from '../source.js';
import type {
  V061Declaration,
  V061Expr,
  V061Module,
  V061Parameter,
} from './ast.js';
import {V061ParseContext} from './context.js';
import {V061LeanSubsetExpressionParser} from './lean-subset-expression-parser.js';
import {parseV061LeanSubsetDeclaration} from './lean-subset-declaration-parser.js';
import {parseV061ParameterSequence} from './parameter-parser.js';
import {parseV061Pattern,type V061Pattern} from './pattern-parser.js';
import {parseV061Type,type V061TypeExpr} from './type-parser.js';
import {parseV061LeanSubsetWhereDeclarations} from './lean-subset-where-parser.js';
import {parseV061ModuleImports} from './module-import-parser.js';

type LeanEquationPattern =
  | V061Pattern
  | {
      readonly kind:'variable';
      readonly name:string;
      readonly span:V061Pattern['span'];
    };

interface LeanEquationRow {
  readonly patterns:readonly LeanEquationPattern[];
  readonly body:V061Expr;
  readonly span:V061Expr['span'];
}

function equationPatternKey(pattern:LeanEquationPattern):string|undefined {
  switch(pattern.kind){
    case 'wildcard':
    case 'variable':
      return undefined;
    case 'bool':return pattern.value?'#true':'#false';
    case 'constructor':return '#ctor:'+pattern.name;
  }
}

function equationAlternativePattern(
  pattern:LeanEquationPattern,
):V061Pattern {
  if(pattern.kind==='variable'){
    return {kind:'wildcard',span:pattern.span};
  }
  return pattern;
}

function stripEquationColumn(
  row:LeanEquationRow,
  scrutinee:V061Expr,
):LeanEquationRow {
  const pattern=row.patterns[0]!;
  const body=pattern.kind==='variable'
    ?({
        kind:'let',
        name:pattern.name,
        value:scrutinee,
        body:row.body,
        span:{start:pattern.span.start,end:row.body.span.end},
      } as V061Expr)
    :row.body;
  return {
    ...row,
    patterns:row.patterns.slice(1),
    body,
  };
}

function compileEquationMatrix(
  scrutinees:readonly V061Expr[],
  rows:readonly LeanEquationRow[],
):V061Expr {
  if(rows.length===0){
    throw new Error('PS_LEAN_SUBSET_EQUATION_INTERNAL: empty equation matrix');
  }
  if(scrutinees.length===0){
    return rows[0]!.body;
  }

  let sawWildcard=false;
  const keys:string[]=[];
  const representative=new Map<string,LeanEquationPattern>();
  for(const row of rows){
    const pattern=row.patterns[0];
    if(pattern===undefined){
      throw new Error('PS_LEAN_SUBSET_EQUATION_INTERNAL: missing equation pattern');
    }
    const key=equationPatternKey(pattern);
    if(key===undefined){
      sawWildcard=true;
      continue;
    }
    if(sawWildcard){
      throw new Error(
        'PS_LEAN_SUBSET_EQUATION_WILDCARD_ORDER: wildcard rows must follow constructor rows',
      );
    }
    if(!representative.has(key)){
      representative.set(key,pattern);
      keys.push(key);
    }
  }

  const alternatives:{
    pattern:V061Pattern;
    body:V061Expr;
    span:V061Expr['span'];
  }[]=[];
  for(const key of keys){
    const applicable=rows
      .filter((row)=>{
        const pattern=row.patterns[0]!;
        const rowKey=equationPatternKey(pattern);
        return rowKey===key||rowKey===undefined;
      })
      .map((row)=>stripEquationColumn(row,scrutinees[0]!));
    const pattern=equationAlternativePattern(representative.get(key)!);
    const body=compileEquationMatrix(
      scrutinees.slice(1),
      applicable,
    );
    alternatives.push({
      pattern,
      body,
      span:{start:pattern.span.start,end:body.span.end},
    });
  }

  const wildcardRows=rows
    .filter((row)=>equationPatternKey(row.patterns[0]!)===undefined)
    .map((row)=>stripEquationColumn(row,scrutinees[0]!));
  if(wildcardRows.length>0){
    const sourcePattern=equationAlternativePattern(rows.find(
      (row)=>equationPatternKey(row.patterns[0]!)===undefined,
    )!.patterns[0]!);
    const body=compileEquationMatrix(
      scrutinees.slice(1),
      wildcardRows,
    );
    alternatives.push({
      pattern:sourcePattern,
      body,
      span:{start:sourcePattern.span.start,end:body.span.end},
    });
  }

  if(alternatives.length===0){
    throw new Error(
      'PS_LEAN_SUBSET_EQUATION_INTERNAL: equation column has no alternatives',
    );
  }
  const first=alternatives[0]!;
  const last=alternatives[alternatives.length-1]!;
  return {
    kind:'match',
    scrutinee:scrutinees[0]!,
    alternatives,
    span:{start:scrutinees[0]!.span.start,end:last.span.end},
  };
}

function exposeEquationArguments(
  type:V061TypeExpr,
  count:number,
):{
  readonly params:readonly V061Parameter[];
  readonly resultType:V061TypeExpr;
  readonly scrutinees:readonly V061Expr[];
} {
  const params:V061Parameter[]=[];
  const scrutinees:V061Expr[]=[];
  let cursor=type;
  for(let index=0;index<count;index+=1){
    if(cursor.kind!=='arrow'&&cursor.kind!=='dependentArrow'){
      throw new Error(
        'PS_LEAN_SUBSET_EQUATION_ARITY: equation patterns exceed the declared function type',
      );
    }
    const name=cursor.kind==='dependentArrow'
      ?cursor.name
      :'_eq_arg_'+index;
    params.push({
      name,
      type:cursor.domain,
      span:cursor.domain.span,
    });
    scrutinees.push({
      kind:'reference',
      name,
      span:cursor.domain.span,
    });
    cursor=cursor.codomain;
  }
  return {params,resultType:cursor,scrutinees};
}

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

  private parseEquationPattern():LeanEquationPattern {
    const token=this.context.cursor.peek();
    const next=this.context.cursor.peek(1);
    if(
      token.kind==='identifier'
      &&token.text!=='_'
      &&token.text!=='true'
      &&token.text!=='false'
      &&!token.text.includes('.')
      &&(next.text===','||next.text==='=>')
    ){
      this.context.cursor.consume();
      return {
        kind:'variable',
        name:token.text,
        span:token.span,
      };
    }
    return parseV061Pattern(this.context);
  }

  private parseEquationRows():readonly LeanEquationRow[] {
    const rows:LeanEquationRow[]=[];
    let arity:number|undefined;
    while(this.context.cursor.at('|')){
      const bar=this.context.cursor.consume();
      const patterns:LeanEquationPattern[]=[];
      while(true){
        patterns.push(this.parseEquationPattern());
        if(!this.context.cursor.consumeIf(','))break;
      }
      if(patterns.length===0){
        throw new SyntaxError(
          'PS_LEAN_SUBSET_EQUATION_EMPTY: equation row requires a pattern',
          bar.span,
        );
      }
      if(arity===undefined)arity=patterns.length;
      else if(patterns.length!==arity){
        throw new SyntaxError(
          'PS_LEAN_SUBSET_EQUATION_ARITY: every equation row must have the same pattern arity',
          bar.span,
        );
      }
      this.context.cursor.expect('=>');
      const body=this.expressions.parse();
      rows.push({
        patterns,
        body,
        span:{start:bar.span.start,end:body.span.end},
      });
    }
    if(rows.length===0){
      throw new SyntaxError(
        'PS_LEAN_SUBSET_EQUATION_EMPTY: expected equation rows',
        this.context.cursor.peek().span,
      );
    }
    return rows;
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
    let resultType=parseV061Type(this.context);
    let declarationParams=params;
    let body:V061Expr;
    if(this.context.cursor.at('|')){
      const rows=this.parseEquationRows();
      const exposed=exposeEquationArguments(
        resultType,
        rows[0]!.patterns.length,
      );
      declarationParams=[...params,...exposed.params];
      resultType=exposed.resultType;
      body=compileEquationMatrix(exposed.scrutinees,rows);
    }else{
      this.context.cursor.expect(':=');
      body=this.expressions.parse();
    }

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
      params:declarationParams,
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
