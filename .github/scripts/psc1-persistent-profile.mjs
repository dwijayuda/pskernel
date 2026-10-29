// Use the previously qualified .5 root; profile without modifying its payload.
import fs from 'node:fs';import path from 'node:path';import os from 'node:os';import assert from 'node:assert/strict';
import {spawnSync}from'node:child_process';
import {readQualifiedArtifact,sha256}from'../../psc1/scripts/kernel435-qualified-artifact.mjs';
const q=JSON.parse(fs.readFileSync('docs/PSC1_DEVELOPMENT_QUALIFICATION_2026-10-29.json'));
const archive=await readQualifiedArtifact(q.qualification,'dist/persistent-profile-input');
const tar=path.join(archive,'modular-toolchain/tarballs',q.package.tarball);assert.equal(sha256(fs.readFileSync(tar)),q.package.sha256);
const directory=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-persistent-profile-'));
const run=(args)=>{const r=spawnSync(process.execPath,args,{cwd:directory,encoding:'utf8',timeout:240000,maxBuffer:33554432});assert.equal(r.error,undefined,String(r.error));assert.equal(r.status,0,r.stdout+r.stderr);return r.stdout;};
const reports=[];
try{
 fs.writeFileSync(path.join(directory,'package.json'),'{"private":true,"type":"module"}');
 run([path.resolve(path.dirname(process.execPath),'../lib/node_modules/npm/bin/npm-cli.js'),'install','--offline','--ignore-scripts','--no-audit','--no-fund','--cache',path.join(directory,'cache'),'--registry','http://127.0.0.1:9',tar]);
 fs.copyFileSync('../.github/scripts/psc1-persistent-profile-driver.mjs',path.join(directory,'profile.mjs'));
 for(const mode of ['cold-check','cold-build','warm-check','warm-build']){
  const output=run([path.join(directory,'profile.mjs'),mode]);const line=output.split('\n').find(l=>l.startsWith('PSC1_PERSISTENT_PROFILE '));assert.ok(line,output);
  const r=JSON.parse(line.slice('PSC1_PERSISTENT_PROFILE '.length));assert.ok(r.outcomes.every(x=>x.admission==='accepted'));reports.push(r);console.log(line);
 }
 fs.mkdirSync('dist/persistent-profile',{recursive:true});fs.writeFileSync('dist/persistent-profile/results.json',JSON.stringify({schema:'psc1-persistent-profile/1',commit:process.env.GITHUB_SHA,package:q.package,reports},null,2)+'\n');
}finally{fs.rmSync(directory,{recursive:true,force:true});}
