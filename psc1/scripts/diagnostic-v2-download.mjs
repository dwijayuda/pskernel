import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import crypto from 'node:crypto';import {spawnSync} from 'node:child_process';
const repo='dwijayuda/pskernel',root=path.resolve('dist/unified-v2-readback-input');fs.mkdirSync(root,{recursive:true});
const headers={Authorization:'Bearer '+process.env.GITHUB_TOKEN,Accept:'application/vnd.github+json','X-GitHub-Api-Version':'2022-11-28'};
async function api(route){const r=await fetch('https://api.github.com/repos/'+repo+route,{headers});assert.equal(r.status,200,route);return r.json();}
const qualification=await api('/actions/runs/40133622389');
assert.equal(qualification.head_sha,'f707e037b5f470ceee65891e0c735316ba097444');assert.equal(qualification.status,'completed');
const assets=(await api('/actions/runs/40133622389/artifacts?per_page=100')).artifacts;
assert.equal(assets.length,1);assert.equal(assets[0].name,'psc1-unified-selfhost-correctness-1800s-rust-f707e037b5f470ceee65891e0c735316ba097444');
const known=[{id:12576126918,digest:'sha256:09357b2b1c6ab48d1e9b8a7e3327544072cb0d333c7321def06c4e13871ee9fc',run:40133269028}];
const metadata=[];
for(const item of [...known,...assets.map(a=>({id:a.id,digest:a.digest,run:40133622389}))]){
 const a=await api('/actions/artifacts/'+item.id);assert.equal(a.id,item.id);assert.equal(a.workflow_run.id,item.run);assert.equal(a.expired,false);
 if(item.digest)assert.equal(a.digest,item.digest);assert.match(a.digest,/^sha256:[a-f0-9]{64}$/);assert.ok(a.size_in_bytes<=256*1024*1024);
 const response=await fetch('https://api.github.com/repos/'+repo+'/actions/artifacts/'+a.id+'/zip',{headers,redirect:'manual'});
 assert.ok([301,302,303,307].includes(response.status));
 const location=new URL(response.headers.get('location'));assert.equal(location.protocol,'https:');
 assert.ok(location.hostname.endsWith('.blob.core.windows.net')||location.hostname.endsWith('.actions.githubusercontent.com'));
 const zipped=await fetch(location,{redirect:'error'});assert.equal(zipped.status,200);
 const bytes=Buffer.from(await zipped.arrayBuffer());assert.equal('sha256:'+crypto.createHash('sha256').update(bytes).digest('hex'),a.digest);
 const zip=path.join(root,a.id+'.zip'),out=path.join(root,String(a.id));fs.writeFileSync(zip,bytes);
 const python=`import pathlib,zipfile,stat,sys
root=pathlib.Path(sys.argv[2]).resolve();root.mkdir()
with zipfile.ZipFile(sys.argv[1]) as z:
    rows=z.infolist();assert len(rows)<50000
    assert sum(i.file_size for i in rows)<=2*1024*1024*1024
    for i in rows:
        p=pathlib.PurePosixPath(i.filename)
        assert not p.is_absolute() and '..' not in p.parts and '\\\\' not in i.filename
        assert stat.S_IFMT(i.external_attr>>16)!=stat.S_IFLNK
        assert (root/pathlib.Path(*p.parts)).resolve().is_relative_to(root)
    z.extractall(root)
`;
 const run=spawnSync('python3',['-c',python,zip,out],{encoding:'utf8',timeout:120000});assert.equal(run.status,0,run.stderr);fs.unlinkSync(zip);
 metadata.push({id:a.id,name:a.name,digest:a.digest,workflowRun:a.workflow_run,directory:out});
 console.log('PSC1_VERIFIED_ARCHIVE: '+JSON.stringify(metadata.at(-1)));
}
fs.writeFileSync(path.join(root,'archives.json'),JSON.stringify(metadata,null,2)+'\n');
