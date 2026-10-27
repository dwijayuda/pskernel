// Inspect the real installable tarballs, including standalone and bundled kernel grants.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {projectOwnedName} from '../../scripts/packaging/license.mjs';
const out='dist/slim-universal',r=JSON.parse(fs.readFileSync(path.join(out,'package-receipt.json')));
const license=fs.readFileSync('LICENSE','utf8'),hash=b=>crypto.createHash('sha256').update(b).digest('hex');
const tar=(file,args)=>{const v=spawnSync('tar',[...args,file],{encoding:'utf8',timeout:10000,maxBuffer:1024*1024});assert.equal(v.error,undefined);assert.equal(v.status,0,v.stderr);return v.stdout;};
function member(file,name){const v=spawnSync('tar',['xOf',file,'package/'+name],{encoding:'utf8',timeout:10000,maxBuffer:1024*1024});assert.equal(v.status,0,v.stderr);return v.stdout;}
const cases=[];
for(const row of r.licensing.owned){
  const file=path.join(out,'tarballs',row.tarball);assert.equal(hash(fs.readFileSync(file)),row.sha256);
  const meta=JSON.parse(member(file,'package.json'));assert.ok(projectOwnedName(meta.name));
  assert.equal(meta.license,'Apache-2.0');assert.equal(meta.name,row.package);
  const entries=tar(file,['tzf']).split('\n');
  const canonical=entries.includes('package/APACHE-2.0.txt')?'APACHE-2.0.txt':'LICENSE';
  assert.equal(member(file,canonical),license);
  assert.match(member(file,'NOTICE'),/ProofScript-owned/);
  cases.push({package:meta.name,version:meta.version,sha256:row.sha256,license:meta.license});
}
assert.equal(cases.length,9,'root, two kernels, two engines, Rust consumer and three dispatch packages');
for(const row of r.licensing.retainedThirdParty)
  assert.equal(hash(fs.readFileSync(path.join(out,'tarballs',row.tarball))),row.sha256,'third-party tarball changed');
const result={schema:'psc1-installed-license/1',testedCommit:process.env.GITHUB_SHA,status:'passed',
  rootSha256:r.sha256,cases,retainedThirdParty:r.licensing.retainedThirdParty,
  executablePolicy:r.licensing.executablePolicy};
fs.writeFileSync('dist/cli/license.json',JSON.stringify(result,null,2)+'\n');
console.log('PSC1_INSTALLED_LICENSE '+JSON.stringify(result));
