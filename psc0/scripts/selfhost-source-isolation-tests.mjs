import assert from "node:assert/strict";
import { mkdir, mkdtemp, readFile, rm, symlink, writeFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import { computeBootstrapWorkspaceClosureSha256 } from "./bootstrap-manifest.mjs";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const entry = "packages/bootstrap/src/Ps/Bootstrap/SelfHost.ps";
const dependency = "packages/foundation/src/Ps/Foundation/Probe.ps";
const extra = "packages/foundation/src/Ps/Foundation/Unused.ps";
let passed = 0;
let skipped = 0;
const failures = [];

async function scenario(label, configure = async () => {}, expectedError) {
  const directory = await mkdtemp(path.join(tmpdir(), "psc2-isolation-test-"));
  try {
    const parent = path.join(directory, "parent");
    const workspace = path.join(parent, "dist", "generated");
    const report = path.join(directory, "consumed.json");
    async function put(file, content) {
      await mkdir(path.dirname(file), { recursive: true });
      await writeFile(file, content, "utf8");
    }
    await mkdir(path.join(parent, "stdlib"), { recursive: true });
    await put(path.join(parent, dependency.replace(/\.ps$/u, ".lean")), "def WRONG_PARENT : Nat := 0\n");
    await put(path.join(workspace, entry), "import Ps.Foundation.Probe;\ndef entryMarker : Nat := 1\n");
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
    const compiler = path.join(directory, "compiler.mjs");
    // A compiler double isolates source selection and module ordering. The
    // production host still invokes the real, pinned TypeScript compiler.
    await put(compiler, `import { writeFileSync } from "node:fs";
export const PsCompilerSourceKind = { lean: "lean", proofScript: "ps" };
let translations = 0;
const ok = value => ({ [Symbol.for("psc2-test-tag")]: "ok", value });
export function psCompilerTranslateSource(_from, _to, source) { translations++; return ok(source); }
export const List = { nil: () => ({}), cons: (head, tail) => ({ head, tail }) };
export function psCompilerPrepareSources(kind, sources) {
  const chunks = [];
  for (let value = sources; 'head' in value; value = value.tail) chunks.push(value.head);
  writeFileSync(process.env.PSC2_TEST_SOURCE_REPORT, JSON.stringify({ kind, source: chunks.join('\\n\\n'), chunks, translations }));
  return ok({});
}
export function psCompilerTypeScriptFromPrepared(_prepared) {
  return ok("export const answer = 42;\\n");
}
`);
    const result = spawnSync(process.execPath, [path.join(root, "scripts/compile-with-generated.mjs"),
      compiler, path.join(workspace, entry), path.join(directory, "output.ts")], {
      cwd: root, encoding: "utf8", timeout: 15000,
      env: { ...process.env, PSC2_TEST_SOURCE_REPORT: report },
    });
    if (result.error) throw result.error;
    const output = `${result.stdout}\n${result.stderr}`;
    if (expectedError) {
      assert.notEqual(result.status, 0, "must reject invalid generated source closure");
      assert.match(output, expectedError);
      assert.equal(existsSync(report), false, "must reject before invoking semantic compilation");
    } else {
      assert.equal(result.status, 0, output);
      assert(existsSync(path.join(directory, 'output.js')), 'real TypeScript compilation must complete');
      const consumed = JSON.parse(await readFile(report, "utf8"));
      assert.equal(consumed.kind, "ps");
      assert.equal(consumed.translations, 0, "generated compilation must not translate a handwritten fallback");
      assert.equal(consumed.chunks.length, 2, "module boundaries must survive compilation");
      assert.match(consumed.source, /GENERATED_DEP/u);
      assert.doesNotMatch(consumed.source, /WRONG_PARENT|STALE_LEAN/u);
      assert.ok(consumed.source.indexOf("GENERATED_DEP") < consumed.source.indexOf("entryMarker"));
      assert.match(output, /PSC2_SELFHOST_SOURCE_CLOSURE_SHA256: [0-9a-f]{64}/u);
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
  await put(path.join(workspace, dependency), "import Ps.Bootstrap.SelfHost;\ndef GENERATED_DEP : Nat := 42\n");
  await saveManifest();
}, /IMPORT_CYCLE/u);
await scenario("selfhost generation manifest accepted", async ({ workspace, put, manifest }) => {
  await rm(path.join(workspace, ".proofscript-bootstrap.json"));
  await put(path.join(workspace, ".proofscript-selfhost.json"), JSON.stringify({ ...manifest, generation: "selfhost" }));
});

if (failures.length) throw new Error(`PSC2_SELFHOST_SOURCE_ISOLATION: ${passed} passed, ${failures.length} failed\n${failures.join("\n")}`);
console.log(`PSC2_SELFHOST_SOURCE_ISOLATION: PASS (${passed} passed; ${skipped} platform skips; compiler double and pinned TypeScript)`);
