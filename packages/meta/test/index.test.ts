import {
  ExprMetaContext,
  MetaVarContext,
  checkExpectedType,
  createGoal,
} from '../src/index.js';
import {
  Environment,
  Kernel,
  LocalContext,
  app,
  constant,
  exprEq,
  forallE,
  fvar,
  levelSucc,
  levelZero,
  mkAppN,
  levelEqStructural,
  nameFromDotted,
  sort,
} from 'lean-ts-kernel';
function equal(a:unknown,b:unknown):void{if(a!==b)throw new Error(`expected ${String(b)}, got ${String(a)}`);}
{
  const context=new MetaVarContext<string>();
  const goal=createGoal(context,'Nat',[{name:'x',type:'Nat'}]);
  equal(goal.mvar.id,0);
  context.assign(goal.mvar,'x');
  equal(context.getAssignment(goal.mvar),'x');
  let threw=false;
  try{context.assign(goal.mvar,'y');}catch{threw=true;}
  equal(threw,true);
}
{
  const kernel={inferType:(term:string)=>term==='zero'?'Nat':'Unknown',isDefEq:(a:string,b:string)=>a===b};
  equal(checkExpectedType(kernel,'zero','Nat'),true);
}
console.log('ok - @proofscript/meta foundation');


{
  const environment=new Environment();
  const context=new ExprMetaContext(environment);
  const sort0=sort(levelZero);
  const sort1=sort(levelSucc(levelZero));
  const meta=context.mkFresh(sort1);
  context.assign(meta,sort0);
  equal(exprEq(context.instantiate(meta),sort0),true);
  context.validateGroundAssignments();
}
{
  const environment=new Environment();
  const context=new ExprMetaContext(environment);
  const sort1=sort(levelSucc(levelZero));
  const meta=context.mkFresh(sort1);
  let occurs=false;
  try{
    context.assign(meta,{kind:'app',fn:meta,arg:sort(levelZero)});
  }catch(error){occurs=/occurs check failed/.test(String(error));}
  equal(occurs,true);
}
{
  const environment=new Environment();
  const context=new ExprMetaContext(environment);
  const type=sort(levelSucc(levelZero));
  const opaque=context.mkFresh(type,new LocalContext(),'syntheticOpaque');
  equal(context.tryAssignByUnification(opaque,sort(levelZero)),false);
  context.assign(opaque,sort(levelZero));
  equal(context.isAssigned(opaque),true);
}
{
  const environment=new Environment();
  const context=new ExprMetaContext(environment);
  const type=sort(levelSucc(levelZero));
  const natural=context.mkFresh(type,new LocalContext(),'natural');
  const synthetic=context.mkFresh(type,new LocalContext(),'synthetic');
  equal(context.unify(synthetic,natural),true);
  equal(exprEq(context.getAssignment(natural)!,synthetic),true);
}
{
  const environment=new Environment();
  const locals=new LocalContext();
  locals.addLocal('x',nameFromDotted('x'),sort(levelZero));
  const context=new ExprMetaContext(environment);
  const meta=context.mkFresh(sort(levelZero),locals);
  context.assign(meta,fvar('x'));
  equal(exprEq(context.instantiate(meta),fvar('x')),true);

  const other=context.mkFresh(sort(levelZero),locals);
  let outOfScope=false;
  try{context.assign(other,fvar('y'));}
  catch(error){outOfScope=/out-of-scope free variable/.test(String(error));}
  equal(outOfScope,true);
}
{
  const environment=new Environment();
  const context=new ExprMetaContext(environment);
  const type=sort(levelSucc(levelZero));
  const first=context.mkFresh(type);
  const second=context.mkFresh(type);
  context.assign(first,second);
  context.assign(second,sort(levelZero));
  equal(exprEq(context.instantiate(first),sort(levelZero)),true);
  context.validateGroundAssignments();
}
{
  const environment=new Environment();
  const context=new ExprMetaContext(environment);
  const type=sort(levelSucc(levelZero));
  let depth=-1;
  context.withDepth(()=>{
    const meta=context.mkFresh(type);
    depth=context.getDecl(meta).depth;
  });
  equal(depth,1);
}
console.log('ok - @proofscript/meta Expr metavariable context');


{
  const environment=new Environment();
  const kernel=new Kernel(environment);
  const Type=sort(levelSucc(levelZero));
  const Nat=nameFromDotted('MetaFunctionNat');
  kernel.addAxiom({
    kind:'axiom',
    name:Nat,
    levelParams:[],
    type:Type,
  });
  const context=new ExprMetaContext(environment);
  const domain=context.mkFresh(Type);
  const codomain=context.mkFresh(Type);
  const expected=forallE(
    nameFromDotted('_'),
    domain,
    codomain,
  );
  const actual=forallE(
    nameFromDotted('x'),
    constant(Nat),
    constant(Nat),
  );
  equal(context.unify(expected,actual),true);
  equal(
    exprEq(context.instantiate(domain),constant(Nat)),
    true,
  );
  equal(
    exprEq(context.instantiate(codomain),constant(Nat)),
    true,
  );
  context.validateGroundAssignments();
}
console.log('ok - @proofscript/meta function-type metavariable unification');




{
  const environment=new Environment();
  const context=new ExprMetaContext(environment);
  const type=sort(levelSucc(levelZero));
  const meta=context.mkFresh(type);
  let loose=false;
  try{context.assign(meta,{kind:'bvar',index:0});}
  catch(error){loose=/loose bound variable/.test(String(error));}
  equal(loose,true);
}
{
  const environment=new Environment();
  const context=new ExprMetaContext(environment);
  const type=sort(levelSucc(levelZero));
  const outer=context.mkFresh(type);
  let inner!:import('lean-ts-kernel').Expr;
  context.withDepth(()=>{
    inner=context.mkFresh(type);
    equal(context.tryAssignByUnification(outer,sort(levelZero)),false);
    equal(context.unify(outer,inner),true);
    equal(exprEq(context.getAssignment(inner)!,outer),true);
  });
}
{
  const environment=new Environment();
  const context=new ExprMetaContext(environment);
  const type=sort(levelSucc(levelZero));
  const outer=context.mkFresh(type);
  let inner!:import('lean-ts-kernel').Expr;
  context.withDepth(()=>{inner=context.mkFresh(type);});
  let leaked=false;
  try{context.assign(outer,inner);}
  catch(error){leaked=/depends on deeper metavariable/.test(String(error));}
  equal(leaked,true);
}
console.log('ok - @proofscript/meta Lean-style metavariable depth discipline');


{
  const environment=new Environment();
  const kernel=new Kernel(environment);
  const U=sort(levelSucc(levelZero));
  const Nat=nameFromDotted('MetaNat');
  const StringType=nameFromDotted('MetaString');
  const F=nameFromDotted('MetaF');
  kernel.addAxiom({
    kind:'axiom',
    name:Nat,
    levelParams:[],
    type:U,
  });
  kernel.addAxiom({
    kind:'axiom',
    name:StringType,
    levelParams:[],
    type:U,
  });
  kernel.addAxiom({
    kind:'axiom',
    name:F,
    levelParams:[],
    type:forallE(
      nameFromDotted('α'),
      U,
      forallE(nameFromDotted('β'),U,U),
    ),
  });

  const context=new ExprMetaContext(environment);
  const meta=context.mkFresh(U);
  equal(
    context.unify(
      app(constant(F),meta),
      app(constant(F),constant(Nat)),
    ),
    true,
  );
  equal(exprEq(context.instantiate(meta),constant(Nat)),true);
}
{
  const environment=new Environment();
  const kernel=new Kernel(environment);
  const U=sort(levelSucc(levelZero));
  const Nat=nameFromDotted('RollbackNat');
  const Other=nameFromDotted('RollbackOther');
  const F=nameFromDotted('RollbackF');
  for(const name of [Nat,Other]){
    kernel.addAxiom({
      kind:'axiom',
      name,
      levelParams:[],
      type:U,
    });
  }
  kernel.addAxiom({
    kind:'axiom',
    name:F,
    levelParams:[],
    type:forallE(
      nameFromDotted('α'),
      U,
      forallE(nameFromDotted('β'),U,U),
    ),
  });

  const context=new ExprMetaContext(environment);
  const meta=context.mkFresh(U);
  const left=app(app(constant(F),meta),constant(Nat));
  const right=app(app(constant(F),constant(Other)),constant(Other));
  equal(context.unify(left,right),false);
  equal(context.isAssigned(meta),false);
}
console.log('ok - @proofscript/meta structural application unification with rollback');

{
  const env=new Environment();
  const meta=new ExprMetaContext(env);
  const lctx=new LocalContext();
  const P=nameFromDotted('P');
  const pId=lctx.fresh('P');
  lctx.addLocal(pId,P,sort(levelZero),'default');
  const q=meta.mkFresh(sort(levelZero),lctx,'natural');
  const candidate=forallE(
    nameFromDotted('_'),
    q,
    q,
    'default',
  );
  const target=forallE(
    nameFromDotted('_'),
    fvar(pId),
    fvar(pId),
    'default',
  );
  equal(meta.unify(candidate,target,lctx),true);
  equal(exprEq(meta.instantiate(q),fvar(pId)),true);
}
console.log('ok - @proofscript/meta structural Pi unification');

{
  const env=new Environment();
  const kernel=new Kernel(env);
  const U=sort(levelSucc(levelZero));
  const Nat=nameFromDotted('MetaPolyNat');
  kernel.addAxiom({
    kind:'axiom',
    name:Nat,
    levelParams:[],
    type:U,
  });

  const lctx=new LocalContext();
  lctx.addLocal('a',nameFromDotted('a'),constant(Nat),'default');
  lctx.addLocal('b',nameFromDotted('b'),constant(Nat),'default');

  const meta=new ExprMetaContext(env);
  const universe=meta.mkFreshLevel();
  const alpha=meta.mkFresh(sort(universe),lctx,'natural');
  const leftValue=meta.mkFresh(alpha,lctx,'natural');
  const rightValue=meta.mkFresh(alpha,lctx,'natural');
  const Rel=nameFromDotted('MetaRel');
  const left=mkAppN(
    constant(Rel,[universe]),
    [alpha,leftValue,rightValue],
  );
  const right=mkAppN(
    constant(Rel,[levelSucc(levelZero)]),
    [constant(Nat),fvar('b'),fvar('a')],
  );

  equal(meta.unify(left,right,lctx),true);
  equal(exprEq(meta.instantiate(alpha),constant(Nat)),true);
  equal(exprEq(meta.instantiate(leftValue),fvar('b')),true);
  equal(exprEq(meta.instantiate(rightValue),fvar('a')),true);
  meta.validateGroundAssignments();
}
console.log('ok - @proofscript/meta mixed universe/application unification');





{
  const environment=new Environment();
  const context=new ExprMetaContext(environment);
  const universe=context.mkFreshLevel();
  const typeMeta=context.mkFresh(sort(universe));
  context.assign(typeMeta,sort(levelZero));
  const solved=context.instantiate(sort(universe));
  equal(solved.kind,'sort');
  if(solved.kind==='sort'){
    equal(levelEqStructural(solved.level,levelSucc(levelZero)),true);
  }
  context.validateGroundAssignments();
}
{
  const environment=new Environment();
  const context=new ExprMetaContext(environment);
  context.mkFreshLevel();
  let unresolved=false;
  try{context.validateGroundAssignments();}
  catch(error){unresolved=/unresolved universe metavariable/.test(String(error));}
  equal(unresolved,true);
}
{
  const environment=new Environment();
  const context=new ExprMetaContext(environment);
  const universe=context.mkFreshLevel();
  const left=app(sort(universe),sort(levelZero));
  const right=app(
    sort(levelSucc(levelZero)),
    sort(levelSucc(levelZero)),
  );
  equal(context.unify(left,right),false);
  let rolledBack=false;
  try{context.validateGroundAssignments();}
  catch(error){
    rolledBack=/unresolved universe metavariable/.test(String(error));
  }
  equal(rolledBack,true);
}
console.log('ok - @proofscript/meta bounded universe metavariable solving');
