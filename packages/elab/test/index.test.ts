import {
  ElaborationError,
  admitElaborated,
  elaborateApplication,
  elaborateChecked,
  elaborateV061Definitions,
} from '../src/index.js';
import {ExprMetaContext} from '@proofscript/meta';
import {parseV061Module} from '@proofscript/syntax';
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
  names:{Nat:ReturnType<typeof nameFromDotted>;zero:ReturnType<typeof nameFromDotted>};
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


function makeDefinitionEnvironment():Environment {
  const env=new Environment();
  const kernel=new Kernel(env);
  const TestNat=nameFromDotted('TestNat');
  kernel.addAxiom({
    kind:'axiom',
    name:TestNat,
    levelParams:[],
    type:sort(levelSucc(levelZero)),
  });
  kernel.addAxiom({
    kind:'axiom',
    name:nameFromDotted('testZero'),
    levelParams:[],
    type:constant(TestNat),
  });
  return env;
}

{
  const env=makeDefinitionEnvironment();
  const result=elaborateV061Definitions(parseV061Module(
    'function id(x : TestNat) : TestNat := x; '+
    'function use(x : TestNat) : TestNat := id(x); '+
    'const z : TestNat := testZero;',
  ),env);
  equal(result.definitions.length,3);
  const id=result.definitions[0]!;
  const use=result.definitions[1]!;
  const z=result.definitions[2]!;
  equal(id.hints.kind,'regular');
  if(id.hints.kind==='regular')equal(id.hints.height,1n);
  equal(use.hints.kind,'regular');
  if(use.hints.kind==='regular')equal(use.hints.height,2n);
  equal(z.hints.kind,'regular');
  if(z.hints.kind==='regular')equal(z.hints.height,1n);
  equal(result.environment.find(nameFromDotted('id'))?.kind,'definition');
  equal(result.environment.find(nameFromDotted('use'))?.kind,'definition');
}
{
  const env=makeDefinitionEnvironment();
  let recursive=false;
  try{
    elaborateV061Definitions(parseV061Module(
      'function loop(x : TestNat) : TestNat := loop(x);',
    ),env);
  }catch(error){recursive=/PS_ELAB_UNKNOWN_NAME/.test(String(error));}
  equal(recursive,true);
}
{
  const env=makeDefinitionEnvironment();
  let notation=false;
  try{
    elaborateV061Definitions(parseV061Module(
      'function bad(x : TestNat) : TestNat := x + x;',
    ),env);
  }catch(error){notation=/PS_ELAB_NOTATION_UNSUPPORTED/.test(String(error));}
  equal(notation,true);
}
{
  const env=makeDefinitionEnvironment();
  let declaration=false;
  try{
    elaborateV061Definitions(parseV061Module(
      'structure Box where { value : TestNat; }',
    ),env);
  }catch(error){declaration=/PS_ELAB_DECL_UNSUPPORTED/.test(String(error));}
  equal(declaration,true);
}
console.log('ok - @proofscript/elab kernel-facing non-recursive definitions');


{
  const env=makeDefinitionEnvironment();
  const result=elaborateV061Definitions(parseV061Module(
    'function identity {α : Type}(x : α) : α := x; '+
    'function useIdentity(x : TestNat) : TestNat := identity(x);',
  ),env);
  const identity=result.definitions[0]!;
  equal(identity.type.kind,'forall');
  if(identity.type.kind==='forall'){
    equal(identity.type.binderInfo,'implicit');
    equal(identity.body?.kind,undefined);
  }
  const use=result.definitions[1]!;
  equal(use.hints.kind,'regular');
  if(use.hints.kind==='regular')equal(use.hints.height,2n);
}
console.log('ok - @proofscript/elab implicit declaration binders');
