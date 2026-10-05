import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const packageRoot = path.join(root, "packages", "pskernel-core");
const compatibilityPath = path.join(packageRoot, "LEAN_4_34_COMPATIBILITY.json");
const conformancePath = path.join(packageRoot, "LEAN_4_34_CONFORMANCE.json");
const requireComplete = process.argv.includes("--require-complete");

const compatibility = JSON.parse(fs.readFileSync(compatibilityPath, "utf8"));
const conformance = JSON.parse(fs.readFileSync(conformancePath, "utf8"));

if (
  compatibility.target.version !== conformance.target.version ||
  compatibility.target.gitCommit !== conformance.target.gitCommit
) {
  throw new Error("PSC1KERNEL_CONFORMANCE_TARGET_MISMATCH");
}

const compatibilityIds = compatibility.rules.map((rule) => rule.id).sort();
const conformanceIds = conformance.rules.map((rule) => rule.id).sort();

if (JSON.stringify(compatibilityIds) !== JSON.stringify(conformanceIds)) {
  const compat = new Set(compatibilityIds);
  const conf = new Set(conformanceIds);
  const missing = compatibilityIds.filter((id) => !conf.has(id));
  const extra = conformanceIds.filter((id) => !compat.has(id));
  throw new Error(
    `PSC1KERNEL_CONFORMANCE_RULE_SET: missing=${missing.join(",")} extra=${extra.join(",")}`,
  );
}

const allowed = new Set(conformance.coverageValues);

function readLeanSources(target) {
  const stat = fs.statSync(target);
  if (stat.isFile()) {
    if (!target.endsWith(".lean")) return [];
    return [fs.readFileSync(target, "utf8")];
  }
  if (!stat.isDirectory()) return [];
  const sources = [];
  for (const entry of fs.readdirSync(target, { withFileTypes: true })) {
    const child = path.join(target, entry.name);
    if (entry.isDirectory()) {
      sources.push(...readLeanSources(child));
    } else if (entry.isFile() && entry.name.endsWith(".lean")) {
      sources.push(fs.readFileSync(child, "utf8"));
    }
  }
  return sources;
}

const configuredTestRoots =
  Array.isArray(conformance.testRoots) && conformance.testRoots.length > 0
    ? conformance.testRoots
    : [conformance.testFile];
const testSource = configuredTestRoots
  .flatMap((target) => readLeanSources(path.join(root, target)))
  .join("\n");

const pending = [];
let directDifferential = 0;
let directInvariant = 0;

for (const entry of conformance.rules) {
  if (!allowed.has(entry.coverage)) {
    throw new Error(
      `PSC1KERNEL_CONFORMANCE_COVERAGE: ${entry.id}: ${entry.coverage}`,
    );
  }

  if (entry.coverage === "pending") {
    pending.push(entry.id);
    if (entry.testSymbol !== null) {
      throw new Error(
        `PSC1KERNEL_CONFORMANCE_PENDING_SYMBOL: ${entry.id}: ${entry.testSymbol}`,
      );
    }
    continue;
  }

  if (!entry.testSymbol) {
    throw new Error(`PSC1KERNEL_CONFORMANCE_TEST_SYMBOL: ${entry.id}`);
  }

  const escaped = entry.testSymbol.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const pattern = new RegExp(`\\bdef\\s+${escaped}\\b`, "u");
  if (!pattern.test(testSource)) {
    throw new Error(
      `PSC1KERNEL_CONFORMANCE_TEST_MISSING: ${entry.id}: ${entry.testSymbol}`,
    );
  }

  if (entry.coverage === "direct-differential") directDifferential += 1;
  if (entry.coverage === "direct-invariant") directInvariant += 1;
}

if (requireComplete && pending.length > 0) {
  throw new Error(
    `PSC1KERNEL_CONFORMANCE_INCOMPLETE: ${pending.join(",")}`,
  );
}

console.log(
  `PSC1KERNEL_CONFORMANCE: target=${conformance.target.version}@${conformance.target.gitCommit} rules=${conformance.rules.length} differential=${directDifferential} invariant=${directInvariant} pending=${pending.length}`,
);
for (const id of pending) {
  console.log(`PSC1KERNEL_CONFORMANCE_PENDING: ${id}`);
}
