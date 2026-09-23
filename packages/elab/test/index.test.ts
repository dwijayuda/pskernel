import {
  ElaborationError,
  admitElaborated,
  elaborateApplication,
  elaborateChecked,
  elaborateV061Definitions,
  elaborateV061Declarations,
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
  natLit,
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
  kernel.addAxiom({
    kind:'axiom',
    name:nameFromDotted('Box'),
    levelParams:[],
    type:forallE(
      nameFromDotted('α'),
      sort(levelSucc(levelZero)),
      sort(levelSucc(levelZero)),
    ),
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
  }catch(error){notation=/PS_ELAB_NAT_ENVIRONMENT/.test(String(error));}
  equal(notation,true);
}
{
  const env=makeDefinitionEnvironment();
  const result=elaborateV061Definitions(parseV061Module(
    'structure Box where { value : TestNat; }',
  ),env);
  equal(result.inductives.length,1);
  equal(result.environment.find(nameFromDotted('Box'))?.kind,'inductive');
  equal(
    result.environment.find(nameFromDotted('Box.mk'))?.kind,
    'constructor',
  );
  equal(
    result.environment.find(nameFromDotted('Box.rec'))?.kind,
    'recursor',
  );
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
  }
  equal(identity.value.kind,'lam');
  if(identity.value.kind==='lam'){
    equal(identity.value.binderInfo,'implicit');
  }
  const use=result.definitions[1]!;
  equal(use.hints.kind,'regular');
  if(use.hints.kind==='regular')equal(use.hints.height,2n);
}
console.log('ok - @proofscript/elab implicit declaration binders');


{
  const env=makeDefinitionEnvironment();
  const result=elaborateV061Definitions(parseV061Module(
    'function keepBox(x : Box(TestNat)) : Box(TestNat) := x;',
  ),env);
  const definition=result.definitions[0]!;
  equal(definition.type.kind,'forall');
  if(definition.type.kind==='forall'){
    equal(definition.type.type.kind,'app');
  }
  equal(result.environment.find(nameFromDotted('keepBox'))?.kind,'definition');
}
console.log('ok - @proofscript/elab dependent type application path');


{
  const result=elaborateV061Declarations(parseV061Module(
    'theorem identityProp(P : Prop, h : P) : P := h; '+
    'theorem useIdentityProp(P : Prop, h : P) : P := identityProp(P, h);',
  ));
  equal(result.theorems.length,2);
  equal(result.definitions.length,0);
  equal(result.declarations.length,2);
  equal(result.environment.find(nameFromDotted('identityProp'))?.kind,'theorem');
  equal(result.environment.find(nameFromDotted('useIdentityProp'))?.kind,'theorem');
}
{
  const env=makeDefinitionEnvironment();
  let rejected=false;
  try{
    elaborateV061Declarations(parseV061Module(
      'theorem notAProposition : TestNat := testZero;',
    ),env);
  }catch(error){rejected=/type is not a proposition/.test(String(error));}
  equal(rejected,true);
}
console.log('ok - @proofscript/elab kernel theorem proof-term admission');


{
  const result=elaborateV061Declarations(parseV061Module(
    'theorem functionProof(P : Prop) : P -> P := fun h => h;',
  ));
  equal(result.theorems.length,1);
  const theorem=result.theorems[0]!;
  equal(theorem.value.kind,'lam');
  if(theorem.value.kind==='lam'){
    equal(theorem.value.body.kind,'lam');
  }
}
{
  const env=makeDefinitionEnvironment();
  const result=elaborateV061Declarations(parseV061Module(
    'const identityFunction : TestNat -> TestNat := fun x => x;',
  ),env);
  equal(result.definitions.length,1);
  equal(result.definitions[0]?.value.kind,'lam');
}
{
  const env=makeDefinitionEnvironment();
  let noExpected=false;
  try{
    elaborateV061Declarations(parseV061Module(
      'const badLambda : TestNat := fun x => x;',
    ),env);
  }catch(error){noExpected=/PS_ELAB_LAMBDA_EXPECTED_FUNCTION/.test(String(error));}
  equal(noExpected,true);
}
console.log('ok - @proofscript/elab expected-type lambda elaboration');


{
  const result=elaborateV061Declarations(parseV061Module(
    'theorem letProof(P : Prop, h : P) : P := let x : P := h; x;',
  ));
  equal(result.theorems.length,1);
  const proof=result.theorems[0]!.value;
  equal(proof.kind,'lam');
  if(proof.kind==='lam'&&proof.body.kind==='lam'){
    equal(proof.body.body.kind,'let');
  }
}
{
  const env=makeDefinitionEnvironment();
  const result=elaborateV061Declarations(parseV061Module(
    'function letValue(x : TestNat) : TestNat := let y := x; y;',
  ),env);
  equal(result.definitions[0]?.value.kind,'lam');
}
console.log('ok - @proofscript/elab core let elaboration');


{
  const result=elaborateV061Declarations(parseV061Module(
    'theorem byExact(P : Prop, h : P) : P := by exact h; '+
    'theorem byAssumption(P : Prop, h : P) : P := by assumption;',
  ));
  equal(result.theorems.length,2);
  equal(result.environment.find(nameFromDotted('byExact'))?.kind,'theorem');
  equal(result.environment.find(nameFromDotted('byAssumption'))?.kind,'theorem');
}
{
  let failed=false;
  try{
    elaborateV061Declarations(parseV061Module(
      'theorem noAssumption(P : Prop) : P := by assumption;',
    ));
  }catch(error){failed=/PS_ELAB_TACTIC_ASSUMPTION/.test(String(error));}
  equal(failed,true);
}
console.log('ok - @proofscript/elab exact and assumption tactic terms');


{
  const result=elaborateV061Declarations(parseV061Module(
    'theorem expectedBy(P : Prop, h : P) : P := by exact h; '+
    'theorem expectedLambda(P : Prop) : P -> P := fun h => h;',
  ));
  equal(result.theorems.length,2);
  equal(result.environment.find(nameFromDotted('expectedBy'))?.kind,'theorem');
  equal(result.environment.find(nameFromDotted('expectedLambda'))?.kind,'theorem');
}
console.log('ok - @proofscript/elab declaration expected-type propagation');


{
  const result=elaborateV061Declarations(parseV061Module(
    'theorem introIdentity(P : Prop) : P -> P := by intro h; assumption; '+
    'theorem introExact(P : Prop) : P -> P := by intro h; exact h;',
  ));
  equal(result.theorems.length,2);
  for(const theorem of result.theorems){
    equal(theorem.value.kind,'lam');
  }
}
{
  let failed=false;
  try{
    elaborateV061Declarations(parseV061Module(
      'theorem badIntro(P : Prop) : P := by intro h; assumption;',
    ));
  }catch(error){failed=/PS_ELAB_TACTIC_INTRO/.test(String(error));}
  equal(failed,true);
}
console.log('ok - @proofscript/elab intro tactic proof-term construction');


function makeNatNotationEnvironment():Environment {
  const env=new Environment();
  const kernel=new Kernel(env);
  const Nat=nameFromDotted('Nat');
  kernel.addAxiom({
    kind:'axiom',
    name:Nat,
    levelParams:[],
    type:sort(levelSucc(levelZero)),
  });
  const binaryType=forallE(
    nameFromDotted('x'),
    constant(Nat),
    forallE(
      nameFromDotted('y'),
      constant(Nat),
      constant(Nat),
    ),
  );
  for(const name of ['Nat.add','Nat.sub','Nat.mul']){
    kernel.addAxiom({
      kind:'axiom',
      name:nameFromDotted(name),
      levelParams:[],
      type:binaryType,
    });
  }
  return env;
}
{
  const env=makeNatNotationEnvironment();
  const result=elaborateV061Declarations(parseV061Module(
    'function add(x : Nat, y : Nat) : Nat := x + y; '+
    'function sub(x : Nat, y : Nat) : Nat := x - y; '+
    'function mul(x : Nat, y : Nat) : Nat := x * y;',
  ),env);
  equal(result.definitions.length,3);
  for(const definition of result.definitions){
    equal(definition.value.kind,'lam');
  }
}
console.log('ok - @proofscript/elab bounded Nat notation');


{
  const env=makeDefinitionEnvironment();
  const result=elaborateV061Declarations(parseV061Module(
    'structure SigmaBox where { T : Type; value : T; }',
  ),env);
  const ctor=result.environment.find(nameFromDotted('SigmaBox.mk'));
  equal(ctor?.kind,'constructor');
  if(ctor?.kind==='constructor'){
    equal(ctor.numFields,2);
    equal(ctor.type.kind,'forall');
  }
}
console.log('ok - @proofscript/elab dependent structure field admission');


{
  const env=makeDefinitionEnvironment();
  const result=elaborateV061Declarations(parseV061Module(
    'structure User where { value : TestNat; } '+
    'function make(x : TestNat) : User := { value := x : User }; '+
    'function get(user : User) : TestNat := user.value;',
  ),env);
  equal(result.structures.length,1);
  const make=result.definitions.find((item)=>
    item.name.kind==='str'&&item.name.value==='make'
  );
  const get=result.definitions.find((item)=>
    item.name.kind==='str'&&item.name.value==='get'
  );
  equal(make?.value.kind,'lam');
  if(make?.value.kind==='lam'){
    equal(make.value.body.kind,'app');
  }
  equal(get?.value.kind,'lam');
  if(get?.value.kind==='lam'){
    equal(get.value.body.kind,'proj');
    if(get.value.body.kind==='proj')equal(get.value.body.index,0);
  }
}
{
  const env=makeDefinitionEnvironment();
  const result=elaborateV061Declarations(parseV061Module(
    'structure SigmaBox where { T : Type; value : T; } '+
    'function makeSigma(x : TestNat) : SigmaBox := '+
    '{ T := TestNat, value := x : SigmaBox };',
  ),env);
  equal(result.definitions.length,1);
  equal(result.structures[0]?.fields.length,2);
}
console.log('ok - @proofscript/elab record construction and kernel projection');


{
  const env=makeNatNotationEnvironment();
  const result=elaborateV061Declarations(parseV061Module(
    'inductive MaybeNat where { | none; | some(value : Nat); } '+
    'const noneValue : MaybeNat := MaybeNat.none; '+
    'const oneValue : MaybeNat := MaybeNat.some(1);',
  ),env);
  equal(result.inductives.length,1);
  equal(
    result.environment.find(nameFromDotted('MaybeNat'))?.kind,
    'inductive',
  );
  equal(
    result.environment.find(nameFromDotted('MaybeNat.none'))?.kind,
    'constructor',
  );
  equal(
    result.environment.find(nameFromDotted('MaybeNat.some'))?.kind,
    'constructor',
  );
  equal(result.definitions.length,2);
}
{
  const env=makeNatNotationEnvironment();
  let recursive=false;
  try{
    elaborateV061Declarations(parseV061Module(
      'inductive NatList where { '+
      '| nil; | cons(head : Nat, tail : NatList); }',
    ),env);
  }catch(error){
    recursive=/PS_ELAB_RECURSIVE_INDUCTIVE_UNSUPPORTED/.test(String(error));
  }
  equal(recursive,true);
}
console.log('ok - @proofscript/elab unparameterized inductive admission');


{
  const env=makeNatNotationEnvironment();
  const result=elaborateV061Declarations(parseV061Module(
    'inductive MaybeNat where { | none; | some(value : Nat); } '+
    'function getOrZero(value : MaybeNat) : Nat := '+
    'match value with { | .none => 0; | .some x => x; };',
  ),env);
  const definition=result.definitions.find(
    (item)=>item.name.kind==='str'&&item.name.value==='getOrZero',
  );
  equal(definition?.value.kind,'lam');
  if(definition?.value.kind==='lam'){
    const some=app(
      constant(nameFromDotted('MaybeNat.some')),
      natLit(7n),
    );
    const reduced=new TypeChecker(
      result.environment,
      new LocalContext(),
    ).whnf(app(definition.value,some));
    equal(exprEq(reduced,natLit(7n)),true);
  }
}
{
  const env=makeNatNotationEnvironment();
  let nonexhaustive=false;
  try{
    elaborateV061Declarations(parseV061Module(
      'inductive MaybeNat where { | none; | some(value : Nat); } '+
      'function bad(value : MaybeNat) : Nat := '+
      'match value with { | .none => 0; };',
    ),env);
  }catch(error){
    nonexhaustive=/PS_ELAB_MATCH_NONEXHAUSTIVE/.test(String(error));
  }
  equal(nonexhaustive,true);
}
console.log('ok - @proofscript/elab verified match recursor elaboration');


{
  const env=makeNatNotationEnvironment();
  const result=elaborateV061Declarations(parseV061Module(
    'inductive Option(α : Type) where { '+
    '| none; | some(value : α); } '+
    'const noneNat : Option(Nat) := Option.none; '+
    'const oneNat : Option(Nat) := Option.some(1);',
  ),env);
  const option=result.environment.find(nameFromDotted('Option'));
  const none=result.environment.find(nameFromDotted('Option.none'));
  const some=result.environment.find(nameFromDotted('Option.some'));
  equal(option?.kind,'inductive');
  if(option?.kind==='inductive')equal(option.numParams,1);
  equal(none?.kind,'constructor');
  if(none?.kind==='constructor'){
    equal(none.numParams,1);
    equal(none.numFields,0);
    equal(none.type.kind,'forall');
    if(none.type.kind==='forall'){
      equal(none.type.binderInfo,'implicit');
    }
  }
  equal(some?.kind,'constructor');
  if(some?.kind==='constructor'){
    equal(some.numParams,1);
    equal(some.numFields,1);
    equal(some.type.kind,'forall');
    if(some.type.kind==='forall'){
      equal(some.type.binderInfo,'implicit');
    }
  }
  equal(result.definitions.length,2);
}
console.log('ok - @proofscript/elab parameterized inductive constructor inference');


{
  const env=makeNatNotationEnvironment();
  const result=elaborateV061Declarations(parseV061Module(
    'inductive PsOption(α : Type) where { '+
    '| none; | some(value : α); } '+
    'function getOr {α : Type}'+
    '(value : PsOption(α), fallback : α) : α := '+
    'match value with { | .none => fallback; | .some x => x; };',
  ),env);
  const definition=result.definitions.find(
    (item)=>item.name.kind==='str'&&item.name.value==='getOr',
  );
  equal(definition?.value.kind,'lam');
  if(definition?.value.kind==='lam'){
    const Some=constant(nameFromDotted('PsOption.some'));
    const someSeven=mkAppN(
      Some,
      [constant(nameFromDotted('Nat')),natLit(7n)],
    );
    const reduced=new TypeChecker(
      result.environment,
      new LocalContext(),
    ).whnf(
      mkAppN(
        definition.value,
        [
          constant(nameFromDotted('Nat')),
          someSeven,
          natLit(3n),
        ],
      ),
    );
    equal(exprEq(reduced,natLit(7n)),true);
  }
}
console.log('ok - @proofscript/elab parameterized verified match recursor elaboration');
