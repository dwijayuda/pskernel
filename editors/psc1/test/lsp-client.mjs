import {spawn} from 'node:child_process';
import {once} from 'node:events';

/** A real stdio JSON-RPC peer. It never synthesizes compiler responses. */
export class LspClient {
  constructor(entry, {cwd, env = process.env} = {}) {
    this.messages = [];
    this.messageTimes = [];
    this.stderr = '';
    this.nextId = 1;
    this.pending = new Map();
    this.waiters = new Set();
    this.buffer = Buffer.alloc(0);
    this.failure = null;
    this.process = spawn(process.execPath, [entry, '--stdio'], {
      cwd, env, stdio: ['pipe', 'pipe', 'pipe'], windowsHide: true,
    });
    this.process.stderr.on('data', bytes => {
      this.stderr = (this.stderr + bytes.toString('utf8')).slice(-128 * 1024);
    });
    this.process.on('error', error => this.fail(error));
    this.process.on('exit', (code, signal) => {
      this.exit = {code, signal};
      if (this.pending.size || this.waiters.size) {
        this.fail(new Error(`LSP exited (${code ?? signal}): ${this.stderr}`));
      }
    });
    this.process.stdout.on('data', bytes => {
      try { this.receive(bytes); } catch (error) { this.fail(error); }
    });
  }

  fail(error) {
    this.failure ||= error;
    for (const p of this.pending.values()) { clearTimeout(p.timer); p.reject(error); }
    for (const waiter of this.waiters) { clearTimeout(waiter.timer); waiter.reject(error); }
    this.pending.clear();
    this.waiters.clear();
  }

  receive(bytes) {
    this.buffer = Buffer.concat([this.buffer, bytes]);
    while (true) {
      const boundary = this.buffer.indexOf('\r\n\r\n');
      if (boundary < 0) {
        if (this.buffer.length > 8192) throw new Error('LSP emitted invalid/oversized header');
        return;
      }
      const header = this.buffer.subarray(0, boundary).toString('ascii');
      const match = /^Content-Length:\s*(\d+)\s*$/mi.exec(header);
      if (!match) throw new Error(`Non-protocol bytes on LSP stdout: ${header}`);
      const length = Number(match[1]);
      if (!Number.isSafeInteger(length) || length > 32 * 1024 * 1024) {
        throw new Error('LSP emitted invalid/oversized payload');
      }
      const end = boundary + 4 + length;
      if (this.buffer.length < end) return;
      const message = JSON.parse(this.buffer.subarray(boundary + 4, end).toString('utf8'));
      this.buffer = this.buffer.subarray(end);
      if (message.jsonrpc !== '2.0') throw new Error('Non-JSON-RPC2 message');
      const index = this.messages.push(message) - 1;
      this.messageTimes.push(performance.now());
      if (message.id !== undefined && !message.method) {
        const p = this.pending.get(message.id);
        if (p) {
          clearTimeout(p.timer);
          this.pending.delete(message.id);
          if (message.error) p.reject(Object.assign(new Error(message.error.message), message.error));
          else p.resolve(message.result);
        }
      }
      for (const waiter of [...this.waiters]) {
        if (index >= waiter.after && waiter.predicate(message)) {
          this.waiters.delete(waiter); clearTimeout(waiter.timer); waiter.resolve(message);
        }
      }
      // The minimal peer does not support server-initiated configuration, but
      // still answers requests instead of leaving the protocol hanging.
      if (message.method && message.id !== undefined) {
        const result = message.method === 'workspace/configuration'
          ? (message.params?.items ?? []).map(() => null) : null;
        this.send({jsonrpc: '2.0', id: message.id, result});
      }
    }
  }

  send(message) {
    if (this.failure) throw this.failure;
    const payload = Buffer.from(JSON.stringify(message), 'utf8');
    this.process.stdin.write(`Content-Length: ${payload.length}\r\n\r\n`);
    this.process.stdin.write(payload);
  }

  notify(method, params) { this.send({jsonrpc: '2.0', method, params}); }

  request(method, params, timeoutMs = 30000) {
    const id = this.nextId++;
    const promise = new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        this.pending.delete(id);
        reject(new Error(`LSP request timed out: ${method}\n${this.stderr}`));
      }, timeoutMs);
      this.pending.set(id, {resolve, reject, timer});
      try { this.send({jsonrpc: '2.0', id, method, params}); }
      catch (error) { clearTimeout(timer); this.pending.delete(id); reject(error); }
    });
    promise.requestId = id;
    return promise;
  }

  waitFor(predicate, {after = 0, timeoutMs = 60000} = {}) {
    const found = this.messages.slice(after).find(predicate);
    if (found) return Promise.resolve(found);
    if (this.failure) return Promise.reject(this.failure);
    return new Promise((resolve, reject) => {
      const waiter = {predicate, after, resolve, reject};
      waiter.timer = setTimeout(() => {
        this.waiters.delete(waiter);
        reject(new Error(`LSP notification timed out. Recent messages:\n${JSON.stringify(this.messages.slice(-8))}\n${this.stderr}`));
      }, timeoutMs);
      this.waiters.add(waiter);
    });
  }

  async shutdown() {
    await this.request('shutdown', null, 10000);
    const exited = this.exit ? Promise.resolve([this.exit.code, this.exit.signal]) : once(this.process, 'exit');
    this.notify('exit');
    const timer = setTimeout(() => this.process.kill('SIGKILL'), 10000);
    try { return await exited; } finally { clearTimeout(timer); }
  }

  dispose() {
    this.fail(new Error('LSP test peer disposed'));
    if (!this.exit) {
      this.process.kill('SIGTERM');
      setTimeout(() => { if (!this.exit) this.process.kill('SIGKILL'); }, 1000).unref();
    }
  }
}
