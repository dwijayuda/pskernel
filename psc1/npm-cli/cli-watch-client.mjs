// Linux Node private worker supervisor. Other qualified hosts retain one-shot execution.
import { spawn } from 'node:child_process';
export function createWatchClient({ file, diagnostic, mode }) {
  let child,
    pending,
    serial = 0,
    attempts = 0,
    stderr = [],
    stderrBytes = 0,
    stdoutBytes = 0,
    deadline,
    signalCode;
  const stop = (signal) => {
    if (child?.pid)
      try {
        process.kill(-child.pid, signal);
      } catch (e) {
        if (e.code !== 'ESRCH') throw e;
      }
  };
  const complete = (code) => {
    clearTimeout(deadline);
    const error = Buffer.concat(stderr).toString('utf8');
    stderr = [];
    stderrBytes = 0;
    stdoutBytes = 0;
    if (error) {
      if (code) diagnostic(error, mode);
      else process.stderr.write(error);
    }
    const waiting = pending;
    pending = undefined;
    waiting?.resolve(code);
  };
  const onSignal = (signal) => {
    signalCode = signal === 'SIGINT' ? 130 : 143;
    stop('SIGKILL');
  };
  const signals = new Map(
    ['SIGINT', 'SIGTERM'].map((signal) => {
      const handler = () => onSignal(signal);
      process.on(signal, handler);
      return [signal, handler];
    }),
  );
  function start() {
    child = spawn(process.execPath, ['--max-old-space-size=4096', '--stack-size=8192', file], {
      detached: true,
      windowsHide: true,
      stdio: ['ignore', 'pipe', 'pipe', 'ipc'],
    });
    attempts = 0;
    signalCode = undefined;
    child.stdout.on('data', (bytes) => {
      stdoutBytes += bytes.length;
      if (stdoutBytes > 33554432) {
        diagnostic('PSC1_CLI_DIAGNOSTIC_LIMIT', mode);
        stop('SIGKILL');
      } else process.stdout.write(bytes);
    });
    child.stderr.on('data', (bytes) => {
      stderrBytes += bytes.length;
      if (stderrBytes > 33554432) stop('SIGKILL');
      else stderr.push(bytes);
    });
    child.on('message', (packet) => {
      if (!pending || packet?.id !== pending.id || ![0, 1].includes(packet.code)) {
        stop('SIGKILL');
        return;
      }
      const done = signalCode || packet.code;
      attempts++;
      if (attempts >= 64) {
        stop('SIGKILL');
        child = undefined;
      }
      complete(done);
    });
    child.on('error', (error) => {
      diagnostic(error, mode);
    });
    const launched = child;
    child.on('close', () => {
      if (child === launched) {
        child = undefined;
        if (pending) complete(signalCode || 1);
      }
    });
  }
  return Object.freeze({
    execute(args) {
      if (pending) throw Error('PSC1_WATCH_CONCURRENT_REQUEST');
      if (!child) start();
      return new Promise((resolve) => {
        pending = { id: ++serial, resolve };
        deadline = setTimeout(() => {
          diagnostic('PSC1_WATCH_REQUEST_TIMEOUT', mode);
          stop('SIGKILL');
        }, 240000);
        child.send({ id: serial, args }, (error) => {
          if (error) {
            diagnostic(error, mode);
            stop('SIGKILL');
          }
        });
      });
    },
    async close() {
      for (const [signal, handler] of signals) process.off(signal, handler);
      clearTimeout(deadline);
      if (!child) return;
      const closing = child;
      stop('SIGKILL');
      await new Promise((resolve) => {
        const timer = setTimeout(resolve, 2000);
        closing.once('close', () => {
          clearTimeout(timer);
          resolve();
        });
      });
    },
  });
}
