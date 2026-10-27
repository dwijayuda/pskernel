// Package inventory and frozen bundle inspection only. No source compiler.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {readQualifiedArtifact,sha256} from './kernel435-qualified-artifact.mjs';
const out=path.resolve('dist/npm-packages');fs.mkdirSync(out,{recursive:true});
const input=JSON.parse(fs.readFileSync('scripts/npm-packages-input.json','utf8'));
const archive=await readQualifiedArtifact(input.root,path.join(out,'qualified-input'));
const candidates=[];
function find(root){for(const n of fs.readdirSync(root)){const p=path.join(root,n);if(fs.statSync(p).isDirectory())find(p);else if(n===input.root.tarball)candidates.push(p);}}
find(archive);assert.equal(candidates.length,1);assert.equal(sha256(fs.readFileSync(candidates[0])),input.root.tarballSha256);
const frozen=path.join(out,'frozen');fs.mkdirSync(frozen);
const result=spawnSync('tar',['xzf',candidates[0],'-C',frozen],{encoding:'utf8',timeout:120000});assert.equal(result.status,0,result.stderr);
const inventory=[];
function files(root,prefix=''){return fs.readdirSync(path.join(root,prefix)).sort().flatMap(n=>{const p=prefix?prefix+'/'+n:n;const s=fs.lstatSync(path.join(root,p));assert.ok(!s.isSymbolicLink());return s.isDirectory()?files(root,p):[{path:p,bytes:s.size,sha256:sha256(fs.readFileSync(path.join(root,p)))}];});}
for(const dir of fs.readdirSync('packages').sort()){
 const root=path.join('packages',dir);if(!fs.statSync(root).isDirectory())continue;
 const p=path.join(root,'package.json'),meta=fs.existsSync(p)?JSON.parse(fs.readFileSync(p,'utf8')):null;
 inventory.push({directory:dir,name:meta?.name??null,version:meta?.version??null,private:meta?.private??false,
  sources:files(root).filter(f=>f.path.startsWith('src/')),dist:files(root).filter(f=>f.path.startsWith('dist/')),
  exports:meta?.exports??null,dependencies:meta?.dependencies??{},metadata:meta});
}
const implementation=path.join(frozen,'package'),distribution=JSON.parse(fs.readFileSync(path.join(implementation,'UNIVERSAL_DISTRIBUTION.json')));
const rootMeta=JSON.parse(fs.readFileSync(path.join(implementation,'package.json')));
const report={schema:'psc1-existing-npm-package-inventory/1',testedCommit:process.env.GITHUB_SHA,
 packages:inventory,count:inventory.length,qualifiedRoot:input.root,rootMetadata:rootMeta,distribution,
 exportedCompilerSymbols:Object.fromEntries(['js','ts'].map(e=>{
  const text=fs.readFileSync(path.join(implementation,'selfhost',e,'module.js'),'utf8');
  return[e,[...text.matchAll(/^export[^\n]+/gm)].map(m=>m[0])];
 })),frozenFiles:files(implementation),
 distinction:'Existing source packages are not independently executing compiler internals; adapters may reuse one checked qualified implementation.'};
fs.writeFileSync(path.join(out,'inventory.json'),JSON.stringify(report,null,2)+'\n');
console.log('PSC1_NPM_INVENTORY '+JSON.stringify({count:report.count,packages:inventory.map(({sources,dist,...r})=>({...r,metadata:undefined,sources:sources.length,dist:dist.length})),root:rootMeta,exports:report.exportedCompilerSymbols}));
