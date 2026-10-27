import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {downloadAndUnzipVSCode, resolveCliArgsFromVSCodeExecutablePath, runTests} from '@vscode/test-electron';

// Linux CI runs this entry with xvfb-run -a. This checks the installed VSIX, not a
// development checkout substituted for it.
const toolsRoot = fileURLToPath(new URL('../', import.meta.url));
const temporary = await fs.mkdtemp(path.join(os.tmpdir(), 'psc1-vsix-smoke-'));
const workspace = path.join(temporary, 'project with spaces');
const extensions = path.join(temporary, 'extensions');
const userData = path.join(temporary, 'user-data');
const harness = path.join(temporary, 'test-runner-extension');
const manifest = JSON.parse(await fs.readFile(path.join(toolsRoot, 'vscode/package.json'), 'utf8'));
const vsix = path.join(toolsRoot, 'dist', `${manifest.name}-${manifest.version}.vsix`);
const version = process.env.PSC1_TEST_VSCODE_VERSION || '1.143.1';

function quoteCmdArgument(value) {
  // Only the downloaded launcher and controlled test paths enter this shell.
  // Disable delayed expansion and reject characters cmd could expand or parse
  // outside our quotes, rather than inventing a generic shell escape function.
  assert.ok(typeof value === 'string' && value.length && !/[\x00-\x1f"%!^&|<>]/.test(value),
    'A Windows test CLI argument contains unsupported shell characters');
  return `"${value}"`;
}

async function directorySummary(directory) {
  try {
    const entries = await fs.readdir(directory, {withFileTypes: true});
    return {directory, entries: entries.slice(0, 24).map(entry => entry.name + (entry.isDirectory() ? '/' : '')),
      total: entries.length};
  } catch (error) { return {directory, error: error.code}; }
}

try {
  await fs.mkdir(workspace); await fs.mkdir(extensions); await fs.mkdir(userData); await fs.mkdir(harness);
  await fs.writeFile(path.join(harness, 'package.json'), JSON.stringify({
    name: 'psc1-vsix-smoke-runner', publisher: 'proofscript-tests', version: '0.0.0',
    engines: {vscode: '^1.106.0'},
  }));
  await fs.writeFile(path.join(workspace, 'Main.ps'), 'def answer : Nat := 42\n');
  await fs.writeFile(path.join(workspace, 'proofscript.json'), JSON.stringify({
    schema: 'proofscript-project/1', entryModule: 'Main', files: [{module: 'Main', path: 'Main.ps'}],
  }));
  const vscodeExecutablePath = await downloadAndUnzipVSCode(version);
  const [cli, ...args] = resolveCliArgsFromVSCodeExecutablePath(vscodeExecutablePath, {reuseMachineInstall: true});
  const installArguments = [...args, '--install-extension', vsix, '--force',
    '--extensions-dir', extensions, '--user-data-dir', userData, '--no-sandbox'];
  let launcher = cli, launcherArguments = installArguments;
  let windowsDirectories;
  const launchOptions = {encoding: 'utf8', timeout: 120000, env: process.env};
  if (process.platform === 'win32') {
    // Use the archive's real launcher: its internal application layout is not
    // an API and may differ from a source-tree launcher template.
    const systemRoot = process.env.SystemRoot || process.env.SYSTEMROOT;
    assert.ok(systemRoot, 'Windows did not provide its SystemRoot directory');
    launcher = path.join(systemRoot, 'System32', 'cmd.exe');
    const command = `"${[cli, ...installArguments].map(quoteCmdArgument).join(' ')}"`;
    launcherArguments = ['/d', '/v:off', '/s', '/c', command];
    launchOptions.windowsVerbatimArguments = true;
    const launcherRoot = path.resolve(path.dirname(cli), '..');
    windowsDirectories = [...new Set([path.dirname(vscodeExecutablePath), path.dirname(cli),
      path.join(launcherRoot, 'resources'), path.join(launcherRoot, 'resources/app')])];
    console.log('PSC1_VSCODE_WINDOWS_LAUNCHER', JSON.stringify({
      vscodeExecutablePath, cli,
      actualLauncher: (await fs.readFile(cli, 'utf8')).split(/\r?\n/)
        .filter(line => /\.exe|\.c?m?js|app\.asar/i.test(line)).slice(0, 12),
    }));
  }
  const installed = spawnSync(launcher, launcherArguments, launchOptions);
  if (windowsDirectories && (installed.error || installed.status !== 0))
    console.log('PSC1_VSCODE_WINDOWS_LAYOUT', JSON.stringify(await Promise.all(windowsDirectories.map(directorySummary))));
  assert.equal(installed.error, undefined, String(installed.error));
  assert.equal(installed.status, 0, installed.stdout + installed.stderr);
  console.log(installed.stdout);
  await runTests({
    vscodeExecutablePath,
    extensionDevelopmentPath: harness,
    extensionTestsPath: path.join(toolsRoot, 'test/extension-smoke.cjs'),
    reuseMachineInstall: true,
    launchArgs: [workspace, '--extensions-dir', extensions, '--user-data-dir', userData,
      '--disable-workspace-trust', '--skip-welcome', '--skip-release-notes', '--disable-gpu', '--no-sandbox'],
    extensionTestsEnv: {
      PSC1_TEST_WORKSPACE: workspace,
      PSC1_TEST_INSTALLED_EXTENSIONS: extensions,
      PSC1_TEST_OUTPUT: path.join(toolsRoot, 'dist/vscode-test-receipt.json'),
      PSC1_TEST_VSCODE_VERSION: version,
      PSC1_TEST_COMMIT: process.env.GITHUB_SHA || '',
    },
  });
} finally {
  await fs.rm(temporary, {recursive: true, force: true, maxRetries: 5, retryDelay: 200});
}
