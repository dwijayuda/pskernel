// Bounded Linux build/qualification tools. No project input selects capabilities.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
export const sha256=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
export const json=value=>JSON.stringify(value,null,2)+'\n';
export const output=path.resolve('dist/executable-packages/compiler');
export function put(file,bytes){
 fs.mkdirSync(path.dirname(file),{recursive:true});
 fs.writeFileSync(file,bytes,{flag:'wx'});
}
export function files(root,prefix=''){
 return fs.readdirSync(path.join(root,prefix)).sort().flatMap(name=>{
  const relative=prefix?prefix+'/'+name:name,absolute=path.join(root,relative),s=fs.lstatSync(absolute);
  assert.ok(!s.isSymbolicLink(),'PSC1_EXECUTABLE_SYMLINK');
  if(s.isDirectory())return files(root,relative);
  assert.ok(s.isFile(),'PSC1_EXECUTABLE_FILE_KIND');
  const bytes=fs.readFileSync(absolute);return [{path:relative,bytes:bytes.length,sha256:sha256(bytes)}];
 });
}
export function run(command,args,options={}){
 const result=spawnSync(command,args,{encoding:'utf8',timeout:240000,maxBuffer:33554432,...options});
 assert.equal(result.error,undefined,result.error?.message);
 assert.equal(result.status,0,result.stdout+'\n'+result.stderr);
 return result.stdout;
}
export function bounded(label,command,{seconds=240,addressSpace=true}={}){
 assert.ok(seconds>0&&seconds<=240);
 const supervisor=path.resolve('host-tools/process/bounded-process.py');
 const log=path.join(output,'execution',label);
 const report=JSON.parse(run('python3',[supervisor,JSON.stringify({
  command:['/usr/bin/prlimit',...(addressSpace?['--as=4294967296']:[]),'--stack=8388608','--cpu='+seconds,'--',...command],
  directory:log,timeoutMs:seconds*1000,maxBuffer:33554432
 })],{timeout:seconds*1000+5000}));
 const stdout=fs.readFileSync(path.join(log,'tool.stdout.txt'),'utf8');
 const stderr=fs.readFileSync(path.join(log,'tool.stderr.txt'),'utf8');
 console.log('PSC1_EXECUTABLE_EXECUTION '+label+' '+JSON.stringify(report));
 assert.ok(!report.error&&report.status===0,label+': '+stderr+'\n'+stdout);
 return {report,stdout,stderr};
}
export function inventory(root){
 const rows=files(root);assert.ok(rows.length<=8192,'PSC1_EXECUTABLE_FILE_COUNT');
 assert.ok(rows.every(r=>r.bytes<=33554432),'PSC1_EXECUTABLE_FILE_BOUND');
 assert.ok(rows.reduce((n,r)=>n+r.bytes,0)<=134217728,'PSC1_EXECUTABLE_AGGREGATE_BOUND');
 return rows;
}
