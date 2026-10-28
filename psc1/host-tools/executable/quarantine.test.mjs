// Host quarantine tests: fixed filenames choose format, never guest authority.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import {canonicalJson,quarantineCandidate} from './quarantine.mjs';
const temporary=fs.mkdtempSync(path.join(os.tmpdir(),'psc1-modular-wire-'));
try{
 const capture={requestId:'wire-test',sourceClosureDigest:'source-test'};
 const emission={sourceClosureDigest:'source-test',units:[{},{}]};
 const metadata=['original-ir.json','specialized-ir.json','fused-ir.json','admissions.json','capture.json','modules.json'];
 const files=metadata.map(name=>[name,'json',name==='capture.json'?capture:name==='modules.json'?emission:
  ['wire', '𐐀é\\\"\n', ['9007199254740993',true,null]],name==='admissions.json'?'\n':'']);
 files.push(['js-runtime.mjs','text','// runtime\n','']);
 for(let unit=0;unit<2;unit++)for(const [variant,extension]of [['js','.mjs'],['js','.d.mts'],['ts','.mts']])
  files.push([variant+'/unit-'+unit+extension,'text','// actual text\n','']);
 const candidate={protocol:'psc1-modular-build/1',status:'candidate',candidateOnly:true,
  admission:'not-run',...capture,files};
 const directory=path.join(temporary,'valid');
 const receipt=quarantineCandidate(JSON.stringify(candidate),directory);
 assert.equal(receipt.files,13);
 assert.equal(fs.readFileSync(path.join(directory,'admissions.json'),'utf8'),
  canonicalJson(files[3][2])+'\n');
 assert.equal(canonicalJson({z:1,a:{b:true,a:'😀'}}),'{"a":{"a":"😀","b":true},"z":1}');
 assert.throws(()=>canonicalJson(9007199254740992));
 assert.throws(()=>canonicalJson(1.5));
 const mutations=[
  x=>x.candidateOnly=false,x=>x.admission='accepted',x=>x.status='accepted',
  x=>x.files[0][0]='../escape',x=>x.files[0][1]='text',x=>x.files[0][3]='\n',
  x=>x.files[3][3]='',x=>x.files[6][1]='json',x=>x.files.push(x.files[0]),
  x=>x.files[0].pop(),x=>x.files[0][2]=9007199254740992
 ];
 for(const [index,mutate]of mutations.entries()){
  const value=structuredClone(candidate);mutate(value);
  const rejected=path.join(temporary,'refused-'+index);
  assert.throws(()=>quarantineCandidate(JSON.stringify(value),rejected));
  assert.ok(!fs.existsSync(rejected),'invalid transport must not start a write');
 }
 console.log('PSC1_MODULAR_WIRE_TESTS '+JSON.stringify({positive:1,refusals:mutations.length,
  canonicalNumbers:2,exactUnicodeAndEscaping:true}));
}finally{fs.rmSync(temporary,{recursive:true,force:true});}
