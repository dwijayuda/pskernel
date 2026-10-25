// Linux host transport only. No compiler semantics or generated wire tool selectors.
import fs from 'node:fs';import path from 'node:path';import os from 'node:os';
import crypto from 'node:crypto';import assert from 'node:assert/strict';
import {spawn} from 'node:child_process';import {fileURLToPath} from 'node:url';
const MAX=128*1024*1024,STREAM=32*1024*1024;
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
export function linuxProcessIdentity(pid){
 if(process.platform!=='linux'||!Number.isSafeInteger(pid)||pid<=1)return null;
 try{const text=fs.readFileSync('/proc/'+pid+'/stat','utf8'),rest=text.slice(text.lastIndexOf(')')+2).trim().split(/\s+/);
  if(['Z','X','x'].includes(rest[0])||!/^[0-9]+$/.test(rest[19]||''))return null;
  return rest[19];
 }catch{return null;}
}
function regular(file,maximum){
 const st=fs.lstatSync(file);assert.ok(st.isFile()&&!st.isSymbolicLink()&&st.size<=maximum);
 return fs.readFileSync(file);
}
export async function guardMain(args){
 assert.equal(process.platform,'linux');assert.equal(args.length,7);
 const [parentText,parentStart,binary,binarySha,input,output,timeoutText]=args;
 const parent=Number(parentText),timeout=Number(timeoutText);
 assert.ok(Number.isSafeInteger(parent)&&parent>1&&/^[0-9]+$/.test(parentStart));
 assert.ok(Number.isSafeInteger(timeout)&&timeout>0&&timeout<=240000);
 assert.ok([binary,input,output].every(path.isAbsolute));assert.match(binarySha,/^[0-9a-f]{64}$/);
 const directory=path.dirname(input),temporaryRoot=fs.realpathSync(os.tmpdir());
 assert.equal(path.dirname(output),directory);assert.equal(path.basename(input),'request.json');assert.equal(path.basename(output),'response.json');
 assert.equal(fs.realpathSync(directory),directory);assert.equal(path.dirname(directory),temporaryRoot);assert.ok(path.basename(directory).startsWith('psc1-rust-request-'));
 assert.ok(fs.lstatSync(directory).isDirectory()&&!fs.lstatSync(directory).isSymbolicLink());assert.equal(fs.existsSync(output),false);
 assert.equal(sha(regular(binary,256*1024*1024)),binarySha);
 const requestSha=sha(regular(input,MAX)),alive=()=>linuxProcessIdentity(parent)===parentStart;
 const cleanupOrphan=()=>{
  if(alive())return;
  try{if(fs.realpathSync(directory)===directory&&path.dirname(directory)===temporaryRoot&&fs.lstatSync(directory).isDirectory()&&!fs.lstatSync(directory).isSymbolicLink())fs.rmSync(directory,{recursive:true});}catch{}
 };
 if(process.ppid!==parent||!alive()){cleanupOrphan();throw Error('PSC1_RUST_PARENT_GONE');}
 const began=Date.now();let child,failure=null,stderrTail='',stdoutBytes=0,stderrBytes=0,closed=false;
 const killGroup=()=>{if(child?.pid&&!closed)try{process.kill(-child.pid,'SIGKILL');}catch(e){if(e.code!=='ESRCH')throw e;}};
 const stop=reason=>{failure||=reason;killGroup();};
 const deadline=setTimeout(()=>stop('deadline'),timeout);
 const owner=setInterval(()=>{if(!alive())stop('parent-exit');},50);
 let result;
 try{
  result=await new Promise(resolve=>{
   child=spawn(binary,[input,output],{detached:true,stdio:['ignore','pipe','pipe'],shell:false});
   child.stdout.on('data',b=>{stdoutBytes+=b.length;if(stdoutBytes>STREAM)stop('stdout-limit');});
   child.stderr.on('data',b=>{stderrBytes+=b.length;stderrTail=(stderrTail+b.toString('utf8')).slice(-6000);if(stderrBytes>STREAM)stop('stderr-limit');});
   child.once('error',e=>{failure||='spawn:'+e.code;});
   // Successful compiler processes cannot leave descendants running.
   child.once('exit',()=>killGroup());
   child.once('close',(status,signal)=>{closed=true;resolve({status,signal});});
  });
 }finally{clearTimeout(deadline);clearInterval(owner);killGroup();cleanupOrphan();}
 if(!alive())return 1;
 const report={protocol:'psc1-rust-host-run/1',binarySha256:binarySha,requestSha256:requestSha,...result,failure,elapsedMs:Date.now()-began,timeoutMs:timeout,stdoutBytes,stderrBytes,stderrTail};
 if(!failure&&result.status===0){
  assert.equal(sha(regular(input,MAX)),requestSha,'PSC1_RUST_REQUEST_CHANGED');
  report.responseSha256=sha(regular(output,MAX));
 }else report.failure||='compiler-exit';
 console.log(JSON.stringify(report));
 return report.failure?1:0;
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)){
 try{process.exitCode=await guardMain(process.argv.slice(2));}
 catch(error){console.error('PSC1_RUST_HOST_GUARD: '+error.message);process.exitCode=1;}
}
