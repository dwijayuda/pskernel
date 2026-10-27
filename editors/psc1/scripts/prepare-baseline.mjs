// A fixed earlier deliverable for a same-runner before/after measurement.
// This is benchmark input only and never enters either new distributable.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const out = path.join(root, 'dist');
const pin = {
  schema: 'psc1-editor-performance-baseline/1', version: '0.1.0',
  commit: '34beabcfc3fce89e4c89bcc6aa4e372e0c1bdeb1',
  runId: 40585721463, artifactId: 12772441610,
  zipSha256: 'e350b263662d2cf4d321ed8181e3e134ff10494e3deab7f9d25efa84ae471cf0',
  tarball: 'proofscript-lsp-0.1.0.tgz',
  tarballSha256: '29f46476552dfb33a0756b02a1a6e2797b6079195ec222fe547ce651bafae2cd',
};
fs.mkdirSync(out, {recursive: true});
const fetched = spawnSync('gh', ['api', `repos/dwijayuda/pskernel/actions/artifacts/${pin.artifactId}/zip`],
  {maxBuffer: 16 * 1024 * 1024});
assert.equal(fetched.status, 0, fetched.stderr?.toString() || 'Previous editor download failed.');
assert.equal(crypto.createHash('sha256').update(fetched.stdout).digest('hex'), pin.zipSha256);
const archive = path.join(out, 'baseline-editor.zip');
fs.writeFileSync(archive, fetched.stdout);
const extraction = spawnSync('python3', ['-c', [
  'import sys,zipfile,tarfile,pathlib,hashlib,io',
  'archive,target,name,expected=sys.argv[1:]',
  'target=pathlib.Path(target); target.mkdir(parents=True,exist_ok=True)',
  'with zipfile.ZipFile(archive) as z:',
  ' names=[n for n in z.namelist() if pathlib.PurePosixPath(n).name==name]',
  ' assert len(names)==1',
  ' data=z.read(names[0]); assert hashlib.sha256(data).hexdigest()==expected',
  ' with tarfile.open(fileobj=io.BytesIO(data),mode="r:gz") as tar:',
  '  for m in tar.getmembers():',
  '   p=pathlib.PurePosixPath(m.name)',
  '   assert not p.is_absolute() and ".." not in p.parts and p.parts[0]=="package"',
  '   assert m.isfile() or m.isdir()',
  '  tar.extractall(target,filter="data")',
].join('\n'), archive, path.join(out, 'baseline'), pin.tarball, pin.tarballSha256], {encoding: 'utf8'});
assert.equal(extraction.status, 0, extraction.stderr);
fs.writeFileSync(path.join(out, 'baseline-input.json'), JSON.stringify(pin, null, 2) + '\n');
console.log('Verified prior 0.1.0 npm package for the controlled latency comparison.');
