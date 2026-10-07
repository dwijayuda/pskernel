import { mkdtemp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { spawn } from 'node:child_process';
import { checkedSeedLimits, checkedSeedFrames, checkedSeedExhausted, checkSeedBytes } from './checked-seed-protocol.mjs';
import { decodeDeclarationOrigins } from './declaration-origins.mjs';
import { decodePublicApi } from './public-api-artifact.mjs';
import { createPscvCertification } from './certified-source.mjs';

function withTimeout(promise, timeoutMs, child, label) {
  let timer;
  const timeout = new Promise((_, reject) => {
    timer = setTimeout(() => {
      child.kill('SIGKILL');
      reject(Object.assign(checkedSeedExhausted('phaseTimeMs', timeoutMs), { phase: label }));
    }, timeoutMs);
  });
  return Promise.race([promise, timeout]).finally(() => clearTimeout(timer));
}

export async function runCheckedSeedSession({
  binaryPath,
  sourceKind,
  source,
  sources,
  checkAdmissions,
  emit,
  timeoutMs = 300000,
  resourceLimits,
  certificationContext,
}) {
  const limits = checkedSeedLimits(resourceLimits);
  if (!['lean', 'ps'].includes(sourceKind)) throw new Error('PSC2_CHECKED_SEED_SOURCE_KIND');
  if (typeof source !== 'string') throw new TypeError('Expected immutable source text');
  if (sources !== undefined && !Array.isArray(sources)) throw new Error('PSC2_CHECKED_SEED_SOURCE_PARTITION');
  const observation = { sourceBytes: checkSeedBytes(source, 'sourceBytes', limits),
    sourceCount: sources === undefined ? 1 : sources.length, snapshotBytes: 0,
    stdoutBytes: 0, stderrBytes: 0, frames: 0, largestFrameBytes: 0, admissionsBytes: 0, generatedBytes: 0 };
  if (!Number.isSafeInteger(observation.sourceCount) || observation.sourceCount > limits.sourceCount)
    throw checkedSeedExhausted('sourceCount', limits.sourceCount, observation.sourceCount);
  if (sources !== undefined && (!Array.isArray(sources) || sources.some(value => typeof value !== 'string') ||
      sources.join('\n\n') + '\n' !== source)) throw new Error('PSC2_CHECKED_SEED_SOURCE_PARTITION');
  if (typeof checkAdmissions !== 'function') throw new TypeError('Expected kernel checker');
  if (!Number.isSafeInteger(timeoutMs) || timeoutMs <= 0 || timeoutMs > 2147483647) throw new TypeError('timeoutMs must be a positive timer interval');

  const inputSources = Object.freeze(sources === undefined ? [source] : [...sources]);
  const snapshot = sources === undefined ? source : JSON.stringify(inputSources);
  observation.snapshotBytes = checkSeedBytes(snapshot, 'snapshotBytes', limits);

  const directory = await mkdtemp(path.join(tmpdir(), 'psc2-checked-seed-'));
  const sourceFile = path.join(directory, sources === undefined ? `snapshot.${sourceKind === 'ps' ? 'ps' : 'lean'}` : 'snapshot.json');
  let child, closed, didClose = false;
  const stderr = [];
  try {
    await writeFile(sourceFile, snapshot, 'utf8');
    child = spawn(path.resolve(binaryPath), [`--session-${sources === undefined ? '' : 'modules-'}${sourceKind}`, sourceFile], {
      stdio: ['pipe', 'pipe', 'pipe'],
      windowsHide: true,
    });
    let rejectFailure, firstFailure;
    const failure = new Promise((_, reject) => { rejectFailure = reject; });
    failure.catch(() => {}); // Failure may arrive between awaited phases.
    const fail = error => {
      if (firstFailure) return;
      firstFailure = error; child.kill('SIGKILL'); rejectFailure(error);
    };
    child.stderr.on('data', chunk => {
      if (firstFailure) return;
      observation.stderrBytes += chunk.length;
      if (observation.stderrBytes > limits.stderrBytes)
        fail(checkedSeedExhausted('stderrBytes', limits.stderrBytes, observation.stderrBytes));
      else stderr.push(chunk);
    });
    child.stdin.on('error', fail);
    child.stderr.on('error', fail);
    child.once('error', fail);
    closed = new Promise(resolve => {
      child.once('close', (code, signal) => { didClose = true; resolve({ code, signal }); });
    });
    const iterator = checkedSeedFrames(child.stdout, limits, observation);
    const phase = (promise, label) => withTimeout(Promise.race([promise, failure]), timeoutMs, child, label);
    async function nextFrame(label) {
      const next = await phase(iterator.next(), label);
      if (next.done) throw new Error('PSC2_CHECKED_SEED_SESSION_EOF: ' + label);
      return next.value;
    }

    const prepared = await nextFrame('prepared');
    if (prepared?.phase !== 'prepared' || typeof prepared.admissions !== 'string') {
      throw new Error('PSC2_CHECKED_SEED_SESSION_PREPARED_RESULT');
    }

    observation.admissionsBytes = checkSeedBytes(prepared.admissions, 'admissionsBytes', limits);
    const kernelResult = await phase(Promise.resolve().then(() => checkAdmissions(prepared.admissions)), 'kernel-check');
    if (kernelResult?.accepted !== true) {
      throw new Error(`PSC2_KERNEL_REJECTED: ${kernelResult?.errorKind ?? 'kernel-rejection'}`);
    }

    let certification;
    if (certificationContext !== undefined) {
      const expected = certificationContext.provider;
      if (!expected || typeof expected !== 'object') throw new Error('PSC2_CHECKED_SEED_CERT_PROVIDER');
      for (const [field, value] of Object.entries(expected)) {
        if (kernelResult?.[field] !== value) throw new Error('PSC2_CHECKED_SEED_PROVIDER_IDENTITY: ' + field);
      }
      certification = createPscvCertification({
        source,
        admissions: prepared.admissions,
        semanticProfile: expected.profile,
        kernelContract: certificationContext.kernelContract,
        provider: expected,
        providerSecurity: certificationContext.providerSecurity,
        assumptionPolicy: certificationContext.assumptionPolicy,
        resourcePolicy: certificationContext.resourcePolicy,
        targets: certificationContext.targets,
        executionBoundary: certificationContext.executionBoundary,
      });
    }

    child.stdin.end(emit ? 'emit\n' : 'checked\n');
    const completed = await nextFrame(emit ? 'emitted' : 'checked');
    if (emit) {
      if (completed?.phase !== 'emitted' || typeof completed.typescript !== 'string') {
        throw new Error('PSC2_CHECKED_SEED_SESSION_EMIT_RESULT');
      }
      if ((completed.runtimeIr !== undefined || completed.verifiedIr !== undefined) &&
          (typeof completed.runtimeIr !== 'string' || typeof completed.verifiedIr !== 'string')) {
        throw new Error('PSC2_CHECKED_SEED_SESSION_STAGES_RESULT');
      }
      if (Object.hasOwn(completed, 'publicApi') && typeof completed.publicApi !== 'string')
        throw new Error('PSC2_CHECKED_SEED_SESSION_PUBLIC_API_RESULT');
      if (Object.hasOwn(completed, 'declarationOrigins') &&
          (typeof completed.declarationOrigins !== 'string' || typeof completed.publicApi !== 'string'))
        throw new Error('PSC2_CHECKED_SEED_SESSION_ORIGINS_RESULT');
      observation.generatedBytes = Buffer.byteLength(completed.declarationOrigins ?? '') + Buffer.byteLength(completed.publicApi ?? '') + Buffer.byteLength(completed.typescript) +
        Buffer.byteLength(completed.runtimeIr ?? '') + Buffer.byteLength(completed.verifiedIr ?? '');
      if (observation.generatedBytes > limits.generatedBytes)
        throw checkedSeedExhausted('generatedBytes', limits.generatedBytes, observation.generatedBytes);
      if (completed.declarationOrigins !== undefined) decodeDeclarationOrigins(Buffer.from(completed.declarationOrigins),
        { sources: inputSources, publicApi: Buffer.from(completed.publicApi), maxBytes: limits.generatedBytes });
      if (completed.publicApi !== undefined) decodePublicApi(Buffer.from(completed.publicApi), { maxBytes: limits.generatedBytes });
    } else if (completed?.phase !== 'checked') {
      throw new Error('PSC2_CHECKED_SEED_SESSION_CHECK_RESULT');
    }

    if (!(await phase(iterator.next(), 'end-of-stream')).done) throw new Error('PSC2_CHECKED_SEED_SESSION_EXTRA_FRAME');
    const status = await phase(closed, 'close');
    if (status.code !== 0) {
      throw new Error(`PSC2_CHECKED_SEED_SESSION_FAILED: ${status.signal || status.code}`);
    }
    return Object.freeze({
      admissions: prepared.admissions,
      resourceObservation: Object.freeze({ contract: 'psc-checked-seed-resources/1',
        limits: Object.freeze({ ...limits, phaseTimeMs: timeoutMs }), observed: Object.freeze({ ...observation }),
        unobserved: Object.freeze(['compiler-internal-work', 'cpu-time', 'peak-memory', 'descendants', 'host-stack']) }),
      ...(emit ? { typeScript: completed.typescript } : {}),
      ...(emit && completed.publicApi !== undefined ? { publicApi: completed.publicApi } : {}),
      ...(emit && completed.declarationOrigins !== undefined ? { declarationOrigins: completed.declarationOrigins } : {}),
      ...(emit && completed.runtimeIr !== undefined
        ? { stages: Object.freeze({ runtimeIr: completed.runtimeIr, verifiedIr: completed.verifiedIr }) } : {}),
      ...(certification ? {
        pscvCertificate: certification.certificate,
        certifiedSourceArtifact: certification.certifiedSource,
      } : {}),
    });
  } catch (error) {
    if (child && child.exitCode === null) child.kill('SIGKILL');
    const diagnostic = Buffer.concat(stderr).toString('utf8').trim().slice(0, 2000);
    if (diagnostic && !String(error.message).includes(diagnostic)) {
      error.message += ` | seed: ${diagnostic}`;
    }
    throw error;
  } finally {
    if (child && !didClose) {
      child.kill('SIGKILL');
      let timer;
      const confirmed = await Promise.race([closed.then(() => true),
        new Promise(resolve => { timer = setTimeout(() => resolve(false), limits.terminationGraceMs); })]);
      clearTimeout(timer);
      if (!confirmed) throw Object.assign(new Error('PSC2_CHECKED_SEED_TERMINATION_UNCONFIRMED'),
        { kind: 'infrastructureUnavailable' });
    }
    await rm(directory, { recursive: true, force: true });
  }
}
