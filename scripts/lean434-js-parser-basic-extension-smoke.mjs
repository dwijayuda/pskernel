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

const envRefEntry=document.initializers.find(
  x=>x.declaration.includes('EnvExtension.envExtensionsRef'),
);
const categoryRefEntry=document.initializers.find(
  x=>x.declaration==='Lean.Parser.categoryParserFnRef',
);
const categoryExtEntry=document.initializers.find(
  x=>x.declaration==='Lean.Parser.categoryParserFnExtension',
);
if(!envRefEntry||!categoryRefEntry||!categoryExtEntry){
  throw new Error(
    'missing required EnvExtension/Parser.Basic initializer metadata',
  );
}

const selectedSet=new Set([
  envRefEntry.declaration,
  categoryRefEntry.declaration,
  categoryExtEntry.declaration,
]);
const initializers=document.initializers.filter(
  x=>selectedSet.has(x.declaration),
);
if(initializers.length!==3){
  throw new Error('expected exactly three selected initializer entries');
}

const replay=new Lean4ExportReplay();
replay.replay(fs.readFileSync(fixture,'utf8'));
const metadata=new Lean434RuntimeMetadataIndex({
  ...document,
  initializers,
});
const evaluator=new Lean434Evaluator(replay.env,{metadata});
const runner=new Lean434InitializerRunner(evaluator,metadata);
const report=runner.runAll();
if(report.executed.length!==3){
  throw new Error(
    'expected three initializer executions, got '+report.executed.length,
  );
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

const second=runner.runAll();
if(second.executed.length!==0||second.skipped.length!==3){
  throw new Error('selected Parser.Basic initializers did not run once');
}

console.log(
  'ok - real Lean registerEnvExtension executes during JS initialization',
);
console.log(
  'ok - Lean.Parser.categoryParserFnExtension is registered from Lean source',
);
