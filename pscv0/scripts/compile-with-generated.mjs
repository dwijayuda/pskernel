import { mkdir, readFile, writeFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { packageBySection, parseImports } from "./workspace-layout.mjs";
import { findSourceWorkspaceRoot, readGeneratedSourceClosure } from "./selfhost-source-workspace.mjs";
import { compileTypeScriptCached } from "./compile-typescript-cached.mjs";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const selfhostRoot = path.resolve(scriptDir, "..");

function usage() {
  return [
    "usage:",
    "  node scripts/compile-with-generated.mjs <compiler.js> <entry.lean|entry.ps> <output.ts|output.js>",
  ].join("\n");
}

function stripImports(source) {
  return source
    .split(/\r?\n/u)
    .filter((line) => !/^\s*import\s+[A-Za-z0-9_.]+\s*;?\s*$/u.test(line))
    .join("\n")
    .trim();
}

function moduleBasePath(workspaceRoot, moduleName) {
  const parts = moduleName.split(".");
  if (parts[0] === "ProofScript") {
    return path.join(workspaceRoot, "stdlib", ...parts);
  }
  if (parts[0] === "Ps" && parts.length >= 2) {
    const packageName = packageBySection.get(parts[1]);
    if (!packageName) {
      throw new Error(`PSC2_SELFHOST_UNKNOWN_PACKAGE: ${moduleName}`);
    }
    return path.join(
      workspaceRoot,
      "packages",
      packageName,
      "src",
      ...parts,
    );
  }
  return path.join(workspaceRoot, ...parts);
}

function resolveModuleSource(workspaceRoot, moduleName) {
  const base = moduleBasePath(workspaceRoot, moduleName);
  const leanPath = base + ".lean";
  const proofScriptPath = base + ".ps";
  const hasLean = existsSync(leanPath);
  const hasProofScript = existsSync(proofScriptPath);

  if (hasLean && hasProofScript) {
    if (moduleName.startsWith("Ps.") || moduleName.startsWith("ProofScript.")) {
      return leanPath;
    }
    throw new Error(`PSC2_SELFHOST_SOURCE_AMBIGUITY: ${moduleName}`);
  }
  if (hasLean) return leanPath;
  if (hasProofScript) return proofScriptPath;
  throw new Error(`PSC2_SELFHOST_SOURCE_MISSING: ${moduleName}`);
}

function exceptTag(value) {
  if (value === null || typeof value !== "object") return undefined;
  for (const symbol of Object.getOwnPropertySymbols(value)) {
    const tag = value[symbol];
    if (tag === "ok" || tag === "error") return tag;
  }
  return undefined;
}

function unwrapExcept(value, stage) {
  const tag = exceptTag(value);
  if (tag === "ok") return value.value;
  if (tag === "error") {
    throw new Error(
      `PSC2_SELFHOST_${stage.toUpperCase()}_FAILED: ${JSON.stringify(value.error)}`,
    );
  }
  throw new Error(`PSC2_SELFHOST_${stage.toUpperCase()}_RESULT_SHAPE`);
}

function requireCompilerApi(compiler) {
  const required = [
    "PsCompilerSourceKind",
    "psCompilerTranslateSource",
    "psCompilerTypeScriptFromPrepared",
    "List",
    "psCompilerParseSource",
    "psElabModule",
    "psListReverse",
    "psListAppend",
    "psCompilerElaborateSourcesWorker",
    "psCompilerPrepareElaborated",
    "psSelfHostProdPreludeEnvironment",
  ];
  for (const name of required) {
    if (!(name in compiler)) {
      throw new Error(`PSC2_SELFHOST_COMPILER_EXPORT_MISSING: ${name}`);
    }
  }
}

function sourceKind(compiler, sourcePath) {
  if (sourcePath.endsWith(".lean")) {
    return compiler.PsCompilerSourceKind.lean;
  }
  if (sourcePath.endsWith(".ps")) {
    return compiler.PsCompilerSourceKind.proofScript;
  }
  throw new Error(`PSC2_SELFHOST_SOURCE_KIND: ${sourcePath}`);
}

async function flattenProject(compiler, entryPath) {
  const workspaceRoot = findSourceWorkspaceRoot(entryPath);
  const generated = await readGeneratedSourceClosure(entryPath, workspaceRoot);
  const targetKind = sourceKind(compiler, entryPath);
  const visited = new Set();
  const ordered = [];

  async function visit(sourcePath) {
    const absolute = path.resolve(sourcePath);
    if (visited.has(absolute)) return;
    visited.add(absolute);

    if (!existsSync(absolute)) {
      throw new Error(`PSC2_SELFHOST_SOURCE_MISSING: ${absolute}`);
    }

    const source = await readFile(absolute, "utf8");
    for (const moduleName of parseImports(source)) {
      await visit(resolveModuleSource(workspaceRoot, moduleName));
    }
    ordered.push({ path: absolute, source });
  }

  if (generated) ordered.push(...generated.ordered);
  else await visit(entryPath);

  const chunks = [];
  for (const item of ordered) {
    const itemKind = sourceKind(compiler, item.path);
    const normalized =
      item.path.endsWith(entryPath.endsWith(".lean") ? ".lean" : ".ps")
        ? item.source
        : unwrapExcept(
            compiler.psCompilerTranslateSource(
              itemKind,
              targetKind,
              item.source,
            ),
            "translate",
          );
    const body = stripImports(normalized);
    if (body.length > 0) chunks.push(body);
  }

  return {
    workspaceRoot,
    moduleCount: ordered.length,
    closureSha256: generated?.closureSha256,
    sourceKind: targetKind,
    sources: chunks,
    source: chunks.join("\n\n") + "\n",
  };
}

function prepareSourcesIncrementally(compiler, sourceKindValue, sourceChunks) {
  let environment = compiler.psSelfHostProdPreludeEnvironment;
  let declarationsRev = compiler.List.nil();
  const progress = process.env.PSC_SELFHOST_PROGRESS === "1";
  const allStarted = performance.now();

  for (let index = 0; index < sourceChunks.length; index += 1) {
    const source = sourceChunks[index];
    const moduleStarted = performance.now();
    const parsed = unwrapExcept(
      compiler.psCompilerParseSource(sourceKindValue, source),
      `parse-module-${index + 1}`,
    );
    const elaborated = unwrapExcept(
      compiler.psElabModule(environment, parsed),
      `elaborate-module-${index + 1}`,
    );
    environment = elaborated.environment;
    declarationsRev = compiler.psListAppend(
      compiler.psListReverse(elaborated.declarations),
      declarationsRev,
    );
    if (progress) {
      process.stdout.write(
        `PSC2_SELFHOST_INCREMENTAL_MODULE: ${index + 1}/${sourceChunks.length} ms=${Math.round(performance.now() - moduleStarted)}\n`,
      );
    }
  }

  const prepareStarted = performance.now();
  const elaborated = unwrapExcept(
    compiler.psCompilerElaborateSourcesWorker(
      sourceKindValue,
      compiler.List.nil(),
      environment,
      declarationsRev,
    ),
    "finalize",
  );
  const prepared = unwrapExcept(
    compiler.psCompilerPrepareElaborated(elaborated),
    "prepare",
  );
  process.stdout.write(
    `PSC2_SELFHOST_INCREMENTAL_PREPARE: PASS (${sourceChunks.length} modules; prepareMs=${Math.round(performance.now() - prepareStarted)}; totalMs=${Math.round(performance.now() - allStarted)})\n`,
  );
  return prepared;
}

if (process.argv.length < 5) {
  throw new Error(usage());
}

const compilerPath = path.resolve(selfhostRoot, process.argv[2]);
const entryPath = path.resolve(selfhostRoot, process.argv[3]);
const requestedOutputPath = path.resolve(selfhostRoot, process.argv[4]);
const outputTsPath =
  requestedOutputPath.endsWith(".js")
    ? requestedOutputPath.replace(/\.js$/u, ".ts")
    : requestedOutputPath;

const emitOnly = process.argv.slice(5).includes("--emit-only");

if (!existsSync(compilerPath)) {
  throw new Error(`PSC2_SELFHOST_COMPILER_MISSING: ${compilerPath}`);
}
if (!entryPath.endsWith(".ps") && !entryPath.endsWith(".lean")) {
  throw new Error(`PSC2_SELFHOST_SOURCE_KIND: ${entryPath}`);
}
if (!outputTsPath.endsWith(".ts")) {
  throw new Error(
    `PSC2_SELFHOST_OUTPUT_KIND: expected .ts or .js, got ${requestedOutputPath}`,
  );
}

const compiler = await import(pathToFileURL(compilerPath).href);
requireCompilerApi(compiler);

const project = await flattenProject(compiler, entryPath);
const prepared = prepareSourcesIncrementally(
  compiler,
  project.sourceKind,
  project.sources,
);
process.stdout.write("PSC2_SELFHOST_PREPARE_MODE: incremental\n");
const backendStarted = performance.now();
const typeScript = unwrapExcept(
  compiler.psCompilerTypeScriptFromPrepared(prepared),
  "compile",
);
const backendMs = Math.round(performance.now() - backendStarted);

await mkdir(path.dirname(outputTsPath), { recursive: true });
await writeFile(outputTsPath, typeScript, "utf8");
const tscStarted = performance.now();
const tscCache = emitOnly ? { cache: "skipped" } : await compileTypeScriptCached(selfhostRoot, outputTsPath);
const tscMs = Math.round(performance.now() - tscStarted);

process.stdout.write(
  [
    `PSC2_SELFHOST_COMPILER: ${path.relative(selfhostRoot, compilerPath)}`,
    `PSC2_SELFHOST_SOURCE: ${path.relative(selfhostRoot, entryPath)}`,
    `PSC2_SELFHOST_MODULES: ${project.moduleCount}`,
    ...(project.closureSha256 ? [`PSC2_SELFHOST_SOURCE_CLOSURE_SHA256: ${project.closureSha256}`] : []),
    `PSC2_SELFHOST_TS: ${path.relative(selfhostRoot, outputTsPath)}`,
    ...(emitOnly
      ? ["PSC2_SELFHOST_TYPESCRIPT_CHECK: SKIPPED (emit-only)"]
      : [`PSC2_SELFHOST_JS: ${path.relative(selfhostRoot, outputTsPath.replace(/\.ts$/u, ".js"))}`]),
    `PSC2_SELFHOST_BACKEND_MS: ${backendMs}`,
    `PSC2_SELFHOST_TSC_MS: ${tscMs}`,
    `PSC2_SELFHOST_TSC_CACHE: ${tscCache.cache}`,
  ].join("\n") + "\n",
);
