// Actual current owned manifests; archived records/dependencies retain their own data.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {projectOwnedName} from '../../scripts/packaging/license.mjs';
const license=fs.readFileSync('LICENSE','utf8');
assert.equal(fs.readFileSync('../LICENSE','utf8'),license);
assert.match(license,/Apache License/);assert.match(license,/Version 2\.0, January 2004/);
const paths=['../package.json','package.json','npm-cli/package.json','host-tools/package.json','host/package.json','stdlib/package.json'];
for(const base of ['packages','../packages'])for(const name of fs.readdirSync(base)){
  const file=path.join(base,name,'package.json');if(fs.existsSync(file))paths.push(file);
}
const cases=[];
for(const file of paths){
  const meta=JSON.parse(fs.readFileSync(file));if(!projectOwnedName(meta.name))continue;
  assert.equal(meta.license,'Apache-2.0',file);
  const dir=path.dirname(file);
  const hasLicense=['LICENSE','APACHE-2.0.txt'].some(name=>fs.existsSync(path.join(dir,name))&&fs.readFileSync(path.join(dir,name),'utf8')===license);
  assert.ok(hasLicense,'missing project license: '+file);
  assert.match(fs.readFileSync(path.join(dir,'NOTICE'),'utf8'),/ProofScript-owned/);
  cases.push({file,package:meta.name,license:meta.license});
}
assert.equal(cases.length,50,'all fifty inspected active owned manifests');
fs.mkdirSync('dist/cli',{recursive:true});
fs.writeFileSync('dist/cli/license-source.json',JSON.stringify({status:'passed',testedCommit:process.env.GITHUB_SHA,cases},null,2)+'\n');
console.log('PSC1_SOURCE_LICENSE '+JSON.stringify({status:'passed',manifests:cases.length}));
