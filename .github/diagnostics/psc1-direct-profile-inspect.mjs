// Read-only artifact analysis. No native or generated compiler execution.
import assert from 'node:assert/strict';import fs from 'node:fs';import path from 'node:path';
import {sha,verifyArtifact} from '../../psc1/host-tools/generated-target-tools.mjs';
function walk(root){return fs.readdirSync(root,{withFileTypes:true}).flatMap(e=>{const f=path.join(root,e.name);assert.equal(e.isSymbolicLink(),false);return e.isDirectory()?walk(f):[f];});}
const profileFiles=walk('input/profile'),originalFiles=walk('input/original');
const profile=profileFiles.find(f=>f.endsWith('v8.log.txt'));assert.ok(profile);
const text=fs.readFileSync(profile,'utf8'),lines=text.split('\n'),sections={};
for(const [key,label,count]of [['summary',' [Summary]:',30],['cpp',' [C++]:',65],['bottomUp',' [Bottom up (heavy) profile]:',160]]){
 let index=lines.findIndex(l=>l===label);if(index<0)index=lines.findIndex(l=>l.includes(label.trim().replace(':','')));
 sections[key]=index<0?[]:lines.slice(index,index+count);
 console.log('PSC1_RETAINED_CPU_'+key+':\n'+sections[key].join('\n'));
}
const reportFile=originalFiles.find(f=>path.basename(f)==='qualification.json'),report=JSON.parse(fs.readFileSync(reportFile));
const dir=path.dirname(reportFile),manifest=path.join(dir,'G1-service/artifact.json');
verifyArtifact(manifest,'7cc7bc0b157d0b7ef400a9b1f8541a7b2d7875472d9ad9e0a007e07e609e1529');
const source=fs.readFileSync(path.join(dir,'G1-service/module.js'),'utf8');assert.equal(sha(source),'f6ea612d97032bf94e348820b9233be21b61a71d61d0326dcf5cfe43aca430ae');
const sourceLines=source.split('\n'),selected=[];
for(const name of ['psJsonStringCharsAccWithFuel$worker','psJsonParseStringChars$worker','psExprInstantiateAtWorker$worker','psMetaExprHasAssignedVarScan','psStringEqFromWithFuel$worker']){
 const index=sourceLines.findIndex(l=>l.includes('function* __ps$impl$'+name+'(')||l.includes('function '+name+'('));
 if(index>=0){const line=sourceLines[index];selected.push({name,line:index+1,generatorLets:(line.match(/yield\* \(function\*/g)||[]).length,text:line.slice(0,3500)});}
}
const row={schema:'psc1-retained-direct-profile-inspection/1',testedCommit:process.env.GITHUB_SHA,
 sourceSha256:sha(source),profileSha256:sha(text),sections,selected,
 sourceShape:{bytes:Buffer.byteLength(source),lines:sourceLines.length,generators:(source.match(/function\*/g)||[]).length,
 generatorLets:(source.match(/yield\* \(function\*/g)||[]).length,tailStateLoops:(source.match(/while \(true\) \{ const \[/g)||[]).length},
 qualification:false,compilerExecution:false};
fs.mkdirSync('profile-inspection',{recursive:true});fs.writeFileSync('profile-inspection/receipt.json',JSON.stringify(row,null,2)+'\n');
console.log('PSC1_RETAINED_SOURCE_SHAPE: '+JSON.stringify({sourceShape:row.sourceShape,selected:row.selected}));
