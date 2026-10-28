// Genuine offline installation fixture shared by modular API and retained watch tests.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';
import {sha256} from '../../psc1/scripts/kernel435-qualified-artifact.mjs';
export function fixture({consumers=false,allProviders=false,global=false}={}){
 const distribution=path.resolve('dist/modular-toolchain');
 const assembly=JSON.parse(fs.readFileSync(path.join(distribution,'package-receipt.json')));
 assert.equal(assembly.testedCommit,process.env.PSC1_MODULAR_INPUT_COMMIT);
 const tarBytes=fs.readFileSync(path.join(distribution,'tarballs',assembly.tarball));
 assert.equal(tarBytes.length,assembly.bytes);assert.equal(sha256(tarBytes),assembly.sha256);
 const resources=JSON.parse(fs.readFileSync(path.join(distribution,'resources.json')));
 const directory=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-modular-consumer-'));
 const runtime=process.env.PSC1_TEST_RUNTIME||process.execPath;
 const flags=path.basename(runtime).startsWith('bun')?['--no-install','--no-macros','--no-env-file']:[];
 const env={...process.env,PATH:[...new Set([path.dirname(runtime),path.dirname(process.execPath)])].join(path.delimiter)};
 for(const key of Object.keys(env))if(key==='NODE_OPTIONS'||key.startsWith('PSC1_')||key.startsWith('LEAN')||key.startsWith('ELAN')||key.startsWith('LD_')||key.startsWith('DYLD_')||key==='PSC_LEAN_KERNEL_PROVIDER_BIN')delete env[key];
 const run=(exe,args,cwd=directory)=>{const r=spawnSync(exe,args,{cwd,env,encoding:'utf8',timeout:240000,maxBuffer:33554432});assert.equal(r.error,undefined,String(r.error));return r;};
 const ok=(exe,args,cwd)=>{const r=run(exe,args,cwd);assert.equal(r.status,0,r.stdout+r.stderr);return r.stdout;};
 const installer=process.env.PSC1_TEST_NODE||process.execPath;
 const npm=path.resolve(path.dirname(installer),'../lib/node_modules/npm/bin/npm-cli.js');
 fs.writeFileSync(path.join(directory,'package.json'),'{"private":true,"type":"module"}');
 const prefix=global?path.join(directory,'global'):directory;
 const install=tars=>ok(installer,[npm,'install',...(global?['--global']:[]),'--prefix',prefix,'--offline','--registry','http://127.0.0.1:9','--ignore-scripts','--no-audit','--no-fund','--cache',path.join(directory,'empty-cache'),...tars]);
 install([path.join(distribution,'tarballs',assembly.tarball)]);
 const root=path.join(prefix,global?'lib/node_modules/proofscript':'node_modules/proofscript');
 const manifest=JSON.parse(fs.readFileSync(path.join(root,'node_modules/@proofscript/compiler/dist/host/UNIVERSAL_DISTRIBUTION.json')));
 const initialGraph=fs.readFileSync(path.join(root,'dist/COMPILER_GRAPH.json'));
 if(consumers||allProviders){
  const selected=resources.tarballs.filter(row=>allProviders||['typescript','@typescript/typescript-linux-x64','@proofscript/rust-target-consumer-linux-x64'].includes(row.package));
  install(selected.map(row=>row.file));
 }
 assert.deepEqual(fs.readFileSync(path.join(root,'dist/COMPILER_GRAPH.json')),initialGraph);
 const cli=path.join(root,'dist/psc.mjs');
 const call=(args,cwd)=>run(runtime,[...flags,cli,...args],cwd);
 const invoke=(args,cwd)=>ok(runtime,[...flags,cli,...args],cwd);
 const observe=receipt=>ok(runtime,[...flags,'--input-type=module','-e',
  'let m=await import('+JSON.stringify(pathToFileURL(receipt.runtimeArtifact||receipt.artifact).href)+');if(m.default)m=m.default;console.log(String(m.answer));']).trim();
 return {directory,runtime,flags,env,cli,root,assembly,manifest,resources,run,ok,call,invoke,observe};
}
