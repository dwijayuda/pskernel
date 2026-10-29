// Reuse a terminal installed qualification. No compiler build or repeated self-host chain.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {readQualifiedArtifact,sha256} from '../../psc1/scripts/kernel435-qualified-artifact.mjs';
const q=JSON.parse(fs.readFileSync('docs/PSC1_PERSISTENT_QUALIFICATION_2026-10-29.json'));
assert.equal(q.status,'qualified-finite-linux-node');
const run=(exe,args,timeout=120000)=>{const r=spawnSync(exe,args,{encoding:'utf8',timeout,maxBuffer:33554432});assert.equal(r.error,undefined);assert.equal(r.status,0,r.stdout+r.stderr);return r.stdout;};
for(const pin of q.hostSources.pins){
 const bytes=fs.readFileSync(pin.path.slice(5));assert.equal(bytes.length,pin.bytes,pin.path);assert.equal(sha256(bytes),pin.sha256,pin.path);
 if(pin.path.endsWith('.mjs'))run(process.execPath,['--check',pin.path.slice(5)]);
}
run('git',['diff','--exit-code',q.baseCommit,'--','packages','host','lakefile.lean','lean-toolchain']);
const archive=await readQualifiedArtifact(q.qualification,'dist/persistent-qualified-input');
const pins=JSON.parse(fs.readFileSync(path.join(archive,'persistent-candidate/pins.json')));
assert.deepEqual(pins,q.hostSources);
const result=JSON.parse(fs.readFileSync(path.join(archive,'development-results/qualification.json')));
assert.equal(result.status,'passed');assert.deepEqual(result,q.results);
const receipt=JSON.parse(fs.readFileSync(path.join(archive,'modular-toolchain/package-receipt.json')));
assert.deepEqual(receipt,q.package);
const out=path.resolve('dist/proofscript-persistent-linux-x64');
fs.mkdirSync(out,{recursive:true});assert.equal(fs.readdirSync(out).length,0);
const tar=path.join(archive,'modular-toolchain/tarballs',receipt.tarball),bytes=fs.readFileSync(tar);
assert.equal(bytes.length,receipt.bytes);assert.equal(sha256(bytes),receipt.sha256);
fs.copyFileSync(tar,path.join(out,receipt.tarball));
const names=run('tar',['tzf',tar]).split('\n').filter(Boolean);
assert.ok(names.every(name=>name.startsWith('package/')&&!name.includes('\\')&&!name.split('/').includes('..')));
const extraction='dist/persistent-qualified-root';fs.mkdirSync(extraction,{recursive:true});run('tar',['xzf',tar,'-C',extraction]);
const pkg=path.join(extraction,'package');
const distributionBytes=fs.readFileSync(path.join(pkg,'node_modules/@proofscript/compiler/dist/host/UNIVERSAL_DISTRIBUTION.json'));
assert.equal(sha256(distributionBytes),receipt.consumerDescriptorsSha256);
const d=JSON.parse(distributionBytes);
const sdkDirectory='dist/development-typescript-input';
const sdk=JSON.parse(fs.readFileSync(path.join(sdkDirectory,'resources.json')));
assert.equal(sdk.platform,'linux-x64');
const expected=[d.targetConsumers.ts,...d.targetConsumers.ts.dependencies];
assert.equal(sdk.packages.length,expected.length);
for(const item of sdk.packages){
 const descriptor=expected.find(row=>row.package===item.package);
 assert.ok(descriptor);assert.equal(item.version,descriptor.version);
 assert.equal(item.sha256,descriptor.tarballSha256);
 assert.equal(item.tarball,path.basename(item.tarball));
 const b=fs.readFileSync(path.join(sdkDirectory,item.tarball));
 assert.equal(sha256(b),descriptor.tarballSha256);
 fs.writeFileSync(path.join(out,item.tarball),b);
}
for(const name of ['LICENSE','NOTICE'])if(fs.existsSync(path.join(pkg,name)))fs.copyFileSync(path.join(pkg,name),path.join(out,name));
fs.writeFileSync(path.join(out,'QUALIFICATION.json'),JSON.stringify(q,null,2)+'\n');
fs.writeFileSync(path.join(out,'INSTALL.md'),
 '# ProofScript .6 Linux x64 development package\n\n'+
 'Requires Node >=22.23.3. Qualified on Node22.23.3/Linux x64 only.\n'+
 'No npm registry publication. Extract this ZIP and run:\n\n'+
 '\`\`\`sh\n'+
 'npm init -y\n'+
 'npm install --offline --ignore-scripts ./'+receipt.tarball+' '+sdk.packages.map(p=>'./'+p.tarball).join(' ')+'\n'+
 'npm exec -- psc init\n'+
 'npm exec -- psc check\n'+
 'npm exec -- psc build --target ts --out out --watch\n'+
 '\`\`\`\n\n'+
 'Check omits target emission unless --target/ABI is explicit. Full audit dumps: --evidence full.\n'+
 'Watch retains compiler modules on Linux/Node. Independent checking and resource boundaries stay fresh.\n'+
 'QUALIFICATION.json records precise tested source/package identities, actual tests and performance.\n'+
 'New .6 host Windows/macOS/Bun qualification is pending; use qualified .4 for that platform evidence.\n');
fs.cpSync(path.join(archive,'modular-toolchain'),'dist/modular-toolchain',{recursive:true});
run(process.execPath,['../.github/scripts/psc1-persistent-compare.mjs'],600000);
const inventory=fs.readdirSync(out).sort().map(file=>({file,bytes:fs.statSync(path.join(out,file)).size,sha256:sha256(fs.readFileSync(path.join(out,file)))}));
fs.writeFileSync(path.join(out,'SHA256SUMS'),inventory.map(row=>row.sha256+'  '+row.file).join('\n')+'\n');
const adoption={schema:'psc1-persistent-source-adoption/1',commit:process.env.GITHUB_SHA,status:'passed',qualificationRun:q.qualification.run,sourcePins:q.hostSources.pins.length,unchangedCompilerSource:true,reusedTestedTarball:receipt.sha256,files:inventory};
fs.writeFileSync(path.join(out,'ADOPTION.json'),JSON.stringify(adoption,null,2)+'\n');
run('python3',['-c','import pathlib,zipfile; r=pathlib.Path("dist/proofscript-persistent-linux-x64"); z=zipfile.ZipFile(str(r)+".zip","w",zipfile.ZIP_DEFLATED); [z.write(p,p.name) for p in sorted(r.iterdir())]; z.close()']);
console.log('PSC1_PERSISTENT_ADOPTION '+JSON.stringify(adoption));
