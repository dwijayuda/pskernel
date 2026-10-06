import { mkdir, rm, writeFile } from "node:fs/promises";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const outRoot = path.join(root, "dist", "rust-backend-compile");
const srcDir = path.join(outRoot, "src");

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: root,
    encoding: "utf8",
    maxBuffer: 128 * 1024 * 1024,
    ...options,
  });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error([
      "PSC2_RUST_BACKEND_COMPILE_COMMAND_FAILED",
      command + " " + args.join(" "),
      result.stdout,
      result.stderr,
    ].filter(Boolean).join("\n"));
  }
  return result.stdout ?? "";
}

await rm(outRoot, { recursive: true, force: true });
await mkdir(srcDir, { recursive: true });

const rustSource = run("lake", ["exe", "psc1_backend_rust_fixture"]);
if (rustSource.length === 0) {
  throw new Error("PSC2_RUST_BACKEND_COMPILE_EMPTY");
}

await writeFile(path.join(srcDir, "lib.rs"), rustSource, "utf8");
await writeFile(
  path.join(outRoot, "Cargo.toml"),
  [
    "[package]",
    'name = "proofscript-rust-backend-compile"',
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

run("cargo", ["check", "--quiet"], { cwd: outRoot });
process.stdout.write(
  "PSC2_RUST_BACKEND_CARGO_CHECK: PASS\n" +
  "bytes=" + String(Buffer.byteLength(rustSource, "utf8")) + "\n",
);
