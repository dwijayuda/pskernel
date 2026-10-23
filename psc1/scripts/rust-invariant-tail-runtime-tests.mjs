// Actual generated Rust ownership/order regression, separate from the frozen corpus.
import assert from 'node:assert/strict';import fs from 'node:fs';import path from 'node:path';
import {buildTarget,observeArtifact,sha} from '../host-tools/generated-target-tools.mjs';
const root=path.resolve('dist/rust-invariant-tail'),source=fs.readFileSync(path.join(root,'module.rs'),'utf8');
const consumer=`
let text = "λ🙂".repeat(10000);
let start = std::time::Instant::now();
let baseline = baseline_scan(text.clone(), PsNat::from(100000u32));
let baseline_ns = start.elapsed().as_nanos();
let start = std::time::Instant::now();
let moved = moved_scan(text.clone(), PsNat::from(100000u32));
let moved_ns = start.elapsed().as_nanos();
assert_eq!(baseline, moved); assert_eq!(moved, PsNat::from(text.len()));
for steps in [0u32, 1u32, 7u32] {
 let b=baseline_order(text.clone(),PsNat::from(steps),PsNat::from(3u8));
 let m=moved_order(text.clone(),PsNat::from(steps),PsNat::from(3u8));
 assert_eq!(b,m);assert_eq!(m,PsNat::from(3usize+steps as usize*text.len()));
 let b=baseline_duplicate(text.clone(),String::from("a"),PsNat::from(steps));
 let m=moved_duplicate(text.clone(),String::from("a"),PsNat::from(steps));
 assert_eq!(b,m);assert_eq!(m,PsNat::from(if steps==0 {1usize}else{text.len()}));
 assert_eq!(baseline_shadow(text.clone(),PsNat::from(steps)),PsNat::from(1u8));
 assert_eq!(moved_shadow(text.clone(),PsNat::from(steps)),PsNat::from(1u8));
 assert_eq!(baseline_reserved(text.clone(),PsNat::from(steps)),moved_reserved(text.clone(),PsNat::from(steps)));
 assert_eq!(baseline_renamed(text.clone(),PsNat::from(steps)),moved_renamed(text.clone(),PsNat::from(steps)));
 assert_eq!(moved_renamed(text.clone(),PsNat::from(steps)),PsNat::from(text.len()));
 assert_eq!(baseline_retained(text.clone(),PsNat::from(steps)),moved_retained(text.clone(),PsNat::from(steps)));
 assert_eq!(moved_retained(text.clone(),PsNat::from(steps)),PsNat::from(2*text.len()));
}
println!("{{\\\"bytes\\\":{},\\\"steps\\\":100000,\\\"baselineNs\\\":{},\\\"movedNs\\\":{},\\\"guards\\\":\\\"passed\\\"}}",text.len(),baseline_ns,moved_ns);
`;
const artifact=buildTarget({target:'rust',source,directory:path.join(root,'execution'),consumer,publicNames:[]});
const result=observeArtifact(artifact);assert.equal(result.observation.guards,'passed');
const report={schema:'psc1-rust-invariant-tail-runtime/1',commit:process.env.GITHUB_SHA,
 irSha256:sha(fs.readFileSync(path.join(root,'original-ir.json'))),sourceSha256:sha(source),
 artifactSha256:artifact.sha256,processDeadlineMs:240000,...result.observation,event:result.event,
 scope:'exact old/current generated Rust; real G2 qualification remains separate'};
fs.writeFileSync(path.join(root,'runtime.json'),JSON.stringify(report,null,2)+'\n');
console.log('PSC1_RUST_INVARIANT_RUNTIME: '+JSON.stringify(report));
