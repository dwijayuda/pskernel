import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {buildTarget,observeArtifact,sha} from '../host-tools/generated-target-tools.mjs';
const root=path.resolve('dist/rust-string-ownership'),publicNames=['readEnd','readNext','readGet','scan','scanAlias','scanWorker','swap','duplicate','later','shadow'];
const consumer=`
let mut observations=Vec::<String>::new();
for text in ["", "abcd", "λ🙂ab", "abcdef"].iter() {
 let input=String::from(*text);
 for fuel in [0u32,1,2,7,100].iter() {
  observations.push(scan(PsNat::from(*fuel),input.clone(),PsNat::from(0u32),PsNat::from(0u32)).to_string());
  observations.push(scanAlias(PsNat::from(*fuel),input.clone(),PsNat::from(0u32),PsNat::from(0u32)).to_string());
  observations.push(scanWorker(PsNat::from(*fuel),input.clone(),PsNat::from(0u32),PsNat::from(0u32)).to_string());
  observations.push(later(PsNat::from(*fuel),input.clone(),PsNat::from(0u32)).to_string());
  observations.push(swap(PsNat::from(*fuel),String::from("abc"),String::from("λ")).to_string());
  observations.push(duplicate(PsNat::from(*fuel),String::from("abc"),String::from("λ")).to_string());
 }
 assert!(shadow(input));
}
println!("{:?}",observations);
`;
const observations=[];
for(const kind of ['legacy','current']){
 const source=fs.readFileSync(path.join(root,kind+'.rs'),'utf8');
 const artifact=buildTarget({target:'rust',source,directory:path.join(root,kind),consumer,publicNames});
 observations.push(observeArtifact(artifact).observation);
}
assert.deepEqual(observations[1],observations[0]);
const current=fs.readFileSync(path.join(root,'current.rs'),'utf8');
assert.ok(current.includes('__ps_internal_tail_arg_'),'snapshot temporaries emitted');
const large=`
let input=String::from("λ🙂ab").repeat(250000);
let expected=PsNat::from(1000000u32);
assert_eq!(scan(PsNat::from(1000001u32),input.clone(),PsNat::from(0u32),PsNat::from(0u32)),expected);
assert_eq!(scanWorker(PsNat::from(1000001u32),input.clone(),PsNat::from(0u32),PsNat::from(0u32)),expected);
assert_eq!(scanAlias(PsNat::from(1000001u32),input,PsNat::from(0u32),PsNat::from(0u32)),expected);
println!("{{}}");
`;
const artifact=buildTarget({target:'rust',source:current,directory:path.join(root,'scale'),consumer:large,publicNames});
const result=observeArtifact(artifact);
const receipt={schema:'psc1-rust-string-ownership/1',testedCommit:process.env.GITHUB_SHA,differentialObservations:observations[0].length,unicodeCharactersPerScan:1000000,scans:3,scaleEvent:result.event,legacyEmitterSha256:sha(fs.readFileSync('test/RustStringOwnershipReference.lean')),sourceSha256:sha(current),publicStringABI:'unchanged',defaultStack:'unchanged'};
fs.writeFileSync(path.join(root,'receipt.json'),JSON.stringify(receipt,null,2)+'\n');console.log('PSC1_RUST_STRING_OWNERSHIP: '+JSON.stringify(receipt));
