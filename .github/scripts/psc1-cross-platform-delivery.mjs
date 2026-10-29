// Package exactly the shared tarball that passed all four installed-runtime jobs.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import{createHash}from'node:crypto';import{spawnSync}from'node:child_process';
const sha=b=>createHash('sha256').update(b).digest('hex'),json=x=>JSON.stringify(x,null,2)+'\n';
const input=path.resolve('dist/modular-toolchain'),receipt=JSON.parse(fs.readFileSync(path.join(input,'package-receipt.json')));
const reports=fs.readdirSync('dist/all-platform-results').filter(n=>n.endsWith('.json')).sort()
 .map(n=>JSON.parse(fs.readFileSync(path.join('dist/all-platform-results',n))));
assert.equal(reports.length,4);
assert.deepEqual(reports.map(r=>r.platform+'-'+r.arch).sort(),['darwin-arm64','darwin-x64','linux-x64','win32-x64'].sort());
for(const r of reports){assert.equal(r.status,'passed');assert.equal(r.testedCommit,process.env.GITHUB_SHA);
 assert.equal(r.tarballSha256,receipt.sha256);assert.equal(r.records.length,12);}
const sourcePins=JSON.parse(fs.readFileSync('dist/platform-host-candidate/pins.json'));
assert.equal(sourcePins.producerCommit,process.env.GITHUB_SHA);
const out=path.resolve('dist/cross-platform-delivery'),stage=path.join(out,'proofscript');
fs.mkdirSync(stage,{recursive:true});
const copy=(from,to)=>{fs.mkdirSync(path.dirname(to),{recursive:true});fs.copyFileSync(from,to);};
const tar=path.join(input,'tarballs',receipt.tarball);assert.equal(sha(fs.readFileSync(tar)),receipt.sha256);
copy(tar,path.join(stage,receipt.tarball));
for(const name of['LICENSE','NOTICE'])copy(name,path.join(stage,name));
copy(path.join(input,'package-receipt.json'),path.join(stage,'evidence/package-receipt.json'));
copy('dist/platform-host-candidate/pins.json',path.join(stage,'evidence/host-source-pins.json'));
const qualification={schema:'psc1-cross-platform-delivery/1',status:'qualified-finite-installed-node',
 testedCommit:process.env.GITHUB_SHA,qualificationRun:Number(process.env.GITHUB_RUN_ID),package:receipt,reports,
 compilerGraphReused:true,selfHostingRerun:false,scope:'Node 22.23.3; Linux x64, Windows x64, macOS x64/arm64; JS/TS engines and JS/TS/Wasm-core output. Windows atomic visibility only; no power-loss directory-durability claim. Rust/component SDK and optional Python/PHP remain separately restricted. Not universal release readiness.'};
fs.writeFileSync(path.join(stage,'evidence/cross-platform.json'),json(qualification));
const sdkRoot='dist/all-platform-typescript',seen=new Map(),platforms=[];
for(const name of fs.readdirSync(sdkRoot).sort()){
 const directory=path.join(sdkRoot,name),r=JSON.parse(fs.readFileSync(path.join(directory,'resources.json')));
 platforms.push(r.platform);
 for(const row of r.packages){
  const file=path.join(directory,row.tarball),bytes=fs.readFileSync(file);assert.equal(sha(bytes),row.sha256);
  if(seen.has(row.tarball)){assert.equal(seen.get(row.tarball),row.sha256);continue;}
  seen.set(row.tarball,row.sha256);copy(file,path.join(stage,'optional/typescript',row.tarball));
 }
 fs.writeFileSync(path.join(stage,'optional/typescript',r.platform+'.json'),json(r));
}
assert.deepEqual(platforms.sort(),['darwin-arm64','darwin-x64','linux-x64','win32-x64'].sort());
fs.writeFileSync(path.join(stage,'INSTALL.md'),[
 '# ProofScript modular npm preview','',
 'Requires Node >=22.23.3. This archive was tested on Node 22.23.3 on Linux x64, Windows x64, macOS x64 and Apple Silicon.',
 'Extract the ZIP, open a terminal in the proofscript folder, then:',
 '',
 '    npm install --offline --ignore-scripts --no-audit --no-fund ./'+receipt.tarball,
 '    npx --offline psc --version',
 '    npx --offline psc init',
 '    npx --offline psc check',
 '    npx --offline psc build Main.ps --out out --watch','',
 'The root bundles the 20 core packages and real official Lean 4.35.0 linear-memory Wasm kernel. JS/TS compiler engines and JS/Wasm-core output need no target SDK.',
 'For checked TypeScript output, install optional/typescript/typescript-7.0.2.tgz and the matching native archive named in optional/typescript/<platform>.json. Use explicit tarball filenames, not all platform archives together. Then use --target ts.',
 'Linux defaults to legacy-symlink, macOS to portable-file. Windows defaults to portable-atomic: complete atomic visibility, explicitly visibility-only durability. Durable portable-file refuses on Windows; no silent downgrade.',
 'Use --engine ts for the TypeScript-generated compiler. Existing Rust/Wasm compiler executor bundles are not qualified for this newer compiler source. Rust/component SDKs and Python/PHP are separate optional integrations with their prior platform restrictions.',
 'This is finite installed-toolchain qualification, not all-platform release qualification, power-loss certification, native binary reproduction or a new self-hosting run.',
 'All archive hashes, exact source identities and platform results are under evidence/. Apache-2.0; see LICENSE/NOTICE.'
].join('\n')+'\n');
function walk(dir,prefix=''){return fs.readdirSync(path.join(dir,prefix)).sort().flatMap(n=>{
 const p=prefix?prefix+'/'+n:n,s=fs.lstatSync(path.join(dir,p));assert.ok(!s.isSymbolicLink());
 return s.isDirectory()?walk(dir,p):[{path:p,sha256:sha(fs.readFileSync(path.join(dir,p)))}];});}
const pins=walk(stage);fs.writeFileSync(path.join(stage,'SHA256SUMS'),pins.map(r=>r.sha256+'  '+r.path).join('\n')+'\n');
const zip=path.join(out,'proofscript-'+receipt.version+'-cross-platform.zip');
const result=spawnSync('zip',['-q','-r',zip,'proofscript'],{cwd:out,encoding:'utf8',timeout:240000});assert.equal(result.status,0,result.stderr);
const check=spawnSync('unzip',['-t',zip],{encoding:'utf8',timeout:240000});assert.equal(check.status,0,check.stdout+check.stderr);
const bytes=fs.readFileSync(zip),delivery={...qualification,zip:path.basename(zip),zipBytes:bytes.length,zipSha256:sha(bytes),files:pins.length};
fs.writeFileSync(path.join(out,'delivery.json'),json(delivery));
console.log('PSC1_CROSS_PLATFORM_DELIVERY '+JSON.stringify(delivery));
