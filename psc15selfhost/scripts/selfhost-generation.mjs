import { readFile, writeFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const selfhostRoot = path.resolve(scriptDir, "..");
const node = process.execPath;

function usage() {
  return [
    "usage:",
    "  node scripts/selfhost-generation.mjs <compiler.js> <input-workspace> <output-generation>",
  ].join("\n");
}

function run(args) {
  const result = spawnSync(node, args, {
    cwd: selfhostRoot,
    encoding: "utf8",
    stdio: "inherit",
  });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(`PSC2_SELFHOST_GENERATION_STEP_FAILED: ${args.join(" ")}`);
  }
}

function findManifest(workspace) {
  for (const name of [
    ".proofscript-bootstrap.json",
    ".proofscript-selfhost.json",
    ".proofscript-project.json",
  ]) {
    const candidate = path.join(workspace, name);
    if (existsSync(candidate)) return candidate;
  }
  throw new Error(`PSC2_SELFHOST_GENERATION_MANIFEST_MISSING: ${workspace}`);
}

if (process.argv.length < 5) {
  throw new Error(usage());
}

const compilerPath = path.resolve(selfhostRoot, process.argv[2]);
const inputWorkspace = path.resolve(selfhostRoot, process.argv[3]);
const outputGeneration = path.resolve(selfhostRoot, process.argv[4]);

if (!existsSync(compilerPath)) {
  throw new Error(`PSC2_SELFHOST_GENERATION_COMPILER_MISSING: ${compilerPath}`);
}

const inputManifestPath = findManifest(inputWorkspace);
const inputManifest = JSON.parse(await readFile(inputManifestPath, "utf8"));
if (!inputManifest.entry) {
  throw new Error("PSC2_SELFHOST_GENERATION_ENTRY_MISSING");
}

const outputWorkspace = path.join(outputGeneration, "workspace");
const outputCompiler = path.join(
  outputGeneration,
  "packages",
  "compiler",
  "index.js",
);

run([
  "scripts/reemit-project-with-generated.mjs",
  compilerPath,
  inputWorkspace,
  outputWorkspace,
]);

const outputEntry = path.join(outputWorkspace, inputManifest.entry);
run([
  "scripts/compile-with-generated.mjs",
  compilerPath,
  outputEntry,
  outputCompiler,
]);

const generationManifest = {
  schemaVersion: 2,
  parentCompiler: path.relative(selfhostRoot, compilerPath).replaceAll(path.sep, "/"),
  parentWorkspace: path.relative(selfhostRoot, inputWorkspace).replaceAll(path.sep, "/"),
  workspace: path.relative(selfhostRoot, outputWorkspace).replaceAll(path.sep, "/"),
  compiler: path.relative(selfhostRoot, outputCompiler).replaceAll(path.sep, "/"),
  entry: inputManifest.entry,
};

await writeFile(
  path.join(outputGeneration, ".proofscript-generation.json"),
  JSON.stringify(generationManifest, null, 2) + "\n",
  "utf8",
);

process.stdout.write(
  [
    `PSC2_SELFHOST_GENERATION: ${path.relative(selfhostRoot, outputGeneration)}`,
    `PSC2_SELFHOST_GENERATION_PS: ${generationManifest.workspace}`,
    `PSC2_SELFHOST_GENERATION_COMPILER: ${generationManifest.compiler}`,
  ].join("\n") + "\n",
);
