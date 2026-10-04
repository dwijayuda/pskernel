import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { test } from "node:test";

import {
  assertRuntimeSemanticsManifest,
  runtimeSemanticsV1,
  runtimeSemanticsV1Canonical,
  runtimeSemanticsV1PackageFolders,
  runtimeSemanticsV1Sha256,
} from "./runtime-semantics-contract.mjs";

const scriptsDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptsDir, "..");

test("RuntimeSemantics-v1 identity is frozen", () => {
  assert.equal(runtimeSemanticsV1.id, "psc-runtime-semantics/1");
  assert.equal(
    runtimeSemanticsV1Sha256,
    "d610e1a1936dd1b090a44a8293a68436bc9300ad5c82872e8faf4e1e6b97ae03",
  );
  assert.equal(runtimeSemanticsV1.sha256, runtimeSemanticsV1Sha256);
  assert.equal(Object.isFrozen(runtimeSemanticsV1), true);
  assert.equal(
    runtimeSemanticsV1Canonical,
    "psc-runtime-semantics/1\nnat=unbounded-nonnegative;sub=saturating-zero;div0=zero;mod0=lhs\nint=unbounded-signed;ofNat=embedding;negSucc=-(n+1)\nmachine-int=fixed-width-twos-complement;binary=mod-2^width;compare=signedness;word-size=target-profile\nfloat=f64-ieee754;float32=f32-ieee754;float32-binary=round-f32\nbool=two-valued\nchar=unicode-scalar;ofNat-invalid=U+0000;toNat=code-point\nstring=unicode-scalar-sequence;length=scalar-count;position=utf8-byte-offset;index-domain=utf8-boundaries;append=concat;eq=sequence\narray=persistent-sequence;size=nat;push=append-one;get=in-bounds;getD=oob-fallback;set=in-bounds;setIfInBounds=oob-identity;map=ordered;foldl=[start,min(stop,size))\nrecord=immutable-named-fields;projection=field-value\nadt=constructor-tagged;match=constructor-dispatch;bindings=declared-fields\nclosure=lexical-capture;call=call-by-value;argument-order=left-to-right\nunsupported=reject-no-fallback\n",
  );
});

for (const folder of runtimeSemanticsV1PackageFolders) {
  test(`${folder} declares RuntimeSemantics-v1`, async () => {
    const manifest = JSON.parse(
      await readFile(path.join(root, "packages", folder, "package.json"), "utf8"),
    );
    assertRuntimeSemanticsManifest(manifest, folder);
  });
}

test("manifest contract rejects an alternate runtime identity", () => {
  assert.throws(
    () =>
      assertRuntimeSemanticsManifest(
        {
          proofscript: {
            runtimeSemantics: {
              id: "psc-runtime-semantics/2",
              sha256: runtimeSemanticsV1.sha256,
            },
          },
        },
        "fixture",
      ),
    /PSC2_RUNTIME_SEMANTICS_ID/u,
  );
});

test("manifest contract rejects an alternate runtime hash", () => {
  assert.throws(
    () =>
      assertRuntimeSemanticsManifest(
        {
          proofscript: {
            runtimeSemantics: {
              id: runtimeSemanticsV1.id,
              sha256: "0".repeat(64),
            },
          },
        },
        "fixture",
      ),
    /PSC2_RUNTIME_SEMANTICS_HASH/u,
  );
});
