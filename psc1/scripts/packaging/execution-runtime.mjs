// Repack transport/metadata only. Every native/Wasm compiler payload byte is retained.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
function inventory(root, prefix='') {
  return fs.readdirSync(path.join(root,prefix)).sort().flatMap(name=>{
    const relative=prefix?prefix+'/'+name:name,file=path.join(root,relative),s=fs.lstatSync(file);
    assert.ok(!s.isSymbolicLink());
    if(s.isDirectory())return inventory(root,relative);
    assert.ok(s.isFile());const bytes=fs.readFileSync(file);
    return [{path:relative,bytes:bytes.length,sha256:sha(bytes)}];
  });
}
export function refreshExecutionRuntime(root, engine, version) {
  assert.ok(['rust','wasm-core'].includes(engine));
  const before=inventory(root),manifestFile=path.join(root,'BUNDLE_MANIFEST.json');
  const original=fs.readFileSync(manifestFile),manifest=JSON.parse(original);
  assert.equal(manifest.schema,'psc1-compiled-compiler-execution-bundle/1');
  assert.equal(manifest.engine,engine);assert.equal(manifest.publicationAuthority,false);
  for(const row of manifest.files)
    assert.deepEqual(before.find(f=>f.path===row.path),row,'original bundle resource changed');
  const payload=before.filter(row=>row.path.startsWith('payload/'));
  assert.ok(payload.length>0);
  if(engine==='rust')for(const name of ['generated-rust-transport.mjs','runtime-policy.mjs'])
    fs.copyFileSync(path.join('host-tools',name),path.join(root,'runtime',name));
  manifest.version=version;
  manifest.files=inventory(root).filter(row=>row.path.startsWith('payload/')||row.path.startsWith('runtime/'));
  const nextManifest=JSON.stringify(manifest,null,2)+'\n';
  fs.writeFileSync(manifestFile,nextManifest);
  const indexFile=path.join(root,'index.mjs'),index=fs.readFileSync(indexFile,'utf8');
  const oldPin=JSON.stringify(sha(original)),newPin=JSON.stringify(sha(nextManifest));
  assert.equal(index.split(oldPin).length,2,'replace exactly the bundle manifest identity');
  fs.writeFileSync(indexFile,index.replace(oldPin,newPin));
  const metaFile=path.join(root,'package.json'),meta=JSON.parse(fs.readFileSync(metaFile));
  assert.equal(meta.name,manifest.package);meta.version=version;meta.engines={...meta.engines,node:'>=22.23.3'};
  fs.writeFileSync(metaFile,JSON.stringify(meta,null,2)+'\n');
  const after=inventory(root);
  assert.deepEqual(after.filter(row=>row.path.startsWith('payload/')),payload,'compiler payload bytes must be unchanged');
  const permitted=new Set(['BUNDLE_MANIFEST.json','package.json','index.mjs',
    ...(engine==='rust'?['runtime/generated-rust-transport.mjs','runtime/runtime-policy.mjs']:[])]);
  for(const row of before)if(!permitted.has(row.path))
    assert.deepEqual(after.find(f=>f.path===row.path),row,'unrelated bundle resource changed');
  return {files:after,manifestSha256:sha(nextManifest),retainedCompilerPayloadFiles:payload.length,engine,
    executableSha256:manifest.executableSha256,fixedPoint:manifest.fixedPoint,
    compilerSourceClosureDigest:manifest.compilerSourceClosureDigest,
    changedHostFiles:[...permitted],kernelIncluded:false};
}
