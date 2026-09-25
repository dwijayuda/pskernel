import { mkdir, readFile, writeFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

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
      `PSC1_SELFHOST_REEMIT_FAILED: ${sourcePath}: ${JSON.stringify(value.error)}`,
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

const manifestPath = path.join(inputWorkspace, ".proofscript-bootstrap.json");
if (!existsSync(manifestPath)) {
  throw new Error(`PSC1_SELFHOST_MANIFEST_MISSING: ${manifestPath}`);
}

const compiler = await import(pathToFileURL(compilerPath).href);
if (
  !("PsCompilerSourceKind" in compiler) ||
  !("psCompilerTranslateSource" in compiler)
) {
  throw new Error("PSC1_SELFHOST_REEMIT_COMPILER_API_MISSING");
}

const manifest = JSON.parse(await readFile(manifestPath, "utf8"));
const psKind = compiler.PsCompilerSourceKind.proofScript;

for (const relativePath of manifest.generated) {
  if (!relativePath.endsWith(".ps")) {
    throw new Error(`PSC1_SELFHOST_REEMIT_SOURCE_KIND: ${relativePath}`);
  }

  const inputPath = path.join(inputWorkspace, relativePath);
  const outputPath = path.join(outputWorkspace, relativePath);
  const source = await readFile(inputPath, "utf8");
  const canonical = unwrapExcept(
    compiler.psCompilerTranslateSource(psKind, psKind, source),
    relativePath,
  );

  await mkdir(path.dirname(outputPath), { recursive: true });
  await writeFile(outputPath, canonical, "utf8");
}

const outputManifest = {
  schemaVersion: 1,
  generation: "selfhost",
  parent: path.relative(selfhostRoot, inputWorkspace).replaceAll(path.sep, "/"),
  entry: manifest.entry,
  sourceCount: manifest.generated.length,
  generated: manifest.generated,
};

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
    `PSC1_SELFHOST_REEMIT_FILES: ${manifest.generated.length}`,
  ].join("\n") + "\n",
);
