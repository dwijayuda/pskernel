// Linux CI artifact transport. Exact job/commit/ZIP identities are required.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import crypto from 'node:crypto';import {spawnSync} from 'node:child_process';
export const sha256=b=>crypto.createHash('sha256').update(b).digest('hex');
export async function readQualifiedArtifact(input,destination){
 assert.ok(input&&Number.isSafeInteger(input.run)&&Number.isSafeInteger(input.job)&&Number.isSafeInteger(input.artifact));assert.match(input.commit,/^[0-9a-f]{40}$/);assert.match(input.zipSha256,/^[0-9a-f]{64}$/);
 const token=process.env.GH_TOKEN;assert.ok(token,'read-only Actions token required');const api=async p=>{const r=await fetch('https://api.github.com/repos/dwijayuda/pskernel/'+p,{headers:{Authorization:'Bearer '+token,'X-GitHub-Api-Version':'2022-11-28'}});assert.ok(r.ok,'GitHub request failed '+r.status+' '+p);return r;};
 const jobs=await(await api('actions/runs/'+input.run+'/jobs?per_page=100')).json();assert.equal(jobs.jobs.find(j=>j.id===input.job)?.conclusion,'success');
 const artifact=await(await api('actions/artifacts/'+input.artifact)).json();assert.equal(artifact.expired,false);assert.equal(artifact.workflow_run.id,input.run);assert.equal(artifact.workflow_run.head_sha,input.commit);assert.equal(artifact.digest,'sha256:'+input.zipSha256);
 const bytes=Buffer.from(await(await api('actions/artifacts/'+input.artifact+'/zip')).arrayBuffer());assert.ok(bytes.length<512*1024*1024);assert.equal(sha256(bytes),input.zipSha256);
 destination=path.resolve(destination);assert.ok(destination.startsWith(path.resolve('dist')+path.sep));fs.mkdirSync(destination,{recursive:true});assert.equal(fs.readdirSync(destination).length,0,'artifact destination must be fresh');const zip=path.join(destination,'input.zip');fs.writeFileSync(zip,bytes);
 const py="import zipfile,sys,pathlib\nroot=pathlib.Path(sys.argv[2]).resolve()\nwith zipfile.ZipFile(sys.argv[1]) as z:\n assert sum(i.file_size for i in z.infolist())<2147483648\n for i in z.infolist():\n  p=(root/i.filename).resolve()\n  assert p.is_relative_to(root) and not ((i.external_attr>>16)&0o170000)==0o120000\n z.extractall(root)\n";
 const r=spawnSync('python3',['-c',py,zip,destination],{encoding:'utf8',timeout:120000,maxBuffer:16*1024*1024});assert.equal(r.error,undefined);assert.equal(r.status,0,r.stderr);return destination;
}
