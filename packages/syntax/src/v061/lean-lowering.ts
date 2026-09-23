import type {V061Expr,V061Module} from './ast.js';
import {v061BinaryPrecedence} from './operators.js';
import {lowerV061TypeToLean} from './type-lowering.js';
import {lowerV061PatternToLean} from './pattern-parser.js';

function lowerV061ParameterToLean(
  parameter:import('./ast.js').V061Parameter,
):string {
  const rendered=parameter.name+' : '+lowerV061TypeToLean(parameter.type);
  switch(parameter.binderInfo??'default'){
    case 'default':return '('+rendered+')';
    case 'implicit':return '{'+rendered+'}';
    case 'strictImplicit':return '{{'+rendered+'}}';
    case 'instImplicit':return '['+rendered+']';
  }
}

function lowerV061FieldToLean(
  field:import('./ast.js').V061StructureField,
):string {
  const rendered=field.name+' : '+lowerV061TypeToLean(field.type);
  switch(field.binderKind){
    case 'explicit':return '  '+rendered;
    case 'implicit':return '  {'+rendered+'}';
    case 'instance':return '  ['+rendered+']';
  }
}

function lowerV061TacticToLean(
  tactic:import('./ast.js').V061Tactic,
):string {
  switch(tactic.kind){
    case 'exact':return 'exact '+lowerV061ExprToLean(tactic.proof);
    case 'exactSearch':return 'exact?';
    case 'assumption':return 'assumption';
    case 'constructor':return 'constructor';
    case 'cases':return 'cases '+tactic.target;
    case 'induction':return 'induction '+tactic.target;
    case 'rw':
      return 'rw ['+(tactic.symm?'← ':'')+
        lowerV061ExprToLean(tactic.proof)+']';
    case 'simp':
      return 'simp only ['+
        tactic.rules.map((rule)=>
          (rule.symm?'← ':'')+lowerV061ExprToLean(rule.proof)
        ).join(', ')+']';
    case 'apply':return 'apply '+lowerV061ExprToLean(tactic.proof);
    case 'refine':return 'refine '+lowerV061ExprToLean(tactic.proof);
    case 'intro':return 'intro '+tactic.name;
  }
}

function precedence(expr:V061Expr):number {
  return expr.kind==='binary'?(v061BinaryPrecedence(expr.operator)??0):8;
}

export function lowerV061ExprToLean(expr:V061Expr,parentPrecedence=0):string {
  switch(expr.kind){
    case 'nat':return expr.text;
    case 'string':return JSON.stringify(expr.value);
    case 'bool':return expr.value?'true':'false';
    case 'unit':return '()';
    case 'syntheticHole':return '?_';
    case 'reference':return expr.name;
    case 'group':return '('+lowerV061ExprToLean(expr.value)+')';
    case 'call':{
      const args=expr.args.map((arg)=>{
        const rendered=lowerV061ExprToLean(arg);
        return arg.kind==='reference'||arg.kind==='nat'||arg.kind==='string'||arg.kind==='bool'||arg.kind==='unit'||arg.kind==='syntheticHole'||arg.kind==='group'
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
    case 'record':{
      const fields=expr.fields.map(
        (field)=>field.name+' := '+lowerV061ExprToLean(field.value),
      ).join(', ');
      return '{ '+fields+' : '+lowerV061TypeToLean(expr.type)+' }';
    }
    case 'match':{
      const alternatives=expr.alternatives.map(
        (alt)=>'  | '+lowerV061PatternToLean(alt.pattern)+' => '+lowerV061ExprToLean(alt.body),
      ).join('\n');
      return 'match '+lowerV061ExprToLean(expr.scrutinee)+' with\n'+alternatives;
    }
    case 'by':
      return 'by '+expr.tactics.map(lowerV061TacticToLean).join('; ');
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
  const declarations=module.declarations.map((decl)=>{
    if(decl.kind==='structure'){
      const params=decl.params.map(
        (param)=>' '+lowerV061ParameterToLean(param),
      ).join('');
      const fields=decl.fields.map(lowerV061FieldToLean).join('\n');
      return 'structure '+decl.name+params+' where\n'+fields;
    }
    if(decl.kind==='class'){
      const params=decl.params.map(
        (param)=>' '+lowerV061ParameterToLean(param),
      ).join('');
      const fields=decl.fields.map(lowerV061FieldToLean).join('\n');
      return 'class '+decl.name+params+' where\n'+fields;
    }
    if(decl.kind==='external'){
      const params=decl.params.map(
        (param)=>' '+lowerV061ParameterToLean(param),
      ).join('');
      return 'axiom '+decl.name+params+' : '+
        lowerV061TypeToLean(decl.resultType);
    }
    if(decl.kind==='instance'){
      const name=decl.anonymous?'':' '+decl.name;
      const params=decl.params.map(
        (param)=>' '+lowerV061ParameterToLean(param),
      ).join('');
      return 'instance'+name+params+' : '+
        lowerV061TypeToLean(decl.resultType)+' := '+
        lowerV061ExprToLean(decl.body);
    }
    if(decl.kind==='inductive'){
      const params=decl.params.map(
        (param)=>' '+lowerV061ParameterToLean(param),
      ).join('');
      const result=decl.resultType===undefined
        ? ''
        : ' : '+lowerV061TypeToLean(decl.resultType);
      const constructors=decl.constructors.map((ctor)=>{
        const ctorParams=ctor.params.map(
          (param)=>' '+lowerV061ParameterToLean(param),
        ).join('');
        return '  | '+ctor.name+ctorParams;
      }).join('\n');
      return 'inductive '+decl.name+params+result+' where\n'+constructors;
    }
    const head=decl.kind==='function'||decl.kind==='const'?'def':decl.kind;
    const params=decl.params.map(
      (p)=>' '+lowerV061ParameterToLean(p),
    ).join('');
    const base=head+' '+decl.name+params+' : '+
      lowerV061TypeToLean(decl.resultType)+' := '+lowerV061ExprToLean(decl.body);
    const whereDeclarations=decl.whereDeclarations??[];
    if(whereDeclarations.length===0)return base;
    const locals=whereDeclarations.map((local)=>{
      const localParams=local.params.map(
        (p)=>' '+lowerV061ParameterToLean(p),
      ).join('');
      return '  '+local.name+localParams+' : '+
        lowerV061TypeToLean(local.resultType)+' := '+
        lowerV061ExprToLean(local.body);
    }).join('\n');
    return base+' where\n'+locals;
  }).join('\n\n');
  const imports=(module.imports??[])
    .map((name)=>'import '+name)
    .join('\n');
  const sections=[imports,declarations]
    .filter((section)=>section.length>0);
  return sections.length===0?'':sections.join('\n\n')+'\n';
}
