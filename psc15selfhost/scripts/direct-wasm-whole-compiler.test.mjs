import { wasmFunctionExports, describeWasmFailure } from './wasm-function-diagnostics.mjs';
import { existsSync } from "node:fs";
import { mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { loadWasmSelfhostCompiler, compileWasmSelfhostProgress, compileWasmSelfhostMonolithic } from './wasm-selfhost-progress.mjs';
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const outRoot = path.join(root, "dist", "direct-wasm-selfhost");
const workspace = path.join(outRoot, "workspace");
const entryLean = path.join(
  root,
  "packages",
  "bootstrap",
  "src",
  "Ps",
  "Bootstrap",
  "SelfHostWasm.lean",
);
const entryPs = path.join(
  workspace,
  "packages",
  "bootstrap",
  "src",
  "Ps",
  "Bootstrap",
  "SelfHostWasm.ps",
);
const outputWasm = path.join(outRoot, "compiler.gen1.wasm");

function run(command, args) {
  const result = spawnSync(command, args, {
    cwd: root,
    encoding: "utf8",
    maxBuffer: 256 * 1024 * 1024,
  });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(
      [
        "PSC2_DIRECT_WASM_WHOLE_COMPILER_COMMAND_FAILED",
        command + " " + args.join(" "),
        result.stdout,
        result.stderr,
      ].filter(Boolean).join("\n"),
    );
  }
  return result.stdout;
}

if (!outRoot.startsWith(root + path.sep)) throw new Error('PSC_WASM_TEST_OUTPUT_ESCAPE');
await rm(outRoot, { recursive: true, force: true });
await mkdir(outRoot, { recursive: true });

run(process.execPath, [
  "scripts/bootstrap-project.mjs",
  path.relative(root, entryLean),
  path.relative(root, workspace),
]);

if (!existsSync(entryPs)) {
  throw new Error("PSC2_DIRECT_WASM_WHOLE_COMPILER_ENTRY_MISSING");
}

const nativeSuffix = process.platform === "win32" ? ".exe" : "";
const nativeCompiler = path.join(root, ".lake", "build", "bin", "psc1" + nativeSuffix);
const command = existsSync(nativeCompiler) ? nativeCompiler : "lake";
const args = existsSync(nativeCompiler)
  ? ["wasm", path.relative(root, entryPs), "--out", path.relative(root, outputWasm)]
  : [
      "exe",
      "psc1",
      "wasm",
      path.relative(root, entryPs),
      "--out",
      path.relative(root, outputWasm),
    ];
run(command, args);

const bytes = await readFile(outputWasm);
const module = await WebAssembly.compile(bytes);
await WebAssembly.instantiate(module, {});

const api = await loadWasmSelfhostCompiler(bytes);
const functionNames = wasmFunctionExports(bytes);
const finishIndex = [...functionNames].find(([, names]) => names.includes('psCompilerWasmProgressFinish'))?.[0];
if (finishIndex === undefined || !describeWasmFailure({ stack: 'wasm-function[' + finishIndex + ']' }, functionNames)[0]?.exports.includes('psCompilerWasmProgressFinish'))
  throw new Error('PSC_WASM_FUNCTION_DIAGNOSTICS_FAILED');
const smokeLean = path.join(outRoot, 'progress-smoke.lean');
await writeFile(smokeLean, 'def forward (A : Type) (value : A) : A := value\ndef answer (value : UInt32) : UInt32 := forward UInt32 value\n');
const emitArgs = ['emit-ps', path.relative(root, smokeLean)];
const smokeSource = run(command, existsSync(nativeCompiler) ? emitArgs : ['exe', 'psc1', ...emitArgs]);
const legacy = compileWasmSelfhostMonolithic(api, [smokeSource]);
const observed = [], staged = compileWasmSelfhostProgress(api, [{ source: smokeSource, path: 'progress-smoke.ps' }], name => observed.push(name));
if (!Buffer.from(legacy).equals(Buffer.from(staged))) throw new Error('PSC_WASM_PROGRESS_OUTPUT_CHANGED');
const smoke = await WebAssembly.instantiate(staged, {});
if (smoke.instance.exports.answer(42) !== 42 || api.Failed(api.Validate(api.Initial())) !== 1)
  throw new Error('PSC_WASM_PROGRESS_SEMANTICS_OR_PHASE_FAILURE');
let rejected = false;
try { compileWasmSelfhostProgress(api, [{ source: 'invalid source !!!', path: 'invalid.ps' }]); }
catch (error) { rejected = /PSC_WASM_PROGRESS_FAILED/.test(error.message); }
if (!rejected) throw new Error('PSC_WASM_PROGRESS_FAILURE_FALLBACK');
process.stdout.write('PSC_WASM_PROGRESS_ABI: PASS (' + observed.join(',') + ')\n');

process.stdout.write(
  [
    "PSC2_DIRECT_WASM_WHOLE_COMPILER: PASS",
    "wasm=" + path.relative(root, outputWasm),
    "bytes=" + String(bytes.length),
  ].join("\n") + "\n",
);
