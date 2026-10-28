// Immutable graph validation before dynamic import. Hashes require a trusted,
// stable build manifest; neither npm metadata nor this verifier is a sandbox.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import { sha256 } from './tools.mjs';

export function readManifestBytes(file) {
  const stat = fs.lstatSync(file);
  assert.ok(
    stat.isFile() && !stat.isSymbolicLink() && stat.size > 0 && stat.size <= 33554432,
    'PSC1_EXECUTABLE_MANIFEST_FILE_BOUND',
  );
  return fs.readFileSync(file);
}

// Reject unexpected paths and oversized files before reading their bytes.
function checkedInventory(root, records, bootstrapPin = null) {
  const expected = new Map(records.map((row) => [row.path, row])),
    directories = new Set(['']);
  for (const row of records) {
    const parts = row.path.split('/');
    for (let i = 1; i < parts.length; i++) directories.add(parts.slice(0, i).join('/'));
  }
  const observed = [];
  const visit = (relative) => {
    for (const name of fs.readdirSync(path.join(root, relative)).sort()) {
      const file = relative ? relative + '/' + name : name,
        absolute = path.join(root, file),
        stat = fs.lstatSync(absolute);
      assert.ok(!stat.isSymbolicLink(), 'PSC1_EXECUTABLE_SYMLINK');
      if (stat.isDirectory()) {
        assert.ok(directories.has(file), 'PSC1_EXECUTABLE_UNEXPECTED_DIRECTORY');
        visit(file);
      } else {
        if (file === bootstrapPin) {
          assert.ok(
            stat.isFile() && stat.size > 0 && stat.size <= 4096,
            'PSC1_EXECUTABLE_BOOTSTRAP_PIN',
          );
          continue; // This trusted bootstrap seal cannot include its own digest.
        }
        const row = expected.get(file);
        assert.ok(stat.isFile() && row, 'PSC1_EXECUTABLE_UNEXPECTED_FILE');
        assert.equal(stat.size, row.bytes, 'PSC1_EXECUTABLE_FILE_SIZE');
        const bytes = fs.readFileSync(absolute);
        observed.push({ path: file, bytes: bytes.length, sha256: sha256(bytes) });
      }
    }
  };
  visit('');
  return observed;
}
export function verify(root, manifestBytes, expectedHash) {
  assert.equal(sha256(manifestBytes), expectedHash, 'PSC1_EXECUTABLE_MANIFEST_HASH');
  const manifest = JSON.parse(manifestBytes);
  const installed = manifest.schema === 'psc1-installed-executable-npm-graph/1';
  assert.ok(installed || manifest.schema === 'psc1-executable-npm-graph/1');
  const packagePrefix = installed ? '' : 'node_modules/';
  const bootstrapPin = installed ? '@proofscript/compiler/dist/host/DISTRIBUTION_PIN.mjs' : null;
  if (installed) {
    assert.ok(Array.isArray(manifest.files) && manifest.files.length <= 8192);
    assert.ok(Array.isArray(manifest.packages) && manifest.packages.length <= 257);
    assert.equal(manifest.bootstrapPin, bootstrapPin);
    assert.ok(!manifest.files.some((row) => row.path === bootstrapPin));
    const pin = path.join(root, bootstrapPin),
      stat = fs.lstatSync(pin);
    assert.ok(stat.isFile() && !stat.isSymbolicLink() && stat.size > 0 && stat.size <= 4096);
    const origin = manifest.sourceGraph;
    assert.match(origin.manifestSha256, /^[a-f0-9]{64}$/);
    assert.equal(sha256(JSON.stringify(origin.manifest, null, 2) + '\n'), origin.manifestSha256);
    assert.equal(origin.manifest.schema, 'psc1-executable-npm-graph/1');
    assert.ok(Array.isArray(origin.manifest.files) && origin.manifest.files.length <= 8192);
    assert.ok(Array.isArray(origin.manifest.units) && origin.manifest.units.length <= 257);
    assert.ok(Array.isArray(origin.manifest.owners) && origin.manifest.owners.length <= 8192);
    for (const key of [
      'protocol',
      'sourceClosureDigest',
      'compilerAssurance',
      'partialNames',
      'runtimeOwner',
      'logicalAdmission',
      'checkerCommit',
      'admissionsDigest',
      'units',
      'owners',
    ])
      assert.deepEqual(manifest[key], origin.manifest[key], 'PSC1_EXECUTABLE_ORIGIN:' + key);
    for (const variant of ['js', 'ts'])
      assert.equal(
        manifest.entry[variant],
        origin.manifest.entry[variant].replace(/^node_modules\//, ''),
      );
    const actual = new Map(manifest.files.map((row) => [row.path, row]));
    for (const row of origin.manifest.files) {
      if (row.path.endsWith('/package.json')) continue; // Versioned host/API metadata only.
      const target = actual.get(row.path.replace(/^node_modules\//, ''));
      assert.deepEqual(
        target,
        { ...row, path: row.path.replace(/^node_modules\//, '') },
        'PSC1_EXECUTABLE_ORIGINAL_FILE',
      );
    }
    for (const source of origin.manifest.packages) {
      const target = manifest.packages.find((row) => row.name === source.name);
      assert.ok(target);
      for (const dependency of Object.keys(source.dependencies))
        assert.ok(Object.hasOwn(target.dependencies, dependency), 'PSC1_EXECUTABLE_ORIGINAL_EDGE');
    }
  }
  assert.equal(manifest.protocol, 'psc1-executable-compiler/1');
  assert.equal(manifest.logicalAdmission, 'accepted');
  assert.equal(manifest.compilerAssurance, 'ordinary-checked');
  assert.ok(Array.isArray(manifest.partialNames));
  assert.equal(manifest.checkerCommit, 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc');
  assert.match(manifest.sourceClosureDigest, /^[0-9a-f]{64}$/);
  assert.equal(manifest.runtimeOwner, '@proofscript/foundation');
  assert.ok(Array.isArray(manifest.files) && manifest.files.length <= 8192);
  const seen = new Set();
  let total = 0;
  for (const row of manifest.files) {
    assert.equal(typeof row.path, 'string');
    assert.ok(
      Buffer.byteLength(row.path) <= 1024 && row.path.split('/').length <= 16,
      'PSC1_EXECUTABLE_PATH_BOUND',
    );
    assert.ok(
      !row.path.includes('\\') &&
        !path.posix.isAbsolute(row.path) &&
        row.path.split('/').every((p) => p && p !== '.' && p !== '..'),
      'PSC1_EXECUTABLE_UNSAFE_PATH',
    );
    assert.ok(!seen.has(row.path), 'PSC1_EXECUTABLE_DUPLICATE_PATH');
    seen.add(row.path);
    assert.ok(Number.isSafeInteger(row.bytes) && row.bytes >= 0 && row.bytes <= 33554432);
    total += row.bytes;
    assert.ok(total <= 134217728);
  }
  assert.deepEqual(
    checkedInventory(root, manifest.files, bootstrapPin),
    manifest.files,
    'PSC1_EXECUTABLE_GRAPH_INVENTORY',
  );
  assert.ok(
    Array.isArray(manifest.units) && manifest.units.length >= 2 && manifest.units.length <= 257,
  );
  assert.ok(
    Array.isArray(manifest.packages) &&
      manifest.packages.length >= 1 &&
      manifest.packages.length <= 257,
  );
  assert.ok(Array.isArray(manifest.owners) && manifest.owners.length <= 8192);
  const names = new Set(manifest.packages.map((p) => p.name));
  assert.equal(names.size, manifest.packages.length, 'PSC1_EXECUTABLE_DUPLICATE_PACKAGE');
  const graph = new Map(
    manifest.packages.map((p) => [
      p.name,
      [
        ...Object.keys(p.dependencies),
        ...Object.keys(p.peerDependencies || {}).filter((n) => names.has(n)),
      ],
    ]),
  );
  const done = new Set(),
    active = new Set();
  const visit = (name) => {
    assert.ok(names.has(name), 'PSC1_EXECUTABLE_UNDECLARED_PACKAGE');
    assert.ok(!active.has(name), 'PSC1_EXECUTABLE_PACKAGE_CYCLE');
    if (done.has(name)) return;
    active.add(name);
    for (const dependency of graph.get(name)) visit(dependency);
    active.delete(name);
    done.add(name);
  };
  for (const p of manifest.packages) {
    assert.match(p.name, /^@proofscript\/[a-z0-9-]+$/);
    visit(p.name);
    const metadata = JSON.parse(
      fs.readFileSync(path.join(root, packagePrefix, p.name, 'package.json')),
    );
    assert.equal(metadata.name, p.name);
    assert.equal(metadata.version, installed ? p.version : manifest.version);
    if (installed) {
      assert.match(p.version, /^[0-9]+\.[0-9]+\.[0-9]+(?:-[A-Za-z0-9.-]+)?$/);
      assert.deepEqual(metadata.peerDependencies || {}, p.peerDependencies || {});
      assert.ok(
        !metadata.scripts ||
          !['preinstall', 'install', 'postinstall'].some((k) => k in metadata.scripts),
      );
      assert.ok(!Object.hasOwn(p.dependencies, 'proofscript'));
    }
    assert.deepEqual(
      installed && metadata.dependencies === undefined ? {} : metadata.dependencies,
      p.dependencies,
    );
  }
  const owners = manifest.owners.map((row) => row[0]);
  assert.equal(new Set(owners).size, owners.length, 'PSC1_EXECUTABLE_DUPLICATE_OWNER');
  assert.deepEqual(
    [...owners].sort(),
    manifest.units.flatMap((u) => u.names).sort(),
    'PSC1_EXECUTABLE_OWNER_COVERAGE',
  );
  for (const variant of ['js', 'ts']) {
    assert.ok(manifest.entry[variant].startsWith(packagePrefix + '@proofscript/compiler/'));
    assert.ok(seen.has(manifest.entry[variant]), 'PSC1_EXECUTABLE_ENTRY');
  }
  return manifest;
}
