import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const packageRoot = path.join(root, "packages", "pskernel-selfhost");
const sourceRoot = path.join(packageRoot, "src", "Ps", "KernelSelfHost");
const manifestPath = path.join(packageRoot, "PSKERNEL_ARCHITECTURE.json");
const compatibilityPath = path.join(packageRoot, "LEAN_4_34_COMPATIBILITY.json");
const conformancePath = path.join(packageRoot, "LEAN_4_34_CONFORMANCE.json");

const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
const compatibility = JSON.parse(fs.readFileSync(compatibilityPath, "utf8"));
const conformance = JSON.parse(fs.readFileSync(conformancePath, "utf8"));

function assertTarget(label, target) {
  if (
    target?.version !== manifest.target.version ||
    target?.gitCommit !== manifest.target.gitCommit
  ) {
    throw new Error("PSC1KERNEL_ARCH_TARGET_MISMATCH: " + label);
  }
}

assertTarget("compatibility", compatibility.target);
assertTarget("conformance", conformance.target);

const prefix = manifest.semanticModulePrefix;

function modulePath(moduleName) {
  if (!moduleName.startsWith(prefix)) {
    throw new Error("PSC1KERNEL_ARCH_EXTERNAL_MODULE: " + moduleName);
  }
  const suffix = moduleName.slice(prefix.length).split(".").join(path.sep);
  return path.join(sourceRoot, suffix + ".lean");
}

function importsOf(source) {
  const imports = [];
  const pattern = /^import\s+([^\s]+)\s*$/gmu;
  for (const match of source.matchAll(pattern)) imports.push(match[1]);
  return imports;
}

const queue = [manifest.semanticRootModule];
const seen = new Set();

while (queue.length > 0) {
  const moduleName = queue.shift();
  if (seen.has(moduleName)) continue;
  seen.add(moduleName);

  const file = modulePath(moduleName);
  if (!fs.existsSync(file)) {
    throw new Error("PSC1KERNEL_ARCH_MODULE_MISSING: " + moduleName);
  }

  const source = fs.readFileSync(file, "utf8");
  for (const imported of importsOf(source)) {
    for (const forbidden of manifest.forbiddenSemanticImportPrefixes) {
      if (imported.startsWith(forbidden)) {
        throw new Error(
          "PSC1KERNEL_ARCH_FORBIDDEN_IMPORT: " + moduleName + ": " + imported
        );
      }
    }
    if (imported.startsWith(prefix)) queue.push(imported);
  }
}

const expectedRoot = path.join(root, manifest.semanticRootPath);
if (modulePath(manifest.semanticRootModule) !== expectedRoot) {
  throw new Error("PSC1KERNEL_ARCH_ROOT_PATH");
}

for (const entry of manifest.currentRoleFiles) {
  const file = path.join(sourceRoot, entry.path);
  if (!fs.existsSync(file)) {
    throw new Error("PSC1KERNEL_ARCH_ROLE_FILE_MISSING: " + entry.path);
  }
  if (!manifest.semanticRoles.includes(entry.role)) {
    throw new Error(
      "PSC1KERNEL_ARCH_ROLE_UNKNOWN: " + entry.path + ": " + entry.role
    );
  }
}

const layerSet = new Set(manifest.targetLayers);
if (layerSet.size !== manifest.targetLayers.length) {
  throw new Error("PSC1KERNEL_ARCH_DUPLICATE_TARGET_LAYER");
}

if (!manifest.migration.finalArchitectureAdopted) {
  throw new Error("PSC1KERNEL_ARCH_REFERENCE_NOT_ADOPTED");
}
if (manifest.migration.finalArchitectureImplemented) {
  throw new Error(
    "PSC1KERNEL_ARCH_MIGRATION_STATUS: final architecture is not yet fully migrated"
  );
}

console.log(
  "PSC1KERNEL_ARCHITECTURE: target=" +
    manifest.target.version +
    "@" +
    manifest.target.gitCommit +
    " root=" +
    manifest.semanticRootModule +
    " closureModules=" +
    seen.size +
    " migration=" +
    manifest.migration.phase
);
