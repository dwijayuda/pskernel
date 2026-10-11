// Check the exact byte-identical user language-design document. No compiler-conformance assertion.
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const hash=b=>createHash('sha256').update(b).digest('hex');
const gitBlob=b=>createHash('sha1').update('blob '+b.length+'\0').update(b).digest('hex');
export async function verifyPscv0Reference(){
  const bytes=await readFile(path.join(root,'PSCV0_LANGUAGE_REFERENCE.md'));
  const adoption=JSON.parse(await readFile(path.join(root,'docs/PSCV0_REFERENCE_ADOPTION.json'),'utf8'));
  assert.equal(bytes.length,308462,'reference byte count');
  assert.equal(hash(bytes),'843940bd7f6a9b286e80b01d8c891a7e01b8868a9de7b05833fce32d49be6cd5','reference SHA-256');
  assert.equal(gitBlob(bytes),'d9e9d7c21337881175b19ccc4c508a792a430195','exact uploaded Git blob');
  assert.equal(adoption.schema,'psc0-language-reference-adoption/2');
  assert.equal(adoption.reference.revision,'v7');
  assert.equal(adoption.reference.repoPath,'psc0/PSCV0_LANGUAGE_REFERENCE.md');
  assert.equal(adoption.reference.bytes,bytes.length);
  assert.equal(adoption.reference.sha256,hash(bytes));
  assert.equal(adoption.reference.gitBlobSha1,gitBlob(bytes));
  assert.equal(adoption.referenceLeanPin.commit,'c29b6dda4f7c20e3eeaa717c4e565663c5cfa364');
  assert.equal(adoption.currentCandidate.newSelfhostFixedPoint,false);
  return {revision:'v7',bytes:bytes.length,sha256:hash(bytes),gitBlobSha1:gitBlob(bytes),leanCommit:'c29b6dda4f7c20e3eeaa717c4e565663c5cfa364',designOnly:true};
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url))
  console.log('PSCV0_REFERENCE_V7_IDENTITY: PASS '+JSON.stringify(await verifyPscv0Reference()));
