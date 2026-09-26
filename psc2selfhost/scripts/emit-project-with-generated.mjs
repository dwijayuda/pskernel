import { mkdir, readFile, writeFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

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
  ["Compiler", "compiler"],
  ["Erasure", "erasure"],
  ["BackendTs", "backend-ts"],
]);

function usage() {
  return [
    "usage:",
    "  node scripts/emit-project-with-generated.mjs <compiler.js> <entry.lean|entry.ps> --to <lean|ps> --out <workspace>",
  ].join("\n");
}

function parseImports(source) {
  const imports = [];
  for (const line of source.split(/\r?\n/u)) {
    const match = line.match(/^\s*import\s+([A-Za-z0-9_.]+)\s*;?\s*$/u);
    if (match) imports.push(match[1]);
  }
  return imports;
}

function findWorkspaceRoot(entryPath) {
  let current = path.dirname(entryPath);
  for (let fuel = 0; fuel < 64; fuel += 1) {
    const hasGeneratedManifest = [
      ".proofscript-bootstrap.json",
      ".proofscript-selfhost.json",
      ".proofscript-project.json",
    ].some((name) => existsSync(path.join(current, name)));
    if (
      existsSync(path.join(current, "packages")) &&
      (
        existsSync(path.join(current, "package.json")) ||
        hasGeneratedManifest
      )
    ) {
      return current;
    }
    const parent = path.dirname(current);
    if (parent === current) break;
    current = parent;
  }
  throw new Error(`PSC1_PROJECT_WORKSPACE_NOT_FOUND: ${entryPath}`);
}

function firstExisting(candidates) {
  for (const candidate of candidates) {
    if (existsSync(candidate)) return candidate;
  }
  return undefined;
}

function moduleBaseCandidates(workspaceRoot, moduleName) {
  const parts = moduleName.split(".");
  if (parts[0] === "ProofScript") {
    return [
      path.join(workspaceRoot, "packages", "stdlib", "src", ...parts),
      path.join(workspaceRoot, "packages", "stdlib", ...parts),
      path.join(workspaceRoot, "stdlib", ...parts),
    ];
  }
  if (parts[0] === "Ps" && parts.length >= 2) {
    const packageName = packageBySection.get(parts[1]);
    if (!packageName) {
      throw new Error(`PSC1_PROJECT_UNKNOWN_PACKAGE: ${moduleName}`);
    }
    return [
      path.join(workspaceRoot, "packages", packageName, "src", ...parts),
    ];
  }
  return [path.join(workspaceRoot, ...parts)];
}

function resolveModuleSource(workspaceRoot, moduleName, preferredExtension) {
  const alternateExtension = preferredExtension === ".lean" ? ".ps" : ".lean";
  const bases = moduleBaseCandidates(workspaceRoot, moduleName);
  const preferred = firstExisting(
    bases.map((base) => base + preferredExtension),
  );
  if (preferred) return preferred;

  const alternate = firstExisting(
    bases.map((base) => base + alternateExtension),
  );
  if (alternate) return alternate;

  throw new Error(`PSC1_PROJECT_SOURCE_MISSING: ${moduleName}`);
}

function exceptTag(value) {
  if (value === null || typeof value !== "object") return undefined;
  for (const symbol of Object.getOwnPropertySymbols(value)) {
    const tag = value[symbol];
    if (tag === "ok" || tag === "error") return tag;
  }
  return undefined;
}

function unwrapExcept(value, stage, sourcePath) {
  const tag = exceptTag(value);
  if (tag === "ok") return value.value;
  if (tag === "error") {
    throw new Error(
      `PSC1_PROJECT_${stage.toUpperCase()}_FAILED: ${sourcePath}: ${JSON.stringify(value.error)}`,
    );
  }
  throw new Error(
    `PSC1_PROJECT_${stage.toUpperCase()}_RESULT_SHAPE: ${sourcePath}`,
  );
}

function compilerKind(compiler, extension) {
  if (extension === ".lean" || extension === "lean") {
    return compiler.PsCompilerSourceKind.lean;
  }
  if (extension === ".ps" || extension === "ps") {
    return compiler.PsCompilerSourceKind.proofScript;
  }
  throw new Error(`PSC1_PROJECT_SOURCE_KIND: ${extension}`);
}

if (process.argv.length < 8) {
  throw new Error(usage());
}

const compilerPath = path.resolve(selfhostRoot, process.argv[2]);
const entryPath = path.resolve(selfhostRoot, process.argv[3]);
const toIndex = process.argv.indexOf("--to");
const outIndex = process.argv.indexOf("--out");
const targetText = toIndex >= 0 ? process.argv[toIndex + 1] : undefined;
const outputWorkspace =
  outIndex >= 0
    ? path.resolve(selfhostRoot, process.argv[outIndex + 1])
    : undefined;

if (!targetText || !outputWorkspace) throw new Error(usage());
if (!existsSync(compilerPath)) {
  throw new Error(`PSC1_PROJECT_COMPILER_MISSING: ${compilerPath}`);
}

const sourceExtension = entryPath.endsWith(".lean")
  ? ".lean"
  : entryPath.endsWith(".ps")
    ? ".ps"
    : undefined;
if (!sourceExtension) {
  throw new Error(`PSC1_PROJECT_ENTRY_KIND: ${entryPath}`);
}
const targetExtension =
  targetText === "lean" || targetText === ".lean"
    ? ".lean"
    : targetText === "ps" || targetText === ".ps"
      ? ".ps"
      : undefined;
if (!targetExtension) {
  throw new Error(`PSC1_PROJECT_TARGET_KIND: ${targetText}`);
}

const compiler = await import(pathToFileURL(compilerPath).href);
if (
  !("PsCompilerSourceKind" in compiler) ||
  !("psCompilerTranslateSource" in compiler)
) {
  throw new Error("PSC1_PROJECT_COMPILER_API_MISSING");
}

const workspaceRoot = findWorkspaceRoot(entryPath);
const sourceKind = compilerKind(compiler, sourceExtension);
const targetKind = compilerKind(compiler, targetExtension);
const visited = new Set();
const ordered = [];

async function visit(sourcePath) {
  const absolute = path.resolve(sourcePath);
  if (visited.has(absolute)) return;
  visited.add(absolute);

  const source = await readFile(absolute, "utf8");
  for (const moduleName of parseImports(source)) {
    await visit(
      resolveModuleSource(
        workspaceRoot,
        moduleName,
        sourceExtension,
      ),
    );
  }
  ordered.push({ path: absolute, source });
}

await visit(entryPath);

const generated = [];
for (const item of ordered) {
  const itemExtension = item.path.endsWith(".lean") ? ".lean" : ".ps";
  const itemKind = compilerKind(compiler, itemExtension);
  const translated = unwrapExcept(
    compiler.psCompilerTranslateSource(itemKind, targetKind, item.source),
    "translate",
    item.path,
  );

  const relative = path.relative(workspaceRoot, item.path);
  if (relative.startsWith("..") || path.isAbsolute(relative)) {
    throw new Error(`PSC1_PROJECT_SOURCE_OUTSIDE_WORKSPACE: ${item.path}`);
  }
  const targetRelative = relative.replace(/\.(lean|ps)$/u, targetExtension);
  const outputPath = path.join(outputWorkspace, targetRelative);
  await mkdir(path.dirname(outputPath), { recursive: true });
  await writeFile(outputPath, translated, "utf8");
  generated.push(targetRelative.replaceAll(path.sep, "/"));
}

const entryRelative = path
  .relative(workspaceRoot, entryPath)
  .replace(/\.(lean|ps)$/u, targetExtension)
  .replaceAll(path.sep, "/");

function leanModuleName(relativePath, sourceRoot) {
  const relativeModule = path.posix
    .relative(sourceRoot, relativePath)
    .replace(/\.lean$/u, "");
  return relativeModule.split("/").join(".");
}

function generatedLakefile(generatedFiles) {
  const groups = new Map();

  for (const relativePath of generatedFiles) {
    if (!relativePath.endsWith(".lean")) continue;
    const normalized = relativePath.replaceAll("\\", "/");
    let sourceRoot;
    let key;

    const packageMatch = normalized.match(/^packages\/([^/]+)\/src\/(.+)\.lean$/u);
    if (packageMatch) {
      key = `package-${packageMatch[1]}`;
      sourceRoot = `packages/${packageMatch[1]}/src`;
    } else if (normalized.startsWith("stdlib/")) {
      key = "stdlib";
      sourceRoot = "stdlib";
    } else {
      key = "root";
      sourceRoot = ".";
    }

    const entry = groups.get(key) ?? { sourceRoot, modules: [] };
    entry.modules.push(leanModuleName(normalized, sourceRoot));
    groups.set(key, entry);
  }

  const lines = [
    "import Lake",
    "open Lake DSL",
    "",
    "package proofscriptGenerated",
    "",
  ];

  let index = 0;
  for (const entry of groups.values()) {
    const targetName = `GeneratedLib${index}`;
    index += 1;
    lines.push("@[default_target]");
    lines.push(`lean_lib ${targetName} where`);
    lines.push(`  srcDir := "${entry.sourceRoot}"`);
    lines.push("  roots := #[");
    const modules = [...entry.modules].sort();
    for (let moduleIndex = 0; moduleIndex < modules.length; moduleIndex += 1) {
      const suffix = moduleIndex + 1 === modules.length ? "" : ",";
      lines.push(`    \`${modules[moduleIndex]}${suffix}`);
    }
    lines.push("  ]");
    lines.push("");
  }

  return lines.join("\n");
}

async function writeGeneratedProjectMetadata() {
  if (targetExtension === ".ps") {
    const generatedConfig = {
      languageVersion: "0.7",
      entry: entryRelative,
      sourceRoots: ["packages", "stdlib"],
      runtimeDependencies: {},
      compilerOptions: {
        outDir: "dist",
        emitTypeScript: true,
        declaration: true,
        sourceMap: true,
      },
    };
    await writeFile(
      path.join(outputWorkspace, "psconfig.json"),
      JSON.stringify(generatedConfig, null, 2) + "\n",
      "utf8",
    );
  } else {
    await writeFile(
      path.join(outputWorkspace, "lean-toolchain"),
      "leanprover/lean4:v4.34.0\n",
      "utf8",
    );
    await writeFile(
      path.join(outputWorkspace, "lakefile.lean"),
      generatedLakefile(generated),
      "utf8",
    );
  }
}

const manifest = {
  schemaVersion: 1,
  sourceKind: sourceExtension.slice(1),
  targetKind: targetExtension.slice(1),
  entry: entryRelative,
  sourceCount: generated.length,
  generated,
};

await mkdir(outputWorkspace, { recursive: true });
await writeFile(
  path.join(outputWorkspace, ".proofscript-project.json"),
  JSON.stringify(manifest, null, 2) + "\n",
  "utf8",
);

await writeGeneratedProjectMetadata();

process.stdout.write(
  [
    `PSC1_PROJECT_EMIT_SOURCE: ${path.relative(selfhostRoot, entryPath)}`,
    `PSC1_PROJECT_EMIT_TARGET: ${targetExtension.slice(1)}`,
    `PSC1_PROJECT_EMIT_OUTPUT: ${path.relative(selfhostRoot, outputWorkspace)}`,
    `PSC1_PROJECT_EMIT_FILES: ${generated.length}`,
  ].join("\n") + "\n",
);
