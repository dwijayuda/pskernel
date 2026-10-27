import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const out = path.join(root, 'dist');
const extensionVersion = JSON.parse(fs.readFileSync(path.join(root, 'vscode/package.json'))).version;
fs.mkdirSync(out, {recursive: true});
const run = (cmd, args, cwd) => {
  const result = spawnSync(cmd, args, {cwd, encoding: 'utf8', maxBuffer: 16 * 1024 * 1024});
  if (result.stdout) process.stdout.write(result.stdout);
  if (result.stderr) process.stderr.write(result.stderr);
  assert.equal(result.status, 0, `${cmd} failed`);
};
run('npm', ['pack', '--ignore-scripts', '--pack-destination', out], path.join(root, 'lsp'));
run(process.execPath, [path.join(root, 'node_modules/@vscode/vsce/vsce'), 'package', '--no-dependencies', '--allow-missing-repository', '--out', path.join(out, `proofscript-psc1-${extensionVersion}.vsix`)], path.join(root, 'vscode'));
const files = fs.readdirSync(out).filter(file => /\.(vsix|tgz)$/.test(file)).sort().map(file => {
  const bytes = fs.readFileSync(path.join(out, file));
  return {file, bytes: bytes.length, sha256: crypto.createHash('sha256').update(bytes).digest('hex')};
});
const receipt = {schema: 'psc1-editor-build/1', commit: process.env.GITHUB_SHA || 'development',
  run: process.env.GITHUB_RUN_ID || null, compiler: JSON.parse(fs.readFileSync(path.join(root, 'compiler-input.json'))),
  node: process.version, platform: process.platform, files, published: false, compilerRebuilt: false};
fs.writeFileSync(path.join(out, 'BUILD.json'), JSON.stringify(receipt, null, 2) + '\n');
fs.writeFileSync(path.join(out, 'SHA256SUMS'), files.map(file => `${file.sha256}  ${file.file}`).join('\n') + '\n');
console.log('PSC1_EDITOR_BUILD ' + JSON.stringify(receipt));
