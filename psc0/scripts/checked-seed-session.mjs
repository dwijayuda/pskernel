import { mkdir, mkdtemp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { spawn } from 'node:child_process';
import { createInterface } from 'node:readline';

function withTimeout(promise, timeoutMs, child, label) {
  let timer;
  const timeout = new Promise((_, reject) => {
    timer = setTimeout(() => {
      child.kill('SIGKILL');
      reject(new Error(`PSC2_CHECKED_SEED_SESSION_TIMEOUT: ${label}`));
    }, timeoutMs);
  });
  return Promise.race([promise, timeout]).finally(() => clearTimeout(timer));
}

async function nextJsonLine(iterator, child, timeoutMs, label) {
  const next = await withTimeout(iterator.next(), timeoutMs, child, label);
  if (next.done) throw new Error(`PSC2_CHECKED_SEED_SESSION_EOF: ${label}`);
  try {
    return JSON.parse(next.value);
  } catch (cause) {
    throw new Error(`PSC2_CHECKED_SEED_SESSION_JSON: ${label}`, { cause });
  }
}

export async function runCheckedSeedSession({
  binaryPath,
  sourceKind,
  source,
  sources,
  checkAdmissions,
  emit,
  timeoutMs = 300000,
}) {
  if (!['lean', 'ps'].includes(sourceKind)) throw new Error('PSC2_CHECKED_SEED_SOURCE_KIND');
  if (typeof source !== 'string') throw new TypeError('Expected immutable source text');
  if (sources !== undefined && (!Array.isArray(sources) || sources.some(value => typeof value !== 'string') ||
      sources.join('\n\n') + '\n' !== source)) throw new Error('PSC2_CHECKED_SEED_SOURCE_PARTITION');
  if (typeof checkAdmissions !== 'function') throw new TypeError('Expected kernel checker');
  if (!Number.isSafeInteger(timeoutMs) || timeoutMs <= 0) throw new TypeError('timeoutMs must be positive');

  const directory = await mkdtemp(path.join(tmpdir(), 'psc2-checked-seed-'));
  const sourceFile = path.join(directory, sources === undefined ? `snapshot.${sourceKind === 'ps' ? 'ps' : 'lean'}` : 'snapshot.json');
  await writeFile(sourceFile, sources === undefined ? source : JSON.stringify(sources), 'utf8');
  let child;
  let stderr = '';
  try {
    child = spawn(path.resolve(binaryPath), [`--session-${sources === undefined ? '' : 'modules-'}${sourceKind}`, sourceFile], {
      stdio: ['pipe', 'pipe', 'pipe'],
      windowsHide: true,
    });
    child.stderr.setEncoding('utf8');
    child.stderr.on('data', chunk => {
      if (stderr.length < 4 * 1024 * 1024) stderr += chunk;
    });
    const closed = new Promise((resolve, reject) => {
      child.once('error', reject);
      child.once('close', (code, signal) => resolve({ code, signal }));
    });
    const lines = createInterface({ input: child.stdout, crlfDelay: Infinity });
    const iterator = lines[Symbol.asyncIterator]();

    const prepared = await nextJsonLine(iterator, child, timeoutMs, 'prepared');
    if (prepared?.phase !== 'prepared' || typeof prepared.admissions !== 'string') {
      throw new Error('PSC2_CHECKED_SEED_SESSION_PREPARED_RESULT');
    }

    const kernelResult = await checkAdmissions(prepared.admissions);
    if (kernelResult?.accepted !== true) {
      // Reproduce any full-corpus rejection without modifying kernel semantics.
      // The full canonical request is written only to an explicitly selected
      // diagnostic path, never into a successful checked artifact.
      const diagnosticPath = process.env.PSC0_DIAGNOSTIC_ADMISSIONS;
      if (diagnosticPath) {
        const destination = path.resolve(diagnosticPath);
        await mkdir(path.dirname(destination), { recursive: true });
        await writeFile(destination, prepared.admissions, 'utf8');
      }
      const entryIndex = kernelResult?.declarationIndex;
      let declarationName = '';
      if (Number.isSafeInteger(entryIndex) && entryIndex >= 0) {
        try {
          const request = JSON.parse(prepared.admissions).admissions?.[entryIndex];
          const name = request?.kind === 'inductive'
            ? request?.declaration?.ts?.[0]?.n : request?.declaration?.n;
          const parts = []; let current = name;
          for (let depth = 0; depth < 64 && current && typeof current === 'object'; depth++) {
            if (current.k === 'a') break;
            if (current.k !== 's' && current.k !== 'n') break;
            parts.push(String(current.v));
            current = current.p;
          }
          if (parts.length) declarationName = ' declaration=' + JSON.stringify(parts.reverse().join('.'));
        } catch { /* The native checker already rejects malformed wire data. */ }
      }
      const errorKind = kernelResult?.errorKind ?? 'kernel-rejection';
      const declarationIndex = Number.isSafeInteger(kernelResult?.declarationIndex) &&
        kernelResult.declarationIndex >= 0 ? ` declarationIndex=${kernelResult.declarationIndex}` : '';
      const message = typeof kernelResult?.message === 'string'
        ? ` message=${JSON.stringify(kernelResult.message.slice(0, 1024))}` : '';
      throw new Error(`PSC2_KERNEL_REJECTED: ${errorKind}${declarationIndex}${message}`);
    }

    child.stdin.end(emit ? 'emit\n' : 'checked\n');
    const completed = await nextJsonLine(iterator, child, timeoutMs, emit ? 'emitted' : 'checked');
    if (emit) {
      if (completed?.phase !== 'emitted' || typeof completed.typescript !== 'string') {
        throw new Error('PSC2_CHECKED_SEED_SESSION_EMIT_RESULT');
      }
    } else if (completed?.phase !== 'checked') {
      throw new Error('PSC2_CHECKED_SEED_SESSION_CHECK_RESULT');
    }

    const status = await withTimeout(closed, timeoutMs, child, 'close');
    lines.close();
    if (status.code !== 0) {
      throw new Error(`PSC2_CHECKED_SEED_SESSION_FAILED: ${stderr.trim() || status.signal || status.code}`);
    }
    return Object.freeze({
      admissions: prepared.admissions,
      ...(emit ? { typeScript: completed.typescript } : {}),
    });
  } catch (error) {
    if (child && child.exitCode === null) child.kill('SIGKILL');
    if (stderr && !String(error.message).includes(stderr.trim())) {
      error.message += ` | seed: ${stderr.trim().slice(0, 2000)}`;
    }
    throw error;
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
}
