'use strict';

const vscode = require('vscode');
const path = require('node:path');
const crypto = require('node:crypto');
const { LanguageClient, TransportKind, State, Trace, CloseAction, ErrorAction } = require('vscode-languageclient/node');
const { renderInfoview, stateLabel } = require('./infoview.cjs');

let controller;

const isSupported = document => document && document.uri.scheme === 'file' &&
  ['proofscript', 'proofscript-lean'].includes(document.languageId);
const toRange = range => new vscode.Range(range.start.line, range.start.character, range.end.line, range.end.character);

class ProofScriptExtension {
  constructor(context) {
    this.context = context;
    this.statuses = new Map();
    this.requiredVersions = new Map();
    this.minimumGeneration = 0;
    this.latestGeneration = 0;
    this.sequence = 0;
    this.restartChain = Promise.resolve();
    this.disposed = false;
    this.output = vscode.window.createOutputChannel('ProofScript', { log: true });
    this.status = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 50);
    this.status.name = 'ProofScript compiler status';
    this.status.command = 'proofscript.showInfoview';
    this.verified = vscode.window.createTextEditorDecorationType({
      gutterIconPath: vscode.Uri.joinPath(context.extensionUri, 'media', 'checked.svg'),
      gutterIconSize: 'contain',
      overviewRulerColor: new vscode.ThemeColor('testing.iconPassed'),
      overviewRulerLane: vscode.OverviewRulerLane.Left
    });
    this.rejected = vscode.window.createTextEditorDecorationType({
      gutterIconPath: vscode.Uri.joinPath(context.extensionUri, 'media', 'rejected.svg'),
      gutterIconSize: 'contain'
    });
    context.subscriptions.push(this.output, this.status, this.verified, this.rejected);
    this.nonce = crypto.randomBytes(16).toString('hex');
  }

  options() {
    const config = vscode.workspace.getConfiguration('proofscript');
    return {
      trusted: vscode.workspace.isTrusted,
      enableLean: true, // Only explicitly selected proofscript-lean buffers enter the client.
      debounceMs: config.get('checkDelay', 350),
      timeoutMs: config.get('checkTimeout', 30000)
    };
  }

  register() {
    const subscriptions = this.context.subscriptions;
    const command = (name, callback) => subscriptions.push(vscode.commands.registerCommand(name, callback));
    command('proofscript.showInfoview', async () => {
      await vscode.commands.executeCommand('proofscript.infoview.focus');
      this.schedule(0);
    });
    command('proofscript.restartServer', () => this.restart());
    command('proofscript.showOutput', () => this.output.show(true));
    command('proofscript.serverInfo', async () => {
      const info = await this.client?.sendRequest('psc1/serverInfo');
      this.output.info(JSON.stringify(info || { state: 'stopped' }, null, 2));
      this.output.show(true);
      return info;
    });
    command('proofscript.recheck', async () => {
      const editor = vscode.window.activeTextEditor;
      if (isSupported(editor?.document) && this.client?.isRunning()) {
        return this.client.sendRequest('psc1/recheck', { uri: editor.document.uri.toString() });
      }
    });
    command('proofscript.copyDeclaredType', async () => {
      const type = this.lastInfo?.declaration?.type;
      if (typeof type === 'string') await vscode.env.clipboard.writeText(type);
    });
    command('proofscript.usePSC1Lean', () => this.useLean());
    subscriptions.push(vscode.window.registerWebviewViewProvider('proofscript.infoview', this));
    subscriptions.push(vscode.window.onDidChangeActiveTextEditor(() => { this.updateDecorations(); this.schedule(0); }));
    subscriptions.push(vscode.window.onDidChangeVisibleTextEditors(() => this.updateDecorations()));
    subscriptions.push(vscode.window.onDidChangeTextEditorSelection(event => {
      if (event.textEditor === vscode.window.activeTextEditor) this.schedule();
    }));
    subscriptions.push(vscode.workspace.onDidChangeTextDocument(event => {
      if (!isSupported(event.document) || !event.contentChanges.length) return;
      this.requiredVersions.set(event.document.uri.toString(), event.document.version);
      // An edited import can invalidate any open dependent, before the server replies.
      for (const document of vscode.workspace.textDocuments.filter(isSupported)) {
        this.statuses.set(document.uri.toString(), {
          uri: document.uri.toString(), version: document.version,
          state: vscode.workspace.isTrusted ? 'pending' : 'untrusted',
          summary: vscode.workspace.isTrusted ? 'Source changed; waiting for compiler feedback.' : 'Trust this workspace to enable compiler checking.',
          declarations: [], diagnostics: []
        });
      }
      this.lastInfo = undefined;
      this.updateDecorations();
      this.schedule(0);
    }));
    subscriptions.push(vscode.workspace.onDidCloseTextDocument(document => {
      this.statuses.delete(document.uri.toString());
      this.requiredVersions.delete(document.uri.toString());
      if (isSupported(document)) {
        this.minimumGeneration = Math.max(this.minimumGeneration, this.latestGeneration + 1);
        this.clear('pending', 'Source closed; refreshing project feedback.');
      }
    }));
    subscriptions.push(vscode.workspace.onDidChangeConfiguration(event => {
      if (!event.affectsConfiguration('proofscript')) return;
      if (this.client?.isRunning()) {
        this.client.sendNotification('psc1/configuration', this.options()).catch(error => this.log(error));
        this.setTrace().catch(error => this.log(error));
      }
    }));
    subscriptions.push(vscode.workspace.onDidGrantWorkspaceTrust(() => {
      if (this.client?.isRunning()) this.client.sendNotification('psc1/configuration', this.options()).catch(error => this.log(error));
    }));
    subscriptions.push({ dispose: () => { this.disposed = true; clearTimeout(this.timer); this.cancelRequest(); } });
  }

  async start() {
    if (this.disposed) return;
    const runtime = process.versions.node.split('.').map(Number);
    if (runtime[0] < 22 || (runtime[0] === 22 && (runtime[1] < 23 || (runtime[1] === 23 && runtime[2] < 3)))) {
      const error = new Error(`PSC1 requires Node >=22.23.3; VS Code provides ${process.versions.node}. Install VS Code 1.143.1 or newer.`);
      this.clear('error', error.message);
      this.log(error);
      throw error;
    }
    this.requiredVersions.clear();
    this.minimumGeneration = 0;
    this.latestGeneration = 0;
    const watcher = vscode.workspace.createFileSystemWatcher('**/*.{ps,lean,json}');
    const server = {
      module: this.context.asAbsolutePath('server/dist/server.cjs'),
      transport: TransportKind.stdio,
      options: { env: { ...process.env, ELECTRON_RUN_AS_NODE: '1' }, execArgv: [] }
    };
    let restarts = [];
    const client = new LanguageClient('proofscript-psc1', 'ProofScript', server, {
      documentSelector: [
        { scheme: 'file', language: 'proofscript' },
        { scheme: 'file', language: 'proofscript-lean' }
      ],
      initializationOptions: this.options(),
      outputChannel: this.output,
      traceOutputChannel: this.output,
      synchronize: { fileEvents: watcher },
      errorHandler: {
        error: (error, _message, count) => {
          this.log(error);
          return { action: (count || 0) <= 3 ? ErrorAction.Continue : ErrorAction.Shutdown };
        },
        closed: () => {
          const now = Date.now();
          restarts = restarts.filter(time => now - time < 180000);
          restarts.push(now);
          this.clear('stopped', 'The language server stopped.');
          return restarts.length <= 3
            ? { action: CloseAction.Restart }
            : { action: CloseAction.DoNotRestart, message: 'ProofScript stopped after repeated failures. Open ProofScript output or use Restart Language Server.' };
        }
      }
    });
    this.client = client;
    this.clientDisposables = [watcher,
      client.onNotification('psc1/documentStatus', status => this.acceptStatus(status)),
      client.onDidChangeState(event => {
        if (event.newState === State.Starting) {
          // A fresh server starts its project generation counter from zero.
          this.requiredVersions.clear();
          this.minimumGeneration = 0;
          this.latestGeneration = 0;
        }
        if (event.newState === State.Running) this.schedule(0);
        else this.clear(event.newState === State.Starting ? 'pending' : 'stopped',
          event.newState === State.Starting ? 'Starting the language server…' : 'The language server is not running.');
      })
    ];
    try {
      await client.start();
      await this.setTrace();
      this.schedule(0);
    } catch (error) {
      this.log(error);
      this.clear('error', `Could not start the compiler service: ${error.message || error}`);
      throw error;
    }
  }

  async setTrace() {
    const level = vscode.workspace.getConfiguration('proofscript').get('trace.server', 'off');
    return this.client?.setTrace(({ off: Trace.Off, messages: Trace.Messages, verbose: Trace.Verbose })[level] ?? Trace.Off);
  }

  acceptStatus(status) {
    if (!this.recordStatus(status)) return;
    this.updateDecorations();
    if (vscode.window.activeTextEditor?.document.uri.toString() === status.uri) this.schedule(0);
  }

  recordStatus(status) {
    if (!status || typeof status.uri !== 'string' || !Number.isInteger(status.version)) return;
    const document = vscode.workspace.textDocuments.find(item => item.uri.toString() === status.uri);
    if (!document || status.version !== document.version) return;
    if (this.requiredVersions.has(status.uri) && status.version >= this.requiredVersions.get(status.uri) && Number.isFinite(status.projectGeneration)) {
      this.requiredVersions.delete(status.uri);
      this.minimumGeneration = Math.max(this.minimumGeneration, status.projectGeneration);
    }
    if (Number.isFinite(status.projectGeneration) && status.projectGeneration < this.minimumGeneration) return;
    // A dependent's unchanged document version cannot acknowledge an unsaved import.
    if (this.requiredVersions.size && !['pending', 'checking', 'untrusted'].includes(status.state)) return;
    const old = this.statuses.get(status.uri);
    if (old && Number.isFinite(old.projectGeneration) && Number.isFinite(status.projectGeneration) && status.projectGeneration < old.projectGeneration) return;
    this.statuses.set(status.uri, status);
    this.latestGeneration = Math.max(this.latestGeneration, status.projectGeneration || 0);
    return true;
  }

  clear(state, summary) {
    this.cancelRequest();
    for (const document of vscode.workspace.textDocuments.filter(isSupported)) {
      this.statuses.set(document.uri.toString(), { uri: document.uri.toString(), version: document.version, state, summary, declarations: [], diagnostics: [] });
    }
    this.lastInfo = undefined;
    this.updateDecorations();
    this.renderCurrent();
  }

  updateDecorations() {
    for (const editor of vscode.window.visibleTextEditors) {
      const status = this.statuses.get(editor.document.uri.toString());
      const current = isSupported(editor.document) && status?.version === editor.document.version;
      const checked = current && ['checked', 'partial'].includes(status.state)
        ? (status.declarations || []).filter(declaration => declaration.verified === true && declaration.selectionRange)
            .map(declaration => ({ range: toRange(declaration.selectionRange), hoverMessage: 'Checked by the PSC1 compiler for this source version.' })) : [];
      const errors = current ? (status?.diagnostics || []).filter(diagnostic => diagnostic.severity === 1 && diagnostic.range)
        .map(diagnostic => ({ range: toRange(diagnostic.range), hoverMessage: new vscode.MarkdownString().appendText(diagnostic.message) })) : [];
      editor.setDecorations(this.verified, checked);
      editor.setDecorations(this.rejected, errors);
    }
  }

  cancelRequest() {
    this.sequence += 1;
    this.requestCancellation?.cancel();
    this.requestCancellation?.dispose();
    this.requestCancellation = undefined;
  }

  schedule(delay = 70) {
    clearTimeout(this.timer);
    this.cancelRequest();
    this.lastInfo = undefined;
    this.renderCurrent();
    this.timer = setTimeout(() => this.refresh().catch(error => this.log(error)), delay);
  }

  async refresh() {
    const editor = vscode.window.activeTextEditor;
    if (!isSupported(editor?.document) || !this.client?.isRunning()) return;
    const uri = editor.document.uri.toString();
    const version = editor.document.version;
    const position = editor.selection.active;
    const sequence = this.sequence;
    const cancellation = new vscode.CancellationTokenSource();
    this.requestCancellation = cancellation;
    try {
      const info = await this.client.sendRequest('psc1/infoview', {
        textDocument: { uri }, version,
        position: { line: position.line, character: position.character }
      }, cancellation.token);
      if (cancellation.token.isCancellationRequested || sequence !== this.sequence || !info) return;
      const active = vscode.window.activeTextEditor;
      if (active?.document.uri.toString() !== uri || active.document.version !== version || info.version !== version) return;
      if (active.selection.active.line !== position.line || active.selection.active.character !== position.character) return;
      if (!this.recordStatus(info)) return;
      this.updateDecorations();
      this.lastInfo = info;
      this.renderCurrent();
    } catch (error) {
      if (!cancellation.token.isCancellationRequested) this.log(error);
    } finally {
      if (this.requestCancellation === cancellation) this.requestCancellation = undefined;
      cancellation.dispose();
    }
  }

  renderCurrent() {
    const editor = vscode.window.activeTextEditor;
    if (!isSupported(editor?.document)) {
      this.status.hide();
      if (this.view) this.view.webview.html = renderInfoview(undefined, undefined, this.nonce);
      return;
    }
    const uri = editor.document.uri.toString();
    const snapshot = this.statuses.get(uri);
    const info = this.lastInfo?.uri === uri && this.lastInfo.version === editor.document.version &&
      this.lastInfo.projectGeneration === snapshot?.projectGeneration ? this.lastInfo : snapshot;
    const state = info?.state || 'pending';
    const icon = ['pending', 'checking'].includes(state) ? '$(sync~spin)' :
      state === 'checked' ? '$(check)' : state === 'rejected' || state === 'error' ? '$(error)' :
      state === 'partial' || state === 'unsupported' ? '$(warning)' : '$(circle-outline)';
    this.status.text = `${icon} ProofScript`;
    this.status.tooltip = `${stateLabel(state)}${info?.summary ? ` — ${info.summary}` : ''}`;
    this.status.accessibilityInformation = { label: `ProofScript: ${stateLabel(state)}` };
    this.status.show();
    if (this.view) this.view.webview.html = renderInfoview(info, {
      name: path.basename(editor.document.fileName), line: editor.selection.active.line,
      character: editor.selection.active.character
    }, this.nonce);
  }

  resolveWebviewView(view) {
    this.view = view;
    view.webview.options = { enableScripts: false, localResourceRoots: [] };
    view.onDidDispose(() => { if (this.view === view) this.view = undefined; });
    view.onDidChangeVisibility(() => { if (view.visible) this.schedule(0); });
    this.schedule(0);
  }

  async useLean() {
    const editor = vscode.window.activeTextEditor;
    if (!editor || editor.document.uri.scheme !== 'file' || !editor.document.fileName.endsWith('.lean')) {
      return vscode.window.showInformationMessage('Open a .lean file in a PSC1 project first.');
    }
    const folder = vscode.workspace.getWorkspaceFolder(editor.document.uri);
    if (!folder) return vscode.window.showInformationMessage('Open the containing PSC1 project folder first.');
    let directory = vscode.Uri.file(path.dirname(editor.document.fileName));
    let found = false;
    while (directory.fsPath === folder.uri.fsPath || directory.fsPath.startsWith(folder.uri.fsPath + path.sep)) {
      try {
        const stat = await vscode.workspace.fs.stat(vscode.Uri.joinPath(directory, 'proofscript.json'));
        if (stat.type & vscode.FileType.File) { found = true; break; }
      } catch { /* Look for the nearest project manifest. */ }
      const parent = path.dirname(directory.fsPath);
      if (parent === directory.fsPath) break;
      directory = vscode.Uri.file(parent);
    }
    if (!found) return vscode.window.showInformationMessage('PSC1 Lean mode requires a proofscript.json project in this workspace.');
    return vscode.languages.setTextDocumentLanguage(editor.document, 'proofscript-lean');
  }

  restart() {
    this.restartChain = this.restartChain.catch(() => {}).then(async () => {
      this.clear('pending', 'Restarting the language server…');
      await this.stop();
      await this.start();
    });
    return this.restartChain;
  }

  async stop() {
    const client = this.client;
    this.client = undefined;
    if (client) await client.dispose();
    for (const disposable of this.clientDisposables || []) disposable.dispose();
    this.clientDisposables = [];
  }

  log(error) { this.output.error(error instanceof Error ? error : new Error(String(error))); }
}

async function activate(context) {
  controller = new ProofScriptExtension(context);
  controller.register();
  await controller.start();
  const requestInfo = (uri, position) => {
      const textDocument = typeof uri === 'string' ? uri : uri.toString();
      const document = vscode.workspace.textDocuments.find(item => item.uri.toString() === textDocument);
      return controller?.client?.sendRequest('psc1/infoview', { textDocument: { uri: textDocument }, version: document?.version, position });
  };
  return Object.freeze({
    getClient: () => controller?.client,
    getDocumentStatus: uri => controller?.statuses.get(typeof uri === 'string' ? uri : uri.toString()),
    getInfoview: requestInfo,
    requestInfo,
    restart: () => controller?.restart()
  });
}

async function deactivate() {
  if (!controller) return;
  controller.disposed = true;
  clearTimeout(controller.timer);
  controller.cancelRequest();
  await controller.stop();
  controller = undefined;
}

module.exports = { activate, deactivate };
