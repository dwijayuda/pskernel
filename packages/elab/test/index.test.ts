import {
  ElaborationError,
  admitElaborated,
  elaborateApplication,
  elaborateChecked,
} from '../src/index.js';
import {ExprMetaContext} from '@proofscript/meta';
import {
  Environment,
  Kernel,
  LocalContext,
  TypeChecker,
  app,
  bvar,
  constant,
  exprEq,
  forallE,
  levelSucc,
  levelZero,
  nameFromDotted,
  sort,
} from 'lean-ts-kernel';
function equal(a:unknown,b:unknown):void{if(a!==b)throw new Error(`expected ${String(b)}, got ${String(a)}`);}
{
  const term=elaborateChecked({elaborate:(surface:string)=>({term:surface.toUpperCase(),diagnostics:[]})},'x');
  equal(term,'X');
}
{
  let threw=false;
  try{elaborateChecked({elaborate:()=>({diagnostics:[{severity:'error',message:'bad'}]})},'x');}
  catch(error){threw=error instanceof ElaborationError;}
  equal(threw,true);
}
equal(admitElaborated({admit:(e:number,d:number)=>e+d},1,2),3);
console.log('ok - @proofscript/elab foundation');


function makeApplicationEnvironment():{
  env:Environment;
  names:{Nat:returnType<typeof nameFromDotted>;zero:returnType<typeof nameFromDotted>};
}{
  const env=new Environment();
  const kernel=new Kernel(env);
  const Nat=nameFromDotted('Test.Nat');
  const zero=nameFromDotted('Test.zero');
  kernel.addAxiom({
    kind:'axiom',
    name:Nat,
    levelParams:[],
    type:sort(levelSucc(levelZero)),
  });
  kernel.addAxiom({
    kind:'axiom',
    name:zero,
    levelParams:[],
    type:constant(Nat),
  });
  return {env,names:{Nat,zero}};
}

{
  const {env,names}=makeApplicationEnvironment();
  const kernel=new Kernel(env);
  const id=nameFromDotted('Test.id');
  const alpha=nameFromDotted('α');
  const x=nameFromDotted('x');
  kernel.addAxiom({
    kind:'axiom',
    name:id,
    levelParams:[],
    type:forallE(
      alpha,
      sort(levelSucc(levelZero)),
      forallE(x,bvar(0),bvar(1),'default'),
      'implicit',
    ),
  });

  const meta=new ExprMetaContext(env);
  const result=elaborateApplication({
    environment:env,
    metaContext:meta,
    fn:constant(id),
    args:[constant(names.zero)],
  });
  equal(result.inserted.length,1);
  equal(result.inserted[0]?.binderInfo,'implicit');
  equal(result.pendingInstances.length,0);
  equal(result.consumedExplicitArgs,1);
  equal(exprEq(result.type,constant(names.Nat)),true);
  equal(meta.snapshotAssignments().size,1);
  const checked=new TypeChecker(env,new LocalContext()).check(result.term);
  equal(exprEq(checked,constant(names.Nat)),true);
}
{
  const {env,names}=makeApplicationEnvironment();
  const kernel=new Kernel(env);
  const fn=nameFromDotted('Test.withInst');
  kernel.addAxiom({
    kind:'axiom',
    name:fn,
    levelParams:[],
    type:forallE(
      nameFromDotted('inst'),
      constant(names.Nat),
      forallE(
        nameFromDotted('x'),
        constant(names.Nat),
        constant(names.Nat),
      ),
      'instImplicit',
    ),
  });

  const meta=new ExprMetaContext(env);
  const result=elaborateApplication({
    environment:env,
    metaContext:meta,
    fn:constant(fn),
    args:[constant(names.zero)],
  });
  equal(result.pendingInstances.length,1);
  const pending=result.pendingInstances[0]!;
  equal(meta.getDecl(pending).kind,'synthetic');
  equal(result.term.kind,'app');
  meta.assign(pending,constant(names.zero));
  const grounded=meta.instantiate(result.term);
  equal(
    exprEq(
      new TypeChecker(env,new LocalContext()).check(grounded),
      constant(names.Nat),
    ),
    true,
  );
}
{
  const {env,names}=makeApplicationEnvironment();
  const kernel=new Kernel(env);
  const fn=nameFromDotted('Test.strictId');
  kernel.addAxiom({
    kind:'axiom',
    name:fn,
    levelParams:[],
    type:forallE(
      nameFromDotted('α'),
      sort(levelSucc(levelZero)),
      forallE(
        nameFromDotted('x'),
        bvar(0),
        bvar(1),
      ),
      'strictImplicit',
    ),
  });
  const meta=new ExprMetaContext(env);
  const applied=elaborateApplication({
    environment:env,
    metaContext:meta,
    fn:constant(fn),
    args:[constant(names.zero)],
  });
  equal(applied.inserted.length,1);

  const bare=elaborateApplication({
    environment:env,
    metaContext:new ExprMetaContext(env),
    fn:constant(fn),
    args:[],
  });
  equal(bare.inserted.length,0);
  equal(bare.type.kind,'forall');
}
console.log('ok - @proofscript/elab Lean-style application elaboration');
