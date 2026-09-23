import {lowerDCallSource,parseV061Module} from '../packages/syntax/dist/src/index.js';
import {text,render} from '../packages/pretty/dist/src/index.js';
import {ExprMetaContext,MetaVarContext,createGoal} from '../packages/meta/dist/src/index.js';
import {elaborateApplication,elaborateChecked,elaborateV061Declarations} from '../packages/elab/dist/src/index.js';
import {Environment,Kernel,LocalContext,TypeChecker,bvar,constant,exprEq,forallE,levelSucc,levelZero,nameFromDotted,sort} from '../dist/src/index.js';
import {exact} from '../packages/tactic/dist/src/index.js';
import {freeVariables,validateIrModule,validateVerifiedIrModule} from '../packages/compiler-ir/dist/src/index.js';
import {eraseCheckedCoreModule} from '../packages/erasure/dist/src/index.js';
import {nat,natAdd} from '../packages/runtime/dist/src/index.js';
import {compileTypeScript,emitModule,emitVerifiedTypeScript} from '../packages/backend-ts/dist/src/index.js';
import {compileCheckedCore} from '../packages/compiler/dist/src/index.js';
import {compileVerifiedSource} from '../packages/cli/dist/src/verified-pipeline.js';
import {processDocument} from '../packages/language/dist/src/index.js';
import {PROOFSCRIPT_LSP_PROTOCOL_VERSION,createInitPreludeEnvironmentProvider,lspCapabilities,toLspDiagnostics} from '../packages/lsp/dist/src/index.js';
import {ProofScriptLanguageService} from '../packages/language-service/dist/src/index.js';
import {createBuildPlan} from '../packages/project/dist/src/index.js';
import {verifyStream} from '../packages/browser/dist/src/index.js';

function assert(condition,message){
  if(!condition)throw new Error('package integration smoke: '+message);
}

const lowered=lowerDCallSource('apply(f x, (y : Nat))');
assert(lowered.kind==='proofscript','syntax D-CALL lowering did not claim expected form');

const meta=new MetaVarContext();
const goal=createGoal(meta,'Nat');
meta.assign(goal.mvar,'zero');
assert(meta.getAssignment(goal.mvar)==='zero','meta assignment failed');

const elaborated=elaborateChecked({
  elaborate:(surface,{expectedType})=>({
    term:{surface,expectedType:expectedType??null},
    diagnostics:[],
  }),
},'zero',{expectedType:'Nat'});
assert(elaborated.expectedType==='Nat','elaboration expected type did not flow');


const kernelEnv=new Environment();
const kernel=new Kernel(kernelEnv);
const TestNat=nameFromDotted('Integration.Nat');
const testZero=nameFromDotted('Integration.zero');
const testId=nameFromDotted('Integration.id');
kernel.addAxiom({
  kind:'axiom',
  name:TestNat,
  levelParams:[],
  type:sort(levelSucc(levelZero)),
});
kernel.addAxiom({
  kind:'axiom',
  name:testZero,
  levelParams:[],
  type:constant(TestNat),
});
kernel.addAxiom({
  kind:'axiom',
  name:testId,
  levelParams:[],
  type:forallE(
    nameFromDotted('α'),
    sort(levelSucc(levelZero)),
    forallE(nameFromDotted('x'),bvar(0),bvar(1)),
    'implicit',
  ),
});
const exprMeta=new ExprMetaContext(kernelEnv);
const applied=elaborateApplication({
  environment:kernelEnv,
  metaContext:exprMeta,
  fn:constant(testId),
  args:[constant(testZero)],
});
assert(applied.inserted.length===1,'real application elaborator did not insert implicit argument');
assert(exprMeta.snapshotAssignments().size===1,'implicit type metavariable was not solved');
assert(exprEq(applied.type,constant(TestNat)),'application elaborator produced wrong dependent result type');
const appliedType=new TypeChecker(kernelEnv,new LocalContext()).check(applied.term);
assert(exprEq(appliedType,constant(TestNat)),'kernel rejected grounded elaborated application');

const tacticState=exact(
  {goals:[{target:'Nat',locals:[]}],proofs:[]},
  'zero',
  {inferType:()=> 'Nat',isDefEq:(a,b)=>a===b},
);
assert(tacticState.goals.length===0,'tactic exact did not solve goal');

const irExpr={
  kind:'lambda',
  params:['x'],
  body:{kind:'call',fn:{kind:'var',name:'f'},args:[{kind:'var',name:'x'}]},
};
assert(freeVariables(irExpr).join(',')==='f','compiler IR free-variable analysis failed');
const irModule={name:'Demo',bindings:[{name:'main',value:{kind:'literal',value:1}}]};
validateIrModule(irModule);
const emitted=emitModule(irModule);
assert(emitted.includes('export const main = 1;'),'backend TS emission failed');
assert(natAdd(nat(2),nat(3))===5n,'runtime Nat semantics failed');

const verifiedSurface=parseV061Module(
  'function identity {α : Type}(x : α) : α := x;',
);
const checkedCore=elaborateV061Declarations(verifiedSurface);
assert(
  checkedCore.kind==='proofscript-checked-core',
  'elaborator did not produce checked dependent core',
);
const verifiedIr=eraseCheckedCoreModule(checkedCore);
validateVerifiedIrModule(verifiedIr);
const verifiedTs=emitVerifiedTypeScript(verifiedIr);
const verifiedJs=compileTypeScript(
  verifiedTs,
  'verified-identity.ts',
);
assert(
  verifiedTs.includes('identity<T0>(x: T0): T0'),
  'verified generic type information was not preserved in TypeScript',
);
assert(
  verifiedJs.javascript.includes('function identity(x)'),
  'verified generic function did not compile to JavaScript',
);
assert(
  !verifiedJs.javascript.includes('T0'),
  'erased dependent type parameter leaked into JavaScript',
);
assert(
  verifiedJs.declaration.includes('identity<T0>(x: T0): T0'),
  'generic API was not preserved in .d.ts',
);


const compilerOrchestrated=compileCheckedCore(
  checkedCore,
  'verified-identity-orchestrated.ts',
);
assert(
  compilerOrchestrated.emitted.javascript.includes('function identity(x)'),
  'checked-core compiler orchestration did not produce JavaScript',
);


const proofCarrying=compileVerifiedSource(
  'function keep {α : Type}(P : Prop, h : P, x : α) : α := x;',
  'proof-erasure.ts',
);
assert(
  proofCarrying.typeScript.includes('keep<T0>(x: T0): T0'),
  'Prop/proof binders were not erased from the verified TypeScript API',
);
assert(
  !proofCarrying.typeScript.includes('P:')&&
  !proofCarrying.typeScript.includes('h:'),
  'proof-carrying generic source leaked proposition/proof parameters',
);
assert(
  proofCarrying.emitted.javascript.includes('function keep(x)'),
  'proof-carrying generic did not erase to the expected runtime arity',
);


const verifiedNat=compileVerifiedSource(
  'function add(x : Nat, y : Nat) : Nat := x + y; '+
  'function twice(x : Nat) : Nat := add(x, x); '+
  'function sub(x : Nat, y : Nat) : Nat := x - y;',
  'verified-nat.ts',
);
assert(
  verifiedNat.checkedCore.definitions.length===3,
  'verified Nat source was not admitted as three checked definitions',
);
assert(
  verifiedNat.typeScript.includes(
    'function add(x: bigint, y: bigint): bigint',
  ),
  'verified Nat.add did not reach typed TypeScript',
);
assert(
  verifiedNat.typeScript.includes('return (x + y);'),
  'verified Nat.add intrinsic did not emit bigint addition',
);
assert(
  verifiedNat.typeScript.includes('return add(x, x);'),
  'verified Nat functions did not compose through checked core',
);
assert(
  verifiedNat.typeScript.includes(
    '__ps_a >= __ps_b ? __ps_a - __ps_b : 0n',
  ),
  'verified Nat.sub lost saturating Lean semantics',
);
assert(
  verifiedNat.emitted.javascript.includes('function twice(x)'),
  'verified Nat composition did not compile to JavaScript',
);


const verifiedIf=compileVerifiedSource(
  'function min(x : Nat, y : Nat) : Nat := '+
  'if (x <= y) { x } else { y }; '+
  'function max(x : Nat, y : Nat) : Nat := '+
  'if (x > y) { x } else { y };',
  'verified-if.ts',
);
assert(
  verifiedIf.typeScript.includes('return ((x <= y) ? x : y);'),
  'verified Lean ite did not lower through Nat ≤',
);
assert(
  verifiedIf.typeScript.includes('return ((y < x) ? x : y);'),
  'verified Lean > relation did not normalize to reversed Nat <',
);




const verifiedStructure=compileVerifiedSource(
  'structure User where { age : Nat; } '+
  'function make(age : Nat) : User := { age := age : User }; '+
  'function get(user : User) : Nat := user.age;',
  'verified-structure.ts',
);
assert(
  verifiedStructure.typeScript.includes('export interface User {'),
  'verified checked structure did not reach TypeScript interface emission',
);
assert(
  verifiedStructure.typeScript.includes('return user.age;'),
  'verified kernel projection did not reach TypeScript field access',
);
assert(
  verifiedStructure.emitted.javascript.includes('Symbol("ProofScript.User")'),
  'verified structure lost nominal runtime branding',
);
assert(
  verifiedStructure.emitted.declaration.includes('export interface User'),
  'verified structure API was not preserved in .d.ts',
);




const verifiedAdt=compileVerifiedSource(
  'inductive MaybeNat where { | none; | some(value : Nat); } '+
  'const noneValue : MaybeNat := MaybeNat.none; '+
  'const oneValue : MaybeNat := MaybeNat.some(1);',
  'verified-adt.ts',
);
assert(
  verifiedAdt.typeScript.includes('export type MaybeNat ='),
  'verified checked inductive did not reach TypeScript union emission',
);
assert(
  verifiedAdt.typeScript.includes('MaybeNat["some"](1n)'),
  'verified constructor application did not reach runtime factory',
);
assert(
  verifiedAdt.emitted.javascript.includes(
    'Symbol("ProofScript.MaybeNat.tag")',
  ),
  'verified ADT lost nominal runtime constructor tag',
);
assert(
  verifiedAdt.emitted.declaration.includes('export declare const MaybeNat'),
  'verified ADT constructor API was not preserved in .d.ts',
);


const verifiedAdtMatch=compileVerifiedSource(
  'inductive MaybeNat where { | none; | some(value : Nat); } '+
  'function getOrZero(value : MaybeNat) : Nat := '+
  'match value with { | .none => 0; | .some x => x; };',
  'verified-adt-match.ts',
);
assert(
  verifiedAdtMatch.ir.declarations.find(
    (item)=>item.name==='getOrZero',
  )?.body.kind==='match',
  'verified ADT match did not reach explicit compiler IR',
);
assert(
  verifiedAdtMatch.typeScript.includes(
    'switch (__ps$match$0[__ps$tag$0])',
  ),
  'verified ADT match did not reach TypeScript tagged-union dispatch',
);
assert(
  verifiedAdtMatch.typeScript.includes(
    'case "some": return ((x) => x)(__ps$match$0.value);',
  ),
  'verified ADT match field binding was not preserved',
);
assert(
  verifiedAdtMatch.emitted.javascript.includes('case "some"'),
  'verified ADT match did not compile to JavaScript',
);


const snapshot=processDocument('demo.ps',1,'x!',{
  process:text=>({
    state:{length:text.length},
    diagnostics:[{severity:'error',message:'bang',start:1,end:2}],
  }),
});
const diagnostics=toLspDiagnostics(snapshot.text,snapshot.diagnostics);
assert(diagnostics[0]?.range.start.character===1,'language/LSP diagnostic mapping failed');


const editorService=new ProofScriptLanguageService();
editorService.openDocument(
  'file:///integration.ps',
  1,
  'theorem editorProof(P : Prop, h : P) : P := by assumption;',
);
const editorAnalysis=editorService.analyze('file:///integration.ps');
assert(editorAnalysis.kernel==='verified','editor service must derive verified only from pskernel admission');
assert(
  editorService.proofState(
    'file:///integration.ps',
    {line:0,character:12},
  ).status==='closed',
  'verified theorem should expose closed declaration-level proof state',
);
assert(PROOFSCRIPT_LSP_PROTOCOL_VERSION===1,'LSP protocol drift');
assert(lspCapabilities().hoverProvider===true,'LSP hover capability missing');

const plan=createBuildPlan([
  {name:'app',dependencies:['core']},
  {name:'core',dependencies:[]},
]);
assert(plan.order.join(',')==='core,app','project build order failed');

const verified=await verifyStream([1,2,3],{
  createState:()=>({sum:0}),
  push:(state,chunk)=>{state.sum+=chunk;},
  finish:state=>state.sum,
});
assert(verified===6,'browser verification stream failed');
assert(render(text('ok'))==='ok','pretty rendering failed');

console.log('package integration smoke: PASS');


const preludeProvider=createInitPreludeEnvironmentProvider();
const preludeStatus=preludeProvider.status();
assert(preludeStatus.loaded===true,'editor prelude environment did not load');
const preludeService=new ProofScriptLanguageService({
  environmentFactory:()=>preludeProvider.create(),
});
preludeService.openDocument(
  'file:///prelude-editor.ps',
  1,
  'function idNat(x : Nat) : Nat := x;',
);
assert(
  preludeService.documentStatus('file:///prelude-editor.ps').kernel==='verified',
  'Init.Prelude-backed editor service did not verify ordinary Nat declaration',
);
