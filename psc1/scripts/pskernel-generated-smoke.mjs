import { pathToFileURL } from "node:url";
import path from "node:path";

if (process.argv.length !== 3) {
  throw new Error("PSKERNEL_GENERATED_SMOKE_USAGE: node scripts/pskernel-generated-smoke.mjs <generated-kernel.js>");
}

const url = pathToFileURL(path.resolve(process.argv[2])).href;
const kernel = await import(url);

function requireExport(name) {
  if (!(name in kernel)) {
    throw new Error(`PSKERNEL_GENERATED_EXPORT_MISSING: ${name}`);
  }
  return kernel[name];
}

function expect(name, condition) {
  if (condition !== true) throw new Error(`PSKERNEL_GENERATED_SMOKE_FAILED: ${name}`);
  console.log(`PSKERNEL_GENERATED_SMOKE PASS: ${name}`);
}

const semanticRoot = requireExport("psKernelCoreSemanticRoot");
expect("semantic root exports true", semanticRoot === true);

const max = requireExport("psKernelStateNatMax");
expect("freshness maximum larger right", max(3n, 14n) === 14n);
expect("freshness maximum larger left", max(19n, 7n) === 19n);
expect("freshness maximum equality", max(7n, 7n) === 7n);

const stringEq = requireExport("psKernelStringEq");
expect("UTF8 byte iteration equal", stringEq("hé", "hé") === true);
expect("UTF8 byte iteration distinct", stringEq("hé", "he") === false);
expect("empty strings equal", stringEq("", "") === true);
expect("length mismatch rejected", stringEq("x", "") === false);

const natLt = requireExport("psKernelNatLt");
expect("strict nat ordering", natLt(2n, 3n) === true && natLt(3n, 2n) === false);

const cacheEligible = requireExport("psKernelSemanticCacheEligible");
const names = requireExport("PsKernelName");
const expr = requireExport("PsKernelExpr");
const levels = requireExport("PsKernelLevel");
if (!names || !expr || !levels || typeof expr.fvar !== "function") {
  throw new Error("PSKERNEL_GENERATED_CONSTRUCTOR_EXPORTS_MISSING");
}
expect("closed sort eligible", cacheEligible(expr.sort(levels.zero)) === true);
expect("free variable never cached", cacheEligible(expr.fvar(names.anonymous)) === false);

const inst1 = requireExport("psKernelExprInstantiate1");
const curriedEq = requireExport("psKernelExprEq");
const eq = (left,right) => curriedEq(left)(right);
const sort0 = expr.sort(levels.zero);
expect("C0 one-variable beta substitution", eq(inst1(expr.bvar(0n), sort0), sort0));
expect("C0 outer de Bruijn decrement", eq(inst1(expr.bvar(2n), sort0), expr.bvar(1n)));
const openApp = expr.app(expr.bvar(0n), expr.bvar(2n));
const expectedApp = expr.app(sort0, expr.bvar(1n));
expect("C0 app substitution in generated JS",
  eq(inst1(openApp, sort0), expectedApp));
expect("C0 closed app retained",
  eq(inst1(expr.app(sort0, sort0), sort0), expr.app(sort0, sort0)));

const multi = requireExport("psKernelExprInstantiateAtChanged");
const psList = requireExport("List");
const nil = typeof psList.nil === "function" ? psList.nil() : psList.nil;
const subs = psList.cons(expr.bvar(3n), psList.cons(sort0, nil));
const multiResult = multi(expr.app(expr.bvar(0n), expr.bvar(2n)), 0n, subs, 0n);
expect("C0 multi substitution generated JS",
  eq(multiResult.fst, expr.app(expr.bvar(3n), expr.bvar(0n))));
const lift = requireExport("psKernelExprLiftLooseBVarsChanged");
const lifted = lift(expr.app(expr.bvar(0n), expr.bvar(2n)), 0n, 3n);
expect("C0 binder-aware lifting in generated JS",
  eq(lifted.fst, expr.app(expr.bvar(3n), expr.bvar(5n))));
const unchanged = lift(expr.bvar(0n), 1n, 2n);
expect("C0 lifting preserves bound variable below cutoff",
  eq(unchanged.fst, expr.bvar(0n)));
const zeroLift = lift(openApp, 0n, 0n);
expect("C0 lifting zero amount remains identity", eq(zeroLift.fst, openApp));

// Complete independent checker. Comparison guards require actual Booleans.
expect("expression equality equal sentinel", eq(sort0,sort0) === true);
const sort1=expr.sort(levels.succ(levels.zero));
expect("expression equality unequal sentinel", eq(sort0,sort1) === false);
const fuel=4096n;
const binder=requireExport("PsKernelBinderInfo");
const safety=requireExport("PsKernelDefinitionSafety");
const hints=requireExport("PsKernelReducibilityHints");
const empty=requireExport("psKernelEnvironmentEmpty");
const maxNat=requireExport("psKernelLeanNatMaxSizeDefault");
const mkSession=requireExport("psKernelMkCheckerSession");
const session=mkSession(empty,nil,safety.safe,fuel,maxNat);
const check=requireExport("psKernelSessionCheck");
const infer=requireExport("psKernelSessionInfer");
const whnf=requireExport("psKernelSessionWhnf");
const defeq=requireExport("psKernelSessionIsDefEq");
function accepted(result,label){
  if(result && typeof result==='object' && 'value' in result)return result.value;
  throw Error('PSKERNEL_GENERATED_UNEXPECTED_REJECTION: '+label+' '+String(result?.error));
}
function isRejected(result){return !!result && typeof result==='object' && 'error' in result;}
const identity=expr.lam(names.anonymous,sort1,expr.bvar(0n),binder.default);
const beta=expr.app(identity,sort0);
const zeta=expr.letE(names.anonymous,sort1,sort0,expr.bvar(0n),false);
for(const [label,term] of [['sort',sort0],['beta',beta],['zeta',zeta],['metadata',expr.mdata(1n,zeta)]]){
  const checked=accepted(check(fuel,session,term),label+'-check');
  expect('complete checked type '+label,eq(checked.fst,sort1)===true);
  const inferred=accepted(infer(fuel,session,term),label+'-infer');
  expect('complete inferred type '+label,eq(inferred.fst,sort1)===true);
  expect('complete WHNF '+label,eq(accepted(whnf(fuel,session,term),label+'-whnf').fst,sort0)===true);
  expect('complete positive DefEq '+label,accepted(defeq(fuel,session,term,sort0),label+'-defeq').fst===true);
  expect('warm checked type '+label,eq(accepted(check(fuel,checked.snd,term),label+'-warm').fst,sort1)===true);
}
expect('complete negative DefEq',accepted(defeq(fuel,session,sort0,sort1),'negative-defeq').fst===false);
for(const [label,term] of [
  ['illtyped application',expr.app(sort0,sort0)],
  ['loose bound variable',expr.bvar(0n)],
  ['undeclared constant',expr.const(names.str(names.anonymous,'Missing'),nil)],
  ['unbound free variable',expr.fvar(names.str(names.anonymous,'Missing'))],
  ['expression metavariable',expr.mvar(names.str(names.anonymous,'Missing'))]]){
  expect('complete checker rejects '+label,isRejected(check(fuel,session,term)));
}
for(const [label,operation] of [
  ['check',()=>check(0n,session,sort0)],['infer',()=>infer(0n,session,sort0)],
  ['WHNF',()=>whnf(0n,session,sort0)],['DefEq',()=>defeq(0n,session,sort0,sort0)]]){
  expect('zero fuel rejects '+label,isRejected(operation()));
}
const admitAxiom=requireExport('psKernelAddAxiom');
const admitDefinition=requireExport('psKernelAddDefinition');
const contains=requireExport('psKernelEnvironmentContains');
const axiomName=names.str(names.anonymous,'GeneratedCheckedAxiom');
const axiom={base:{name:axiomName,levelParams:nil,type:sort1},isUnsafe:false};
const axiomEnv=accepted(admitAxiom(fuel,empty,axiom,fuel,maxNat),'admit-axiom');
expect('checked axiom is visible',contains(axiomEnv,axiomName)===true);
expect('axiom admission preserves input environment',contains(empty,axiomName)===false);
const definitionName=names.str(names.anonymous,'GeneratedCheckedDefinition');
const definition={base:{name:definitionName,levelParams:nil,type:sort1},value:sort0,hints:hints.abbrevHint,safety:safety.safe};
const definitionEnv=accepted(admitDefinition(fuel,axiomEnv,definition,fuel,maxNat),'admit-definition');
expect('checked definition is visible',contains(definitionEnv,definitionName)===true);
const declared=expr.const(definitionName,nil);
const declaredSession=mkSession(definitionEnv,nil,safety.safe,fuel,maxNat);
expect('definition has checked type',eq(accepted(check(fuel,declaredSession,declared),'check-definition').fst,sort1)===true);
expect('delta unfolds admitted definition',eq(accepted(whnf(fuel,declaredSession,declared),'delta-definition').fst,sort0)===true);
expect('delta DefEq uses admitted definition',accepted(defeq(fuel,declaredSession,declared,sort0),'delta-defeq').fst===true);
const invalidDefinition={...definition,base:{...definition.base,name:names.str(names.anonymous,'InvalidDefinition'),type:sort0}};
expect('admission rejects wrong definition type',isRejected(admitDefinition(fuel,definitionEnv,invalidDefinition,fuel,maxNat)));
expect('admission rejects duplicate declaration',isRejected(admitDefinition(fuel,definitionEnv,definition,fuel,maxNat)));
const addInductive=requireExport('psKernelAddSimpleInductive');
const enumName=names.str(names.anonymous,'GeneratedCheckedEnum');
const ctorName=names.str(enumName,'mk');
const enumType=expr.const(enumName,nil);
const enumDecl={levelParams:nil,name:enumName,type:sort1,ctors:psList.cons({name:ctorName,type:enumType},nil),isUnsafe:false,numParams:0n};
const enumEnv=accepted(addInductive(fuel,empty,enumDecl,fuel,maxNat),'admit-inductive');
expect('ordinary inductive and constructor admitted',contains(enumEnv,enumName)===true && contains(enumEnv,ctorName)===true);
const enumSession=mkSession(enumEnv,nil,safety.safe,fuel,maxNat);
expect('constructor passes complete checking',eq(accepted(check(fuel,enumSession,expr.const(ctorName,nil)),'check-constructor').fst,enumType)===true);
expect('generated recursor is present',contains(enumEnv,names.str(enumName,'rec'))===true);
const motive=expr.lam(names.anonymous,enumType,sort1,binder.default);
const recursor=expr.const(names.str(enumName,'rec'),psList.cons(levels.succ(levels.succ(levels.zero)),nil));
const recursorApp=expr.app(expr.app(expr.app(recursor,motive),sort0),expr.const(ctorName,nil));
const recursorType=accepted(check(fuel,enumSession,recursorApp),'checked-recursor').fst;
expect('recursor result type is definitionally Sort1',accepted(defeq(fuel,enumSession,recursorType,sort1),'recursor-type').fst===true);
expect('actual iota reduction',eq(accepted(whnf(fuel,enumSession,recursorApp),'iota').fst,sort0)===true);
expect('actual recursor DefEq',accepted(defeq(fuel,enumSession,recursorApp,sort0),'recursor-defeq').fst===true);
const addMutual=requireExport('psKernelAddSimpleMutualInductive');
const leftName=names.str(names.anonymous,'GeneratedMutualLeft');
const rightName=names.str(names.anonymous,'GeneratedMutualRight');
const mutualType=name=>({name,type:sort1,ctors:psList.cons({name:names.str(name,'mk'),type:expr.const(name,nil)},nil)});
const mutual={levelParams:nil,numParams:0n,types:psList.cons(mutualType(leftName),psList.cons(mutualType(rightName),nil)),isUnsafe:false};
const mutualEnv=accepted(addMutual(fuel,empty,mutual,fuel,maxNat),'admit-mutual');
expect('mutual inductives admitted',contains(mutualEnv,leftName)===true && contains(mutualEnv,rightName)===true);
const localName=names.str(names.anonymous,'ScopedLocal');
const local=expr.fvar(localName);
const addLocal=requireExport('psKernelLocalContextAddLocal');
const emptyLocal=requireExport('psKernelLocalContextEmpty');
const makeContext=type=>({...session.context,localContext:addLocal(emptyLocal,localName,localName,type,binder.default)});
const firstLocal=accepted(infer(fuel,{context:makeContext(sort0),state:session.state},local),'local-context-one');
expect('first local context type',eq(firstLocal.fst,sort0)===true);
const secondLocal=accepted(infer(fuel,{context:makeContext(sort1),state:firstLocal.snd.state},local),'local-context-two');
expect('free-variable inference does not leak across contexts',eq(secondLocal.fst,sort1)===true);
const stateEmpty=requireExport('psKernelCheckerStateEmpty');
const mapInsert=requireExport('psKernelExprMapInsert');
const mapGet=requireExport('psKernelExprMapGet');
const map=mapInsert(requireExport('psKernelExprMapEmpty'),local,sort0);
const pairs=requireExport('psKernelExprPairSetInsert')(requireExport('psKernelExprPairSetEmpty'),local,sort0);
const child={...stateEmpty,nextFresh:7n,inferOnly:map,checkedInfer:map,whnfCore:map,whnf:map,unfold:map,success:pairs,failure:pairs};
const restored=requireExport('psKernelCheckerStateExitLocalScope')(stateEmpty,child);
expect('scope exit preserves monotone fresh identifiers',restored.nextFresh===7n);
for(const field of ['inferOnly','checkedInfer','whnfCore','whnf','unfold']){
  const found=mapGet(restored[field],local);
  expect('scope exit drops child '+field+' cache',!found || (typeof found==='object' && !('value' in found)));
}
const pairContains=requireExport('psKernelExprPairSetContains');
expect('scope exit drops child positive DefEq cache',pairContains(restored.success,local,sort0)===false);
expect('scope exit drops child negative DefEq cache',pairContains(restored.failure,local,sort0)===false);
console.log('PSKERNEL_GENERATED_COMPLETE_CHECKER: PASS');
console.log('PSKERNEL_GENERATED_SMOKE: PASS');
