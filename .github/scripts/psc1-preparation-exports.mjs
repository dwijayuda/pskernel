import fs from'node:fs';import path from'node:path';import os from'node:os';import assert from'node:assert/strict';
import{spawnSync}from'node:child_process';import{pathToFileURL}from'node:url';import{verify}from'../../psc1/host-tools/executable/verify.mjs';
const input=path.resolve('dist/development-input'),r=JSON.parse(fs.readFileSync(path.join(input,'package-receipt.json')));
const directory=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-api-probe-')),npm=path.resolve(path.dirname(process.execPath),'../lib/node_modules/npm/bin/npm-cli.js');
try{
 fs.writeFileSync(path.join(directory,'package.json'),'{"private":true,"type":"module"}');
 const x=spawnSync(process.execPath,[npm,'install','--offline','--ignore-scripts','--no-audit','--no-fund','--cache',path.join(directory,'cache'),
 '--registry','http://127.0.0.1:9',path.join(input,'tarballs',r.tarball)],{cwd:directory,encoding:'utf8',timeout:240000,maxBuffer:33554432});
 assert.equal(x.status,0,x.stderr);
 const root=path.join(directory,'node_modules/proofscript'),nodes=path.join(root,'node_modules');
 const m=verify(nodes,fs.readFileSync(path.join(root,'dist/COMPILER_GRAPH.json')),r.manifestSha256);
 const rows=[];
 for(const [owner,name]of[['compiler','Ps.Compiler.Service'],['compiler','Ps.Compiler.Api'],['compiler-ir','Ps.CompilerIr.Validate'],['bridge','Ps.Bridge.Json'],['foundation','runtime']]){
 const file=path.join(nodes,'@proofscript',owner,'dist/js/generated',name+'.mjs'),mod=await import(pathToFileURL(file));
 const selected=Object.keys(mod).filter(n=>owner!=='foundation'||/Except|Option|List|psFn_|PsCompilerSourceKind/.test(n)).slice(0,100);
 rows.push({owner,name,exports:selected.map(n=>({name:n,type:typeof mod[n],keys:mod[n]&&typeof mod[n]==='object'?Object.keys(mod[n]).slice(0,15):undefined})),
 names:m.owners.filter(([n])=>n.includes(name.replace('Ps.Compiler.',''))).slice(0,12)});
 console.log('PSC1_PREPARATION_EXPORTS '+JSON.stringify(rows.at(-1)));
 }
 fs.mkdirSync('dist/development-profile',{recursive:true});fs.writeFileSync('dist/development-profile/exports.json',JSON.stringify(rows,null,2));
}finally{fs.rmSync(directory,{recursive:true,force:true});}
