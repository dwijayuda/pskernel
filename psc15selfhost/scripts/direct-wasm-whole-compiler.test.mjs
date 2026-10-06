import { existsSync } from "node:fs";
import { mkdir, readFile, rm } from "node:fs/promises";
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
}

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

process.stdout.write(
  [
    "PSC2_DIRECT_WASM_WHOLE_COMPILER: PASS",
    "wasm=" + path.relative(root, outputWasm),
    "bytes=" + String(bytes.length),
  ].join("\n") + "\n",
);
