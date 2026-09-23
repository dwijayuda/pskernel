import {lowerDCallSource} from '../packages/syntax/dist/src/index.js';
import {text,render} from '../packages/pretty/dist/src/index.js';
import {ExprMetaContext,MetaVarContext,createGoal} from '../packages/meta/dist/src/index.js';
import {elaborateApplication,elaborateChecked} from '../packages/elab/dist/src/index.js';
import {Environment,Kernel,LocalContext,TypeChecker,bvar,constant,exprEq,forallE,levelSucc,levelZero,nameFromDotted,sort} from '../dist/src/index.js';
import {exact} from '../packages/tactic/dist/src/index.js';
import {freeVariables,validateIrModule} from '../packages/compiler-ir/dist/src/index.js';
import {nat,natAdd} from '../packages/runtime/dist/src/index.js';
import {emitModule} from '../packages/backend-ts/dist/src/index.js';
import {processDocument} from '../packages/language/dist/src/index.js';
import {PROOFSCRIPT_LSP_PROTOCOL_VERSION,lspCapabilities,toLspDiagnostics} from '../packages/lsp/dist/src/index.js';
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
