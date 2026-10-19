import { mkdir, readFile, writeFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { inspect } from "node:util";
import { assertProofScriptGrammar, readProofScriptSource } from "./proofscript-source.mjs";
import {
  bootstrapManifestSchemaVersion,
  canonicalGeneratedPaths,
  computeBootstrapWorkspaceClosureSha256,
  assertBootstrapManifestShape,
  assertBootstrapWorkspaceManifest,
} from "./bootstrap-manifest.mjs";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const selfhostRoot = path.resolve(scriptDir, "..");

function usage() {
  return [
    "usage:",
    "  node scripts/reemit-project-with-generated.mjs <compiler.js> <input-workspace> <output-workspace>",
  ].join("\n");
}

function exceptTag(value) {
  if (value === null || typeof value !== "object") return undefined;
  for (const symbol of Object.getOwnPropertySymbols(value)) {
    const tag = value[symbol];
    if (tag === "ok" || tag === "error") return tag;
  }
  return undefined;
}

function unwrapExcept(value, sourcePath) {
  const tag = exceptTag(value);
  if (tag === "ok") return value.value;
  if (tag === "error") {
    throw new Error(
      `PSC1_SELFHOST_REEMIT_FAILED: ${sourcePath}: ${inspect(value.error, { depth: 8 })}`,
    );
  }
  throw new Error(`PSC1_SELFHOST_REEMIT_RESULT_SHAPE: ${sourcePath}`);
}

if (process.argv.length < 5) {
  throw new Error(usage());
}

const compilerPath = path.resolve(selfhostRoot, process.argv[2]);
const inputWorkspace = path.resolve(selfhostRoot, process.argv[3]);
const outputWorkspace = path.resolve(selfhostRoot, process.argv[4]);

if (!existsSync(compilerPath)) {
  throw new Error(`PSC1_SELFHOST_COMPILER_MISSING: ${compilerPath}`);
}

const manifestCandidates = [
  ".proofscript-bootstrap.json",
  ".proofscript-selfhost.json",
  ".proofscript-project.json",
];
const manifestName = manifestCandidates.find((name) =>
  existsSync(path.join(inputWorkspace, name)),
);
if (!manifestName) {
  throw new Error(`PSC1_SELFHOST_MANIFEST_MISSING: ${inputWorkspace}`);
}
const manifestPath = path.join(inputWorkspace, manifestName);

const compiler = await import(pathToFileURL(compilerPath).href);
if (
  !("PsCompilerSourceKind" in compiler) ||
  !("psCompilerTranslateSource" in compiler)
) {
  throw new Error("PSC1_SELFHOST_REEMIT_COMPILER_API_MISSING");
}

assertProofScriptGrammar(compiler);

const manifest = JSON.parse(await readFile(manifestPath, "utf8"));
const expectedGeneration =
  manifestName === ".proofscript-bootstrap.json"
    ? "bootstrap"
    : manifestName === ".proofscript-selfhost.json"
      ? "selfhost"
      : undefined;

if (expectedGeneration !== undefined) {
  await assertBootstrapWorkspaceManifest(
    inputWorkspace,
    manifest,
    expectedGeneration,
  );
}

const generated = canonicalGeneratedPaths(manifest.generated);
const psKind = compiler.PsCompilerSourceKind.proofScript;

for (const relativePath of generated) {
  const inputPath = path.join(inputWorkspace, relativePath);
  const outputPath = path.join(outputWorkspace, relativePath);
  const source = await readProofScriptSource(inputPath);
  const canonical = unwrapExcept(
    compiler.psCompilerTranslateSource(psKind, psKind, source),
    relativePath,
  );

  await mkdir(path.dirname(outputPath), { recursive: true });
  await writeFile(outputPath, canonical, "utf8");
}

const closureSha256 = await computeBootstrapWorkspaceClosureSha256(
  outputWorkspace,
  manifest.entry,
  generated,
);
const outputManifest = {
  schemaVersion: bootstrapManifestSchemaVersion,
  generation: "selfhost",
  parent: path.relative(selfhostRoot, inputWorkspace).replaceAll(path.sep, "/"),
  parentClosureSha256:
    typeof manifest.closureSha256 === "string" ? manifest.closureSha256 : undefined,
  entry: manifest.entry,
  sourceCount: generated.length,
  generated,
  closureSha256,
};
assertBootstrapManifestShape(outputManifest, "selfhost");

await mkdir(outputWorkspace, { recursive: true });
await writeFile(
  path.join(outputWorkspace, ".proofscript-selfhost.json"),
  JSON.stringify(outputManifest, null, 2) + "\n",
  "utf8",
);

process.stdout.write(
  [
    `PSC1_SELFHOST_REEMIT_COMPILER: ${path.relative(selfhostRoot, compilerPath)}`,
    `PSC1_SELFHOST_REEMIT_SOURCE: ${path.relative(selfhostRoot, inputWorkspace)}`,
    `PSC1_SELFHOST_REEMIT_OUTPUT: ${path.relative(selfhostRoot, outputWorkspace)}`,
    `PSC1_SELFHOST_REEMIT_FILES: ${generated.length}`,
    `PSC1_SELFHOST_REEMIT_CLOSURE_SHA256: ${closureSha256}`,
  ].join("\n") + "\n",
);
