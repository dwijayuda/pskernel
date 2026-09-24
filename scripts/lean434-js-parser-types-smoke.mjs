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

const optionalEpsilon=evaluator.evaluate(
  mkAppN(
    constant(nameFromDotted('Lean.Parser.FirstTokens.toOptional')),
    [epsilon],
  ),
);
expectCtor(
  optionalEpsilon,
  'Lean.Parser.FirstTokens.epsilon',
  'FirstTokens.toOptional epsilon',
);
console.log('ok - real Lean.Parser.FirstTokens.toOptional executes in JS');

const seqEpsilonUnknown=evaluator.evaluate(
  mkAppN(
    constant(nameFromDotted('Lean.Parser.FirstTokens.seq')),
    [epsilon,unknown],
  ),
);
expectCtor(
  seqEpsilonUnknown,
  'Lean.Parser.FirstTokens.unknown',
  'FirstTokens.seq epsilon unknown',
);
console.log('ok - real Lean.Parser.FirstTokens.seq executes in JS');

const merged=evaluator.evaluate(
  mkAppN(
    constant(nameFromDotted('Lean.Parser.FirstTokens.merge')),
    [epsilon,unknown],
  ),
);
expectCtor(
  merged,
  'Lean.Parser.FirstTokens.unknown',
  'FirstTokens.merge epsilon unknown',
);
console.log(
  'ok - real Lean.Parser.Types algorithms execute through pskernel + JS runtime',
);
