// Capture canonical host/package inputs; the historical feature guard runs first.
import fs from'node:fs';import path from'node:path';import assert from'node:assert/strict';
import{createHash}from'node:crypto';import{spawnSync}from'node:child_process';
const receipt=JSON.parse(fs.readFileSync('docs/PSC1_CROSS_PLATFORM_QUALIFICATION_2026-10-29.json'));
const sources={},pins=[];
for(const row of receipt.hostSources.pins){
 assert.ok(row.path.startsWith('psc1/'));const file=row.path.slice(5),bytes=fs.readFileSync(file);
 sources[row.path]=bytes.toString('utf8');pins.push({path:row.path,bytes:bytes.length,sha256:createHash('sha256').update(bytes).digest('hex')});
 if(file.endsWith('.mjs')){const r=spawnSync(process.execPath,['--check',file],{encoding:'utf8'});assert.equal(r.status,0,r.stderr);}
}
fs.mkdirSync('dist/platform-host-candidate',{recursive:true});
fs.writeFileSync('dist/platform-host-candidate/sources.json',JSON.stringify(sources,null,2)+'\n');
fs.writeFileSync('dist/platform-host-candidate/pins.json',JSON.stringify({schema:'psc1-platform-host-source-pins/1',
 producerCommit:process.env.GITHUB_SHA,baseCommit:receipt.baseCommit,pins},null,2)+'\n');
console.log('PSC1_PLATFORM_HOST_SOURCE_PINS '+JSON.stringify({producerCommit:process.env.GITHUB_SHA,pins}));
