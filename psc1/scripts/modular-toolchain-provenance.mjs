// Build-time provenance only. No graph code executes until the checked host admits it.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import { readQualifiedArtifact, sha256 } from './kernel435-qualified-artifact.mjs';
import { verify, readManifestBytes } from '../host-tools/executable/verify.mjs';

export async function readQualifiedModularGraph(input, destination) {
  assert.equal(input.schema, 'psc1-qualified-modular-graph-input/1');
  assert.ok(
    [
      'docs/PSC1_PORTABLE_MODULAR_QUALIFICATION_2026-10-29.json',
      'docs/PSC1_WIRE_MODULAR_QUALIFICATION_2026-10-29.json',
    ].includes(input.qualificationReceipt),
  );
  const receiptBytes = fs.readFileSync(input.qualificationReceipt);
  const receipt = JSON.parse(receiptBytes);
  assert.equal(receipt.schema, 'psc1-portable-modular-qualification/1');
  assert.equal(receipt.status, 'qualified-finite-linux-modular-js-ts');
  assert.equal(receipt.generationRun, input.artifact.run);
  assert.equal(receipt.generationRun, input.crossCheckArtifact.run);
  assert.equal(receipt.testedImplementationCommit, input.artifact.commit);
  assert.equal(receipt.testedImplementationCommit, input.crossCheckArtifact.commit);
  assert.equal(receipt.sourceCommit, input.sourceCommit);
  assert.equal(receipt.sourceClosureDigest, input.compilerSourceClosureDigest);
  const graphs = {};
  for (const [variant, pin] of [
    ['js', input.artifact],
    ['ts', input.crossCheckArtifact],
  ]) {
    const archive = await readQualifiedArtifact(pin, path.join(destination, variant));
    const directory = path.join(archive, 'selfhost-' + variant);
    const report = JSON.parse(fs.readFileSync(path.join(directory, 'qualification.json')));
    assert.deepEqual(
      report,
      receipt.generations[variant].report,
      'PSC1_INSTALL_SELFHOST_TRANSCRIPTION',
    );
    assert.equal(report.status, 'passed');
    assert.equal(report.nativeFrontendCalls, 0);
    assert.equal(report.fixedPoint, 'exact-G1-G2-G3-graph-files-and-npm-tarballs');
    assert.equal(report.correctnessQualification, 'qualified-finite-linux-scope');
    assert.equal(report.g1ManifestSha256, input.manifestSha256);
    assert.deepEqual(
      report.generations.map((row) => row.generation),
      [2, 3],
    );
    for (const row of report.generations) {
      assert.equal(row.status, 'qualified-generated-modular-compiler');
      assert.equal(row.execution.status, 0);
      assert.equal(row.execution.timeoutPolicy, 'g2g3-correctness-3600s');
      assert.equal(row.independentAdmission.accepted, true);
      assert.equal(row.independentAdmission.checkerCommit, receipt.preservation.leanCommit);
      assert.equal(
        row.independentAdmission.admissionsDigest,
        receipt.portableG1Seed.independentAdmission.admissionsDigest,
      );
      assert.equal(row.manifestSha256, input.manifestSha256);
      assert.equal(row.fullGraphByteIdentity, true);
      assert.equal(row.originalAndTransformedIrIdentity, true);
      assert.equal(row.renderedNativeReferenceIdentity, true);
      assert.deepEqual(row.packages, report.generations[0].packages);
      const stage = path.join(directory, 'G' + row.generation);
      const manifestBytes = readManifestBytes(path.join(stage, 'manifest.json'));
      const graphRoot = path.join(stage, 'candidate');
      const manifest = verify(graphRoot, manifestBytes, input.manifestSha256);
      assert.equal(manifest.sourceClosureDigest, input.compilerSourceClosureDigest);
      assert.equal(manifest.compilerCommit, input.sourceCommit);
      assert.equal(manifest.units.length, input.units);
      assert.equal(manifest.packages.length, input.packages);
      assert.equal(manifest.files.length, input.files);
      assert.equal(
        manifest.files.reduce((n, file) => n + file.bytes, 0),
        input.bytes,
      );
      for (const pkg of row.packages) {
        assert.match(pkg.filename, /^[A-Za-z0-9_.-]+[.]tgz$/);
        const bytes = fs.readFileSync(path.join(stage, 'tarballs', pkg.filename));
        assert.equal(bytes.length, pkg.bytes);
        assert.equal(sha256(bytes), pkg.sha256, 'PSC1_INSTALL_SELFHOST_TARBALL');
      }
      assert.equal(
        sha256(fs.readFileSync(path.join(stage, 'admissions.json'))),
        manifest.admissionsDigest,
      );
      if (row.generation === 3)
        graphs[variant] = { archive: stage, root: graphRoot, manifest, manifestBytes };
    }
  }
  assert.deepEqual(graphs.js.manifestBytes, graphs.ts.manifestBytes);
  assert.deepEqual(
    receipt.generations.js.report.generations[1].packages,
    receipt.generations.ts.report.generations[1].packages,
    'PSC1_INSTALL_CROSS_ENGINE_FIXED_POINT',
  );
  const qualification = {
    schema: 'psc1-installed-compiler-selfhosting/1',
    status: receipt.status,
    engines: ['js', 'ts'],
    qualificationRun: receipt.generationRun,
    sourceCommit: input.sourceCommit,
    sourceClosureDigest: input.compilerSourceClosureDigest,
    sourceGraphManifestSha256: input.manifestSha256,
    receiptSha256: sha256(receiptBytes),
    receiptPath: 'dist/COMPILER_SELFHOST_QUALIFICATION.json',
    fixedPoint: 'exact-G1-G2-G3-graph-files-and-npm-tarballs',
    qualifiedCorrectnessSeconds: 3600,
    performance240Qualified: false,
    installedHostQualification: 'separate installation CI; not inherited from self-hosting',
    scope:
      'finite Linux JS/TS compiler graph; not universal toolchain release or native binary reproduction',
  };
  return { ...graphs.js, qualification, receiptBytes };
}
