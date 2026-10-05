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

assert(
  scripts["fixed-point:bootstrap-js"] ===
    "npm run check:fast && npm run selfhost && npm run verify:selfhost",
  "fixed-point:bootstrap-js must remain an explicit generated-bootstrap regression gate",
);
assert(
  scripts["fixed-point:js"] ===
    "npm run check:fast && node scripts/fixed-point-current.mjs",
  "fixed-point:js must build and self-host current source rather than stale bootstrap artifacts",
);
const currentFixedPoint = await readFile(
  path.join(root, "scripts", "fixed-point-current.mjs"),
  "utf8",
);
for (const marker of [
  "scripts/emit-project-with-generated.mjs",
  "scripts/compile-with-generated.mjs",
  "scripts/selfhost-generation.mjs",
  "scripts/compare-source-workspaces.mjs",
  "scripts/compare-generated-source-workspaces.mjs",
  "scripts/compare-compiler-artifacts.mjs",
  "mode=reused-proven-bootstrap",
  "mode=recompiled-current-source",
]) {
  assert(
    currentFixedPoint.includes(marker),
    `current-source fixed point is missing stage: ${marker}`,
  );
}

assert(
  scripts["dev:selfhost"] === "node scripts/selfhost-dev.mjs",
  "resident selfhost developer loop must remain available",
);
assert(
  scripts["dev:selfhost:check"] ===
    "npm run check:fast && node scripts/selfhost-dev.mjs --check",
  "resident fixed-point check must include the fast edit gate",
);
assert(
  scripts["dev:selfhost:cold-check"] ===
    "npm run check:fast && node scripts/selfhost-dev.mjs --cold-check",
  "cold resident fixed-point must remain an explicit oracle path",
);
const residentDev = await readFile(
  path.join(root, "scripts", "selfhost-dev.mjs"),
  "utf8",
);
for (const marker of [
  "PSC2_DEV_BUILD: PASS",
  "PSC2_DEV_FIXED_POINT: PASS",
  "PSC2_DEV_ORACLE: PASS",
  "compare-generated-source-workspaces.mjs",
  "cold-check",
]) {
  assert(
    residentDev.includes(marker),
    `resident selfhost workflow is missing invariant: ${marker}`,
  );
}
const residentSession = await readFile(
  path.join(root, "scripts", "generated-compiler-session.mjs"),
  "utf8",
);
for (const marker of [
  "parseCache",
  "snapshotCache",
  "semanticStateCache",
  "preparedCache",
  "backendCache",
  "options.cold === true",
  "semanticValueFingerprint",
  "psc2-resident-semantic-prefix-v2",
]) {
  assert(
    residentSession.includes(marker),
    `resident compiler session is missing cache invariant: ${marker}`,
  );
}
const cacheUtils = await readFile(
  path.join(root, "scripts", "cache-utils.mjs"),
  "utf8",
);
assert(
  cacheUtils.includes('process.env.PSC_NO_CACHE !== "1"'),
  "content caches must retain an explicit cold bypass",
);
const cachedTsc = await readFile(
  path.join(root, "scripts", "compile-typescript-cached.mjs"),
  "utf8",
);
assert(
  cachedTsc.includes("toolchainSha256: pinned.sha256"),
  "TypeScript artifact cache must be keyed by exact toolchain bytes",
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
  "check:selfhost-profile",
  "check:selfhost-contract",
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
