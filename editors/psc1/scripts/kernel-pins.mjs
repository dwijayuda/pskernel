// Build-time pins are derived from the verified release archive, never learned
// from a possibly changed extracted installation. This does not run a compiler.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';

export function writeKernelPins(editorRoot, output) {
  const pin = JSON.parse(fs.readFileSync(path.join(editorRoot, 'compiler-input.json'), 'utf8'));
  const program = [
    'import sys,json,zipfile,tarfile,io,hashlib,pathlib',
    'archive,root,name,zip_hash,tar_hash,version,lean_commit=sys.argv[1:]',
    'digest=lambda b:hashlib.sha256(b).hexdigest()',
    'archive_bytes=pathlib.Path(archive).read_bytes()',
    'assert digest(archive_bytes)==zip_hash, "qualified archive hash"',
    'with zipfile.ZipFile(io.BytesIO(archive_bytes)) as z:',
    ' names=[n for n in z.namelist() if pathlib.PurePosixPath(n).name==name]',
    ' assert len(names)==1, "exactly one qualified tarball"',
    ' packed=z.read(names[0])',
    'assert digest(packed)==tar_hash, "qualified compiler tarball hash"',
    'with tarfile.open(fileobj=io.BytesIO(packed),mode="r:gz") as tar:',
    ' members={}',
    ' for member in tar.getmembers():',
    '  p=pathlib.PurePosixPath(member.name)',
    '  assert not p.is_absolute() and ".." not in p.parts and p.parts[0]=="package"',
    '  assert member.isfile() or member.isdir(), "regular package members only"',
    '  if member.isfile():',
    '   assert member.name not in members, "duplicate tar member"',
    '   members[member.name]=member',
    ' def read(relative):',
    '  key="package/"+relative',
    '  assert key in members and 0<members[key].size<=128*1024*1024, "bounded pinned member"',
    '  return tar.extractfile(members[key]).read()',
    ' prefix="dist/implementation/"',
    ' distribution=json.loads(read(prefix+"UNIVERSAL_DISTRIBUTION.json"))',
    ' assert distribution["schema"]=="psc1-universal-npm-distribution/1"',
    ' assert distribution["version"]==version and distribution["leanCommit"]==lean_commit',
    ' assert distribution["defaultKernel"]=="wasm"',
    ' provider=distribution["kernels"]["wasm"]',
    ' assert provider["package"]=="@proofscript/pskernel-lean-wasm" and provider["entry"]=="dist/index.js"',
    ' provider_root="node_modules/@proofscript/pskernel-lean-wasm/"',
    ' selected=set(["package.json","dist/index.js",prefix+"DISTRIBUTION_PIN.mjs",prefix+"UNIVERSAL_DISTRIBUTION.json"])',
    ' for base,records in [(prefix,distribution["hostFiles"]),(provider_root,provider["files"])]:',
    '  for record in records:',
    '   relative=base+record["path"]',
    '   b=read(relative)',
    '   assert len(b)==record["bytes"] and digest(b)==record["sha256"], "distribution resource pin"',
    '   selected.add(relative)',
    ' rows=[]',
    ' package=pathlib.Path(root)',
    ' assert package.is_dir() and not package.is_symlink()',
    ' for relative in sorted(selected):',
    '  b=read(relative)',
    '  actual=package.joinpath(*pathlib.PurePosixPath(relative).parts)',
    '  cursor=actual',
    '  while cursor!=package:',
    '   assert not cursor.is_symlink(), "extracted resource symlink"',
    '   cursor=cursor.parent',
    '  assert actual.is_file() and actual.stat().st_size==len(b) and digest(actual.read_bytes())==digest(b), "extracted resource differs from qualified archive"',
    '  rows.append({"path":relative,"bytes":len(b),"sha256":digest(b)})',
    ' print(json.dumps({"schema":"psc1-editor-kernel-pins/1","compilerTarballSha256":tar_hash,"compilerVersion":version,"leanCommit":lean_commit,"providerEntry":provider_root+provider["entry"],"files":rows}))',
  ].join('\n');
  const result = spawnSync('python3', ['-c', program,
    path.join(editorRoot, 'dist/qualified-compiler.zip'),
    path.join(editorRoot, 'lsp/compiler/package'), pin.tarball, pin.zipSha256,
    pin.tarballSha256, pin.version, pin.leanCommit],
    {encoding: 'utf8', maxBuffer: 8 * 1024 * 1024});
  assert.equal(result.status, 0, result.stderr || result.error?.message || 'Cannot capture qualified kernel pins');
  const pins = JSON.parse(result.stdout);
  assert.equal(pins.compilerTarballSha256, pin.tarballSha256);
  fs.writeFileSync(output, '// Generated from the SHA-verified qualified archive. Do not edit.\n' +
    'const pins = ' + JSON.stringify(pins, null, 2) + ';\n' +
    'for (const file of pins.files) Object.freeze(file);\n' +
    'Object.freeze(pins.files);\nexport default Object.freeze(pins);\n');
}
