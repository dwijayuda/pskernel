import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {createTypedIo} from '../host-tools/typed-io.mjs';
const work=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-io-policy-'));
const root=path.join(work,'root');fs.mkdirSync(root);
const input=path.join(work,'input'),output=path.join(work,'output');
fs.writeFileSync(input,Buffer.from('😀\r\n\nlast','utf8'));fs.writeFileSync(output,'');
const inputFd=fs.openSync(input,'r'),outputFd=fs.openSync(output,'w');
const config={abi:'psc1-node-linux-string-io/1',capabilities:['readLine','writeLine','readUtf8','writeUtf8'],
 required:[],root,maxFileBytes:32,maxLineBytes:16,inputFd,outputFd};
const checks=[];
function check(name,fn){fn();checks.push(name);}
const request=(host,op,fields={})=>JSON.parse(host.execute(JSON.stringify({op,...fields})));
const isError=(value,error)=>assert.deepEqual(value,{kind:'error',error});
let host;
try{
 check('unsupported ABI refuses before opening root',()=>{
  assert.throws(()=>createTypedIo({...config,abi:'wasm-component',root:'/missing'}),/UNSUPPORTED_ABI/);
 });
 check('required capability denied before execution',()=>{
  assert.throws(()=>createTypedIo({...config,capabilities:[],required:['writeUtf8'],root:'/missing'}),/REQUIRED_CAPABILITY_DENIED/);
 });
 check('finite and exact configuration',()=>{
  for(const maxFileBytes of [0,-1,Infinity,1.1,16777217])assert.throws(()=>createTypedIo({...config,maxFileBytes}),/CONFIGURATION/);
  assert.throws(()=>createTypedIo({...config,unexpected:true}),/CONFIGURATION/);
 });
 host=createTypedIo(config);
 check('UTF-8 CRLF empty line unterminated line and EOF',()=>{
  for(const text of ['😀','','last',null,null])assert.deepEqual(request(host,'readLine'),{kind:'line',text});
 });
 check('writeLine emits exactly one LF',()=>{
  assert.deepEqual(request(host,'writeLine',{text:'😀'}),{kind:'unit'});
  assert.deepEqual(request(host,'writeLine',{text:''}),{kind:'unit'});
  assert.equal(fs.readFileSync(output,'utf8'),'😀\n\n');
  isError(request(host,'writeLine',{text:'bad\nline'}),'protocolError');
  isError(request(host,'writeLine',{text:'bad\rline'}),'protocolError');
 });
 check('bounded regular UTF-8 file round trip and BOM preservation',()=>{
  assert.deepEqual(request(host,'writeUtf8',{path:'data',text:'\uFEFF😀\n'}),{kind:'unit'});
  assert.deepEqual(request(host,'readUtf8',{path:'data'}),{kind:'text',text:'\uFEFF😀\n'});
  fs.mkdirSync(path.join(root,'nested'));
  assert.deepEqual(request(host,'writeUtf8',{path:'nested/empty',text:''}),{kind:'unit'});
  assert.deepEqual(request(host,'readUtf8',{path:'nested/empty'}),{kind:'text',text:''});
 });
 check('byte bound includes Unicode and preserves previous file on refusal',()=>{
  fs.writeFileSync(path.join(root,'data'),'previous');
  isError(request(host,'writeUtf8',{path:'data',text:'😀'.repeat(9)}),'tooLarge');
  assert.equal(fs.readFileSync(path.join(root,'data'),'utf8'),'previous');
  assert.deepEqual(request(host,'writeUtf8',{path:'data',text:'😀'.repeat(8)}),{kind:'unit'});
  fs.writeFileSync(path.join(root,'large'),Buffer.alloc(33));
  isError(request(host,'readUtf8',{path:'large'}),'tooLarge');
 });
 check('invalid UTF-8 and ill-formed host strings refuse',()=>{
  fs.writeFileSync(path.join(root,'invalid'),Buffer.from([0xc0,0xaf]));
  isError(request(host,'readUtf8',{path:'invalid'}),'invalidUtf8');
  isError(request(host,'writeUtf8',{path:'data',text:'\ud800'}),'invalidUtf8');
 });
 check('actual permission refusal preserves previous file',()=>{
  assert.notEqual(process.getuid(),0,'permission test requires the normal unprivileged Linux runner');
  const directory=path.join(root,'protected');fs.mkdirSync(directory);
  const file=path.join(directory,'value');fs.writeFileSync(file,'previous');
  fs.chmodSync(directory,0o500);
  try{
   isError(request(host,'writeUtf8',{path:'protected/value',text:'changed'}),'ioFailure');
   assert.equal(fs.readFileSync(file,'utf8'),'previous');
  }finally{fs.chmodSync(directory,0o700);}
 });
 check('missing file and directory are typed errors',()=>{
  isError(request(host,'readUtf8',{path:'missing'}),'notFound');
  isError(request(host,'readUtf8',{path:'nested'}),'wrongType');
  isError(request(host,'writeUtf8',{path:'nested',text:'x'}),'wrongType');
 });
 check('path traversal absolute empty components and NUL refuse',()=>{
  for(const relative of ['','../escape','nested/../escape','/tmp/escape','./data','nested//x','data/','a\\b','bad\0name']){
   isError(request(host,'readUtf8',{path:relative}),'pathDenied');
   isError(request(host,'writeUtf8',{path:relative,text:'x'}),'pathDenied');
  }
 });
 check('leaf and parent symlinks refuse and preserve outside content',()=>{
  fs.writeFileSync(path.join(work,'outside'),'secret');
  fs.symlinkSync(path.join(work,'outside'),path.join(root,'link'));
  fs.symlinkSync(work,path.join(root,'parent'),'dir');
  for(const relative of ['link','parent/outside']){
   isError(request(host,'readUtf8',{path:relative}),'pathDenied');
   isError(request(host,'writeUtf8',{path:relative,text:'changed'}),'pathDenied');
  }
  assert.equal(fs.readFileSync(path.join(work,'outside'),'utf8'),'secret');
 });
 check('FIFO refuses without blocking',()=>{
  const made=spawnSync('mkfifo',[path.join(root,'fifo')],{encoding:'utf8',timeout:1000});
  assert.equal(made.status,0,made.stderr);
  isError(request(host,'readUtf8',{path:'fifo'}),'wrongType');
  isError(request(host,'writeUtf8',{path:'fifo',text:'x'}),'wrongType');
 });
 check('malformed and extra-field request refuses',()=>{
  for(const value of [null,false,42,[],{}]){
   isError(request(host,'readUtf8',{path:value}),'pathDenied');
   isError(request(host,'writeUtf8',{path:value,text:'x'}),'pathDenied');
   isError(request(host,'writeLine',{text:value}),'protocolError');
   isError(request(host,'writeUtf8',{path:'data',text:value}),'protocolError');
  }
  isError(request(host,'readUtf8',{path:'\ud800'}),'pathDenied');
  for(const source of ['{','null','[]','{"op":"unknown"}','{"op":"readLine","extra":1}'])
   isError(JSON.parse(host.execute(source)),'protocolError');
 });
 check('optional denied capability is a typed error',()=>{
  const denied=createTypedIo({...config,capabilities:[]});
  try{isError(request(denied,'readUtf8',{path:'data'}),'capabilityDenied');}
  finally{denied.close();}
 });
 check('closed-host integration error escapes',()=>{
  const closed=createTypedIo(config);closed.close();
  assert.throws(()=>closed.execute('{"op":"readLine"}'),/PSC1_IO_CLOSED/);
 });
 for(const [name,bytes,limit,expected]of [
  ['invalid line',Buffer.from([0xff,10]),2,'invalidUtf8'],
  ['oversize CR at EOF',Buffer.from('ab\r'),2,'tooLarge'],
  ['oversize line',Buffer.from('abc\n'),2,'tooLarge']]){
  check(name,()=>{
   const file=path.join(work,'line');fs.writeFileSync(file,bytes);const fd=fs.openSync(file,'r');
   const scoped=createTypedIo({...config,inputFd:fd,maxLineBytes:limit});
   try{isError(request(scoped,'readLine'),expected);if(expected==='tooLarge')isError(request(scoped,'readLine'),expected);}
   finally{scoped.close();fs.closeSync(fd);}
  });
 }
 check('no temporary files remain',()=>assert.ok(!fs.readdirSync(root).some(name=>name.startsWith('.psc1-io-'))));
 const receipt={schema:'psc1-typed-io-policy-tests/1',testedCommit:process.env.GITHUB_SHA||null,
  branchHeadCommit:process.env.PSC1_HEAD_SHA||null,platform:process.platform,passed:true,checks};
 fs.mkdirSync('dist/scoped-correctness/typed-io',{recursive:true});
 fs.writeFileSync('dist/scoped-correctness/typed-io/policy.json',JSON.stringify(receipt,null,2)+'\n');
 console.log('PSC1_TYPED_IO_POLICY: '+JSON.stringify(receipt));
}finally{
 host?.close();fs.closeSync(inputFd);fs.closeSync(outputFd);
 fs.rmSync(work,{recursive:true,force:true});
}
