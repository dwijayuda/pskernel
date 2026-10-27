const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const path = require('node:path');
const vscode = require('vscode');

async function waitUntil(get, describe, timeout = 90000) {
  const deadline = Date.now() + timeout;
  let last;
  while (Date.now() < deadline) {
    last = await get();
    if (last) return last;
    await new Promise(resolve => setTimeout(resolve, 100));
  }
  throw new Error(`Timed out: ${describe}; last result: ${JSON.stringify(last)}`);
}

async function setText(document, text) {
  const edit = new vscode.WorkspaceEdit();
  edit.replace(document.uri, new vscode.Range(document.positionAt(0), document.positionAt(document.getText().length)), text);
  assert.equal(await vscode.workspace.applyEdit(edit), true);
}

exports.run = async function run() {
  const extension = vscode.extensions.getExtension('proofscript.proofscript-psc1');
  assert.ok(extension, 'Installed ProofScript PSC1 extension was not discovered');
  assert.ok(extension.extensionPath.startsWith(process.env.PSC1_TEST_INSTALLED_EXTENSIONS + path.sep),
    `Expected the installed VSIX, got ${extension.extensionPath}`);
  const api = await extension.activate();
  assert.equal(extension.isActive, true);
  assert.equal(typeof api.getDocumentStatus, 'function');
  const openStarted = performance.now();
  const document = await vscode.workspace.openTextDocument(path.join(process.env.PSC1_TEST_WORKSPACE, 'Main.ps'));
  await vscode.window.showTextDocument(document);
  assert.equal(document.languageId, 'proofscript');

  const checked = await waitUntil(() => {
    const status = api.getDocumentStatus(document.uri);
    if (status?.version === document.version && ['error', 'unsupported', 'rejected'].includes(status.state)) {
      throw new Error(`Bundled compiler did not check a valid project: ${JSON.stringify(status)}`);
    }
    return status?.version === document.version && status.state === 'checked' && status;
  }, 'installed extension checks initial source');
  const sourceOpenToCheckedMs = Math.round(performance.now() - openStarted);
  assert.ok(checked.declarations.some(d => d.name === 'answer' && d.verified));
  assert.equal(checked.receipt.targetValidation, 'not-run');
  assert.equal(checked.receipt.publication, 'not-requested');

  const symbols = await vscode.commands.executeCommand('vscode.executeDocumentSymbolProvider', document.uri);
  assert.ok(symbols.some(s => s.name === 'answer'));
  const hovers = await vscode.commands.executeCommand('vscode.executeHoverProvider', document.uri, new vscode.Position(0, 6));
  assert.ok(Array.isArray(hovers) && hovers.length, 'The installed extension must provide hover information');
  // VS Code exposes MarkdownString.value through an accessor. Serializing the
  // API object loses that content, so inspect its public value directly.
  const hoverText = hovers.flatMap(hover => hover.contents)
    .map(content => typeof content === 'string' ? content : content.value).join('\n');
  assert.match(hoverText, /Nat/);
  const info = await api.getInfoview(document.uri, {line: 0, character: 6});
  assert.equal(info.goalsAvailable, false);
  assert.equal(info.declaration.name, 'answer');
  await vscode.commands.executeCommand('proofscript.showInfoview');
  await vscode.commands.executeCommand('proofscript.showOutput');
  const serverInfo = await api.getClient().sendRequest('psc1/serverInfo', {});

  const invalidStarted = performance.now();
  await setText(document, 'def answer : Nat := true\n');
  const rejected = await waitUntil(() => {
    const status = api.getDocumentStatus(document.uri);
    return status?.version === document.version && status.state === 'rejected' && status;
  }, 'installed extension rejects an ill-typed unsaved buffer');
  const editToRejectedMs = Math.round(performance.now() - invalidStarted);
  assert.ok(rejected.diagnostics.some(d => d.severity === 1));
  await waitUntil(() => vscode.languages.getDiagnostics(document.uri).some(d => d.severity === vscode.DiagnosticSeverity.Error),
    'real compiler diagnostic reaches the Problems collection');
  assert.ok(document.isDirty, 'The invalid source should still be an unsaved editor buffer');

  const restartStarted = performance.now();
  await api.restart();
  await setText(document, 'def answer : Nat := 43\n');
  const recovered = await waitUntil(() => {
    const status = api.getDocumentStatus(document.uri);
    return status?.version === document.version && status.state === 'checked' && status;
  }, 'restart resynchronizes and checks the current editor buffer');
  const restartAndRepairMs = Math.round(performance.now() - restartStarted);
  await waitUntil(() => !vscode.languages.getDiagnostics(document.uri).some(d => d.severity === vscode.DiagnosticSeverity.Error),
    'repair clears compiler errors');
  const beforeSave = await api.getClient().sendRequest('psc1/serverInfo', {});
  const saveStarted = performance.now();
  assert.equal(await document.save(), true);
  const saved = await waitUntil(() => {
    const status = api.getDocumentStatus(document.uri);
    return status?.version === document.version && status.state === 'checked' &&
      status.reused === true && status.trigger === 'save' && status;
  }, 'saving an unchanged checked buffer reuses its terminal state');
  const unchangedSaveMs = Math.round(performance.now() - saveStarted);
  const afterSave = await api.getClient().sendRequest('psc1/serverInfo', {});
  assert.equal(afterSave.metrics.checksStarted, beforeSave.metrics.checksStarted,
    'Saving an already checked buffer must not invoke the compiler again');

  // A real project-loading failure exercises terminal infrastructure feedback.
  // It is independent of platform-specific compiler behavior and not a mock
  // compiler response. Keep the failed project active while another changes.
  const blockedDirectory = path.join(process.env.PSC1_TEST_WORKSPACE, 'blocked project');
  await fs.mkdir(blockedDirectory);
  await fs.writeFile(path.join(blockedDirectory, 'Bad.ps'), 'def answer : Nat := 7\n');
  await fs.writeFile(path.join(blockedDirectory, 'proofscript.json'), JSON.stringify({
    schema: 'proofscript-project/1', entryModule: 'Bad', files: [{module: 'Bad', path: 'Bad.ps'}],
    checkerExecutable: 'project-metadata-must-not-select-a-checker',
  }));
  const blocked = await vscode.workspace.openTextDocument(path.join(blockedDirectory, 'Bad.ps'));
  await vscode.window.showTextDocument(blocked);
  const failure = await waitUntil(() => {
    const status = api.getDocumentStatus(blocked.uri);
    return status?.version === blocked.version && status.state === 'error' && status;
  }, 'a project-loading failure reaches the installed extension as a terminal error');
  assert.ok(failure.diagnostics.some(diagnostic => /PROJECT_FIELDS/.test(diagnostic.code)));
  await vscode.commands.executeCommand('proofscript.showInfoview');
  await setText(document, 'def answer : Nat := 44\n');
  await waitUntil(() => {
    const status = api.getDocumentStatus(document.uri);
    return status?.version === document.version && status.state === 'checked' && status;
  }, 'the unrelated valid project checks after an edit');
  const preservedFailure = await waitUntil(() => {
    const status = api.getDocumentStatus(blocked.uri);
    return status?.version === blocked.version && status.state === 'error' && status;
  }, 'an unrelated project edit must not strand the failed project at waiting');
  const failureInfo = await api.getInfoview(blocked.uri, {line: 0, character: 6});
  assert.equal(failureInfo.state, 'error');
  assert.ok(failureInfo.messages.some(message => /PROJECT_FIELDS/.test(message.code)));
  assert.ok(!preservedFailure.declarations.some(declaration => declaration.verified));
  await waitUntil(() => vscode.languages.getDiagnostics(blocked.uri).some(diagnostic =>
    diagnostic.severity === vscode.DiagnosticSeverity.Error && /PROJECT_FIELDS/.test(String(
      typeof diagnostic.code === 'object' ? diagnostic.code.value : diagnostic.code))),
  'the failed project retains its real error in Problems');

  await fs.writeFile(process.env.PSC1_TEST_OUTPUT, JSON.stringify({
    schema: 'psc1-vscode-installed-smoke/1', status: 'passed',
    testedCommit: process.env.PSC1_TEST_COMMIT, vscode: vscode.version, node: process.version,
    platform: process.platform, architecture: process.arch,
    electron: process.versions.electron, extensionId: extension.id,
    installedVsix: true, sourceDevelopmentExtensionUsed: false,
    serverInfo, hover: {count: hovers.length, text: hoverText},
    checked: {state: checked.state, elapsedMs: checked.elapsedMs},
    rejected: {state: rejected.state, diagnostics: rejected.diagnostics},
    recovered: {state: recovered.state, elapsedMs: recovered.elapsedMs},
    saved: {reused: saved.reused, checksStarted: afterSave.metrics.checksStarted},
    infrastructureFailure: {state: preservedFailure.state, diagnostics: preservedFailure.diagnostics,
      visibleInfoState: failureInfo.state},
    latency: {sourceOpenToCheckedMs, editToRejectedMs, restartAndRepairMs, unchangedSaveMs},
    checks: ['activation', '.ps registration', 'real compiler checking', 'document symbols',
      'hover', 'Infoview protocol', 'Infoview command', 'unsaved invalid buffer', 'Problems diagnostics',
      'restart and resynchronization', 'save without redundant checking',
      'terminal project failure', 'cross-project error feedback'],
  }, null, 2) + '\n');
  console.log('PSC1 installed VSIX smoke passed', {vscode: vscode.version, node: process.version});
};
