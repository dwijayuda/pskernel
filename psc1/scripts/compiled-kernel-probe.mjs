import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { readQualifiedArtifact, sha256 as sha } from './kernel435-qualified-artifact.mjs';
import { crosscheckCompilerAdmissions } from './crosscheck-compiler-admissions.mjs';
const input = JSON.parse(fs.readFileSync('scripts/compiled-kernel-probe-inputs.json'));
const out = path.resolve('dist/compiler-kernel-probe');
const compilerArchive = await readQualifiedArtifact(input.compiler, path.join(out, 'compiler'));
const directory = path.join(compilerArchive, 'generated-unified-js-compiler');
const q = JSON.parse(fs.readFileSync(path.join(directory, 'qualification.json')));
assert.equal(q.status, 'passed'); assert.equal(q.correctnessQualification, 'G1-only');
assert.equal(q.sourceClosureDigest, '073e5156a3fb521119bcfb4b06ad18ff136e734a0b2e10a676b1e16225835ef9');
const candidate = JSON.parse(fs.readFileSync(path.join(directory, 'G1-bootstrap.candidate.json')));
const admissions = candidate.admissionRequest.admissions;
assert.equal(sha(admissions), q.bootstrap.admissionsSha256);
const admissionFile = path.join(out, 'compiler-admissions.json'); fs.writeFileSync(admissionFile, admissions);
const kernelArchive = await readQualifiedArtifact(input.kernels, path.join(out, 'kernels'));
const receipt = JSON.parse(fs.readFileSync(path.join(kernelArchive, 'package-receipt.json')));
const roots = {};
for (const [provider, key] of [['wasm', 'wasmKernel'], ['native', 'nativeKernel']]) {
  const metadata = receipt.input.packages[key];
  const tarball = path.join(kernelArchive, 'tarballs', metadata.tarball);
  assert.equal(sha(fs.readFileSync(tarball)), metadata.sha256);
  const destination = path.join(out, provider); fs.mkdirSync(destination);
  const result = spawnSync('tar', ['xzf', tarball, '-C', destination], {
    encoding: 'utf8', timeout: 120000, maxBuffer: 32 * 1024 * 1024 });
  assert.equal(result.status, 0, result.stderr);
  roots[provider] = path.join(destination, 'package');
}
await crosscheckCompilerAdmissions({ sourceClosureDigest: q.sourceClosureDigest,
  admissions: [{ file: admissionFile, sha256: q.bootstrap.admissionsSha256 }],
  kernelRoots: roots, outputFile: path.join(out, 'qualification.json') });
