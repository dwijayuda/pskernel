import fs from 'node:fs';
import { resolve } from 'node:path';
import { Lean4ExportReplay } from '../dist/src/integration/lean4export.js';
import { nameFromDotted } from '../dist/src/core/name.js';
import { N } from '../dist/src/kernel/names.js';

const file=resolve(process.argv[2]??'oracle/fixtures/lean434-primitive-closure.ndjson');
if(!fs.existsSync(file)) throw new Error(`missing pinned primitive closure fixture: ${file}`);
const replay=new Lean4ExportReplay();
const stats=replay.replay(fs.readFileSync(file,'utf8'));
const expected={lines:14702,names:2233,levels:18,expressions:12125,declarations:325};
for(const [k,v] of Object.entries(expected)) if(stats[k]!==v) throw new Error(`primitive closure ${k} drift: got ${stats[k]}, expected ${v}`);
if(replay.env.entries().length!==390) throw new Error(`primitive closure constant count drift: got ${replay.env.entries().length}, expected 390`);
for(const n of [N.NatAdd,N.NatSub,N.NatPred,N.NatBeq,N.NatBle,N.NatMod,N.NatDiv,N.NatGcd,N.NatBitwise,N.NatBitwiseUnaryProof1]){
  if(!replay.env.has(n)) throw new Error(`primitive closure missing admitted constant`);
}
if(!replay.env.has(nameFromDotted('Nat.bitwise._unary'))) throw new Error('primitive closure missing Nat.bitwise._unary');
console.log(JSON.stringify({ok:true,file,stats,constants:replay.env.entries().length},null,2));
