// Consume the successful portable G1 job without regenerating it after transport fixes.
import fs from'node:fs';import path from'node:path';import assert from'node:assert/strict';
import{readQualifiedArtifact,sha256}from'../../psc1/scripts/kernel435-qualified-artifact.mjs';
const request=JSON.parse(fs.readFileSync('../.github/psc1/wire-generations.json')),pin=request.seed;
assert.ok(pin);const archive=await readQualifiedArtifact(pin,'dist/wire-selfhost-seed-input');
assert.ok(!fs.existsSync('dist/portable-modules'));fs.mkdirSync('dist/portable-modules',{recursive:true});
// A single uploaded directory is rooted at its contents, not its folder name.
for(const name of['G1','compiler.request.json','g1-receipt.json','input.json','native-reference','execution']){
 const source=path.join(archive,name);assert.ok(fs.existsSync(source),name);fs.cpSync(source,path.join('dist/portable-modules',name),{recursive:true});
}
const input=JSON.parse(fs.readFileSync('dist/portable-modules/input.json')),receipt=JSON.parse(fs.readFileSync('dist/portable-modules/g1-receipt.json'));
assert.equal(input.sourceCommit,pin.commit);assert.equal(receipt.sourceCommit,pin.commit);assert.equal(receipt.status,'passed-native-reference-and-portable-generation');
assert.equal(input.g1.manifestSha256,receipt.manifestSha256);assert.equal(receipt.manifestSha256,request.manifestSha256);assert.equal(receipt.sourceClosureDigest,request.sourceDigest);
assert.equal(sha256(fs.readFileSync('dist/portable-modules/G1/manifest.json')),request.manifestSha256);
console.log('PSC1_WIRE_GENERATION_SEED '+JSON.stringify({pin,receipt,testedCommit:process.env.GITHUB_SHA}));
