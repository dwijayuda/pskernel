import {SyntaxError} from '../source.js';
import type {V061Expr,V061LambdaBinder} from './ast.js';
import {V061ParseContext,spanBetween} from './context.js';
import {v061BinaryPrecedence} from './operators.js';
import {parseV061Type} from './type-parser.js';
import {parseV061Pattern} from './pattern-parser.js';
import {parseV061RecordExpression} from './record-parser.js';
import {parseV061ByExpression} from './tactic-parser.js';

export class V061ExpressionParser {
  constructor(readonly context:V061ParseContext){}

  parse(minPrecedence=0):V061Expr {
    let left=this.parsePrefix();
    while(true){
      const op=this.context.cursor.peek();
      const precedence=v061BinaryPrecedence(op.text);
      if(precedence===undefined||precedence<minPrecedence)break;
      this.context.cursor.consume();
      const right=this.parse(precedence+1);
      left={kind:'binary',operator:op.text,left,right,span:spanBetween(left,right)};
    }
    return left;
  }

  private parsePrefix():V061Expr {
    if(this.context.cursor.at('by'))return parseV061ByExpression(this.context,this);
    if(this.context.cursor.at('match'))return this.parseMatch();
    if(this.context.cursor.at('fun'))return this.parseLambda();
    if(this.context.cursor.at('let'))return this.parseLet();
    if(this.context.cursor.at('if'))return this.parseIf();
    if(this.context.cursor.at('!')){
      const first=this.context.cursor.consume();
      const operand=this.parse(7);
      return {kind:'unary',operator:'!',operand,span:spanBetween(first,operand)};
    }
    return this.parsePrimary();
  }



  private parseMatch():V061Expr {
    const first=this.context.cursor.expect('match');
    this.context.own('E-MATCH-BODY');
    const scrutinee=this.parse();
    this.context.cursor.expect('with');
    this.context.cursor.expect('{');

    const alternatives:{pattern:ReturnType<typeof parseV061Pattern>;body:V061Expr;span:V061Expr['span']}[]=[];
    while(!this.context.cursor.at('}')){
      const bar=this.context.cursor.expect('|');
      const pattern=parseV061Pattern(this.context);
      this.context.cursor.expect('=>');
      const body=this.parse();
      const semi=this.context.cursor.consumeIf(';');
      if(semi)this.context.own('D-DECL-SEMI');
      if(!semi&&!this.context.cursor.at('}')){
        throw new SyntaxError("expected ';' or '}' after match alternative",this.context.cursor.peek().span);
      }
      alternatives.push({
        pattern,
        body,
        span:{start:bar.span.start,end:(semi??body).span.end},
      });
    }
    const close=this.context.cursor.expect('}');
    if(alternatives.length===0){
      throw new SyntaxError('match requires at least one alternative',close.span);
    }
    return {
      kind:'match',
      scrutinee,
      alternatives,
      span:{start:first.span.start,end:close.span.end},
    };
  }

  private parseLambda():V061Expr {
    const first=this.context.cursor.expect('fun');
    const binders:V061LambdaBinder[]=[];

    while(!this.context.cursor.at('=>')){
      const start=this.context.cursor.peek();
      if(start.text==='('){
        const open=this.context.cursor.consume();
        const name=this.context.cursor.expectKind('identifier','lambda binder name');
        this.context.cursor.expect(':');
        const type=parseV061Type(this.context);
        const close=this.context.cursor.expect(')');
        binders.push({name:name.text,type,span:{start:open.span.start,end:close.span.end}});
      }else if(start.kind==='identifier'){
        const name=this.context.cursor.consume();
        binders.push({name:name.text,span:name.span});
      }else{
        throw new SyntaxError("expected lambda binder or '=>', got '"+start.text+"'",start.span);
      }
    }

    if(binders.length===0){
      throw new SyntaxError('lambda requires at least one binder',first.span);
    }
    this.context.cursor.expect('=>');
    const body=this.parse();
    return {kind:'lambda',binders,body,span:{start:first.span.start,end:body.span.end}};
  }

  private parseLet():V061Expr {
    const first=this.context.cursor.expect('let');
    const name=this.context.cursor.expectKind('identifier','let binding name');
    const declaredType=this.context.cursor.consumeIf(':')?parseV061Type(this.context):undefined;
    this.context.cursor.expect(':=');
    const value=this.parse();
    this.context.cursor.expect(';');
    const body=this.parse();
    return {
      kind:'let',
      name:name.text,
      ...(declaredType===undefined?{}:{declaredType}),
      value,
      body,
      span:{start:first.span.start,end:body.span.end},
    };
  }

  private parseIf():V061Expr {
    const first=this.context.cursor.expect('if');
    this.context.own('E-IF-BRACE');
    this.context.cursor.expect('(');
    const condition=this.parse();
    this.context.cursor.expect(')');
    this.context.cursor.expect('{');
    const thenBranch=this.parse();
    this.context.cursor.expect('}');
    this.context.cursor.expect('else');
    this.context.cursor.expect('{');
    const elseBranch=this.parse();
    const close=this.context.cursor.expect('}');
    return {kind:'if',condition,thenBranch,elseBranch,span:{start:first.span.start,end:close.span.end}};
  }

  private parsePrimary():V061Expr {
    if(this.context.cursor.at('{')){
      return parseV061RecordExpression(this.context,()=>this.parse());
    }
    const token=this.context.cursor.peek();

    if(
      token.text==='?'
      &&this.context.cursor.peek(1).text==='_'
    ){
      const first=this.context.cursor.consume();
      const hole=this.context.cursor.consume();
      return {
        kind:'syntheticHole',
        span:{start:first.span.start,end:hole.span.end},
      };
    }

    if(token.kind==='number'){
      this.context.cursor.consume();
      return {kind:'nat',text:token.text,span:token.span};
    }
    if(token.kind==='string'){
      this.context.cursor.consume();
      return {kind:'string',value:token.value??'',span:token.span};
    }
    if(token.text==='true'||token.text==='false'){
      this.context.cursor.consume();
      return {kind:'bool',value:token.text==='true',span:token.span};
    }
    if(token.text==='('){
      const open=this.context.cursor.consume();
      if(this.context.cursor.at(')')){
        const close=this.context.cursor.consume();
        return {kind:'unit',span:{start:open.span.start,end:close.span.end}};
      }
      const value=this.parse();
      const close=this.context.cursor.expect(')');
      return {kind:'group',value,span:{start:open.span.start,end:close.span.end}};
    }
    if(token.kind==='identifier'){
      this.context.cursor.consume();
      const reference:V061Expr={kind:'reference',name:token.text,span:token.span};
      const open=this.context.cursor.peek();
      if(open.text!=='('||!open.adjacentToPrevious)return reference;

      this.context.own('D-CALL');
      this.context.cursor.consume();
      const args:V061Expr[]=[];
      if(this.context.cursor.at(')')){
        const close=this.context.cursor.consume();
        args.push({kind:'unit',span:{start:open.span.start,end:close.span.end}});
        return {kind:'call',callee:token.text,args,span:{start:token.span.start,end:close.span.end}};
      }
      while(true){
        args.push(this.parse());
        if(!this.context.cursor.consumeIf(','))break;
      }
      const close=this.context.cursor.expect(')');
      return {kind:'call',callee:token.text,args,span:{start:token.span.start,end:close.span.end}};
    }

    throw new SyntaxError("expected expression, got '"+token.text+"'",token.span);
  }
}
