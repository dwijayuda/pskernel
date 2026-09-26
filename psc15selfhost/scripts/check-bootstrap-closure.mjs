import { existsSync } from "node:fs";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");

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
  ["BackendRust", "backend-rust"],
  ["BackendWasm", "backend-wasm"],
]);

const allowedBootstrapPackages = new Set([
  "bootstrap",
  "foundation",
  "syntax",
  "core",
  "environment",
  "project",
  "meta",
  "elab",
  "bridge",
  "compiler-ir",
  "erasure",
  "compiler",
  "backend-ts",
  "stdlib",
]);

const forbiddenBootstrapPackages = new Set([
  "backend-rust",
  "backend-wasm",
  "pskernel",
]);

function parseImports(source) {
  const imports = [];
  for (const line of source.split(/\r?\n/u)) {
    const match = line.match(/^\s*import\s+([A-Za-z0-9_.]+)\s*$/u);
    if (match) imports.push(match[1]);
  }
  return imports;
}

function sourceForModule(moduleName) {
  const parts = moduleName.split(".");
  if (parts[0] === "ProofScript") {
    return {
      packageName: "stdlib",
      sourcePath: path.join(root, "stdlib", ...parts) + ".lean",
    };
  }
  if (parts[0] === "Ps" && parts.length >= 2) {
    const packageName = packageBySection.get(parts[1]);
    if (!packageName) {
      throw new Error(`PSC2_BOOTSTRAP_UNKNOWN_PACKAGE: ${moduleName}`);
    }
    return {
      packageName,
      sourcePath: path.join(root, "packages", packageName, "src", ...parts) + ".lean",
    };
  }
  throw new Error(`PSC2_BOOTSTRAP_UNKNOWN_IMPORT: ${moduleName}`);
}

const psconfig = JSON.parse(await readFile(path.join(root, "psconfig.json"), "utf8"));
const requiredEntry = "packages/bootstrap/src/Ps/Bootstrap/SelfHost.lean";
if (psconfig.entry !== requiredEntry) {
  throw new Error(
    `PSC2_BOOTSTRAP_ENTRY: expected ${requiredEntry}, got ${psconfig.entry ?? "<none>"}`,
  );
}

if (psconfig.implementationProfile !== "PSC1") {
  throw new Error("PSC2_BOOTSTRAP_IMPLEMENTATION_PROFILE: expected PSC1");
}
if (psconfig.acceptedLanguageProfile !== "PSC2-bootstrap") {
  throw new Error("PSC2_BOOTSTRAP_ACCEPTED_PROFILE: expected PSC2-bootstrap");
}

const semanticApiPath = path.join(
  root,
  "packages",
  "compiler",
  "src",
  "Ps",
  "Compiler",
  "Api.lean",
);
const semanticApi = await readFile(semanticApiPath, "utf8");
if (/\bPs\.Backend/u.test(semanticApi)) {
  throw new Error("PSC2_BOOTSTRAP_COMPILER_API_BACKEND_COUPLING");
}

const entry = path.join(root, psconfig.entry);
if (!existsSync(entry)) {
  throw new Error(`PSC2_BOOTSTRAP_ENTRY_MISSING: ${psconfig.entry}`);
}

const visited = new Set();
const packageNames = new Set(["bootstrap"]);

async function visit(sourcePath) {
  const absolute = path.resolve(sourcePath);
  if (visited.has(absolute)) return;
  visited.add(absolute);

  if (!existsSync(absolute)) {
    throw new Error(`PSC2_BOOTSTRAP_SOURCE_MISSING: ${path.relative(root, absolute)}`);
  }

  const source = await readFile(absolute, "utf8");
  for (const moduleName of parseImports(source)) {
    const resolved = sourceForModule(moduleName);
    packageNames.add(resolved.packageName);
    await visit(resolved.sourcePath);
  }
}

await visit(entry);

for (const packageName of packageNames) {
  if (forbiddenBootstrapPackages.has(packageName)) {
    throw new Error(`PSC2_BOOTSTRAP_FORBIDDEN_PACKAGE: ${packageName}`);
  }
  if (!allowedBootstrapPackages.has(packageName)) {
    throw new Error(`PSC2_BOOTSTRAP_UNAPPROVED_PACKAGE: ${packageName}`);
  }
}

process.stdout.write(
  `PSC2_BOOTSTRAP_CLOSURE: PASS (${visited.size} modules; ${[...packageNames].sort().join(", ")})\n`,
);
