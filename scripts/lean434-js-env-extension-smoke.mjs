import fs from 'node:fs';
import {
  Lean4ExportReplay,
  constant,
  levelZero,
  mkAppN,
  nameFromDotted,
  natLit,
} from '../dist/src/index.js';
import {
  Lean434Evaluator,
} from '../packages/runtime/dist/src/lean4-eval.js';
import {
  Lean434InitializerRunner,
} from '../packages/runtime/dist/src/lean4-init.js';
import {
  Lean434RuntimeMetadataIndex,
  parseLean434RuntimeMetadata,
} from '../packages/runtime/dist/src/lean4-metadata.js';
import {
  LeanRef,
  lean_st_ref_get,
} from '../packages/runtime/dist/src/lean4.js';

const [fixture,metadataFile]=process.argv.slice(2);
if(!fixture||!metadataFile){
  throw new Error(
    'usage: node scripts/lean434-js-env-extension-smoke.mjs '+
    '<corpus.ndjson> <runtime-metadata.json>',
  );
}
if(!fs.existsSync(fixture))throw new Error('missing corpus: '+fixture);
if(!fs.existsSync(metadataFile))throw new Error('missing metadata: '+metadataFile);

const document=parseLean434RuntimeMetadata(
  JSON.parse(fs.readFileSync(metadataFile,'utf8')),
);
const importingRefEntry=document.initializers.find(
  x=>x.declaration.includes('ImportingFlag')
    &&x.declaration.endsWith('.importingRef'),
);
const envRefEntry=document.initializers.find(
  x=>x.declaration.includes('EnvExtension.envExtensionsRef'),
);
if(!importingRefEntry||!envRefEntry){
  throw new Error(
    'Lean.Environment metadata is missing importingRef/envExtensionsRef initializers',
  );
}

const selectedInitializers=[importingRefEntry,envRefEntry];
const metadata=new Lean434RuntimeMetadataIndex({
  ...document,
  initializers:selectedInitializers,
});

const preludeFixture='oracle/fixtures/lean434-init-prelude.ndjson';
if(!fs.existsSync(preludeFixture)){
  throw new Error('missing pinned Lean 4.34 Init.Prelude fixture');
}
const prelude=new Lean4ExportReplay();
prelude.replay(fs.readFileSync(preludeFixture,'utf8'));
const replay=new Lean4ExportReplay(prelude.env);
const delta=fs.readFileSync(fixture,'utf8');
const replayStats=replay.replay(delta);
console.log(JSON.stringify({
  phase:'env-extension-delta-replay',
  bytes:Buffer.byteLength(delta),
  lines:delta.split(/\r?\n/u).filter(Boolean).length,
  declarations:replayStats.declarations,
  environmentConstants:replay.env.size,
}));

const evaluator=new Lean434Evaluator(
  replay.env,
  {metadata,maxSteps:100_000},
);
const runner=new Lean434InitializerRunner(evaluator,metadata);
const initialized=runner.runAll();
if(initialized.executed.length!==2||initialized.skipped.length!==0){
  throw new Error(
    'expected importingRef and envExtensionsRef to initialize exactly once',
  );
}

const importingRef=evaluator.getRuntimeGlobal(importingRefEntry.declaration);
if(!(importingRef instanceof LeanRef)){
  throw new Error('Lean importingRef did not initialize to a LeanRef');
}
if(lean_st_ref_get(importingRef)!==false){
  throw new Error('Lean importingRef did not initialize to false');
}

const envRef=evaluator.getRuntimeGlobal(envRefEntry.declaration);
if(!(envRef instanceof LeanRef)){
  throw new Error('Lean EnvExtension.envExtensionsRef did not initialize to a LeanRef');
}
const before=lean_st_ref_get(envRef);
if(!Array.isArray(before)){
  throw new Error('Lean EnvExtension.envExtensionsRef did not contain an Array');
}
const beforeCount=before.length;

const Nat=constant(nameFromDotted('Nat'));
const natType=evaluator.evaluate(Nat);
const mkInitial=evaluator.evaluate(
  mkAppN(
    constant(nameFromDotted('IO.mkRef'),[levelZero]),
    [Nat,natLit(7n)],
  ),
);

let none=evaluator.evaluate(
  constant(nameFromDotted('Option.none'),[levelZero]),
);
// The Option element type is erased at runtime. Supplying the Nat type token
// creates the parameterized nullary Option.none runtime constructor.
none=evaluator.applyRuntimeValue(none,natType);

const mainOnly=evaluator.evaluate(
  constant(nameFromDotted('Lean.EnvExtension.AsyncMode.mainOnly')),
);

let register=evaluator.evaluate(
  constant(nameFromDotted('Lean.registerEnvExtension'),[levelZero]),
);
register=evaluator.applyRuntimeValue(register,natType);
register=evaluator.applyRuntimeValue(register,mkInitial);
register=evaluator.applyRuntimeValue(register,none);
register=evaluator.applyRuntimeValue(register,mainOnly);

const result=evaluator.runInitializerAction(register).value;
if(
  typeof result!=='object'
  ||result===null
  ||Array.isArray(result)
  ||result.kind!=='constructor'
  ||result.name!=='Lean.EnvExtension.mk'
){
  throw new Error(
    'Lean.registerEnvExtension did not return Lean.EnvExtension.mk',
  );
}
if(result.fields.length!==4){
  throw new Error(
    'Lean.EnvExtension.mk runtime field count mismatch: '+
    String(result.fields.length),
  );
}
if(result.fields[0]!==BigInt(beforeCount)){
  throw new Error(
    'Lean.registerEnvExtension returned wrong extension index: expected '+
    String(beforeCount)+', got '+String(result.fields[0]),
  );
}

const after=lean_st_ref_get(envRef);
if(!Array.isArray(after)){
  throw new Error('envExtensionsRef stopped containing an Array');
}
if(after.length!==beforeCount+1){
  throw new Error(
    'Lean.registerEnvExtension did not append exactly one extension',
  );
}
if(after[beforeCount]!==result){
  throw new Error(
    'registered extension identity differs from returned EnvExtension value',
  );
}

console.log(
  'ok - real Lean.registerEnvExtension executes in JS over initialized Lean globals',
);
console.log(
  'ok - EnvExtension registration appends one JS-backed extension without kernel shortcuts',
);
