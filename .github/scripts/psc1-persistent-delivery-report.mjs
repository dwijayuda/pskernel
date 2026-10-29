// Read terminal delivery evidence only. No installation, compilation or qualification.
import fs from'node:fs';import path from'node:path';import assert from'node:assert/strict';import{spawnSync}from'node:child_process';
import{readQualifiedArtifact,sha256}from'../../psc1/scripts/kernel435-qualified-artifact.mjs';
const input=JSON.parse(fs.readFileSync('../.github/psc1/persistent-delivery.json'));
const archive=await readQualifiedArtifact(input,'dist/persistent-delivery-report-input');
const zip=path.join(archive,'proofscript-persistent-linux-x64.zip');
const r=spawnSync('python3',['-c','import zipfile,sys; z=zipfile.ZipFile(sys.argv[1]); i=z.getinfo("COMPARISON.json"); assert i.file_size==9228; sys.stdout.buffer.write(z.read(i))',zip],{encoding:'utf8',timeout:120000,maxBuffer:1048576});
assert.equal(r.error,undefined);assert.equal(r.status,0,r.stderr);assert.equal(Buffer.byteLength(r.stdout),input.comparisonBytes);assert.equal(sha256(r.stdout),input.comparisonSha256);
const report=JSON.parse(r.stdout);assert.equal(report.status,'passed');assert.equal(report.commit,input.commit);
console.log('PSC1_CONTROLLED_DELIVERY_REPORT '+JSON.stringify(report));

for(const [label,file]of [['before','persistent-profile/results.json'],['after','persistent-results/profile.json']]){
 const report=JSON.parse(fs.readFileSync(path.join(archive,file)));
 const app=report.reports.find(row=>row.mode==='warm-app');assert.ok(app);
 console.log('PSC1_REAL_APPLICATION_PHASES '+JSON.stringify({label,phases:app.phases,outcomes:app.outcomes,children:app.children,maxRssKiB:app.maxRssKiB}));
}
