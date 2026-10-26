// A bounded correspondence guard for the first handwritten host cleanup.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const require = createRequire(path.join(root, 'host-tools/package.json'));
const prettier = require('prettier');
const {parse} = require('@babel/parser');
const baseline = '3089cbc369bc8a11f540c13140c7003c9dadf4a8';
const cleanupCommit = '446a0f21c6288a7c20b843bbeadcd18ba1460fa2';
// Intentional checked-target/publication features have separate behavior qualification.
// Preserve the original cleanup proof; do not call these features formatting.
const featureBaselines = {
  'host-tools/installed-engine-resolver.mjs': '943057c61fd3a3fce7caa0760d5a8e3a89b4e337',
  'npm-cli/universal.mjs': 'dc0f1a3225ea5fa34a7edcbb9a2d66595db274a3',
  'npm-cli/universal-cli.mjs': 'dc0f1a3225ea5fa34a7edcbb9a2d66595db274a3',
};
const featureQualification = 'docs/PSC1_CHECKED_DISPATCH_QUALIFICATION_2026-10-26.json';
const files = [
  'host-tools/installed-engine-resolver.mjs',
  'npm-cli/universal.mjs',
  'npm-cli/universal-cli.mjs',
];
const formatOptions = {parser: 'babel', singleQuote: true, printWidth: 100};
const ignoredMetadata = new Set([
  'start', 'end', 'loc', 'extra', 'comments',
  'leadingComments', 'trailingComments', 'innerComments',
]);
const executableAst = source => JSON.parse(JSON.stringify(
  parse(source, {sourceType: 'module'}),
  (key, value) => ignoredMetadata.has(key) ? undefined : value,
));
const propose = process.argv.length === 3 && process.argv[2] === '--propose';
assert.ok(propose || process.argv.length === 2, 'expected [--propose]');
assert.equal(require('prettier/package.json').version, '3.6.2');
assert.equal(require('@babel/parser/package.json').version, '7.28.0');

const proposal = {};
const results = [];
for (const file of files) {
  const original = spawnSync('git', ['show', baseline + ':psc1/' + file], {
    cwd: root, encoding: 'utf8', timeout: 10000, maxBuffer: 1024 * 1024,
  });
  assert.equal(original.status, 0, file + '\n' + original.stderr);
  const cleanup = spawnSync('git', ['show', cleanupCommit + ':psc1/' + file], {
    cwd: root, encoding: 'utf8', timeout: 10000, maxBuffer: 1024 * 1024,
  });
  assert.equal(cleanup.status, 0, file + '\n' + cleanup.stderr);
  assert.deepEqual(executableAst(cleanup.stdout), executableAst(original.stdout),
    file + ': original cleanup correspondence changed');
  const feature = spawnSync('git', ['show', featureBaselines[file] + ':psc1/' + file], {
    cwd: root, encoding: 'utf8', timeout: 10000, maxBuffer: 1024 * 1024,
  });
  assert.equal(feature.status, 0, file + '\n' + feature.stderr);
  const source = fs.readFileSync(path.join(root, file), 'utf8');
  assert.deepEqual(executableAst(source), executableAst(feature.stdout),
    file + ': executable AST changed from the explicit feature baseline');
  const formatted = await prettier.format(source, formatOptions);
  assert.deepEqual(executableAst(formatted), executableAst(source),
    file + ': formatter changed executable AST');
  if (propose) proposal[file] = formatted;
  else assert.equal(source, formatted, file + ': run pinned scoped formatter');
  results.push({file, originalCleanupAstCorrespondence: true, featureBaseline: featureBaselines[file],
    featureQualification, executableAstMatchesBaseline: true,
    formatted: source === formatted, lines: source.split('\n').length});
}

const newModules = [
  'host-tools/checked-component.mjs',
  'host-tools/checked-optional-provider.mjs',
  'host-tools/checked-targets.mjs',
  'host-tools/generated-compiler-session.mjs',
];
for (const file of newModules) {
  const featureBaseline = '7062f6823b434657e433caae21a03238f6bbb685';
  const feature = spawnSync('git', ['show', featureBaseline + ':psc1/' + file], {
    cwd: root, encoding: 'utf8', timeout: 10000, maxBuffer: 1024 * 1024,
  });
  assert.equal(feature.status, 0, file + '\n' + feature.stderr);
  const source = fs.readFileSync(path.join(root, file), 'utf8');
  assert.deepEqual(executableAst(source), executableAst(feature.stdout),
    file + ': new dispatch module changed from its explicit feature baseline');
  const formatted = await prettier.format(source, formatOptions);
  assert.deepEqual(executableAst(formatted), executableAst(source),
    file + ': formatter changed executable AST');
  if (propose) proposal[file] = formatted;
  else assert.equal(source, formatted, file + ': run pinned scoped formatter');
  results.push({file, originalCleanupAstCorrespondence: 'not-claimed-new-module',
    featureBaseline, featureQualification, executableAstMatchesBaseline: true,
    formatted: source === formatted, lines: source.split('\n').length});
}

const out = path.join(root, 'dist/readability');
fs.mkdirSync(out, {recursive: true});
fs.writeFileSync(path.join(out, 'host.json'), JSON.stringify({
  schema: 'psc1-readability-host/1', commit: process.env.GITHUB_SHA,
  baseline, cleanupCommit, featureBaselines, featureQualification,
  mode: propose ? 'proposal-not-qualification' : 'check',
  formatter: 'prettier@3.6.2', parser: '@babel/parser@7.28.0', results,
}, null, 2) + '\n');
if (propose) console.log('PSC1_HOST_FORMAT_PROPOSAL=' + JSON.stringify(proposal));
else console.log('PSC1_READABILITY_HOST: PASS ' + JSON.stringify(results));
