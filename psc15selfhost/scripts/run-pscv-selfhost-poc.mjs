import { existsSync } from "node:fs";
import { readFile, rm } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const compiler = path.join(root, "dist/bootstrap/packages/compiler/index.js");
const proof = path.join(
  root,
  "packages/compiler/proofs/Ps/Compiler/PscvPoc.lean",
);
const runtimeRoot = path.join(
  root,
  "packages/bootstrap/src/Ps/Bootstrap/SelfHost.lean",
);
const outputRoot = path.join(root, "dist/pscv-selfhost-poc");
const workspace = path.join(outputRoot, "workspace");
const generatedProof = path.join(
  workspace,
  "packages/compiler/proofs/Ps/Compiler/PscvPoc.ps",
);

function run(label, command, args) {
  const result = spawnSync(command, args, {
    cwd: root,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
    timeout: 180000,
    maxBuffer: 32 * 1024 * 1024,
    windowsHide: true,
  });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(
      `PSCV_SELFHOST_POC_${label}_FAILED\n${result.stdout}\n${result.stderr}`,
    );
  }
  process.stdout.write(result.stdout);
  process.stderr.write(result.stderr);
}

if (!existsSync(compiler)) {
  throw new Error(
    "PSCV_SELFHOST_POC_COMPILER_MISSING: run `npm run bootstrap` first",
  );
}
if (!existsSync(proof)) throw new Error("PSCV_SELFHOST_POC_PROOF_MISSING");

const runtimeSource = await readFile(runtimeRoot, "utf8");
if (runtimeSource.includes("PscvPoc")) {
  throw new Error("PSCV_SELFHOST_POC_RUNTIME_IMPORTS_PROOF");
}

await rm(outputRoot, { recursive: true, force: true });

run("TRANSLATE", process.execPath, [
  "scripts/emit-project-with-generated.mjs",
  compiler,
  proof,
  "--to",
  "ps",
  "--out",
  workspace,
]);

if (!existsSync(generatedProof)) {
  throw new Error("PSCV_SELFHOST_POC_GENERATED_PROOF_MISSING");
}

const generated = await readFile(generatedProof, "utf8");
for (const required of [
  "theorem pscvPocCheckElaboratedIsPrepare",
  "psCompilerCheckElaborated",
  "psCompilerPrepareElaborated",
  "theorem pscvPocCheckElaboratedIsPrepare",
]) {
  if (!generated.includes(required)) {
    throw new Error(`PSCV_SELFHOST_POC_GENERATED_PROOF_DRIFT: ${required}`);
  }
}

run("KERNEL_CHECK", process.execPath, [
  "scripts/checked-build.mjs",
  generatedProof,
  "--check",
  "--compiler",
  compiler,
  "--kernel",
  "lean434-wasm",
]);

process.stdout.write(
  [
    "PSCV_SELFHOST_POC: PASS",
    "claim=PSCV-POC-COMP-001",
    "theorem=pscvPocCheckElaboratedIsPrepare",
    "proofRuntimeDependency=false",
    "executableProofArtifact=false",
    "checkedProvider=lean434-wasm",
    "note=provider repin to Lean 4.35.0-rc3 remains required for PSCV RC-v2 conformance",
  ].join("\n") + "\n",
);
