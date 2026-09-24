import fs from 'node:fs';
import {
  Lean4ExportReplay,
  addOffset,
  levelEqStructural,
  levelIMaxRaw,
  levelMVar,
  levelMaxRaw,
  levelParam,
  levelSucc,
  levelZero,
  nameFromDotted,
} from '../dist/src/index.js';
import {
  Lean434Evaluator,
} from '../packages/runtime/dist/src/lean4-eval.js';
import {
  kernelLevelToLean434Runtime,
  lean434RuntimeLevelToKernel,
} from '../packages/runtime/dist/src/lean4-level.js';

const fixture=process.argv[2]??'lean434-level-bootstrap.ndjson';
if(!fs.existsSync(fixture)){
  throw new Error('missing generated Lean.Level fixture: '+fixture);
}

const preludeFixture='oracle/fixtures/lean434-init-prelude.ndjson';
if(!fs.existsSync(preludeFixture)){
  throw new Error('missing pinned Lean 4.34 Init.Prelude fixture');
}

const prelude=new Lean4ExportReplay();
prelude.replay(fs.readFileSync(preludeFixture,'utf8'));
const replay=new Lean4ExportReplay(prelude.env);
replay.replay(fs.readFileSync(fixture,'utf8'));

const evaluator=new Lean434Evaluator(replay.env);
const input=levelIMaxRaw(
  levelMaxRaw(
    levelSucc(levelParam(nameFromDotted('u'))),
    levelMVar(nameFromDotted('m')),
  ),
  levelSucc(levelZero),
);

let addOffsetFn=evaluator.evaluate(
  {kind:'const',name:nameFromDotted('Lean.Level.addOffset'),levels:[]},
);
addOffsetFn=evaluator.applyRuntimeValue(
  addOffsetFn,
  kernelLevelToLean434Runtime(input),
);
const result=evaluator.applyRuntimeValue(addOffsetFn,2n);
const actual=lean434RuntimeLevelToKernel(result);
const expected=addOffset(input,2n);

if(!levelEqStructural(actual,expected)){
  throw new Error(
    'real Lean.Level.addOffset disagrees structurally with pskernel Level.addOffset',
  );
}

console.log(
  'ok - real Lean.Level.addOffset executes through canonical pskernel Level bridge',
);
