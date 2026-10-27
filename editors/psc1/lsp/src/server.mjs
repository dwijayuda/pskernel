import path from 'node:path';
import fs from 'node:fs';
import os from 'node:os';
import { fork } from 'node:child_process';
import { createConnection, TextDocuments, TextDocumentSyncKind, ResponseError, LSPErrorCodes } from 'vscode-languageserver/node';
import { TextDocument } from 'vscode-languageserver-textdocument';
import { loadProject } from './project.mjs';
import { keywords, outline, wordAt, lexicalHighlights, originDeclarations, compilerPosition, contains, importAt } from './syntax.mjs';

// esbuild bundles this entry as CommonJS. All executable paths are installation-owned.
const distribution = path.resolve(__dirname, '..');
const connection = createConnection(process.stdin, process.stdout);
const documents = new TextDocuments(TextDocument);
const states = new Map(), projects = new Map(), published = new Set();
const temporaryDirectories = new Set();
const settings = { trusted: false, enableLean: false, debounceMs: 350, timeoutMs: 30000 };
let workspaceFolders = [], generation = 0, timer, running, shutdown = false, semanticRefresh = false, workspaceFolderEvents = false;
const metrics = { checksStarted: 0, checksCompleted: 0, superseded: 0, timeouts: 0, lastElapsedMs: null };
const MAX_OPEN_DOCUMENTS = 64;
const MAX_EDITOR_CHARACTERS = 8 * 1024 * 1024;
const smallDocument = doc => doc && doc.getText().length <= MAX_EDITOR_CHARACTERS;

function supported(doc) {
  return doc?.uri.startsWith('file:') && (doc.uri.endsWith('.ps') ||
    (settings.enableLean && doc.uri.endsWith('.lean') && ['proofscript-lean', 'lean'].includes(doc.languageId)));
}
function updateSettings(value = {}) {
  if (typeof value.trusted === 'boolean') settings.trusted = value.trusted;
  if (typeof value.enableLean === 'boolean') settings.enableLean = value.enableLean;
  for (const [name, minimum, maximum] of [['debounceMs', 0, 2000], ['timeoutMs', 1000, 120000]])
    if (Number.isFinite(value[name])) settings[name] = Math.max(minimum, Math.min(maximum, value[name]));
}
function sendDiagnostics(uri, diagnostics = []) {
  const version = documents.get(uri)?.version;
  connection.sendDiagnostics({ uri, ...(version !== undefined ? { version } : {}), diagnostics });
  if (diagnostics.length) published.add(uri); else published.delete(uri);
}
function setState(doc, state, summary, extra = {}) {
  if (!doc || shutdown) return;
  const status = { uri: doc.uri, version: doc.version, projectGeneration: generation,
    state, summary, diagnostics: [], declarations: [], goalsAvailable: false, ...extra };
  states.set(doc.uri, status);
  connection.sendNotification('psc1/documentStatus', status);
}
function killRunning() {
  if (!running) return;
  metrics.superseded++;
  running.cancel();
  running = undefined;
}
function invalidate() {
  if (shutdown) return;
  generation++;
  clearTimeout(timer);
  killRunning();
  projects.clear();
  for (const uri of [...published]) sendDiagnostics(uri);
  for (const doc of documents.all()) {
    if (!supported(doc)) setState(doc, 'unsupported', 'Use a .ps file or explicitly select PSC1 for a project .lean file.');
    else if (!settings.trusted) setState(doc, 'untrusted', 'Trust this workspace to run the bundled PSC1 compiler. Syntax outline remains available.');
    else setState(doc, 'pending', 'Waiting for the current source snapshot.');
  }
  if (settings.trusted) timer = setTimeout(() => void checkGeneration(generation), settings.debounceMs);
}
function compilerJob(project) {
  const temporary = fs.mkdtempSync(path.join(os.tmpdir(), 'psc1-lsp-'));
  temporaryDirectories.add(temporary);
  let child, settled = false, timeout, stderr = '';
  let finish;
  const promise = new Promise(resolve => { finish = value => {
    if (settled) return;
    settled = true;
    clearTimeout(timeout);
    if (child?.pid) {
      try { if (process.platform !== 'win32') process.kill(-child.pid, 'SIGKILL'); else child.kill('SIGKILL'); } catch { /* Already exited. */ }
    }
    // Child temp directories stay within this private per-job directory.
    setTimeout(() => fs.rm(temporary, { recursive: true, force: true }, () => temporaryDirectories.delete(temporary)), 100).unref();
    resolve(value);
  }; });
  try {
    child = fork(path.join(distribution, 'dist/worker.mjs'), [], {
      cwd: distribution, detached: process.platform !== 'win32', windowsHide: true,
      execArgv: ['--max-old-space-size=1024'],
      env: { ...process.env, NODE_OPTIONS: '', TMPDIR: temporary, TMP: temporary, TEMP: temporary, ELECTRON_RUN_AS_NODE: '1' },
      stdio: ['ignore', 'ignore', 'pipe', 'ipc'],
    });
    child.stderr.on('data', chunk => { stderr = (stderr + chunk.toString()).slice(-8192); });
    child.once('message', value => {
      if (!value || typeof value !== 'object' || !['checked', 'partial', 'rejected', 'error'].includes(value.state))
        finish({ state: 'error', summary: 'Invalid compiler adapter response.', diagnostics: [], declarations: [] });
      else finish(value);
    });
    child.once('error', error => finish({ state: 'error', summary: 'Compiler process failed: ' + error.message, diagnostics: [], declarations: [] }));
    child.once('exit', (code, signal) => finish({ state: 'error', summary: `Compiler process exited (${signal || code}). ${stderr}`.slice(0, 4096), diagnostics: [], declarations: [] }));
    timeout = setTimeout(() => {
      metrics.timeouts++;
      finish({ state: 'error', summary: `Checking exceeded ${settings.timeoutMs} ms; no verification result was accepted.`, diagnostics: [], declarations: [] });
    }, settings.timeoutMs);
    child.send({ sources: project.sources, entryModule: project.entryModule, assurance: project.assurance || 'checked' }, error => {
      if (error) finish({ state: 'error', summary: 'Cannot send compiler snapshot: ' + error.message, diagnostics: [], declarations: [] });
    });
  } catch (error) { finish({ state: 'error', summary: error.message, diagnostics: [], declarations: [] }); }
  return { promise, cancel: () => finish(null) };
}

function diagnosticFor(file, row) {
  const start = compilerPosition(file.text, row.line, row.column);
  const precision = row.precision || (row.line ? 'declaration' : 'module');
  return { range: { start, end: start }, severity: row.severity || 1,
    source: 'PSC1', code: row.code || 'PSC1_CHECK',
    message: String(row.message || row.code || 'Compiler rejected the source.') +
      (precision === 'module' ? '\nThe compiler did not provide a precise source position.' : ''),
    data: { precision, module: row.module, projectGeneration: generation } };
}
async function checkGeneration(expected) {
  const current = () => expected === generation && !shutdown && settings.trusted;
  const all = documents.all().filter(supported);
  if (all.length > MAX_OPEN_DOCUMENTS) {
    for (const doc of all) setState(doc, 'error', `At most ${MAX_OPEN_DOCUMENTS} source documents may be open for checking.`);
    return;
  }
  const snapshots = new Map();
  for (const doc of all) {
    if (!current()) return;
    if ([...snapshots.values()].some(project => project.files.some(file => file.uri === doc.uri))) continue;
    try {
      const project = await loadProject(doc.uri, new Map(documents.all().map(d => [d.uri, d])), workspaceFolders);
      if (!current()) return;
      if (!snapshots.has(project.key)) snapshots.set(project.key, project);
    } catch (error) {
      if (!current()) return;
      const diagnostic = { range: { start: { line: 0, character: 0 }, end: { line: 0, character: 0 } }, severity: 1,
        source: 'PSC1 project', code: error.code || 'PSC1_PROJECT', message: String(error.message || error) };
      sendDiagnostics(doc.uri, [diagnostic]);
      setState(doc, 'error', 'Project loading failed.', { diagnostics: [diagnostic] });
    }
  }
  for (const project of snapshots.values()) {
    if (!current()) return;
    for (const file of project.files) {
      const doc = documents.get(file.uri);
      if (doc) setState(doc, 'checking', 'PSC1 compilation and independent Lean kernel checking are running.');
    }
    metrics.checksStarted++;
    const job = compilerJob(project);
    running = job;
    const result = await job.promise;
    if (running === job) running = undefined;
    if (!current() || !result) return;
    metrics.checksCompleted++;
    metrics.lastElapsedMs = result.elapsedMs ?? null;
    const mapped = new Map();
    for (const file of project.files) {
      const doc = documents.get(file.uri) || TextDocument.create(file.uri, file.uri.endsWith('.ps') ? 'proofscript' : 'proofscript-lean', 0, file.text);
      const ds = (result.declarations || []).filter(d => d.module === file.module).sort((a, b) => a.line - b.line || a.column - b.column);
      mapped.set(file.uri, originDeclarations(doc, ds));
    }
    projects.set(project.key, { project, result, mapped, generation: expected });
    const unattributed = (result.diagnostics || []).filter(d => !project.files.some(f => f.module === d.module));
    for (const file of project.files) {
      const rows = (result.diagnostics || []).filter(d => d.module === file.module);
      if (file.module === project.entryModule) rows.push(...unattributed);
      let diagnostics = rows.map(row => diagnosticFor(file, row));
      if (file.module === project.entryModule && ['error', 'rejected'].includes(result.state) && !diagnostics.length)
        diagnostics = [diagnosticFor(file, { message: result.summary, code: 'PSC1_CHECK', precision: 'module' })];
      sendDiagnostics(file.uri, diagnostics);
      const doc = documents.get(file.uri);
      if (doc) setState(doc, result.state, result.summary, { diagnostics, declarations: mapped.get(file.uri),
        elapsedMs: result.elapsedMs, receipt: result.receipt, compilerVersion: result.compilerVersion,
        project: { root: project.root, entryModule: project.entryModule, modules: project.files.map(f => f.module) } });
    }
    if (semanticRefresh) connection.languages.semanticTokens.refresh().catch(() => {});
  }
}

function currentState(uri) {
  const doc = documents.get(uri), state = states.get(uri);
  return doc && state?.version === doc.version && state.projectGeneration === generation ? state : null;
}
function declarationKind(d) {
  return ['structure', 'class', 'inductive'].includes(d.kind) ? 23 : ['theorem', 'lemma', 'axiom'].includes(d.kind) ? 14 : 12;
}
function getOutline(doc) {
  if (!smallDocument(doc)) return [];
  const state = currentState(doc.uri);
  return state?.declarations?.length ? state.declarations : outline(doc);
}
function checkedDeclarations(uri) {
  for (const value of projects.values()) if (value.generation === generation && value.project.files.some(f => f.uri === uri))
    return [...value.mapped.values()].flat();
  return [];
}
function ensureNotCancelled(token) {
  if (token?.isCancellationRequested) throw new ResponseError(LSPErrorCodes.RequestCancelled, 'Request cancelled.');
}
connection.onInitialize(params => {
  workspaceFolders = params.workspaceFolders || (params.rootUri ? [{ uri: params.rootUri, name: 'workspace' }] : []);
  updateSettings(params.initializationOptions);
  semanticRefresh = params.capabilities?.workspace?.semanticTokens?.refreshSupport === true;
  workspaceFolderEvents = params.capabilities?.workspace?.workspaceFolders === true;
  return { serverInfo: { name: 'PSC1 Language Server', version: '0.1.0' }, capabilities: {
    positionEncoding: 'utf-16', textDocumentSync: { openClose: true, change: TextDocumentSyncKind.Incremental, save: { includeText: false } },
    hoverProvider: true, definitionProvider: true, documentSymbolProvider: true,
    workspaceSymbolProvider: true, documentHighlightProvider: true,
    completionProvider: { resolveProvider: false, triggerCharacters: ['.'] },
    semanticTokensProvider: { legend: { tokenTypes: ['function', 'type', 'variable'], tokenModifiers: ['declaration'] }, full: true },
    workspace: { workspaceFolders: { supported: true, changeNotifications: workspaceFolderEvents } },
  } };
});
connection.onInitialized(() => {
  if (workspaceFolderEvents) connection.workspace.onDidChangeWorkspaceFolders(event => {
    workspaceFolders = workspaceFolders.filter(f => !event.removed.some(r => r.uri === f.uri)).concat(event.added);
    invalidate();
  });
});
connection.onNotification('psc1/configuration', value => { updateSettings(value); invalidate(); });
connection.onDidChangeConfiguration(params => { updateSettings(params.settings?.proofscript || params.settings || {}); invalidate(); });
connection.onDidChangeWatchedFiles(() => invalidate());
documents.onDidChangeContent(() => invalidate());
documents.onDidSave(() => invalidate());
documents.onDidClose(({ document }) => {
  sendDiagnostics(document.uri);
  states.delete(document.uri);
  invalidate();
});
connection.onRequest('psc1/recheck', () => { invalidate(); return { scheduled: true, projectGeneration: generation }; });
connection.onRequest('psc1/serverInfo', () => ({ name: 'PSC1 Language Server', version: '0.1.0',
  protocol: 'LSP over stdio', node: process.version, platform: process.platform,
  compiler: 'proofscript@0.1.0-psc1.12', kernel: 'official Lean 4.35.0, linear-memory Wasm',
  compilerTarballSha256: '9a66dcd0f92aaa60f600674fb91b31bc0d67b211d1e9e004146baa8e96502fcc',
  compilerSourceUnchanged: true, selfHosting: 'external tooling', settings, metrics,
  limitations: ['No proof-state snapshots or term-level type inference.', 'No binding-aware references, rename, signature help or quick fixes.',
    'Definitions navigate compiler-origin declarations and explicit imports; reference binding is not guessed.', 'Parse errors may have module-level locations.'],
}));
connection.onRequest('psc1/infoview', (params, token) => {
  ensureNotCancelled(token);
  const doc = documents.get(params.textDocument?.uri);
  if (!smallDocument(doc)) return null;
  if (params.version !== undefined && params.version !== doc.version)
    throw new ResponseError(LSPErrorCodes.ContentModified, 'Document version changed.');
  const state = currentState(doc.uri) || { uri: doc.uri, version: doc.version, projectGeneration: generation, state: 'pending', summary: 'No current result.', diagnostics: [], declarations: [] };
  const position = params.position || { line: 0, character: 0 };
  const selected = getOutline(doc).find(d => contains(d.selectionRange, position)) ||
    [...getOutline(doc)].reverse().find(d => contains(d.range, position)) || null;
  return { ...state, declaration: selected, goalsAvailable: false, messages: state.diagnostics,
    goalsMessage: 'This compiler distribution does not expose interactive proof-state snapshots.' };
});
connection.onDocumentSymbol((params, token) => {
  ensureNotCancelled(token);
  const doc = documents.get(params.textDocument.uri);
  return !doc ? [] : getOutline(doc).map(d => ({ name: d.name, kind: declarationKind(d), range: d.range, selectionRange: d.selectionRange,
    detail: d.verified ? 'Independent kernel checked' : d.syntaxOnly ? 'Syntax outline; not checked' : 'Not independently admitted' }));
});
connection.onWorkspaceSymbol((params, token) => {
  ensureNotCancelled(token);
  const result = [];
  for (const doc of documents.all()) for (const d of getOutline(doc)) if (d.name.toLowerCase().includes((params.query || '').toLowerCase())) {
    result.push({ name: d.name, kind: declarationKind(d), location: { uri: doc.uri, range: d.selectionRange }, containerName: d.syntaxOnly ? 'Syntax outline' : d.module });
    if (result.length >= 1000) return result;
  }
  return result;
});
connection.onHover((params, token) => {
  ensureNotCancelled(token);
  const doc = documents.get(params.textDocument.uri);
  if (!smallDocument(doc)) return null;
  const word = wordAt(doc, params.position);
  if (!word) return null;
  const direct = getOutline(doc).find(d => contains(d.selectionRange, params.position));
  const matches = checkedDeclarations(doc.uri).filter(d => d.name === word.name);
  const declaration = direct || (matches.length === 1 ? matches[0] : null);
  if (!declaration) return null;
  const content = [declaration.name, declaration.type ? `Elaborated declaration type: ${declaration.type}` : 'Type information is unavailable.',
    declaration.verified ? 'Independent Lean kernel admission accepted for this declaration in the current captured project.' : 'This declaration is not independently verified.',
    direct ? '' : 'Declaration lookup by exact spelling; the compiler does not expose reference binding.',
    declaration.syntaxOnly ? 'Syntax outline only.' : ''].filter(Boolean).join('\n\n');
  return { contents: { kind: 'plaintext', value: content }, range: word.range };
});
connection.onDefinition((params, token) => {
  ensureNotCancelled(token);
  const doc = documents.get(params.textDocument.uri);
  if (!smallDocument(doc)) return null;
  const imported = importAt(doc, params.position);
  for (const { project } of projects.values()) if (project.files.some(f => f.uri === doc.uri) && imported) {
    const file = project.files.find(f => f.module === imported);
    if (file) return { uri: file.uri, range: { start: { line: 0, character: 0 }, end: { line: 0, character: 0 } } };
  }
  const declaration = getOutline(doc).find(d => !d.syntaxOnly && contains(d.selectionRange, params.position));
  return declaration ? { uri: doc.uri, range: declaration.selectionRange } : null;
});
connection.onCompletion((params, token) => {
  ensureNotCancelled(token);
  const doc = documents.get(params.textDocument.uri);
  const declarations = doc ? checkedDeclarations(doc.uri) : [];
  const result = keywords.map(label => ({ label, kind: 14, detail: 'Syntax keyword' }));
  const seen = new Set(keywords);
  for (const d of declarations) if (!seen.has(d.name)) {
    seen.add(d.name);
    result.push({ label: d.name, kind: 3, detail: d.verified ? 'Checked project declaration; availability at cursor is not inferred' : 'Project declaration; not independently admitted',
      documentation: { kind: 'plaintext', value: d.type || 'Elaborated type unavailable.' } });
    if (result.length >= 1000) break;
  }
  return { isIncomplete: result.length >= 1000, items: result };
});
connection.onDocumentHighlight((params, token) => {
  ensureNotCancelled(token);
  const doc = documents.get(params.textDocument.uri);
  return smallDocument(doc) ? lexicalHighlights(doc, params.position) : [];
});
connection.languages.semanticTokens.on((params, token) => {
  ensureNotCancelled(token);
  const state = currentState(params.textDocument.uri), data = [];
  let previousLine = 0, previousChar = 0;
  for (const d of (state?.declarations || []).filter(d => d.verified).sort((a, b) => a.selectionRange.start.line - b.selectionRange.start.line || a.selectionRange.start.character - b.selectionRange.start.character)) {
    const { start, end } = d.selectionRange;
    if (start.line !== end.line || end.character <= start.character) continue;
    data.push(start.line - previousLine, start.line === previousLine ? start.character - previousChar : start.character,
      end.character - start.character, ['structure', 'inductive', 'class'].includes(d.kind) ? 1 : 0, 1);
    previousLine = start.line; previousChar = start.character;
  }
  return { data };
});
function stop() {
  shutdown = true; clearTimeout(timer); killRunning();
  for (const directory of temporaryDirectories) {
    try { fs.rmSync(directory, { recursive: true, force: true }); } catch { /* Process exit must still terminate children. */ }
  }
  temporaryDirectories.clear();
}
connection.onShutdown(() => { stop(); return null; });
connection.onExit(() => { stop(); });
process.on('SIGTERM', () => { stop(); process.exit(0); });
process.on('SIGINT', () => { stop(); process.exit(0); });
process.on('exit', stop);
documents.listen(connection);
connection.listen();
