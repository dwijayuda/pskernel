import {
  type Expr,
  type Level,
  exprEq,
  levelEqStructural,
  levelEquivalent,
  levelHasMVar,
  levelMVar,
  levelSucc,
  mkIMax,
  mkMax,
  nameEq,
  nameFromDotted,
  nameKey,
} from 'lean-ts-kernel';

export class LevelMetaContext {
  private nextIndex=0;
  private readonly declarations=new Map<string,import('lean-ts-kernel').Name>();
  private readonly assignments=new Map<string,Level>();

  mkFresh():Level {
    const name=nameFromDotted('_u'+this.nextIndex++);
    this.declarations.set(nameKey(name),name);
    return levelMVar(name);
  }

  snapshot():ReadonlyMap<string,Level> {
    return new Map(this.assignments);
  }

  restore(snapshot:ReadonlyMap<string,Level>):void {
    this.assignments.clear();
    for(const [key,value] of snapshot)this.assignments.set(key,value);
  }

  private occurs(key:string,level:Level):boolean {
    const value=this.instantiate(level);
    switch(value.kind){
      case 'mvar':return nameKey(value.name)===key;
      case 'succ':return this.occurs(key,value.of);
      case 'max':
      case 'imax':
        return this.occurs(key,value.left)||this.occurs(key,value.right);
      default:return false;
    }
  }

  private assign(meta:Extract<Level,{kind:'mvar'}>,value:Level):boolean {
    const key=nameKey(meta.name);
    if(!this.declarations.has(key))return false;
    const resolved=this.instantiate(value);
    if(this.occurs(key,resolved))return false;
    this.assignments.set(key,resolved);
    return true;
  }

  instantiate(level:Level):Level {
    switch(level.kind){
      case 'mvar':{
        const assigned=this.assignments.get(nameKey(level.name));
        return assigned===undefined?level:this.instantiate(assigned);
      }
      case 'succ':return levelSucc(this.instantiate(level.of));
      case 'max':
        return mkMax(this.instantiate(level.left),this.instantiate(level.right));
      case 'imax':
        return mkIMax(this.instantiate(level.left),this.instantiate(level.right));
      default:return level;
    }
  }

  unify(left:Level,right:Level):boolean {
    const lhs=this.instantiate(left);
    const rhs=this.instantiate(right);
    if(levelEqStructural(lhs,rhs))return true;
    if(lhs.kind==='mvar')return this.assign(lhs,rhs);
    if(rhs.kind==='mvar')return this.assign(rhs,lhs);
    if(lhs.kind==='succ'&&rhs.kind==='succ'){
      return this.unify(lhs.of,rhs.of);
    }
    if(lhs.kind==='max'&&rhs.kind==='max'){
      return this.unify(lhs.left,rhs.left)
        &&this.unify(lhs.right,rhs.right);
    }
    if(lhs.kind==='imax'&&rhs.kind==='imax'){
      return this.unify(lhs.left,rhs.left)
        &&this.unify(lhs.right,rhs.right);
    }
    if(levelHasMVar(lhs)||levelHasMVar(rhs))return false;
    return levelEquivalent(lhs,rhs);
  }

  instantiateExpr(expr:Expr):Expr {
    switch(expr.kind){
      case 'sort':return {...expr,level:this.instantiate(expr.level)};
      case 'const':
        return {...expr,levels:expr.levels.map((level)=>this.instantiate(level))};
      case 'app':
        return {
          ...expr,
          fn:this.instantiateExpr(expr.fn),
          arg:this.instantiateExpr(expr.arg),
        };
      case 'lam':
      case 'forall':
        return {
          ...expr,
          type:this.instantiateExpr(expr.type),
          body:this.instantiateExpr(expr.body),
        };
      case 'let':
        return {
          ...expr,
          type:this.instantiateExpr(expr.type),
          value:this.instantiateExpr(expr.value),
          body:this.instantiateExpr(expr.body),
        };
      case 'mdata':
      case 'proj':
        return {...expr,expr:this.instantiateExpr(expr.expr)};
      default:return expr;
    }
  }

  hasUnresolvedExpr(expr:Expr):boolean {
    const value=this.instantiateExpr(expr);
    switch(value.kind){
      case 'sort':return levelHasMVar(value.level);
      case 'const':return value.levels.some(levelHasMVar);
      case 'app':
        return this.hasUnresolvedExpr(value.fn)
          ||this.hasUnresolvedExpr(value.arg);
      case 'lam':
      case 'forall':
        return this.hasUnresolvedExpr(value.type)
          ||this.hasUnresolvedExpr(value.body);
      case 'let':
        return this.hasUnresolvedExpr(value.type)
          ||this.hasUnresolvedExpr(value.value)
          ||this.hasUnresolvedExpr(value.body);
      case 'mdata':
      case 'proj':
        return this.hasUnresolvedExpr(value.expr);
      default:return false;
    }
  }

  unifyExprLevels(left:Expr,right:Expr):boolean {
    const lhs=this.instantiateExpr(left);
    const rhs=this.instantiateExpr(right);
    if(exprEq(lhs,rhs))return true;
    if(lhs.kind==='sort'&&rhs.kind==='sort'){
      return this.unify(lhs.level,rhs.level);
    }
    if(lhs.kind==='const'&&rhs.kind==='const'){
      if(!nameEq(lhs.name,rhs.name)||lhs.levels.length!==rhs.levels.length){
        return false;
      }
      return lhs.levels.every(
        (level,index)=>this.unify(level,rhs.levels[index]!),
      );
    }
    if(lhs.kind==='app'&&rhs.kind==='app'){
      return this.unifyExprLevels(lhs.fn,rhs.fn)
        &&this.unifyExprLevels(lhs.arg,rhs.arg);
    }
    if(
      (lhs.kind==='lam'&&rhs.kind==='lam')
      ||(lhs.kind==='forall'&&rhs.kind==='forall')
    ){
      return lhs.binderInfo===rhs.binderInfo
        &&this.unifyExprLevels(lhs.type,rhs.type)
        &&this.unifyExprLevels(lhs.body,rhs.body);
    }
    if(lhs.kind==='let'&&rhs.kind==='let'){
      return this.unifyExprLevels(lhs.type,rhs.type)
        &&this.unifyExprLevels(lhs.value,rhs.value)
        &&this.unifyExprLevels(lhs.body,rhs.body);
    }
    if(lhs.kind==='mdata')return this.unifyExprLevels(lhs.expr,rhs);
    if(rhs.kind==='mdata')return this.unifyExprLevels(lhs,rhs.expr);
    if(lhs.kind==='proj'&&rhs.kind==='proj'){
      return lhs.index===rhs.index
        &&nameEq(lhs.typeName,rhs.typeName)
        &&this.unifyExprLevels(lhs.expr,rhs.expr);
    }
    return false;
  }

  validateResolved():void {
    for(const name of this.declarations.values()){
      const value=this.instantiate(levelMVar(name));
      if(levelHasMVar(value)){
        throw new Error(
          "unresolved universe metavariable '?"+nameKey(name)+"'",
        );
      }
    }
  }
}
