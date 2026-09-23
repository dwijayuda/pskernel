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
