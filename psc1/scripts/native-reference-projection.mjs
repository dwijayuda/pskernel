// CI reference spelling only. A projected candidate still requires fresh graph and native checks.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';

const schema='psc1-native-reference-projection/1';
const limit=32*1024*1024,sourceLimit=1024*1024;
const hash=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
const decode=bytes=>new TextDecoder('utf-8',{fatal:true,ignoreBOM:true}).decode(bytes);
const json=value=>JSON.stringify(value,null,2)+'\n';
function fileBytes(file,max){
 const stat=fs.lstatSync(file);assert.ok(stat.isFile()&&!stat.isSymbolicLink()&&stat.size<=max);
 return fs.readFileSync(file);
}
export function validateNativeProjection(sources,response){
 assert.equal(response.schema,schema);assert.equal(response.status,'candidate-only');
 assert.equal(response.sourceGrammar,'lean');assert.equal(response.inputKind,'ordinary-source-printer-output');
 for(const key of ['admissionAuthority','sourceFilesWritten','formalSourcePreservationProof'])assert.equal(response[key],false);
 assert.ok(Array.isArray(response.modules));assert.equal(response.modules.length,sources.length);
 assert.equal(new Set(response.modules.map(row=>row.module)).size,sources.length);
 const modules=new Map(),observations=[];
 for(let i=0;i<sources.length;i++){
  const source=sources[i],row=response.modules[i],input=Buffer.from(source.bytes);
  assert.equal(row.module,source.module);assert.equal(row.inputBytes,input.length);
  assert.equal(row.reparsed,true);assert.equal(row.idempotent,true);
  assert.equal(typeof row.text,'string');assert.ok(Array.isArray(row.constructorDots)&&row.constructorDots.length<=262144);
  const parts=[];let cursor=0;
  for(const dot of row.constructorDots){
   assert.ok(Number.isSafeInteger(dot.byteOffset)&&Number.isSafeInteger(dot.nameStopByteOffset));
   assert.ok(dot.byteOffset>=cursor&&dot.nameStopByteOffset>dot.byteOffset&&dot.nameStopByteOffset<=input.length);
   assert.equal(typeof dot.name,'string');assert.ok(dot.name.length>0&&!dot.name.includes('.'));
   const name=Buffer.from(dot.name);
   assert.equal(dot.nameStopByteOffset-dot.byteOffset,name.length);
   assert.ok(input.subarray(dot.byteOffset,dot.nameStopByteOffset).equals(name),'Exact parsed name bytes required');
   assert.notEqual(input[dot.byteOffset-1],46,'An already dotted constructor cannot gain another dot');
   parts.push(input.subarray(cursor,dot.byteOffset),Buffer.from('.'),input.subarray(dot.byteOffset,dot.nameStopByteOffset));
   cursor=dot.nameStopByteOffset;
  }
  parts.push(input.subarray(cursor));
  const exact=Buffer.concat(parts),output=Buffer.from(row.text);
  assert.ok(output.length<=sourceLimit&&output.length===input.length+row.constructorDots.length);
  assert.equal(row.outputBytes,output.length);assert.ok(exact.equals(output),'Only reported literal dots may change source bytes');
  assert.equal(decode(output),row.text);modules.set(row.module,output);
  observations.push({module:row.module,inputBytes:input.length,inputSha256:hash(input),
   outputBytes:output.length,outputSha256:hash(output),constructorDots:row.constructorDots,
   reparsed:true,idempotent:true,allOriginalBytesPreserved:true});
 }
 return {modules,observations};
}
export function projectNativeReferences({root,out,label,sources}){
 assert.match(label,/^[a-z][a-z0-9-]{0,63}$/);
 assert.ok(Array.isArray(sources)&&sources.length>0&&sources.length<=256);
 assert.equal(new Set(sources.map(row=>row.module)).size,sources.length);
 for(const row of sources){
  assert.equal(typeof row.module,'string');assert.ok(row.module.length>0&&Buffer.byteLength(row.module)<=1024);
  assert.ok(row.bytes instanceof Uint8Array&&row.bytes.byteLength<=sourceLimit);
  assert.ok(Buffer.from(decode(row.bytes)).equals(Buffer.from(row.bytes)));
 }
 const script=path.join(root,'scripts/NativeReferenceProjection.lean');
 const scriptBytes=fileBytes(script,sourceLimit);
 const directory=path.join(out,'native-reference-projection');fs.mkdirSync(directory,{recursive:true});
 const work=fs.mkdtempSync(path.join(directory,label+'-'));
 const request=Buffer.from(JSON.stringify([schema,sources.map(row=>[row.module,decode(row.bytes)])]));
 assert.ok(request.length<=limit);
 const input=path.join(work,'request.json'),output=path.join(work,'response.json');
 fs.writeFileSync(input,request,{flag:'wx',mode:0o600});
 const started=Date.now();
 const args=['--as=4294967296','--stack=8388608','--','lake','env','lean','--run',script,input,output];
 const result=spawnSync('prlimit',args,{cwd:root,encoding:'utf8',timeout:240000,maxBuffer:limit,
  env:{...process.env,LEAN_MAIN_USE_THREAD:'0',LEAN_NUM_THREADS:'0',LEAN_STACK_SIZE_KB:'8192'}});
 fs.writeFileSync(path.join(work,'process.json'),json({command:'prlimit',args,status:result.status,
  signal:result.signal,error:result.error?String(result.error):null,elapsedMs:Date.now()-started,
  timeoutMs:240000,maxBuffer:limit,stdout:String(result.stdout??''),stderr:String(result.stderr??'')}));
 assert.equal(result.error,undefined);assert.equal(result.status,0,String(result.stdout)+'\n'+String(result.stderr));
 assert.equal(result.signal,null);
 assert.ok(fileBytes(input,limit).equals(request));assert.ok(fileBytes(script,sourceLimit).equals(scriptBytes));
 const responseBytes=fileBytes(output,limit),response=JSON.parse(decode(responseBytes));
 const checked=validateNativeProjection(sources,response);
 const evidence={schema,status:'candidate-only',script:'scripts/NativeReferenceProjection.lean',
  scriptSha256:hash(scriptBytes),requestSha256:hash(request),responseSha256:hash(responseBytes),
  elapsedMs:Date.now()-started,modules:checked.observations,
  admissionAuthority:false,sourceFilesWritten:false,formalSourcePreservationProof:false};
 fs.writeFileSync(path.join(work,'projection.json'),json(evidence));
 return {...checked,evidence,response};
}
