import { access, readFile, readdir } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptsDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptsDir, "..");

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

const rootPackage = await readJson(path.join(root, "package.json"));
const expectedWorkspaces = ["packages/*", "host", "stdlib"];
for (const workspace of expectedWorkspaces) {
  if (!rootPackage.workspaces?.includes(workspace)) {
    throw new Error(`PSC1_WORKSPACE_ROOT_MISSING: ${workspace}`);
  }
}

const packageDirs = [];
for (const entry of await readdir(path.join(root, "packages"), { withFileTypes: true })) {
  if (entry.isDirectory()) {
    packageDirs.push(path.join(root, "packages", entry.name));
  }
}
packageDirs.push(path.join(root, "host"));
packageDirs.push(path.join(root, "stdlib"));

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
