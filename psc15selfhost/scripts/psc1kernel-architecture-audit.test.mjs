import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { auditArchitecture } from "./psc1kernel-architecture-audit.mjs";

function fixture(t) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "pskernel-architecture-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const packageRoot = path.join(root, "packages/pskernel-selfhost");
  const sourceRoot = path.join(packageRoot, "src/Ps/KernelSelfHost");
  fs.mkdirSync(sourceRoot, { recursive: true });
  const prefix = "Ps.KernelSelfHost.";
  const target = { version: "4.34.0", gitCommit: "pinned-test-target" };
  const manifest = {
    target,
    semanticRootModule: prefix + "SelfHost",
    semanticRootPath: "packages/pskernel-selfhost/src/Ps/KernelSelfHost/SelfHost.lean",
    semanticModulePrefix: prefix,
    migration: {
      finalArchitectureAdopted: true,
      finalArchitectureImplemented: false,
      migrationShims: [prefix + "CheckerState"],
    },
    forbiddenSemanticImportPrefixes: ["PSC1Kernel.", prefix + "Compat.", "KernelSelfHost."],
    currentRoleFiles: [],
    semanticRoles: [],
    trustStatuses: [],
    targetLayers: ["Checker"],
    canonicalOwners: [{ area: "checker-state", module: prefix + "Checker.State", legacyShim: prefix + "CheckerState" }],
  };
  const json = (name, value) => fs.writeFileSync(path.join(packageRoot, name), JSON.stringify(value));
  const lean = (name, source) => {
    const file = path.join(sourceRoot, name + ".lean");
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.writeFileSync(file, source);
  };
  json("PSKERNEL_ARCHITECTURE.json", manifest);
  json("LEAN_4_34_COMPATIBILITY.json", { target });
  json("LEAN_4_34_CONFORMANCE.json", { target });
  json("PSKERNEL_TCB.json", { target, productionSemanticRoot: prefix + "SelfHost" });
  lean("SelfHost", "import Ps.KernelSelfHost.Checker.State\n");
  lean("Checker/State", "def testState : Bool := true\n");
  lean("CheckerState", "import Ps.KernelSelfHost.Checker.State\n/- Forwarding only. -/\n");
  return { root, lean, json, manifest };
}

test("comments and strings do not create imports; trailing comments preserve imports", (t) => {
  const f = fixture(t);
  f.lean("SelfHost", `/- Outer /- nested -/ comment
import PSC1Kernel.Fake
-/
import Ps.KernelSelfHost.Checker.State -- owner
def note : String := "import PSC1Kernel.Fake"
`);
  assert.match(auditArchitecture(f.root), /closureModules=2/);
});

for (const source of [
  "import PSC1Kernel.Hidden -- trailing comment\n",
  "import Ps.KernelSelfHost.Checker.State PSC1Kernel.Hidden\n",
  "  public import PSC1Kernel.Hidden /- block comment -/\n",
]) {
  test("reject hidden reference import: " + source.trim(), (t) => {
    const f = fixture(t);
    f.lean("SelfHost", source);
    assert.throws(() => auditArchitecture(f.root), /ARCH_FORBIDDEN_IMPORT/);
  });
}

test("reject host imports outside the semantic package", (t) => {
  const f = fixture(t);
  f.lean("Checker/State", "import Lean\n");
  assert.throws(() => auditArchitecture(f.root), /ARCH_EXTERNAL_IMPORT/);
});

test("reject an import whose syntax cannot be audited", (t) => {
  const f = fixture(t);
  f.lean("SelfHost", "import\nPs.KernelSelfHost.Checker.State\n");
  assert.throws(() => auditArchitecture(f.root), /ARCH_IMPORT_SYNTAX/);
});

test("reject a transitive migration shim in the semantic closure", (t) => {
  const f = fixture(t);
  f.lean("Checker/State", "import Ps.KernelSelfHost.CheckerState\n");
  assert.throws(() => auditArchitecture(f.root), /ARCH_SHIM_IN_SEMANTIC_ROOT/);
});

test("reject declarations added to a forwarding shim", (t) => {
  const f = fixture(t);
  f.lean("CheckerState", "import Ps.KernelSelfHost.Checker.State\ndef secondState : Bool := false\n");
  assert.throws(() => auditArchitecture(f.root), /ARCH_NON_FORWARDING_SHIM/);
});

test("reject a shim forwarding to a different owner", (t) => {
  const f = fixture(t);
  f.lean("CheckerState", "import Ps.KernelSelfHost.SelfHost\n");
  assert.throws(() => auditArchitecture(f.root), /ARCH_NON_FORWARDING_SHIM/);
});

test("reject duplicate ownership", (t) => {
  const f = fixture(t);
  f.manifest.canonicalOwners.push({ ...f.manifest.canonicalOwners[0] });
  f.json("PSKERNEL_ARCHITECTURE.json", f.manifest);
  assert.throws(() => auditArchitecture(f.root), /ARCH_DUPLICATE_OWNER/);
});

test("reject target drift", (t) => {
  const f = fixture(t);
  f.json("LEAN_4_34_CONFORMANCE.json", { target: { version: "4.35.0" } });
  assert.throws(() => auditArchitecture(f.root), /ARCH_TARGET_MISMATCH/);
});

test("reject a checker import across a configured layer fence", (t) => {
  const f = fixture(t);
  f.manifest.importFences = [{ from: ["Ps.KernelSelfHost.Checker."], forbidden: ["Ps.KernelSelfHost.SelfHost"] }];
  f.json("PSKERNEL_ARCHITECTURE.json", f.manifest);
  f.lean("Checker/State", "import Ps.KernelSelfHost.SelfHost\n");
  assert.throws(() => auditArchitecture(f.root), /ARCH_IMPORT_FENCE/);
});

test("validate every forwarding shim for an owner with multiple legacy paths", (t) => {
  const f = fixture(t);
  f.manifest.canonicalOwners[0].legacyShims = ["Ps.KernelSelfHost.OldState"];
  f.manifest.migration.migrationShims.push("Ps.KernelSelfHost.OldState");
  f.json("PSKERNEL_ARCHITECTURE.json", f.manifest);
  f.lean("OldState", "import Ps.KernelSelfHost.Checker.State\n");
  assert.match(auditArchitecture(f.root), /closureModules=2/);
  f.lean("OldState", "import Ps.KernelSelfHost.SelfHost\n");
  assert.throws(() => auditArchitecture(f.root), /ARCH_NON_FORWARDING_SHIM/);
});

test("reject a registered shim without a declared owner", (t) => {
  const f = fixture(t);
  delete f.manifest.canonicalOwners[0].legacyShim;
  f.json("PSKERNEL_ARCHITECTURE.json", f.manifest);
  assert.throws(() => auditArchitecture(f.root), /ARCH_SHIM_OWNER_MISSING/);
});

test("reject duplicate recursion owners even outside the semantic closure", (t) => {
  const f = fixture(t);
  f.manifest.recursiveWiring = { module: "Ps.KernelSelfHost.Checker.State", symbols: ["testState"] };
  f.json("PSKERNEL_ARCHITECTURE.json", f.manifest);
  assert.match(auditArchitecture(f.root), /closureModules=2/);
  f.lean("Hidden", "def testState : Bool := false\n");
  assert.throws(() => auditArchitecture(f.root), /ARCH_WIRING_SYMBOL_OWNER/);
});

test("reject a recursion symbol moved away from its declared owner", (t) => {
  const f = fixture(t);
  f.manifest.recursiveWiring = { module: "Ps.KernelSelfHost.Checker.State", symbols: ["testState"] };
  f.json("PSKERNEL_ARCHITECTURE.json", f.manifest);
  f.lean("Checker/State", "");
  f.lean("Hidden", "def testState : Bool := false\n");
  assert.throws(() => auditArchitecture(f.root), /ARCH_WIRING_SYMBOL_OWNER/);
});
