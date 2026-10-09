import test from 'node:test';
import assert from 'node:assert/strict';
import { access, lstat, mkdir, mkdtemp, readFile, readdir, rm, symlink, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { tmpdir } from 'node:os';
import { initProject } from './project-init.mjs';

const version = '0.1.0-preview.2';
const launcher = 'node ./node_modules/proofscript/bin/psc.mjs';

async function fixture(t) {
  const root = await mkdtemp(path.join(tmpdir(), 'psc-init-'));
  t.after(() => rm(root, { recursive: true, force: true, maxRetries: 5, retryDelay: 100 }));
  return root;
}
async function absent(file) { await assert.rejects(access(file), { code: 'ENOENT' }); }
async function npmProject(root, metadata = '{}\n') {
  await mkdir(root, { recursive: true });
  await writeFile(path.join(root, 'package.json'), metadata);
}
async function directoryLink(target, link) {
  await symlink(target, link, process.platform === 'win32' ? 'junction' : 'dir');
}

test('init creates a pinned local starter without installing or generating output', async t => {
  const root = await fixture(t);
  const project = path.join(root, 'new project λ');
  const result = await initProject({ cwd: root, directory: 'new project λ', version });
  assert.equal(result.projectRoot, project);
  assert.equal(result.mode, 'new');
  assert.deepEqual(result.createdFiles, ['package.json', 'src/Main.ps', 'PROOFSCRIPT.md']);
  assert.deepEqual(result.preservedFiles, []);
  const metadata = JSON.parse(await readFile(path.join(project, 'package.json'), 'utf8'));
  assert.deepEqual(metadata.devDependencies, { proofscript: version });
  assert.equal(metadata.private, true);
  assert.equal(metadata.type, 'module');
  assert.deepEqual(metadata.scripts, {
    check: launcher + ' check src/Main.ps',
    build: launcher + ' build src/Main.ps --out src/Main.ts',
  });
  assert.deepEqual(metadata.proofscript, {
    profile: 'checked', entry: 'src/Main.ps', out: 'src/Main.ts', extensions: [],
  });
  assert.equal(await readFile(path.join(project, 'src/Main.ps'), 'utf8'), 'def answer : Nat := 42\n');
  assert.match(await readFile(path.join(project, 'PROOFSCRIPT.md'), 'utf8'),
    /unpublished preview[\s\S]*proofscript-0\.1\.0-preview\.2\.tgz/u);
  for (const relative of ['node_modules', 'package-lock.json', 'src/Main.ts', 'src/Main.checked.json']) {
    await absent(path.join(project, relative));
  }
});

test('init adds a source beside existing TypeScript without rewriting project files', async t => {
  const root = await fixture(t);
  const metadata = '\uFEFF{\r\n  "name": "existing", "scripts": {"build":"existing build"},\r\n' +
    '  "devDependencies": {"some-tool":"1.2.3"}, "proofscript":{"profile":"checked"}\r\n}\r\n';
  const tsconfig = '\uFEFF{\r\n  "compilerOptions": {"strict":true}\r\n}\r\n';
  const consumer = 'export const existingValue: number = 9;\r\n';
  await npmProject(root, metadata);
  await mkdir(path.join(root, 'src'));
  await writeFile(path.join(root, 'tsconfig.json'), tsconfig);
  await writeFile(path.join(root, 'src/consumer.ts'), consumer);
  const result = await initProject({ cwd: root, version });
  assert.equal(result.mode, 'existing');
  assert.deepEqual(result.createdFiles, ['src/Main.ps', 'PROOFSCRIPT.md']);
  assert.deepEqual(result.preservedFiles, ['package.json']);
  assert.equal(await readFile(path.join(root, 'package.json'), 'utf8'), metadata);
  assert.equal(await readFile(path.join(root, 'tsconfig.json'), 'utf8'), tsconfig);
  assert.equal(await readFile(path.join(root, 'src/consumer.ts'), 'utf8'), consumer);
  assert.deepEqual(result.suggestedPackageChanges.devDependencies, { proofscript: version });
  assert.equal(result.suggestedPackageChanges.scripts['ps:build'],
    launcher + ' build src/Main.ps --out src/Main.ts');
  assert.match(await readFile(path.join(root, 'PROOFSCRIPT.md'), 'utf8'), /were preserved/u);
  await absent(path.join(root, 'proofscript.json'));
  await absent(path.join(root, 'node_modules'));
});

test('reserved source, generated output, receipt, and guide collisions are preflight refusals', async t => {
  const root = await fixture(t);
  for (const relative of ['src/Main.ps', 'src/Main.ts', 'src/Main.checked.json', 'PROOFSCRIPT.md']) {
    const project = path.join(root, relative.replaceAll('/', '-'));
    await npmProject(project, '{"private":true}\n');
    await mkdir(path.join(project, 'src'));
    const sentinel = 'user-owned ' + relative + '\r\n';
    await writeFile(path.join(project, relative), sentinel);
    await assert.rejects(initProject({ directory: project, version }), /PSC_INIT_CONFLICT/u);
    assert.equal(await readFile(path.join(project, relative), 'utf8'), sentinel);
    assert.equal(await readFile(path.join(project, 'package.json'), 'utf8'), '{"private":true}\n');
    assert.deepEqual((await readdir(project)).sort(),
      (relative === 'PROOFSCRIPT.md' ? ['PROOFSCRIPT.md', 'package.json', 'src'] : ['package.json', 'src']).sort());
    assert.deepEqual(await readdir(path.join(project, 'src')), relative.startsWith('src/') ? [path.basename(relative)] : []);
  }
});

test('repeated init refuses while preserving every generated file', async t => {
  const root = await fixture(t);
  const first = await initProject({ directory: root, version });
  const before = await Promise.all(first.createdFiles.map(relative => readFile(path.join(root, relative))));
  await assert.rejects(initProject({ directory: root, version }), /PSC_INIT_CONFLICT/u);
  for (const [index, relative] of first.createdFiles.entries()) {
    assert.deepEqual(await readFile(path.join(root, relative)), before[index]);
  }
});

test('init refuses directory links and linked ancestors rather than writing outside the target', async t => {
  const root = await fixture(t);
  const outside = path.join(root, 'outside');
  await mkdir(outside);
  const link = path.join(root, 'link');
  await directoryLink(outside, link);
  await assert.rejects(initProject({ directory: link, version }), /PSC_INIT_DIRECTORY/u);
  await assert.rejects(initProject({ directory: path.join(link, 'child'), version }), /PSC_INIT_DIRECTORY/u);
  await absent(path.join(outside, 'child'));
  assert.deepEqual(await readdir(outside), []);

  const project = path.join(root, 'project');
  await npmProject(project);
  await directoryLink(outside, path.join(project, 'src'));
  await assert.rejects(initProject({ directory: project, version }), /PSC_INIT_DIRECTORY/u);
  await absent(path.join(project, 'PROOFSCRIPT.md'));
  assert.deepEqual(await readdir(outside), []);
  assert.equal((await lstat(path.join(project, 'src'))).isSymbolicLink(), true);
});

test('init rejects malformed package metadata, source parent files, and nonempty non-projects', async t => {
  const root = await fixture(t);
  for (const [index, metadata] of ['{bad', 'null', '[]', '"package"'].entries()) {
    const project = path.join(root, 'bad-' + index);
    await npmProject(project, metadata);
    await assert.rejects(initProject({ directory: project, version }), /PSC_INIT_PACKAGE_JSON/u);
    assert.deepEqual(await readdir(project), ['package.json']);
    assert.equal(await readFile(path.join(project, 'package.json'), 'utf8'), metadata);
  }
  const sourceFile = path.join(root, 'source-file');
  await npmProject(sourceFile);
  await writeFile(path.join(sourceFile, 'src'), 'keep this file');
  await assert.rejects(initProject({ directory: sourceFile, version }), /PSC_INIT_DIRECTORY/u);
  await absent(path.join(sourceFile, 'PROOFSCRIPT.md'));
  assert.equal(await readFile(path.join(sourceFile, 'src'), 'utf8'), 'keep this file');

  const ordinary = path.join(root, 'ordinary');
  await mkdir(ordinary);
  await writeFile(path.join(ordinary, 'keep.txt'), 'keep');
  await assert.rejects(initProject({ directory: ordinary, version }), /PSC_INIT_PACKAGE_REQUIRED/u);
  assert.deepEqual(await readdir(ordinary), ['keep.txt']);
});

test('init requires an exact release version before creating a directory', async t => {
  const root = await fixture(t);
  const project = path.join(root, 'absent');
  for (const candidate of [undefined, 'latest', '^0.1.0', '0.1.0\n', 123]) {
    await assert.rejects(initProject({ directory: project, version: candidate }), /PSC_INIT_ARGUMENT/u);
  }
  await absent(project);
});

test('concurrent initializers use exclusive writes and leave one complete starter', async t => {
  const root = await fixture(t);
  const project = path.join(root, 'concurrent');
  const results = await Promise.allSettled([
    initProject({ directory: project, version }),
    initProject({ directory: project, version }),
  ]);
  assert.equal(results.filter(result => result.status === 'fulfilled').length, 1);
  const failure = results.find(result => result.status === 'rejected');
  assert.match(failure.reason.message, /PSC_INIT_(?:CONFLICT|PACKAGE_REQUIRED|PACKAGE_JSON)/u);
  assert.equal(JSON.parse(await readFile(path.join(project, 'package.json'), 'utf8')).devDependencies.proofscript, version);
  assert.equal(await readFile(path.join(project, 'src/Main.ps'), 'utf8'), 'def answer : Nat := 42\n');
  assert.match(await readFile(path.join(project, 'PROOFSCRIPT.md'), 'utf8'), /ProofScript starter/u);
});

if (process.platform === 'win32') test('Windows init rejects aliased reserved paths and output namespaces', async t => {
  const root = await fixture(t);
  await npmProject(root);
  await mkdir(path.join(root, 'src'));
  await writeFile(path.join(root, 'src/main.PS'), 'preserve this case alias');
  await assert.rejects(initProject({ directory: root, version }), /PSC_INIT_CONFLICT/u);
  assert.equal(await readFile(path.join(root, 'src/main.PS'), 'utf8'), 'preserve this case alias');
  await absent(path.join(root, 'PROOFSCRIPT.md'));
  for (const name of ['NUL', 'project.', 'project:stream']) {
    await assert.rejects(initProject({ directory: path.join(root, name), version }), /PSC0_OUTPUT_WINDOWS_PATH/u);
  }
});
