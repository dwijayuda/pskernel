import {
  Environment,
  LocalContext,
  TypeChecker,
  type Expr,
  app,
  exprEq,
  hasLooseBVar,
  hasMVar,
} from 'lean-ts-kernel';

export type ExprMetavarKind='natural'|'synthetic'|'syntheticOpaque';

export interface ExprMetavarDecl {
  readonly id:string;
  readonly type:Expr;
  readonly localContext:LocalContext;
  readonly kind:ExprMetavarKind;
  readonly depth:number;
  readonly index:number;
}

function asMVarId(meta:Expr|string):string {
  if(typeof meta==='string')return meta;
  if(meta.kind!=='mvar')throw new Error('expected metavariable expression');
  return meta.id;
}

function containsMVarId(expr:Expr,id:string):boolean {
  switch(expr.kind){
    case 'mvar':return expr.id===id;
    case 'app':return containsMVarId(expr.fn,id)||containsMVarId(expr.arg,id);
    case 'lam':
    case 'forall':
      return containsMVarId(expr.type,id)||containsMVarId(expr.body,id);
    case 'let':
      return containsMVarId(expr.type,id)
        ||containsMVarId(expr.value,id)
        ||containsMVarId(expr.body,id);
    case 'mdata':return containsMVarId(expr.expr,id);
    case 'proj':return containsMVarId(expr.expr,id);
    default:return false;
  }
}

function collectMVarIds(expr:Expr,out:Set<string>=new Set()):ReadonlySet<string> {
  switch(expr.kind){
    case 'mvar':
      out.add(expr.id);
      break;
    case 'app':
      collectMVarIds(expr.fn,out);
      collectMVarIds(expr.arg,out);
      break;
    case 'lam':
    case 'forall':
      collectMVarIds(expr.type,out);
      collectMVarIds(expr.body,out);
      break;
    case 'let':
      collectMVarIds(expr.type,out);
      collectMVarIds(expr.value,out);
      collectMVarIds(expr.body,out);
      break;
    case 'mdata':
    case 'proj':
      collectMVarIds(expr.expr,out);
      break;
    default:
      break;
  }
  return out;
}

function assertFVarsInScope(expr:Expr,lctx:LocalContext):void {
  const visit=(value:Expr):void=>{
    switch(value.kind){
      case 'fvar':
        if(lctx.get(value.id)===undefined){
          throw new Error(
            "metavariable assignment references out-of-scope free variable '"+value.id+"'",
          );
        }
        return;
      case 'app':
        visit(value.fn);
        visit(value.arg);
        return;
      case 'lam':
      case 'forall':
        visit(value.type);
        visit(value.body);
        return;
      case 'let':
        visit(value.type);
        visit(value.value);
        visit(value.body);
        return;
      case 'mdata':
      case 'proj':
        visit(value.expr);
        return;
      default:
        return;
    }
  };
  visit(expr);
}

function rebuild(
  expr:Expr,
  instantiate:(expr:Expr,active:ReadonlySet<string>)=>Expr,
  active:ReadonlySet<string>,
):Expr {
  switch(expr.kind){
    case 'app':return app(
      instantiate(expr.fn,active),
      instantiate(expr.arg,active),
    );
    case 'lam':return {
      ...expr,
      type:instantiate(expr.type,active),
      body:instantiate(expr.body,active),
    };
    case 'forall':return {
      ...expr,
      type:instantiate(expr.type,active),
      body:instantiate(expr.body,active),
    };
    case 'let':return {
      ...expr,
      type:instantiate(expr.type,active),
      value:instantiate(expr.value,active),
      body:instantiate(expr.body,active),
    };
    case 'mdata':return {...expr,expr:instantiate(expr.expr,active)};
    case 'proj':return {...expr,expr:instantiate(expr.expr,active)};
    default:return expr;
  }
}

export class ExprMetaContext {
  private nextIndex=0;
  private currentDepth=0;
  private readonly declarations=new Map<string,ExprMetavarDecl>();
  private readonly assignments=new Map<string,Expr>();

  constructor(readonly environment:Environment){}

  withDepth<T>(action:()=>T):T {
    this.currentDepth+=1;
    try{return action();}
    finally{this.currentDepth-=1;}
  }

  mkFresh(
    type:Expr,
    localContext=new LocalContext(),
    kind:ExprMetavarKind='natural',
  ):Expr {
    const index=this.nextIndex++;
    const id='m.'+index;
    this.declarations.set(id,{
      id,
      type,
      localContext:localContext.clone(),
      kind,
      depth:this.currentDepth,
      index,
    });
    return {kind:'mvar',id};
  }

  findDecl(meta:Expr|string):ExprMetavarDecl|undefined {
    return this.declarations.get(asMVarId(meta));
  }

  getDecl(meta:Expr|string):ExprMetavarDecl {
    const id=asMVarId(meta);
    const declaration=this.declarations.get(id);
    if(declaration===undefined)throw new Error("unknown metavariable '?"+id+"'");
    return declaration;
  }

  isAssigned(meta:Expr|string):boolean {
    return this.assignments.has(asMVarId(meta));
  }

  getAssignment(meta:Expr|string):Expr|undefined {
    return this.assignments.get(asMVarId(meta));
  }

  instantiate(expr:Expr):Expr {
    const go=(value:Expr,active:ReadonlySet<string>):Expr=>{
      if(value.kind==='mvar'){
        const assigned=this.assignments.get(value.id);
        if(assigned===undefined)return value;
        if(active.has(value.id)){
          throw new Error("cyclic metavariable assignment at '?"+value.id+"'");
        }
        const next=new Set(active);
        next.add(value.id);
        return go(assigned,next);
      }
      return rebuild(value,go,active);
    };
    return go(expr,new Set());
  }

  private validateGroundAssignment(
    declaration:ExprMetavarDecl,
    value:Expr,
  ):void {
    const instantiatedValue=this.instantiate(value);
    const instantiatedType=this.instantiate(declaration.type);
    if(hasMVar(instantiatedValue)||hasMVar(instantiatedType))return;

    const checker=new TypeChecker(
      this.environment,
      declaration.localContext.clone(),
    );
    const actual=checker.check(instantiatedValue);
    if(!checker.isDefEq(actual,instantiatedType)){
      throw new Error(
        "metavariable '?"+declaration.id+"' assignment has incompatible type",
      );
    }
  }

  assign(meta:Expr|string,value:Expr):void {
    const declaration=this.getDecl(meta);
    if(this.assignments.has(declaration.id)){
      throw new Error("metavariable '?"+declaration.id+"' is already assigned");
    }

    const instantiated=this.instantiate(value);
    if(hasLooseBVar(instantiated)){
      throw new Error(
        "metavariable '?"+declaration.id+"' assignment contains a loose bound variable",
      );
    }
    if(containsMVarId(instantiated,declaration.id)){
      throw new Error("occurs check failed for '?"+declaration.id+"'");
    }
    assertFVarsInScope(instantiated,declaration.localContext);
    for(const dependencyId of collectMVarIds(instantiated)){
      const dependency=this.declarations.get(dependencyId);
      if(dependency===undefined){
        throw new Error(
          "metavariable '?"+declaration.id+
          "' assignment references unknown metavariable '?"+dependencyId+"'",
        );
      }
      if(dependency.depth>declaration.depth){
        throw new Error(
          "metavariable '?"+declaration.id+
          "' assignment depends on deeper metavariable '?"+dependencyId+"'",
        );
      }
    }
    this.validateGroundAssignment(declaration,instantiated);
    this.assignments.set(declaration.id,instantiated);
  }

  tryAssignByUnification(meta:Expr|string,value:Expr):boolean {
    const declaration=this.getDecl(meta);
    if(
      declaration.kind==='syntheticOpaque'
      ||declaration.depth!==this.currentDepth
    )return false;
    this.assign(declaration.id,value);
    return true;
  }

  unify(left:Expr,right:Expr,localContext=new LocalContext()):boolean {
    const lhs=this.instantiate(left);
    const rhs=this.instantiate(right);
    if(exprEq(lhs,rhs))return true;

    if(lhs.kind==='mvar'&&rhs.kind==='mvar'){
      const leftDecl=this.getDecl(lhs);
      const rightDecl=this.getDecl(rhs);
      if(
        leftDecl.kind==='synthetic'
        &&rightDecl.kind==='natural'
      ){
        return this.tryAssignByUnification(rhs,lhs);
      }
      if(
        rightDecl.kind==='synthetic'
        &&leftDecl.kind==='natural'
      ){
        return this.tryAssignByUnification(lhs,rhs);
      }
      if(this.tryAssignByUnification(lhs,rhs))return true;
      return this.tryAssignByUnification(rhs,lhs);
    }

    if(lhs.kind==='mvar')return this.tryAssignByUnification(lhs,rhs);
    if(rhs.kind==='mvar')return this.tryAssignByUnification(rhs,lhs);

    if(hasMVar(lhs)||hasMVar(rhs))return false;
    try{
      return new TypeChecker(
        this.environment,
        localContext.clone(),
      ).isDefEq(lhs,rhs);
    }catch{
      return false;
    }
  }

  validateGroundAssignments():void {
    for(const [id,value] of this.assignments){
      this.validateGroundAssignment(this.getDecl(id),value);
    }
  }

  snapshotAssignments():ReadonlyMap<string,Expr> {
    return new Map(this.assignments);
  }
}
