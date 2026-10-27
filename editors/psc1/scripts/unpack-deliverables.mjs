// Native CI consumes the exact Linux-built archive, rather than rebuilding a
// platform-specific substitute for the package the user will install.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const delivered = path.join(root, 'delivered');
const candidates = [path.join(delivered, 'dist'), delivered];
const input = candidates.find(directory => fs.existsSync(path.join(directory, 'BUILD.json')));
assert.ok(input, 'Delivered build receipt is present.');
const build = JSON.parse(fs.readFileSync(path.join(input, 'BUILD.json')));
assert.equal(build.commit, process.env.GITHUB_SHA, 'Native qualification uses this exact implementation.');
const out = path.join(root, 'dist');
fs.mkdirSync(out, {recursive: true});
for (const file of build.files) {
  assert.equal(path.basename(file.file), file.file);
  const data = fs.readFileSync(path.join(input, file.file));
  assert.equal(data.length, file.bytes);
  assert.equal(crypto.createHash('sha256').update(data).digest('hex'), file.sha256);
  fs.writeFileSync(path.join(out, file.file), data);
}
const tarball = build.files.find(file => /^proofscript-lsp-.*\.tgz$/.test(file.file));
assert.ok(tarball);
// Relative archive paths avoid GNU tar interpreting a Windows drive colon as a
// remote-host separator. Forward slashes work in both native and Git Bash tar.
const unpack = spawnSync('tar', ['-xzf', `dist/${tarball.file}`, '--strip-components=1', '-C', 'lsp'],
  {cwd: root, encoding: 'utf8', windowsHide: true});
assert.equal(unpack.status, 0, unpack.stderr || unpack.error?.message);
fs.writeFileSync(path.join(out, 'delivered-build-receipt.json'), JSON.stringify(build, null, 2) + '\n');
console.log('Native runtime will execute the SHA-256 verified Linux-built npm server and VSIX.');
