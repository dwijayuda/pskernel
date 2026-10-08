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
  /def psErasureAddUniqueString[\s\S]*?(?=\nstructure PsErasureNameState)/,
);
if (match === null) {
  throw new Error(
    "PSC2_ERASURE_ADD_UNIQUE_STRING_SELFHOST_SOURCE_SYNTAX_MISSING: declaration block",
  );
}

const block = match[0];
const required = [
  /\| Nat\.zero => fun \(base : String\) => String\.Internal\.append base "_overflow"/,
  /String\.Internal\.append base "_"/,
  /psErasureAddUniqueStringWorker used remaining;/,
  /if psErasureStringInList used base then smaller \(String\.Internal\.append base "_"\)/,
  /psErasureAddUniqueStringWorker used attempts base/,
];
for (const pattern of required) {
  if (!pattern.test(block)) {
    throw new Error(
      `PSC2_ERASURE_ADD_UNIQUE_STRING_SELFHOST_SOURCE_SYNTAX_MISSING: ${pattern}`,
    );
  }
}

if (/\+\+|\.contains/.test(block)) {
  throw new Error(
    "PSC2_ERASURE_ADD_UNIQUE_STRING_SELFHOST_SOURCE_SYNTAX_FORBIDDEN: ++",
  );
}

for (const marker of ['psErasureAddUniqueStringWorker used remaining;',
  'psErasureAddUniqueStringWorker used attempts base']) {
  assert.ok(block.includes(marker));
  const broken = block.replace(marker, 'missing');
  assert.ok(required.some(pattern => !pattern.test(broken)));
}
assert.match(source, /if psStringEq value target then true else smaller target/);

process.stdout.write(
  "PSC2_ERASURE_ADD_UNIQUE_STRING_SELFHOST_SOURCE_SYNTAX: PASS (direct String.Internal.append; ++ syntax excluded)\n",
);
