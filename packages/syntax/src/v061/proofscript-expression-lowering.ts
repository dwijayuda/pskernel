import type {
  V061Expr,
  V061Tactic,
} from './ast.js';
import type {V061Pattern} from './pattern-parser.js';
import {v061BinaryPrecedence} from './operators.js';
import {lowerV061TypeToProofScript} from './proofscript-type-lowering.js';
import {quoteV061Char} from './char-literal.js';

const PRIMARY_PRECEDENCE=8;
const UNARY_PRECEDENCE=7;

function wrap(
  rendered:string,
  precedence:number,
  parentPrecedence:number,
):string {
  return precedence<parentPrecedence?'('+rendered+')':rendered;
}

function lowerPattern(pattern:V061Pattern):string {
  switch(pattern.kind){
    case 'bool':
      return pattern.value?'true':'false';
    case 'wildcard':
      return '_';
    case 'constructor':
      return pattern.binders.length===0
        ?pattern.name
        :pattern.name+' '+pattern.binders.join(' ');
  }
}

function lowerTactic(tactic:V061Tactic):string {
  switch(tactic.kind){
    case 'exact':
      return 'exact '+lowerV061ExprToProofScript(tactic.proof);
    case 'exactSearch':
      return 'exact?';
    case 'assumption':
      return 'assumption';
    case 'rfl':
      return 'rfl';
    case 'constructor':
      return 'constructor';
    case 'cases':
      return 'cases '+tactic.target;
    case 'induction':
      return 'induction '+tactic.target;
    case 'rw':
      return 'rw ['+(tactic.symm?'← ':'')+
        lowerV061ExprToProofScript(tactic.proof)+']';
    case 'simp':
      return 'simp only ['+
        tactic.rules.map((rule)=>
          (rule.symm?'← ':'')+
          lowerV061ExprToProofScript(rule.proof)
        ).join(', ')+']';
    case 'apply':
      return 'apply '+lowerV061ExprToProofScript(tactic.proof);
    case 'refine':
      return 'refine '+lowerV061ExprToProofScript(tactic.proof);
    case 'intro':
      return 'intro '+tactic.name;
  }
}

function expressionPrecedence(expr:V061Expr):number {
  if(expr.kind==='binary'){
    return v061BinaryPrecedence(expr.operator)??0;
  }
  if(expr.kind==='unary')return UNARY_PRECEDENCE;
  switch(expr.kind){
    case 'nat':
    case 'string':
    case 'char':
    case 'bool':
    case 'unit':
    case 'syntheticHole':
    case 'reference':
    case 'group':
    case 'call':
    case 'record':
      return PRIMARY_PRECEDENCE;
    default:
      return 0;
  }
}

export function lowerV061ExprToProofScript(
  expr:V061Expr,
  parentPrecedence=0,
):string {
  const precedence=expressionPrecedence(expr);
  let rendered:string;
  switch(expr.kind){
    case 'nat':
      rendered=expr.text;
      break;
    case 'string':
      rendered=JSON.stringify(expr.value);
      break;
    case 'char':
      rendered=quoteV061Char(expr.value);
      break;
    case 'bool':
      rendered=expr.value?'true':'false';
      break;
    case 'unit':
      rendered='()';
      break;
    case 'syntheticHole':
      rendered='?_';
      break;
    case 'reference':
      rendered=expr.name;
      break;
    case 'group':
      return lowerV061ExprToProofScript(
        expr.value,
        parentPrecedence,
      );
    case 'call':{
      const args=
        expr.args.length===1&&expr.args[0]?.kind==='unit'
          ?''
          :expr.args.map(
            (arg)=>lowerV061ExprToProofScript(arg),
          ).join(', ');
      rendered=expr.callee+'('+args+')';
      break;
    }
    case 'unary':
      rendered='!'+
        lowerV061ExprToProofScript(expr.operand,UNARY_PRECEDENCE);
      break;
    case 'binary':
      rendered=
        lowerV061ExprToProofScript(expr.left,precedence)+' '+
        expr.operator+' '+
        lowerV061ExprToProofScript(expr.right,precedence+1);
      break;
    case 'if':
      rendered=
        'if ('+lowerV061ExprToProofScript(expr.condition)+') { '+
        lowerV061ExprToProofScript(expr.thenBranch)+' } else { '+
        lowerV061ExprToProofScript(expr.elseBranch)+' }';
      break;
    case 'record':
      rendered=
        '{ '+
        expr.fields.map(
          (field)=>field.name+' := '+
            lowerV061ExprToProofScript(field.value),
        ).join(', ')+
        ' : '+lowerV061TypeToProofScript(expr.type)+' }';
      break;
    case 'match':
      rendered=
        'match '+lowerV061ExprToProofScript(expr.scrutinee)+' with { '+
        expr.alternatives.map(
          (alt)=>'| '+lowerPattern(alt.pattern)+' => '+
            lowerV061ExprToProofScript(alt.body)+';',
        ).join(' ')+
        ' }';
      break;
    case 'by':
      rendered='by '+expr.tactics.map(lowerTactic).join('; ');
      break;
    case 'lambda':
      rendered=
        'fun '+
        expr.binders.map((binder)=>
          binder.type===undefined
            ?binder.name
            :'('+binder.name+' : '+
              lowerV061TypeToProofScript(binder.type)+')',
        ).join(' ')+
        ' => '+lowerV061ExprToProofScript(expr.body);
      break;
    case 'let':
      rendered=
        'let '+expr.name+
        (expr.declaredType===undefined
          ?''
          :' : '+lowerV061TypeToProofScript(expr.declaredType))+
        ' := '+lowerV061ExprToProofScript(expr.value)+
        '; '+lowerV061ExprToProofScript(expr.body);
      break;
  }
  return wrap(rendered,precedence,parentPrecedence);
}
