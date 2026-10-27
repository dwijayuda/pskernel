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
  // Match VS Code's official Windows code.cmd entry without a command shell:
  // Code.exe resources/app/out/cli.js under ELECTRON_RUN_AS_NODE.
  const cliExecutable = process.platform === 'win32' ? vscodeExecutablePath : cli;
  const cliArguments = process.platform === 'win32'
    ? [path.join(path.dirname(vscodeExecutablePath), 'resources/app/out/cli.js')]
    : args;
  const installed = spawnSync(cliExecutable, [...cliArguments, '--install-extension', vsix, '--force',
    '--extensions-dir', extensions, '--user-data-dir', userData, '--no-sandbox'],
  {encoding: 'utf8', timeout: 120000,
    env: process.platform === 'win32' ? {...process.env, ELECTRON_RUN_AS_NODE: '1', VSCODE_DEV: ''} : process.env});
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
