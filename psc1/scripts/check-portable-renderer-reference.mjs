// Exact original native bodies; reference is excluded from portable source capture.
import assert from 'node:assert/strict';import fs from 'node:fs';import {spawnSync} from 'node:child_process';
const ref=fs.readFileSync('host/src/Ps/Host/M5RendererReference.lean','utf8');
for(const backend of ['Js','Ts']){
 const file='psc1/packages/backend-'+backend.toLowerCase()+'/src/Ps/Backend'+backend+'/ModuleFiles.lean';
 const result=spawnSync('git',['show','d53b43c271c65635b07a6ffa78fb6b08a5fa55de:'+file],{encoding:'utf8'});
 assert.equal(result.status,0,result.stderr);
 const original=result.stdout.slice(result.stdout.indexOf('namespace Ps.Internal.Modular'+backend));
 assert.ok(ref.includes(original.replaceAll('Ps.Internal.Modular'+backend,'Ps.Host.M5Reference'+backend)));
}
console.log('PSC1_IMMUTABLE_RENDERER_REFERENCE exact pre-M5 bodies and namespaces only');

