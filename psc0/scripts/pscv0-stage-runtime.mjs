// Verify the retained archive before invoking npm. This stages no new runtime.
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import path from 'node:path';
const directory=path.resolve(process.argv[2]);
const manifest=JSON.parse(await readFile(path.join(directory,'manifest.json'),'utf8'));
assert.equal(manifest.sourceCommit,'2f42a52814f3785ff2d92bd826f6e7fb3eb9bc8a');
assert.equal(manifest.sourceVariant,'lean');
for(const name of ['proofscript-0.1.0-psc0.1.tgz','typescript-7.0.2.tgz','typescript-typescript-'+process.platform+'-x64-7.0.2.tgz']){
  const record=manifest.packages.find(x=>x.name===name);
  assert(record,'missing retained artifact '+name);
  const actual=createHash('sha256').update(await readFile(path.join(directory,name))).digest('hex');
  assert.equal(actual,record.sha256,'retained archive mismatch '+name);
}
console.log('PSCV0_RETAINED_RUNTIME: PASS '+process.platform);
