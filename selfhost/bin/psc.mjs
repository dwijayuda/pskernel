#!/usr/bin/env node
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const binDir = path.dirname(fileURLToPath(import.meta.url));
const selfhostRoot = path.resolve(binDir, "..");
const node = process.execPath;
const npm = process.platform === "win32" ? "npm.cmd" : "npm";

function run(command, args) {
  const result = spawnSync(command, args, {
    cwd: selfhostRoot,
    stdio: "inherit",
  });
  if (result.error) throw result.error;
  process.exitCode = result.status ?? 1;
}

function usage() {
  return [
    "ProofScript self-host CLI",
    "",
    "usage:",
    "  psc bootstrap",
    "  psc build <entry.ps> --out <output.ts> [--compiler <compiler.js>]",
    "  psc selfhost",
    "  psc verify-selfhost",
    "  psc fixed-point",
    "",
    "defaults:",
    "  compiler: dist/bootstrap/compiler.js",
    "  self-host source: dist/bootstrap/workspace/SELFHOST-COMPILER.ps",
  ].join("\n");
}

const args = process.argv.slice(2);
const command = args[0];

if (!command || command === "--help" || command === "-h") {
  process.stdout.write(usage() + "\n");
} else if (command === "bootstrap") {
  run(npm, ["run", "bootstrap"]);
} else if (command === "selfhost") {
  run(npm, ["run", "selfhost"]);
} else if (command === "verify-selfhost") {
  run(npm, ["run", "verify:selfhost"]);
} else if (command === "fixed-point") {
  run(npm, ["run", "fixed-point"]);
} else if (command === "build") {
  const entry = args[1];
  const outIndex = args.indexOf("--out");
  const compilerIndex = args.indexOf("--compiler");
  const output = outIndex >= 0 ? args[outIndex + 1] : undefined;
  const compiler =
    compilerIndex >= 0
      ? args[compilerIndex + 1]
      : "dist/bootstrap/compiler.js";

  if (!entry || !output) {
    throw new Error(usage());
  }

  run(node, [
    "scripts/compile-with-generated.mjs",
    compiler,
    entry,
    output,
  ]);
} else {
  throw new Error(usage());
}
