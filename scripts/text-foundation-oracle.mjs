import fs from 'node:fs';
import {resolve} from 'node:path';
import {replayLeanEnvironment,replayLeanEnvironmentInto} from '../packages/environment/dist/src/index.js';
import {nameFromDotted} from '../dist/src/core/name.js';

const file=resolve(
  process.argv[2]??'oracle/fixtures/lean434-proofscript-text-foundation.ndjson',
);
if(!fs.existsSync(file)){
  throw new Error(
    'missing ProofScript text-foundation fixture: '+file+
    '; run scripts/generate-text-foundation-fixture.sh with Lean 4.34.0',
  );
}

const preludeFile=resolve('oracle/fixtures/lean434-init-prelude.ndjson');
if(!fs.existsSync(preludeFile)){
  throw new Error('missing pinned Lean 4.34 Init.Prelude fixture: '+preludeFile);
}
const prelude=replayLeanEnvironment(fs.readFileSync(preludeFile,'utf8'));
const replay=replayLeanEnvironmentInto(
  prelude.environment,
  fs.readFileSync(file,'utf8'),
);
const stats=replay.stats;
const required=[
  'Char.toNat',
  'String.push',
  'String.singleton',
  'String.Internal.length',
  'String.Internal.append',
  'String.Internal.next',
  'String.Internal.get',
  'String.Internal.atEnd',
  'String.Internal.extract',
];
for(const name of required){
  if(replay.environment.find(nameFromDotted(name))===undefined){
    throw new Error('text-foundation fixture missing '+name);
  }
}

console.log(JSON.stringify({
  ok:true,
  file,
  stats,
  baseConstants:prelude.environment.entries().length,
  constants:replay.environment.entries().length,
  addedConstants:replay.environment.entries().length-prelude.environment.entries().length,
  required:required.length,
},null,2));
