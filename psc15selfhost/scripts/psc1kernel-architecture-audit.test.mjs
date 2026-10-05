import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { auditArchitecture } from "./psc1kernel-architecture-audit.mjs";

function fixture(t) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "pskernel-architecture-"));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const packageRoot = path.join(root, "packages/pskernel-core");
  const sourceRoot = path.join(packageRoot, "src/Ps/KernelCore");
  fs.mkdirSync(sourceRoot, { recursive: true });
  const prefix = "Ps.KernelCore.";
  const target = { version: "4.34.0", gitCommit: "pinned-test-target" };
  const manifest = {
    target,
    semanticRootModule: prefix + "SelfHost",
    semanticRootPath: "packages/pskernel-core/src/Ps/KernelCore/SelfHost.lean",
    semanticModulePrefix: prefix,
    migration: {
      finalArchitectureAdopted: true,
      finalArchitectureImplemented: false,
      migrationShims: [prefix + "CheckerState"],
    },
    forbiddenSemanticImportPrefixes: ["PSC1Kernel.", prefix + "Compat.", "KernelCore."],
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
  lean("SelfHost", "import Ps.KernelCore.Checker.State\n");
  lean("Checker/State", "def testState : Bool := true\n");
  lean("CheckerState", "import Ps.KernelCore.Checker.State\n/- Forwarding only. -/\n");
  return { root, lean, json, manifest };
}

for (const missing of ["SelfHost", "Checker.State", "CheckerState"]) {
  test("reject missing Lake registration: " + missing, (t) => {
    const f = fixture(t);
    f.manifest.lakeLibrary = "PsKernelCore";
    f.json("PSKERNEL_ARCHITECTURE.json", f.manifest);
    const roots = ["SelfHost", "Checker.State", "CheckerState"].filter((name) => name !== missing);
    fs.writeFileSync(path.join(f.root, "lakefile.lean"),
      "lean_lib PsKernelCore where\n  roots := #[" + roots.map((name) => "`Ps.KernelCore." + name).join(", ") + "]\n" +
      "lean_lib Other where\n  roots := #[`Ps.KernelCore." + missing + "]\n");
    assert.throws(() => auditArchitecture(f.root), /ARCH_LAKE_MODULE_MISSING/);
  });
}

function ruleFixture(t) {
  const f = fixture(t);
  f.manifest.ruleInventory = "RULES.json";
  f.json("PSKERNEL_ARCHITECTURE.json", f.manifest);
  f.json("LEAN_4_34_COMPATIBILITY.json", {
    target: f.manifest.target, rules: [{ id: "RULE", pskernelSymbol: "testState" }],
  });
  const rule = {
    id: "RULE", parentId: "RULE", ownerModule: "Ps.KernelCore.Checker.State",
    implementationSymbols: ["testState"],
    evidence: [{ testFile: "test/PsKernelCoreFoundationTests.lean", testSymbol: "focused", coverage: "direct-invariant" }],
  };
  const inventory = { target: f.manifest.target, rules: [rule] };
  f.json("RULES.json", inventory);
  fs.mkdirSync(path.join(f.root, "test"));
  const testFile = path.join(f.root, "test/PsKernelCoreFoundationTests.lean");
  fs.writeFileSync(testFile, "def focused : Bool := true\ndef main : Bool := focused\n");
  return { ...f, rule, inventory, testFile };
}

test("reject a deleted module still registered with Lake", (t) => {
  const f = fixture(t);
  f.manifest.lakeLibrary = "PsKernelCore";
  f.json("PSKERNEL_ARCHITECTURE.json", f.manifest);
  fs.writeFileSync(path.join(f.root, "lakefile.lean"),
    "lean_lib PsKernelCore where\n  roots := #[`Ps.KernelCore.SelfHost, `Ps.KernelCore.Checker.State, `Ps.KernelCore.CheckerState, `Ps.KernelCore.Deleted]\n");
  assert.throws(() => auditArchitecture(f.root), /ARCH_LAKE_STALE_MODULE/);
});

test("retired compatibility shims cannot be registered again", (t) => {
  const f = fixture(t);
  f.manifest.migration.compatibilityShimsRetired = true;
  f.json("PSKERNEL_ARCHITECTURE.json", f.manifest);
  assert.throws(() => auditArchitecture(f.root), /ARCH_RETIRED_SHIM_REGISTERED/);
});

test("accept canonical rules with reachable executable evidence", (t) => {
  assert.match(auditArchitecture(ruleFixture(t).root), /closureModules=2/);
});

test("reject evidence present in a file but not called by main", (t) => {
  const f = ruleFixture(t);
  fs.writeFileSync(f.testFile, "def focused : Bool := true\ndef main : Bool := true\n");
  assert.throws(() => auditArchitecture(f.root), /ARCH_RULE_EVIDENCE/);
});

test("reject a rule symbol duplicated outside its canonical owner", (t) => {
  const f = ruleFixture(t);
  f.lean("Checker/Duplicate", "def testState : Bool := false\n");
  assert.throws(() => auditArchitecture(f.root), /ARCH_RULE_SYMBOL_OWNER/);
});

test("reject a missing top-level compatibility mapping", (t) => {
  const f = ruleFixture(t);
  f.inventory.rules = [];
  f.json("RULES.json", f.inventory);
  assert.throws(() => auditArchitecture(f.root), /ARCH_RULE_COMPATIBILITY/);
});

test("reject a rule assigned to an unknown owner", (t) => {
  const f = ruleFixture(t);
  f.rule.ownerModule = "Ps.KernelCore.Checker.Missing";
  f.json("RULES.json", f.inventory);
  assert.throws(() => auditArchitecture(f.root), /ARCH_RULE_OWNER/);
});

test("reject duplicate rule ids", (t) => {
  const f = ruleFixture(t);
  f.inventory.rules.push(f.rule);
  f.json("RULES.json", f.inventory);
  assert.throws(() => auditArchitecture(f.root), /ARCH_DUPLICATE_RULE/);
});

test("reject unclassified new checker diagnostics", (t) => {
  const f = fixture(t);
  f.manifest.diagnosticInventory = "DIAGNOSTICS.json";
  f.json("PSKERNEL_ARCHITECTURE.json", f.manifest);
  f.json("DIAGNOSTICS.json", { unknownDiagnostic: "internalError", diagnostics: [] });
  f.lean("Checker/State", 'def testState : Except String Bool := Except.error "new failure"\n');
  assert.throws(() => auditArchitecture(f.root), /ARCH_DIAGNOSTIC_INCOMPLETE/);
});

test("completion requires production evidence instead of a status flag alone", (t) => {
  const f = fixture(t);
  f.manifest.migration.finalArchitectureImplemented = true;
  f.json("PSKERNEL_ARCHITECTURE.json", f.manifest);
  assert.throws(() => auditArchitecture(f.root), /ARCH_COMPLETION_EVIDENCE_MISSING/);
});

test("comments and strings do not create imports; trailing comments preserve imports", (t) => {
  const f = fixture(t);
  f.lean("SelfHost", `/- Outer /- nested -/ comment
import PSC1Kernel.Fake
-/
import Ps.KernelCore.Checker.State -- owner
def note : String := "import PSC1Kernel.Fake"
`);
  assert.match(auditArchitecture(f.root), /closureModules=2/);
});

for (const source of [
  "import PSC1Kernel.Hidden -- trailing comment\n",
  "import Ps.KernelCore.Checker.State PSC1Kernel.Hidden\n",
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
  f.lean("SelfHost", "import\nPs.KernelCore.Checker.State\n");
  assert.throws(() => auditArchitecture(f.root), /ARCH_IMPORT_SYNTAX/);
});

test("reject a transitive migration shim in the semantic closure", (t) => {
  const f = fixture(t);
  f.lean("Checker/State", "import Ps.KernelCore.CheckerState\n");
  assert.throws(() => auditArchitecture(f.root), /ARCH_SHIM_IN_SEMANTIC_ROOT/);
});

test("reject declarations added to a forwarding shim", (t) => {
  const f = fixture(t);
  f.lean("CheckerState", "import Ps.KernelCore.Checker.State\ndef secondState : Bool := false\n");
  assert.throws(() => auditArchitecture(f.root), /ARCH_NON_FORWARDING_SHIM/);
});

test("reject a shim forwarding to a different owner", (t) => {
  const f = fixture(t);
  f.lean("CheckerState", "import Ps.KernelCore.SelfHost\n");
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
  f.manifest.importFences = [{ from: ["Ps.KernelCore.Checker."], forbidden: ["Ps.KernelCore.SelfHost"] }];
  f.json("PSKERNEL_ARCHITECTURE.json", f.manifest);
  f.lean("Checker/State", "import Ps.KernelCore.SelfHost\n");
  assert.throws(() => auditArchitecture(f.root), /ARCH_IMPORT_FENCE/);
});

test("validate every forwarding shim for an owner with multiple legacy paths", (t) => {
  const f = fixture(t);
  f.manifest.canonicalOwners[0].legacyShims = ["Ps.KernelCore.OldState"];
  f.manifest.migration.migrationShims.push("Ps.KernelCore.OldState");
  f.json("PSKERNEL_ARCHITECTURE.json", f.manifest);
  f.lean("OldState", "import Ps.KernelCore.Checker.State\n");
  assert.match(auditArchitecture(f.root), /closureModules=2/);
  f.lean("OldState", "import Ps.KernelCore.SelfHost\n");
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
  f.manifest.recursiveWiring = { module: "Ps.KernelCore.Checker.State", symbols: ["testState"] };
  f.json("PSKERNEL_ARCHITECTURE.json", f.manifest);
  assert.match(auditArchitecture(f.root), /closureModules=2/);
  f.lean("Hidden", "def testState : Bool := false\n");
  assert.throws(() => auditArchitecture(f.root), /ARCH_WIRING_SYMBOL_OWNER/);
});

test("reject a recursion symbol moved away from its declared owner", (t) => {
  const f = fixture(t);
  f.manifest.recursiveWiring = { module: "Ps.KernelCore.Checker.State", symbols: ["testState"] };
  f.json("PSKERNEL_ARCHITECTURE.json", f.manifest);
  f.lean("Checker/State", "");
  f.lean("Hidden", "def testState : Bool := false\n");
  assert.throws(() => auditArchitecture(f.root), /ARCH_WIRING_SYMBOL_OWNER/);
});
