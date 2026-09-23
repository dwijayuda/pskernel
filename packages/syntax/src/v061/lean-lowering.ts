import type {V061Expr,V061Module} from './ast.js';
import {v061BinaryPrecedence} from './operators.js';
import {lowerV061TypeToLean} from './type-parser.js';

function precedence(expr:V061Expr):number {
  return expr.kind==='binary'?(v061BinaryPrecedence(expr.operator)??0):8;
}

export function lowerV061ExprToLean(expr:V061Expr,parentPrecedence=0):string {
  switch(expr.kind){
    case 'nat':return expr.text;
    case 'string':return JSON.stringify(expr.value);
    case 'bool':return expr.value?'true':'false';
    case 'unit':return '()';
    case 'reference':return expr.name;
    case 'group':return '('+lowerV061ExprToLean(expr.value)+')';
    case 'call':{
      const args=expr.args.map((arg)=>{
        const rendered=lowerV061ExprToLean(arg);
        return arg.kind==='reference'||arg.kind==='nat'||arg.kind==='string'||arg.kind==='bool'||arg.kind==='unit'
          ? rendered
          : '('+rendered+')';
      });
      return expr.callee+' '+args.join(' ');
    }
    case 'unary':return '!'+lowerV061ExprToLean(expr.operand,7);
    case 'binary':{
      const p=precedence(expr);
      const rendered=lowerV061ExprToLean(expr.left,p)+' '+expr.operator+' '+lowerV061ExprToLean(expr.right,p+1);
      return p<parentPrecedence?'('+rendered+')':rendered;
    }
    case 'if':
      return 'if '+lowerV061ExprToLean(expr.condition)+' then '+lowerV061ExprToLean(expr.thenBranch)+' else '+lowerV061ExprToLean(expr.elseBranch);
    case 'lambda':{
      const binders=expr.binders.map((binder)=>
        binder.type===undefined
          ? binder.name
          : '('+binder.name+' : '+lowerV061TypeToLean(binder.type)+')'
      ).join(' ');
      return 'fun '+binders+' => '+lowerV061ExprToLean(expr.body);
    }
    case 'let':{
      const annotation=expr.declaredType===undefined?'':' : '+lowerV061TypeToLean(expr.declaredType);
      return 'let '+expr.name+annotation+' := '+lowerV061ExprToLean(expr.value)+'; '+lowerV061ExprToLean(expr.body);
    }
  }
}

export function lowerV061ModuleToLean(module:V061Module):string {
  return module.declarations.map((decl)=>{
    const head=decl.kind==='function'||decl.kind==='const'?'def':decl.kind;
    const params=decl.params.map((p)=>' ('+p.name+' : '+lowerV061TypeToLean(p.type)+')').join('');
    return head+' '+decl.name+params+' : '+lowerV061TypeToLean(decl.resultType)+' := '+lowerV061ExprToLean(decl.body);
  }).join('\n\n')+'\n';
}
