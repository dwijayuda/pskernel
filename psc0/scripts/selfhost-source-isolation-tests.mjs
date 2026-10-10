import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, rm, symlink, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { computeBootstrapWorkspaceClosureSha256 } from "./bootstrap-manifest.mjs";
import { sh1GrammarProfile } from "./source-grammar-profile.mjs";
import { readProofScriptImports as importsFromParser } from "./proofscript-source.mjs";
import { readCheckedSourceSnapshot } from "./checked-source-snapshot.mjs";

const entry = "packages/bootstrap/src/Ps/Bootstrap/SelfHost.ps";
const dependency = "packages/foundation/src/Ps/Foundation/Probe.ps";
const extra = "packages/foundation/src/Ps/Foundation/Unused.ps";
let passed = 0;
let skipped = 0;
const failures = [];

// Fixed AST responses isolate filesystem selection and module ordering. This
// double is not a PS parser, elaborator, kernel, or emitter. Actual compiler,
// admission, and TypeScript behavior belong to the separate integration gates.
const fixtureImports = new Map([
  ["import Ps.Foundation.Probe\ndef entryMarker : Nat := 1\n", ["Ps.Foundation.Probe"]],
  ["def GENERATED_DEP : Nat := 42\n", []],
  ["def GENERATED_DEP : Nat := 43\n", []],
  ["import Ps.Bootstrap.SelfHost\ndef GENERATED_DEP : Nat := 42\n", ["Ps.Bootstrap.SelfHost"]],
]);
const tag = Symbol("psc2-isolation-parser");
const ok = value => ({ [tag]: "ok", value });
const List = {
  nil: () => ({ [tag]: "nil" }),
  cons: (head, tail) => ({ [tag]: "cons", head, tail }),
};
const parser = Object.freeze({
  psProofScriptGrammarEdition: sh1GrammarProfile.edition,
  psProofScriptGrammarMode: sh1GrammarProfile.mode,
  psProofScriptGrammarReferenceSha256: sh1GrammarProfile.referenceSha256,
  psParseProofScriptSource(source) {
    assert(fixtureImports.has(source), "unexpected parser-double source: " + JSON.stringify(source));
    const imports = fixtureImports.get(source).reduceRight(
      (tail, text) => List.cons({ moduleName: { text } }, tail), List.nil());
    return ok({ imports });
  },
  psPrintSyntaxName(name) { return ok(name.text); },
});

async function scenario(label, configure = async () => {}, expectedError) {
  const directory = await mkdtemp(path.join(tmpdir(), "psc2-isolation-test-"));
  try {
    const parent = path.join(directory, "parent");
    const workspace = path.join(parent, "dist", "generated");
    async function put(file, content) {
      await mkdir(path.dirname(file), { recursive: true });
      await writeFile(file, content, "utf8");
    }
    await mkdir(path.join(parent, "stdlib"), { recursive: true });
    await put(path.join(parent, dependency.replace(/\.ps$/u, ".lean")), "def WRONG_PARENT : Nat := 0\n");
    await put(path.join(workspace, entry), "import Ps.Foundation.Probe\ndef entryMarker : Nat := 1\n");
    await put(path.join(workspace, dependency), "def GENERATED_DEP : Nat := 42\n");
    const manifest = {
      schemaVersion: 2, generation: "bootstrap", entry,
      generated: [entry, dependency].sort(), sourceCount: 2,
    };
    async function saveManifest() {
      manifest.sourceCount = manifest.generated.length;
      manifest.closureSha256 = await computeBootstrapWorkspaceClosureSha256(workspace, manifest.entry, manifest.generated);
      await put(path.join(workspace, ".proofscript-bootstrap.json"), JSON.stringify(manifest));
    }
    await saveManifest();
    const fixture = { directory, parent, workspace, manifest, put, saveManifest };
    await configure(fixture);
    let snapshot;
    const parserInputs = [];
    async function readSnapshot() {
      snapshot = await readCheckedSourceSnapshot(path.join(workspace, entry), {
        readProofScriptImports(source, file) {
          parserInputs.push({ source, file });
          return importsFromParser(parser, source, file);
        },
      });
      return snapshot;
    }
    if (expectedError) {
      await assert.rejects(readSnapshot, expectedError,
        "invalid generated source closures must be refused by the production snapshot boundary");
      assert.equal(snapshot, undefined, "a rejected closure must not produce a source snapshot");
    } else {
      await readSnapshot();
      const expectedSources = ["def GENERATED_DEP : Nat := 42\n",
        "import Ps.Foundation.Probe\ndef entryMarker : Nat := 1\n"];
      assert.equal(snapshot.root, workspace);
      assert.equal(snapshot.entry, path.join(workspace, entry));
      assert.equal(snapshot.kind, "ps");
      assert.equal(snapshot.sources.length, 2, "module boundaries must survive source selection");
      assert.deepEqual(snapshot.sources, expectedSources,
        "the snapshot must preserve exact raw PS modules, including imports");
      assert.deepEqual(snapshot.ordered.map(item => item.path),
        [path.join(workspace, dependency), path.join(workspace, entry)]);
      assert.deepEqual(snapshot.ordered.map(item => item.source), expectedSources);
      assert.deepEqual(parserInputs, [
        { source: expectedSources[1], file: path.join(workspace, entry) },
        { source: expectedSources[0], file: path.join(workspace, dependency) },
      ], "the parser adapter must receive exact raw source bytes before dependency resolution");
      assert.equal(snapshot.source, expectedSources.join("\n\n") + "\n");
      assert.doesNotMatch(snapshot.source, /WRONG_PARENT|STALE_LEAN/u);
      assert.ok(snapshot.source.indexOf("GENERATED_DEP") < snapshot.source.indexOf("entryMarker"));
      assert.match(snapshot.closureSha256, /^[0-9a-f]{64}$/u);
      assert.equal(snapshot.closureSha256, manifest.closureSha256);
      assert(Object.isFrozen(snapshot) && Object.isFrozen(snapshot.sources) &&
        Object.isFrozen(snapshot.ordered) && snapshot.ordered.every(Object.isFrozen),
        "the accepted source snapshot and its source records must be immutable");
    }
    passed++;
    console.log(`PSC2_SELFHOST_SOURCE_ISOLATION_CASE: PASS ${label}`);
  } catch (error) {
    if (error?.code === "PSC2_POSIX_ONLY_SKIP") {
      skipped++;
      console.log(`PSC2_SELFHOST_SOURCE_ISOLATION_CASE: SKIP ${label}: ${error.message}`);
    } else {
      failures.push(`${label}: ${error.message}`);
      console.error(`PSC2_SELFHOST_SOURCE_ISOLATION_CASE: FAIL ${label}: ${error.message}`);
    }
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
}

await scenario("nested generated workspace without stdlib");
await scenario("isolated generated workspace without stdlib", async ({ parent }) => {
  await rm(path.join(parent, "stdlib"), { recursive: true });
  await rm(path.join(parent, "packages"), { recursive: true });
});
await scenario("stale Lean sibling cannot shadow canonical PS", async ({ workspace, put }) => {
  await mkdir(path.join(workspace, "stdlib"));
  await put(path.join(workspace, dependency.replace(/\.ps$/u, ".lean")), "def STALE_LEAN : Nat := 0\n");
});
await scenario("tampered source bytes", async ({ workspace, put }) => {
  await put(path.join(workspace, dependency), "def GENERATED_DEP : Nat := 43\n");
}, /CLOSURE_MISMATCH/u);
await scenario("missing PS cannot fall back to Lean", async ({ workspace, put }) => {
  await rm(path.join(workspace, dependency));
  await put(path.join(workspace, dependency.replace(/\.ps$/u, ".lean")), "def STALE_LEAN : Nat := 0\n");
}, /SOURCE_MISSING/u);
await scenario("unlisted imported source", async ({ workspace, put, manifest, saveManifest }) => {
  manifest.generated = [entry];
  await saveManifest();
}, /SOURCE_NOT_IN_MANIFEST/u);
await scenario("manifest includes unreachable source", async ({ workspace, put, manifest, saveManifest }) => {
  await put(path.join(workspace, extra), "def unused : Nat := 1\n");
  manifest.generated = [...manifest.generated, extra].sort();
  await saveManifest();
}, /SOURCE_FILESET_MISMATCH/u);
await scenario("manifest entry mismatch", async ({ workspace, put, manifest }) => {
  await put(path.join(workspace, ".proofscript-bootstrap.json"), JSON.stringify({ ...manifest, entry: dependency }));
}, /SOURCE_ENTRY_MISMATCH/u);
await scenario("malformed manifest cannot fall back to parent", async ({ workspace, put }) => {
  await put(path.join(workspace, ".proofscript-bootstrap.json"), "{");
}, /MANIFEST_INVALID/u);
await scenario("generation tag mismatch", async ({ workspace, put, manifest }) => {
  await put(path.join(workspace, ".proofscript-bootstrap.json"), JSON.stringify({ ...manifest, generation: "selfhost" }));
}, /MANIFEST_GENERATION/u);
await scenario("ambiguous generation manifests", async ({ workspace, put, manifest }) => {
  await put(path.join(workspace, ".proofscript-selfhost.json"), JSON.stringify({ ...manifest, generation: "selfhost" }));
}, /MANIFEST_AMBIGUITY/u);
await scenario("symlink cannot escape generated root", async ({ directory, workspace, put }) => {
  const outside = path.join(directory, "outside.ps");
  await put(outside, await readFile(path.join(workspace, dependency), "utf8"));
  await rm(path.join(workspace, dependency));
  try {
    await symlink(outside, path.join(workspace, dependency));
  } catch (error) {
    if (process.platform === "win32" && error?.code === "EPERM") {
      const skip = new Error("Windows host cannot create this symlink; covered by the POSIX run");
      skip.code = "PSC2_POSIX_ONLY_SKIP";
      throw skip;
    }
    throw error;
  }
}, /SOURCE_OUTSIDE_WORKSPACE/u);
await scenario("cyclic source imports", async ({ workspace, put, saveManifest }) => {
  await put(path.join(workspace, dependency), "import Ps.Bootstrap.SelfHost\ndef GENERATED_DEP : Nat := 42\n");
  await saveManifest();
}, /IMPORT_CYCLE/u);
await scenario("selfhost generation manifest accepted", async ({ workspace, put, manifest }) => {
  await rm(path.join(workspace, ".proofscript-bootstrap.json"));
  await put(path.join(workspace, ".proofscript-selfhost.json"), JSON.stringify({ ...manifest, generation: "selfhost" }));
});

if (failures.length) throw new Error(`PSC2_SELFHOST_SOURCE_ISOLATION: ${passed} passed, ${failures.length} failed\n${failures.join("\n")}`);
console.log(`PSC2_SELFHOST_SOURCE_ISOLATION: PASS (${passed} passed; ${skipped} platform skips; bounded parser double; production source snapshot)`);
