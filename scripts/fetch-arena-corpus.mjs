import {createWriteStream,existsSync,mkdirSync,readFileSync,rmSync} from 'node:fs';
import {spawnSync} from 'node:child_process';
import {join,resolve} from 'node:path';

const out=resolve(process.argv[2]??'.arena-tests');
const lock=JSON.parse(readFileSync('ARENA_LOCK.json','utf8'));
const cache=resolve('.arena-cache');
mkdirSync(cache,{recursive:true});
const archive=join(cache,'lean-arena-tests.tar.gz');
const artifactZip=join(cache,'artifact.zip');

async function download(url,file,headers={}){
  const r=await fetch(url,{headers,redirect:'follow'});
  if(!r.ok)throw new Error(`download failed ${r.status} ${url}`);
  const buf=Buffer.from(await r.arrayBuffer());
  await new Promise((res,rej)=>{const w=createWriteStream(file);w.on('error',rej);w.on('finish',res);w.end(buf);});
}

let got=false;
const token=process.env.GITHUB_TOKEN||process.env.GH_TOKEN;
if(token){
  try{
    const url=`https://api.github.com/repos/${lock.source.repository}/actions/artifacts/${lock.source.artifactId}/zip`;
    await download(url,artifactZip,{Authorization:`Bearer ${token}`,Accept:'application/vnd.github+json','X-GitHub-Api-Version':'2022-11-28'});
    const tmp=join(cache,'artifact');
    rmSync(tmp,{recursive:true,force:true});mkdirSync(tmp,{recursive:true});
    const uz=spawnSync('unzip',['-q',artifactZip,'-d',tmp],{stdio:'inherit'});
    if(uz.status!==0)throw new Error('unzip artifact failed');
    const candidate=join(tmp,'lean-arena-tests.tar.gz');
    if(!existsSync(candidate))throw new Error('artifact missing lean-arena-tests.tar.gz');
    const cp=spawnSync(process.execPath,['-e',`require('fs').copyFileSync(${JSON.stringify(candidate)},${JSON.stringify(archive)})`],{stdio:'inherit'});
    if(cp.status!==0)throw new Error('copy artifact tarball failed');
    got=true;
  }catch(e){console.error('[arena-fetch] exact artifact unavailable, trying pinned-content site fallback:',e instanceof Error?e.message:String(e));}
}
if(!got)await download(lock.source.siteUrl,archive);
rmSync(out,{recursive:true,force:true});mkdirSync(out,{recursive:true});
const t=spawnSync('tar',['-xzf',archive,'-C',out],{stdio:'inherit'});
if(t.status!==0)throw new Error('tar extraction failed');
const v=spawnSync(process.execPath,['scripts/verify-arena-corpus.mjs',out],{stdio:'inherit'});
if(v.status!==0)throw new Error('downloaded Arena corpus does not match ARENA_LOCK.json');
console.log(JSON.stringify({ok:true,out,source:got?'github-actions-artifact':'arena-site-content-match'},null,2));
