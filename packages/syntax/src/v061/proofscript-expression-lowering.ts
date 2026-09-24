import type {
  V061Expr,
  V061Tactic,
} from './ast.js';
import type {V061Pattern} from './pattern-parser.js';
import {v061BinaryPrecedence} from './operators.js';
import {lowerV061TypeToProofScript} from './proofscript-type-lowering.js';

const PRIMARY_PRECEDENCE=8;
const UNARY_PRECEDENCE=7;

type V061CallExpr=Extract<V061Expr,{readonly kind:'call'}>;

function psxStringArg(
  expr:V061Expr|undefined,
  label:string,
):string {
  if(expr?.kind!=='string'){
    throw new Error(
      'PS_PRINT_JSX_INTERNAL: expected string '+label,
    );
  }
  return expr.value;
}

function asPsxCall(
  expr:V061Expr|undefined,
  callee:string,
):V061CallExpr|undefined {
  return expr?.kind==='call'&&expr.callee===callee
    ?expr
    :undefined;
}

function lowerPsxChild(expr:V061Expr):string {
  const text=asPsxCall(expr,'$psx.text');
  if(text!==undefined){
    return psxStringArg(text.args[0],'text');
  }
  const expressionChild=asPsxCall(expr,'$psx.child');
  if(expressionChild!==undefined){
    const child=expressionChild.args[0];
    if(child===undefined){
      throw new Error('PS_PRINT_JSX_INTERNAL: missing expression child');
    }
    return '{'+lowerV061ExprToProofScript(child)+'}';
  }
  const element=
    asPsxCall(expr,'$psx.element')
    ??asPsxCall(expr,'$psx.fragment');
  if(element!==undefined){
    return lowerPsxCall(element);
  }
  throw new Error(
    'PS_PRINT_JSX_INTERNAL: unexpected JSX child representation',
  );
}

function lowerPsxCall(expr:V061CallExpr):string {
  if(expr.callee==='$psx.fragment'){
    return '<>'+expr.args.map(lowerPsxChild).join('')+'</>';
  }
  if(expr.callee!=='$psx.element'){
    throw new Error(
      "PS_PRINT_JSX_INTERNAL: unsupported internal call '"+expr.callee+"'",
    );
  }
  const tag=psxStringArg(expr.args[0],'tag');
  psxStringArg(expr.args[1],'tag kind');
  const attributes:string[]=[];
  const children:V061Expr[]=[];
  for(const item of expr.args.slice(2)){
    const attribute=asPsxCall(item,'$psx.attr');
    if(attribute!==undefined){
      const name=psxStringArg(attribute.args[0],'attribute name');
      const value=attribute.args[1];
      if(value===undefined){
        throw new Error(
          'PS_PRINT_JSX_INTERNAL: missing attribute value',
        );
      }
      attributes.push(
        name+'='+
        (value.kind==='string'
          ?JSON.stringify(value.value)
          :'{'+lowerV061ExprToProofScript(value)+'}'),
      );
    }else{
      children.push(item);
    }
  }
  const attrs=attributes.length===0?'':' '+attributes.join(' ');
  if(children.length===0)return '<'+tag+attrs+' />';
  return '<'+tag+attrs+'>'+
    children.map(lowerPsxChild).join('')+
    '</'+tag+'>';
}

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
      rendered='('+lowerV061ExprToProofScript(expr.value)+')';
      break;
    case 'call':{
      if(expr.callee.startsWith('$psx.')){
        rendered=lowerPsxCall(expr);
        break;
      }
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
