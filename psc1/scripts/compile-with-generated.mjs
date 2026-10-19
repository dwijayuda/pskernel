import { mkdir, readFile, writeFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { spawnSync } from "node:child_process";
import { packageBySection, parseImports } from "./workspace-layout.mjs";
import { readProofScriptImports, readProofScriptSource } from "./proofscript-source.mjs";
import { findSourceWorkspaceRoot, readGeneratedSourceClosure } from "./selfhost-source-workspace.mjs";
import { expectedTypeScriptVersion, resolveTypeScriptCli, typeScriptProfileArgs } from "./typescript-cli.mjs";

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
    "psCompilerPrepareSources",
    "psCompilerTypeScriptFromPrepared",
    "List",
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
  const parsedImports = (source, file) => readProofScriptImports(compiler, source, file);
  const generated = await readGeneratedSourceClosure(entryPath, workspaceRoot, parsedImports);
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

    const source = absolute.endsWith(".ps")
      ? await readProofScriptSource(absolute) : await readFile(absolute, "utf8");
    const imports = absolute.endsWith(".ps") ? parsedImports(source, absolute) : parseImports(source);
    for (const moduleName of imports) {
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
    // PS keeps exact raw bytes, including imports and leading whitespace.
    const body = entryPath.endsWith(".ps") ? normalized : stripImports(normalized);
    if (entryPath.endsWith(".ps") || body.length > 0) chunks.push(body);
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

function compileTypeScript(typeScriptPath) {
  const expectedVersion = expectedTypeScriptVersion();
  const tsc = resolveTypeScriptCli();
  const version = spawnSync(process.execPath, [tsc, '--version'], { encoding: 'utf8', timeout: 10000 });
  if (version.error || version.status !== 0 || version.stdout.trim() !== 'Version ' + expectedVersion)
    throw new Error('PSC2_SELFHOST_TYPESCRIPT_PIN: require TypeScript ' + expectedVersion);
  const result = spawnSync(
    process.execPath,
    [
      tsc,
      ...typeScriptProfileArgs([
        typeScriptPath,
        "--target",
        "ES2022",
        "--module",
        "ES2022",
        "--moduleResolution",
        "bundler",
        "--strict",
        "--declaration",
        "--sourceMap",
        "--noEmitOnError",
        "--skipLibCheck",
        "--pretty",
        "false",
      ], expectedVersion),
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
        "PSC2_SELFHOST_TSC_FAILED",
        result.stdout,
        result.stderr,
      ].filter(Boolean).join("\n"),
    );
  }
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
const sources = project.sources.reduceRight((tail, head) => compiler.List.cons(head, tail), compiler.List.nil());
const prepared = unwrapExcept(compiler.psCompilerPrepareSources(project.sourceKind, sources), "prepare");
const typeScript = unwrapExcept(compiler.psCompilerTypeScriptFromPrepared(prepared), "compile");

await mkdir(path.dirname(outputTsPath), { recursive: true });
await writeFile(outputTsPath, typeScript, "utf8");
compileTypeScript(outputTsPath);

process.stdout.write(
  [
    `PSC2_SELFHOST_COMPILER: ${path.relative(selfhostRoot, compilerPath)}`,
    `PSC2_SELFHOST_SOURCE: ${path.relative(selfhostRoot, entryPath)}`,
    `PSC2_SELFHOST_MODULES: ${project.moduleCount}`,
    ...(project.closureSha256 ? [`PSC2_SELFHOST_SOURCE_CLOSURE_SHA256: ${project.closureSha256}`] : []),
    `PSC2_SELFHOST_TS: ${path.relative(selfhostRoot, outputTsPath)}`,
    `PSC2_SELFHOST_JS: ${path.relative(selfhostRoot, outputTsPath.replace(/\.ts$/u, ".js"))}`,
  ].join("\n") + "\n",
);
