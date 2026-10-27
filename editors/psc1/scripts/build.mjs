import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {build} from 'esbuild';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const lsp = path.join(root, 'lsp'), vscode = path.join(root, 'vscode');
if (!fs.existsSync(path.join(lsp, 'compiler/package/dist/index.js'))) throw Error('Run npm run prepare:compiler first.');
fs.rmSync(path.join(lsp, 'dist'), {recursive: true, force: true});
fs.mkdirSync(path.join(lsp, 'dist'), {recursive: true});
fs.mkdirSync(path.join(vscode, 'dist'), {recursive: true});
await build({entryPoints: [path.join(lsp, 'src/server.mjs')], outfile: path.join(lsp, 'dist/server.cjs'),
  platform: 'node', format: 'cjs', target: 'node22', bundle: true, sourcemap: false,
  banner: {js: '#!/usr/bin/env node'}, legalComments: 'eof'});
fs.chmodSync(path.join(lsp, 'dist/server.cjs'), 0o755);
for (const name of ['worker.mjs', 'checked-types.mjs']) fs.copyFileSync(path.join(lsp, 'src', name), path.join(lsp, 'dist', name));
await build({entryPoints: [path.join(vscode, 'src/extension.cjs')], outfile: path.join(vscode, 'dist/extension.cjs'),
  platform: 'node', format: 'cjs', target: 'node22', bundle: true, sourcemap: false, external: ['vscode'], legalComments: 'eof'});
for (const target of [lsp, vscode]) for (const name of ['LICENSE', 'NOTICE'])
  fs.copyFileSync(path.join(root, '../..', name), path.join(target, name));
// Retain the bundled dependency licenses as well as the compiler's complete,
// unchanged upstream notices. No dependency license is replaced by ours.
const notices = [];
for (const name of ['vscode-languageserver', 'vscode-languageserver-textdocument', 'vscode-languageserver-protocol', 'vscode-languageserver-types', 'vscode-jsonrpc', 'vscode-languageclient', 'minimatch', 'brace-expansion', 'balanced-match', 'semver']) {
  const packageRoot = path.join(root, 'node_modules', name);
  if (!fs.existsSync(packageRoot)) continue;
  const meta = JSON.parse(fs.readFileSync(path.join(packageRoot, 'package.json')));
  notices.push(`${meta.name}@${meta.version}\n${meta.license || ''}`);
  for (const file of fs.readdirSync(packageRoot).filter(file => /^(licen[cs]e|copying|notice)(\.|$)/i.test(file)))
    if (fs.statSync(path.join(packageRoot, file)).isFile()) notices.push(fs.readFileSync(path.join(packageRoot, file), 'utf8'));
}
for (const target of [lsp, vscode]) fs.writeFileSync(path.join(target, 'THIRD_PARTY_NOTICES.txt'), notices.join('\n\n---\n\n') + '\n');
const server = path.join(vscode, 'server');
fs.rmSync(server, {recursive: true, force: true});
fs.mkdirSync(server, {recursive: true});
for (const dir of ['dist', 'compiler']) fs.cpSync(path.join(lsp, dir), path.join(server, dir), {recursive: true});
console.log('Built standalone stdio server and VS Code client with unchanged bundled compiler.');
