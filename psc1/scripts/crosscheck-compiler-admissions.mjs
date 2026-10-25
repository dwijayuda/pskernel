// Real packaged official kernels check the complete compiler's canonical graph.
// This is logical admission, not a compiler-preservation or self-hosting proof.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { sha256 as sha } from './kernel435-qualified-artifact.mjs';
import { fixtures } from './kernel435-fixtures.mjs';
const leanCommit = 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc';
export async function crosscheckCompilerAdmissions({ sourceClosureDigest, admissions, kernelRoots, outputFile }) {
  assert.match(sourceClosureDigest, /^[a-f0-9]{64}$/);
  assert.ok(admissions.length > 0);
  const wasmManifest = JSON.parse(fs.readFileSync(path.join(kernelRoots.wasm, 'PREBUILT_WASM_MANIFEST.json')));
  assert.equal(wasmManifest.memoryModel, 'linear');
  assert.equal(wasmManifest.leanVersion, '4.35.0');
  const handles = {}, records = [];
  const env = { ...process.env }; delete env.PSC_LEAN_KERNEL_PROVIDER_BIN;
  for (const provider of ['wasm', 'native']) {
    const api = await import(pathToFileURL(path.join(kernelRoots[provider], 'index.mjs')).href);
    handles[provider] = await api.createKernel({
      timeoutMs: 120000, maxBuffer: 32 * 1024 * 1024,
      ...(provider === 'native' ? { env, allowSourceCheckoutFallback: false } : {}),
    });
    assert.equal(handles[provider].metadata.leanVersion, '4.35.0');
    assert.equal(handles[provider].metadata.leanCommit, leanCommit);
    assert.equal(handles[provider].metadata.profile, 'lean4.35-core');
  }
  for (const input of admissions) {
    const bytes = fs.readFileSync(input.file); assert.equal(sha(bytes), input.sha256);
    const source = new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(bytes);
    const graph = JSON.parse(source);
    assert.equal(graph.protocol, 'pskernel-lean/1');
    assert.equal(graph.format, 'proofscript-checked-admissions'); assert.equal(graph.version, 2);
    const bad = JSON.parse(fixtures.find(item => item.id === 'kernel-type-rejection').input).admissions[0];
    bad.declaration.n.v = 'PSC1.WholeCompilerInvalidType';
    const invalid = JSON.stringify({ ...graph, admissions: [bad, ...graph.admissions] });
    const providers = {};
    for (const provider of ['wasm', 'native']) {
      const started = Date.now(), accepted = await handles[provider].checkCanonicalAdmissions(source);
      assert.equal(accepted.accepted, true, provider + ':' + JSON.stringify(accepted));
      const elapsedMs = Date.now() - started;
      const rejected = await handles[provider].checkCanonicalAdmissions(invalid);
      assert.equal(rejected.accepted, false, provider + ': malformed compiler graph accepted');
      assert.equal(rejected.error?.kind, 'kernel-rejection');
      providers[provider] = { accepted: true, elapsedMs, invalidTypeRejected: true,
        acceptedResponseSha256: sha(JSON.stringify(accepted)),
        rejectionResponseSha256: sha(JSON.stringify(rejected)) };
    }
    records.push({ admissionsSha256: input.sha256, bytes: bytes.length,
      admissionRecords: graph.admissions.length, providers, agreement: true });
    console.log('PSC1_COMPILER_KERNEL_CROSSCHECK: ' + JSON.stringify(records.at(-1)));
  }
  const report = { schema: 'psc1-compiler-kernel-admission/1', testedCommit: process.env.GITHUB_SHA,
    sourceClosureDigest, status: 'passed', leanVersion: '4.35.0', leanCommit,
    defaultKernelMemoryModel: 'linear', records, scope: 'independent logical admission only' };
  fs.mkdirSync(path.dirname(outputFile), { recursive: true });
  fs.writeFileSync(outputFile, JSON.stringify(report, null, 2) + '\n');
  return report;
}
