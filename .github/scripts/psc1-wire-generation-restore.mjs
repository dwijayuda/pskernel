// Consume only this run's successful corrected-source portable G1.
import fs from'node:fs';import path from'node:path';import assert from'node:assert/strict';
import{readQualifiedArtifact,sha256}from'../../psc1/scripts/kernel435-qualified-artifact.mjs';
const response=await fetch('https://api.github.com/repos/dwijayuda/pskernel/actions/runs/'+process.env.GITHUB_RUN_ID+'/jobs?per_page=100',{headers:{Authorization:'Bearer '+process.env.GH_TOKEN},signal:AbortSignal.timeout(120000)});assert.equal(response.status,200);
const jobs=await response.json(),seed=jobs.jobs.find(j=>j.name==='seed');assert.equal(seed?.conclusion,'success');
const pin={run:Number(process.env.GITHUB_RUN_ID),job:seed.id,commit:process.env.GITHUB_SHA,artifact:Number(process.env.PSC1_SEED_ARTIFACT),zipSha256:process.env.PSC1_SEED_SHA256};
const archive=await readQualifiedArtifact(pin,'dist/wire-selfhost-seed-input');assert.ok(!fs.existsSync('dist/portable-modules'));fs.mkdirSync('dist/portable-modules',{recursive:true});
for(const name of['G1','compiler.request.json','g1-receipt.json','input.json','native-reference','execution']){const source=path.join(archive,name);assert.ok(fs.existsSync(source),name);fs.cpSync(source,path.join('dist/portable-modules',name),{recursive:true});}
const input=JSON.parse(fs.readFileSync('dist/portable-modules/input.json')),receipt=JSON.parse(fs.readFileSync('dist/portable-modules/g1-receipt.json'));
assert.equal(input.sourceCommit,pin.commit);assert.equal(receipt.sourceCommit,pin.commit);assert.equal(receipt.status,'passed-native-reference-and-portable-generation');assert.equal(input.g1.manifestSha256,receipt.manifestSha256);assert.equal(sha256(fs.readFileSync('dist/portable-modules/G1/manifest.json')),receipt.manifestSha256);
console.log('PSC1_WIRE_GENERATION_SEED '+JSON.stringify({pin,receipt,testedCommit:process.env.GITHUB_SHA}));
