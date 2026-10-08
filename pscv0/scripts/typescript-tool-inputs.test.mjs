import assert from 'node:assert/strict';
import { test } from 'node:test';
import { mkdtemp, mkdir, writeFile, rm, symlink, unlink, utimes } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { captureTypeScriptToolInputs, verifyTypeScriptToolInputs } from './typescript-tool-inputs.mjs';
import { createCheckedBuildGraph } from './checked-build-evidence.mjs';
import { packObservedBuildArchive, verifyObservedBuildArchive } from './observed-build-archive.mjs';
import { artifactKey } from './artifact-evidence.mjs';

async function fixture(run) {
  const directory = await mkdtemp(path.join(tmpdir(), 'psc-ts-inputs-'));
  const root = path.join(directory, 'node_modules', 'typescript');
  const nativeName = '@typescript/typescript-' + process.platform + '-' + process.arch;
  const nativeRoot = path.join(root, 'node_modules', nativeName);
  const executable = path.join(nativeRoot, 'lib', 'tsc' + (process.platform === 'win32' ? '.exe' : ''));
  try {
    await mkdir(path.join(root, 'bin'), { recursive: true });
    await mkdir(path.join(nativeRoot, 'lib'), { recursive: true });
    await writeFile(path.join(root, 'package.json'), JSON.stringify({ name: 'typescript', version: '7.0.2',
      bin: { tsc: './bin/tsc' }, optionalDependencies: { [nativeName]: '7.0.2' } }));
    await writeFile(path.join(nativeRoot, 'package.json'), JSON.stringify({ name: nativeName, version: '7.0.2',
      os: [process.platform], cpu: [process.arch] }));
    await writeFile(path.join(root, 'bin/tsc'), '// fictional launcher, never executed');
    await writeFile(executable, 'fictional native compiler, never executed');
    await writeFile(path.join(nativeRoot, 'lib/lib.es2022.d.ts'), 'declare const fixture: number;');
    await run({ directory, root, nativeRoot, executable, entry: path.join(root, 'bin/tsc') });
  } finally { await rm(directory, { recursive: true, force: true }); }
}

test('installed input snapshot binds selected native code and libraries, excluding mtime', async () => fixture(async ({ entry, executable }) => {
  const captured = await captureTypeScriptToolInputs(entry);
  assert.equal(captured.command, executable);
  assert.deepEqual(captured.argumentsPrefix, []);
  assert.equal(captured.details.coverage, 'installed-package-and-selected-native-package');
  assert.equal(captured.details.files.length, 5);
  assert.equal(captured.details.fullInputClosureEstablished, false);
  await utimes(executable, new Date(0), new Date(0));
  const verified = await verifyTypeScriptToolInputs(captured);
  assert.equal(verified.files.length, 5);
  // Public byte copies cannot mutate the stored capture.
  verified.files[0].bytes.fill(0);
  assert.notEqual((await verifyTypeScriptToolInputs(captured)).files[0].bytes[0], 0);
  await assert.rejects(verifyTypeScriptToolInputs({ ...captured }), /UNKNOWN_CAPTURE/);
}));

test('changed executable, added/removed file, invalid profile and resource exhaustion fail closed', async () => {
  for (const mutate of [
    f => writeFile(f.executable, 'changed native compiler'),
    f => writeFile(path.join(f.nativeRoot, 'lib/added.d.ts'), 'added'),
    f => rm(path.join(f.nativeRoot, 'lib/lib.es2022.d.ts')),
  ]) await fixture(async f => {
    const captured = await captureTypeScriptToolInputs(f.entry);
    await mutate(f);
    await assert.rejects(verifyTypeScriptToolInputs(captured), /CHANGED/);
  });
  await fixture(async f => {
    for (const limits of [{ maxFiles: 1 }, { maxFileBytes: 1 }, { maxTotalBytes: 1 }, { maxDepth: 0 }, { maxMetadataBytes: 1 }])
      await assert.rejects(captureTypeScriptToolInputs(f.entry, limits), /RESOURCE_EXHAUSTED/);
    await writeFile(path.join(f.nativeRoot, 'package.json'), '{"name":"wrong","version":"7.0.2"}');
    await assert.rejects(captureTypeScriptToolInputs(f.entry), /NATIVE_PACKAGE_PROFILE/);
  });
});

test('package inventory rejects directory links and custom entry remains explicitly incomplete', async () => fixture(async f => {
  const link = path.join(f.nativeRoot, 'lib/linked');
  await symlink(path.join(f.root, 'bin'), link, process.platform === 'win32' ? 'junction' : 'dir');
  try { await assert.rejects(captureTypeScriptToolInputs(f.entry), /SYMLINK|DIRECTORY_SHAPE/); }
  finally { await unlink(link); }
  const custom = path.join(f.directory, 'custom.mjs');
  await writeFile(custom, 'console.log("Version 7.0.2");');
  const captured = await captureTypeScriptToolInputs(custom);
  assert.equal(captured.details.coverage, 'explicit-entry-only');
  assert.equal(captured.details.fullInputClosureEstablished, false);
  assert.equal((await verifyTypeScriptToolInputs(captured)).files.length, 1);
}));

test('observed build archive retains tool bytes and binds their manifest to the tsc pass', async () => fixture(async f => {
  const captured = await captureTypeScriptToolInputs(f.entry), inputs = await verifyTypeScriptToolInputs(captured);
  const entryBytes = inputs.files.find(item => item.path === inputs.details.entryPath).bytes;
  const built = createCheckedBuildGraph({ sourceKind: 'lean', sources: ['fixture'], admissions: 'fixture', typeScript: 'fixture',
    javaScript: Buffer.from('fixture'), declarations: Buffer.from('fixture'), sourceMap: Buffer.from('{}'),
    compilerBytes: Buffer.from('fictional compiler'), compilerKind: 'test-double', typeScriptCompilerBytes: entryBytes,
    typeScriptToolInputs: inputs, provider: { profile: 'test' }, providerSecurity: {}, kernelContract: {},
    hostSources: [], runtime: { version: 'test' }, outputStem: 'out' });
  const tool = built.graph.entries.find(entry => entry.identity.contract === 'psc-typescript-tool-inputs/1');
  assert.deepEqual(tool.identity, built.typeScriptToolInputs);
  assert.equal(tool.canonicalValue.files.length, inputs.files.length);
  const definition = built.graph.entries.find(entry => entry.canonicalValue?.passId === 'typescript-to-es2022/1');
  assert.deepEqual(definition.canonicalValue.implementationId, tool.identity);
  const archive = packObservedBuildArchive(built);
  const allowedAssumptions = [...new Set(built.graph.entries.flatMap(entry => entry.canonicalValue?.assumptionIds ?? []))];
  const replay = await verifyObservedBuildArchive(archive.bytes, { expectedGraphId: built.identity, allowedAssumptions });
  assert.equal(replay.kind, 'accepted', replay.reason);
  assert.equal(replay.fullInputClosureEstablished, false);
  assert.equal(replay.preservationVerified, false);
  const native = tool.canonicalValue.files.find(item => item.path === inputs.details.nativePath);
  built.artifacts.get(artifactKey(native.artifact)).fill(0);
  assert.throws(() => packObservedBuildArchive(built), /ARTIFACT_BYTES/);
}));
