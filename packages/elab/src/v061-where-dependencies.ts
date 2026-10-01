import type {
  V061Expr,
  V061TypeExpr,
  V061WhereDeclaration,
} from '@proofscript/syntax';

function collectTypeDependencies(
  type:V061TypeExpr,
  names:ReadonlySet<string>,
  out:Set<string>,
  bound:ReadonlySet<string>=new Set(),
):void {
  switch(type.kind){
    case 'nat':
    case 'bool':
      return;
    case 'named':
      if(names.has(type.name)&&!bound.has(type.name))out.add(type.name);
      return;
    case 'group':
      collectTypeDependencies(type.value,names,out,bound);
      return;
    case 'application':
      collectTypeDependencies(type.fn,names,out,bound);
      for(const arg of type.args){
        collectTypeDependencies(arg,names,out,bound);
      }
      return;
    case 'unary':
      collectTypeDependencies(type.operand,names,out,bound);
      return;
    case 'binary':
      collectTypeDependencies(type.left,names,out,bound);
      collectTypeDependencies(type.right,names,out,bound);
      return;
    case 'equality':
      collectTypeDependencies(type.left,names,out,bound);
      collectTypeDependencies(type.right,names,out,bound);
      return;
    case 'dependentArrow':{
      collectTypeDependencies(type.domain,names,out,bound);
      const next=new Set(bound);
      next.add(type.name);
      collectTypeDependencies(type.codomain,names,out,next);
      return;
    }
    case 'arrow':
      collectTypeDependencies(type.domain,names,out,bound);
      collectTypeDependencies(type.codomain,names,out,bound);
      return;
  }
}

function collectExprDependencies(
  expr:V061Expr,
  names:ReadonlySet<string>,
  bound:ReadonlySet<string>,
  out:Set<string>,
):void {
  const use=(name:string):void=>{
    if(names.has(name)&&!bound.has(name))out.add(name);
  };
  switch(expr.kind){
    case 'nat':
    case 'string':
    case 'char':
    case 'bool':
    case 'unit':
      return;
    case 'reference':
      use(expr.name);
      return;
    case 'group':
      collectExprDependencies(expr.value,names,bound,out);
      return;
    case 'call':
      use(expr.callee);
      for(const arg of expr.args){
        collectExprDependencies(arg,names,bound,out);
      }
      return;
    case 'unary':
      collectExprDependencies(expr.operand,names,bound,out);
      return;
    case 'binary':
      collectExprDependencies(expr.left,names,bound,out);
      collectExprDependencies(expr.right,names,bound,out);
      return;
    case 'if':
      collectExprDependencies(expr.condition,names,bound,out);
      collectExprDependencies(expr.thenBranch,names,bound,out);
      collectExprDependencies(expr.elseBranch,names,bound,out);
      return;
    case 'lambda':{
      const next=new Set(bound);
      for(const binder of expr.binders)next.add(binder.name);
      collectExprDependencies(expr.body,names,next,out);
      return;
    }
    case 'by':
      return;
    case 'record':
      for(const field of expr.fields){
        collectExprDependencies(field.value,names,bound,out);
      }
      return;
    case 'match':
      collectExprDependencies(expr.scrutinee,names,bound,out);
      for(const alternative of expr.alternatives){
        const next=new Set(bound);
        if(alternative.pattern.kind==='constructor'){
          for(const binder of alternative.pattern.binders)next.add(binder);
        }
        collectExprDependencies(alternative.body,names,next,out);
      }
      return;
    case 'let':{
      collectExprDependencies(expr.value,names,bound,out);
      const next=new Set(bound);
      next.add(expr.name);
      collectExprDependencies(expr.body,names,next,out);
      return;
    }
  }
}

export function orderedV061WhereDeclarations(
  declarations:readonly V061WhereDeclaration[],
):readonly V061WhereDeclaration[] {
  const byName=new Map<string,V061WhereDeclaration>();
  for(const declaration of declarations){
    if(byName.has(declaration.name)){
      throw new Error(
        "PS_ELAB_DUPLICATE_WHERE: duplicate local declaration '"+
        declaration.name+"'",
      );
    }
    byName.set(declaration.name,declaration);
  }

  const names=new Set(byName.keys());
  const deps=new Map<string,Set<string>>();
  for(const declaration of declarations){
    const refs=new Set<string>();
    for(const parameter of declaration.params){
      collectTypeDependencies(parameter.type,names,refs);
    }
    collectTypeDependencies(declaration.resultType,names,refs);
    collectExprDependencies(
      declaration.body,
      names,
      new Set(declaration.params.map((parameter)=>parameter.name)),
      refs,
    );
    deps.set(declaration.name,refs);
  }

  const visiting=new Set<string>();
  const visited=new Set<string>();
  const order:V061WhereDeclaration[]=[];
  const visit=(name:string,stack:readonly string[]):void=>{
    if(visited.has(name))return;
    if(visiting.has(name)){
      throw new Error(
        'PS_ELAB_WHERE_RECURSION_UNSUPPORTED: recursive where cycle '+
        [...stack,name].join(' -> ')+
        ' requires Lean-compatible termination elaboration',
      );
    }
    visiting.add(name);
    for(const dependency of deps.get(name)??[]){
      visit(dependency,[...stack,name]);
    }
    visiting.delete(name);
    visited.add(name);
    order.push(byName.get(name)!);
  };

  for(const declaration of declarations)visit(declaration.name,[]);
  return order;
}
