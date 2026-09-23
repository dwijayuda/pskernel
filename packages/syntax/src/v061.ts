
import {lex} from './lexer.js';
import {SyntaxError,type SourceSpan,type Token} from './source.js';
import type {ProofScriptFeatureId} from './features.js';
import {TokenCursor} from './parser-core.js';

export type V061TypeName = 'Nat'|'Int'|'Bool'|'String'|'Unit'|string;
export interface V061Parameter { readonly name:string; readonly type:V061TypeName; readonly span:SourceSpan; }

export type V061Expr =
  | {readonly kind:'nat';readonly text:string;readonly span:SourceSpan}
  | {readonly kind:'string';readonly value:string;readonly span:SourceSpan}
  | {readonly kind:'bool';readonly value:boolean;readonly span:SourceSpan}
  | {readonly kind:'unit';readonly span:SourceSpan}
  | {readonly kind:'reference';readonly name:string;readonly span:SourceSpan}
  | {readonly kind:'group';readonly value:V061Expr;readonly span:SourceSpan}
  | {readonly kind:'call';readonly callee:string;readonly args:readonly V061Expr[];readonly span:SourceSpan}
  | {readonly kind:'unary';readonly operator:'!';readonly operand:V061Expr;readonly span:SourceSpan}
  | {readonly kind:'binary';readonly operator:string;readonly left:V061Expr;readonly right:V061Expr;readonly span:SourceSpan}
  | {readonly kind:'if';readonly condition:V061Expr;readonly thenBranch:V061Expr;readonly elseBranch:V061Expr;readonly span:SourceSpan};

export interface V061Declaration {
  readonly kind:'const'|'def'|'function';
  readonly name:string;
  readonly params:readonly V061Parameter[];
  readonly resultType:V061TypeName;
  readonly body:V061Expr;
  readonly terminatedBySemicolon:boolean;
  readonly span:SourceSpan;
}

export interface V061Module {
  readonly kind:'v061-module';
  readonly declarations:readonly V061Declaration[];
  readonly featureIds:readonly ProofScriptFeatureId[];
}

const BINARY = new Map<string,number>([
  ['||',1],['&&',2],['==',3],['!=',3],
  ['<',4],['<=',4],['>',4],['>=',4],
  ['+',5],['-',5],['*',6],['/',6],['%',6],
]);

function span(first:Token|V061Expr,last:Token|V061Expr):SourceSpan {
  return {start:first.span.start,end:last.span.end};
}

class V061Parser {
  readonly cursor:TokenCursor;
  readonly features = new Set<ProofScriptFeatureId>();

  constructor(source:string) {
    this.cursor = new TokenCursor(lex(source));
  }

  parseModule():V061Module {
    const declarations:V061Declaration[] = [];
    while(!this.cursor.done) declarations.push(this.parseDeclaration());
    return {kind:'v061-module',declarations,featureIds:[...this.features]};
  }

  private parseDeclaration():V061Declaration {
    const keyword = this.cursor.peek();
    if(keyword.text!=='const' && keyword.text!=='def' && keyword.text!=='function') {
      throw new SyntaxError("expected const, def, or function, got '"+keyword.text+"'",keyword.span);
    }
    this.cursor.consume();
    const kind = keyword.text as 'const'|'def'|'function';
    const name = this.cursor.expectKind('identifier','declaration name');
    const params:V061Parameter[] = [];

    if(this.cursor.at('(')) {
      if(kind==='const') throw new SyntaxError('const declarations cannot have parameters',this.cursor.peek().span);
      this.features.add('D-EXPLICIT-PARAMS');
      this.cursor.consume();
      if(!this.cursor.at(')')) {
        while(true) {
          const paramName = this.cursor.expectKind('identifier','parameter name');
          this.cursor.expect(':');
          const paramType = this.cursor.expectKind('identifier','parameter type');
          params.push({name:paramName.text,type:paramType.text,span:span(paramName,paramType)});
          if(!this.cursor.consumeIf(',')) break;
        }
      }
      this.cursor.expect(')');
    }

    if(kind==='function') {
      this.features.add('D-FUNCTION-ALIAS');
      if(params.length===0) throw new SyntaxError('function requires at least one explicit parameter',name.span);
    }
    if(kind==='const') this.features.add('D-CONST-ALIAS');

    this.cursor.expect(':');
    const resultType = this.cursor.expectKind('identifier','result type');
    this.cursor.expect(':=');
    const body = this.parseExpression();
    const semi = this.cursor.consumeIf(';');
    if(semi) this.features.add('D-DECL-SEMI');
    if(!semi && !this.cursor.done) {
      throw new SyntaxError("expected ';' between ProofScript declarations",this.cursor.peek().span);
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

  private parseExpression(minPrecedence=0):V061Expr {
    let left = this.parsePrefix();
    while(true) {
      const op = this.cursor.peek();
      const precedence = BINARY.get(op.text);
      if(precedence===undefined || precedence<minPrecedence) break;
      this.cursor.consume();
      const right = this.parseExpression(precedence+1);
      left = {kind:'binary',operator:op.text,left,right,span:span(left,right)};
    }
    return left;
  }

  private parsePrefix():V061Expr {
    if(this.cursor.at('if')) return this.parseIf();
    if(this.cursor.at('!')) {
      const first = this.cursor.consume();
      const operand = this.parseExpression(7);
      return {kind:'unary',operator:'!',operand,span:span(first,operand)};
    }
    return this.parsePrimary();
  }

  private parseIf():V061Expr {
    const first = this.cursor.expect('if');
    this.features.add('E-IF-BRACE');
    this.cursor.expect('(');
    const condition = this.parseExpression();
    this.cursor.expect(')');
    this.cursor.expect('{');
    const thenBranch = this.parseExpression();
    this.cursor.expect('}');
    this.cursor.expect('else');
    this.cursor.expect('{');
    const elseBranch = this.parseExpression();
    const close = this.cursor.expect('}');
    return {kind:'if',condition,thenBranch,elseBranch,span:{start:first.span.start,end:close.span.end}};
  }

  private parsePrimary():V061Expr {
    const token = this.cursor.peek();

    if(token.kind==='number') {
      this.cursor.consume();
      return {kind:'nat',text:token.text,span:token.span};
    }
    if(token.kind==='string') {
      this.cursor.consume();
      return {kind:'string',value:token.value??'',span:token.span};
    }
    if(token.text==='true' || token.text==='false') {
      this.cursor.consume();
      return {kind:'bool',value:token.text==='true',span:token.span};
    }
    if(token.text==='(') {
      const open = this.cursor.consume();
      if(this.cursor.at(')')) {
        const close = this.cursor.consume();
        return {kind:'unit',span:{start:open.span.start,end:close.span.end}};
      }
      const value = this.parseExpression();
      const close = this.cursor.expect(')');
      return {kind:'group',value,span:{start:open.span.start,end:close.span.end}};
    }
    if(token.kind==='identifier') {
      this.cursor.consume();
      const reference:V061Expr = {kind:'reference',name:token.text,span:token.span};
      const open = this.cursor.peek();
      if(open.text!=='(' || !open.adjacentToPrevious) return reference;

      this.features.add('D-CALL');
      this.cursor.consume();
      const args:V061Expr[] = [];
      if(!this.cursor.at(')')) {
        while(true) {
          args.push(this.parseExpression());
          if(!this.cursor.consumeIf(',')) break;
        }
      }
      const close = this.cursor.expect(')');
      return {kind:'call',callee:token.text,args,span:{start:token.span.start,end:close.span.end}};
    }

    throw new SyntaxError("expected expression, got '"+token.text+"'",token.span);
  }
}

export function parseV061Module(source:string):V061Module {
  return new V061Parser(source).parseModule();
}

function precedence(expr:V061Expr):number {
  return expr.kind==='binary' ? (BINARY.get(expr.operator)??0) : 8;
}

export function lowerV061ExprToLean(expr:V061Expr,parentPrecedence=0):string {
  switch(expr.kind) {
    case 'nat': return expr.text;
    case 'string': return JSON.stringify(expr.value);
    case 'bool': return expr.value ? 'true' : 'false';
    case 'unit': return '()';
    case 'reference': return expr.name;
    case 'group': return '('+lowerV061ExprToLean(expr.value)+')';
    case 'call': {
      const args = expr.args.map((arg)=>{
        const rendered = lowerV061ExprToLean(arg);
        return arg.kind==='reference'||arg.kind==='nat'||arg.kind==='string'||arg.kind==='bool'||arg.kind==='unit'
          ? rendered
          : '('+rendered+')';
      });
      return args.length===0 ? expr.callee+' ()' : expr.callee+' '+args.join(' ');
    }
    case 'unary': return '!'+lowerV061ExprToLean(expr.operand,7);
    case 'binary': {
      const p = precedence(expr);
      const rendered = lowerV061ExprToLean(expr.left,p)+' '+expr.operator+' '+lowerV061ExprToLean(expr.right,p+1);
      return p<parentPrecedence ? '('+rendered+')' : rendered;
    }
    case 'if':
      return 'if '+lowerV061ExprToLean(expr.condition)+' then '+lowerV061ExprToLean(expr.thenBranch)+' else '+lowerV061ExprToLean(expr.elseBranch);
  }
}

export function lowerV061ModuleToLean(module:V061Module):string {
  return module.declarations.map((decl)=>{
    const head = decl.kind==='function'||decl.kind==='const' ? 'def' : decl.kind;
    const params = decl.params.map((p)=>' ('+p.name+' : '+p.type+')').join('');
    return head+' '+decl.name+params+' : '+decl.resultType+' := '+lowerV061ExprToLean(decl.body);
  }).join('\n\n')+'\n';
}
