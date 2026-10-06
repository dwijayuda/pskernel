import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const fixture = "test/fixtures/ErasureEta.lean";
const directory = await mkdtemp(path.join(tmpdir(), "psc-erasure-eta-"));
function compile(args) {
  const result = spawnSync("lake", ["exe", "psc1", ...args], {
    cwd: root, encoding: "utf8", windowsHide: true, maxBuffer: 32 * 1024 * 1024,
  });
  if (result.error) throw result.error;
  assert.equal(result.status, 0, [result.stdout, result.stderr].join("\n"));
  return result.stdout;
}
try {
  const js = path.join(directory, "fixture.mjs");
  const jsSource = compile(["javascript", fixture]);
  await writeFile(js, jsSource);
  const portable = path.join(directory, "fixture.ps");
  compile(["translate", fixture, "--to", "ps", "--out", portable]);
  assert.equal(compile(["javascript", portable]), jsSource, "Lean/ProofScript eta erasure parity");
  const generated = await import(pathToFileURL(js).href);
  const checks = ["etaRuntimeCheck", "etaCaptureCheck", "etaShadowCheck", "etaMatchZeroCheck",
    "etaMatchSuccessorCheck", "etaConditionalTrueCheck", "etaConditionalFalseCheck", "etaForwardCheck"];
  for (const name of checks) assert.equal(generated[name], true, name);
  for (const offset of [0n, 2n, 99n]) {
    for (const value of [0n, 40n, 123n]) {
      assert.equal(generated.etaConditional(true, offset, value), offset + value);
      assert.equal(generated.etaConditional(false, offset, value), value >= offset ? value - offset : 0n);
      assert.equal(generated.etaCapture(offset, value), offset + value);
      assert.equal(generated.etaShadow(offset, value), offset + value);
      assert.equal(generated.etaMatch(offset, value), offset + value);
      assert.equal(generated.etaCount(offset, value), offset + value);
    }
  }
  const wasm = path.join(directory, "fixture.wasm");
  compile(["wasm", fixture, "--out", wasm]);
  const { instance } = await WebAssembly.instantiate(await readFile(wasm), {});
  assert.equal(instance.exports.__ps_selfhost_bytes_head, undefined);
  for (const name of checks) assert.equal(instance.exports[name](), 1, name);
  console.log("PSC1_ERASURE_ETA_RUNTIME: PASS (JavaScript and Wasm)");
} finally {
  await rm(directory, { recursive: true, force: true });
}
