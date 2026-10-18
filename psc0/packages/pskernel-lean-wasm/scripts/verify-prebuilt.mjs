// Verify complete byte-for-byte artifact + source + pinned compiler provenance.
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {readFile} from 'node:fs/promises';
import {resolve, dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {loadGcProbe} from '../index.mjs';

const root=resolve(dirname(fileURLToPath(import.meta.url)), '..');
const file=p=>resolve(root,p);
const manifest=JSON.parse(await readFile(file('PREBUILT_GC_PROBE_MANIFEST.json'), 'utf8'));
const pin=JSON.parse(await readFile(file('LEAN_SOURCE_PIN.json'), 'utf8'));
const sha=data=>createHash('sha256').update(data).digest('hex');
assert.equal(manifest.isProofKernel,false);
assert.equal(manifest.acceptsCanonicalAdmissions,false);
assert.equal(manifest.status,'gc-backend-probe-only');
assert.equal(manifest.sourceLanguage,pin.languageProfile);
assert.equal(manifest.leanCommit,pin.leanCommit);
assert.equal(manifest.sourceSha256,sha(await readFile(file('src/PsKernelLeanWasmGc/Probe.lean'))));
for (const [key,{path:relativePath,bytes,sha256}] of Object.entries(manifest.assets)){
  assert.equal(key,relativePath.slice(5));
  const payload=await readFile(file(relativePath));
  assert.equal(payload.length,bytes,'size mismatch '+relativePath);
  assert.equal(sha(payload),sha256,'sha mismatch '+relativePath);
}
const {probe,module}=await loadGcProbe();
assert.equal(WebAssembly.Module.imports(module).length,0);
assert.equal(WebAssembly.Module.exports(module).some(e=>e.kind==='memory'),false);
for(let a=0;a<=1;a++)for(let b=0;b<=1;b++){
  assert.equal(probe(a,b),a&&b?1:0,'GC probe runtime');
}
console.log('PSC0_WASM_GC_PREBUILT: PASS (sha256 + source identity + actual GC runtime; NOT a proof checker)');
