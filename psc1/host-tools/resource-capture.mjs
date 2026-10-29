// Coalesce identity reads only while constructing a synchronous host plan.
// No compiler, checker, target execution or publication occurs inside this scope.
// Every existing execution boundary remains. Outside setup, mutable resources
// are hashed fresh. The running-image optimization has a separate OS-backed
// identity proof in running-executable.mjs; neither path accepts mtime as identity.
import fs from 'node:fs';
import { runningExecutableIdentity } from './running-executable.mjs';
import crypto from 'node:crypto';
let active;
export function resourceIdentity(file) {
  const prior = active?.files.get(file);
  if (prior) {
    active.metrics.duplicateReadsAvoided++;
    active.metrics.duplicateBytesAvoided += prior.bytes;
    return prior;
  }
  const running = runningExecutableIdentity(file);
  if (running) {
    if (active) {
      active.files.set(file, running);
      active.metrics.runningExecutableBindings++;
    }
    return running;
  }
  const started = performance.now(),
    bytes = fs.readFileSync(file);
  const row = Object.freeze({
    bytes: bytes.length,
    sha256: crypto.createHash('sha256').update(bytes).digest('hex'),
  });
  if (active) {
    active.files.set(file, row);
    active.metrics.uniqueReads++;
    active.metrics.uniqueBytes += bytes.length;
    active.metrics.readAndHashMs += performance.now() - started;
  }
  return row;
}
export const resourceDigest = (file) => resourceIdentity(file).sha256;
export function captureResourceSetup(operation) {
  if (active) throw Error('PSC1_RESOURCE_CAPTURE_NESTED');
  const frame = {
    files: new Map(),
    metrics: {
      uniqueReads: 0,
      uniqueBytes: 0,
      duplicateReadsAvoided: 0,
      duplicateBytesAvoided: 0,
      readAndHashMs: 0,
      runningExecutableBindings: 0,
    },
  };
  active = frame;
  try {
    const value = operation();
    if (value && typeof value.then === 'function') throw Error('PSC1_RESOURCE_CAPTURE_ASYNC');
    return { value, metrics: Object.freeze({ ...frame.metrics }) };
  } finally {
    active = undefined;
  }
}
