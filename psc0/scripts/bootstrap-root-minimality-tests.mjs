import { existsSync } from "node:fs";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { packageBySection, parseImports } from "./workspace-layout.mjs";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const entry = path.join(
  root,
  "packages",
  "bootstrap",
  "src",
  "Ps",
  "Bootstrap",
  "SelfHost.lean",
);
const tsCompositionModule = "Ps.BackendTs.Compiler";

function moduleSourcePath(moduleName) {
  const parts = moduleName.split(".");
  if (parts[0] === "ProofScript") {
    return path.join(root, "stdlib", ...parts) + ".lean";
  }
  if (parts[0] === "Ps" && parts.length >= 2) {
    const packageName = packageBySection.get(parts[1]);
    if (!packageName) {
      throw new Error(`PSC2_BOOTSTRAP_ROOT_UNKNOWN_PACKAGE: ${moduleName}`);
    }
    return path.join(root, "packages", packageName, "src", ...parts) + ".lean";
  }
  throw new Error(`PSC2_BOOTSTRAP_ROOT_UNKNOWN_IMPORT: ${moduleName}`);
}

async function orderedClosureFromRootImports(rootImports) {
  const visited = new Set();
  const ordered = [];

  async function visit(sourcePath) {
    const absolute = path.resolve(sourcePath);
    if (visited.has(absolute)) return;
    visited.add(absolute);
    if (!existsSync(absolute)) {
      throw new Error(
        `PSC2_BOOTSTRAP_ROOT_SOURCE_MISSING: ${path.relative(root, absolute)}`,
      );
    }
    const source = await readFile(absolute, "utf8");
    for (const moduleName of parseImports(source)) {
      await visit(moduleSourcePath(moduleName));
    }
    ordered.push(path.relative(root, absolute).replaceAll(path.sep, "/"));
  }

  for (const moduleName of rootImports) {
    await visit(moduleSourcePath(moduleName));
  }
  ordered.push(path.relative(root, entry).replaceAll(path.sep, "/"));
  return ordered;
}

const entrySource = await readFile(entry, "utf8");
const directImports = parseImports(entrySource);
if (directImports.length === 0) {
  throw new Error("PSC2_BOOTSTRAP_ROOT_NO_IMPORTS");
}
if (!directImports.includes(tsCompositionModule)) {
  throw new Error("PSC2_BOOTSTRAP_ROOT_MISSING_TS_COMPOSITION");
}
if (directImports.some((moduleName) => moduleName.startsWith('Ps.Kernel.'))) {
  throw new Error('PSC2_BOOTSTRAP_ROOT_KERNEL_MUST_BE_HOST_SIDE');
}
if (JSON.stringify(directImports) !== JSON.stringify([tsCompositionModule])) {
  throw new Error(`PSC2_BOOTSTRAP_ROOT_NOT_COMPILER_ONLY: ${directImports.join(", ")}`);
}

const baseline = await orderedClosureFromRootImports(directImports);
const redundant = [];
for (const moduleName of directImports) {
  const candidate = await orderedClosureFromRootImports(
    directImports.filter((candidateImport) => candidateImport !== moduleName),
  );
  if (JSON.stringify(candidate) === JSON.stringify(baseline)) {
    redundant.push(moduleName);
  }
}

if (redundant.length > 0) {
  throw new Error(
    `PSC2_BOOTSTRAP_ROOT_REDUNDANT_IMPORTS: ${redundant.join(", ")}`,
  );
}

const compilerOnlyClosure = await orderedClosureFromRootImports([
  tsCompositionModule,
]);
const compilerOnlyStdlib = compilerOnlyClosure.filter((relativePath) =>
  relativePath.startsWith("stdlib/"),
);
if (compilerOnlyStdlib.length > 0) {
  throw new Error(
    `PSC2_BOOTSTRAP_ROOT_COMPILER_REQUIRES_STDLIB: ${compilerOnlyStdlib.join(", ")}`,
  );
}

const portableLibraryImports = directImports.filter((moduleName) =>
  moduleName.startsWith("ProofScript."),
);
if (portableLibraryImports.length > 0) {
  throw new Error(
    [
      "PSC2_BOOTSTRAP_ROOT_LIBRARY_AGGREGATION:",
      portableLibraryImports.join(", "),
      `(compiler-only closure is ${compilerOnlyClosure.length} modules and reaches no stdlib sources)`,
    ].join(" "),
  );
}

process.stdout.write(
  `PSC2_BOOTSTRAP_ROOT_MINIMALITY: PASS (${directImports.length} direct imports; ${baseline.length} ordered closure modules; compiler-only=${compilerOnlyClosure.length})\n`,
);
