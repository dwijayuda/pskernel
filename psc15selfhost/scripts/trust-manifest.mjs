import { access, readFile, readdir } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { readCheckedBuildHostSources } from './checked-build-evidence.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const trust = JSON.parse(await readFile(path.join(root, "TRUST_MANIFEST.json"), "utf8"));
const execution = JSON.parse(await readFile(path.join(root, "contracts/compiler/COMPILER_EXECUTION_POLICY_V1.json"), "utf8"));
if (trust.implementationProfile !== execution.implementationProfile ||
    trust.executionPolicy !== "contracts/compiler/COMPILER_EXECUTION_POLICY_V1.json" ||
    trust.selfHostProfilesRole !== "historical-optional-checks-not-active-implementation-constraints")
  throw new Error("PSC_TRUST_EXECUTION_POLICY_DRIFT");
const selfHost = JSON.parse(await readFile(path.join(root, "selfhost-profile.json"), "utf8"));
if (trust.schemaVersion !== 1 || trust.contract !== "psc-trust-manifest/1") throw new Error("PSC_TRUST_MANIFEST_SCHEMA");
if (trust.masterPlan !== "THE_PSCV_COMPILER_REFERENCE_VERSION_5.1.md") throw new Error("PSC_TRUST_MANIFEST_MASTER_PLAN");
await access(path.join(root, trust.semanticBootstrapRoot));
for (const relative of [trust.checkedAuthority.hostBoundary, trust.checkedAuthority.checkedBuildBoundary]) await access(path.join(root, relative));
const expected = [...trust.bootstrapPackageClosure].sort();
const profile = [...selfHost.allowedPackages].sort();
if (JSON.stringify(expected) !== JSON.stringify(profile)) throw new Error("PSC_TRUST_BOOTSTRAP_PROFILE_DRIFT");

const manifests = new Map();
for (const entry of await readdir(path.join(root, "packages"), { withFileTypes: true })) {
  if (!entry.isDirectory()) continue;
  try {
    const manifest = JSON.parse(await readFile(path.join(root, "packages", entry.name, "package.json"), "utf8"));
    manifests.set(manifest.name, { folder: entry.name, manifest });
  } catch {}
}
const start = manifests.get("@proofscript/psc2-bootstrap");
if (!start) throw new Error("PSC_TRUST_BOOTSTRAP_PACKAGE");
const pending = [start];
const seenFolders = new Set();
while (pending.length) {
  const item = pending.pop();
  if (seenFolders.has(item.folder)) continue;
  seenFolders.add(item.folder);
  for (const dep of Object.keys(item.manifest.dependencies ?? {})) {
    const next = manifests.get(dep);
    if (next) pending.push(next);
  }
}
const allowed = new Set(trust.bootstrapPackageClosure);
for (const folder of seenFolders) {
  if (!allowed.has(folder)) throw new Error("PSC_TRUST_BOOTSTRAP_CLOSURE_EXPANDED: " + folder);
}
const hostSources = await readCheckedBuildHostSources();
const declaration = trust.hostSourceClosure;
if (declaration?.coverage !== 'static-relative-esm-imports/1' || declaration.entry !== 'scripts/checked-build.mjs' ||
    JSON.stringify(hostSources.map(item => item.path)) !== JSON.stringify(declaration.declared)) {
  throw new Error('PSC_TRUST_HOST_CLOSURE_UNDECLARED_OR_STALE');
}
const dynamicOwners = hostSources.filter(item => /\bimport\s*\(/u.test(item.bytes.toString('utf8'))).map(item => item.path);
if (JSON.stringify(dynamicOwners) !== JSON.stringify(declaration.dynamicImportOwners)) throw new Error('PSC_TRUST_DYNAMIC_IMPORT_OWNER_DRIFT');
process.stdout.write('PSCV_TRUST_HOST_CLOSURE: PASS (' + hostSources.length + ' declared static host modules)\n');
process.stdout.write("PSCV_TRUST_MANIFEST: PASS (" + seenFolders.size + " reachable bootstrap packages)\n");
