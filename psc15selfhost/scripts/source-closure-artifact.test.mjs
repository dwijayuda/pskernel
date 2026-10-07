import assert from 'node:assert/strict';
import { test } from 'node:test';
import path from 'node:path';
import { artifactKey } from './artifact-evidence.mjs';
import { checkedSourceClosureArtifacts, verifyCheckedSourceClosure } from './source-closure-artifact.mjs';

function snapshot() {
  const root = path.resolve('/fixture');
  return {
    root,
    entry: path.join(root,'Main.ps'),
    kind:'ps',
    closureSha256:'1'.repeat(64),
    ordered:[
      { path:path.join(root,'Lib.ps'), source:'const helper: Nat := { 1 }\n' },
      { path:path.join(root,'Main.ps'), source:'import Lib\nconst answer: Nat := { helper }\n' },
    ],
  };
}

test('closure binds exact logical paths, preparation order and file bytes', () => {
  const built = checkedSourceClosureArtifacts(snapshot());
  const blobs = new Map(built.files.map(item=>[artifactKey(item.identity),item.bytes]));
  const checked = verifyCheckedSourceClosure(built.closure,{resolveArtifact:id=>blobs.get(artifactKey(id))});
  assert.equal(checked.entry,'Main.ps');
  assert.deepEqual(checked.preparationOrder,['Lib.ps','Main.ps']);
  assert.equal(checked.fileCount,2);
  assert.equal(checked.authority,'source-identity-only');
  const value=JSON.parse(built.closure.bytes);
  assert.deepEqual(value.files.map(item=>item.path),['Lib.ps','Main.ps']);
});

test('closure verification rejects tampered files, path collisions and missing entry', () => {
  const built=checkedSourceClosureArtifacts(snapshot());
  const blobs=new Map(built.files.map(item=>[artifactKey(item.identity),item.bytes]));
  const key=artifactKey(built.files[0].identity);
  const tampered=new Map(blobs);tampered.set(key,Buffer.from('tampered'));
  assert.throws(()=>verifyCheckedSourceClosure(built.closure,{resolveArtifact:id=>tampered.get(artifactKey(id))}),/ARTIFACT_BYTES/);
  const duplicate=snapshot(); duplicate.ordered.push({path:path.join(duplicate.root,'lib.ps'),source:'x'});
  assert.throws(()=>checkedSourceClosureArtifacts(duplicate),/DUPLICATE/);
  const missing=snapshot(); missing.entry=path.join(missing.root,'Missing.ps');
  assert.throws(()=>checkedSourceClosureArtifacts(missing),/ENTRY/);
});

test('closure construction and replay enforce aggregate resource limits', () => {
  assert.throws(()=>checkedSourceClosureArtifacts(snapshot(),{maxFiles:1}),/LIMIT|RESOURCE_EXHAUSTED/);
  const built=checkedSourceClosureArtifacts(snapshot());
  const blobs=new Map(built.files.map(item=>[artifactKey(item.identity),item.bytes]));
  assert.throws(()=>verifyCheckedSourceClosure(built.closure,{resolveArtifact:id=>blobs.get(artifactKey(id)),maxTotalBytes:1}),/RESOURCE_EXHAUSTED/);
});
