import { mkdir, readFile, writeFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { spawnSync } from "node:child_process";
import { parseImports, resolveModuleSource } from "./workspace-layout.mjs";

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

function findWorkspaceRoot(entryPath) {
  let current = path.dirname(entryPath);
  for (let fuel = 0; fuel < 64; fuel += 1) {
    if (
      existsSync(path.join(current, "packages")) &&
      existsSync(path.join(current, "stdlib"))
    ) {
      return current;
    }
    const parent = path.dirname(current);
    if (parent === current) break;
    current = parent;
  }
  throw new Error(`PSC2_SELFHOST_WORKSPACE_NOT_FOUND: ${entryPath}`);
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
    "psCompilerTypeScriptSource",
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
  const workspaceRoot = findWorkspaceRoot(entryPath);
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
      const dependency = resolveModuleSource(
        workspaceRoot,
        moduleName,
        ".lean",
      );
      if (!dependency) {
        throw new Error(`PSC2_SELFHOST_SOURCE_MISSING: ${moduleName}`);
      }
      await visit(dependency);
    }
    ordered.push({ path: absolute, source });
  }

  await visit(entryPath);

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
    sourceKind: targetKind,
    source: chunks.join("\n\n") + "\n",
  };
}

function compileTypeScript(typeScriptPath) {
  const npx = process.platform === "win32" ? "npx.cmd" : "npx";
  const result = spawnSync(
    npx,
    [
      "--no-install",
      "tsc",
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
const typeScript = unwrapExcept(
  compiler.psCompilerTypeScriptSource(
    project.sourceKind,
    project.source,
  ),
  "compile",
);

await mkdir(path.dirname(outputTsPath), { recursive: true });
await writeFile(outputTsPath, typeScript, "utf8");
compileTypeScript(outputTsPath);

process.stdout.write(
  [
    `PSC2_SELFHOST_COMPILER: ${path.relative(selfhostRoot, compilerPath)}`,
    `PSC2_SELFHOST_SOURCE: ${path.relative(selfhostRoot, entryPath)}`,
    `PSC2_SELFHOST_MODULES: ${project.moduleCount}`,
    `PSC2_SELFHOST_TS: ${path.relative(selfhostRoot, outputTsPath)}`,
    `PSC2_SELFHOST_JS: ${path.relative(selfhostRoot, outputTsPath.replace(/\.ts$/u, ".js"))}`,
  ].join("\n") + "\n",
);
