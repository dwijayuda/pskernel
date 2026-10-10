import {test} from 'node:test';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {
 expectedLeanSourcePath,shaGitBlob,reviewBatchSourceBlobs,
 leanCommit,
} from '../src/batch-source-provenance.mjs';

test('module names map to expected pinned Lean Git source paths, not arbitrary paths',()=>{
 assert.equal(expectedLeanSourcePath('Init.Prelude'),'src/Init/Prelude.lean');
 assert.equal(expectedLeanSourcePath('Init.Data.Int.Basic'),'src/Init/Data/Int/Basic.lean');
 assert.equal(expectedLeanSourcePath('Std.Data.TreeMap.Basic'),'src/Std/Data/TreeMap/Basic.lean');
 for(const bad of ['../Init.Prelude','Other.Initial','Init..Prelude',
    'Init.Data/Bad','Init.Fake\\..','Init.X;rm','',null]) {
  assert.throws(()=>expectedLeanSourcePath(bad),
    /PSC_PSCV_BATCH_BLOB_PROVENANCE_IMPORTED_MODULE_PATH/u);
 }
});
test('Git raw source blob SHA-1 is content-identity not a file-path claim',()=>{
 const source='instance named : Add Nat where\n  add := Nat.add\n';
 const header='blob '+Buffer.byteLength(source)+String.fromCharCode(0);
 const sha=createHash('sha1').update(header).update(source).digest('hex');
 assert.equal(shaGitBlob(source),sha);
 assert.notEqual(shaGitBlob(source+'\n'),sha);
 assert.throws(()=>shaGitBlob(null),
   /PSC_PSCV_BATCH_BLOB_PROVENANCE_BLOB_NOT_TEXT/u);
});
test('forged imported module identity is rejected without touching Standard authority',()=>{
 const f={
  typedReport:{identitySha256:'abc06182e2875b15f150fabd567fa7a3c86ccb783030bf0ac04dc635fe41a372',
    selectedDeclarationCount:45,verifiedExecutableAuthorized:false,
    selectedDeclarations:[{name:'instHAdd',importedModule:'Forged.Module'}]},
  upstreamCommit:leanCommit,sourceFiles:[],
 };
 assert.throws(()=>reviewBatchSourceBlobs(f),
  /PSC_PSCV_BATCH_BLOB_PROVENANCE_/u);
 assert.throws(()=>reviewBatchSourceBlobs({...f,upstreamCommit:'0'.repeat(40)}),
  /PSC_PSCV_BATCH_BLOB_PROVENANCE_/u);
});
