import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { maskLeanNonCode } from "./psc1-source-profile.mjs";

export function auditArchitecture(root) {
const packageRoot = path.join(root, "packages", "pskernel-core");
const sourceRoot = path.join(packageRoot, "src", "Ps", "KernelCore");
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
const matchesModule = (moduleName, selector) =>
  selector.endsWith(".") ? moduleName.startsWith(selector) : moduleName === selector;

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
    for (const fence of manifest.importFences ?? []) {
      if (fence.from.some((selector) => matchesModule(moduleName, selector)) &&
          fence.forbidden.some((selector) => matchesModule(imported, selector))) {
        throw new Error("PSC1KERNEL_ARCH_IMPORT_FENCE: " + moduleName + ": " + imported);
      }
    }
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
      const target = path.join(sourceRoot, entry.path.replace(/^src\/Ps\/KernelCore\//, ""));
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
if (manifest.migration.compatibilityShimsRetired && registeredShims.size > 0) {
  throw new Error("PSC1KERNEL_ARCH_RETIRED_SHIM_REGISTERED");
}
if (manifest.lakeLibrary) {
  const lake = maskLeanNonCode(fs.readFileSync(path.join(root, "lakefile.lean"), "utf8"));
  const blocks = [...lake.matchAll(/^lean_lib\s+(\w+)\s+where\b([\s\S]*?)(?=^\S|(?![\s\S]))/gmu)];
  const block = blocks.find((match) => match[1] === manifest.lakeLibrary);
  if (!block) throw new Error("PSC1KERNEL_ARCH_LAKE_LIBRARY_MISSING");
  const modules = [...block[2].matchAll(/`([A-Za-z_][A-Za-z0-9_.]*)/gu)].map((match) => match[1]);
  const registered = new Set(modules);
  if (registered.size !== modules.length) throw new Error("PSC1KERNEL_ARCH_LAKE_DUPLICATE_MODULE");
  for (const moduleName of registered) {
    if (moduleName.startsWith(prefix) && !fs.existsSync(modulePath(moduleName))) {
      throw new Error("PSC1KERNEL_ARCH_LAKE_STALE_MODULE: " + moduleName);
    }
  }
  for (const moduleName of [...seen, ...registeredShims]) {
    if (!registered.has(moduleName)) {
      throw new Error("PSC1KERNEL_ARCH_LAKE_MODULE_MISSING: " + moduleName);
    }
  }
}
const ownedShims = new Set();
for (const owner of manifest.canonicalOwners ?? []) {
  if (ownerAreas.has(owner.area) || ownerModules.has(owner.module)) {
    throw new Error("PSC1KERNEL_ARCH_DUPLICATE_OWNER: " + owner.area);
  }
  ownerAreas.add(owner.area);
  ownerModules.add(owner.module);
  for (const shim of [...(owner.legacyShim ? [owner.legacyShim] : []), ...(owner.legacyShims ?? [])]) {
    if (!registeredShims.has(shim)) {
      throw new Error("PSC1KERNEL_ARCH_UNREGISTERED_SHIM: " + shim);
    }
    if (ownedShims.has(shim)) {
      throw new Error("PSC1KERNEL_ARCH_DUPLICATE_SHIM_OWNER: " + shim);
    }
    ownedShims.add(shim);
    const shimSource = maskLeanNonCode(fs.readFileSync(modulePath(shim), "utf8")).trim();
    if (shimSource !== "import " + owner.module) {
      throw new Error("PSC1KERNEL_ARCH_NON_FORWARDING_SHIM: " + shim);
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

for (const shim of registeredShims) {
  if (!ownedShims.has(shim)) {
    throw new Error("PSC1KERNEL_ARCH_SHIM_OWNER_MISSING: " + shim);
  }
}

if (manifest.recursiveWiring) {
  const wiring = manifest.recursiveWiring;
  if (!ownerModules.has(wiring.module)) {
    throw new Error("PSC1KERNEL_ARCH_WIRING_OWNER_MISSING: " + wiring.module);
  }
  const definitions = new Map(wiring.symbols.map((symbol) => [symbol, []]));
  function inspectDefinitions(directory) {
    for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
      const file = path.join(directory, entry.name);
      if (entry.isDirectory()) inspectDefinitions(file);
      else if (entry.isFile() && entry.name.endsWith(".lean")) {
        const source = maskLeanNonCode(fs.readFileSync(file, "utf8"));
        for (const match of source.matchAll(/^\s*(?:(?:private|protected|noncomputable|partial)\s+)*def\s+(\w+)\b/gmu)) {
          definitions.get(match[1])?.push(file);
        }
      }
    }
  }
  inspectDefinitions(sourceRoot);
  for (const [symbol, files] of definitions) {
    if (files.length !== 1 || files[0] !== modulePath(wiring.module)) {
      throw new Error("PSC1KERNEL_ARCH_WIRING_SYMBOL_OWNER: " + symbol);
    }
  }
}

const sourceFiles = [];
function collectSources(directory) {
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const file = path.join(directory, entry.name);
    if (entry.isDirectory()) collectSources(file);
    else if (entry.isFile() && entry.name.endsWith(".lean")) sourceFiles.push(file);
  }
}
collectSources(sourceRoot);
const symbolOwners = new Map();
const literalErrors = new Set();
for (const file of sourceFiles) {
  const moduleName = prefix + path.relative(sourceRoot, file).replaceAll(path.sep, ".").slice(0, -5);
  const raw = fs.readFileSync(file, "utf8");
  const code = maskLeanNonCode(raw);
  for (const match of code.matchAll(/^\s*(?:(?:private|protected|noncomputable|partial)\s+)*(?:def|structure|inductive)\s+(\w+)\b/gmu)) {
    const owners = symbolOwners.get(match[1]) ?? [];
    owners.push(moduleName);
    symbolOwners.set(match[1], owners);
  }
  for (const match of raw.matchAll(/\bExcept\.error\s+("(?:[^"\\]|\\.)*")/gu)) {
    if (code.slice(match.index, match.index + 12) === "Except.error") literalErrors.add(JSON.parse(match[1]));
  }
}

if (manifest.ruleInventory) {
  const inventory = JSON.parse(fs.readFileSync(path.join(packageRoot, manifest.ruleInventory), "utf8"));
  assertTarget("rule inventory", inventory.target);
  const parentIds = new Set(compatibility.rules.map((rule) => rule.id));
  const ruleIds = new Set();
  // Evidence must be both imported and reachable from the foundation main.
  const testDefinitions = new Map();
  const testModules = new Set();
  function readTests(moduleName) {
    if (testModules.has(moduleName)) return;
    testModules.add(moduleName);
    const testFile = path.join(root, "test", moduleName.replaceAll(".", path.sep) + ".lean");
    if (!fs.existsSync(testFile)) return;
    const code = maskLeanNonCode(fs.readFileSync(testFile, "utf8"));
    for (const imported of importsOf(code)) readTests(imported);
    const definitions = [...code.matchAll(/^\s*(?:private\s+)?def\s+(\w+)\b/gmu)];
    for (let i = 0; i < definitions.length; i++) {
      const name = definitions[i][1];
      if (testDefinitions.has(name)) throw new Error("PSC1KERNEL_ARCH_DUPLICATE_TEST_SYMBOL: " + name);
      testDefinitions.set(name, { file: testFile, body: code.slice(definitions[i].index, definitions[i + 1]?.index ?? code.length) });
    }
  }
  readTests("PsKernelCoreFoundationTests");
  const reachable = new Set();
  const pending = ["main"];
  while (pending.length) {
    const name = pending.pop();
    if (reachable.has(name) || !testDefinitions.has(name)) continue;
    reachable.add(name);
    for (const token of testDefinitions.get(name).body.matchAll(/\b[A-Za-z_][A-Za-z0-9_]*\b/gu)) {
      if (testDefinitions.has(token[0])) pending.push(token[0]);
    }
  }
  for (const rule of inventory.rules) {
    if (ruleIds.has(rule.id)) throw new Error("PSC1KERNEL_ARCH_DUPLICATE_RULE: " + rule.id);
    ruleIds.add(rule.id);
    if (!parentIds.has(rule.parentId)) throw new Error("PSC1KERNEL_ARCH_RULE_PARENT: " + rule.id);
    if (!seen.has(rule.ownerModule) || !ownerModules.has(rule.ownerModule)) throw new Error("PSC1KERNEL_ARCH_RULE_OWNER: " + rule.id);
    if (!rule.implementationSymbols?.length || !rule.evidence?.length) throw new Error("PSC1KERNEL_ARCH_RULE_INCOMPLETE: " + rule.id);
    for (const symbol of rule.implementationSymbols) {
      const owners = symbolOwners.get(symbol) ?? [];
      if (owners.length !== 1 || owners[0] !== rule.ownerModule) throw new Error("PSC1KERNEL_ARCH_RULE_SYMBOL_OWNER: " + rule.id + ": " + symbol);
    }
    for (const evidence of rule.evidence) {
      const definition = testDefinitions.get(evidence.testSymbol);
      if (!definition || definition.file !== path.join(root, evidence.testFile) || !reachable.has(evidence.testSymbol)) {
        throw new Error("PSC1KERNEL_ARCH_RULE_EVIDENCE: " + rule.id + ": " + evidence.testSymbol);
      }
      if (!["direct-differential", "direct-invariant"].includes(evidence.coverage)) throw new Error("PSC1KERNEL_ARCH_RULE_COVERAGE: " + rule.id);
    }
  }
  for (const rule of compatibility.rules) {
    const mapped = inventory.rules.find((entry) => entry.id === rule.id);
    if (!mapped || mapped.parentId !== rule.id || !mapped.implementationSymbols.includes(rule.pskernelSymbol)) {
      throw new Error("PSC1KERNEL_ARCH_RULE_COMPATIBILITY: " + rule.id);
    }
  }
}

if (manifest.diagnosticInventory) {
  const inventory = JSON.parse(fs.readFileSync(path.join(packageRoot, manifest.diagnosticInventory), "utf8"));
  const messages = new Set();
  for (const diagnostic of inventory.diagnostics) {
    if (messages.has(diagnostic.message) || !literalErrors.has(diagnostic.message)) throw new Error("PSC1KERNEL_ARCH_DIAGNOSTIC_STALE: " + diagnostic.message);
    messages.add(diagnostic.message);
    if (!["rejectedInvalid", "declinedUnsupported", "resourceExhausted", "internalError"].includes(diagnostic.category)) throw new Error("PSC1KERNEL_ARCH_DIAGNOSTIC_CATEGORY");
  }
  if (inventory.unknownDiagnostic !== "internalError" || messages.size !== literalErrors.size) throw new Error("PSC1KERNEL_ARCH_DIAGNOSTIC_INCOMPLETE");
}

if (manifest.migration.finalArchitectureImplemented) {
  if (!manifest.ruleInventory || !manifest.diagnosticInventory || !manifest.lakeLibrary) throw new Error("PSC1KERNEL_ARCH_COMPLETION_EVIDENCE_MISSING");
  const required = ["Core.Name", "Core.Level", "Core.Expr", "Core.Declaration", "Core.Substitution.Abstract", "Environment.Semantic", "Environment.Environment", "Environment.Lookup", "Environment.Operations", "Checker.Ops", "Checker.Knot", "Checker.Session", "Checker.ResourcePolicy", "Runtime.Acceleration.Cache", "Runtime.Acceleration.EnvironmentIndex", "Runtime.Capability.Types", "Runtime.Capability.Lean434NativeReduction", "Admission.Declaration.Admission", "Admission.Quot.Admission", "Admission.Inductive.Ordinary.Admission", "Admission.Inductive.Mutual.Admission", "Admission.Inductive.Nested.Admission", "API.Outcome", "API.KernelContractV1", "API.Kernel", "API.Session", "API.Provider"];
  for (const suffix of required) if (!seen.has(prefix + suffix)) throw new Error("PSC1KERNEL_ARCH_REQUIRED_OWNER: " + suffix);
  for (const file of sourceFiles) {
    const suffix = path.relative(sourceRoot, file).replaceAll(path.sep, ".").slice(0, -5);
    const moduleName = prefix + suffix;
    if (registeredShims.has(moduleName)) continue;
    const sourcePath = suffix.replaceAll(".", "/");
    const inTargetLayer = [...layerSet].some((layer) => sourcePath === layer || sourcePath.startsWith(layer + "/"));
    if (!seen.has(moduleName) || !ownerModules.has(moduleName) || !inTargetLayer) {
      throw new Error("PSC1KERNEL_ARCH_UNOWNED_SOURCE: " + moduleName);
    }
  }
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
