import fs from 'node:fs';
import {
  Lean4ExportReplay,
  constant,
  mkAppN,
  nameFromDotted,
} from '../dist/src/index.js';
import {
  Lean434Evaluator,
} from '../packages/runtime/dist/src/lean4-eval.js';

const fixture=process.argv[2]??'lean434-parser-types-bootstrap.ndjson';
if(!fs.existsSync(fixture)){
  throw new Error('missing generated Lean.Parser.Types fixture: '+fixture);
}

const replay=new Lean4ExportReplay();
replay.replay(fs.readFileSync(fixture,'utf8'));
const evaluator=new Lean434Evaluator(replay.env);

function expectCtor(value,name,label){
  if(
    typeof value!=='object'
    ||value===null
    ||Array.isArray(value)
    ||value.kind!=='constructor'
    ||value.name!==name
  ){
    throw new Error(
      label+' expected constructor '+name+', got '+JSON.stringify(value),
    );
  }
}

const epsilon=constant(nameFromDotted('Lean.Parser.FirstTokens.epsilon'));
const unknown=constant(nameFromDotted('Lean.Parser.FirstTokens.unknown'));
const epsilonValue=evaluator.evaluate(epsilon);
const unknownValue=evaluator.evaluate(unknown);
expectCtor(
  epsilonValue,
  'Lean.Parser.FirstTokens.epsilon',
  'FirstTokens.epsilon value',
);
expectCtor(
  unknownValue,
  'Lean.Parser.FirstTokens.unknown',
  'FirstTokens.unknown value',
);
console.log('ok - real Lean.Parser.FirstTokens constructors execute in JS');

const toOptionalFn=evaluator.evaluate(
  constant(nameFromDotted('Lean.Parser.FirstTokens.toOptional')),
);
const optionalEpsilon=evaluator.applyRuntimeValue(
  toOptionalFn,
  epsilonValue,
);
expectCtor(
  optionalEpsilon,
  'Lean.Parser.FirstTokens.epsilon',
  'FirstTokens.toOptional epsilon',
);
console.log('ok - real Lean.Parser.FirstTokens.toOptional executes in JS');

let seqFn=evaluator.evaluate(
  constant(nameFromDotted('Lean.Parser.FirstTokens.seq')),
);
seqFn=evaluator.applyRuntimeValue(seqFn,epsilonValue);
const seqEpsilonUnknown=evaluator.applyRuntimeValue(seqFn,unknownValue);
expectCtor(
  seqEpsilonUnknown,
  'Lean.Parser.FirstTokens.unknown',
  'FirstTokens.seq epsilon unknown',
);
console.log('ok - real Lean.Parser.FirstTokens.seq executes in JS');

let mergeFn=evaluator.evaluate(
  constant(nameFromDotted('Lean.Parser.FirstTokens.merge')),
);
mergeFn=evaluator.applyRuntimeValue(mergeFn,epsilonValue);
const merged=evaluator.applyRuntimeValue(mergeFn,unknownValue);
expectCtor(
  merged,
  'Lean.Parser.FirstTokens.unknown',
  'FirstTokens.merge epsilon unknown',
);
console.log(
  'ok - real Lean.Parser.Types algorithms execute through pskernel + JS runtime',
);
