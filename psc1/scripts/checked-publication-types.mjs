// Typecheck installed declarations with the exact offline optional TS consumer.
import fs from 'node:fs';import path from 'node:path';import os from 'node:os';import assert from 'node:assert/strict';import {spawnSync} from 'node:child_process';
const out=path.resolve('dist/slim-universal'),a=JSON.parse(fs.readFileSync(path.join(out,'package-receipt.json')));
const root=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-public-types-'));
fs.writeFileSync(path.join(root,'package.json'),'{"private":true,"type":"module"}');
const npm=path.resolve(path.dirname(process.execPath),'../lib/node_modules/npm/bin/npm-cli.js');
const run=args=>{const r=spawnSync(process.execPath,args,{cwd:root,encoding:'utf8',timeout:240000,maxBuffer:32*1024*1024});assert.equal(r.error,undefined,String(r.error));assert.equal(r.status,0,r.stdout+r.stderr);};
run([npm,'install','--prefix',root,'--cache',path.join(root,'empty-cache'),'--offline','--registry','http://127.0.0.1:9','--ignore-scripts','--no-audit','--no-fund',...[a.tarball,a.targetConsumers.ts.tarball,...a.targetConsumers.ts.dependencies.map(d=>d.tarball)].map(f=>path.join(out,'tarballs',f))]);
fs.writeFileSync(path.join(root,'consumer.mts'),`
import {compile,build,compileCandidate,readPublication,type Source,type CheckedTarget,type PublicationProtocol} from 'proofscript';
import {createTypedIo,type TypedIoConfiguration} from 'proofscript/io';
const sources:readonly Source[]=[{module:'Entry',kind:'lean',text:'def answer : Nat := 42'}];
const protocol:PublicationProtocol='portable-file';
for(const target of ['js','ts','rust','wasm-core','wasm-component','python','php'] as const){
 const checked=compile({sources,entryModule:'Entry',target});
 const encoding:'utf8'|'psc1-wasm-hex/1'|'psc1-wasm-component-hex/1'=checked.sourceEncoding;
 const built=build({sources,entryModule:'Entry',target,publicationProtocol:protocol,out:'out',rustToolchainRoot:'/sdk'});
 const file:string=built.runtimeArtifact; const selected:CheckedTarget=built.target;
 const current=readPublication({out:'out',publicationProtocol:protocol});
 console.log(encoding,file,selected,current?.generation);
}
const candidate=compileCandidate({sources,entryModule:'Entry',target:'rust'});const authority:false=candidate.publicationAuthority;
const config:TypedIoConfiguration={abi:'psc1-node-linux-string-io/1',capabilities:['readUtf8'],required:['readUtf8'],root:'/tmp',maxFileBytes:512,maxLineBytes:128,inputFd:0,outputFd:1};
const io=createTypedIo(config);io.close();
// @ts-expect-error unsupported checked target
compile({sources,entryModule:'Entry',target:'ruby'});
// @ts-expect-error closed protocol
build({sources,entryModule:'Entry',out:'out',publicationProtocol:'arbitrary'});
// @ts-expect-error no metadata authority
compile({sources,entryModule:'Entry',checkerExecutable:'/arbitrary'});
// @ts-expect-error readonly outcome
candidate.publicationAuthority=true;
console.log(authority);
`);
fs.writeFileSync(path.join(root,'tsconfig.json'),JSON.stringify({compilerOptions:{noEmit:true,strict:true,module:'NodeNext',moduleResolution:'NodeNext',target:'ES2022'},files:['consumer.mts']}));
run([path.join(root,'node_modules/typescript/bin/tsc'),'--project',path.join(root,'tsconfig.json')]);
fs.writeFileSync(path.join(out,'checked-publication-types.json'),JSON.stringify({schema:'psc1-checked-publication-types/1',testedCommit:process.env.GITHUB_SHA,status:'passed',typescript:'7.0.2',offline:true,tarballSha256:a.sha256},null,2)+'\n');
console.log('PSC1_CHECKED_PUBLICATION_TYPES: PASS');
