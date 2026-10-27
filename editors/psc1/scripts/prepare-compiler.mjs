// Download only the already-qualified immutable compiler; never rebuild it here.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const pin = JSON.parse(fs.readFileSync(path.join(root, 'compiler-input.json')));
const digest = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const output = path.join(root, 'dist');
fs.mkdirSync(output, {recursive: true});
const zip = path.join(output, 'qualified-compiler.zip');
if (!fs.existsSync(zip) || digest(fs.readFileSync(zip)) !== pin.zipSha256) {
  const fetched = spawnSync('gh', ['api', `repos/${pin.repository}/actions/artifacts/${pin.artifactId}/zip`], {maxBuffer: 16 * 1024 * 1024});
  assert.equal(fetched.status, 0, fetched.stderr?.toString() || 'Qualified compiler download failed.');
  assert.equal(digest(fetched.stdout), pin.zipSha256, 'Qualified compiler artifact ZIP hash');
  fs.writeFileSync(zip, fetched.stdout);
}
const extracted = spawnSync('python3', ['-c', [
  'import sys,zipfile,tarfile,pathlib,hashlib,shutil',
  'archive,target,name,expected=sys.argv[1:]',
  'target=pathlib.Path(target)',
  'with zipfile.ZipFile(archive) as z:',
  ' matches=[n for n in z.namelist() if pathlib.PurePosixPath(n).name==name]',
  ' assert len(matches)==1, "qualified tarball must occur exactly once"',
  ' data=z.read(matches[0])',
  ' assert hashlib.sha256(data).hexdigest()==expected, "compiler tarball hash"',
  ' target.mkdir(parents=True,exist_ok=True)',
  ' tgz=target/name; tgz.write_bytes(data)',
  ' if (target/"package").exists(): shutil.rmtree(target/"package")',
  ' with tarfile.open(tgz) as tar:',
  '  for m in tar.getmembers():',
  '   p=pathlib.PurePosixPath(m.name)',
  '   assert not p.is_absolute() and ".." not in p.parts and p.parts[0]=="package"',
  '   assert m.isfile() or m.isdir(), "non-regular compiler member"',
  '  tar.extractall(target,filter="data")',
  ' tgz.unlink()',
].join('\n'), zip, path.join(root, 'lsp/compiler'), pin.tarball, pin.tarballSha256], {encoding: 'utf8'});
assert.equal(extracted.status, 0, extracted.stderr);
fs.copyFileSync(path.join(root, 'compiler-input.json'), path.join(root, 'lsp/compiler/INPUT.json'));
console.log(JSON.stringify({compiler: pin.version, tarballSha256: pin.tarballSha256, source: 'unchanged qualified artifact'}));
