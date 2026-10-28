// Deliver byte-identical qualified packages; never rebuild or publish them.
import fs from'node:fs';import path from'node:path';import assert from'node:assert/strict';
import{spawnSync}from'node:child_process';
import{readQualifiedArtifact,sha256}from'../../psc1/scripts/kernel435-qualified-artifact.mjs';
const input=JSON.parse(fs.readFileSync('../.github/scripts/psc1-preview-delivery-input.json'));
const out=path.resolve('dist/modular-preview-delivery');fs.mkdirSync(out,{recursive:true});
const qualified=await readQualifiedArtifact(input.package,path.join(out,'package-input'));
const receipt=JSON.parse(fs.readFileSync(path.join(qualified,'package-receipt.json')));
assert.equal(receipt.testedCommit,input.source);
assert.equal(receipt.compilerSourceClosureDigest,'41eb40437e0df1722128c09c9b9da7cad0ccb1ad61371f23eb6bc2db4e9a1106');
const diagnostics={};
for(const [runtime,pin]of Object.entries(input.diagnostics)){
 const archive=await readQualifiedArtifact(pin,path.join(out,'diagnostic-'+runtime));
 const boundary=JSON.parse(fs.readFileSync(path.join(archive,'boundaries-'+runtime+'.json')));
 const io=JSON.parse(fs.readFileSync(path.join(archive,'io-types-'+runtime+'.json')));
 for(const report of[boundary,io]){assert.equal(report.status,'passed');assert.equal(report.inputCommit,input.source);}
 assert.equal(boundary.cases.length,23);assert.equal(io.records.length,8);assert.equal(io.negatives.length,4);
 assert.deepEqual(io.typeConsumers,['NodeNext','Bundler']);assert.equal(io.tsWatch.builds,2);
 diagnostics[runtime]={boundaryCases:23,ioBuilds:8,ioRefusals:4,typeConsumers:io.typeConsumers,tsWatch:io.tsWatch,pin};
}
const installable=path.join(out,'installable');fs.mkdirSync(installable);
const tar=fs.readFileSync(path.join(qualified,'tarballs',receipt.tarball));
assert.equal(tar.length,receipt.bytes);assert.equal(sha256(tar),receipt.sha256);
fs.writeFileSync(path.join(installable,receipt.tarball),tar);
for(const file of['LICENSE','NOTICE'])fs.copyFileSync(file,path.join(installable,file));
fs.writeFileSync(path.join(installable,'INSTALL.txt'),[
 'ProofScript checked modular compiler preview '+receipt.version,
 'Qualified focused Linux preview. Not a new modular self-hosted/fixed-point release.',
 'Verify SHA256SUMS, then install only the root tarball:',
 '  npm install --offline --ignore-scripts ./'+receipt.tarball,
 '  npx --no-install psc --help',
 '  npx --no-install psc init',
 '  npx --no-install psc check',
 '  npx --no-install psc build --out out --publication-protocol portable-file',
 '  npx --no-install psc build --out out --engine ts --watch',
 '',
 'Node >=22.23.3 or Bun >=1.4.4. Actual preview qualification uses Node22.23.3/Bun1.4.4 on Linux.',
 'The root bundles all20 core packages and the genuine official Lean4.35.0 C++/Emscripten linear-memory Wasm kernel.',
 'Core packages live inside node_modules/proofscript/node_modules/@proofscript. Use stable proofscript/* subpaths instead of assuming hoisting.',
 'Example generated navigation: proofscript/foundation/generated/runtime and proofscript/foundation/generated/runtime/ts.',
 'Both JS/TS compiler engines execute genuine source-owned modules. There is no dist/implementation/module.js compiler bundle.',
 'Checked compile/build entry points remain at proofscript and @proofscript/compiler; lower old ./compiler aliases are removed in this versioned preview.',
 'Standalone checked-host installation is not qualified; install the umbrella.',
 '',
 'Python/PHP remain optional independent providers. TS/Rust/component output SDKs are optional and must match the exact qualified target resource archive.',
 'No install/build operation downloads a missing SDK. Rust target validation retains the exact official1.90.0 SDK policy.',
 'Rust/Wasm outputs are supported through JS/TS. Older Rust/Wasm compiler executors remain with the preserved .13 reference and refuse this newer source cohort.',
 'Other-platform durability, native binary reproduction and new modular G2/G3/fixed points are not qualified.',
 'No merge or npm publication has occurred. Preserve the .13 reference.'
 ].join('\n')+'\n');
const report={schema:'psc1-modular-preview-delivery/1',status:'qualified-focused-linux-preview',
 testedCommit:process.env.GITHUB_SHA,packageCommit:input.source,package:receipt,diagnostics,
 modularQualificationRun:input.qualificationRun,sourceAndReferenceCliQualification:'recorded separately in repository qualification receipt',
 noRegistryPublication:true,noMerge:true,fullModularSelfHosting:false,defaultReferenceReplaced:false};
fs.writeFileSync(path.join(installable,'QUALIFICATION.json'),JSON.stringify(report,null,2)+'\n');
fs.writeFileSync(path.join(installable,'SHA256SUMS'),fs.readdirSync(installable).sort().map(name=>
 sha256(fs.readFileSync(path.join(installable,name)))+'  '+name).join('\n')+'\n');
const zip=path.join(out,'proofscript-'+receipt.version+'-installable.zip');
const py='import zipfile,pathlib,sys\nroot=pathlib.Path(sys.argv[1])\nwith zipfile.ZipFile(sys.argv[2],"w",compression=zipfile.ZIP_DEFLATED,compresslevel=9) as z:\n for p in sorted(root.iterdir()): z.write(p,p.name)\nwith zipfile.ZipFile(sys.argv[2]) as z:\n assert z.testzip() is None\n';
const result=spawnSync('python3',['-c',py,installable,zip],{encoding:'utf8',timeout:240000});
assert.equal(result.error,undefined);assert.equal(result.status,0,result.stderr);
const bytes=fs.readFileSync(zip),final={...report,zip:path.basename(zip),zipBytes:bytes.length,zipSha256:sha256(bytes)};
fs.writeFileSync(path.join(out,'delivery.json'),JSON.stringify(final,null,2)+'\n');
console.log('PSC1_MODULAR_PREVIEW_DELIVERY '+JSON.stringify(final));
