// CI-only content-addressed Git objects. This helper never creates a commit or moves a ref.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';

export async function uploadPreparedSourceTree({entries,baseTree,preparedCommit,out}) {
 const json=value=>JSON.stringify(value,null,2)+'\n';
 const put=(name,value)=>fs.writeFileSync(path.join(out,name),json(value));
 const upload={schema:'psc1-canonical-object-upload/1',status:'not-requested',
  preparedCommit,baseTree,startedAt:new Date().toISOString(),
  requestBytesLimit:512*1024,maxAttempts:3,deadlineMs:10*60*1000,
  attempts:[],batches:[],commitsCreated:false,refsChanged:false};
 const save=()=>put('object-upload.json',upload);
 if(process.env.PSC1_CREATE_SOURCE_TREE!=='1'){save();return {treeSha:null,upload};}
 assert.equal(process.env.GITHUB_REPOSITORY,'dwijayuda/pskernel');
 assert.ok(process.env.GH_TOKEN,'GitHub Actions token required');
 assert.match(baseTree,/^[0-9a-f]{40}$/);assert.match(preparedCommit,/^[0-9a-f]{40}$/);
 assert.ok(Array.isArray(entries)&&entries.length>0&&entries.length<=1024);
 assert.equal(new Set(entries.map(entry=>entry.path)).size,entries.length);
 for(const entry of entries){
  assert.ok(entry.path.startsWith('psc1/')&&!entry.path.includes('\\')&&
   !entry.path.includes('\0')&&!entry.path.split('/').some(part=>!part||part==='.'||part==='..'));
  assert.equal(entry.mode,'100644');assert.equal(entry.type,'blob');
  assert.equal(typeof entry.content,'string');assert.match(entry.sha,/^[0-9a-f]{40}$/);
 }
 const pause=ms=>new Promise(resolve=>setTimeout(resolve,ms));
 const deadline=Date.now()+upload.deadlineMs;
 let lastWriteAt=0;
 async function request(method,endpoint,payload){
  assert.ok(/^(?:\/git\/trees|\/git\/trees\/[0-9a-f]{40}(?:\?recursive=1)?)$/.test(endpoint));
  assert.ok(method==='GET'||method==='POST');
  const body=payload===undefined?undefined:JSON.stringify(payload);
  const requestBytes=body===undefined?0:Buffer.byteLength(body);
  assert.ok(requestBytes<=upload.requestBytesLimit,'Bounded Git request exceeded: '+endpoint);
  for(let attempt=1;attempt<=upload.maxAttempts;attempt++){
   if(method==='POST'){
    const pacing=Math.max(0,lastWriteAt+1000-Date.now());
    if(pacing)await pause(pacing);
    lastWriteAt=Date.now();
   }
   const remainingMs=deadline-Date.now();assert.ok(remainingMs>0,'Git object upload deadline exhausted');
   const observed={method,endpoint,attempt,requestBytes,startedAt:new Date().toISOString()};
   try{
    const response=await fetch('https://api.github.com/repos/dwijayuda/pskernel'+endpoint,{
     method,headers:{Authorization:'Bearer '+process.env.GH_TOKEN,
      Accept:'application/vnd.github+json','Content-Type':'application/json','X-GitHub-Api-Version':'2022-11-28'},
     body,signal:AbortSignal.timeout(Math.min(60000,remainingMs))});
    const raw=await response.text();
    assert.ok(Buffer.byteLength(raw)<=8*1024*1024,'Git object response exceeded limit');
    let value;try{value=JSON.parse(raw);}catch{value={message:raw.slice(0,2000)};}
    observed.status=response.status;
    if(!response.ok){
     const error=new Error('Git object request HTTP '+response.status+': '+String(value?.message??'no message').slice(0,2000));
     const retryAfter=Number(response.headers.get('retry-after'));
     error.retryAfterMs=Number.isFinite(retryAfter)&&retryAfter>0?retryAfter*1000:0;
     error.retryable=[408,429,500,502,503,504].includes(response.status)||
      (response.status===403&&error.retryAfterMs>0);
     throw error;
    }
    assert.equal(response.status,method==='POST'?201:200);
    observed.finishedAt=new Date().toISOString();upload.attempts.push(observed);save();
    return value;
   }catch(error){
    const code=String(error.cause?.code??error.code??error.name??'unknown');
    observed.errorCode=code;observed.message=String(error.message).slice(0,2000);
    observed.finishedAt=new Date().toISOString();upload.attempts.push(observed);save();
    const transient=error.retryable===true||
     ['EPIPE','ECONNRESET','ETIMEDOUT','UND_ERR_SOCKET','UND_ERR_CONNECT_TIMEOUT',
      'UND_ERR_HEADERS_TIMEOUT','UND_ERR_BODY_TIMEOUT','TimeoutError','AbortError'].includes(code);
    if(!transient||attempt===upload.maxAttempts)throw error;
    const delay=Math.max(error.retryAfterMs??0,1000*(2**(attempt-1)));
    assert.ok(delay<=60000&&Date.now()+delay<deadline,'Git retry delay exceeds bounded upload policy');
    await pause(delay);
   }
  }
  throw new Error('Git object request exhausted retries');
 }
 function verifyBlobs(tree,expected){
  assert.equal(tree.truncated,false,'Git tree response must be complete');
  const blobs=new Map(tree.tree.filter(row=>row.type==='blob').map(row=>[row.path,row]));
  assert.equal(blobs.size,expected.length,'Temporary tree must contain exactly its prepared blobs');
  for(const entry of expected){
   const actual=blobs.get(entry.path);assert.ok(actual,'Git blob missing: '+entry.path);
   assert.equal(actual.mode,entry.mode,'Git mode changed: '+entry.path);
   assert.equal(actual.sha,entry.sha,'Git content address changed: '+entry.path);
  }
 }
 upload.status='uploading';save();
 try{
  const batches=[];let batch=[];
  for(const entry of entries){
   const inline={path:entry.path,mode:entry.mode,type:entry.type,content:entry.content};
   const candidate=[...batch,inline];
   if(Buffer.byteLength(JSON.stringify({tree:candidate}))>upload.requestBytesLimit){
    assert.ok(batch.length,'One prepared entry exceeds bounded Git upload size: '+entry.path);
    batches.push(batch);batch=[inline];
    assert.ok(Buffer.byteLength(JSON.stringify({tree:batch}))<=upload.requestBytesLimit,
     'One prepared entry exceeds bounded Git upload size: '+entry.path);
   }else batch=candidate;
  }
  if(batch.length)batches.push(batch);
  upload.batchCount=batches.length;save();
  const expectedByPath=new Map(entries.map(entry=>[entry.path,entry]));
  for(let index=0;index<batches.length;index++){
   const created=await request('POST','/git/trees',{tree:batches[index]});
   assert.match(created.sha,/^[0-9a-f]{40}$/);
   const verified=await request('GET','/git/trees/'+created.sha+'?recursive=1');
   verifyBlobs(verified,batches[index].map(entry=>expectedByPath.get(entry.path)));
   upload.batches.push({index,treeSha:created.sha,entries:batches[index].length,contentAddressesVerified:true});
   save();console.log('PSC1_CANONICAL_OBJECT_BATCH: '+JSON.stringify(upload.batches.at(-1)));
  }
  const finalTree=await request('POST','/git/trees',{base_tree:baseTree,
   tree:entries.map(({path,mode,type,sha})=>({path,mode,type,sha}))});
  assert.match(finalTree.sha,/^[0-9a-f]{40}$/);
  const rootTree=await request('GET','/git/trees/'+finalTree.sha);
  const pscTree=rootTree.tree.find(entry=>entry.path==='psc1'&&entry.type==='tree');
  assert.ok(pscTree,'Final tree must contain the PSC1 subtree');assert.match(pscTree.sha,/^[0-9a-f]{40}$/);
  const verified=await request('GET','/git/trees/'+pscTree.sha+'?recursive=1');
  assert.equal(verified.truncated,false,'Final PSC1 subtree verification must be complete');
  const actualByPath=new Map(verified.tree.filter(entry=>entry.type==='blob').map(entry=>['psc1/'+entry.path,entry]));
  for(const entry of entries){
   const actual=actualByPath.get(entry.path);assert.ok(actual,'Final Git blob missing: '+entry.path);
   assert.equal(actual.sha,entry.sha,'Final Git blob changed: '+entry.path);
   assert.equal(actual.mode,entry.mode,'Final Git mode changed: '+entry.path);
  }
  upload.status='complete';upload.finalTreeSha=finalTree.sha;upload.finalPreparedBlobsVerified=entries.length;
  upload.finishedAt=new Date().toISOString();save();
  return {treeSha:finalTree.sha,upload};
 }catch(error){
  upload.status='failed';upload.finishedAt=new Date().toISOString();
  upload.failure={message:String(error.message).slice(0,4000),
   code:String(error.cause?.code??error.code??error.name??'unknown')};
  save();throw error;
 }
}
