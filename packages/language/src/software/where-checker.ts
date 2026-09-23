import type {
  V061Expr,
  V061ValueDeclaration,
  V061WhereDeclaration,
} from '@proofscript/syntax';
import type {SoftwareExpressionContext} from './check-context.js';
import {nominalTypeNames} from './check-context.js';
import type {
  CheckedSoftwareLocalDeclaration,
  SoftwareSignature,
  SoftwareType,
} from './types.js';
import {softwareTypeEquals,softwareTypeToString} from './types.js';
import {asSoftwareType} from './type-conversion.js';
import {checkSoftwareExpr} from './expression-checker.js';

function collectDependencies(
  expr:V061Expr,
  localNames:ReadonlySet<string>,
  out:Set<string>,
):void {
  switch(expr.kind){
    case 'nat':
    case 'string':
    case 'bool':
    case 'unit':
      return;
    case 'reference':
      if(localNames.has(expr.name))out.add(expr.name);
      return;
    case 'group':
      collectDependencies(expr.value,localNames,out);
      return;
    case 'call':
      if(localNames.has(expr.callee))out.add(expr.callee);
      for(const arg of expr.args)collectDependencies(arg,localNames,out);
      return;
    case 'unary':
      collectDependencies(expr.operand,localNames,out);
      return;
    case 'binary':
      collectDependencies(expr.left,localNames,out);
      collectDependencies(expr.right,localNames,out);
      return;
    case 'if':
      collectDependencies(expr.condition,localNames,out);
      collectDependencies(expr.thenBranch,localNames,out);
      collectDependencies(expr.elseBranch,localNames,out);
      return;
    case 'lambda':
      collectDependencies(expr.body,localNames,out);
      return;
    case 'record':
      for(const field of expr.fields)collectDependencies(field.value,localNames,out);
      return;
    case 'match':
      collectDependencies(expr.scrutinee,localNames,out);
      for(const alternative of expr.alternatives){
        collectDependencies(alternative.body,localNames,out);
      }
      return;
    case 'let':
      collectDependencies(expr.value,localNames,out);
      collectDependencies(expr.body,localNames,out);
      return;
  }
}

function topologicalWhereOrder(
  declarations:readonly V061WhereDeclaration[],
):readonly V061WhereDeclaration[] {
  const byName=new Map<string,V061WhereDeclaration>();
  for(const declaration of declarations){
    if(byName.has(declaration.name)){
      throw new Error(
        "PS_CHECK_DUPLICATE_WHERE: duplicate local declaration '"+declaration.name+"'",
      );
    }
    byName.set(declaration.name,declaration);
  }

  const names=new Set(byName.keys());
  const dependencies=new Map<string,Set<string>>();
  for(const declaration of declarations){
    const refs=new Set<string>();
    collectDependencies(declaration.body,names,refs);
    dependencies.set(declaration.name,refs);
  }

  const visiting=new Set<string>();
  const visited=new Set<string>();
  const order:V061WhereDeclaration[]=[];
  const visit=(name:string,stack:readonly string[]):void=>{
    if(visited.has(name))return;
    if(visiting.has(name)){
      throw new Error(
        'PS_CHECK_WHERE_RECURSION_UNSUPPORTED: recursive where cycle '+
        [...stack,name].join(' -> ')+
        ' requires Lean-compatible termination elaboration',
      );
    }
    visiting.add(name);
    for(const dependency of dependencies.get(name)??[]){
      visit(dependency,[...stack,name]);
    }
    visiting.delete(name);
    visited.add(name);
    order.push(byName.get(name)!);
  };

  for(const declaration of declarations)visit(declaration.name,[]);
  return order;
}

function localSignature(
  declaration:V061WhereDeclaration,
  nominalNames:ReadonlySet<string>,
):SoftwareSignature {
  return {
    params:declaration.params.map(
      (param)=>asSoftwareType(param.type,nominalNames),
    ),
    result:asSoftwareType(declaration.resultType,nominalNames),
  };
}

export function checkValueDeclarationWithWhere(
  declaration:V061ValueDeclaration,
  context:SoftwareExpressionContext,
  expected:SoftwareType,
):{
  readonly body:ReturnType<typeof checkSoftwareExpr>;
  readonly whereDeclarations:readonly CheckedSoftwareLocalDeclaration[];
} {
  const sourceLocals=declaration.whereDeclarations??[];
  if(sourceLocals.length===0){
    return {
      body:checkSoftwareExpr(declaration.body,context,expected),
      whereDeclarations:[],
    };
  }

  const ordered=topologicalWhereOrder(sourceLocals);
  const names=nominalTypeNames(context);
  const signatures=new Map(context.signatures);

  for(const local of ordered){
    if(context.locals.has(local.name)){
      throw new Error(
        "PS_CHECK_WHERE_SHADOW_PARAM: local declaration '"+local.name+
        "' conflicts with an enclosing parameter/local",
      );
    }
    if(signatures.has(local.name)){
      throw new Error(
        "PS_CHECK_WHERE_SHADOW_DECL: local declaration '"+local.name+
        "' conflicts with an existing declaration",
      );
    }
    signatures.set(local.name,localSignature(local,names));
  }

  const whereContext={...context,signatures};
  const checkedLocals=ordered.map((local)=>{
    const signature=signatures.get(local.name)!;
    const locals=new Map(context.locals);
    const params=local.params.map((param,index)=>{
      if(locals.has(param.name)){
        throw new Error(
          "PS_CHECK_DUPLICATE_PARAM: duplicate local parameter '"+param.name+"'",
        );
      }
      const type=signature.params[index]!;
      locals.set(param.name,type);
      return {name:param.name,type};
    });

    const body=checkSoftwareExpr(
      local.body,
      {...whereContext,locals},
      signature.result,
    );
    if(!softwareTypeEquals(body.resultType,signature.result)){
      throw new Error(
        'PS_CHECK_WHERE_TYPE: '+local.name+' expects '+
        softwareTypeToString(signature.result)+', got '+
        softwareTypeToString(body.resultType),
      );
    }
    return {
      name:local.name,
      params,
      resultType:signature.result,
      body,
    };
  });

  return {
    body:checkSoftwareExpr(declaration.body,whereContext,expected),
    whereDeclarations:checkedLocals,
  };
}
