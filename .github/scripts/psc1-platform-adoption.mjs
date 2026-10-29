// Adopt the previously tested bytes; verify archive/source identities without rerunning compiler generations.
import fs from'node:fs';import path from'node:path';import assert from'node:assert/strict';
import{createHash}from'node:crypto';import{spawnSync}from'node:child_process';
const hash=b=>createHash('sha256').update(b).digest('hex');
const receipt=JSON.parse(fs.readFileSync('docs/PSC1_CROSS_PLATFORM_QUALIFICATION_2026-10-29.json'));
assert.equal(receipt.status,'qualified-finite-installed-node');
for(const pin of receipt.hostSources.pins){const bytes=fs.readFileSync('../'+pin.path);assert.equal(bytes.length,pin.bytes);assert.equal(hash(bytes),pin.sha256,pin.path);}
const unchanged=spawnSync('git',['diff','--exit-code',receipt.baseCommit,'HEAD','--','packages','host','lakefile.lean','lean-toolchain'],{encoding:'utf8'});
assert.equal(unchanged.status,0,unchanged.stdout+unchanged.stderr);
const token=process.env.GH_TOKEN,api=await fetch('https://api.github.com/repos/dwijayuda/pskernel/actions/runs/'+receipt.qualificationRun,
 {headers:{Authorization:'Bearer '+token,Accept:'application/vnd.github+json'},signal:AbortSignal.timeout(30000)});
assert.equal(api.status,200);const run=await api.json();assert.equal(run.head_sha,receipt.testedCommit);
assert.equal(run.conclusion,'success');assert.equal(run.status,'completed');
const input='dist/qualified-platform-delivery',archive=path.join(input,receipt.zip);
assert.equal(hash(fs.readFileSync(archive)),receipt.zipSha256);
const directory=path.resolve('dist/platform-adoption-extracted');fs.mkdirSync(directory,{recursive:true});
let r=spawnSync('unzip',['-q',path.resolve(archive),'-d',directory],{encoding:'utf8',timeout:120000});assert.equal(r.status,0,r.stderr);
const root=path.join(directory,'proofscript'),lines=fs.readFileSync(path.join(root,'SHA256SUMS'),'utf8').trim().split('\n');
for(const line of lines){const m=/^([a-f0-9]{64})  (.+)$/.exec(line);assert.ok(m);assert.ok(!m[2].split('/').includes('..')&&!path.posix.isAbsolute(m[2]));
 assert.equal(hash(fs.readFileSync(path.join(root,m[2]))),m[1],m[2]);}
assert.equal(hash(fs.readFileSync(path.join(root,receipt.package.tarball))),receipt.package.sha256);
const report={schema:'psc1-cross-platform-adoption/1',status:'passed',testedCommit:process.env.GITHUB_SHA,
 producerCommit:receipt.testedCommit,qualificationRun:receipt.qualificationRun,sourceFiles:receipt.hostSources.pins.length,
 compilerSourceUnchanged:true,compilerSourceClosureDigest:receipt.package.compilerSourceClosureDigest,
 packageSha256:receipt.package.sha256,zipSha256:receipt.zipSha256,extractedFiles:lines.length,repeatCompilation:false};
fs.writeFileSync(path.join(input,'adoption.json'),JSON.stringify(report,null,2)+'\n');
console.log('PSC1_CROSS_PLATFORM_ADOPTION '+JSON.stringify(report));
