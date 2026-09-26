import { existsSync } from "node:fs";
import { readFile, readdir } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { packageBySection, parseImports } from "./workspace-layout.mjs";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");

const allowedBootstrapPackages = new Set([
  "bootstrap",
  "foundation",
  "syntax",
  "core",
  "environment",
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
  "project",
  "backend-rust",
  "backend-wasm",
  "pskernel",
]);

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

async function readJson(file) {
  return JSON.parse(await readFile(file, "utf8"));
}

async function workspaceManifests() {
  const byFolder = new Map();
  const byName = new Map();
  const packageEntries = await readdir(path.join(root, "packages"), {
    withFileTypes: true,
  });
  const directories = packageEntries
    .filter((entry) => entry.isDirectory())
    .map((entry) => ({ folder: entry.name, directory: path.join(root, "packages", entry.name) }));
  directories.push({ folder: "stdlib", directory: path.join(root, "stdlib") });

  for (const { folder, directory } of directories) {
    const manifestPath = path.join(directory, "package.json");
    if (!existsSync(manifestPath)) continue;
    const manifest = await readJson(manifestPath);
    const record = { folder, directory, manifest };
    byFolder.set(folder, record);
    if (typeof manifest.name === "string") byName.set(manifest.name, record);
  }
  return { byFolder, byName };
}

const psconfig = await readJson(path.join(root, "psconfig.json"));
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

const manifests = await workspaceManifests();
for (const packageName of packageNames) {
  const record = manifests.byFolder.get(packageName);
  if (!record) {
    throw new Error(`PSC2_BOOTSTRAP_MANIFEST_MISSING: ${packageName}`);
  }
  const config = record.manifest.proofscript;
  if (config?.bootstrap !== true || config?.portable === false) {
    throw new Error(`PSC2_BOOTSTRAP_MANIFEST_NOT_PORTABLE: ${packageName}`);
  }

  for (const dependencyName of Object.keys(record.manifest.dependencies ?? {})) {
    const dependency = manifests.byName.get(dependencyName);
    if (!dependency) continue;
    const dependencyConfig = dependency.manifest.proofscript;
    if (
      forbiddenBootstrapPackages.has(dependency.folder) ||
      !allowedBootstrapPackages.has(dependency.folder) ||
      dependencyConfig?.bootstrap !== true ||
      dependencyConfig?.portable === false
    ) {
      throw new Error(
        `PSC2_BOOTSTRAP_MANIFEST_DEPENDENCY: ${packageName} -> ${dependency.folder}`,
      );
    }
  }
}

process.stdout.write(
  `PSC2_BOOTSTRAP_CLOSURE: PASS (${visited.size} modules; ${[...packageNames].sort().join(", ")})\n`,
);
