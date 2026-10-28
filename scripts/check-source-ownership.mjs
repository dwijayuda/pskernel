// Exhaustive repository-wide .ps ownership inventory. It grants no admission authority.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
import {readCanonicalOwnership} from '../psc1/host-tools/canonical-sources.mjs';

const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const out=path.join(root,'psc1/dist/canonical-source-check');
fs.mkdirSync(out,{recursive:true});
const digest=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
const relative=value=>{
 assert.equal(typeof value,'string');
 assert.ok(value&&!value.startsWith('/')&&!value.includes('\\')&&!value.split('/').some(p=>!p||p==='.'||p==='..'),'invalid ownership path: '+value);
 return value;
};
function bytes(file){
 relative(file);let current=root;
 for(const part of file.split('/')){current=path.join(current,part);assert.ok(!fs.lstatSync(current).isSymbolicLink(),'ownership symlink: '+file);}
 assert.ok(fs.statSync(current).isFile(),'ownership regular file required: '+file);
 return fs.readFileSync(current);
}
const identity=file=>{const value=bytes(file);return {path:file,bytes:value.length,sha256:digest(value)};};
const read=file=>JSON.parse(bytes(file).toString('utf8'));
process.on('uncaughtExceptionMonitor',error=>fs.writeFileSync(path.join(out,'repository-ownership-failure.json'),JSON.stringify({
 status:'refused',message:String(error.message),testedCommit:process.env.GITHUB_SHA??null,receiptGrantsAdmissionAuthority:false},null,2)+'\n'));
const registry=read('SOURCE_OWNERSHIP.json');
assert.equal(registry.schema,'pskernel-proofscript-ownership/1');
assert.equal(registry.defaultAction,'refuse-unclassified-proofscript');
assert.equal(registry.psc1.manifest,'psc1/CANONICAL_SOURCES.json');
identity(registry.psc1.policy);
const checked=readCanonicalOwnership(path.join(root,'psc1'));
const canonical=new Map(checked.manifest.owners.map(row=>['psc1/'+row.path,row]));
const generated=new Map();
for(const view of checked.manifest.generatedViews){
 const target='psc1/'+relative(view.path),from='psc1/'+relative(view.from);
 for(const [owner,row] of canonical){
  if(!owner.startsWith(from+'/'))continue;
  const name=target+owner.slice(from.length);
  assert.ok(!generated.has(name),'duplicate generated view: '+name);
  generated.set(name,{owner,row});
 }
}
const rules=registry.rules;
assert.ok(Array.isArray(rules));const ids=new Set();
for(const rule of rules){
 assert.ok(!ids.has(rule.id));ids.add(rule.id);
 assert.ok(Boolean(rule.path)!==Boolean(rule.prefix),'one ownership selector required');
 if(rule.path)relative(rule.path);else{assert.ok(rule.prefix.endsWith('/'));relative(rule.prefix.slice(0,-1));}
 assert.ok(['self','retained-historical-bytes','retained-reference-bytes'].includes(rule.sourceOfTruth));
 identity(rule.policy);if(rule.pairedReference)identity(rule.pairedReference);
}
const retained=new Map(registry.retainedGenerated.map(row=>{
 relative(row.path);assert.equal(row.role,'retained-generated-kernel-artifact');
 identity(row.sourceRegistry);identity(row.buildRegistry);identity(row.policy);
 return [row.path,row];
}));
assert.equal(retained.size,registry.retainedGenerated.length);
const result=spawnSync('git',['ls-files','-z','--','*.ps'],{cwd:root,encoding:'utf8',timeout:20000,maxBuffer:32*1024*1024});
assert.equal(result.error,undefined);assert.equal(result.status,0,result.stderr);
const paths=result.stdout.split('\0').filter(Boolean).map(relative).sort();
assert.equal(new Set(paths).size,paths.length);
const rows=paths.map(file=>{
 assert.ok(file.endsWith('.ps'));
 const owner=canonical.get(file),view=generated.get(file),history=retained.get(file);
 const matches=rules.filter(rule=>rule.path?rule.path===file:file.startsWith(rule.prefix));
 assert.equal(Number(Boolean(owner))+Number(Boolean(view))+Number(Boolean(history))+matches.length,1,'exactly one .ps owner required: '+file);
 const actual=identity(file);
 if(owner){
  assert.equal(actual.sha256,owner.sha256);assert.equal(actual.bytes,owner.bytes);
  return {...actual,role:'canonical-editable-proofscript',project:'psc1',sourceOfTruth:file,
   module:owner.module,bootstrapReference:identity('psc1/'+owner.bootstrap.path)};
 }
 if(view){
  assert.equal(actual.sha256,view.row.sha256);assert.equal(actual.bytes,view.row.bytes);
  return {...actual,role:'exact-generated-packaging-view',project:'psc1',sourceOfTruth:view.owner};
 }
 if(history)return {...actual,role:history.role,project:history.project,
  sourceRegistry:identity(history.sourceRegistry),buildRegistry:identity(history.buildRegistry),editable:false};
 const rule=matches[0];
 return {...actual,role:rule.role,project:rule.project,rule:rule.id,
  sourceOfTruth:rule.sourceOfTruth==='self'?file:rule.sourceOfTruth,
  ...(rule.pairedReference?{pairedReference:identity(rule.pairedReference)}:{})};
});
const tracked=new Set(paths);
for(const file of canonical.keys())assert.ok(tracked.has(file),'untracked canonical source: '+file);
for(const file of retained.keys())assert.ok(tracked.has(file),'missing retained generated artifact: '+file);
for(const rule of rules)if(rule.path)assert.ok(tracked.has(rule.path),'missing declared source: '+rule.path);
const counts={};for(const row of rows)counts[row.role]=(counts[row.role]??0)+1;
const receipt={schema:'pskernel-proofscript-ownership-inventory/1',status:'passed',
 testedCommit:process.env.GITHUB_SHA??null,runId:process.env.GITHUB_RUN_ID??null,
 registry:identity('SOURCE_OWNERSHIP.json'),psc1Manifest:identity(registry.psc1.manifest),
 trackedProofScriptFiles:rows.length,counts,files:rows,unclassified:[],receiptGrantsAdmissionAuthority:false};
fs.writeFileSync(path.join(out,'repository-proofscript-ownership.json'),JSON.stringify(receipt,null,2)+'\n');
console.log('PSKERNEL_PROOFSCRIPT_OWNERSHIP: '+JSON.stringify({status:receipt.status,trackedProofScriptFiles:rows.length,counts,
 registrySha256:receipt.registry.sha256,psc1ManifestSha256:receipt.psc1Manifest.sha256}));
