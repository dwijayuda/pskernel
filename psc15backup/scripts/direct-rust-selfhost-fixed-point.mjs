import { existsSync } from "node:fs";
import { mkdir, readFile, rm, writeFile } from "node:fs/promises";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { readGeneratedSourceClosure } from "./selfhost-source-workspace.mjs";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const outRoot = path.join(root, "dist", "direct-rust-fixed-point");
const workspace = path.join(outRoot, "workspace");
const entryLean = path.join(
  root, "packages", "bootstrap", "src", "Ps", "Bootstrap", "SelfHostRust.lean",
);
const entryPs = path.join(
  workspace, "packages", "bootstrap", "src", "Ps", "Bootstrap", "SelfHostRust.ps",
);
const gen1 = path.join(outRoot, "compiler.gen1.rs");
const gen2 = path.join(outRoot, "compiler.gen2.rs");
const gen3 = path.join(outRoot, "compiler.gen3.rs");
const cargoRoot = path.join(outRoot, "native");
const cargoSrc = path.join(cargoRoot, "src");
const cargoLib = path.join(cargoSrc, "lib.rs");
const cargoMain = path.join(cargoSrc, "main.rs");
const binary = path.join(
  cargoRoot,
  "target",
  "debug",
  process.platform === "win32" ? "psc-rust-selfhost.exe" : "psc-rust-selfhost",
);

function execute(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: root,
    encoding: "utf8",
    maxBuffer: 512 * 1024 * 1024,
    ...options,
  });
  if (result.error) throw result.error;
  return result;
}

function requireSuccess(result, label, command, args) {
  if (result.status !== 0) {
    throw new Error([
      label,
      command + " " + args.join(" "),
      result.stdout,
      result.stderr,
    ].filter(Boolean).join("\n"));
  }
  return result.stdout ?? "";
}

function phase(name) {
  process.stdout.write("PSC2_DIRECT_RUST_SELFHOST_PHASE: " + name + "\n");
}

function bytesEqual(left, right) {
  return Buffer.from(left).equals(Buffer.from(right));
}

async function writeCargoProject(rustSource) {
  await mkdir(cargoSrc, { recursive: true });
  await writeFile(cargoLib, rustSource, "utf8");
  await writeFile(
    cargoMain,
    [
      "use proofscript_direct_rust_selfhost::{",
      "  psCompilerRustProofScriptSourcesOrEmpty,",
      "  psCompilerRustSelfHostSourceListCons,",
      "  psCompilerRustSelfHostSourceListEmpty,",
      "};",
      "use std::{env, fs, process};",
      "",
      "fn main() {",
      "  let paths: Vec<String> = env::args().skip(1).collect();",
      "  let mut sources = psCompilerRustSelfHostSourceListEmpty();",
      "  for file in paths.iter().rev() {",
      "    let source = match fs::read_to_string(file) {",
      "      Ok(value) => value,",
      "      Err(error) => { eprintln!(\"PSC2_DIRECT_RUST_SELFHOST_READ_FAILED: {file}: {error}\"); process::exit(2); }",
      "    };",
      "    sources = psCompilerRustSelfHostSourceListCons(source, sources);",
      "  }",
      "  let output = psCompilerRustProofScriptSourcesOrEmpty(sources);",
      "  if output.is_empty() {",
      "    eprintln!(\"PSC2_DIRECT_RUST_SELFHOST_COMPILE_FAILED_OR_EMPTY\");",
      "    process::exit(3);",
      "  }",
      "  print!(\"{}\", output);",
      "}",
      "",
    ].join("\n"),
    "utf8",
  );
  await writeFile(
    path.join(cargoRoot, "Cargo.toml"),
    [
      "[package]",
      'name = "proofscript-direct-rust-selfhost"',
      'version = "0.0.0"',
      'edition = "2021"',
      "",
      "[lib]",
      'name = "proofscript_direct_rust_selfhost"',
      'path = "src/lib.rs"',
      "",
      "[[bin]]",
      'name = "psc-rust-selfhost"',
      'path = "src/main.rs"',
      "",
      "[dependencies]",
      'num-bigint = "0.4"',
      'num-traits = "0.2"',
      "",
    ].join("\n"),
    "utf8",
  );
}

function buildNative() {
  requireSuccess(
    execute("cargo", ["build", "--quiet"], {
      cwd: cargoRoot,
      env: { ...process.env, RUSTFLAGS: "-Awarnings" },
    }),
    "PSC2_DIRECT_RUST_SELFHOST_CARGO_BUILD_FAILED",
    "cargo",
    ["build", "--quiet"],
  );
  if (!existsSync(binary)) {
    throw new Error("PSC2_DIRECT_RUST_SELFHOST_BINARY_MISSING");
  }
}

function runNative(paths, stage) {
  phase(stage);
  const result = execute(binary, paths, {
    cwd: root,
    maxBuffer: 512 * 1024 * 1024,
  });
  if (result.status !== 0 && /overflowed its stack/u.test(result.stderr ?? "")) {
    // Diagnostic replay cannot satisfy the fixed-point gate. GNU timeout kills
    // the debugger's process group after 45 seconds; never enlarge the stack.
    // Disable automatic debugger scripts before reading generated binaries:
    // https://sourceware.org/gdb/current/onlinedocs/gdb.html/Auto_002dloading.html
    if (process.platform === "linux" && existsSync("/usr/bin/gdb") && existsSync("/usr/bin/timeout")) {
      phase(stage + "-overflow-diagnostic");
      const trace = spawnSync("/usr/bin/timeout", [
        "--signal=KILL", "45s", "/usr/bin/gdb", "--batch", "--nx", "--quiet",
        "-iex", "set auto-load off", "-ex", "set pagination off",
        "-ex", "set debuginfod enabled off", "-ex", "set startup-with-shell off",
        "-ex", "set print frame-arguments none", "-ex", "run", "-ex", "backtrace 96",
        "--args", binary, ...paths,
      ], { cwd: root, encoding: "utf8", maxBuffer: 8 * 1024 * 1024 });
      process.stderr.write("PSC2_DIRECT_RUST_OVERFLOW_DIAGNOSTIC: " +
        JSON.stringify({ status: trace.status, signal: trace.signal, error: trace.error?.code }) + "\n");
      process.stderr.write((trace.stdout ?? "").slice(-128 * 1024) + (trace.stderr ?? "").slice(-8192));
    } else {
      process.stderr.write("PSC2_DIRECT_RUST_OVERFLOW_DIAGNOSTIC_UNAVAILABLE\n");
    }
  }
  return requireSuccess(
    result,
    "PSC2_DIRECT_RUST_SELFHOST_" + stage + "_FAILED",
    binary,
    paths,
  );
}

await rm(outRoot, { recursive: true, force: true });
await mkdir(outRoot, { recursive: true });

phase("bootstrap-workspace");
requireSuccess(
  execute(process.execPath, [
    "scripts/bootstrap-project.mjs",
    path.relative(root, entryLean),
    path.relative(root, workspace),
  ]),
  "PSC2_DIRECT_RUST_SELFHOST_BOOTSTRAP_WORKSPACE_FAILED",
  process.execPath,
  ["scripts/bootstrap-project.mjs", path.relative(root, entryLean), path.relative(root, workspace)],
);

if (!existsSync(entryPs)) {
  throw new Error("PSC2_DIRECT_RUST_SELFHOST_ENTRY_MISSING");
}

phase("native-generation-1");
const nativeSuffix = process.platform === "win32" ? ".exe" : "";
const nativeCompiler = path.join(root, ".lake", "build", "bin", "psc1" + nativeSuffix);
const command = existsSync(nativeCompiler) ? nativeCompiler : "lake";
const prefix = existsSync(nativeCompiler) ? [] : ["exe", "psc1"];
const emitArgs = [
  ...prefix,
  "rust",
  path.relative(root, entryPs),
  "--out",
  path.relative(root, gen1),
];
requireSuccess(
  execute(command, emitArgs),
  "PSC2_DIRECT_RUST_SELFHOST_NATIVE_EMIT_FAILED",
  command,
  emitArgs,
);

phase("load-source-closure");
const closure = await readGeneratedSourceClosure(entryPs, workspace);
if (!closure || closure.ordered.length === 0) {
  throw new Error("PSC2_DIRECT_RUST_SELFHOST_CLOSURE_EMPTY");
}
const sourcePaths = closure.ordered.map(item => item.path);

const generation1 = await readFile(gen1);
phase("build-generation-1");
await writeCargoProject(generation1.toString("utf8"));
buildNative();

const generation2Text = runNative(sourcePaths, "compile-generation-2");
await writeFile(gen2, generation2Text, "utf8");
const generation2 = await readFile(gen2);
if (!bytesEqual(generation1, generation2)) {
  throw new Error("PSC2_DIRECT_RUST_SELFHOST_BOOTSTRAP_FIXED_POINT_MISMATCH");
}

phase("build-generation-2");
await writeFile(cargoLib, generation2);
buildNative();

const generation3Text = runNative(sourcePaths, "compile-generation-3");
await writeFile(gen3, generation3Text, "utf8");
const generation3 = await readFile(gen3);
if (!bytesEqual(generation2, generation3)) {
  throw new Error("PSC2_DIRECT_RUST_SELFHOST_SELF_FIXED_POINT_MISMATCH");
}

phase("fixed-point-complete");
process.stdout.write(
  [
    "PSC2_DIRECT_RUST_SELFHOST_FIXED_POINT: PASS",
    "compiler=" + path.relative(root, gen2),
    "modules=" + String(closure.ordered.length),
    "closureSha256=" + closure.closureSha256,
    "bytes=" + String(generation2.length),
  ].join("\n") + "\n",
);
