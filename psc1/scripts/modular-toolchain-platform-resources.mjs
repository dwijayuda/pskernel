// Build-time acquisition of the already locked TypeScript7 platform consumers.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';

export async function preparePlatformTypeScript({out,distribution,files,write,json,run,sha256}) {
  const lock=JSON.parse(fs.readFileSync('../package-lock.json'));
  const common=distribution.targetConsumers.ts,linux=common.dependencies[0];
  assert.equal(common.package,'typescript');assert.equal(common.version,'7.0.2');
  assert.equal(linux.package,'@typescript/typescript-linux-x64');assert.equal(linux.version,'7.0.2');
  common.platformDependencies={};
  const resources=path.join(out,'typescript-platforms');
  for(const key of ['linux-x64','darwin-x64','darwin-arm64','win32-x64']){
    let descriptor=linux,archive=path.join(out,'target-tarballs',linux.tarball);
    if(key!=='linux-x64'){
      const name='@typescript/typescript-'+key,record=lock.packages['node_modules/'+name];
      assert.equal(record.version,'7.0.2');
      assert.equal(record.resolved,'https://registry.npmjs.org/'+name+'/-/typescript-'+key+'-7.0.2.tgz');
      assert.ok(record.integrity.startsWith('sha512-'));
      const response=await fetch(record.resolved,{signal:AbortSignal.timeout(120000)});
      assert.equal(response.status,200);
      const bytes=Buffer.from(await response.arrayBuffer());assert.ok(bytes.length<=134217728);
      assert.equal('sha512-'+crypto.createHash('sha512').update(bytes).digest('base64'),record.integrity);
      const directory=path.join(out,'typescript-input',key);fs.mkdirSync(directory,{recursive:true});
      archive=path.join(directory,'typescript-'+key+'-7.0.2.tgz');fs.writeFileSync(archive,bytes);
      assert.ok(run('tar',['tzf',archive]).split('\n').filter(Boolean).every(file=>
        file.startsWith('package/')&&!file.includes('\\')&&!file.split('/').includes('..')));
      run('tar',['xzf',archive,'-C',directory]);
      const pkg=path.join(directory,'package'),meta=JSON.parse(fs.readFileSync(path.join(pkg,'package.json')));
      assert.equal(meta.name,name);assert.equal(meta.version,'7.0.2');
      const pins=files(pkg);
      const names=new Set(['tsgo','tsc','tsgo.exe','tsc.exe']);
      const entries=pins.filter(row=>names.has(path.posix.basename(row.path)));
      assert.equal(entries.length,1,'PSC1_TYPESCRIPT_PLATFORM_BINARY:'+key);
      descriptor={package:name,version:'7.0.2',platform:key,entry:entries[0].path,files:pins,
        tarball:path.basename(archive),tarballSha256:sha256(bytes),upstreamIntegrity:record.integrity};
      common.platformDependencies[key]=descriptor;
    }
    const destination=path.join(resources,key);fs.mkdirSync(destination,{recursive:true});
    const selected=[common,descriptor],rows=[];
    for(const item of selected){
      const source=item===common?path.join(out,'target-tarballs',item.tarball):archive;
      const bytes=fs.readFileSync(source);assert.equal(sha256(bytes),item.tarballSha256);
      fs.copyFileSync(source,path.join(destination,item.tarball));
      rows.push({package:item.package,version:item.version,tarball:item.tarball,sha256:item.tarballSha256});
    }
    write(path.join(destination,'resources.json'),json({schema:'psc1-platform-typescript-resources/1',
      testedCommit:process.env.GITHUB_SHA,platform:key,packages:rows}));
  }
  return resources;
}
