import { access, readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const registry = JSON.parse(await readFile(path.join(root, "contracts/registry/ARCHITECTURE_REGISTRY.json"), "utf8"));
if (registry.schemaVersion !== 1) throw new Error("PSC_ARCH_REGISTRY_SCHEMA");
if (registry.masterPlan !== "THE_PSCV_COMPILER_REFERENCE_VERSION_5.1.md") throw new Error("PSC_ARCH_REGISTRY_MASTER_PLAN");
const ids = new Set();
const allowed = new Set(["current","frozen","experimental","target","accepted-target","current-host","current-hosted-semantic","retired","historical"]);
for (const entry of registry.entries ?? []) {
  if (!entry?.id || ids.has(entry.id)) throw new Error("PSC_ARCH_REGISTRY_ID");
  ids.add(entry.id);
  if (!allowed.has(entry.status)) throw new Error("PSC_ARCH_REGISTRY_STATUS: " + entry.id);
  if (entry.canonicalPath) await access(path.join(root, entry.canonicalPath));
}
for (const required of ["pscv-architecture/v3","pscv-architecture/v5.1","psc-v5-migration-status/1","pscv-v1","proofscript-kernel-contract/1","psc-verified-ir/1","psc-runtime-semantics/1","psc-provider-security/1","psc-trust-manifest/1","psc-checked-core-capability/1"]) {
  if (!ids.has(required)) throw new Error("PSC_ARCH_REGISTRY_REQUIRED: " + required);
}
process.stdout.write("PSCV_ARCHITECTURE_REGISTRY: PASS (" + ids.size + " identities)\n");
