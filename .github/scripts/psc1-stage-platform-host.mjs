// Qualify proposed host changes before adopting them into canonical sources.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import crypto from 'node:crypto';import{spawnSync}from'node:child_process';import{createRequire}from'node:module';
const proposal=JSON.parse(fs.readFileSync('../.github/psc1/platform-host-candidate.json'));
assert.equal(proposal.schema,'psc1-platform-host-candidate/1');
assert.equal(proposal.baseCommit,'2c278ab9a47c24ef8635f99b41629fc79fd82699');
const expected=['host-tools/runtime-policy.mjs','host-tools/transactional-publication.mjs',
 'host-tools/installed-engine-resolver.mjs','npm-cli/compiler-api.mjs','npm-cli/cli-project.mjs',
 'npm-cli/proofscript-cli.mjs','npm-cli/cli-watch.mjs','npm-cli/universal.d.ts',
 'scripts/modular-toolchain-platform-resources.mjs','scripts/modular-toolchain-package.mjs',
 'scripts/modular-toolchain-input.json'].map(file=>'psc1/'+file).sort();
assert.deepEqual(Object.keys(proposal.files).sort(),expected);
const untouched=spawnSync('git',['diff','--exit-code',proposal.baseCommit,'HEAD','--',
 'packages','host','host-tools','npm-cli','lakefile.lean','lean-toolchain'],{encoding:'utf8'});
assert.equal(untouched.status,0,untouched.stdout+untouched.stderr);
const require=createRequire(path.resolve('host-tools/package.json')),prettier=require('prettier'),{parse}=require('@babel/parser');
assert.equal(require('prettier/package.json').version,'3.6.2');
const ignored=new Set(['start','end','loc','extra','comments','leadingComments','trailingComments','innerComments']);
const ast=source=>JSON.parse(JSON.stringify(parse(source,{sourceType:'module'}),(key,value)=>ignored.has(key)?undefined:value));
const formatted=new Set(['psc1/npm-cli/compiler-api.mjs','psc1/host-tools/installed-engine-resolver.mjs']);
const sources={},pins=[];
for(const [file,original]of Object.entries(proposal.files)){
 let source=original;
 if(formatted.has(file)){
  source=await prettier.format(original,{parser:'babel',singleQuote:true,printWidth:100});
  assert.deepEqual(ast(source),ast(original));
  console.log('PSC1_PLATFORM_FORMATTED_SOURCE '+JSON.stringify({file,source}));
 }
 const target=file.slice('psc1/'.length);fs.mkdirSync(path.dirname(target),{recursive:true});fs.writeFileSync(target,source);
 sources[file]=source;pins.push({path:file,bytes:Buffer.byteLength(source),sha256:crypto.createHash('sha256').update(source).digest('hex')});
 if(file.endsWith('.mjs')){
  const checked=spawnSync(process.execPath,['--check',target],{encoding:'utf8'});
  assert.equal(checked.status,0,checked.stderr);
 }
}
fs.mkdirSync('dist/platform-host-candidate',{recursive:true});
fs.writeFileSync('dist/platform-host-candidate/sources.json',JSON.stringify(sources,null,2)+'\n');
fs.writeFileSync('dist/platform-host-candidate/pins.json',JSON.stringify({schema:'psc1-platform-host-source-pins/1',
 producerCommit:process.env.GITHUB_SHA,baseCommit:proposal.baseCommit,pins},null,2)+'\n');
console.log('PSC1_PLATFORM_HOST_SOURCE_PINS '+JSON.stringify({producerCommit:process.env.GITHUB_SHA,pins}));
