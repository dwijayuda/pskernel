import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import { spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import { fileURLToPath, pathToFileURL } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const outputRoot = path.join(root, "dist/scoped-correctness/practical-forms");
const work = fs.mkdtempSync(path.join(os.tmpdir(), "psc1-practical-forms-"));
fs.mkdirSync(outputRoot, { recursive: true });
fs.writeFileSync(path.join(work, "package.json"), '{"type":"module"}\n');
fs.writeFileSync(path.join(outputRoot, "package.json"), '{"type":"module"}\n');
const native = path.join(root, ".lake/build/bin/psc1");
const env = { ...process.env, PSC1_HOST_TOOLS: path.join(root, "host-tools/artifacts.mjs") };
const sha = bytes => createHash("sha256").update(bytes).digest("hex");
const records = [];
const checkerCommit = "eb6cafb7290e8bd5f2937522d8d804f58f02bafc";
function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: root, env, encoding: "utf8", timeout: 120000, maxBuffer: 32 * 1024 * 1024, ...options,
  });
  if (result.error || result.status !== 0)
    throw new Error(command + " " + args.join(" ") + "\n" + (result.error || result.stderr) + result.stdout);
  return result.stdout;
}
function build(label, source, target, extension, extra = []) {
  const output = path.join(outputRoot, label + "." + extension);
  run(native, ["build", source, "--target", target, ...extra, "--out", output]);
  const manifestPath = output + ".bundle.json";
  const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
  assert.equal(manifest.target, target);
  assert.equal(manifest.logicalChecker, "lean4:4.35.0");
  assert.equal(manifest.logicalCheckerCommit, checkerCommit);
  assert.equal(manifest.assurance, "checked-logical");
  assert.equal(manifest.behaviorallyVerified, false);
  assert.match(manifest.sourceClosureSha256, /^[0-9a-f]{64}$/);
  return { output, label, target, manifest,
    artifactSha256: sha(fs.readFileSync(fs.realpathSync(output))),
    manifestSha256: sha(fs.readFileSync(manifestPath)) };
}
function record(artifact, values) {
  records.push({ fixture: artifact.label, target: artifact.target,
    sourceClosureSha256: artifact.manifest.sourceClosureSha256,
    artifactSha256: artifact.artifactSha256, manifestSha256: artifact.manifestSha256, values });
}
function expectedCalls(expected) {
  return Object.entries(expected).flatMap(([name, values]) =>
    values.map((value, index) => ({ name, argument: Boolean(index), expected: value })));
}

const numeric = {
  "lean": "def keep {A : Type} (value : A) : A := value\ndef infercall (flag : Bool) : String := Int.repr (keep (if flag then 7 else 9))\ndef product (flag : Bool) : String := let pair : Prod Int Bool := Prod.mk (if flag then 11 else 13) flag; Int.repr (Prod.fst pair)\ndef array (flag : Bool) : String := let values : Array Int := Array.push (Array.emptyWithCapacity 1) (if flag then 17 else 19); Int.repr (Array.getD values 0 0)\ndef natops (flag : Bool) : String := let value : Nat := if flag then 20 - 3 * 4 else (20 - 3) * 4; Int.repr (Int.ofNat value)\ndef intops (flag : Bool) : String := let value : Int := if flag then -3 + 2 * 5 else -(3 + 2) * 5; Int.repr value\ndef divmod (flag : Bool) : String := let value : Nat := if flag then 17 / 5 + 17 % 5 else 2 - 5; Int.repr (Int.ofNat value)\n",
  "ps": "def keep {A : Type}(value : A) : A := value\ndef infercall(flag : Bool) : String := Int.repr(keep(if (flag) { 7 } else { 9 }))\ndef product(flag : Bool) : String := let pair : Prod(Int, Bool) := Prod.mk(if (flag) { 11 } else { 13 }, flag)\n Int.repr(Prod.fst(pair))\ndef array(flag : Bool) : String := let values : Array(Int) := Array.push(Array.emptyWithCapacity(1), if (flag) { 17 } else { 19 })\n Int.repr(Array.getD(values, 0, 0))\ndef natops(flag : Bool) : String := let value : Nat := if (flag) { 20 - 3 * 4 } else { (20 - 3) * 4 }\n Int.repr(Int.ofNat(value))\ndef intops(flag : Bool) : String := let value : Int := if (flag) { -3 + 2 * 5 } else { -(3 + 2) * 5 }\n Int.repr(value)\ndef divmod(flag : Bool) : String := let value : Nat := if (flag) { 17 / 5 + 17 % 5 } else { 2 - 5 }\n Int.repr(Int.ofNat(value))\n"
};
const numericExpected = {"infercall":["9","7"],"product":["13","11"],"array":["19","17"],"natops":["68","8"],"intops":["-25","7"],"divmod":["0","5"]};
const boolCases = [
  {
    "name": "operators",
    "expected": [false, true],
    "lean": "def answer (flag : Bool) : Bool := flag || false && !flag\n",
    "ps": "def answer(flag : Bool) : Bool := flag || false && !flag\n"
  },
  {
    "name": "iddo",
    "expected": [false, true],
    "lean": "def answer (flag : Bool) : Bool := Id.run (do { let a : Bool := flag; let b <- a; return b })\n",
    "ps": "def answer(flag : Bool) : Bool := Id.run(do {\n let a : Bool := flag\n let b <- a\n return b\n})\n"
  },
  {
    "name": "exceptdo",
    "expected": [true, false],
    "lean": "def answer (flag : Bool) : Bool :=\n let initial : Except Bool Bool := do { let value : Bool <- Except.ok flag; return value };\n let selected : Bool := match initial with | Except.error error => error | Except.ok value => value;\n let action : Except Bool Bool := do {\n  let value : Bool <- if selected then Except.ok false else Except.error true;\n  let ignored : Unit <- Except.error false;\n  return value\n };\n match action with | Except.error error => error | Except.ok value => value\n",
    "ps": "def answer(flag : Bool) : Bool :=\n let initial : Except(Bool, Bool) := do {\n  let value : Bool <- Except.ok(flag)\n  return value\n }\n let selected : Bool := match initial with { | Except.error error => error | Except.ok value => value }\n let action : Except(Bool, Bool) := do {\n  let value : Bool <- if (selected) { Except.ok(false) } else { Except.error(true) }\n  let ignored : Unit <- Except.error(false)\n  return value\n }\n match action with { | Except.error error => error | Except.ok value => value }\n"
  }
];

async function executePortable(label, source, expected) {
  const calls = expectedCalls(expected);
  for (const target of ["js", "ts", "rust"]) {
    const artifact = build(label + "-" + target, source, target, target === "rust" ? "rs" : target);
    if (target === "rust") {
      const crate = path.join(work, label + "-crate");
      fs.cpSync(fs.realpathSync(artifact.output.replace(/\.rs$/, ".cargo")), crate, { recursive: true });
      const assertions = calls.map(c =>
        "assert_eq!(" + c.name + "(" + c.argument + "), " + JSON.stringify(c.expected) + ");").join("\n");
      fs.chmodSync(path.join(crate, "src/lib.rs"), 0o644);
      fs.appendFileSync(path.join(crate, "src/lib.rs"),
        "\n#[cfg(test)] mod practical_forms { use super::*; #[test] fn actual_results() {\n" + assertions + "\n} }\n");
      const stdout = run("cargo", ["test", "--manifest-path", path.join(crate, "Cargo.toml"), "--locked"],
        { env: { ...env, CARGO_TARGET_DIR: path.join(work, "cargo-target") } });
      assert.match(stdout, /test practical_forms::actual_results \.\.\. ok/);
      record(artifact, { calls, runnerStdoutSha256: sha(stdout) });
    } else {
      let modulePath = fs.realpathSync(artifact.output);
      if (target === "ts") {
        assert.ok(process.env.PSC1_TSC, "PSC1_TSC must name the qualified TypeScript compiler");
        const consumer = path.join(work, label + "-ts");
        fs.mkdirSync(consumer, { recursive: true });
        const input = path.join(consumer, "module.ts");
        fs.copyFileSync(modulePath, input);
        run(process.execPath, [process.env.PSC1_TSC, "--ignoreConfig", "--strict", "--target", "ES2022",
          "--module", "NodeNext", "--moduleResolution", "NodeNext", "--outDir", path.join(consumer, "out"), input]);
        modulePath = path.join(consumer, "out/module.js");
      }
      const module = await import(pathToFileURL(modulePath).href);
      const values = calls.map(c => {
        const actual = module[c.name](c.argument);
        assert.equal(actual, c.expected, label + "/" + target + "/" + c.name + "(" + c.argument + ")");
        return { ...c, actual };
      });
      record(artifact, values);
    }
  }
}
try {
  for (const kind of ["lean", "ps"]) {
    const numericSource = path.join(outputRoot, "numeric." + kind);
    fs.writeFileSync(numericSource, numeric[kind]);
    assert.match(run(native, ["check", numericSource]), /PSC1_KERNEL_CHECK: PASS/);
    await executePortable("numeric-" + kind, numericSource, numericExpected);
    for (const test of boolCases) {
      const label = test.name + "-" + kind;
      const source = path.join(outputRoot, label + "." + kind);
      fs.writeFileSync(source, test[kind]);
      assert.match(run(native, ["check", source]), /PSC1_KERNEL_CHECK: PASS/);
      await executePortable(label, source, { answer: test.expected });
      const core = build(label + "-core", source, "wasm-core", "wasm");
      const instance = await WebAssembly.instantiate(fs.readFileSync(core.output));
      const actual = [0, 1].map(input => instance.instance.exports.answer(input));
      assert.deepEqual(actual, test.expected.map(Number));
      record(core, actual);
      const component = build(label + "-component", source, "wasm-component", "wasm", ["--export", "answer"]);
      const componentValues = [false, true].map(input =>
        run("wasmtime", ["run", "--invoke", "answer(" + input + ")", component.output]).trim());
      assert.deepEqual(componentValues, test.expected.map(String));
      record(component, componentValues);
    }
  }
  console.log("PSC1_PRACTICAL_FORMS_BACKENDS: PASS " + records.length + " executed artifacts");
} finally {
  const results = JSON.stringify({ sha: process.env.GITHUB_SHA, logicalChecker: "lean4:4.35.0",
    logicalCheckerCommit: checkerCommit, fullSelfHostTests: false, records }, null, 2) + "\n";
  const resultsPath = path.join(outputRoot, "execution-results.json");
  fs.writeFileSync(resultsPath, results);
  fs.writeFileSync(resultsPath + ".sha256", sha(results) + "\n");
  fs.rmSync(work, { recursive: true, force: true });
}
