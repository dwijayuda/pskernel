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
  mkAppN,
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


{
  const result=elaborateV061Declarations(parseV061Module(
    'theorem applyPremise(P : Prop, Q : Prop, f : P -> Q, h : P) : Q := '+
    'by apply f; assumption;',
  ));
  equal(result.theorems.length,1);
  const theorem=result.theorems[0]!;
  equal(theorem.value.kind,'lam');
  equal(
    result.environment.find(nameFromDotted('applyPremise'))?.kind,
    'theorem',
  );
}
{
  let failed=false;
  try{
    elaborateV061Declarations(parseV061Module(
      'theorem badApply(P : Prop, Q : Prop, h : P) : Q := '+
      'by apply h; assumption;',
    ));
  }catch(error){failed=/PS_ELAB_TACTIC_APPLY/.test(String(error));}
  equal(failed,true);
}
console.log('ok - @proofscript/elab bounded apply tactic proof-term construction');

{
  const result=elaborateV061Declarations(parseV061Module(
    'theorem applyTwo(P : Prop, Q : Prop, R : Prop, '+
    'f : P -> Q -> R, hp : P, hq : Q) : R := '+
    'by apply f; assumption; assumption;',
  ));
  equal(result.theorems.length,1);
  equal(
    result.environment.find(nameFromDotted('applyTwo'))?.kind,
    'theorem',
  );
}
console.log('ok - @proofscript/elab ordered multi-goal apply tactic');

{
  const result=elaborateV061Declarations(parseV061Module(
    'theorem refinePremise(P : Prop, Q : Prop, f : P -> Q, h : P) : Q := '+
    'by refine f(?_); assumption; '+
    'theorem refineGoal(P : Prop, h : P) : P := '+
    'by refine ?_; assumption;',
  ));
  equal(result.theorems.length,2);
  equal(
    result.environment.find(nameFromDotted('refinePremise'))?.kind,
    'theorem',
  );
  equal(
    result.environment.find(nameFromDotted('refineGoal'))?.kind,
    'theorem',
  );
}
{
  let rejected=false;
  try{
    elaborateV061Declarations(parseV061Module(
      'theorem holeOutside(P : Prop) : P := ?_;',
    ));
  }catch(error){
    rejected=/PS_ELAB_SYNTHETIC_HOLE_OUTSIDE_REFINE/.test(String(error));
  }
  equal(rejected,true);
}
console.log('ok - @proofscript/elab bounded synthetic-hole refine tactic');

{
  const result=elaborateV061Declarations(parseV061Module(
    'inductive PropPair where { | mk(left : Prop, right : Prop); } '+
    'theorem buildPair(P : Prop, Q : Prop) : PropPair := '+
    'by constructor; assumption; assumption;',
  ));
  equal(result.inductives.length,1);
  equal(result.theorems.length,1);
  equal(
    result.environment.find(nameFromDotted('buildPair'))?.kind,
    'theorem',
  );
}
{
  let rejected=false;
  try{
    elaborateV061Declarations(parseV061Module(
      'theorem badConstructor(P : Prop) : P := by constructor;',
    ));
  }catch(error){
    rejected=/PS_ELAB_TACTIC_CONSTRUCTOR/.test(String(error));
  }
  equal(rejected,true);
}
console.log('ok - @proofscript/elab bounded constructor via apply');

{
  const result=elaborateV061Declarations(parseV061Module(
    'inductive Choice where { | left; | right; } '+
    'theorem chooseCases(P : Prop, h : P, c : Choice) : P := '+
    'by cases c; assumption; assumption;',
  ));
  equal(result.inductives.length,1);
  equal(result.theorems.length,1);
  equal(
    result.environment.find(nameFromDotted('chooseCases'))?.kind,
    'theorem',
  );
}
{
  let rejected=false;
  try{
    elaborateV061Declarations(parseV061Module(
      'theorem badCases(P : Prop, h : P) : P := by cases h; assumption;',
    ));
  }catch(error){
    rejected=/PS_ELAB_TACTIC_CASES/.test(String(error));
  }
  equal(rejected,true);
}
console.log('ok - @proofscript/elab bounded cases via recursor');

{
  const result=elaborateV061Declarations(parseV061Module(
    'inductive Wrap(α : Type) where { | mk(value : α); } '+
    'theorem unwrapCase(P : Prop, h : P, w : Wrap(Prop)) : P := '+
    'by cases w; assumption;',
  ));
  equal(result.theorems.length,1);
  equal(
    result.environment.find(nameFromDotted('unwrapCase'))?.kind,
    'theorem',
  );
}
console.log('ok - @proofscript/elab parameterized bounded cases');

{
  const result=elaborateV061Declarations(parseV061Module(
    'inductive Chain where { | nil; | cons(tail : Chain); } '+
    'theorem chainInduction(P : Prop, base : P, step : P -> P, xs : Chain) : P := '+
    'by induction xs; assumption; apply step; assumption;',
  ));
  equal(result.inductives.length,1);
  equal(result.theorems.length,1);
  equal(
    result.environment.find(nameFromDotted('chainInduction'))?.kind,
    'theorem',
  );
}
{
  const result=elaborateV061Declarations(parseV061Module(
    'inductive PsListI(α : Type) where { '+
    '| nil; | cons(head : α, tail : PsListI(α)); } '+
    'theorem listInduction {α : Type}'+
    '(P : Prop, base : P, step : P -> P, xs : PsListI(α)) : P := '+
    'by induction xs; assumption; apply step; assumption;',
  ));
  equal(result.theorems.length,1);
  equal(
    result.environment.find(nameFromDotted('listInduction'))?.kind,
    'theorem',
  );
}
{
  let rejected=false;
  try{
    elaborateV061Declarations(parseV061Module(
      'inductive ChoiceI where { | left; | right; } '+
      'theorem badDependentContext'+
      '(M : ChoiceI -> Prop, c : ChoiceI, h : M(c), P : Prop, hp : P) : P := '+
      'by induction c; assumption; assumption;',
    ));
  }catch(error){
    rejected=/PS_ELAB_TACTIC_INDUCTION_DEPENDENT_CONTEXT/.test(String(error));
  }
  equal(rejected,true);
}
console.log('ok - @proofscript/elab bounded induction via recursor');

{
  const source=parseV061Module(
    'theorem parsedRw(a : Nat, b : Nat, h : a = b) : a = b := '+
    'by rw [h]; rw [← h]; assumption;',
  );
  const body=source.declarations[0]?.body;
  equal(body?.kind,'by');
  if(body?.kind==='by'){
    equal(body.tactics[0]?.kind,'rw');
    equal(body.tactics[1]?.kind,'rw');
  }
}
console.log('ok - @proofscript/elab rw syntax reaches tactic AST');

{
  const source=parseV061Module(
    'theorem parsedSimp(A : Type, B : Type, C : Type, D : Type, '+
    'h1 : BoxT(A) = B, h2 : WrapT(C) = D) : P := '+
    'by simp only [h1, ← h2];',
  );
  const body=source.declarations[0]?.body;
  equal(body?.kind,'by');
  if(body?.kind==='by'){
    equal(body.tactics[0]?.kind,'simp');
    if(body.tactics[0]?.kind==='simp'){
      equal(body.tactics[0].rules.length,2);
    }
  }
}
console.log('ok - @proofscript/elab multi-rule simp-only syntax reaches tactic AST');


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
  const result=elaborateV061Declarations(parseV061Module(
    'inductive NatList where { '+
    '| nil; | cons(head : Nat, tail : NatList); }',
  ),env);
  const list=result.environment.find(nameFromDotted('NatList'));
  equal(list?.kind,'inductive');
  if(list?.kind==='inductive')equal(list.isRec,true);
  equal(
    result.environment.find(nameFromDotted('NatList.rec'))?.kind,
    'recursor',
  );
}
{
  const env=makeNatNotationEnvironment();
  let rejected=false;
  try{
    elaborateV061Declarations(parseV061Module(
      'inductive BadRec where { '+
      '| mk(f : BadRec -> Nat); }',
    ),env);
  }catch(error){
    rejected=/non-positive occurrence/.test(String(error));
  }
  equal(rejected,true);
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


{
  const env=makeNatNotationEnvironment();
  const result=elaborateV061Declarations(parseV061Module(
    'inductive PsList(α : Type) where { '+
    '| nil; | cons(head : α, tail : PsList(α)); } '+
    'function headOr {α : Type}'+
    '(value : PsList(α), fallback : α) : α := '+
    'match value with { | .nil => fallback; | .cons head tail => head; };',
  ),env);
  const list=result.environment.find(nameFromDotted('PsList'));
  equal(list?.kind,'inductive');
  if(list?.kind==='inductive')equal(list.isRec,true);
  const headOr=result.definitions.find(
    (item)=>item.name.kind==='str'&&item.name.value==='headOr',
  );
  equal(headOr?.kind,'definition');
}
console.log('ok - @proofscript/elab direct recursive inductive + recursor match');


function containsNamedConstant(
  expr:import('lean-ts-kernel').Expr,
  name:string,
):boolean {
  switch(expr.kind){
    case 'const':
      return expr.name.kind==='str'&&
        (expr.name.value===name||containsNamePrefix(expr.name,name));
    case 'app':
      return containsNamedConstant(expr.fn,name)
        ||containsNamedConstant(expr.arg,name);
    case 'lam':
    case 'forall':
      return containsNamedConstant(expr.type,name)
        ||containsNamedConstant(expr.body,name);
    case 'let':
      return containsNamedConstant(expr.type,name)
        ||containsNamedConstant(expr.value,name)
        ||containsNamedConstant(expr.body,name);
    case 'mdata':
    case 'proj':
      return containsNamedConstant(expr.expr,name);
    default:
      return false;
  }
}
function containsNamePrefix(
  name:import('lean-ts-kernel').Name,
  expected:string,
):boolean {
  const parts:string[]=[];
  let cursor=name;
  while(cursor.kind!=='anonymous'){
    if(cursor.kind==='str'){
      parts.push(cursor.value);
      cursor=cursor.prefix;
    }else{
      parts.push(String(cursor.value));
      cursor=cursor.prefix;
    }
  }
  return parts.reverse().join('.')===expected;
}

{
  const env=makeNatNotationEnvironment();
  const result=elaborateV061Declarations(parseV061Module(
    'inductive PsList(α : Type) where { '+
    '| nil; | cons(head : α, tail : PsList(α)); } '+
    'function length {α : Type}(xs : PsList(α)) : Nat := '+
    'match xs with { | .nil => 0; | .cons head tail => 1 + length(tail); };',
  ),env);
  const length=result.definitions.find(
    (item)=>containsNamePrefix(item.name,'length'),
  );
  equal(length?.kind,'definition');
  if(length?.kind==='definition'){
    equal(containsNamedConstant(length.value,'PsList.rec'),true);
    equal(containsNamedConstant(length.value,'length'),false);
  }
}
{
  const env=makeNatNotationEnvironment();
  let rejected=false;
  try{
    elaborateV061Declarations(parseV061Module(
      'inductive PsList(α : Type) where { '+
      '| nil; | cons(head : α, tail : PsList(α)); } '+
      'function bad {α : Type}(xs : PsList(α)) : Nat := '+
      'match xs with { | .nil => 0; | .cons head tail => bad(xs); };',
    ),env);
  }catch(error){
    rejected=/PS_ELAB_STRUCTURAL_RECURSION_NOT_DECREASING/.test(String(error));
  }
  equal(rejected,true);
}
console.log('ok - @proofscript/elab structural recursion via recursor');

{
  const env=makeNatNotationEnvironment();
  const result=elaborateV061Declarations(parseV061Module(
    'inductive PsList2(α : Type) where { '+
    '| nil; | cons(head : α, tail : PsList2(α)); } '+
    'function countFrom {α : Type}(base : Nat, xs : PsList2(α)) : Nat := '+
    'match xs with { | .nil => base; '+
    '| .cons head tail => 1 + countFrom(base, tail); };',
  ),env);
  const countFrom=result.definitions.find(
    (item)=>containsNamePrefix(item.name,'countFrom'),
  );
  equal(countFrom?.kind,'definition');
  if(countFrom?.kind==='definition'){
    equal(containsNamedConstant(countFrom.value,'PsList2.rec'),true);
    equal(containsNamedConstant(countFrom.value,'countFrom'),false);
  }
}
{
  const env=makeNatNotationEnvironment();
  let rejected=false;
  try{
    elaborateV061Declarations(parseV061Module(
      'inductive PsList3(α : Type) where { '+
      '| nil; | cons(head : α, tail : PsList3(α)); } '+
      'function badCount {α : Type}(base : Nat, xs : PsList3(α)) : Nat := '+
      'match xs with { | .nil => base; '+
      '| .cons head tail => badCount(0, tail); };',
    ),env);
  }catch(error){
    rejected=/PS_ELAB_STRUCTURAL_RECURSION_INVARIANT_ARGUMENT/.test(String(error));
  }
  equal(rejected,true);
}
console.log('ok - @proofscript/elab structural recursion with invariant parameters');



{
  const result=elaborateV061Declarations(parseV061Module(
    'structure Box(α : Type) where { value : α; } '+
    'function boxId {α : Type}(x : α) : Box(α) := '+
    '{ value := x : Box(α) }; '+
    'function unbox {α : Type}(box : Box(α)) : α := box.value;',
  ));
  equal(result.structures.length,1);
  const structure=result.structures[0]!;
  const info=result.environment.find(structure.name);
  equal(info?.kind,'inductive');
  if(info?.kind==='inductive')equal(info.numParams,1);
  const constructor=result.environment.find(structure.constructor);
  equal(constructor?.kind,'constructor');
  if(constructor?.kind==='constructor')equal(constructor.numParams,1);
  equal(result.definitions.length,2);
}
console.log('ok - @proofscript/elab generic structure admission');


{
  const env=makeDefinitionEnvironment();
  const result=elaborateV061Declarations(parseV061Module(
    'function use(x : TestNat) : TestNat := second(x) where { '+
    'second(y : TestNat) : TestNat := first(y); '+
    'first(y : TestNat) : TestNat := y; }',
  ),env);
  equal(result.definitions.length,1);
  const use=result.definitions[0]!;
  equal(use.value.kind,'lam');
}
{
  const env=makeDefinitionEnvironment();
  let recursive=false;
  try{
    elaborateV061Declarations(parseV061Module(
      'function use(x : TestNat) : TestNat := loop(x) where { '+
      'loop(y : TestNat) : TestNat := loop(y); }',
    ),env);
  }catch(error){
    recursive=/PS_ELAB_WHERE_RECURSION_UNSUPPORTED/.test(String(error));
  }
  equal(recursive,true);
}
console.log('ok - @proofscript/elab acyclic where local helpers');


{
  const env=makeNatNotationEnvironment();
  const result=elaborateV061Declarations(parseV061Module(
    'class Sized(α : Type) where { size : α -> Nat; }',
  ),env);
  equal(result.classes.length,1);
  equal(result.structures.length,1);
  equal(
    result.environment.find(nameFromDotted('Sized'))?.kind,
    'inductive',
  );
  equal(
    result.environment.find(nameFromDotted('Sized.mk'))?.kind,
    'constructor',
  );
  equal(
    result.environment.find(nameFromDotted('Sized.rec'))?.kind,
    'recursor',
  );
}
console.log('ok - @proofscript/elab class admission as kernel inductive');


{
  const env=makeNatNotationEnvironment();
  const result=elaborateV061Declarations(parseV061Module(
    'class Boxed(α : Type) where { value : α; } '+
    'function reuse {α : Type}[inst : Boxed(α)](x : α) : α := x; '+
    'function caller {α : Type}[inst : Boxed(α)](x : α) : α := reuse(x);',
  ),env);
  equal(result.classes.length,1);
  const caller=result.definitions.find(
    (item)=>item.name.kind==='str'&&item.name.value==='caller',
  );
  equal(caller?.kind,'definition');
  equal(caller?.value.kind,'lam');
}
console.log('ok - @proofscript/elab local class instance synthesis');


{
  const env=makeNatNotationEnvironment();
  const result=elaborateV061Declarations(parseV061Module(
    'class Boxed(α : Type) where { value : α; } '+
    'instance boxedNat : Boxed(Nat) := { value := 7 : Boxed(Nat) }; '+
    'instance boxedBoxedNat : Boxed(Boxed(Nat)) := '+
    '{ value := boxedNat : Boxed(Boxed(Nat)) }; '+
    'function get {α : Type}[inst : Boxed(α)](x : α) : α := inst.value; '+
    'function read(x : Nat) : Nat := get(x);',
  ),env);
  equal(result.classes.length,1);
  equal(result.instances.length,2);
  equal(result.instances[0]?.anonymous,false);
  equal(result.instances[1]?.anonymous,false);
  const read=result.definitions.find(
    (item)=>item.name.kind==='str'&&item.name.value==='read',
  );
  equal(read?.kind,'definition');
  equal(result.environment.find(nameFromDotted('boxedNat'))?.kind,'definition');
}
console.log('ok - @proofscript/elab global class instance synthesis');
