export type IrLiteral=null|boolean|string|number|bigint;

export type IrExpr =
  | {readonly kind:'literal';readonly value:IrLiteral}
  | {readonly kind:'var';readonly name:string}
  | {readonly kind:'lambda';readonly params:readonly string[];readonly body:IrExpr}
  | {readonly kind:'call';readonly fn:IrExpr;readonly args:readonly IrExpr[]}
  | {readonly kind:'let';readonly name:string;readonly value:IrExpr;readonly body:IrExpr}
  | {readonly kind:'if';readonly cond:IrExpr;readonly then:IrExpr;readonly else:IrExpr}
  | {readonly kind:'ctor';readonly tag:string;readonly fields:readonly IrExpr[]};

export interface IrBinding {readonly name:string;readonly value:IrExpr}
export interface IrModule {readonly name:string;readonly bindings:readonly IrBinding[]}

const validName=/^[A-Za-z_$][A-Za-z0-9_$]*$/;
export function assertIrName(name:string):void{
  if(!validName.test(name))throw new Error(`invalid IR identifier '${name}'`);
}

export function validateIrModule(module:IrModule):true{
  if(module.name.length===0)throw new Error('IR module name must be non-empty');
  const seen=new Set<string>();
  for(const binding of module.bindings){
    assertIrName(binding.name);
    if(seen.has(binding.name))throw new Error(`duplicate IR binding '${binding.name}'`);
    seen.add(binding.name);
    walkIr(binding.value,()=>{});
  }
  return true;
}

export function walkIr(expr:IrExpr,visit:(expr:IrExpr)=>void):void{
  visit(expr);
  switch(expr.kind){
    case 'literal':
    case 'var':
      return;
    case 'lambda':
      walkIr(expr.body,visit);return;
    case 'call':
      walkIr(expr.fn,visit);for(const arg of expr.args)walkIr(arg,visit);return;
    case 'let':
      walkIr(expr.value,visit);walkIr(expr.body,visit);return;
    case 'if':
      walkIr(expr.cond,visit);walkIr(expr.then,visit);walkIr(expr.else,visit);return;
    case 'ctor':
      for(const field of expr.fields)walkIr(field,visit);return;
  }
}

export function freeVariables(expr:IrExpr):readonly string[]{
  const free=new Set<string>();
  const go=(node:IrExpr,bound:Set<string>):void=>{
    switch(node.kind){
      case 'literal':return;
      case 'var':if(!bound.has(node.name))free.add(node.name);return;
      case 'lambda':{
        const next=new Set(bound);for(const param of node.params){assertIrName(param);next.add(param);}
        go(node.body,next);return;
      }
      case 'call':go(node.fn,bound);for(const arg of node.args)go(arg,bound);return;
      case 'let':{
        go(node.value,bound);
        const next=new Set(bound);assertIrName(node.name);next.add(node.name);
        go(node.body,next);return;
      }
      case 'if':go(node.cond,bound);go(node.then,bound);go(node.else,bound);return;
      case 'ctor':for(const field of node.fields)go(field,bound);return;
    }
  };
  go(expr,new Set());
  return [...free].sort();
}

export * from './software.js';

export * from './verified.js';
