import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const packageRoot = path.join(root, "packages", "pskernel-core");
const sourceRoot = path.join(packageRoot, "src", "Ps", "KernelCore");
const manifestPath = path.join(packageRoot, "LEAN_4_34_COMPATIBILITY.json");
const requireComplete = process.argv.includes("--require-complete");

function walk(directory) {
  const result = [];
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const target = path.join(directory, entry.name);
    if (entry.isDirectory()) result.push(...walk(target));
    else if (entry.isFile() && entry.name.endsWith(".lean")) result.push(target);
  }
  return result;
}

const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
if (manifest?.target?.version !== "4.34.0") {
  throw new Error("PSC1KERNEL_COMPAT_TARGET_VERSION");
}
if (manifest?.target?.gitCommit !== "293d5d0c0c3f3dded4688b3ccd6a33939ac5102b") {
  throw new Error("PSC1KERNEL_COMPAT_TARGET_COMMIT");
}

const allowed = new Set(manifest.policy.ruleStatusValues);
const ids = new Set();
const source = walk(sourceRoot)
  .sort()
  .map((file) => fs.readFileSync(file, "utf8"))
  .join("\n");

let implemented = 0;
let differential = 0;
const missing = [];

for (const rule of manifest.rules) {
  if (!rule.id || ids.has(rule.id)) {
    throw new Error(`PSC1KERNEL_COMPAT_RULE_ID: ${rule.id ?? "<missing>"}`);
  }
  ids.add(rule.id);
  if (!allowed.has(rule.status)) {
    throw new Error(`PSC1KERNEL_COMPAT_RULE_STATUS: ${rule.id}: ${rule.status}`);
  }
  if (!rule.leanLocator || !rule.pskernelSymbol) {
    throw new Error(`PSC1KERNEL_COMPAT_RULE_LOCATOR: ${rule.id}`);
  }

  const symbolPattern = new RegExp(
    `\\b${rule.pskernelSymbol.replace(/[.*+?^${}()|[\\]\\]/g, "\\$&")}\\b`,
    "u",
  );
  const symbolExists = symbolPattern.test(source);

  if (rule.status === "missing") {
    missing.push(rule);
    if (symbolExists) {
      throw new Error(
        `PSC1KERNEL_COMPAT_STALE_MISSING: ${rule.id}: ${rule.pskernelSymbol}`,
      );
    }
  } else {
    implemented += 1;
    if (rule.status === "implemented-differential") differential += 1;
    if (!symbolExists) {
      throw new Error(
        `PSC1KERNEL_COMPAT_SYMBOL_MISSING: ${rule.id}: ${rule.pskernelSymbol}`,
      );
    }
  }
}

if (requireComplete && missing.length > 0) {
  throw new Error(
    `PSC1KERNEL_COMPAT_INCOMPLETE: ${missing.map((rule) => rule.id).join(",")}`,
  );
}

console.log(
  `PSC1KERNEL_COMPATIBILITY: target=${manifest.target.version}@${manifest.target.gitCommit} rules=${manifest.rules.length} implemented=${implemented} differential=${differential} missing=${missing.length}`,
);
for (const rule of missing) {
  console.log(
    `PSC1KERNEL_COMPATIBILITY_MISSING: ${rule.id} ${rule.area} lean=${rule.leanLocator}`,
  );
}
