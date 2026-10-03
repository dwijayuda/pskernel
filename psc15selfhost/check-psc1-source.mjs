import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { auditPsc1Source } from "./scripts/psc1-source-profile.mjs";

const scriptPath = fileURLToPath(import.meta.url);
const workspaceRoot = path.dirname(scriptPath);
const allPortable = process.argv.includes("--all-portable");

function readJson(file) {
  return JSON.parse(fs.readFileSync(file, "utf8"));
}

function workspaceDirectories() {
  const directories = [];
  const packagesRoot = path.join(workspaceRoot, "packages");
  if (fs.existsSync(packagesRoot)) {
    for (const entry of fs.readdirSync(packagesRoot, { withFileTypes: true })) {
      if (entry.isDirectory()) {
        directories.push(path.join(packagesRoot, entry.name));
      }
    }
  }
  for (const name of ["host", "stdlib"]) {
    const directory = path.join(workspaceRoot, name);
    if (fs.existsSync(directory)) directories.push(directory);
  }
  return directories;
}

const roots = [];
for (const directory of workspaceDirectories()) {
  const manifestPath = path.join(directory, "package.json");
  if (!fs.existsSync(manifestPath)) continue;
  const manifest = readJson(manifestPath);
  const config = manifest.proofscript;
  if (!config || config.portable === false) continue;
  if (!allPortable && config.bootstrap !== true) continue;
  for (const sourceRoot of config.sourceRoots ?? []) {
    roots.push(path.resolve(directory, sourceRoot));
  }
}

const files = [];

function walk(dir) {
  if (!fs.existsSync(dir)) return;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const file = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      walk(file);
    } else if (entry.isFile() && entry.name.endsWith(".lean")) {
      files.push(file);
    }
  }
}

for (const sourceRoot of roots) walk(sourceRoot);

let failed = false;
for (const file of files) {
  const source = fs.readFileSync(file, "utf8");
  for (const rule of auditPsc1Source(source)) {
    console.error(
      `PSC1_SOURCE_PROFILE: ${path.relative(workspaceRoot, file)}: forbidden ${rule.label}`,
    );
    failed = true;
  }
}

if (files.length === 0) {
  console.error("PSC1_SOURCE_PROFILE: no portable Lean modules found");
  failed = true;
}

if (failed) process.exit(1);

const scope = allPortable ? "all-portable" : "bootstrap";
console.log(
  `PSC1_SOURCE_PROFILE: PASS (${scope}; ${files.length} portable modules across ${roots.length} source roots)`,
);
