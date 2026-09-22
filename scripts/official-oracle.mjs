import { existsSync } from "node:fs";
import { spawnSync } from "node:child_process";
import { dirname, join, resolve } from "node:path";

const expected = "Lean (version 4.34.0, Release)";
const candidates = [
  process.env.LEAN434_BIN,
  "/mnt/data/work/lean4src/lean4-4.34.0/build/release/stage1/bin",
].filter(Boolean).map((p) => resolve(p));

const bin = candidates.find((p) => existsSync(join(p, "lean")) && existsSync(join(p, "leanchecker")));
if (!bin) {
  console.error("official-oracle: SKIP/FAIL: set LEAN434_BIN to a Lean 4.34.0 bin directory containing lean and leanchecker");
  process.exit(2);
}

const env = { ...process.env, PATH: `${bin}:${process.env.PATH ?? ""}` };
const run = (exe, args, timeout = 15000) => spawnSync(join(bin, exe), args, {
  encoding: "utf8",
  env,
  timeout,
  cwd: dirname(bin),
});

const version = run("lean", ["--version"], 5000);
if (version.error || version.status !== 0) {
  console.error(`official-oracle: lean --version failed: ${version.error?.message ?? version.stderr}`);
  process.exit(1);
}
const actual = version.stdout.trim();
if (actual !== expected) {
  console.error(`official-oracle: version drift: expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  process.exit(1);
}

const modules = [
  "Init.Prelude",
  "Init.Data.Nat.Div.Basic",
  "Init.Data.Nat.Gcd",
  "Init.Data.Nat.Bitwise.Basic",
];
for (const mod of modules) {
  const checker = run("leanchecker", ["--fresh", mod], 20000);
  if (checker.error?.code === "ETIMEDOUT") {
    console.error(`official-oracle: leanchecker ${mod} timed out`);
    process.exit(1);
  }
  if (checker.error || checker.status !== 0) {
    console.error(`official-oracle: leanchecker ${mod} failed: ${checker.error?.message ?? checker.stderr}`);
    process.exit(1);
  }
}

console.log(`official-oracle: PASS (${actual}; ${modules.length} fresh-module replays)`);
