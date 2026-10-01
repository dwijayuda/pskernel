import "./selfhost-source-isolation-tests.mjs";
import {
  assertBootstrapManifestShape,
  computeBootstrapClosureSha256,
} from "./bootstrap-manifest.mjs";

function assert(condition, message) {
  if (!condition) throw new Error(`PSC2_BOOTSTRAP_MANIFEST_TEST: ${message}`);
}

function assertThrows(action, prefix, label) {
  try {
    action();
  } catch (error) {
    assert(
      error instanceof Error && error.message.startsWith(prefix),
      `${label}: unexpected error ${error instanceof Error ? error.message : String(error)}`,
    );
    return;
  }
  throw new Error(`PSC2_BOOTSTRAP_MANIFEST_TEST: ${label}: expected rejection`);
}

async function assertRejects(action, prefix, label) {
  try {
    await action();
  } catch (error) {
    assert(
      error instanceof Error && error.message.startsWith(prefix),
      `${label}: unexpected error ${error instanceof Error ? error.message : String(error)}`,
    );
    return;
  }
  throw new Error(`PSC2_BOOTSTRAP_MANIFEST_TEST: ${label}: expected rejection`);
}

const sources = new Map([
  ["packages/bootstrap/src/Ps/Bootstrap/SelfHost.ps", "import Ps.Compiler.Api\n"],
  ["packages/compiler/src/Ps/Compiler/Api.ps", "def answer : Nat := 42\n"],
]);
const generated = [...sources.keys()].sort();
const entry = "packages/bootstrap/src/Ps/Bootstrap/SelfHost.ps";
const closureSha256 = await computeBootstrapClosureSha256(
  entry,
  generated,
  async (relativePath) => sources.get(relativePath),
);

const valid = {
  schemaVersion: 2,
  generation: "bootstrap",
  entry,
  sourceCount: generated.length,
  generated,
  closureSha256,
};
assertBootstrapManifestShape(valid, "bootstrap");

assertThrows(
  () => assertBootstrapManifestShape({ ...valid, sourceCount: 1 }, "bootstrap"),
  "PSC2_BOOTSTRAP_MANIFEST_SOURCE_COUNT",
  "sourceCount mismatch accepted",
);
assertThrows(
  () => assertBootstrapManifestShape({ ...valid, generated: [generated[0], generated[0]] }, "bootstrap"),
  "PSC2_BOOTSTRAP_MANIFEST_DUPLICATE_PATH",
  "duplicate generated path accepted",
);
assertThrows(
  () => assertBootstrapManifestShape({ ...valid, generated: [...generated].reverse() }, "bootstrap"),
  "PSC2_BOOTSTRAP_MANIFEST_NONCANONICAL_ORDER",
  "noncanonical order accepted",
);
assertThrows(
  () => assertBootstrapManifestShape({ ...valid, entry: "../escape.ps" }, "bootstrap"),
  "PSC2_BOOTSTRAP_MANIFEST_PATH_TRAVERSAL",
  "path traversal accepted",
);
assertThrows(
  () => assertBootstrapManifestShape({ ...valid, generated: ["packages/bootstrap/SelfHost.lean"] }, "bootstrap"),
  "PSC2_BOOTSTRAP_MANIFEST_PATH_KIND",
  "non-ps generated path accepted",
);
assertThrows(
  () => assertBootstrapManifestShape({ ...valid, entry: "packages/bootstrap/src/Missing.ps" }, "bootstrap"),
  "PSC2_BOOTSTRAP_MANIFEST_ENTRY_NOT_GENERATED",
  "entry outside generated set accepted",
);
assertThrows(
  () => assertBootstrapManifestShape({ ...valid, closureSha256: "forged" }, "bootstrap"),
  "PSC2_BOOTSTRAP_MANIFEST_CLOSURE_HASH",
  "invalid closure hash accepted",
);

const changedSources = new Map(sources);
changedSources.set(
  "packages/compiler/src/Ps/Compiler/Api.ps",
  "def answer : Nat := 43\n",
);
const changedHash = await computeBootstrapClosureSha256(
  entry,
  generated,
  async (relativePath) => changedSources.get(relativePath),
);
assert(changedHash !== closureSha256, "source mutation did not change closure hash");

await assertRejects(
  () => computeBootstrapClosureSha256(
    entry,
    [entry, "../escape.ps"],
    async (relativePath) => sources.get(relativePath),
  ),
  "PSC2_BOOTSTRAP_MANIFEST_PATH_TRAVERSAL",
  "fingerprint accepted unsafe path",
);

process.stdout.write(
  `PSC2_BOOTSTRAP_MANIFEST_CONTRACT: PASS (${generated.length} fixture sources)\n`,
);
