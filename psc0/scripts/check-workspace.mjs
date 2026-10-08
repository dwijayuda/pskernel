import { access, readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { allowedBootstrapPackageNames, bootstrapPackageViolation } from "./bootstrap-closure-contract.mjs";

const scriptsDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptsDir, "..");
const nonWorkspacePackageDirs = new Set(["pskernel-lean", "pskernel-lean-wasm", "pskernel-core", "backend-js", "backend-wasm", "backend-rust"]);
// These packages are native host providers or optional extensions; they are NOT
// dependencies of the minimal compiler-only npm bootstrap workspace.

async function exists(file) {
  try {
    await access(file);
    return true;
  } catch {
    return false;
  }
}

async function readJson(file) {
  return JSON.parse(await readFile(file, "utf8"));
}

for (const packageName of nonWorkspacePackageDirs) {
  if (!bootstrapPackageViolation(packageName)) {
    throw new Error(`PSC1_NON_WORKSPACE_PACKAGE_NOT_FORBIDDEN: ${packageName}`);
  }
}

const rootPackage = await readJson(path.join(root, "package.json"));
const expectedWorkspaces = [
  ...allowedBootstrapPackageNames.map(name => 'packages/' + name),
  'packages/cli', 'host', 'stdlib',
];
if (JSON.stringify(rootPackage.workspaces) !== JSON.stringify(expectedWorkspaces)) {
  throw new Error('PSC0_WORKSPACE_WHITELIST_DRIFT: only compiler closure, CLI, host and stdlib may be npm workspaces');
}
const packageDirs = expectedWorkspaces.map(relative => path.join(root, relative));

for (const packageDir of packageDirs) {
  const manifestPath = path.join(packageDir, "package.json");
  if (!(await exists(manifestPath))) {
    throw new Error(`PSC1_WORKSPACE_MANIFEST_MISSING: ${path.relative(root, manifestPath)}`);
  }

  const manifest = await readJson(manifestPath);
  const config = manifest.proofscript;
  if (!config) {
    throw new Error(`PSC1_WORKSPACE_PROOFSCRIPT_METADATA: ${manifest.name}`);
  }
  if (!Array.isArray(config.sourceRoots) || config.sourceRoots.length === 0) {
    throw new Error(`PSC1_WORKSPACE_SOURCE_ROOTS: ${manifest.name}`);
  }
  if (!Array.isArray(config.testRoots) || config.testRoots.length === 0) {
    throw new Error(`PSC1_WORKSPACE_TEST_ROOTS: ${manifest.name}`);
  }
  if (config.outDir !== "dist") {
    throw new Error(`PSC1_WORKSPACE_OUT_DIR: ${manifest.name}`);
  }

  for (const sourceRoot of config.sourceRoots) {
    const sourcePath = path.resolve(packageDir, sourceRoot);
    if (!(await exists(sourcePath))) {
      throw new Error(
        `PSC1_WORKSPACE_SOURCE_MISSING: ${manifest.name}:${sourceRoot}`,
      );
    }
  }
}

const psconfig = await readJson(path.join(root, "psconfig.json"));
if (!psconfig.entry || !(await exists(path.join(root, psconfig.entry)))) {
  throw new Error(`PSC1_WORKSPACE_ENTRY_MISSING: ${psconfig.entry ?? "<none>"}`);
}

const binPath = rootPackage.bin?.psc;
if (!binPath || !(await exists(path.join(root, binPath)))) {
  throw new Error("PSC1_WORKSPACE_BIN_MISSING: psc");
}

process.stdout.write(
  `PSC1_WORKSPACE_SHAPE: PASS (${packageDirs.length} workspaces)\n`,
);
