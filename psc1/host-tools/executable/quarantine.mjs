// Host IO quarantine only. Candidate strings never acquire admission or publication.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
const MAX_FILE=33554432,MAX_STAGE=134217728;
export function quarantineCandidate(text,directory){
 assert.equal(typeof text,'string');assert.ok(Buffer.byteLength(text)<=MAX_STAGE);
 const candidate=JSON.parse(text);
 assert.equal(candidate.protocol,'psc1-modular-build/1');
 assert.equal(candidate.status,'candidate',JSON.stringify(candidate));
 assert.equal(candidate.candidateOnly,true);assert.equal(candidate.admission,'not-run');
 assert.ok(Array.isArray(candidate.files)&&candidate.files.length<=778);
 const names=new Set(['original-ir.json','specialized-ir.json','fused-ir.json','admissions.json',
  'capture.json','modules.json','js-runtime.mjs']);
 for(let unit=0;unit<257;unit++)for(const [variant,extension]of [['js','.mjs'],['js','.d.mts'],['ts','.mts']])
  names.add(variant+'/unit-'+unit+extension);
 const seen=new Set();let total=0;
 for(const row of candidate.files){
  assert.ok(Array.isArray(row)&&row.length===2);
  const [name,source]=row;assert.ok(names.has(name)&&!seen.has(name));
  assert.equal(typeof source,'string');const bytes=Buffer.byteLength(source);
  assert.ok(bytes<=MAX_FILE);total+=bytes;assert.ok(total<=MAX_STAGE);seen.add(name);
 }
 // Validate the entire write set before creating any file. Directory is host-owned.
 assert.ok(!fs.existsSync(directory),'PSC1_MODULAR_FRESH_QUARANTINE');
 fs.mkdirSync(directory,{recursive:true});fs.mkdirSync(path.join(directory,'js'));fs.mkdirSync(path.join(directory,'ts'));
 for(const [name,source]of candidate.files)fs.writeFileSync(path.join(directory,name),source,{flag:'wx',mode:0o600});
 const capture=JSON.parse(fs.readFileSync(path.join(directory,'capture.json')));
 const emission=JSON.parse(fs.readFileSync(path.join(directory,'modules.json')));
 assert.equal(candidate.requestId,capture.requestId);assert.equal(candidate.sourceClosureDigest,capture.sourceClosureDigest);
 assert.equal(emission.sourceClosureDigest,capture.sourceClosureDigest);
 assert.ok(emission.units.length>=2&&emission.units.length<=257);
 const expected=new Set([...names].filter(name=>!name.includes('/')));
 for(let unit=0;unit<emission.units.length;unit++)for(const [variant,extension]of [['js','.mjs'],['js','.d.mts'],['ts','.mts']])
  expected.add(variant+'/unit-'+unit+extension);
 assert.deepEqual([...seen].sort(),[...expected].sort(),'PSC1_MODULAR_COMPLETE_WRITE_SET');
 return {files:seen.size,bytes:total,wireBytes:Buffer.byteLength(text),candidateOnly:true,admission:'not-run'};
}

