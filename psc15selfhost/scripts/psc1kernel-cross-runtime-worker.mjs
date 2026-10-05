import assert from 'node:assert/strict';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { admissionRequest, iterations, requestCases, warmup, workloads } from './psc1kernel-cross-runtime-corpus.mjs';

const elapsed = start => Number(process.hrtime.bigint() - start);
const mode = process.argv[2];
const report = { runtime: mode, node: process.version, arch: process.arch, platform: process.platform };
if (mode === 'js') {
  const start = process.hrtime.bigint();
  const kernel = await import(pathToFileURL(path.resolve(process.argv[3])).href);
  report.importNs = elapsed(start);
  assert.equal(kernel.psKernelCrossGuards, true, 'rejection, exhaustion, exact large naturals');
  report.guards = true;
  report.rows = [];
  // Rotate order across fresh workers so one workload is not always first.
  const offset = Number(process.argv[4] ?? 0) % workloads.length;
  for (let n = 0; n < workloads.length; n++) {
    const kind = (offset + n) % workloads.length;
    const kindNat = BigInt(kind);
    const inputs = Array.from({ length: 16 }, (_, i) => kernel.psKernelCrossInput(kindNat, BigInt(i)));
    const firstStart = process.hrtime.bigint();
    assert.equal(kernel.psKernelCrossRun(kindNat, inputs[0]), true);
    const firstCallNs = elapsed(firstStart);
    for (let i = 0; i < warmup; i++) assert.equal(kernel.psKernelCrossRun(kindNat, inputs[i % 16]), true);
    let hits = 0;
    const timedStart = process.hrtime.bigint();
    for (let i = 0; i < iterations; i++) if (kernel.psKernelCrossRun(kindNat, inputs[i % 16])) hits++;
    const ns = elapsed(timedStart);
    assert.equal(hits, iterations);
    report.rows.push({ name: workloads[kind], kind, hits, ns, firstCallNs });
  }
  // Shared fixture admission semantics only. No public JS provider/JSON adapter exists yet.
  report.admissions = requestCases.map(({ count, bad }) => {
    const start = process.hrtime.bigint();
    const accepted = kernel.psKernelCrossAdmit(BigInt(count), bad);
    const ns = elapsed(start);
    assert.equal(accepted, !bad);
    return { count, bad, accepted, ns };
  });
} else if (mode === 'wasm') {
  const { createKernel } = await import('../packages/pskernel-lean-wasm/index.mjs');
  const healthStart = process.hrtime.bigint();
  const provider = await createKernel({ timeoutMs: 10_000 });
  report.healthRequestNs = elapsed(healthStart);
  report.identity = provider.metadata;
  report.admissions = [];
  for (const { count, bad } of requestCases) {
    const encodeStart = process.hrtime.bigint();
    const request = admissionRequest(count, bad);
    const encodeNs = elapsed(encodeStart);
    const start = process.hrtime.bigint();
    const result = await provider.checkCanonicalAdmissions(request);
    const ns = elapsed(start);
    assert.equal(result.accepted, !bad);
    if (bad) assert.equal(result.errorKind, 'kernel-rejection');
    report.admissions.push({ count, bad, accepted: result.accepted, ns, encodeNs, bytes: Buffer.byteLength(request) });
  }
} else throw Error('Expected js or wasm worker');
console.log(JSON.stringify(report));
