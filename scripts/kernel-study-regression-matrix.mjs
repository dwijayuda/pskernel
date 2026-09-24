import {readdirSync,readFileSync,statSync} from 'node:fs';
import {join} from 'node:path';

const roots=['study/lean4-4.34.0/tests/elab','study/lean4-4.34.0/tests/elab_fail'];

function walk(dir){
  const out=[];
  for(const name of readdirSync(dir)){
    const p=join(dir,name),s=statSync(p);
    if(s.isDirectory())out.push(...walk(p));
    else if(/^kernel.*\.lean$/.test(name))out.push(p.replaceAll('\\','/'));
  }
  return out;
}

const matrix={
  'study/lean4-4.34.0/tests/elab/kernel1.lean':{kind:'direct',tests:['Nat.add reduction uses exact bigint','native reduction matches Lean kernel1 defeq cases after delta unfolding'],note:'basic kernel defeq/Nat behavior plus Lean.reduceNat/Lean.reduceBool compiler-backed reduction through delta unfolding'},
  'study/lean4-4.34.0/tests/elab/kernel2.lean':{kind:'direct',tests:['defeq expands string literals exactly through String.ofList','Nat.pow reduction'],note:'basic WHNF/defeq/string and arithmetic behavior'},
  'study/lean4-4.34.0/tests/elab/kernelBacktrack.lean':{kind:'frontend-operational',note:'Core task/error backtracking is outside the trusted semantic checker'},
  'study/lean4-4.34.0/tests/elab/kernelErrorFollowup.lean':{kind:'frontend-operational',note:'frontend environment/error recovery after rejected declarations'},
  'study/lean4-4.34.0/tests/elab/kernelImaxProp.lean':{kind:'direct',tests:['imax-normalized Prop inductive keeps Prop-only elimination','projection typing forbids extracting data from a proof']},
  'study/lean4-4.34.0/tests/elab/kernelImaxPropInductive.lean':{kind:'direct',tests:['imax-normalized Prop inductive keeps Prop-only elimination']},
  'study/lean4-4.34.0/tests/elab/kernelInterrupt.lean':{kind:'operational-resource',note:'cancellation/exception transport is operational behavior, not kernel term semantics'},
  'study/lean4-4.34.0/tests/elab/kernelMaxRecDepth.lean':{kind:'direct',tests:['kernel recursion budget fails deterministically and succeeds when raised']},
  'study/lean4-4.34.0/tests/elab/kernelMutualDupName.lean':{kind:'direct',tests:['mutual definitions reject safe, mixed, duplicate, and non-transactional blocks']},
  'study/lean4-4.34.0/tests/elab/kernelNestedAuxName.lean':{kind:'direct',tests:['nested inductive admission rejects the reserved _nested auxiliary namespace','public ordinary admission rejects reserved _nested references but not sibling prefixes']},
  'study/lean4-4.34.0/tests/elab/kernelProjIdx.lean':{kind:'direct',tests:['projection indices reject negative, fractional, and uint32-overflow values']},
  'study/lean4-4.34.0/tests/elab/kernelProjSname.lean':{kind:'direct',tests:['projection reduction never crosses an unrelated structure name']},
  'study/lean4-4.34.0/tests/elab/kernel_is_def_eq_equiv_manager_1.lean':{kind:'direct-invariant-plus-oracle',tests:['defeq success cache remains pair-local and never gains transitive closure'],note:'full hash-collision exploit remains in official Lean adversarial oracle'},
  'study/lean4-4.34.0/tests/elab/kernel_is_def_eq_equiv_manager_2.lean':{kind:'direct-invariant-plus-oracle',tests:['defeq success cache remains pair-local and never gains transitive closure'],note:'full transported result-sort exploit remains oracle coverage until compact TS minimization'},
  'study/lean4-4.34.0/tests/elab/kernel_is_prop_ensure_sort.lean':{kind:'direct-invariant-plus-oracle',tests:['reducible Prop sort remains proof-only through inductive and projection checking'],note:'compact TS regression covers the ensure_sort/isProp/projection invariant; full transported-history exploit remains in the official Lean adversarial oracle'},
  'study/lean4-4.34.0/tests/elab/kernel_is_prop_issue.lean':{kind:'direct-invariant-plus-oracle',tests:['reducible Prop sort remains proof-only through inductive and projection checking'],note:'upstream commit 403bfc9a confirms this is a second adversarial test for the same is_prop bug fixed by #14807; the compact invariant is direct while the full transported-history/eager sequence remains oracle stress coverage'},
  'study/lean4-4.34.0/tests/elab/kernel_maxheartbeats.lean':{kind:'operational-resource',note:'deterministic heartbeat accounting is outside current semantic-equivalence target'},
  'study/lean4-4.34.0/tests/elab_fail/kernelMVarBug.lean':{kind:'frontend-plus-direct-boundary',tests:['declaration rejects expression and universe metavariables transactionally'],note:'original bug is elaborator postponed-instance registration; kernel rejection boundary is direct'},
  'study/lean4-4.34.0/tests/elab_fail/kernelQuotNameCollision.lean':{kind:'direct',tests:['Quot bootstrap rejects occupied primitive names without overwriting them']},
};

const hardeningExtras={
  'study/lean4-4.34.0/tests/elab/nat_mod_defeq.lean':{
    kind:'direct',
    tests:['primitive Nat.mod checks bounded wrapper and go fuel equations'],
    note:'admitted Nat.mod is explicitly rechecked at a free divisor: 0 % n is definitionally equal to 0, so coverage cannot come from the numeric-literal fast path',
  },
  'study/lean4-4.34.0/tests/elab/strLitProj.lean':{
    kind:'direct',
    tests:['string literal projection reduces through String.ofList like Lean strLitProj'],
    note:'kernel projection reduction must expand a String literal through String.ofList before selecting the structure field',
  },
  'study/lean4-4.34.0/tests/elab/proj_delta_issue.lean':{
    kind:'direct',
    tests:['defeq compares projections after lazy delta even when other structure fields differ'],
    note:'lazy projection delta compares the projected field before forcing unrelated expensive fields',
  },
  'study/lean4-4.34.0/tests/elab/etaStruct.lean':{
    kind:'direct',
    tests:['defeq implements structure eta through projections','defeq treats zero-field single-constructor inductives as unit-like'],
    note:'core structure eta plus unit-like single-constructor equality',
  },
  'study/lean4-4.34.0/tests/elab/reduceBool.lean':{
    kind:'direct-native-boundary',
    tests:['explicit native evaluator controls Lean.reduceNat and Lean.reduceBool results'],
    note:'upstream smoke for Lean.reduceNat/Lean.reduceBool; direct TS provider test locks returned Nat/Bool behavior while native-oracle-smoke locks compiler execution and @[implemented_by]',
  },
  'study/lean4-4.34.0/tests/elab/issue_14576.lean':{
    kind:'direct-invariant-plus-oracle',
    tests:['nested fixed parameters are checked even when auxiliary preprocessing drops them'],
    note:'compact TS regression covers #14577 dropped nested fixed-parameter checking; the full hash-collision exploit remains official Lean oracle stress coverage',
  },
  'study/lean4-4.34.0/tests/elab/issue_14576_min.lean':{
    kind:'direct-invariant-plus-oracle',
    tests:['nested fixed parameters are checked even when auxiliary preprocessing drops them'],
    note:'minimal upstream #14577 scenario maps to the same direct nested-application checking invariant',
  },
  'study/lean4-4.34.0/tests/elab/issue14484.lean':{
    kind:'direct-hardening',
    tests:['opaque admission rejects dangling free variables transactionally'],
    note:'Lean #14484/#14498 closure fix: opaque bodies must reject FVars before stale inference-cache entries can be reused',
  },
  'study/lean4-4.34.0/tests/elab/issue_14576_nonuniform.lean':{
    kind:'direct-hardening',
    tests:[
      'inductive uniformity is checked before WHNF can erase a bad occurrence',
      'nested inductive uniformity is checked before preprocessing can drop bad parameters',
      'inductive uniformity requires exact declaration universe arguments',
      'uniform occurrence accepts a constructor parameter whose type is definitionally equal',
    ],
    note:'Lean 4.34 follow-up to #14576: syntactic uniformity must run before WHNF and nested preprocessing while preserving definitionally-equal parameter domains',
  },
};

const actual=roots.flatMap(walk).sort();
const expected=Object.keys(matrix).sort();
const missing=actual.filter(p=>!(p in matrix));
const stale=expected.filter(p=>!actual.includes(p));
if(missing.length||stale.length){
  let msg='kernel study regression matrix drift';
  if(missing.length)msg+='\nunclassified: '+missing.join(', ');
  if(stale.length)msg+='\nstale: '+stale.join(', ');
  throw new Error(msg);
}

const tests=readFileSync('test/all.test.ts','utf8');
for(const [path,entry] of [...Object.entries(matrix),...Object.entries(hardeningExtras)]){
  if(!readFileSync(path,'utf8'))throw new Error(path+': hardening source is unreadable');
  for(const name of entry.tests??[]){
    if(!tests.includes("test('"+name+"'"))throw new Error(path+': mapped TS regression is missing: '+name);
  }
}

const exporter=readFileSync('oracle/replay-probe/DependencyExport.lean','utf8');
const safeAllMarkers=[
  'if dv.safety == .safe then',
  'DefinitionVal.all is informational for safe definitions',
  'dumpDefinition dv',
];
for(const m of safeAllMarkers){
  if(!exporter.includes(m))throw new Error('safe DefinitionVal.all replay drift: missing '+m);
}

for(const marker of [
  '("rootOrderMeaning", "serialized-module-sequence")',
  '("rootDedup", "first-serialized-occurrence")',
  'unless seen.contains n do',
  '("emissionOrder", "dependency-first")',
  '("canonicalScope", "pskernel-project-protocol")',
  '("replayPolicy", "Lean.Kernel.Environment.replay")',
  '("replayableConstants", replayable)',
  '("skippedUnsafe", skippedUnsafe)',
  '("skippedPartial", skippedPartial)',
  'skipNonReplayable := true',
  'ci.isUnsafe || ci.isPartial',
  'dumpConstant env \`Eq',
  'This is not claimed to be\nsource declaration order',
]){
  if(!exporter.includes(marker))throw new Error('canonical replay exporter protocol drift: missing '+marker);
}
if(!exporter.includes('if xs[i]! == d then return i')){
  throw new Error('MData equality-id drift: exporter must use Lean KVMap BEq, not entry-list identity');
}
if(exporter.includes('xs[i]!.entries == d.entries')){
  throw new Error('MData equality-id drift: raw KVMap entry-list equality is stricter than Lean 4.34 BEq');
}
const moduleStream=readFileSync('scripts/module-stream-oracle.mjs','utf8');
for(const marker of [
  "header.rootOrderMeaning!=='serialized-module-sequence'",
  "header.rootDedup!=='first-serialized-occurrence'",
  "header.emissionOrder!=='dependency-first'",
  "header.canonicalScope!=='pskernel-project-protocol'",
  "header.replayPolicy!=='Lean.Kernel.Environment.replay'",
  "protocol:'canonical-module-stream-v2'",
  'replayableConstants+skippedUnsafe+skippedPartial!==totalConstants',
  'shared.size!==replayableConstants',
]){
  if(!moduleStream.includes(marker))throw new Error('canonical replay consumer protocol drift: missing '+marker);
}
const assuranceDoc=readFileSync('docs/research/LEAN434_KERNEL_STUDY.md','utf8');
if(!assuranceDoc.includes('Do not call this source\ndeclaration order')){
  throw new Error('canonical replay assurance wording drift: source-order disclaimer missing');
}

const localAssuranceRunner=readFileSync('scripts/run-full-std-local.ps1','utf8');
for(const marker of [
  '& npm ci --no-audit --no-fund',
  'dependencyInstall=npm ci',
  'git status: $dirtySummary',
  'npm ci changed tracked files; refusing assurance evidence.',
]){
  if(!localAssuranceRunner.includes(marker))throw new Error('local Full-Std assurance runner drift: missing '+marker);
}
if(localAssuranceRunner.includes('& npm install --no-audit --no-fund')){
  throw new Error('local Full-Std assurance runner drift: mutable npm install must not replace npm ci');
}

const nativeEval=readFileSync('oracle/replay-probe/NativeEval.lean','utf8');
for(const marker of [
  'Kernel.whnf env {} e',
  'mkApp (mkConst \`\`Lean.reduceNat) arg',
  'mkApp (mkConst \`\`Lean.reduceBool) arg',
  '.lit (.natVal value)',
  'result.isConstOf \`\`Bool.true',
  'result.isConstOf \`\`Bool.false',
]){
  if(!nativeEval.includes(marker))throw new Error('native evaluator boundary drift: missing '+marker);
}
for(const forbidden of [
  '← Meta.reduceNatNative',
  '← Meta.reduceBoolNative',
  '← IO.ofExcept <| env.evalConst Nat',
  '← IO.ofExcept <| env.evalConst Bool',
  'checkConstType env',
]){
  if(nativeEval.includes(forbidden))throw new Error('native evaluator boundary drift: reference helper must use Kernel.whnf, found '+forbidden);
}

const replaySource=readFileSync('src/integration/lean4export.ts','utf8');
if(!replaySource.includes("if(!exprKernelMetadataEq(g.type,expectedType))throw new KernelError(\`generated constructor type mismatch")){
  throw new Error('constructor replay metadata comparator drift: Lean 4.34 ConstructorVal BEq requires Expr.eqv');
}
if(!replaySource.includes("if(!exprKernelMetadataEq(g.type,expectedType))throw new KernelError(\`generated recursor type mismatch")){
  throw new Error('recursor replay metadata comparator drift: Lean 4.34 RecursorVal BEq requires Expr.eqv');
}
if(!replaySource.includes("if(!namesEq(g.levelParams,expectedLevels)||!nameEq(g.induct")){
  throw new Error('constructor replay metadata drift: ConstructorVal BEq includes levelParams');
}
if(!replaySource.includes("if(!namesEq(g.levelParams,expectedLevels))throw new KernelError(\`generated recursor levelParams mismatch")){
  throw new Error('recursor replay metadata drift: RecursorVal BEq includes levelParams');
}
if(!replaySource.includes("!exprKernelMetadataEq(got.type,expectedType))throw new KernelError(\`exported Quot metadata mismatch")){
  throw new Error('Quot replay metadata comparator drift: generated Quot types must use Lean Expr.eqv');
}

const counts={};
for(const entry of [...Object.values(matrix),...Object.values(hardeningExtras)])counts[entry.kind]=(counts[entry.kind]??0)+1;
console.log(JSON.stringify({
  ok:true,
  classified:actual.length,
  hardeningExtras:Object.keys(hardeningExtras).length,
  counts,
  oracleOnly:Object.entries(matrix).filter(([,v])=>v.kind==='oracle-only-adversarial').map(([path,v])=>({path,note:v.note})),
},null,2));
