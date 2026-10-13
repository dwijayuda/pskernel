// Check the exact user language-design document with the authorized stable-pin amendment. No compiler-conformance assertion.
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
  assert.equal(bytes.length,309429,'reference byte count');
  assert.equal(hash(bytes),'07e505a93806c47faab5bd215e8fe2c76c2998ca48654dda86f0bb5f161ca389','reference SHA-256');
  assert.equal(gitBlob(bytes),'25e1ef788794db175a2183679e37ff8c8e9b6a2e','exact amended Git blob');
  assert.equal(adoption.schema,'psc0-language-reference-adoption/2');
  assert.equal(adoption.reference.revision,'v7');
  assert.equal(adoption.reference.repoPath,'psc0/PSCV0_LANGUAGE_REFERENCE.md');
  assert.equal(adoption.reference.bytes,bytes.length);
  assert.equal(adoption.reference.sha256,hash(bytes));
  assert.equal(adoption.reference.gitBlobSha1,gitBlob(bytes));
  assert.equal(adoption.referenceLeanPin.commit,'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
  assert.equal(adoption.currentCandidate.newSelfhostFixedPoint,false);
  return {revision:'v7',bytes:bytes.length,sha256:hash(bytes),gitBlobSha1:gitBlob(bytes),leanCommit:'eb6cafb7290e8bd5f2937522d8d804f58f02bafc',designOnly:true};
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url))
  console.log('PSCV0_REFERENCE_V7_IDENTITY: PASS '+JSON.stringify(await verifyPscv0Reference()));
