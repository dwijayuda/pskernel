import "./check-erasure-core-module-sequencing-selfhost-source-syntax.mjs";
import "./check-erasure-application-arguments-cons-selfhost-source-syntax.mjs";
import assert from 'node:assert/strict';
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const source = await readFile(
  path.join(root, "packages/erasure/src/Ps/Erasure/Definition.lean"),
  "utf8",
);

const match = source.match(
  /def psErasureAddUniqueStringWorker\b[\s\S]*?(?=\nstructure PsErasureNameState)/,
);
if (match === null) {
  throw new Error(
    "PSC2_ERASURE_ADD_UNIQUE_STRING_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
  );
}

// Source checks retain primitive ownership, fuel recursion and wrapper order.
// Both historical and qualified SH/1 authoring are permitted; the helper
// migration conformance gate checks exact collision and exhaustion behavior.
const block = match[0];
const workerForms = [
  [
    /def psErasureAddUniqueStringWorker\s*\(used : List String\)\s*\(attempts : Nat\)\s*:\s*String -> String :=\s*match attempts with/,
    /\| Nat\.zero =>\s*fun \(base : String\) =>\s*String\.Internal\.append base "_overflow"/,
    /\| Nat\.succ remaining =>\s*let smaller : String -> String :=\s*psErasureAddUniqueStringWorker used remaining;\s*fun \(base : String\) =>\s*if psErasureStringInList used base then\s*smaller \(String\.Internal\.append base "_"\)\s*else base/,
  ],
  [
    /def psErasureAddUniqueStringWorker\s*\(used : List String\)\s*\(attempts : Nat\)\s*\(base : String\)\s*:\s*String :=\s*match attempts with/,
    /\| Nat\.zero =>\s*String\.Internal\.append base "_overflow"/,
    /\| Nat\.succ remaining =>\s*if psErasureStringInList used base then\s*psErasureAddUniqueStringWorker used remaining\s*\(String\.Internal\.append base "_"\)\s*else base/,
  ],
];
const wrapper =
  /def psErasureAddUniqueString\s*\(used : List String\)\s*\(base : String\)\s*\(attempts : Nat\)\s*:\s*String :=\s*psErasureAddUniqueStringWorker used attempts base/;
const supported = (text) =>
  workerForms.some((patterns) => patterns.every((pattern) => pattern.test(text))) &&
  wrapper.test(text);
if (!supported(block)) {
  throw new Error(
    "PSC2_ERASURE_ADD_UNIQUE_STRING_SELFHOST_SOURCE_SYNTAX_MISSING: supported structural worker or public wrapper order",
  );
}

if (/\+\+|\.contains/.test(block)) {
  throw new Error(
    "PSC2_ERASURE_ADD_UNIQUE_STRING_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: use direct String.Internal.append and psErasureStringInList",
  );
}

for (const marker of [
  /psErasureAddUniqueStringWorker used remaining\b/,
  /psErasureAddUniqueStringWorker used attempts base/,
]) {
  assert.match(block, marker);
  assert.ok(!supported(block.replace(marker, 'missing')));
}
assert.match(source, /if psStringEq value target then true else smaller target/);

process.stdout.write(
  "PSC2_ERASURE_ADD_UNIQUE_STRING_SELFHOST_SOURCE_SYNTAX: PASS (historical or qualified SH/1 worker; direct String.Internal.append; public wrapper order)\n",
);
