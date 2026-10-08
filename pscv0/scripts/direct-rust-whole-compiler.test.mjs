import { existsSync } from "node:fs";
import { mkdir, rm, writeFile } from "node:fs/promises";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const outRoot = path.join(root, "dist", "direct-rust-selfhost");
const workspace = path.join(outRoot, "workspace");
const entryLean = path.join(
  root, "packages", "bootstrap", "src", "Ps", "Bootstrap", "SelfHostRust.lean",
);
const entryPs = path.join(
  workspace, "packages", "bootstrap", "src", "Ps", "Bootstrap", "SelfHostRust.ps",
);
const generatedRust = path.join(outRoot, "compiler.gen1.rs");
const cargoRoot = path.join(outRoot, "cargo");
const cargoSrc = path.join(cargoRoot, "src");

function execute(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: root,
    encoding: "utf8",
    maxBuffer: 256 * 1024 * 1024,
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

await rm(outRoot, { recursive: true, force: true });
await mkdir(outRoot, { recursive: true });

requireSuccess(
  execute(process.execPath, [
    "scripts/bootstrap-project.mjs",
    path.relative(root, entryLean),
    path.relative(root, workspace),
  ]),
  "PSC2_DIRECT_RUST_BOOTSTRAP_WORKSPACE_FAILED",
  process.execPath,
  ["scripts/bootstrap-project.mjs", path.relative(root, entryLean), path.relative(root, workspace)],
);

if (!existsSync(entryPs)) {
  throw new Error("PSC2_DIRECT_RUST_ENTRY_MISSING");
}

const nativeSuffix = process.platform === "win32" ? ".exe" : "";
const nativeCompiler = path.join(root, ".lake", "build", "bin", "psc1" + nativeSuffix);
const command = existsSync(nativeCompiler) ? nativeCompiler : "lake";
const prefix = existsSync(nativeCompiler) ? [] : ["exe", "psc1"];

const coverageArgs = [...prefix, "rust-coverage", path.relative(root, entryPs)];
const coverageResult = execute(command, coverageArgs);
const coverage = requireSuccess(
  coverageResult,
  "PSC2_DIRECT_RUST_COVERAGE_COMMAND_FAILED",
  command,
  coverageArgs,
);
process.stdout.write(coverage);

const match = coverage.match(/PSC1_RUST_COVERAGE_UNSUPPORTED_COUNT:\s*(\d+)/u);
if (!match) {
  throw new Error("PSC2_DIRECT_RUST_COVERAGE_COUNT_MISSING");
}
process.stdout.write(
  "PSC2_DIRECT_RUST_WHOLE_COMPILER_UNSUPPORTED_COUNT: " + match[1] + "\n",
);

if (match[1] !== "0") {
  throw new Error(
    "PSC2_DIRECT_RUST_WHOLE_COMPILER_UNSUPPORTED: " + match[1],
  );
}

const emitArgs = [
  ...prefix,
  "rust",
  path.relative(root, entryPs),
  "--out",
  path.relative(root, generatedRust),
];
requireSuccess(
  execute(command, emitArgs),
  "PSC2_DIRECT_RUST_WHOLE_COMPILER_EMIT_FAILED",
  command,
  emitArgs,
);

await mkdir(cargoSrc, { recursive: true });
const rustSource = await import("node:fs/promises").then(fs => fs.readFile(generatedRust, "utf8"));
await writeFile(path.join(cargoSrc, "lib.rs"), rustSource, "utf8");
await writeFile(
  path.join(cargoRoot, "Cargo.toml"),
  [
    "[package]",
    'name = "proofscript-direct-rust-selfhost"',
    'version = "0.0.0"',
    'edition = "2021"',
    "",
    "[lib]",
    'path = "src/lib.rs"',
    "",
    "[dependencies]",
    'num-bigint = "0.4"',
    'num-traits = "0.2"',
    "",
  ].join("\n"),
  "utf8",
);

requireSuccess(
  execute("cargo", ["check", "--quiet"], {
    cwd: cargoRoot,
    env: { ...process.env, RUSTFLAGS: "-Awarnings" },
  }),
  "PSC2_DIRECT_RUST_WHOLE_COMPILER_CARGO_CHECK_FAILED",
  "cargo",
  ["check", "--quiet"],
);

process.stdout.write(
  [
    "PSC2_DIRECT_RUST_WHOLE_COMPILER: PASS",
    "rust=" + path.relative(root, generatedRust),
    "unsupported=" + match[1],
    "bytes=" + String(Buffer.byteLength(rustSource, "utf8")),
  ].join("\n") + "\n",
);
