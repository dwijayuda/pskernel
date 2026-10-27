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
  schema: 'psc1-editor-performance-baseline/1', version: '0.1.1',
  commit: '45818c359a9005ea98ac38117d3dab473ded8ce8',
  runId: 40591485183, artifactId: 12773214308,
  zipSha256: 'a65cc86e0d2f3b26271a9a572006826f5690df5e0845c7fc9d3012664b006ce9',
  tarball: 'proofscript-lsp-0.1.1.tgz',
  tarballSha256: '5b0e05b2e7f2627c44b7cb22fe7db636d66d1f26bf4921a56617d28e0f2ff1cb',
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
console.log('Verified prior 0.1.1 npm package for the controlled latency comparison.');
