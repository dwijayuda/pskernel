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

const closureTests = '\n#[cfg(test)] mod closure_regressions {\n' +
  '  use super::*;\n' +
  '  #[test] fn captured_closures_are_owned_and_reusable() {\n' +
  '    let direct = makeAdder(PsNat::from(2u8));\n' +
  '    assert_eq!(direct(PsNat::from(40u8)), PsNat::from(42u8));\n' +
  '    assert_eq!(direct(PsNat::from(1u8)), PsNat::from(3u8));\n' +
  '    let via_let = makeAdderViaLet(PsNat::from(2u8));\n' +
  '    assert_eq!(via_let(PsNat::from(40u8)), PsNat::from(42u8));\n' +
  '    let forwarded = returnCallback(direct.clone());\n' +
  '    assert_eq!(forwarded(PsNat::from(5u8)), PsNat::from(7u8));\n' +
  '    assert_eq!(sharedCapture(PsNat::from(2u8), PsNat::from(40u8)), PsNat::from(46u8));\n' +
  '    assert_eq!(globalCallback(PsNat::from(42u8)), PsNat::from(42u8));\n' +
  '    assert_eq!(conditionalCallback(true, PsNat::from(42u8)), PsNat::from(42u8));\n' +
  '    assert_eq!(conditionalCallback(false, PsNat::from(4u8)), PsNat::from(0u8));\n' +
  '  }\n}\n';
await writeFile(path.join(srcDir, "lib.rs"), rustSource + closureTests, "utf8");
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
run("cargo", ["test", "--quiet"], { cwd: outRoot });
process.stdout.write(
  "PSC2_RUST_BACKEND_CARGO_CHECK: PASS\n" +
  "bytes=" + String(Buffer.byteLength(rustSource, "utf8")) + "\n",
);
