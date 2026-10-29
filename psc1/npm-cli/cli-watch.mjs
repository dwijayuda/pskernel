// Dependency-bounded watch supervision. No second compiler, cache or plugin loader.
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import {
  captureProject,
  captureIdentity,
  declaredWatchPaths,
  MAX_INPUT_BYTES,
  refuse,
} from './cli-project.mjs';
const intervalMs = 100;
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
function stamp(files) {
  return files
    .map((file) => {
      try {
        const s = fs.lstatSync(file, { bigint: true });
        return [
          file,
          s.dev,
          s.ino,
          s.mode,
          s.size,
          s.mtimeNs ?? s.mtimeMs,
          s.ctimeNs ?? s.ctimeMs,
        ].join(':');
      } catch (error) {
        return file + ':' + error.code;
      }
    })
    .join('\n');
}
export async function watchProject({ command, parsed, execute, diagnostic, mode }) {
  let files = declaredWatchPaths(parsed),
    previous = stamp(files),
    dirty = true;
  let changedAt = 0,
    stopped = 0,
    attempt = 0,
    lastSuccessfulCheck;
  const notify = (event, fields = {}) => {
    if (mode === 'json')
      process.stderr.write(
        JSON.stringify({
          schema: 'proofscript-watch-event/1',
          event,
          attempt,
          ...fields,
        }) + '\n',
      );
    else
      process.stderr.write(
        '[psc watch] ' +
          event +
          (fields.elapsedMs === undefined ? '' : ' (' + fields.elapsedMs + ' ms)') +
          '\n',
      );
  };
  const handlers = new Map(
    [
      ['SIGINT', 130],
      ['SIGTERM', 143],
      ...(process.platform === 'win32' ? [['SIGBREAK', 130]] : []),
    ].map(([signal, code]) => {
      const handler = () => {
        stopped = code;
      };
      process.on(signal, handler);
      return [signal, handler];
    }),
  );
  const poll = () => {
    const next = stamp(files);
    if (next !== previous) {
      previous = next;
      dirty = true;
      changedAt = Date.now();
    }
  };
  const timer = setInterval(poll, intervalMs);
  notify('watching', { intervalMs, files: files.length });
  try {
    while (!stopped) {
      if (!dirty || Date.now() - changedAt < intervalMs) {
        await sleep(25);
        continue;
      }
      dirty = false;
      try {
        files = declaredWatchPaths(parsed);
      } catch {
        /* retain config/old dependencies until repaired */
      }
      previous = stamp(files);
      let directory;
      const started = Date.now();
      attempt++;
      try {
        const captured = captureProject(parsed);
        const args = [];
        if (parsed.file) args.push(parsed.file);
        for (const [key, value] of parsed.options) args.push(key, value);
        const job = JSON.stringify({
          command,
          args,
          cwd: process.cwd(),
          captureIdentity: captureIdentity(captured),
        });
        // No new request or admission claim for a byte-identical successful check.
        // Builds still revalidate their publication; errors always clear this reuse.
        if (command === 'check' && job === lastSuccessfulCheck) {
          notify('unchanged', { logicalAdmission: 'not-run', previousResult: 'retained' });
          continue;
        }
        if (Buffer.byteLength(job) > MAX_INPUT_BYTES)
          refuse('INPUT_KIND_SIZE', 'Watch request exceeds 128 MiB.');
        directory = fs.mkdtempSync(path.join(os.tmpdir(), 'proofscript-watch-'));
        const file = path.join(directory, 'job.json');
        fs.writeFileSync(file, job, { flag: 'wx', mode: 0o600 });
        notify('checking');
        const code = await execute(
          [file, crypto.createHash('sha256').update(job).digest('hex')],
          mode,
          'cli-watch-worker.mjs',
        );
        if (stopped) break;
        lastSuccessfulCheck = command === 'check' && code === 0 ? job : undefined;
        notify(code === 0 ? 'ready' : 'failed; waiting for changes', {
          exitCode: code,
          elapsedMs: Date.now() - started,
        });
      } catch (error) {
        lastSuccessfulCheck = undefined;
        diagnostic(error, mode);
        notify('failed; waiting for changes', { elapsedMs: Date.now() - started });
      } finally {
        if (directory) fs.rmSync(directory, { recursive: true, force: true });
      }
      // Catch edits while a child was running, including atomic replacement.
      poll();
    }
    notify('stopped', { exitCode: stopped });
    return stopped;
  } finally {
    clearInterval(timer);
    for (const [signal, handler] of handlers) process.off(signal, handler);
  }
}
