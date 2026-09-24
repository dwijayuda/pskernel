import fs from 'node:fs';
import {
  Lean4ExportReplay,
  constant,
  nameFromDotted,
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
    'usage: node scripts/lean434-js-parser-basic-init-smoke.mjs '+
    '<corpus.ndjson> <runtime-metadata.json>',
  );
}
if(!fs.existsSync(fixture))throw new Error('missing corpus: '+fixture);
if(!fs.existsSync(metadataFile))throw new Error('missing metadata: '+metadataFile);

const document=parseLean434RuntimeMetadata(
  JSON.parse(fs.readFileSync(metadataFile,'utf8')),
);
const target='Lean.Parser.categoryParserFnRef';
const entry=document.initializers.find(x=>x.declaration===target);
if(entry===undefined){
  throw new Error('missing Lean.Parser.Basic initializer metadata for '+target);
}

const replay=new Lean4ExportReplay();
replay.replay(fs.readFileSync(fixture,'utf8'));

const filtered={
  ...document,
  initializers:[entry],
};
const metadata=new Lean434RuntimeMetadataIndex(filtered);
const evaluator=new Lean434Evaluator(replay.env,{metadata});
const runner=new Lean434InitializerRunner(evaluator,metadata);

const report=runner.runAll();
if(report.executed.length!==1||report.skipped.length!==0){
  throw new Error(
    'categoryParserFnRef initializer did not execute exactly once',
  );
}
const initialized=evaluator.evaluate(
  constant(nameFromDotted(target)),
);
if(!(initialized instanceof LeanRef)){
  throw new Error('categoryParserFnRef initializer did not store a LeanRef');
}
const categoryParserFn=lean_st_ref_get(initialized);
if(
  typeof categoryParserFn!=='object'
  ||categoryParserFn===null
  ||Array.isArray(categoryParserFn)
  ||categoryParserFn.kind!=='closure'
){
  throw new Error(
    'categoryParserFnRef did not contain the Lean-written parser function',
  );
}

const second=runner.runAll();
if(second.executed.length!==0||second.skipped.length!==1){
  throw new Error('categoryParserFnRef initializer was not run-once');
}

console.log(
  'ok - real Lean.Parser.Basic categoryParserFnRef initializer runs in JS',
);
console.log(
  'ok - initialized parser registry ref contains a Lean-written closure',
);
