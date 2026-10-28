// Repository source identity and fresh paired-grammar checking. Receipts grant no admission authority.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
import {readCanonicalOwnership, readCanonicalCompilerSources, verifyTrackedSourceDomains} from '../host-tools/canonical-sources.mjs';
import {createLosslessSourceTool, createSourceOwnershipTool, createCheckedSourceConverter} from '../host-tools/source-refactoring.mjs';
import {compilerSourceClosureDigest} from '../host-tools/compiler-host-protocol.mjs';
import {projectNativeReferences} from './native-reference-projection.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');process.chdir(root);
const args=process.argv.slice(2);assert.ok(args.length===0||(args.length===1&&args[0]==='--static'));
const out=path.resolve('dist/canonical-source-check');fs.mkdirSync(out,{recursive:true});
const sha=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
const json=value=>JSON.stringify(value,null,2)+'\n';
const put=(name,value)=>fs.writeFileSync(path.join(out,name),json(value));
process.on('uncaughtExceptionMonitor',error=>put('failure.json',{status:'refused',testedCommit:process.env.GITHUB_SHA??null,
 message:String(error.message),cause:error.cause??null,receiptGrantsAdmissionAuthority:false}));
const ownership=readCanonicalOwnership(root),manifest=ownership.manifest;
// CI provenance is independent of ordinary source reads. The initial manifest blob
// is the exact reviewed promotion; later edits name an ancestral checked manifest.
const git=args=>{
 const result=spawnSync('git',args,{cwd:root,encoding:null,timeout:10000,maxBuffer:8*1024*1024});
 assert.equal(result.error,undefined);assert.equal(result.status,0,String(result.stderr));return result.stdout;
};
const baselineRecordBytes=fs.readFileSync('bootstrap/CANONICAL_BASELINE.json');
const introductions=git(['log','--format=%H','--diff-filter=A','--',':(top)psc1/bootstrap/CANONICAL_BASELINE.json'])
 .toString('utf8').trim().split('\n').filter(Boolean);
assert.equal(introductions.length,1,'The initial ownership baseline may not be deleted, replaced or reintroduced.');
assert.match(introductions[0],/^[0-9a-f]{40}$/);
assert.ok(git(['show',introductions[0]+':psc1/bootstrap/CANONICAL_BASELINE.json']).equals(baselineRecordBytes),
 'The initial ownership baseline record must remain byte-identical to its introduction.');
const baselineRecord=JSON.parse(baselineRecordBytes.toString('utf8'));
assert.match(baselineRecord.preparedCommit,/^[0-9a-f]{40}$/);
git(['merge-base','--is-ancestor',baselineRecord.preparedCommit,introductions[0]]);
assert.equal(baselineRecord.schema,'psc1-canonical-source-baseline/1');
assert.match(baselineRecord.manifestGitBlobSha,/^[0-9a-f]{40}$/);
assert.match(baselineRecord.manifestSha256,/^[0-9a-f]{64}$/);
const initialBytes=git(['cat-file','blob',baselineRecord.manifestGitBlobSha]);
assert.equal(sha(initialBytes),baselineRecord.manifestSha256);
const initial=JSON.parse(initialBytes.toString('utf8'));
assert.equal(initial.preparedCommit,baselineRecord.preparedCommit);
assert.equal(initial.preparedRunId,String(baselineRecord.preparedRunId));
let prior=initial,priorBytes=initialBytes,baselineCommit=null;
if(manifest.referenceRefresh){
 const refresh=manifest.referenceRefresh;baselineCommit=refresh.baseline;
 assert.match(baselineCommit,/^[0-9a-f]{40}$/);
 git(['merge-base','--is-ancestor',baselineCommit,'HEAD']);
 priorBytes=git(['show',baselineCommit+':psc1/CANONICAL_SOURCES.json']);
 assert.equal(sha(priorBytes),refresh.baselineManifestSha256);
 prior=JSON.parse(priorBytes.toString('utf8'));
 assert.equal(refresh.untouchedReferenceBytesPreserved,true);
}
assert.equal(prior.schema,manifest.schema);
const initialOwners=new Map(initial.owners.map(row=>[row.module,row]));
assert.equal(initialOwners.size,initial.owners.length);
assert.deepEqual([...initialOwners.keys()].sort(),manifest.owners.map(row=>row.module).sort());
const boundary=row=>({path:row.path,role:row.role,canonicalImplementation:row.canonicalImplementation??null});
const sortedBoundaries=value=>value.classifiedRemainder.map(boundary).sort((a,b)=>a.path.localeCompare(b.path));
assert.deepEqual(sortedBoundaries(manifest),sortedBoundaries(initial),
 'Changing native/canonical ownership boundaries requires a separate reviewed migration.');
for(const row of manifest.owners){
 const initialOwner=initialOwners.get(row.module);
 for(const key of ['path','authority'])assert.equal(row[key],initialOwner[key]);
 for(const key of ['path','authority'])assert.equal(row.bootstrap[key],initialOwner.bootstrap[key]);
}
const priorOwners=new Map(prior.owners.map(row=>[row.module,row]));
assert.equal(priorOwners.size,prior.owners.length);
assert.deepEqual([...priorOwners.keys()].sort(),manifest.owners.map(row=>row.module).sort(),
 'New or removed canonical owners require a separate reviewed ownership migration.');
const changedOwners=[];
for(const row of manifest.owners){
 const before=priorOwners.get(row.module);
 assert.equal(row.path,before.path);assert.equal(row.authority,before.authority);
 assert.equal(row.bootstrap.path,before.bootstrap.path);assert.equal(row.bootstrap.authority,before.bootstrap.authority);
 const psChanged=row.sha256!==before.sha256||row.bytes!==before.bytes;
 const referenceChanged=row.bootstrap.sha256!==before.bootstrap.sha256||row.bootstrap.bytes!==before.bootstrap.bytes;
 if(!psChanged)assert.equal(referenceChanged,false,'Bootstrap reference changed without its canonical PS owner: '+row.module);
 if(psChanged){
  assert.ok(manifest.referenceRefresh,'Canonical edits require checked reference refresh evidence: '+row.module);
  changedOwners.push({module:row.module,path:row.path,reference:row.bootstrap.path,referenceChanged,
   beforeSha256:before.sha256,afterSha256:row.sha256});
 }
}
if(manifest.referenceRefresh){
 assert.deepEqual([...manifest.referenceRefresh.changedCanonicalModules].sort(),changedOwners.map(row=>row.module).sort());
 const compilerReferences=changedOwners.filter(row=>row.referenceChanged&&row.path.startsWith('packages/'));
 if(compilerReferences.length)assert.equal(manifest.referenceRefresh.nativeProjectionProbe?.status,'passed');
}
const transition={schema:'psc1-canonical-source-transition/1',status:'static-pins-passed',
 baselineCommit,baselineManifestSha256:sha(priorBytes),initialManifestGitBlobSha:baselineRecord.manifestGitBlobSha,
 changedOwners,unchangedOwnerReferencesPreserved:true,receiptGrantsAdmissionAuthority:false};
put('transition.json',transition);
const listed=spawnSync('git',['ls-files','-z','--','.'],{cwd:root,encoding:'utf8',timeout:10000,maxBuffer:8*1024*1024});
assert.equal(listed.error,undefined);assert.equal(listed.status,0,listed.stderr);
const domains=verifyTrackedSourceDomains(listed.stdout.split('\0').filter(Boolean),{root,ownership});
put('source-domains.json',domains);
const canonical=readCanonicalCompilerSources('Ps.CompilerUnified.Service',{root});
const projectBytes=fs.readFileSync(manifest.primaryProject),project=JSON.parse(projectBytes);
assert.equal(project.schemaVersion,1);assert.equal(project.entryModule,'Ps.CompilerUnified.Service');
assert.deepEqual(project.sources,canonical.map(row=>({module:row.module,path:row.path})));
const unifiedDigest=compilerSourceClosureDigest(canonical);
assert.equal(unifiedDigest,(manifest.currentUnified??manifest.qualifiedUnified).sourceClosureDigest);
const integrity={schema:'psc1-canonical-source-integrity/1',status:'passed',testedCommit:process.env.GITHUB_SHA??null,
 manifestSha256:sha(fs.readFileSync('CANONICAL_SOURCES.json')),projectSha256:sha(projectBytes),
 owners:manifest.ownerCount,compilerOwners:manifest.compilerOwnerCount,libraryOwners:manifest.libraryOwnerCount,
 sourceDomains:domains.counts,unifiedModules:canonical.length,sourceClosureDigest:unifiedDigest,
 authoredOwner:'repository-proofscript',bootstrapAuthority:'immutable-checked-reference',
 receiptGrantsAdmissionAuthority:false};
put('integrity.json',integrity);
if(args[0]==='--static'){
 console.log('PSC1_CANONICAL_SOURCE_INTEGRITY: '+JSON.stringify(integrity));
}else{
 const binary=name=>path.join(root,'.lake/build/bin',name);
 const hashes=Object.fromEntries(['psc1_lossless_source','psc1_source_ownership','psc1_independent_checker'].map(name=>[name,sha(fs.readFileSync(binary(name)))]));
 const lexical=createLosslessSourceTool({executable:binary('psc1_lossless_source'),sha256:hashes.psc1_lossless_source});
 const checker=createSourceOwnershipTool({qualificationGraphProfile:'canonical-repository-40m',lexicalTool:lexical,executable:binary('psc1_source_ownership'),sha256:hashes.psc1_source_ownership,
  checkerExecutable:binary('psc1_independent_checker'),checkerSha256:hashes.psc1_independent_checker});
 const shape=index=>index.modules.map(module=>({module:module.module,imports:module.imports,
  origins:module.origins.map(origin=>({sourceIndex:origin.sourceIndex,sourceName:origin.sourceName,
   members:origin.members.map(member=>({index:member.index,name:member.name,role:member.role})),
   normalization:origin.normalization?.workerName??null}))}));
 const groups=[],projectedGroups=[];
 const converter=createCheckedSourceConverter({ownershipTool:checker});
 for(const [label,filter,audit,expected]of[
  ['compiler',row=>row.path.startsWith('packages/'),manifest.auditRoot,manifest.correspondence],
  ['library',row=>row.path.startsWith('stdlib/ProofScript/'),manifest.libraryCorrespondence.auditRoot,manifest.libraryCorrespondence]]){
  console.log('PSC1_CANONICAL_SOURCE_CHECK: '+label);
  const started=Date.now(),rows=manifest.owners.filter(filter).map(row=>ownership.modules.get(row.module));
  const auditBytes=Buffer.from(audit.imports.map(module=>'import '+module).join('\n')+'\n');
  const snapshots=grammar=>[...rows.map(row=>lexical.capture({module:row.module,grammar,bytes:grammar==='ps'?row.ps:row.lean})),
   lexical.capture({module:audit.module,grammar,bytes:auditBytes})];
  const lean=checker.analyze({snapshots:snapshots('lean'),entry:audit.module,assurance:'ordinary-checked'});
  const psSnapshots=snapshots('ps');
  const ps=checker.analyze({snapshots:psSnapshots,entry:audit.module,assurance:'ordinary-checked'});
  const changed=changedOwners.filter(row=>filter(row));
  if(changed.length){
   const projection=converter.convert({index:ps,snapshots:psSnapshots,targetGrammar:'lean',commentPolicy:'owner-notes'});
   const nativeProjection=projectNativeReferences({root,out,label:label+'-transition',
    sources:changed.map(row=>({module:row.module,bytes:Buffer.from(converter.readCandidate(projection,row.module))}))});
   for(const changedOwner of changed){
    const row=ownership.modules.get(changedOwner.module);
    const generated=nativeProjection.modules.get(row.module);
    assert.ok(generated.equals(row.lean),'Changed reference must be the freshly checked PS projection: '+row.module);
    assert.equal(sha(generated),row.bootstrap.generatedProjectionSha256);
   }
   projectedGroups.push({label,modules:changed.map(row=>row.module),admissionsSha256:projection.admissionsSha256,
    originalIrSha256:projection.originalIrSha256,nativePatternProjection:nativeProjection.evidence,freshCheckedProjection:true});
  }
  for(const key of ['admissionsSha256','originalIrSha256']){
   assert.equal(lean[key],ps[key],label+' paired '+key);assert.equal(ps[key],expected[key],label+' recorded '+key);
  }
  assert.equal(lean.sourceClosureDigest,expected.bootstrapSourceClosureDigest);
  assert.equal(ps.sourceClosureDigest,expected.canonicalSourceClosureDigest);
  assert.deepEqual(lean.partialNames,ps.partialNames);assert.deepEqual(shape(lean),shape(ps));
  assert.equal(lean.checker.accepted,true);assert.equal(ps.checker.accepted,true);
  groups.push({label,status:'passed',modules:rows.length,elapsedMs:Date.now()-started,
   admissionsSha256:ps.admissionsSha256,originalIrSha256:ps.originalIrSha256,
   bootstrapSourceClosureDigest:lean.sourceClosureDigest,canonicalSourceClosureDigest:ps.sourceClosureDigest,
   bootstrapChecker:lean.checker,canonicalChecker:ps.checker,bootstrapMetrics:lean.metrics,canonicalMetrics:ps.metrics});
 }
 readCanonicalOwnership(root);
 const result={...integrity,
  schema:'psc1-canonical-source-correspondence/1',helperHashes:hashes,groups,
  actualIndependentAdmissions:4+projectedGroups.length,projectedGroups,transition:{...transition,status:'passed'},
  originalStrictIrCorrespondence:true,formalSourcePreservationProof:false,receiptGrantsAdmissionAuthority:false};
 put('transition.json',{...transition,status:'passed',projectedGroups});
 put('correspondence.json',result);
 console.log('PSC1_CANONICAL_SOURCE_CORRESPONDENCE: '+JSON.stringify(result));
}
