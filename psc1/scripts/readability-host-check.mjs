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
  const source = fs.readFileSync(path.join(root, file), 'utf8');
  assert.deepEqual(executableAst(source), executableAst(original.stdout),
    file + ': executable AST changed from the immutable cleanup baseline');
  const formatted = await prettier.format(source, formatOptions);
  assert.deepEqual(executableAst(formatted), executableAst(source),
    file + ': formatter changed executable AST');
  if (propose) proposal[file] = formatted;
  else assert.equal(source, formatted, file + ': run pinned scoped formatter');
  results.push({file, executableAstMatchesBaseline: true,
    formatted: source === formatted, lines: source.split('\n').length});
}
const out = path.join(root, 'dist/readability');
fs.mkdirSync(out, {recursive: true});
fs.writeFileSync(path.join(out, 'host.json'), JSON.stringify({
  schema: 'psc1-readability-host/1', commit: process.env.GITHUB_SHA,
  baseline, mode: propose ? 'proposal-not-qualification' : 'check',
  formatter: 'prettier@3.6.2', parser: '@babel/parser@7.28.0', results,
}, null, 2) + '\n');
if (propose) console.log('PSC1_HOST_FORMAT_PROPOSAL=' + JSON.stringify(proposal));
else console.log('PSC1_READABILITY_HOST: PASS ' + JSON.stringify(results));
