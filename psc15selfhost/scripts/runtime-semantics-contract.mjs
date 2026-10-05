import { createHash } from "node:crypto";

export const runtimeSemanticsV1Canonical = "psc-runtime-semantics/1\nnat=unbounded-nonnegative;sub=saturating-zero;div0=zero;mod0=lhs\nint=unbounded-signed;ofNat=embedding;negSucc=-(n+1)\nmachine-int=fixed-width-twos-complement;binary=mod-2^width;compare=signedness;word-size=target-profile\nfloat=f64-ieee754;float32=f32-ieee754;float32-binary=round-f32\nbool=two-valued\nchar=unicode-scalar;ofNat-invalid=U+0000;toNat=code-point\nstring=unicode-scalar-sequence;length=scalar-count;position=utf8-byte-offset;index-domain=utf8-boundaries;append=concat;eq=sequence\narray=persistent-sequence;size=nat;push=append-one;get=in-bounds;getD=oob-fallback;set=in-bounds;setIfInBounds=oob-identity;map=ordered;foldl=[start,min(stop,size))\nrecord=immutable-named-fields;projection=field-value\nadt=constructor-tagged;match=constructor-dispatch;bindings=declared-fields\nclosure=lexical-capture;call=call-by-value;argument-order=left-to-right\nunsupported=reject-no-fallback\n";

export const runtimeSemanticsV1Sha256 = createHash("sha256")
  .update(runtimeSemanticsV1Canonical, "utf8")
  .digest("hex");

export const runtimeSemanticsV1 = Object.freeze({
  id: "psc-runtime-semantics/1",
  sha256: runtimeSemanticsV1Sha256,
});

export const runtimeSemanticsV1PackageFolders = Object.freeze([
  "compiler-ir",
  "backend-ts",
  "backend-js",
  "backend-rust",
  "backend-wasm",
]);

export function assertRuntimeSemanticsManifest(manifest, folder = "<unknown>") {
  const declared = manifest?.proofscript?.runtimeSemantics;
  if (!declared || typeof declared !== "object" || Array.isArray(declared)) {
    throw new Error(`PSC2_RUNTIME_SEMANTICS_MISSING: ${folder}`);
  }
  if (declared.id !== runtimeSemanticsV1.id) {
    throw new Error(`PSC2_RUNTIME_SEMANTICS_ID: ${folder}`);
  }
  if (declared.sha256 !== runtimeSemanticsV1.sha256) {
    throw new Error(`PSC2_RUNTIME_SEMANTICS_HASH: ${folder}`);
  }
}
