// Same profiler against the newly assembled root, with no extra full qualification.
import fs from 'node:fs';import path from 'node:path';import os from 'node:os';import assert from'node:assert/strict';import{spawnSync}from'node:child_process';
const input=path.resolve('dist/modular-toolchain'),receipt=JSON.parse(fs.readFileSync(path.join(input,'package-receipt.json')));
const directory=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-persistent-after-'));
const run=args=>{const r=spawnSync(process.execPath,args,{cwd:directory,encoding:'utf8',timeout:240000,maxBuffer:33554432});assert.equal(r.error,undefined);assert.equal(r.status,0,r.stdout+r.stderr);return r.stdout;};
try{
 fs.writeFileSync(path.join(directory,'package.json'),'{"private":true,"type":"module"}');
 run([path.resolve(path.dirname(process.execPath),'../lib/node_modules/npm/bin/npm-cli.js'),'install','--offline','--ignore-scripts','--no-audit','--no-fund','--cache',path.join(directory,'cache'),'--registry','http://127.0.0.1:9',path.join(input,'tarballs',receipt.tarball)]);
 fs.copyFileSync('../.github/scripts/psc1-persistent-profile-driver.mjs',path.join(directory,'profile.mjs'));
 const reports=[];
 for(const mode of ['cold-check','cold-build','warm-check','warm-build']){
  const output=run([path.join(directory,'profile.mjs'),mode]),line=output.split('\n').find(l=>l.startsWith('PSC1_PERSISTENT_PROFILE '));assert.ok(line,output);const report=JSON.parse(line.slice('PSC1_PERSISTENT_PROFILE '.length));assert.ok(report.outcomes.every(x=>x.admission==='accepted'));reports.push(report);console.log(line);
 }
 fs.mkdirSync('dist/persistent-results',{recursive:true});fs.writeFileSync('dist/persistent-results/profile.json',JSON.stringify({commit:process.env.GITHUB_SHA,receipt,reports},null,2)+'\n');
}finally{fs.rmSync(directory,{recursive:true,force:true});}
