// Test a closed host proposal before canonical adoption. Generated compiler bytes stay unchanged.
import fs from'node:fs';import path from'node:path';import assert from'node:assert/strict';
import{spawnSync}from'node:child_process';import{createRequire}from'node:module';import{createHash}from'node:crypto';
const p=JSON.parse(fs.readFileSync('../.github/psc1/development-candidate.json'));assert.equal(p.schema,'psc1-development-candidate/1');
const require=createRequire(path.resolve('host-tools/package.json')),prettier=require('prettier'),{parse}=require('@babel/parser');
const ast=s=>JSON.parse(JSON.stringify(parse(s,{sourceType:'module'}),(k,v)=>['start','end','loc','extra','comments','leadingComments','trailingComments','innerComments'].includes(k)?undefined:v));
const guarded=new Set(['host-tools/generated-compiler-session.mjs','host-tools/installed-engine-resolver.mjs','npm-cli/compiler-api.mjs']);
const sources={},pins=[];
for(const [file,source]of Object.entries(p.files)){
 assert.ok(file.startsWith('psc1/')&&!file.includes('..'));
 const target=file.slice(5);let text=source;
 if(guarded.has(target)){text=await prettier.format(text,{parser:'babel',singleQuote:true,printWidth:100});assert.deepEqual(ast(text),ast(source));console.log('PSC1_DEVELOPMENT_FORMAT '+JSON.stringify({file,source:text}));}
 fs.mkdirSync(path.dirname(target),{recursive:true});fs.writeFileSync(target,text);
 if(file.endsWith('.mjs')){const r=spawnSync(process.execPath,['--check',target],{encoding:'utf8'});assert.equal(r.status,0,r.stderr);}
 sources[file]=text;pins.push({path:file,bytes:Buffer.byteLength(text),sha256:createHash('sha256').update(text).digest('hex')});
}
const r=spawnSync('git',['diff','--exit-code',p.baseCommit,'--','packages','host','lakefile.lean','lean-toolchain'],{encoding:'utf8'});assert.equal(r.status,0,r.stdout+r.stderr);
fs.mkdirSync('dist/development-candidate',{recursive:true});
fs.writeFileSync('dist/development-candidate/sources.json',JSON.stringify(sources,null,2)+'\n');
fs.writeFileSync('dist/development-candidate/pins.json',JSON.stringify({producerCommit:process.env.GITHUB_SHA,baseCommit:p.baseCommit,pins},null,2)+'\n');
console.log('PSC1_DEVELOPMENT_SOURCE_PINS '+JSON.stringify({producerCommit:process.env.GITHUB_SHA,baseCommit:p.baseCommit,pins}));
