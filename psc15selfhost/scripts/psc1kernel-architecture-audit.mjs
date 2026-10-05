import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { maskLeanNonCode } from "./psc1-source-profile.mjs";

export function auditArchitecture(root) {
const packageRoot = path.join(root, "packages", "pskernel-selfhost");
const sourceRoot = path.join(packageRoot, "src", "Ps", "KernelSelfHost");
const manifestPath = path.join(packageRoot, "PSKERNEL_ARCHITECTURE.json");
const compatibilityPath = path.join(packageRoot, "LEAN_4_34_COMPATIBILITY.json");
const conformancePath = path.join(packageRoot, "LEAN_4_34_CONFORMANCE.json");
const tcbPath = path.join(packageRoot, "PSKERNEL_TCB.json");

const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
const compatibility = JSON.parse(fs.readFileSync(compatibilityPath, "utf8"));
const conformance = JSON.parse(fs.readFileSync(conformancePath, "utf8"));
const tcb = JSON.parse(fs.readFileSync(tcbPath, "utf8"));

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
assertTarget("tcb", tcb.target);

if (tcb.productionSemanticRoot !== manifest.semanticRootModule) {
  throw new Error("PSC1KERNEL_ARCH_TCB_ROOT_MISMATCH");
}

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
  const pattern = /^[ \t]*(?:(?:public|private)[ \t]+)?import\b([^\n]*)/gmu;
  for (const match of maskLeanNonCode(source).matchAll(pattern)) {
    for (const moduleName of match[1].trim().split(/\s+/u)) {
      if (!/^[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*$/u.test(moduleName)) {
        throw new Error("PSC1KERNEL_ARCH_IMPORT_SYNTAX: " + moduleName);
      }
      imports.push(moduleName);
    }
  }
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
    if (!imported.startsWith(prefix)) {
      throw new Error("PSC1KERNEL_ARCH_EXTERNAL_IMPORT: " + moduleName + ": " + imported);
    }
    queue.push(imported);
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

for (const group of ["logicalTCB", "accelerationTCB", "capabilityTCB"]) {
  for (const entry of tcb[group] ?? []) {
    if (!manifest.semanticRoles.includes(entry.semanticRole)) {
      throw new Error(
        "PSC1KERNEL_ARCH_TCB_ROLE_UNKNOWN: " +
          group +
          ": " +
          entry.component +
          ": " +
          entry.semanticRole
      );
    }
    if (!manifest.trustStatuses.includes(entry.trustStatus)) {
      throw new Error(
        "PSC1KERNEL_ARCH_TCB_STATUS_UNKNOWN: " +
          group +
          ": " +
          entry.component +
          ": " +
          entry.trustStatus
      );
    }
    if (entry.path) {
      const target = path.join(sourceRoot, entry.path.replace(/^src\/Ps\/KernelSelfHost\//, ""));
      if (!fs.existsSync(target)) {
        throw new Error(
          "PSC1KERNEL_ARCH_TCB_FILE_MISSING: " + group + ": " + entry.path
        );
      }
    }
  }
}

const layerSet = new Set(manifest.targetLayers);
if (layerSet.size !== manifest.targetLayers.length) {
  throw new Error("PSC1KERNEL_ARCH_DUPLICATE_TARGET_LAYER");
}

if (!manifest.migration.finalArchitectureAdopted) {
  throw new Error("PSC1KERNEL_ARCH_REFERENCE_NOT_ADOPTED");
}
for (const shim of manifest.migration.migrationShims ?? []) {
  if (seen.has(shim)) {
    throw new Error("PSC1KERNEL_ARCH_SHIM_IN_SEMANTIC_ROOT: " + shim);
  }
}

const ownerAreas = new Set();
const ownerModules = new Set();
const registeredShims = new Set(manifest.migration.migrationShims ?? []);
for (const owner of manifest.canonicalOwners ?? []) {
  if (ownerAreas.has(owner.area) || ownerModules.has(owner.module)) {
    throw new Error("PSC1KERNEL_ARCH_DUPLICATE_OWNER: " + owner.area);
  }
  ownerAreas.add(owner.area);
  ownerModules.add(owner.module);
  if (owner.legacyShim) {
    if (!registeredShims.has(owner.legacyShim)) {
      throw new Error("PSC1KERNEL_ARCH_UNREGISTERED_SHIM: " + owner.legacyShim);
    }
    const shimSource = maskLeanNonCode(fs.readFileSync(modulePath(owner.legacyShim), "utf8")).trim();
    if (shimSource !== "import " + owner.module) {
      throw new Error("PSC1KERNEL_ARCH_NON_FORWARDING_SHIM: " + owner.legacyShim);
    }
  }
  if (!seen.has(owner.module)) {
    throw new Error(
      "PSC1KERNEL_ARCH_CANONICAL_OWNER_NOT_IN_CLOSURE: " +
        owner.area +
        ": " +
        owner.module
    );
  }
}

if (manifest.migration.finalArchitectureImplemented) {
  throw new Error(
    "PSC1KERNEL_ARCH_MIGRATION_STATUS: final architecture is not yet fully migrated"
  );
}

return (
  "PSC1KERNEL_ARCHITECTURE: target=" +
    manifest.target.version +
    "@" +
    manifest.target.gitCommit +
    " root=" +
    manifest.semanticRootModule +
    " closureModules=" +
    seen.size +
    " migration=" +
    manifest.migration.phase +
    " tcbLogical=" +
    (tcb.logicalTCB?.length ?? 0) +
    " tcbAcceleration=" +
    (tcb.accelerationTCB?.length ?? 0) +
    " tcbCapability=" +
    (tcb.capabilityTCB?.length ?? 0)
);

}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
  console.log(auditArchitecture(root));
}
