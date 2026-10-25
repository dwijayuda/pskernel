// Actual Linux file operations and child-process termination; no OS simulation.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {openPublicationStore,readPublication} from '../host-tools/transactional-publication.mjs';
const sha = b => crypto.createHash('sha256').update(b).digest('hex');
const out = path.resolve('dist/transactional-publication');
fs.mkdirSync(out,{recursive:true});
let serial=0;const records=[];
function prepared(root,protocol,value) {
 const transaction=openPublicationStore(root,protocol);
 const stage=fs.mkdtempSync(path.join(root,'generations/.stage-'));
 const source='export const answer='+JSON.stringify(value)+';\n';
 fs.writeFileSync(path.join(stage,'target.mjs'),source);
 const files=[{path:'target.mjs',bytes:Buffer.byteLength(source),sha256:sha(source)}];
 return {transaction,stage,manifest:{schema:'psc1-generated-service-bundle/1',targetFile:'target.mjs',
   files,sequence:serial++,logicalAdmission:'accepted'},verify() {
   assert.equal(fs.readFileSync(path.join(stage,'target.mjs'),'utf8'),source);
 }};
}
function publish(p,fault) {
 // The store checks the sealed copy after rename; session verification here binds
 // trusted tool bytes and does not refer to a stage that has already been sealed.
 return p.transaction.publish({...p,verify:()=>{},fault});
}
for(const protocol of ['legacy-symlink','portable-file']) {
 const root=path.join(out,protocol);
 assert.equal(readPublication(path.join(root,'absent'),protocol),null);
 const first=publish(prepared(root,protocol,42));
 assert.equal(readPublication(root,protocol).generation,first.generation);
 const firstBytes=fs.readFileSync(first.target);
 const stale=prepared(root,protocol,7);
 const second=publish(prepared(root,protocol,43));
 assert.equal(fs.readFileSync(first.target).equals(firstBytes),true,'returned paths are immutable');
 assert.equal(readPublication(root,protocol).generation,second.generation);
 assert.throws(()=>publish(stale),/PRIOR_PUBLICATION_CHANGED/);
 for(const phase of ['before-seal','after-seal','before-commit']) {
   const prior=readPublication(root,protocol).generation;
   assert.throws(()=>publish(prepared(root,protocol,phase),at=>{if(at===phase)throw Error('fault');}),/fault/);
   assert.equal(readPublication(root,protocol).generation,prior);
   assert.equal(fs.readdirSync(root).some(name=>name.startsWith('.current-')),false);
 }
 const committed=prepared(root,protocol,44);
 let uncertain;
 try {publish(committed,phase=>{if(phase==='after-commit')throw Error('sync fault');});}
 catch(error){uncertain=error;}
 assert.match(uncertain.message,/COMMITTED_DURABILITY_UNCERTAIN/);
 assert.equal(uncertain.committedPublication.durability,'unconfirmed');
 assert.equal(readPublication(root,protocol).generation,uncertain.committedPublication.generation);
 assert.throws(()=>publish(committed),/PUBLICATION_CONSUMED/);
 const corrupt=prepared(root,protocol,45);
 assert.throws(()=>publish(corrupt,phase=>{
   if(phase==='after-seal'){
     const generation=fs.readdirSync(path.join(root,'generations')).find(name=>{
       if(!/^[a-f0-9]{64}$/.test(name))return false;
       const m=JSON.parse(fs.readFileSync(path.join(root,'generations',name,'manifest.json')));
       return m.sequence===corrupt.manifest.sequence;
     });
     fs.writeFileSync(path.join(root,'generations',generation,'target.mjs'),'tamper');
   }
 }),/ARTIFACT_CHANGED/);
 assert.equal(readPublication(root,protocol).generation,uncertain.committedPublication.generation);
 assert.throws(()=>openPublicationStore(root,protocol==='portable-file'?'legacy-symlink':'portable-file'),/STORE_UNMANAGED/);
 const gens=path.join(root,'generations'),moved=gens+'.saved';
 fs.renameSync(gens,moved);fs.symlinkSync(moved,gens,'dir');
 try{assert.throws(()=>readPublication(root,protocol),/STORE_INVALID/);}
 finally{fs.unlinkSync(gens);fs.renameSync(moved,gens);}
 const cleanup=prepared(root,protocol,46);let cleanupError;
 try{publish(cleanup,phase=>{if(phase==='after-commit'){
   fs.unlinkSync(path.join(root,'.publish.lock'));fs.mkdirSync(path.join(root,'.publish.lock'));
 }});}catch(error){cleanupError=error;}
 assert.match(cleanupError.message,/COMMITTED_DURABILITY_UNCERTAIN/);
 assert.equal(readPublication(root,protocol).generation,cleanupError.committedPublication.generation);
 fs.rmdirSync(path.join(root,'.publish.lock'));
 records.push({protocol,postcommitCleanupFailureExplicit:true,symlinkGenerationRootRefused:true,priorPreserved:true,immutableReaders:true,staleWriterRefused:true,
   precommitFaults:3,postcommitUncertaintyExplicit:true,sealedTamperRefused:true,mixedProtocolsRefused:true});
}
// Kill a writer after durable seal, before pointer replacement. Readers retain the
// previous generation. A stale lock intentionally refuses automatic takeover.
const crashRoot=path.join(out,'crash');const before=publish(prepared(crashRoot,'portable-file',1));
const child=path.join(out,'crash.mjs');
fs.writeFileSync(child,"import fs from 'node:fs';import path from 'node:path';"+
 "import {openPublicationStore} from "+JSON.stringify(new URL('../host-tools/transactional-publication.mjs',import.meta.url).href)+";"+
 "const root=process.argv[2],tx=openPublicationStore(root,'portable-file'),stage=fs.mkdtempSync(path.join(root,'generations/.stage-'));"+
 "fs.writeFileSync(path.join(stage,'target.mjs'),'x');"+
 "tx.publish({stage,manifest:{schema:'psc1-generated-service-bundle/1',files:[],targetFile:'target.mjs'},verify(){},fault(phase){if(phase==='after-seal')process.kill(process.pid,'SIGKILL');}});");
const killed=spawnSync(process.execPath,[child,crashRoot],{encoding:'utf8',timeout:10000});
assert.equal(killed.signal,'SIGKILL');
assert.equal(readPublication(crashRoot,'portable-file').generation,before.generation);
assert.throws(()=>publish(prepared(crashRoot,'portable-file',2)),/EEXIST/);
records.push({crash:'SIGKILL after-seal',priorReadable:true,unsafeLockTakeoverRefused:true});
fs.writeFileSync(path.join(out,'qualification.json'),JSON.stringify({schema:'psc1-transactional-publication-tests/1',
 testedCommit:process.env.GITHUB_SHA,platform:process.platform,architecture:process.arch,
 status:'passed',records,otherPlatformQualification:'not-run'},null,2)+'\n');
console.log('PSC1_TRANSACTIONAL_PUBLICATION: PASS '+JSON.stringify(records));
