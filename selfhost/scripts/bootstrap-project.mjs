import { mkdir, readFile, writeFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const selfhostRoot = path.resolve(scriptDir, "..");

const packageBySection = new Map([
  ["Foundation", "foundation"],
  ["Syntax", "syntax"],
  ["Core", "core"],
  ["Environment", "environment"],
  ["Project", "project"],
  ["Meta", "meta"],
  ["Elab", "elab"],
  ["Bridge", "bridge"],
  ["CompilerIr", "compiler-ir"],
  ["Erasure", "erasure"],
  ["BackendTs", "backend-ts"],
]);

function usage() {
  return [
    "usage:",
    "  node scripts/bootstrap-project.mjs <entry.lean> <out-workspace>",
    "",
    "default:",
    "  entry: SELFHOST-COMPILER.lean",
    "  out:   dist/bootstrap/workspace",
  ].join("\n");
}

function parseImports(source) {
  const imports = [];
  for (const line of source.split(/\r?\n/u)) {
    const match = line.match(/^\s*import\s+([A-Za-z0-9_.]+)\s*$/u);
    if (match) imports.push(match[1]);
  }
  return imports;
}

function moduleSourcePath(moduleName) {
  const parts = moduleName.split(".");
  if (parts[0] === "ProofScript") {
    return path.join(selfhostRoot, "stdlib", ...parts) + ".lean";
  }
  if (parts[0] === "Ps" && parts.length >= 2) {
    const packageName = packageBySection.get(parts[1]);
    if (!packageName) {
      throw new Error(`PSC1_BOOTSTRAP_UNKNOWN_PACKAGE: ${moduleName}`);
    }
    return path.join(
      selfhostRoot,
      "packages",
      packageName,
      "src",
      ...parts,
    ) + ".lean";
  }
  throw new Error(`PSC1_BOOTSTRAP_UNKNOWN_IMPORT: ${moduleName}`);
}

async function collectProject(entryPath) {
  const visited = new Set();
  const ordered = [];

  async function visit(sourcePath) {
    const absolute = path.resolve(sourcePath);
    if (visited.has(absolute)) return;
    visited.add(absolute);

    if (!existsSync(absolute)) {
      throw new Error(`PSC1_BOOTSTRAP_SOURCE_MISSING: ${absolute}`);
    }

    const source = await readFile(absolute, "utf8");
    for (const moduleName of parseImports(source)) {
      await visit(moduleSourcePath(moduleName));
    }
    ordered.push(absolute);
  }

  await visit(entryPath);
  return ordered;
}

function translatedRelativePath(sourcePath) {
  const relative = path.relative(selfhostRoot, sourcePath);
  if (relative.startsWith("..") || path.isAbsolute(relative)) {
    throw new Error(`PSC1_BOOTSTRAP_SOURCE_OUTSIDE_WORKSPACE: ${sourcePath}`);
  }
  return relative.replace(/\.lean$/u, ".ps");
}

function translateFile(sourcePath, outputPath) {
  const relativeSource = path.relative(selfhostRoot, sourcePath);
  const relativeOutput = path.relative(selfhostRoot, outputPath);
  const result = spawnSync(
    "lake",
    [
      "exe",
      "psc1",
      "translate",
      relativeSource,
      "--to",
      "ps",
      "--out",
      relativeOutput,
    ],
    {
      cwd: selfhostRoot,
      encoding: "utf8",
      stdio: "pipe",
    },
  );
  if (result.status !== 0) {
    throw new Error(
      [
        `PSC1_BOOTSTRAP_TRANSLATE_FAILED: ${relativeSource}`,
        result.stdout,
        result.stderr,
      ].filter(Boolean).join("\n"),
    );
  }
}

const entryArg = process.argv[2] ?? "SELFHOST-COMPILER.lean";
const outArg = process.argv[3] ?? path.join("dist", "bootstrap", "workspace");
const entryPath = path.resolve(selfhostRoot, entryArg);
const outWorkspace = path.resolve(selfhostRoot, outArg);

const sources = await collectProject(entryPath);
const generated = [];

for (const sourcePath of sources) {
  const relative = translatedRelativePath(sourcePath);
  const outputPath = path.join(outWorkspace, relative);
  await mkdir(path.dirname(outputPath), { recursive: true });
  translateFile(sourcePath, outputPath);
  generated.push(relative.replaceAll(path.sep, "/"));
}

const entryRelative = translatedRelativePath(entryPath);
const manifest = {
  schemaVersion: 1,
  entry: entryRelative.replaceAll(path.sep, "/"),
  sourceCount: sources.length,
  generated,
};

await mkdir(outWorkspace, { recursive: true });
await writeFile(
  path.join(outWorkspace, ".proofscript-bootstrap.json"),
  JSON.stringify(manifest, null, 2) + "\n",
  "utf8",
);

process.stdout.write(
  [
    `PSC1_BOOTSTRAP_PS_WORKSPACE: ${path.relative(selfhostRoot, outWorkspace)}`,
    `PSC1_BOOTSTRAP_PS_ENTRY: ${path.join(path.relative(selfhostRoot, outWorkspace), entryRelative)}`,
    `PSC1_BOOTSTRAP_PS_SOURCES: ${sources.length}`,
  ].join("\n") + "\n",
);
