#!/usr/bin/env node
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { realpath, lstat } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { spawn } from 'node:child_process';

const version = '0.1.0-preview.5';
const maxMessage = 2 * 1024 * 1024;
const maxDocument = 1024 * 1024;
const maxOpenBytes = 8 * 1024 * 1024;
const maxDocuments = 32;
const maxResponse = 1024 * 1024;
const digest = data => createHash('sha256').update(data).digest('hex');
const fallbackRange = { start: { line: 0, character: 0 }, end: { line: 0, character: 0 } };
const inside = (root, file) => {
  const relative = path.relative(root, file);
  return relative !== '..' && !relative.startsWith('..' + path.sep) && !path.isAbsolute(relative);
};

if (process.argv.length !== 3 || process.argv[2] !== '--stdio') {
  process.stderr.write('pslsp: usage: pslsp --stdio (stdio JSON-RPC only)\n');
  process.exit(2);
}

let compilerCli;
try {
  const pkg = createRequire(import.meta.url).resolve('proofscript/package.json');
  const meta = createRequire(import.meta.url)(pkg);
  if (meta.name !== 'proofscript' || meta.version !== version) {
    throw new Error('PSC_LSP_COMPILER_PIN');
  }
  compilerCli = path.join(path.dirname(pkg), 'bin/psc.mjs');
} catch (error) {
  process.stderr.write('pslsp: requires explicitly installed proofscript ' + version +
    ': ' + (error.message ?? error) + '\n');
  process.exit(2);
}

const docs = new Map();
let buffer = Buffer.alloc(0), initialized = false, shuttingDown = false;
let projectRoot = path.resolve(process.cwd());

function emit(value) {
  const body = Buffer.from(JSON.stringify(value), 'utf8');
  if (body.length > maxResponse) throw new Error('PSC_LSP_RESPONSE_LIMIT');
  process.stdout.write('Content-Length: ' + body.length + '\r\n\r\n');
  process.stdout.write(body);
}
const response = (id, result) => emit({ jsonrpc: '2.0', id, result });
const errorResponse = (id, code, message) =>
  emit({ jsonrpc: '2.0', id, error: { code, message } });
const notify = (method, params) => emit({ jsonrpc: '2.0', method, params });
const log = message => process.stderr.write('pslsp: ' + message + '\n');
function publish(uri, currentVersion, diagnostics) {
  notify('textDocument/publishDiagnostics', {
    uri, ...(Number.isSafeInteger(currentVersion) ? { version: currentVersion } : {}),
    diagnostics,
  });
}
function safeDiagnostic(message, source = 'ProofScript language server') {
  return { range: fallbackRange, source, severity: 2,
    code: 'PSC_LSP_CHECK_UNAVAILABLE', message: String(message).slice(0, 350) };
}
function validRange(range) {
  const validPosition = p => p && Number.isSafeInteger(p.line) && p.line >= 0 &&
    Number.isSafeInteger(p.character) && p.character >= 0;
  return validPosition(range?.start) && validPosition(range?.end) &&
    (range.end.line > range.start.line ||
     range.end.line === range.start.line && range.end.character >= range.start.character);
}

function endQuery(document) {
  clearTimeout(document.timer);
  document.generation++;
  if (document.child) {
    try { document.child.kill('SIGTERM'); } catch {}
    document.child = undefined;
  }
}
function queueQuery(document) {
  endQuery(document);
  const generation = document.generation;
  document.timer = setTimeout(() => {
    document.timer = undefined;
    void runQuery(document, generation);
  }, 140);
}
async function checkPath(uri) {
  let file;
  try {
    const url = new URL(uri);
    if (url.protocol !== 'file:') return null;
    file = path.resolve(fileURLToPath(url));
  } catch { return null; }
  if (!file.endsWith('.ps')) return null;
  const root = await realpath(projectRoot);
  const actual = await realpath(file);
  if (!inside(root, actual)) throw new Error('PSC_LSP_DOCUMENT_OUTSIDE_PROJECT');
  const status = await lstat(file);
  if (!status.isFile() || status.isSymbolicLink()) throw new Error('PSC_LSP_DOCUMENT_NOT_REGULAR');
  return file;
}

async function runQuery(doc, generation) {
  if (!initialized || shuttingDown || docs.get(doc.uri) !== doc ||
      doc.generation !== generation) return;
  let file;
  try { file = await checkPath(doc.uri); }
  catch (error) {
    if (docs.get(doc.uri) === doc && doc.generation === generation) {
      publish(doc.uri, doc.version, [safeDiagnostic(error.message)]);
    }
    return;
  }
  if (!file) return;
  if (Buffer.byteLength(doc.text, 'utf8') > maxDocument) {
    publish(doc.uri, doc.version, [safeDiagnostic('Document exceeds 1 MiB query limit')]);
    return;
  }
  // The compiler executes in an independent, bounded subprocess so an editor
  // change can cancel old work even if its checked provider uses synchronous IO.
  let child;
  try {
    child = spawn(process.execPath, [compilerCli, 'query', file, '--stdin', '--json'], {
      cwd: projectRoot, windowsHide: true, stdio: ['pipe', 'pipe', 'pipe'],
      env: { ...process.env },
    });
  } catch (error) {
    publish(doc.uri, doc.version, [safeDiagnostic('Unable to start compiler: ' + error.message)]);
    return;
  }
  doc.child = child;
  const currentVersion = doc.version;
  const sourceSha256 = digest(doc.text);
  let output = '', errors = '', settled = false;
  const timer = setTimeout(() => {
    try { child.kill('SIGKILL'); } catch {}
  }, 90000);
  const close = (code, cause) => {
    if (settled) return;
    settled = true; clearTimeout(timer);
    if (doc.child === child) doc.child = undefined;
    if (docs.get(doc.uri) !== doc || doc.generation !== generation || shuttingDown) return;
    if (cause || code !== 0) {
      publish(doc.uri, currentVersion, [safeDiagnostic('Checking unavailable: ' +
        (cause?.message ?? (errors.slice(-260) || ('compiler exited ' + code))))]);
      return;
    }
    let result;
    try {
      result = JSON.parse(output);
      if (result.kind !== 'psc-source-query/1' ||
          result.sourceSha256 !== sourceSha256 || result.entryPath !== file ||
          !['accepted', 'rejected', 'unavailable'].includes(result.status) ||
          !Array.isArray(result.diagnostics) || result.diagnostics.length > 10) {
        throw new Error('PSC_LSP_QUERY_RESPONSE');
      }
      if (result.status === 'accepted' && (result.kernelAdmissionAccepted !== true ||
          result.diagnostics.length !== 0)) throw new Error('PSC_LSP_QUERY_ACCEPTANCE');
    } catch (error) {
      publish(doc.uri, currentVersion, [safeDiagnostic('Malformed checked query result: ' + error.message)]);
      return;
    }
    const diagnostics = result.diagnostics.map(item => ({
      source: 'ProofScript', code: typeof item.code === 'string' ? item.code.slice(0, 100) : 'PSC_QUERY',
      severity: item.severity === 1 ? 1 : 2,
      message: typeof item.message === 'string' ? item.message.slice(0, 512) : 'ProofScript check unavailable',
      range: validRange(item.range) ? item.range : fallbackRange,
    }));
    publish(doc.uri, currentVersion, diagnostics);
  };
  child.on('error', error => close(null, error));
  child.on('close', code => close(code));
  child.stdout.on('data', data => {
    output += data.toString('utf8');
    if (Buffer.byteLength(output) > maxResponse) child.kill('SIGKILL');
  });
  child.stderr.on('data', data => {
    errors += data.toString('utf8');
    if (Buffer.byteLength(errors) > 8192) child.kill('SIGKILL');
  });
  child.stdin.on('error', () => {});
  child.stdin.end(doc.text);
}

function didOpen(params) {
  const item = params?.textDocument;
  if (!item || typeof item.uri !== 'string' || !item.uri.startsWith('file:') ||
      !item.uri.endsWith('.ps') || typeof item.text !== 'string' ||
      !Number.isSafeInteger(item.version) || item.version < 0) return;
  if (!docs.has(item.uri) && docs.size >= maxDocuments) {
    publish(item.uri, item.version, [safeDiagnostic('Maximum 32 open ProofScript documents')]);
    return;
  }
  const prior = docs.get(item.uri);
  if (prior) endQuery(prior);
  const doc = { uri: item.uri, version: item.version, text: item.text, generation: 0 };
  docs.set(doc.uri, doc);
  if ([...docs.values()].reduce((sum, x) => sum + Buffer.byteLength(x.text, 'utf8'), 0) > maxOpenBytes) {
    docs.delete(doc.uri);
    publish(doc.uri, doc.version, [safeDiagnostic('Maximum 8 MiB of open ProofScript documents')]);
    return;
  }
  queueQuery(doc);
}
function didChange(params) {
  const uri = params?.textDocument?.uri;
  const versionNumber = params?.textDocument?.version;
  const doc = docs.get(uri);
  if (!doc || !Number.isSafeInteger(versionNumber) || versionNumber <= doc.version ||
      !Array.isArray(params.contentChanges) || params.contentChanges.length !== 1 ||
      typeof params.contentChanges[0].text !== 'string' ||
      'range' in params.contentChanges[0]) return;
  const text = params.contentChanges[0].text;
  if (Buffer.byteLength(text, 'utf8') > maxDocument) {
    endQuery(doc); doc.version = versionNumber;
    publish(uri, versionNumber, [safeDiagnostic('Document exceeds 1 MiB query limit')]);
    return;
  }
  const total = [...docs.values()].reduce((sum, x) =>
    sum + Buffer.byteLength(x === doc ? text : x.text, 'utf8'), 0);
  if (total > maxOpenBytes) {
    endQuery(doc); doc.version = versionNumber;
    publish(uri, versionNumber, [safeDiagnostic('Maximum 8 MiB of open ProofScript documents')]);
    return;
  }
  doc.text = text; doc.version = versionNumber; queueQuery(doc);
}
function didClose(params) {
  const uri = params?.textDocument?.uri, doc = docs.get(uri);
  if (!doc) return;
  endQuery(doc);
  docs.delete(uri);
  publish(uri, undefined, []);
}
function processMessage(message) {
  if (!message || message.jsonrpc !== '2.0' || typeof message.method !== 'string') return;
  const id = message.id;
  const request = typeof id === 'string' || typeof id === 'number';
  if (message.method === 'initialize' && request && !initialized) {
    const uri = message.params?.rootUri;
    if (uri !== null && uri !== undefined) {
      try {
        const root = new URL(uri);
        if (root.protocol !== 'file:') throw Error('not file URI');
        projectRoot = path.resolve(fileURLToPath(root));
      } catch {
        errorResponse(id, -32602, 'PSC_LSP_ROOT_URI');
        return;
      }
    }
    initialized = true;
    response(id, {
      capabilities: { textDocumentSync: { openClose: true, change: 1 },
        hoverProvider: false, definitionProvider: false },
      serverInfo: { name: 'pslsp', version },
    });
    return;
  }
  if (!initialized) {
    if (request) errorResponse(id, -32002, 'Server not initialized');
    return;
  }
  if (message.method === 'shutdown' && request) {
    shuttingDown = true;
    for (const doc of docs.values()) endQuery(doc);
    response(id, null);
    return;
  }
  if (message.method === 'exit') {
    for (const doc of docs.values()) endQuery(doc);
    process.exit(shuttingDown ? 0 : 1);
  }
  if (shuttingDown) return;
  if (message.method === 'textDocument/didOpen') didOpen(message.params);
  else if (message.method === 'textDocument/didChange') didChange(message.params);
  else if (message.method === 'textDocument/didClose') didClose(message.params);
  else if (message.method === 'textDocument/didSave') {
    const doc = docs.get(message.params?.textDocument?.uri);
    if (doc) queueQuery(doc);
  } else if (message.method === 'workspace/didChangeWatchedFiles') {
    if (Array.isArray(message.params?.changes) &&
        message.params.changes.some(change => typeof change?.uri === 'string' &&
          change.uri.endsWith('.ps'))) {
      for (const doc of docs.values()) queueQuery(doc);
    }
  } else if (request) errorResponse(id, -32601, 'Method not supported');
}

const separator = Buffer.from('\r\n\r\n');
process.stdin.on('data', chunk => {
  buffer = Buffer.concat([buffer, chunk]);
  if (buffer.length > maxMessage + 8192) {
    log('incoming message limit exceeded'); process.exitCode = 2;
    process.stdin.pause(); return;
  }
  while (true) {
    const headerEnd = buffer.indexOf(separator);
    if (headerEnd < 0) {
      if (buffer.length > 4096) {
        log('header limit exceeded'); process.exitCode = 2; process.stdin.pause();
      }
      break;
    }
    if (headerEnd > 4096) {
      log('header limit exceeded'); process.exitCode = 2; process.stdin.pause(); break;
    }
    const header = buffer.subarray(0, headerEnd).toString('ascii');
    const found = /(?:^|\r\n)Content-Length: ([0-9]+)(?=\r\n|$)/iu.exec(header);
    const length = found ? Number(found[1]) : NaN;
    if (!Number.isSafeInteger(length) || length < 1 || length > maxMessage) {
      log('invalid content length'); process.exitCode = 2; process.stdin.pause(); break;
    }
    if (buffer.length < headerEnd + 4 + length) break;
    const payload = buffer.subarray(headerEnd + 4, headerEnd + 4 + length);
    buffer = buffer.subarray(headerEnd + 4 + length);
    try { processMessage(JSON.parse(payload.toString('utf8'))); }
    catch (error) {
      log('invalid JSON-RPC request: ' + error.message);
      errorResponse(null, -32700, 'Parse error');
    }
  }
});
process.stdin.on('end', () => {
  for (const doc of docs.values()) endQuery(doc);
});
