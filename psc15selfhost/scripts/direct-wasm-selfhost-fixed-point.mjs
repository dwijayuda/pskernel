import { existsSync } from "node:fs";
import { mkdir, readFile, rm, writeFile } from "node:fs/promises";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { readGeneratedSourceClosure } from "./selfhost-source-workspace.mjs";
import { loadWasmSelfhostCompiler, compileWasmSelfhostProgress } from './wasm-selfhost-progress.mjs';

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
const generation1 = path.join(outRoot, "compiler.gen1.wasm");
const generation2 = path.join(outRoot, "compiler.gen2.wasm");
const generation3 = path.join(outRoot, "compiler.gen3.wasm");

const startedAt = performance.now();
function phase(name) {
  process.stdout.write("PSC2_DIRECT_WASM_SELFHOST_PHASE: " + name +
    " elapsedMs=" + String(Math.round(performance.now() - startedAt)) + "\n");
}

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
        "PSC2_DIRECT_WASM_SELFHOST_COMMAND_FAILED",
        command + " " + args.join(" "),
        result.stdout,
        result.stderr,
      ].filter(Boolean).join("\n"),
    );
  }
}

function bytesEqual(left, right) {
  if (left.length !== right.length) return false;
  for (let index = 0; index < left.length; index += 1) {
    if (left[index] !== right[index]) return false;
  }
  return true;
}

await rm(outRoot, { recursive: true, force: true });
await mkdir(outRoot, { recursive: true });

phase("bootstrap-workspace");
run(process.execPath, [
  "scripts/bootstrap-project.mjs",
  path.relative(root, entryLean),
  path.relative(root, workspace),
]);

if (!existsSync(entryPs)) {
  throw new Error("PSC2_DIRECT_WASM_SELFHOST_ENTRY_MISSING");
}

const nativeSuffix = process.platform === "win32" ? ".exe" : "";
const nativeCompiler = path.join(root, ".lake", "build", "bin", "psc1" + nativeSuffix);
const nativeCommand = existsSync(nativeCompiler) ? nativeCompiler : "lake";
const nativeArgs = existsSync(nativeCompiler)
  ? ["wasm", path.relative(root, entryPs), "--out", path.relative(root, generation1)]
  : [
      "exe",
      "psc1",
      "wasm",
      path.relative(root, entryPs),
      "--out",
      path.relative(root, generation1),
    ];
phase("native-generation-1");
run(nativeCommand, nativeArgs);

const closure = await readGeneratedSourceClosure(entryPs, workspace);
if (!closure || closure.ordered.length === 0) {
  throw new Error("PSC2_DIRECT_WASM_SELFHOST_CLOSURE_EMPTY");
}
const sources = closure.ordered.map(item => ({ source: item.source, path: path.relative(workspace, item.path).split(path.sep).join('/') }));
phase("source-closure:" + String(sources.length) + ":" + closure.closureSha256);

const generation1Bytes = new Uint8Array(await readFile(generation1));
phase("load-generation-1:bytes:" + String(generation1Bytes.length));
const compiler1 = await loadWasmSelfhostCompiler(generation1Bytes);
const generation2Bytes = compileWasmSelfhostProgress(compiler1, sources, name => phase("generation-2:" + name));
await writeFile(generation2, generation2Bytes);

if (!bytesEqual(generation1Bytes, generation2Bytes)) {
  throw new Error("PSC2_DIRECT_WASM_SELFHOST_BOOTSTRAP_FIXED_POINT_MISMATCH");
}
phase("generation-1-equals-2");

phase("load-generation-2");
const compiler2 = await loadWasmSelfhostCompiler(generation2Bytes);
const generation3Bytes = compileWasmSelfhostProgress(compiler2, sources, name => phase("generation-3:" + name));
await writeFile(generation3, generation3Bytes);

if (!bytesEqual(generation2Bytes, generation3Bytes)) {
  throw new Error("PSC2_DIRECT_WASM_SELFHOST_SELF_FIXED_POINT_MISMATCH");
}
phase("generation-2-equals-3");

process.stdout.write(
  [
    "PSC2_DIRECT_WASM_SELFHOST_FIXED_POINT: PASS",
    "compiler=" + path.relative(root, generation2),
    "modules=" + String(closure.ordered.length),
    "closureSha256=" + closure.closureSha256,
    "bytes=" + String(generation2Bytes.length),
  ].join("\n") + "\n",
);
