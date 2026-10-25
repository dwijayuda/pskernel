import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {buildTarget,observeArtifact,sha} from '../host-tools/generated-target-tools.mjs';
const root=path.resolve('dist/rust-nat-literal'),expected=JSON.parse(fs.readFileSync(path.join(root,'expected.json')));
const observed=[],events=[];
for(const kind of ['legacy','current']){
 const source=fs.readFileSync(path.join(root,kind+'.rs'),'utf8');
 const artifact=buildTarget({target:'rust',source,directory:path.join(root,kind),publicNames:['observe'],
  consumer:'let values: Vec<String> = observe().iter().map(|n|n.to_string()).collect(); println!("{:?}",values);'});
 const result=observeArtifact(artifact);assert.deepEqual(result.observation,expected);
 observed.push(result.observation);events.push(result.event);
}
assert.deepEqual(observed[0],observed[1]);
const source=fs.readFileSync(path.join(root,'current.rs'),'utf8');
assert.match(source,/PsNat::from\(18446744073709551615u64\)/);
assert.match(source,/__ps_nat_lit\("18446744073709551616"\)/);
const receipt={schema:'psc1-rust-nat-literal/1',testedCommit:process.env.GITHUB_SHA,
 values:expected,observations:observed[0].length,events,sourceSha256:sha(source),
 publicNatABI:'unchanged BigUint',arbitraryPrecisionFallback:'exact retained decimal parser',
 qualification:'finite exact literal regression; full G2/G3 is separate'};
fs.writeFileSync(path.join(root,'receipt.json'),JSON.stringify(receipt,null,2)+'\n');
console.log('PSC1_RUST_NAT_LITERAL: '+JSON.stringify(receipt));
