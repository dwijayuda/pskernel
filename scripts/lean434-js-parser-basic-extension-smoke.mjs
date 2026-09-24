import fs from 'node:fs';
import {
  Lean4ExportReplay,
  constant,
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
    'usage: node scripts/lean434-js-parser-basic-extension-smoke.mjs '+
    '<corpus.ndjson> <runtime-metadata.json>',
  );
}

const document=parseLean434RuntimeMetadata(
  JSON.parse(fs.readFileSync(metadataFile,'utf8')),
);

const importingRefEntry=document.initializers.find(
  x=>x.declaration.includes('ImportingFlag')&&
    x.declaration.endsWith('.importingRef'),
);
const envRefEntry=document.initializers.find(
  x=>x.declaration.includes('EnvExtension.envExtensionsRef'),
);
const categoryRefEntry=document.initializers.find(
  x=>x.declaration==='Lean.Parser.categoryParserFnRef',
);
const categoryExtEntry=document.initializers.find(
  x=>x.declaration==='Lean.Parser.categoryParserFnExtension',
);
if(
  !importingRefEntry
  ||!envRefEntry
  ||!categoryRefEntry
  ||!categoryExtEntry
){
  throw new Error(
    'missing required EnvExtension/Parser.Basic initializer metadata',
  );
}

const selectedSet=new Set([
  importingRefEntry.declaration,
  envRefEntry.declaration,
  categoryRefEntry.declaration,
  categoryExtEntry.declaration,
]);
const initializers=document.initializers.filter(
  x=>selectedSet.has(x.declaration),
);
if(initializers.length!==4){
  throw new Error('expected exactly four selected initializer entries');
}

const preludeFixture='oracle/fixtures/lean434-init-prelude.ndjson';
if(!fs.existsSync(preludeFixture)){
  throw new Error('missing pinned Lean 4.34 Init.Prelude fixture');
}
const preludeReplay=new Lean4ExportReplay();
preludeReplay.replay(fs.readFileSync(preludeFixture,'utf8'));
const replay=new Lean4ExportReplay(preludeReplay.env);
const deltaText=fs.readFileSync(fixture,'utf8');
console.log(JSON.stringify({
  phase:'delta-input',
  bytes:Buffer.byteLength(deltaText),
  lines:deltaText.split(/\r?\n/u).filter(x=>x.length>0).length,
}));
const replayStats=replay.replay(deltaText,{
  every:500,
  onProgress:(stats)=>console.log(JSON.stringify({
    phase:'delta-replay',
    ...stats,
  })),
});
console.log(JSON.stringify({
  phase:'delta-replay-complete',
  ...replayStats,
  environmentConstants:replay.env.size,
}));
const metadata=new Lean434RuntimeMetadataIndex({
  ...document,
  initializers,
});
const evaluator=new Lean434Evaluator(
  replay.env,
  {metadata,maxSteps:200_000},
);
const runner=new Lean434InitializerRunner(evaluator,metadata);
const executed=[];
for(const entry of initializers){
  console.log('begin initializer - '+entry.declaration);
  const report=runner.runSelected([entry]);
  if(report.executed.length!==1||report.skipped.length!==0){
    throw new Error(
      'initializer did not execute exactly once: '+entry.declaration,
    );
  }
  executed.push(...report.executed);
  console.log('end initializer - '+entry.declaration);
}
if(executed.length!==4){
  throw new Error(
    'expected four initializer executions, got '+executed.length,
  );
}

const importingRef=evaluator.getRuntimeGlobal(
  importingRefEntry.declaration,
);
if(!(importingRef instanceof LeanRef)){
  throw new Error('Lean.ImportingFlag.importingRef is not a LeanRef');
}
if(lean_st_ref_get(importingRef)!==false){
  throw new Error('Lean.ImportingFlag.importingRef did not initialize false');
}

const envRef=evaluator.getRuntimeGlobal(envRefEntry.declaration);
if(!(envRef instanceof LeanRef)){
  throw new Error('EnvExtension.envExtensionsRef is not a LeanRef');
}
const extensions=lean_st_ref_get(envRef);
if(!Array.isArray(extensions)){
  throw new Error('EnvExtension.envExtensionsRef does not contain an array');
}
if(extensions.length!==1){
  throw new Error(
    'expected exactly one registered extension, got '+extensions.length,
  );
}

const categoryRef=evaluator.getRuntimeGlobal(
  'Lean.Parser.categoryParserFnRef',
);
if(!(categoryRef instanceof LeanRef)){
  throw new Error('categoryParserFnRef is not a LeanRef');
}

const categoryExt=evaluator.getRuntimeGlobal(
  'Lean.Parser.categoryParserFnExtension',
);
if(
  typeof categoryExt!=='object'
  ||categoryExt===null
  ||Array.isArray(categoryExt)
  ||categoryExt.kind!=='constructor'
){
  throw new Error(
    'categoryParserFnExtension is not a Lean EnvExtension constructor',
  );
}
if(!categoryExt.name.includes('EnvExtension')){
  throw new Error(
    'unexpected environment extension constructor: '+categoryExt.name,
  );
}

const second=runner.runSelected(initializers);
if(second.executed.length!==0||second.skipped.length!==4){
  throw new Error('selected Parser.Basic initializers did not run once');
}

console.log(
  'ok - real Lean registerEnvExtension executes during JS initialization',
);
console.log(
  'ok - Lean.Parser.categoryParserFnExtension is registered from Lean source',
);
