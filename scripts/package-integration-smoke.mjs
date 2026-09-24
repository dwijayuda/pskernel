import {
  createDefaultSourceFrontendRegistry,
  createDefaultTranslationTargetPrinterRegistry,
  lowerDCallSource,
  parseV061Module,
} from '../packages/syntax/dist/src/index.js';
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
import {
  checkVerifiedSource,
  compileVerifiedSource,
} from '../packages/cli/dist/src/verified-pipeline.js';
import {runCommand} from '../packages/cli/dist/src/commands/run.js';
import {readFileSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
import {PROOFSCRIPT_LSP_PROTOCOL_VERSION,createInitPreludeEnvironmentProvider,lspCapabilities,toLspDiagnostics} from '../packages/lsp/dist/src/index.js';
import {ProofScriptLanguageService} from '../packages/language-service/dist/src/index.js';
import {createBuildPlan} from '../packages/project/dist/src/index.js';
import {verifyStream} from '../packages/browser/dist/src/index.js';

function assert(condition,message){
  if(!condition)throw new Error('package integration smoke: '+message);
}

function semanticFingerprint(value){
  return JSON.stringify(
    value,
    (_key,item)=>typeof item==='bigint'
      ?{$bigint:item.toString()}
      :item,
  );
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

let tacticAssignment;
const tacticState=exact(
  {goals:[{id:'g0',target:'Nat',locals:[]}]},
  'zero',
  {
    inferType:()=> 'Nat',
    isDefEq:(a,b)=>a===b,
    assign:(goal,proof)=>{
      tacticAssignment={goal:goal.id,proof};
    },
  },
);
assert(tacticState.goals.length===0,'tactic exact did not solve goal');
assert(
  tacticAssignment?.goal==='g0'&&tacticAssignment?.proof==='zero',
  'tactic exact did not assign the checked proof to the solved goal',
);

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


const verifiedApply=compileVerifiedSource(
  'theorem applyPremise(P : Prop, Q : Prop, f : P -> Q, h : P) : Q := '+
  'by apply f; assumption;',
  'verified-apply.ts',
);
assert(
  verifiedApply.checkedCore.theorems.length===1,
  'bounded apply did not construct a pskernel-admitted theorem proof term',
);


const verifiedRewrite=compileVerifiedSource(
  'theorem rewriteForward(a : Nat, b : Nat, h : a = b) : '+
  'a = b := by rw [h]; '+
  'theorem rewriteReverse(a : Nat, b : Nat, h : a = b) : '+
  'b = a := by rw [← h];',
  'verified-rewrite.ts',
);
assert(
  verifiedRewrite.checkedCore.theorems.length===2,
  'bounded rw did not construct pskernel-admitted equality transport proofs',
);


const verifiedSimpOnly=compileVerifiedSource(
  'inductive BoxT(α : Type) where { | mk; } '+
  'inductive WrapT(α : Type) where { | mk; } '+
  'inductive PairT(α : Type, β : Type) where { | mk; } '+
  'theorem simplifyTypes'+
  '(A : Type, B : Type, C : Type, D : Type, '+
  'h1 : BoxT(A) = B, h2 : WrapT(C) = D) : '+
  'PairT(BoxT(A), WrapT(C)) = PairT(B, D) := '+
  'by simp only [h1, h2];',
  'verified-simp-only.ts',
);
assert(
  verifiedSimpOnly.checkedCore.theorems.length===1,
  'bounded multi-rule simp only did not construct a pskernel-admitted proof',
);


const verifiedDependentTheoremType=compileVerifiedSource(
  'theorem succRewrite(a : Nat, h : Nat.succ(a) = a) : '+
  'Nat.succ(a) = a := by rw [h];',
  'verified-dependent-theorem-type.ts',
);
assert(
  verifiedDependentTheoremType.checkedCore.theorems.length===1,
  'dependent term application in theorem result type was not admitted',
);


const verifiedArithmeticTheoremType=compileVerifiedSource(
  'theorem addZeroAssumed(n : Nat, h : n + 0 = n) : '+
  'n + 0 = n := by rw [h];',
  'verified-arithmetic-theorem-type.ts',
);
assert(
  verifiedArithmeticTheoremType.checkedCore.theorems.length===1,
  'Nat arithmetic/literal theorem result syntax was not admitted',
);


const verifiedRelationTheoremType=compileVerifiedSource(
  'theorem leAssumed(x : Nat, y : Nat, h : x <= y) : '+
  'x <= y := by assumption; '+
  'theorem gtAssumed(x : Nat, y : Nat, h : x > y) : '+
  'x > y := by assumption;',
  'verified-relation-theorem-type.ts',
);
assert(
  verifiedRelationTheoremType.checkedCore.theorems.length===2,
  'Nat relation theorem result syntax was not admitted',
);


const verifiedBoolTheoremTerms=compileVerifiedSource(
  'theorem beqAssumed(x : Nat, y : Nat, h : x == y = true) : '+
  'x == y = true := by assumption; '+
  'theorem boolLogicAssumed(p : Bool, q : Bool, h : !p || q = true) : '+
  '!p || q = true := by assumption;',
  'verified-bool-theorem-terms.ts',
);
assert(
  verifiedBoolTheoremTerms.checkedCore.theorems.length===2,
  'Bool-valued theorem term syntax was not admitted inside propositions',
);


const verifiedDependentPi=compileVerifiedSource(
  'theorem dependentPiReflexive'+
  '(f : (x : Nat) -> x = x, n : Nat) : n = n := by exact f(n);',
  'verified-dependent-pi.ts',
);
assert(
  verifiedDependentPi.checkedCore.theorems.length===1,
  'explicit dependent Pi binder was not admitted through checked core',
);


const verifiedExactSearch=compileVerifiedSource(
  'theorem exactSearchBase(P : Prop, h : P) : P := by assumption; '+
  'theorem exactSearchCopy : (P : Prop) -> P -> P := by exact?;',
  'verified-exact-search.ts',
);
assert(
  verifiedExactSearch.checkedCore.theorems.length===2,
  'bounded exact? did not construct a pskernel-admitted proof',
);


const verifiedExactSearchApplication=compileVerifiedSource(
  'theorem exactSearchPoly {P : Prop} : P -> P := '+
  'by intro h; exact h; '+
  'theorem exactSearchPolyUse(Q : Prop) : Q -> Q := by exact?;',
  'verified-exact-search-application.ts',
);
assert(
  verifiedExactSearchApplication.checkedCore.theorems.length===2,
  'bounded exact? did not infer a zero-subgoal candidate argument',
);


const verifiedExactSearchSymmetry=compileVerifiedSource(
  'theorem exactSearchSymm'+
  '(a : Nat, b : Nat, h : b = a) : a = b := by exact?;',
  'verified-exact-search-symmetry.ts',
);
assert(
  verifiedExactSearchSymmetry.checkedCore.theorems.length===1,
  'bounded exact? Eq symmetry did not construct a pskernel-admitted proof',
);


const dualSourceCorpus=
  'structure Box(α : Type) where { value : α; } '+
  'class Sized(α : Type) where { size : α -> Nat; } '+
  'inductive Choice where { | left; | right; } '+
  'instance sizedNat : Sized(Nat) := '+
  '{ size := fun x => x : Sized(Nat) }; '+
  'def choose(flag : Bool) : Nat := match flag with { '+
  '| true => 1; | false => 2; }; '+
  'def viaWhere(x : Nat) : Nat := helper(x) where { '+
  'helper(y : Nat) : Nat := y + 1; }; '+
  'theorem exactSearchProof(P : Prop, h : P) : P := by exact?;';

const dualFrontends=createDefaultSourceFrontendRegistry();
const dualTargets=createDefaultTranslationTargetPrinterRegistry();

const dualPs=compileVerifiedSource(
  dualSourceCorpus,
  'dual-source-equivalence.ts',
  'dual-source-equivalence.ps',
);
const dualLeanSource=dualTargets.require('lean').print(dualPs.surface);
const dualLean=compileVerifiedSource(
  dualLeanSource,
  'dual-source-equivalence.ts',
  'dual-source-equivalence.lean',
);
const dualProofScriptSource=dualTargets.require('ps').print(dualLean.surface);
const dualPsRoundTrip=compileVerifiedSource(
  dualProofScriptSource,
  'dual-source-equivalence.ts',
  'dual-source-equivalence-roundtrip.ps',
);

assert(
  dualFrontends.forFile('x.ps').kind==='proofscript'
    &&dualFrontends.forFile('x.lean').kind==='lean-subset',
  'dual-source frontend registry did not select both source kinds',
);
assert(
  dualPs.canonicalSourceHash===dualLean.canonicalSourceHash
    &&dualLean.canonicalSourceHash===dualPsRoundTrip.canonicalSourceHash,
  'dual-source canonical source identity diverged',
);
assert(
  dualProofScriptSource===dualPs.canonicalSource,
  'Lean -> ProofScript translation did not recover canonical shared source',
);
assert(
  semanticFingerprint(dualPs.checkedCore.admissions)
    ===semanticFingerprint(dualLean.checkedCore.admissions)
    &&semanticFingerprint(dualLean.checkedCore.admissions)
      ===semanticFingerprint(dualPsRoundTrip.checkedCore.admissions),
  'PS/Lean round-trip changed pskernel checked-core admissions',
);
assert(
  semanticFingerprint(dualPs.ir)===semanticFingerprint(dualLean.ir)
    &&semanticFingerprint(dualLean.ir)
      ===semanticFingerprint(dualPsRoundTrip.ir),
  'PS/Lean round-trip changed verified compiler IR',
);
assert(
  dualPs.typeScript===dualLean.typeScript
    &&dualLean.typeScript===dualPsRoundTrip.typeScript,
  'PS/Lean round-trip changed emitted TypeScript',
);
assert(
  dualPs.emitted.javascript===dualLean.emitted.javascript
    &&dualLean.emitted.javascript===dualPsRoundTrip.emitted.javascript,
  'PS/Lean round-trip changed emitted JavaScript',
);
assert(
  dualPs.emitted.declaration===dualLean.emitted.declaration
    &&dualLean.emitted.declaration===dualPsRoundTrip.emitted.declaration,
  'PS/Lean round-trip changed emitted TypeScript declarations',
);

const dualTextSourceCorpus=
  'def charCode(c : Char) : Nat := Char.toNat(c); '+
  'def oneChar(c : Char) : String := String.singleton(c); '+
  'def textLength(s : String) : Nat := String.Internal.length(s); '+
  'def pushChar(s : String, c : Char) : String := String.push(s, c); '+
  'def appendText(a : String, b : String) : String := String.Internal.append(a, b); '+
  'def mkPos(n : Nat) : String.Pos.Raw := String.Pos.Raw.mk(n); '+
  'def posByte(p : String.Pos.Raw) : Nat := String.Pos.Raw.byteIdx(p); '+
  'def byteSize(s : String) : Nat := String.utf8ByteSize(s); '+
  'def nextPos(s : String, p : String.Pos.Raw) : String.Pos.Raw := '+
  'String.Internal.next(s, p); '+
  'def getAt(s : String, p : String.Pos.Raw) : Char := '+
  'String.Internal.get(s, p); '+
  'def atEnd(s : String, p : String.Pos.Raw) : Bool := '+
  'String.Internal.atEnd(s, p); '+
  'def extractText(s : String, b : String.Pos.Raw, e : String.Pos.Raw) : String := '+
  'String.Internal.extract(s, b, e); '+
  'def sameText(a : String, b : String) : Bool := a == b; '+
  'def sameChar(a : Char, b : Char) : Bool := a == b;';

const dualTextPs=compileVerifiedSource(
  dualTextSourceCorpus,
  'dual-text-equivalence.ts',
  'dual-text-equivalence.ps',
);
const dualTextLeanSource=dualTargets.require('lean').print(dualTextPs.surface);
const dualTextLean=compileVerifiedSource(
  dualTextLeanSource,
  'dual-text-equivalence.ts',
  'dual-text-equivalence.lean',
);
const dualTextPsSource=dualTargets.require('ps').print(dualTextLean.surface);
const dualTextPsRoundTrip=compileVerifiedSource(
  dualTextPsSource,
  'dual-text-equivalence.ts',
  'dual-text-equivalence-roundtrip.ps',
);

assert(
  dualTextPs.canonicalSourceHash===dualTextLean.canonicalSourceHash
    &&dualTextLean.canonicalSourceHash===
      dualTextPsRoundTrip.canonicalSourceHash,
  'SH1 PS/Lean text canonical source identity diverged',
);
assert(
  semanticFingerprint(dualTextPs.checkedCore.admissions)
    ===semanticFingerprint(dualTextLean.checkedCore.admissions)
    &&semanticFingerprint(dualTextLean.checkedCore.admissions)
      ===semanticFingerprint(dualTextPsRoundTrip.checkedCore.admissions),
  'SH1 PS/Lean text changed pskernel checked-core admissions',
);
assert(
  semanticFingerprint(dualTextPs.ir)
    ===semanticFingerprint(dualTextLean.ir)
    &&semanticFingerprint(dualTextLean.ir)
      ===semanticFingerprint(dualTextPsRoundTrip.ir),
  'SH1 PS/Lean text changed verified compiler IR',
);
assert(
  dualTextPs.typeScript===dualTextLean.typeScript
    &&dualTextLean.typeScript===dualTextPsRoundTrip.typeScript,
  'SH1 PS/Lean text changed emitted TypeScript',
);
assert(
  dualTextPs.emitted.javascript===dualTextLean.emitted.javascript
    &&dualTextLean.emitted.javascript===
      dualTextPsRoundTrip.emitted.javascript,
  'SH1 PS/Lean text changed emitted JavaScript',
);
assert(
  dualTextPs.emitted.declaration===dualTextLean.emitted.declaration
    &&dualTextLean.emitted.declaration===
      dualTextPsRoundTrip.emitted.declaration,
  'SH1 PS/Lean text changed emitted TypeScript declarations',
);

const lexerModuleSource=readFileSync(
  new URL('../stdlib/src/ProofScript/Text/Lexer.ps',import.meta.url),
  'utf8',
);
const lexerModulePs=compileVerifiedSource(
  lexerModuleSource,
  'proofscript-text-lexer.ts',
  'ProofScript/Text/Lexer.ps',
);
const lexerModuleLeanSource=
  dualTargets.require('lean').print(lexerModulePs.surface);
const lexerModuleLean=compileVerifiedSource(
  lexerModuleLeanSource,
  'proofscript-text-lexer.ts',
  'ProofScript/Text/Lexer.lean',
);
const lexerModulePsSource=
  dualTargets.require('ps').print(lexerModuleLean.surface);
const lexerModulePsRoundTrip=compileVerifiedSource(
  lexerModulePsSource,
  'proofscript-text-lexer.ts',
  'ProofScript/Text/Lexer.roundtrip.ps',
);

assert(
  lexerModulePs.canonicalSourceHash===lexerModuleLean.canonicalSourceHash
    &&lexerModuleLean.canonicalSourceHash===
      lexerModulePsRoundTrip.canonicalSourceHash,
  'ProofScript.Text.Lexer dual-source canonical identity diverged\n'+
    '--- from ProofScript ---\n'+lexerModulePs.canonicalSource+
    '--- from Lean ---\n'+lexerModuleLean.canonicalSource+
    '--- round-trip ProofScript ---\n'+
      lexerModulePsRoundTrip.canonicalSource,
);
assert(
  semanticFingerprint(lexerModulePs.checkedCore.admissions)
    ===semanticFingerprint(lexerModuleLean.checkedCore.admissions)
    &&semanticFingerprint(lexerModuleLean.checkedCore.admissions)
      ===semanticFingerprint(
        lexerModulePsRoundTrip.checkedCore.admissions,
      ),
  'ProofScript.Text.Lexer dual-source checked-core fingerprint diverged',
);
assert(
  semanticFingerprint(lexerModulePs.ir)
    ===semanticFingerprint(lexerModuleLean.ir)
    &&semanticFingerprint(lexerModuleLean.ir)
      ===semanticFingerprint(lexerModulePsRoundTrip.ir),
  'ProofScript.Text.Lexer dual-source compiler IR diverged',
);
assert(
  lexerModulePs.typeScript===lexerModuleLean.typeScript
    &&lexerModuleLean.typeScript===lexerModulePsRoundTrip.typeScript,
  'ProofScript.Text.Lexer dual-source TypeScript diverged',
);
assert(
  lexerModulePs.emitted.javascript===lexerModuleLean.emitted.javascript
    &&lexerModuleLean.emitted.javascript===
      lexerModulePsRoundTrip.emitted.javascript,
  'ProofScript.Text.Lexer dual-source JavaScript diverged',
);
assert(
  lexerModulePs.emitted.declaration===lexerModuleLean.emitted.declaration
    &&lexerModuleLean.emitted.declaration===
      lexerModulePsRoundTrip.emitted.declaration,
  'ProofScript.Text.Lexer dual-source declarations diverged',
);

const productModuleSource=readFileSync(
  new URL('../stdlib/src/ProofScript/Data/Product.ps',import.meta.url),
  'utf8',
);
const productModulePs=compileVerifiedSource(
  productModuleSource,
  'proofscript-data-product.ts',
  'ProofScript/Data/Product.ps',
);
const productModuleLeanSource=
  dualTargets.require('lean').print(productModulePs.surface);
const productModuleLean=compileVerifiedSource(
  productModuleLeanSource,
  'proofscript-data-product.ts',
  'ProofScript/Data/Product.lean',
);
const productModulePsSource=
  dualTargets.require('ps').print(productModuleLean.surface);
const productModulePsRoundTrip=compileVerifiedSource(
  productModulePsSource,
  'proofscript-data-product.ts',
  'ProofScript/Data/Product.roundtrip.ps',
);

assert(
  productModulePs.canonicalSourceHash===productModuleLean.canonicalSourceHash
    &&productModuleLean.canonicalSourceHash===
      productModulePsRoundTrip.canonicalSourceHash,
  'ProofScript.Data.Product dual-source canonical identity diverged\n'+
    '--- from ProofScript ---\n'+productModulePs.canonicalSource+
    '--- from Lean ---\n'+productModuleLean.canonicalSource+
    '--- round-trip ProofScript ---\n'+
      productModulePsRoundTrip.canonicalSource,
);
assert(
  semanticFingerprint(productModulePs.checkedCore.admissions)
    ===semanticFingerprint(productModuleLean.checkedCore.admissions)
    &&semanticFingerprint(productModuleLean.checkedCore.admissions)
      ===semanticFingerprint(productModulePsRoundTrip.checkedCore.admissions),
  'ProofScript.Data.Product checked-core fingerprint diverged',
);
assert(
  semanticFingerprint(productModulePs.ir)
    ===semanticFingerprint(productModuleLean.ir)
    &&semanticFingerprint(productModuleLean.ir)
      ===semanticFingerprint(productModulePsRoundTrip.ir),
  'ProofScript.Data.Product compiler IR diverged',
);
assert(
  productModulePs.typeScript===productModuleLean.typeScript
    &&productModuleLean.typeScript===productModulePsRoundTrip.typeScript,
  'ProofScript.Data.Product TypeScript diverged',
);
assert(
  productModulePs.emitted.javascript===productModuleLean.emitted.javascript
    &&productModuleLean.emitted.javascript===
      productModulePsRoundTrip.emitted.javascript,
  'ProofScript.Data.Product JavaScript diverged',
);
assert(
  productModulePs.emitted.declaration===productModuleLean.emitted.declaration
    &&productModuleLean.emitted.declaration===
      productModulePsRoundTrip.emitted.declaration,
  'ProofScript.Data.Product declarations diverged',
);

const arrayModuleSource=readFileSync(
  new URL('../stdlib/src/ProofScript/Data/Array.ps',import.meta.url),
  'utf8',
);
const arrayModulePs=compileVerifiedSource(
  arrayModuleSource,
  'proofscript-data-array.ts',
  'ProofScript/Data/Array.ps',
);
const arrayModuleLeanSource=
  dualTargets.require('lean').print(arrayModulePs.surface);
const arrayModuleLean=compileVerifiedSource(
  arrayModuleLeanSource,
  'proofscript-data-array.ts',
  'ProofScript/Data/Array.lean',
);
const arrayModulePsSource=
  dualTargets.require('ps').print(arrayModuleLean.surface);
const arrayModulePsRoundTrip=compileVerifiedSource(
  arrayModulePsSource,
  'proofscript-data-array.ts',
  'ProofScript/Data/Array.roundtrip.ps',
);

assert(
  arrayModulePs.canonicalSourceHash===arrayModuleLean.canonicalSourceHash
    &&arrayModuleLean.canonicalSourceHash===
      arrayModulePsRoundTrip.canonicalSourceHash,
  'ProofScript.Data.Array dual-source canonical identity diverged\n'+
    '--- from ProofScript ---\n'+arrayModulePs.canonicalSource+
    '--- from Lean ---\n'+arrayModuleLean.canonicalSource+
    '--- round-trip ProofScript ---\n'+
      arrayModulePsRoundTrip.canonicalSource,
);
assert(
  semanticFingerprint(arrayModulePs.checkedCore.admissions)
    ===semanticFingerprint(arrayModuleLean.checkedCore.admissions)
    &&semanticFingerprint(arrayModuleLean.checkedCore.admissions)
      ===semanticFingerprint(arrayModulePsRoundTrip.checkedCore.admissions),
  'ProofScript.Data.Array checked-core fingerprint diverged',
);
assert(
  semanticFingerprint(arrayModulePs.ir)
    ===semanticFingerprint(arrayModuleLean.ir)
    &&semanticFingerprint(arrayModuleLean.ir)
      ===semanticFingerprint(arrayModulePsRoundTrip.ir),
  'ProofScript.Data.Array compiler IR diverged',
);
assert(
  arrayModulePs.typeScript===arrayModuleLean.typeScript
    &&arrayModuleLean.typeScript===arrayModulePsRoundTrip.typeScript,
  'ProofScript.Data.Array TypeScript diverged',
);
assert(
  arrayModulePs.emitted.javascript===arrayModuleLean.emitted.javascript
    &&arrayModuleLean.emitted.javascript===
      arrayModulePsRoundTrip.emitted.javascript,
  'ProofScript.Data.Array JavaScript diverged',
);
assert(
  arrayModulePs.emitted.declaration===arrayModuleLean.emitted.declaration
    &&arrayModuleLean.emitted.declaration===
      arrayModulePsRoundTrip.emitted.declaration,
  'ProofScript.Data.Array declarations diverged',
);

let unsupportedLeanRejected=false;
try{
  compileVerifiedSource(
    'namespace Demo\ndef x : Nat := 0\nend Demo\n',
    'unsupported-lean.ts',
    'unsupported-lean.lean',
  );
}catch(error){
  unsupportedLeanRejected=
    /PS_LEAN_SUBSET_UNSUPPORTED_COMMAND/.test(String(error));
}
assert(
  unsupportedLeanRejected,
  'unsupported Lean command did not fail closed before checked core',
);


const verifiedNat=compileVerifiedSource(
  'function add(x : Nat, y : Nat) : Nat := x + y; '+
  'function twice(x : Nat) : Nat := add(x, x); '+
  'function sub(x : Nat, y : Nat) : Nat := x - y; '+
  'function div(x : Nat, y : Nat) : Nat := x / y; '+
  'function mod(x : Nat, y : Nat) : Nat := x % y;',
  'verified-nat.ts',
);
assert(
  verifiedNat.checkedCore.definitions.length===5,
  'verified Nat source was not admitted as five checked definitions',
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
  verifiedNat.typeScript.includes(
    '__ps_b === 0n ? 0n : __ps_a / __ps_b',
  ),
  'verified Nat.div lost Lean total division-by-zero semantics',
);
assert(
  verifiedNat.typeScript.includes(
    '__ps_b === 0n ? __ps_a : __ps_a % __ps_b',
  ),
  'verified Nat.mod lost Lean total modulo-by-zero semantics',
);
assert(
  verifiedNat.emitted.javascript.includes('function twice(x)'),
  'verified Nat composition did not compile to JavaScript',
);


const verifiedIf=compileVerifiedSource(
  'function min(x : Nat, y : Nat) : Nat := '+
  'if (x <= y) { x } else { y }; '+
  'function max(x : Nat, y : Nat) : Nat := '+
  'if (x > y) { x } else { y }; '+
  'function sameOr(x : Nat, y : Nat) : Nat := '+
  'if (x == y) { x } else { y }; '+
  'function same(x : Nat, y : Nat) : Bool := x == y; '+
  'function differentOr(x : Nat, y : Nat) : Nat := '+
  'if (x != y) { x } else { y }; '+
  'function different(x : Nat, y : Nat) : Bool := x != y;',
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
assert(
  verifiedIf.typeScript.includes('return ((x === y) ? x : y);'),
  'verified Lean Nat == condition did not lower through Nat.beq/Bool coercion',
);
assert(
  verifiedIf.typeScript.includes(
    'function same(x: bigint, y: bigint): boolean',
  ),
  'verified Nat == did not retain its Bool result outside a condition',
);
assert(
  verifiedIf.typeScript.includes('return ((x !== y) ? x : y);'),
  'verified Lean Nat != condition did not lower through bne semantics',
);
assert(
  verifiedIf.typeScript.includes(
    'function different(x: bigint, y: bigint): boolean',
  ),
  'verified Nat != did not retain its Bool result outside a condition',
);
assert(
  verifiedIf.typeScript.includes('return (x !== y);'),
  'verified Nat != did not emit the checked direct Bool comparison',
);




const verifiedBoolLogic=compileVerifiedSource(
  'function logic(a : Bool, b : Bool) : Bool := !a || (a && b); '+
  'function sameBool(a : Bool, b : Bool) : Bool := a == b; '+
  'function differentBool(a : Bool, b : Bool) : Bool := a != b; '+
  'function chooseFlag(flag : Bool, x : Nat, y : Nat) : Nat := '+
  'if (flag) { x } else { y }; '+
  'function chooseLogic(a : Bool, b : Bool, x : Nat, y : Nat) : Nat := '+
  'if (a && !b) { x } else { y };',
  'verified-bool-logic.ts',
);
assert(
  verifiedBoolLogic.typeScript.includes(
    'function logic(a: boolean, b: boolean): boolean',
  ),
  'verified Bool logic lost its Bool signature',
);
assert(
  verifiedBoolLogic.typeScript.includes('(!a)'),
  'verified Bool.not did not reach TypeScript',
);
assert(
  verifiedBoolLogic.typeScript.includes('(a && b)'),
  'verified Bool.and did not reach TypeScript',
);
assert(
  verifiedBoolLogic.typeScript.includes('return (a === b);'),
  'verified Bool == did not lower through checked Bool equality',
);
assert(
  verifiedBoolLogic.typeScript.includes('return (a !== b);'),
  'verified Bool != did not lower through checked Bool inequality',
);
assert(
  verifiedBoolLogic.typeScript.includes('||'),
  'verified Bool.or did not reach TypeScript',
);
assert(
  verifiedBoolLogic.typeScript.includes('(flag ? x : y)'),
  'verified Bool local did not become a checked if condition',
);
assert(
  verifiedBoolLogic.typeScript.includes('((a && (!b)) ? x : y)'),
  'verified composed Bool condition did not reach TypeScript',
);


const verifiedComposition=compileVerifiedSource(
  'inductive ComposeOption(α : Type) where { '+
  '| none; | some(value : α); } '+
  'function composed(x : Nat, flag : Bool, value : ComposeOption(Nat)) : Nat := '+
  'let choose : Nat -> Nat := fun y => '+
  'if (flag) { y + 1 } else { y }; '+
  'match value with { '+
  '| .none => choose(x); '+
  '| .some y => choose(y); };',
  'verified-composition.ts',
);
const composed=verifiedComposition.ir.declarations.find(
  (item)=>item.name==='composed',
);
assert(
  composed?.body.kind==='let',
  'verified composition did not retain outer let in IR',
);
if(composed?.body.kind==='let'){
  assert(
    composed.body.value.kind==='lambda',
    'verified composition let value did not retain lambda in IR',
  );
  if(composed.body.value.kind==='lambda'){
    assert(
      composed.body.value.body.kind==='if',
      'verified composition lambda body did not retain checked if in IR',
    );
  }
  assert(
    composed.body.body.kind==='match',
    'verified composition let body did not retain ADT match in IR',
  );
}
assert(
  verifiedComposition.typeScript.includes('const choose ='),
  'verified composition did not emit local higher-order binding',
);
assert(
  verifiedComposition.typeScript.includes('case "some"'),
  'verified composition did not emit ADT match branch',
);
assert(
  verifiedComposition.typeScript.includes('flag ?'),
  'verified composition did not emit nested Bool condition',
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
    'case "some": return ((x: bigint) => x)(__ps$match$0.value);',
  ),
  'verified ADT match field binding was not preserved',
);
assert(
  verifiedAdtMatch.emitted.javascript.includes('case "some"'),
  'verified ADT match did not compile to JavaScript',
);



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
assert(PROOFSCRIPT_LSP_PROTOCOL_VERSION===2,'LSP protocol drift');
const integrationLspCapabilities=lspCapabilities();
assert(
  integrationLspCapabilities.experimental?.proofscriptProtocolVersion===
    PROOFSCRIPT_LSP_PROTOCOL_VERSION,
  'LSP advertised protocol version drift',
);
assert(integrationLspCapabilities.hoverProvider===true,'LSP hover capability missing');

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


const verifiedGenericAdt=compileVerifiedSource(
  'inductive PsOption(α : Type) where { | none; | some(value : α); } '+
  'const noneNat : PsOption(Nat) := PsOption.none; '+
  'const oneNat : PsOption(Nat) := PsOption.some(1);',
  'verified-generic-adt.ts',
);
assert(
  verifiedGenericAdt.typeScript.includes('export type PsOption<T0> ='),
  'verified generic ADT did not preserve its type parameter',
);
assert(
  verifiedGenericAdt.typeScript.includes('PsOption["none"]<bigint>()'),
  'nullary generic constructor did not retain compile-time type argument',
);
assert(
  verifiedGenericAdt.typeScript.includes('PsOption["some"]<bigint>(1n)'),
  'generic constructor did not erase shared parameter at runtime',
);
assert(
  !verifiedGenericAdt.emitted.javascript.includes('<T0>'),
  'generic ADT type parameter leaked into JavaScript',
);


const verifiedGenericMatch=compileVerifiedSource(
  'inductive PsOption(α : Type) where { | none; | some(value : α); } '+
  'function getOr {α : Type}'+
  '(value : PsOption(α), fallback : α) : α := '+
  'match value with { | .none => fallback; | .some x => x; };',
  'verified-generic-match.ts',
);
const getOr=verifiedGenericMatch.ir.declarations.find(
  (item)=>item.name==='getOr',
);
assert(
  getOr?.body.kind==='match',
  'generic ADT match did not reach verified match IR',
);
assert(
  verifiedGenericMatch.typeScript.includes(
    'function getOr<T0>(value: PsOption<T0>, fallback: T0): T0',
  ),
  'generic ADT match did not preserve the enclosing type parameter',
);
assert(
  verifiedGenericMatch.typeScript.includes('(x: T0) => x'),
  'generic ADT branch field type was not instantiated from recursor parameters',
);
assert(
  verifiedGenericMatch.emitted.javascript.includes('case "some"'),
  'generic ADT match did not compile to JavaScript',
);


const verifiedRecursiveAdt=compileVerifiedSource(
  'inductive PsList(α : Type) where { '+
  '| nil; | cons(head : α, tail : PsList(α)); } '+
  'function headOr {α : Type}'+
  '(value : PsList(α), fallback : α) : α := '+
  'match value with { | .nil => fallback; | .cons head tail => head; };',
  'verified-recursive-adt.ts',
);
assert(
  verifiedRecursiveAdt.typeScript.includes(
    'readonly tail: PsList<T0>;',
  ),
  'direct recursive ADT field did not remain recursive in verified TypeScript',
);
assert(
  verifiedRecursiveAdt.typeScript.includes('case "cons"'),
  'recursive ADT recursor did not erase to runtime match',
);
assert(
  verifiedRecursiveAdt.emitted.javascript.includes('case "cons"'),
  'recursive ADT match did not compile to JavaScript',
);


const verifiedLength=compileVerifiedSource(
  'inductive PsList(α : Type) where { '+
  '| nil; | cons(head : α, tail : PsList(α)); } '+
  'function length {α : Type}(xs : PsList(α)) : Nat := '+
  'match xs with { | .nil => 0; | .cons head tail => 1 + length(tail); };',
  'verified-length.ts',
);
assert(
  verifiedLength.typeScript.includes(
    'function length<T0>(xs: PsList<T0>): bigint',
  ),
  'structural recursive function lost its verified generic signature',
);
assert(
  verifiedLength.typeScript.includes('1n + length(tail)'),
  'recursor induction hypothesis did not lower to structural runtime self-call',
);
assert(
  verifiedLength.emitted.javascript.includes('length(tail)'),
  'structural recursion did not compile to JavaScript recursion',
);


const verifiedCountFrom=compileVerifiedSource(
  'inductive PsListInvariant(α : Type) where { '+
  '| nil; | cons(head : α, tail : PsListInvariant(α)); } '+
  'function countFrom {α : Type}'+
  '(base : Nat, xs : PsListInvariant(α)) : Nat := '+
  'match xs with { | .nil => base; '+
  '| .cons head tail => 1 + countFrom(base, tail); };',
  'verified-count-from.ts',
);
assert(
  verifiedCountFrom.typeScript.includes('countFrom(base, tail)'),
  'recursor IH did not preserve invariant runtime parameters in self-call',
);
assert(
  verifiedCountFrom.emitted.javascript.includes('countFrom(base, tail)'),
  'invariant structural recursion did not compile to JavaScript',
);


const verifiedGenericMap=compileVerifiedSource(
  'inductive PsMapList(α : Type) where { '+
  '| nil; | cons(head : α, tail : PsMapList(α)); } '+
  'function map {α : Type}{β : Type}'+
  '(f : α -> β, xs : PsMapList(α)) : PsMapList(β) := '+
  'match xs with { | .nil => PsMapList.nil; '+
  '| .cons head tail => PsMapList.cons(f(head), map(f, tail)); };',
  'verified-generic-map.ts',
);
assert(
  verifiedGenericMap.typeScript.includes(
    'function map<T0, T1>(f: (_arg0: T0) => T1, xs: PsMapList<T0>): PsMapList<T1>',
  ),
  'higher-order generic recursive signature was not preserved',
);
assert(
  verifiedGenericMap.typeScript.includes('map(f, tail)'),
  'generic map IH did not lower to a structural self-call',
);
assert(
  verifiedGenericMap.emitted.javascript.includes('map(f, tail)'),
  'generic map did not compile to JavaScript recursion',
);


const verifiedClassLocalInstance=compileVerifiedSource(
  'class Boxed(α : Type) where { value : α; } '+
  'function reuse {α : Type}[inst : Boxed(α)](x : α) : α := x; '+
  'function caller {α : Type}[inst : Boxed(α)](x : α) : α := reuse(x);',
  'verified-class-local-instance.ts',
);
assert(
  verifiedClassLocalInstance.checkedCore.classes.length===1,
  'class metadata did not survive pskernel checked-core admission',
);
assert(
  verifiedClassLocalInstance.typeScript.includes(
    'function caller<T0>(inst: Boxed<T0>, x: T0): T0',
  ),
  'class-constrained function lost its runtime dictionary parameter',
);
assert(
  verifiedClassLocalInstance.typeScript.includes('return reuse(inst, x);'),
  'local class instance synthesis did not become an ordinary runtime dictionary call',
);


const verifiedGlobalInstance=compileVerifiedSource(
  'class Boxed(α : Type) where { value : α; } '+
  'instance boxedNat : Boxed(Nat) := { value := 7 : Boxed(Nat) }; '+
  'instance boxedBoxedNat : Boxed(Boxed(Nat)) := '+
  '{ value := boxedNat : Boxed(Boxed(Nat)) }; '+
  'function get {α : Type}[inst : Boxed(α)](x : α) : α := inst.value; '+
  'function read(x : Nat) : Nat := get(x);',
  'verified-global-instance.ts',
);
assert(
  verifiedGlobalInstance.checkedCore.instances.length===2,
  'global instance metadata did not survive checked-core admission',
);
assert(
  verifiedGlobalInstance.typeScript.includes('return get(boxedNat, x);'),
  'global instance synthesis did not become an ordinary checked dictionary call',
);
assert(
  verifiedGlobalInstance.emitted.javascript.includes('get(boxedNat, x)'),
  'global instance dictionary call did not compile to JavaScript',
);

const verifiedExternalChecked=checkVerifiedSource(
  'extern function hostInc(x : Nat) : Nat from "host-lib" import inc; '+
  'function main(x : Nat) : Nat := hostInc(x);',
);
const verifiedExternalIr=eraseCheckedCoreModule(
  verifiedExternalChecked.checkedCore,
);
const verifiedExternalTs=emitVerifiedTypeScript(verifiedExternalIr);
assert(
  verifiedExternalChecked.checkedCore.externals.length===1,
  'source external was not represented in checked core',
);
assert(
  verifiedExternalTs.includes(
    'import { inc as hostInc } from "host-lib";',
  ),
  'source external did not lower to named ESM import',
);
assert(
  verifiedExternalTs.includes('return hostInc(x);'),
  'source external call did not survive verified TypeScript emission',
);


const verifiedRfl=compileVerifiedSource(
  'theorem boundedRfl(n : Nat) : n + 0 = n := by rfl;',
  'verified-rfl.ts',
);
assert(
  verifiedRfl.checkedCore.theorems.length===1,
  'bounded Eq-only rfl did not construct a pskernel-admitted theorem',
);

const stdlibDirectory=fileURLToPath(
  new URL('../stdlib/',import.meta.url),
);
const stdlibRun=await runCommand({
  project:stdlibDirectory,
  json:true,
  verified:true,
  passthrough:['9'],
});
assert(
  stdlibRun.mainResult==='22',
  'ProofScript-written stdlib dogfood program did not return 22',
);
assert(
  stdlibRun.moduleCount===6,
  'ProofScript-written stdlib project did not load six modules',
);
const stdlibModules=new Set(stdlibRun.moduleOrder);
for(const moduleName of [
  'ProofScript.Data.Option',
  'ProofScript.Data.Result',
  'ProofScript.Data.List',
  'ProofScript.Data.Array',
  'ProofScript.Text.Lexer',
  'main',
]){
  assert(
    stdlibModules.has(moduleName),
    'ProofScript-written stdlib project missed module '+moduleName,
  );
}
assert(
  stdlibRun.assurance?.kernelCheckedTheoremCount===37,
  'ProofScript-written stdlib theorems were not admitted by pskernel',
);
assert(
  stdlibRun.assurance?.runtimeAssumptionCount===0,
  'ProofScript-written stdlib unexpectedly depends on runtime externals',
);

