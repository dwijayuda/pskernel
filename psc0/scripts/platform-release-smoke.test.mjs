import assert from 'node:assert/strict';
import { mkdtemp, readFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import test from 'node:test';
import {
  installedPaths, nodeOnlyEnvironment, powershellCmdInvocation,
  peImportInventory, qualifyInstalledPackage,
} from './platform-release-smoke.mjs';

test('global package and executable paths follow each npm platform layout', () => {
  assert.deepEqual(installedPaths('/tmp/space here/global tools', 'linux'), {
    installed: '/tmp/space here/global tools/lib/node_modules/proofscript',
    command: '/tmp/space here/global tools/bin/psc',
  });
  assert.deepEqual(installedPaths('C:\\Temp\\space here\\global tools', 'win32'), {
    installed: 'C:\\Temp\\space here\\global tools\\node_modules\\proofscript',
    command: 'C:\\Temp\\space here\\global tools\\psc.cmd',
  });
  assert.throws(() => installedPaths('/tmp/unsupported', 'darwin'), /PSC_SMOKE_PLATFORM/u);
});

test('Node-only environment removes case aliases and development overrides', () => {
  const original = Object.freeze({
    Path: 'C:\\developer tools', PATH: 'C:\\other tools', patH: 'C:\\third tools',
    Node_Options: '--require unwanted.cjs', node_path: 'C:\\external modules',
    lean_path: 'C:\\Lean', eLaN_hOmE: 'C:\\elan',
    LD_PRELOAD: '/tmp/unwanted.so', psModulePath: 'C:\\external PowerShell',
    PSC0_SMOKE_NPM_CLI: 'C:\\npm\\bin\\npm-cli.js', PSC0_SMOKE_EXPECT_NPM: '12.0.2',
    PSC0_SMOKE_POWERSHELL: 'C:\\PowerShell\\pwsh.exe', PSC0_SMOKE_COMMAND: 'stale',
    SystemRoot: 'C:\\Windows', ComSpec: 'C:\\Windows\\System32\\cmd.exe',
    TEMP: 'C:\\Temp', GITHUB_RUN_ID: '123',
  });
  assert.deepEqual(nodeOnlyEnvironment(original, 'C:\\node only'), {
    SystemRoot: 'C:\\Windows', ComSpec: 'C:\\Windows\\System32\\cmd.exe',
    TEMP: 'C:\\Temp', GITHUB_RUN_ID: '123', PATH: 'C:\\node only',
  });
  assert.equal(original.Path, 'C:\\developer tools');
});

test('PowerShell forwarding keeps paths and arguments outside its fixed program', () => {
  const shell = 'C:\\Program Files\\PowerShell\\7\\pwsh.exe';
  const command = "C:\\Temp\\user's space\\global tools\\psc.cmd";
  const args = ['build', 'src/Main.ps', '--out', 'src/Main.ts', '--json'];
  const env = { PATH: 'C:\\node only', SystemRoot: 'C:\\Windows' };
  const first = powershellCmdInvocation(shell, command, args, env);
  const second = powershellCmdInvocation(shell, 'C:\\another space\\psc.cmd', ['version', '--json'], env);
  assert.equal(first.command, shell);
  assert.deepEqual(first.args.slice(0, -1), ['-NoLogo', '-NoProfile', '-NonInteractive', '-EncodedCommand']);
  assert.equal(first.args.at(-1), second.args.at(-1));
  const program = Buffer.from(first.args.at(-1), 'base64').toString('utf16le');
  assert.match(program, /ConvertFrom-Json -InputObject \$env:PSC0_SMOKE_COMMAND/u);
  assert.match(program, /& \$request.command @arguments/u);
  assert.equal(program.includes(command), false);
  assert.equal(program.includes('src/Main.ps'), false);
  assert.deepEqual(JSON.parse(first.env.PSC0_SMOKE_COMMAND), { command, args });
  assert.equal(first.env.PATH, env.PATH);
  assert.equal(Object.hasOwn(env, 'PSC0_SMOKE_COMMAND'), false);
});

test('the smoke refuses unsafe cmd arguments and nonabsolute executable routes', () => {
  const shell = 'C:\\Program Files\\PowerShell\\7\\pwsh.exe';
  const command = 'C:\\global tools\\psc.cmd';
  for (const value of ['bad&command', '%TEMP%', 'bad|pipe', 'bad>file', 'bad<file',
    'bad^escape', 'bad!expansion', 'bad(operand)', 'bad"quote', 'bad\nline', 'bad\rline']) {
    assert.throws(() => powershellCmdInvocation(shell, command, [value], {}), /PSC_SMOKE_CMD_UNSAFE_ARGUMENT/u);
  }
  assert.throws(() => powershellCmdInvocation('pwsh.exe', command, [], {}), /PSC_SMOKE_POWERSHELL_PATH/u);
  assert.throws(() => powershellCmdInvocation(shell, 'psc.cmd', [], {}), /PSC_SMOKE_CMD_PATH/u);
  assert.throws(() => powershellCmdInvocation(shell, command, [1], {}), /PSC_SMOKE_CMD_ARGUMENTS/u);
});

// A small PE32+ image with one raw section, one regular descriptor and one
// delay descriptor, followed by their terminating zero descriptors. It is data,
// not executable test code; layout comes from the PE/COFF specification.
function peFixture() {
  const bytes = Buffer.alloc(0x600);
  bytes.writeUInt16LE(0x5a4d, 0);
  bytes.writeUInt32LE(0x80, 0x3c);
  bytes.writeUInt32LE(0x4550, 0x80);
  bytes.writeUInt16LE(0x8664, 0x84);
  bytes.writeUInt16LE(1, 0x86);
  bytes.writeUInt32LE(0x12345678, 0x88);
  bytes.writeUInt16LE(0xf0, 0x94);
  const optional = 0x98;
  bytes.writeUInt16LE(0x20b, optional);
  bytes.writeBigUInt64LE(0x140000000n, optional + 24);
  bytes.writeUInt32LE(0x200, optional + 60);
  bytes.writeUInt32LE(16, optional + 108);
  bytes.writeUInt32LE(0x1000, optional + 112 + 8);
  bytes.writeUInt32LE(40, optional + 112 + 12);
  bytes.writeUInt32LE(0x1100, optional + 112 + 13 * 8);
  bytes.writeUInt32LE(64, optional + 116 + 13 * 8);
  const section = optional + 0xf0;
  bytes.writeUInt32LE(0x1000, section + 12);
  bytes.writeUInt32LE(0x400, section + 16);
  bytes.writeUInt32LE(0x200, section + 20);
  bytes.writeUInt32LE(0x1080, 0x200 + 12);
  bytes.write('KERNEL32.dll\0', 0x280, 'ascii');
  bytes.writeUInt32LE(1, 0x300);
  bytes.writeUInt32LE(0x1180, 0x304);
  bytes.write('USER32.dll\0', 0x380, 'ascii');
  return bytes;
}

test('PE inventory reads both normal and delayed imports with bounded claims', () => {
  assert.deepEqual(peImportInventory(peFixture()), {
    kind: 'pe-import-table-inventory', format: 'PE32+', machine: 'AMD64',
    coffTimeDateStamp: 0x12345678,
    imports: ['KERNEL32.dll'], delayImports: ['USER32.dll'],
    arbitraryDynamicLoadsEnumerated: false,
  });
});

test('PE inventory handles empty tables and legacy delay virtual addresses', () => {
  const empty = peFixture();
  empty.fill(0, 0x98 + 112 + 8, 0x98 + 112 + 16);
  empty.fill(0, 0x98 + 112 + 13 * 8, 0x98 + 112 + 14 * 8);
  assert.deepEqual(peImportInventory(empty).imports, []);
  assert.deepEqual(peImportInventory(empty).delayImports, []);
  const legacy = peFixture();
  legacy.writeBigUInt64LE(0x400000n, 0x98 + 24);
  legacy.writeUInt32LE(0, 0x300);
  legacy.writeUInt32LE(0x401180, 0x304);
  assert.deepEqual(peImportInventory(legacy).delayImports, ['USER32.dll']);
});

test('PE inventory refuses malformed headers, unmapped names and missing terminators', () => {
  assert.throws(() => peImportInventory(Buffer.alloc(8)), /PSC_SMOKE_PE_DOS/u);
  const wrongMachine = peFixture();
  wrongMachine.writeUInt16LE(0x14c, 0x84);
  assert.throws(() => peImportInventory(wrongMachine), /PSC_SMOKE_PE_MACHINE/u);
  const badRva = peFixture();
  badRva.writeUInt32LE(0x9000, 0x20c);
  assert.throws(() => peImportInventory(badRva), /PSC_SMOKE_PE_RVA/u);
  const unterminated = peFixture();
  unterminated.writeUInt32LE(20, 0x98 + 112 + 12);
  assert.throws(() => peImportInventory(unterminated), /PSC_SMOKE_PE_IMPORT_TERMINATOR/u);
  const badDelay = peFixture();
  badDelay.writeUInt32LE(2, 0x300);
  assert.throws(() => peImportInventory(badDelay), /PSC_SMOKE_PE_DELAY_ATTRIBUTES/u);
  const truncated = peFixture().subarray(0, 0x80);
  assert.throws(() => peImportInventory(truncated), /PSC_SMOKE_PE_BOUNDS/u);
});

test('missing tarballs still produce failed evidence without claiming the clean execution ran', async t => {
  const directory = await mkdtemp(path.join(tmpdir(), 'psc smoke missing-'));
  t.after(() => rm(directory, { recursive: true, force: true, maxRetries: 5, retryDelay: 100 }));
  t.mock.method(console, 'log', () => {});
  const evidence = path.join(directory, 'evidence');
  await assert.rejects(qualifyInstalledPackage(path.join(directory, 'missing.tgz'), evidence), { code: 'ENOENT' });
  const result = JSON.parse(await readFile(path.join(evidence, 'installed-package-qualification.json'), 'utf8'));
  assert.equal(result.passed, false);
  assert.equal(result.tarballSha256, null);
  assert.equal(result.tarballBytes, null);
  assert.equal(result.nodeOnlyExecutionPath, false);
  assert.equal(result.npmRuntime, null);
  assert.equal(result.shellRuntime, null);
  assert.deepEqual(result.observations, []);
  assert.match(result.failure.message, /ENOENT/u);
});
