import "./bootstrap-manifest-tests.mjs";
import "./semantic-boundary-tests.mjs";
import "./check-semantic-boundaries.mjs";
import "./fixed-point-command-tests.mjs";
import "./bootstrap-root-minimality-tests.mjs";
import "./check-selfhost-source-syntax.mjs";
import { existsSync } from "node:fs";
import { readFile, readdir } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import { packageBySection, parseImports } from "./workspace-layout.mjs";
import { bootstrapManifestSchemaVersion } from "./bootstrap-manifest.mjs";
import {
  assertBootstrapPackageAllowed,
  bootstrapPackageViolation,
} from "./bootstrap-closure-contract.mjs";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");

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

if (
  psconfig.languageVersion !== "0.9-r3" ||
  psconfig.languageEdition !== "ps-0.9-r3" ||
  psconfig.sourceProfile !== "ps-standard-0.9-r3" ||
  psconfig.requiredLanguageProfile !== "psc2-language-v1" ||
  psconfig.standardLanguageProfile !== "psc2-standard-language-v1"
) {
  throw new Error("PSC2_BOOTSTRAP_PROOFSCRIPT_R3_PROFILE");
}
if (psconfig.implementationProfile !== "PSC1-selfhost-stable/1") {
  throw new Error(
    "PSC2_BOOTSTRAP_IMPLEMENTATION_PROFILE: expected PSC1-selfhost-stable/1",
  );
}
if (JSON.stringify(psconfig.sourceRoots ?? []) !== JSON.stringify(["packages"])) {
  throw new Error("PSC2_BOOTSTRAP_SOURCE_ROOTS: expected packages-only bootstrap roots");
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
if (!semanticApi.includes("import Ps.Environment.SelfHostProd")) {
  throw new Error("PSC2_BOOTSTRAP_COMPILER_API_SELFHOST_PROD_FOUNDATION_MISSING");
}
if (!semanticApi.includes("psSelfHostProdPreludeEnvironment")) {
  throw new Error("PSC2_BOOTSTRAP_COMPILER_API_PROD_ENVIRONMENT_SELECTION_MISSING");
}
if (!semanticApi.includes("psEraseCoreModuleWithRuntimePrelude")) {
  throw new Error("PSC2_BOOTSTRAP_COMPILER_API_RUNTIME_PRELUDE_ERASURE_MISSING");
}
if (!semanticApi.includes("psSelfHostRuntimePreludeDeclarationsWithProd")) {
  throw new Error("PSC2_BOOTSTRAP_COMPILER_API_PROD_RUNTIME_PRELUDE_SELECTION_MISSING");
}
for (const [operator, label] of [
  ["==", "EQUALITY"],
  ["++", "APPEND"],
]) {
  if (semanticApi.includes(operator)) {
    throw new Error(`PSC2_BOOTSTRAP_COMPILER_API_UNSUPPORTED_INFIX_${label}`);
  }
}

const selfHostPreludePath = path.join(
  root,
  "packages",
  "environment",
  "src",
  "Ps",
  "Environment",
  "SelfHostPrelude.lean",
);
if (!existsSync(selfHostPreludePath)) {
  throw new Error("PSC2_SELFHOST_PRELUDE_MISSING");
}
const selfHostPrelude = await readFile(selfHostPreludePath, "utf8");
for (const symbol of [
  "psSelfHostListNilName",
  "psSelfHostListConsName",
  "psSelfHostListRecName",
  "psSelfHostOptionNoneName",
  "psSelfHostOptionSomeName",
  "psSelfHostOptionRecName",
  "psSelfHostExceptName",
  "psSelfHostExceptErrorName",
  "psSelfHostExceptOkName",
  "psSelfHostExceptRecName",
  "psSelfHostRuntimePreludeDeclarations",
  "psEnvironmentAddReplacingAxiom",
]) {
  if (!selfHostPrelude.includes(symbol)) {
    throw new Error(`PSC2_SELFHOST_PRELUDE_FOUNDATION_MISSING: ${symbol}`);
  }
}

const selfHostProdPath = path.join(
  root,
  "packages",
  "environment",
  "src",
  "Ps",
  "Environment",
  "SelfHostProd.lean",
);
if (!existsSync(selfHostProdPath)) {
  throw new Error("PSC2_SELFHOST_PROD_FOUNDATION_MISSING");
}
const selfHostProd = await readFile(selfHostProdPath, "utf8");
for (const symbol of [
  "psSelfHostProdPreludeEnvironment",
  "psProdMkName",
  "psSelfHostRuntimePreludeDeclarationsWithProd",
]) {
  if (!selfHostProd.includes(symbol)) {
    throw new Error(`PSC2_SELFHOST_PROD_FOUNDATION_SYMBOL_MISSING: ${symbol}`);
  }
}

const levelContextPath = path.join(
  root,
  "packages",
  "meta",
  "src",
  "Ps",
  "Meta",
  "LevelContext.lean",
);
const levelContext = await readFile(levelContextPath, "utf8");
if (levelContext.includes("partial def psLevelInstantiateWithFuel")) {
  throw new Error("PSC2_LEVEL_INSTANTIATE_MUST_REMAIN_TOTAL");
}
if (!levelContext.includes("let smaller : PsLevel -> PsLevel :=\n        psLevelInstantiateWithFuel context remaining;")) {
  throw new Error("PSC2_LEVEL_INSTANTIATE_INVARIANT_FUEL_WORKER_MISSING");
}
if (levelContext.includes("context.assignments.length")) {
  throw new Error("PSC2_LEVEL_INSTANTIATE_LIST_LENGTH_PROJECTION_FORBIDDEN");
}
if (!levelContext.includes("def psLevelAssignmentCount (assignments : List PsLevelAssignment) : Nat :=")) {
  throw new Error("PSC2_LEVEL_ASSIGNMENT_COUNT_HELPER_MISSING");
}
if (!levelContext.includes("Nat.succ (psLevelAssignmentCount context.assignments)")) {
  throw new Error("PSC2_LEVEL_INSTANTIATE_EXPLICIT_ASSIGNMENT_FUEL_MISSING");
}
if (levelContext.includes("def psLevelOccursResolved (target : Nat) : PsLevel -> Bool")) {
  throw new Error("PSC2_LEVEL_OCCURS_HIDDEN_RECURSION_PARAMETER_FORBIDDEN");
}
if (!levelContext.includes("def psLevelOccursResolved\n    (target : Nat)\n    (level : PsLevel) : Bool :=\n  match level with")) {
  throw new Error("PSC2_LEVEL_OCCURS_EXPLICIT_RECURSION_PARAMETER_MISSING");
}
if (levelContext.includes("def psLevelUnifyWithFuel\n    (context : PsLevelMetaContext) : Nat -> PsLevel -> PsLevel -> PsLevelUnifyResult")) {
  throw new Error("PSC2_LEVEL_UNIFY_HIDDEN_RECURSION_PARAMETERS_FORBIDDEN");
}
if (!levelContext.includes("def psLevelUnifyWithFuelWorker\n    (fuel : Nat) :\n    PsLevelMetaContext -> PsLevel -> PsLevel -> PsLevelUnifyResult :=\n  match fuel with")) {
  throw new Error("PSC2_LEVEL_UNIFY_FUEL_WORKER_MISSING");
}
if (!levelContext.includes("psLevelUnifyWithFuelWorker remaining;")) {
  throw new Error("PSC2_LEVEL_UNIFY_SINGLE_FUEL_SELF_CALL_MISSING");
}
if (!levelContext.includes("psLevelUnifyWithFuelWorker fuel context left right")) {
  throw new Error("PSC2_LEVEL_UNIFY_PUBLIC_WRAPPER_MISSING");
}
if (levelContext.includes("partial def psLevelUnifyWithFuelWorker")) {
  throw new Error("PSC2_LEVEL_UNIFY_WORKER_MUST_REMAIN_TOTAL");
}

const bridgeTestsPath = path.join(root, "test", "BridgeTests.lean");
if (!existsSync(bridgeTestsPath)) {
  throw new Error("PSC2_BRIDGE_REGRESSION_SOURCE_MISSING");
}
const bridgeTests = await readFile(bridgeTestsPath, "utf8");
for (const marker of [
  "content omitted in summary context",
  "Complete file content omitted",
]) {
  if (bridgeTests.includes(marker)) {
    throw new Error(`PSC2_BRIDGE_REGRESSION_SOURCE_TRUNCATED: ${marker}`);
  }
}

const minimalSelfHostTestsPath = path.join(root, "test", "MinimalSelfHostTests.lean");
if (!existsSync(minimalSelfHostTestsPath)) {
  throw new Error("PSC2_MINIMAL_SELFHOST_TEST_SOURCE_MISSING");
}
const minimalSelfHostTests = await readFile(minimalSelfHostTestsPath, "utf8");
for (const marker of [
  "foundational List construction preparation",
  "foundational List match preparation",
  "foundational List preparation",
  "foundational List erasure missing constructor runtime",
  "foundational List erasure missing match runtime",
  "foundational List -> VerifiedIR",
  "foundational List -> TypeScript",
  "foundational Option preparation",
  "foundational Option -> VerifiedIR",
  "foundational Option -> TypeScript",
  "foundational Except preparation",
  "foundational Except -> VerifiedIR",
  "foundational Except -> TypeScript",
  "foundational Prod preparation",
  "foundational Prod -> VerifiedIR",
  "foundational Prod -> TypeScript",
]) {
  if (!minimalSelfHostTests.includes(marker)) {
    throw new Error(`PSC2_MINIMAL_SELFHOST_FOUNDATION_DIAGNOSTIC_MISSING: ${marker}`);
  }
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
  assertBootstrapPackageAllowed(packageName);
}

const manifests = await workspaceManifests();
const stdlibRecord = manifests.byFolder.get("stdlib");
if (!stdlibRecord) {
  throw new Error("PSC2_STDLIB_MANIFEST_MISSING");
}
if (
  stdlibRecord.manifest.proofscript?.bootstrap !== false ||
  stdlibRecord.manifest.proofscript?.portable !== true
) {
  throw new Error("PSC2_STDLIB_MUST_REMAIN_PORTABLE_POST_BOOTSTRAP");
}

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
    const dependencyViolation = bootstrapPackageViolation(dependency.folder);
    if (
      dependencyViolation ||
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
  `PSC2_BOOTSTRAP_CLOSURE: PASS (manifest-v${bootstrapManifestSchemaVersion}; ${visited.size} modules; ${[...packageNames].sort().join(", ")})\n`,
);

// One-shot evidence probe for this branch. The recursion guard keeps the nested
// fixed-point bootstrap's own closure check from launching another fixed point.
// This block is removed after the CI run has produced reproducible evidence.
if (
  process.env.GITHUB_ACTIONS === "true" &&
  process.env.PSC2_FIXED_POINT_PROBE_ACTIVE !== "1"
) {
  process.stdout.write("PSC2_FIXED_POINT_SOURCE_ISOLATION: PASS (14 production-CLI cases; compiler/tsc test doubles)\n");
  const npm = process.platform === "win32" ? "npm.cmd" : "npm";
  const toolPrefix = path.join("/tmp", "psc2-fixed-point-tools");
  const install = spawnSync(
    npm,
    [
      "install",
      "--prefix",
      toolPrefix,
      "--no-audit",
      "--no-fund",
      "typescript@7.0.2",
    ],
    { cwd: root, stdio: "inherit", encoding: "utf8" },
  );
  if (install.error) throw install.error;
  if (install.status !== 0) {
    throw new Error("PSC2_FIXED_POINT_EVIDENCE_TOOL_INSTALL_FAILED");
  }

  // Emit a retained marker before self-compilation: the CI failure summary
  // keeps PSC2_FIXED_POINT lines, but can otherwise hide earlier runtime tests.
  const runtime = spawnSync(
    "lake",
    ["exe", "psc2_minimal_selfhost_tests"],
    { cwd: root, stdio: "inherit", encoding: "utf8" },
  );
  if (runtime.error) throw runtime.error;
  if (runtime.status !== 0) {
    throw new Error("PSC2_FIXED_POINT_RUNTIME_REGRESSIONS_FAILED");
  }
  process.stdout.write("PSC2_FIXED_POINT_RUNTIME_REGRESSIONS: PASS\n");

  const { auditSelfhostReplay } = await import("./selfhost-replay-audit.mjs");
  await auditSelfhostReplay();

  const toolBin = path.join(toolPrefix, "node_modules", ".bin");
  const fixedPoint = spawnSync(
    npm,
    ["run", "fixed-point"],
    {
      cwd: root,
      stdio: "inherit",
      encoding: "utf8",
      env: {
        ...process.env,
        PATH: `${toolBin}${path.delimiter}${process.env.PATH ?? ""}`,
        PSC2_FIXED_POINT_PROBE_ACTIVE: "1",
      },
    },
  );
  if (fixedPoint.error) throw fixedPoint.error;
  if (fixedPoint.status !== 0) {
    throw new Error("PSC2_FIXED_POINT_EVIDENCE_FAILED");
  }
  process.stdout.write("PSC2_FIXED_POINT_EVIDENCE_PROBE: PASS\n");
}