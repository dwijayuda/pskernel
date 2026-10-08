import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const packageJson = JSON.parse(
  await readFile(path.join(root, "package.json"), "utf8"),
);
const scripts = packageJson.scripts ?? {};

function assert(condition, message) {
  if (!condition) {
    throw new Error(`PSC2_FIXED_POINT_COMMAND_TEST: ${message}`);
  }
}

function npmRunDependencies(command) {
  const dependencies = [];
  const pattern = /\bnpm\s+run\s+([A-Za-z0-9:_-]+)/gu;
  for (const match of command.matchAll(pattern)) {
    dependencies.push(match[1]);
  }
  return dependencies;
}

function reachableScripts(rootScript) {
  const visited = new Set();
  const stack = [rootScript];
  while (stack.length > 0) {
    const scriptName = stack.pop();
    if (visited.has(scriptName)) continue;
    visited.add(scriptName);
    const command = scripts[scriptName];
    assert(typeof command === "string", `missing script: ${scriptName}`);
    for (const dependency of npmRunDependencies(command)) {
      stack.push(dependency);
    }
  }
  return visited;
}

assert(
  scripts["fixed-point"] ===
    "npm run bootstrap && npm run selfhost && npm run verify:selfhost",
  "fixed-point must remain the canonical bootstrap -> selfhost -> verification pipeline",
);

const reachable = reachableScripts("fixed-point");

for (const required of [
  "bootstrap",
  "bootstrap:lean",
  "bootstrap:check",
  "bootstrap:emit",
  "bootstrap:compiler",
  "selfhost",
  "verify:selfhost",
  "verify:source",
  "verify:compiler",
  "check:workspace",
  "check:source:bootstrap",
  "check:layout",
  "check:bootstrap-closure",
  "check:ir-neutrality",
  "build:lean",
  "build:lake",
  "test:bootstrap",
]) {
  assert(reachable.has(required), `fixed-point does not reach required script: ${required}`);
}

for (const forbidden of [
  "check",
  "check:source:all",
  "check:kernel-core-source",
  "test:kernel-core",
  "test:regression",
  "test:extensions",
  "test:all",
  "test:lean",
  "build:dual",
]) {
  assert(!reachable.has(forbidden), `fixed-point reaches non-bootstrap assurance: ${forbidden}`);
}

const reachableCommands = [...reachable]
  .sort()
  .map((scriptName) => `${scriptName}: ${scripts[scriptName]}`)
  .join("\n");
for (const forbiddenFragment of [
  "psc1_backend_rust",
  "psc1_backend_wasm",
  "psc2_kernel_core",
]) {
  assert(
    !reachableCommands.includes(forbiddenFragment),
    `fixed-point command graph contains extension/kernel command: ${forbiddenFragment}`,
  );
}

assert(
  scripts["verify:source"]?.includes("compare-source-workspaces.mjs"),
  "fixed-point must verify canonical source-workspace parity",
);
assert(
  scripts["verify:compiler"]?.includes("compare-selfhost.mjs"),
  "fixed-point must verify generated compiler parity",
);
assert(
  scripts["selfhost:fixed-point"] === "npm run fixed-point",
  "legacy selfhost:fixed-point must remain a compatibility alias, not a second pipeline",
);

process.stdout.write(
  `PSC2_FIXED_POINT_COMMAND_GRAPH: PASS (${reachable.size} reachable scripts; extensions excluded)\n`,
);
