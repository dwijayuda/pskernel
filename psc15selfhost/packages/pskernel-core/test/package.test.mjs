import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import * as publicMetadata from "../metadata.mjs";
const manifest = JSON.parse(await readFile(new URL("../package.json", import.meta.url), "utf8"));
const capabilities = JSON.parse(await readFile(new URL("../CAPABILITIES.json", import.meta.url), "utf8"));
test("new package identity and publication guard", () => {
  assert.equal(manifest.name, "@proofscript/pskernel-core");
  assert.equal(manifest.private, true);
  assert.equal(manifest.proofscript.bootstrap, false);
  assert.equal(manifest.proofscript.portable, false);
});
test("design package has no checking entry point or dependencies", () => {
  assert.deepEqual(manifest.exports, { "./metadata": "./metadata.mjs" });
  assert.deepEqual(Object.keys(publicMetadata), ["kernelMetadata"]);
  for (const field of ["dependencies", "optionalDependencies", "peerDependencies"]) {
    assert.equal(Object.keys(manifest[field] ?? {}).length, 0);
  }
  for (const key of ["preinstall", "install", "postinstall"]) assert.equal(manifest.scripts[key], undefined);
});
test("capability metadata cannot claim a working kernel", () => {
  const metadata = publicMetadata.kernelMetadata;
  assert.equal(metadata.status, "design-only");
  assert.equal(metadata.status, capabilities.status);
  assert.equal(metadata.name, capabilities.package);
  assert.equal(metadata.version, manifest.version);
  assert.equal(metadata.version, capabilities.packageVersion);
  for (const key of ["canCheckProofs", "canAuthorizeEmission", "selfHosted", "leanCompatibilityVerified"]) {
    assert.equal(metadata[key], false);
    assert.equal(capabilities[key], false);
  }
  assert.equal(metadata.targetLeanVersion, capabilities.target.leanVersion);
  assert.equal(metadata.targetLeanCommit, capabilities.target.leanCommit);
  assert.equal(metadata.targetProfile, capabilities.target.profile);
  assert.equal(Object.isFrozen(metadata), true);
  assert.throws(() => { metadata.canCheckProofs = true; }, TypeError);
});
test("reference and target are not mislabeled as measured evidence", () => {
  assert.equal(capabilities.legacyPackage, "@proofscript/pskernel-core.old");
  assert.equal(capabilities.target.profileStatus, "proposed-not-implemented");
  for (const evidence of Object.values(capabilities.evidence)) assert.deepEqual(evidence, []);
});
