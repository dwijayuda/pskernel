import {SyntaxError,type Token} from '../source.js';
import type {
  V061Expr,
  V061LambdaBinder,
} from './ast.js';
import {V061ParseContext,spanBetween} from './context.js';
import {v061LeanSubsetBinaryPrecedence} from './operators.js';
import {parseV061LeanSubsetMatch} from './lean-subset-match-parser.js';
import {parseV061RecordExpression} from './record-parser.js';
import {parseV061ByExpression} from './tactic-parser.js';
import {parseV061Type} from './type-parser.js';

const RESERVED_APPLICATION_HEADS=new Set([
  'def','theorem','structure','class','instance','inductive',
  'namespace','end','section','open','variable','axiom','opaque','abbrev',
  'example','macro','syntax','elab','attribute','noncomputable',
  'private','protected','partial',
  'where','then','else','with','by',
]);

function canStartLeanAtom(token:Token):boolean {
  if(token.kind==='number'||token.kind==='string'||token.kind==='char')return true;
  if(
    token.text==='('||token.text==='['||token.text==='?'||token.text==='.'||
    token.text==='true'||token.text==='false'
  ){
    return true;
  }
  return token.kind==='identifier'&&!RESERVED_APPLICATION_HEADS.has(token.text);
}

export class V061LeanSubsetExpressionParser {
  constructor(readonly context:V061ParseContext){}

  parse(minPrecedence=0):V061Expr {
    let left=this.parsePrefix();
    while(true){
      const op=this.context.cursor.peek();
      const precedence=v061LeanSubsetBinaryPrecedence(op.text);
      if(precedence===undefined||precedence<minPrecedence)break;
      this.context.cursor.consume();
      const right=this.parse(precedence+1);
      left={
        kind:'binary',
        operator:op.text,
        left,
        right,
        span:spanBetween(left,right),
      };
    }
    return left;
  }

  private parsePrefix():V061Expr {
    if(this.context.cursor.at('by')){
      return parseV061ByExpression(this.context,this);
    }
    if(this.context.cursor.at('fun'))return this.parseLambda();
    if(this.context.cursor.at('let'))return this.parseLet();
    if(this.context.cursor.at('if'))return this.parseIf();
    if(this.context.cursor.at('match')){
      return parseV061LeanSubsetMatch(
        this.context,
        ()=>this.parse(),
      );
    }
    if(this.context.cursor.at('{')){
      return parseV061RecordExpression(
        this.context,
        ()=>this.parse(),
      );
    }
    if(this.context.cursor.at('!')){
      const first=this.context.cursor.consume();
      const operand=this.parse(7);
      return {
        kind:'unary',
        operator:'!',
        operand,
        span:spanBetween(first,operand),
      };
    }
    return this.parseApplication();
  }

  private parseApplication():V061Expr {
    const first=this.parsePrimary();
    if(first.kind!=='reference')return first;

    const args:V061Expr[]=[];
    while(
      this.context.cursor.peek().leadingTrivia.length>0
      &&canStartLeanAtom(this.context.cursor.peek())
    ){
      args.push(this.parsePrimary());
    }
    if(args.length===0)return first;
    return {
      kind:'call',
      callee:first.name,
      args,
      span:{start:first.span.start,end:args[args.length-1]!.span.end},
    };
  }

  private parseListLiteral():V061Expr {
    const open=this.context.cursor.expect('[');
    const items:V061Expr[]=[];
    if(!this.context.cursor.at(']')){
      while(true){
        items.push(this.parse());
        if(!this.context.cursor.consumeIf(','))break;
      }
    }
    const close=this.context.cursor.expect(']');
    let result:V061Expr={
      kind:'reference',
      name:'List.nil',
      span:{start:open.span.start,end:close.span.end},
    };
    for(let index=items.length-1;index>=0;index-=1){
      const item=items[index]!;
      result={
        kind:'call',
        callee:'List.cons',
        args:[item,result],
        span:{start:item.span.start,end:close.span.end},
      };
    }
    return result;
  }

  private parseLambda():V061Expr {
    const first=this.context.cursor.expect('fun');
    const binders:V061LambdaBinder[]=[];
    while(!this.context.cursor.at('=>')){
      const token=this.context.cursor.peek();
      if(token.text==='('){
        const open=this.context.cursor.consume();
        const name=this.context.cursor.expectKind(
          'identifier',
          'Lean lambda binder name',
        );
        this.context.cursor.expect(':');
        const type=parseV061Type(this.context);
        const close=this.context.cursor.expect(')');
        binders.push({
          name:name.text,
          type,
          span:{start:open.span.start,end:close.span.end},
        });
        continue;
      }
      if(token.kind==='identifier'){
        const name=this.context.cursor.consume();
        binders.push({name:name.text,span:name.span});
        continue;
      }
      throw new SyntaxError(
        "PS_LEAN_SUBSET_LAMBDA: expected binder or '=>', got '"+token.text+"'",
        token.span,
      );
    }
    if(binders.length===0){
      throw new SyntaxError(
        'PS_LEAN_SUBSET_LAMBDA: lambda requires at least one binder',
        first.span,
      );
    }
    this.context.cursor.expect('=>');
    const body=this.parse();
    return {
      kind:'lambda',
      binders,
      body,
      span:{start:first.span.start,end:body.span.end},
    };
  }

  private parseLet():V061Expr {
    const first=this.context.cursor.expect('let');
    const name=this.context.cursor.expectKind(
      'identifier',
      'Lean let binding name',
    );
    const declaredType=this.context.cursor.consumeIf(':')
      ?parseV061Type(this.context)
      :undefined;
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
    const condition=this.parse();
    this.context.cursor.expect('then');
    const thenBranch=this.parse();
    this.context.cursor.expect('else');
    const elseBranch=this.parse();
    return {
      kind:'if',
      condition,
      thenBranch,
      elseBranch,
      span:{start:first.span.start,end:elseBranch.span.end},
    };
  }

  private parsePrimary():V061Expr {
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
      return {
        kind:'string',
        value:token.value??'',
        span:token.span,
      };
    }
    if(token.kind==='char'){
      this.context.cursor.consume();
      return {
        kind:'char',
        value:token.value??'',
        span:token.span,
      };
    }
    if(token.text==='['){
      return this.parseListLiteral();
    }
    if(token.text==='.'){
      const dot=this.context.cursor.consume();
      const ctor=this.context.cursor.expectKind(
        'identifier',
        'Lean constructor shorthand',
      );
      return {
        kind:'reference',
        name:'.'+ctor.text,
        span:{start:dot.span.start,end:ctor.span.end},
      };
    }
    if(token.text==='true'||token.text==='false'){
      this.context.cursor.consume();
      return {
        kind:'bool',
        value:token.text==='true',
        span:token.span,
      };
    }
    if(token.text==='('){
      const open=this.context.cursor.consume();
      if(this.context.cursor.at(')')){
        const close=this.context.cursor.consume();
        return {
          kind:'unit',
          span:{start:open.span.start,end:close.span.end},
        };
      }
      const value=this.parse();
      const close=this.context.cursor.expect(')');
      return {
        kind:'group',
        value,
        span:{start:open.span.start,end:close.span.end},
      };
    }
    if(token.kind==='identifier'&&!RESERVED_APPLICATION_HEADS.has(token.text)){
      this.context.cursor.consume();
      return {
        kind:'reference',
        name:token.text,
        span:token.span,
      };
    }
    throw new SyntaxError(
      "PS_LEAN_SUBSET_TERM: unsupported Lean term token '"+token.text+"'",
      token.span,
    );
  }
}
