import fs from 'node:fs';
import {resolve} from 'node:path';
import {Lean4ExportReplay} from '../dist/src/integration/lean4export.js';
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

const replay=new Lean4ExportReplay();
const stats=replay.replay(fs.readFileSync(file,'utf8'));
const required=[
  'Char.ofNat',
  'Char.toNat',
  'Char.isWhitespace',
  'Char.isUpper',
  'Char.isLower',
  'Char.isAlpha',
  'Char.isDigit',
  'Char.isAlphanum',
  'String.push',
  'String.singleton',
  'String.append',
  'String.length',
  'String.utf8ByteSize',
  'String.rawStartPos',
  'String.rawEndPos',
  'String.Pos.Raw.get',
  'String.Pos.Raw.get?',
  'String.Pos.Raw.next',
  "String.Pos.Raw.next'",
  'String.Pos.Raw.atEnd',
  'String.Pos.Raw.extract',
  'String.Pos.Raw.prev',
];
for(const name of required){
  if(replay.env.find(nameFromDotted(name))===undefined){
    throw new Error('text-foundation fixture missing '+name);
  }
}

console.log(JSON.stringify({
  ok:true,
  file,
  stats,
  constants:replay.env.entries().length,
  required:required.length,
},null,2));
