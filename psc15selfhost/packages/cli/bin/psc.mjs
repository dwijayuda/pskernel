#!/usr/bin/env node
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const binDir = path.dirname(fileURLToPath(import.meta.url));
const selfhostRoot = path.resolve(binDir, "../../..");
const node = process.execPath;
const npm = process.platform === "win32" ? "npm.cmd" : "npm";
const defaultCompiler = "dist/bootstrap/packages/compiler/index.js";
const defaultWorkspace = "dist/bootstrap/workspace";
const defaultGeneration = "dist/selfhost";

function run(command, args) {
  const result = spawnSync(command, args, {
    cwd: selfhostRoot,
    stdio: "inherit",
  });
  if (result.error) throw result.error;
  process.exitCode = result.status ?? 1;
}

function option(args, name) {
  const index = args.indexOf(name);
  return index >= 0 ? args[index + 1] : undefined;
}

function usage() {
  return [
    "PSCV compiler CLI",
    "",
    "usage:",
    "  psc bootstrap",
    "  psc build <entry.lean|entry.ps> --out <output.js|output.ts|output.wasm|output.rs> [--backend typescript|javascript|wasm|rust] [--products source|executable|metadata|declarations|source-map|declaration-map|linked|all] [--js-representation closed|uniform] [--wasm-exports <selection.json>] [--compiler <compiler.js> | --seed <binary>] [--kernel <provider>] [--security-profile <profile>] [--archive-max-bytes <n>] [--archive-max-total-bytes <n>]",
    "  psc build-unchecked <entry.lean|entry.ps> --out <output.js|output.ts> [--compiler <compiler.js>]  # bootstrap/internal",
    "  psc translate <input.lean|input.ps> --to <lean|ps> [--out <output>] [--compiler <compiler.js>]",
    "  psc emit-lean <input.lean|input.ps> [--out <output.lean>] [--compiler <compiler.js>]",
    "  psc emit-ps <input.lean|input.ps> [--out <output.ps>] [--compiler <compiler.js>]",
    "  psc project emit <entry.lean|entry.ps> --to <lean|ps> --out <workspace> [--compiler <compiler.js>]",
    "  psc selfhost [--compiler <compiler.js>] [--workspace <ps-workspace>] [--out <generation>] [--emit-lean]",
    "  psc verify-selfhost",
    "  psc fixed-point",
    "",
    "defaults:",
    "  build: native checked compiler (prepare with npm run build:hosted)",
    `  legacy translation/selfhost compiler: ${defaultCompiler}`,
    `  workspace: ${defaultWorkspace}`,
    `  next generation: ${defaultGeneration}`,
  ].join("\n");
}

const args = process.argv.slice(2);
const command = args[0];

if (!command || command === "--help" || command === "-h") {
  process.stdout.write(usage() + "\n");
} else if (command === "bootstrap") {
  run(npm, ["run", "bootstrap"]);
} else if (command === "selfhost") {
  const compiler = option(args, "--compiler") ?? defaultCompiler;
  const workspace = option(args, "--workspace") ?? defaultWorkspace;
  const output = option(args, "--out") ?? defaultGeneration;
  const selfhostArgs = [
    "scripts/selfhost-generation.mjs",
    compiler,
    workspace,
    output,
  ];
  if (args.includes("--emit-lean")) selfhostArgs.push("--emit-lean");
  run(node, selfhostArgs);
} else if (command === "verify-selfhost") {
  run(npm, ["run", "verify:selfhost"]);
} else if (command === "fixed-point") {
  run(npm, ["run", "fixed-point"]);
} else if (command === "build") {
  const entry = args[1];
  if (!entry || entry.startsWith("--") || !args.includes("--out")) throw new Error(usage());
  // The checked builder owns option validation and provider-specific defaults.
  // Forward the explicit request intact instead of supplying a bootstrap module.
  run(node, ["scripts/checked-build.mjs", ...args.slice(1)]);
} else if (command === "build-unchecked") {
  const entry = args[1];
  const output = option(args, "--out");
  const compiler = option(args, "--compiler") ?? defaultCompiler;
  if (!entry || !output) throw new Error(usage());
  run(node, ["scripts/compile-with-generated.mjs", compiler, entry, output]);
} else if (command === "project" && args[1] === "emit") {
  const entry = args[2];
  const target = option(args, "--to");
  const output = option(args, "--out");
  const compiler = option(args, "--compiler") ?? defaultCompiler;

  if (!entry || !target || !output) throw new Error(usage());

  run(node, [
    "scripts/emit-project-with-generated.mjs",
    compiler,
    entry,
    "--to",
    target,
    "--out",
    output,
  ]);
} else if (command === "translate") {
  const input = args[1];
  const target = option(args, "--to");
  const output = option(args, "--out");
  const compiler = option(args, "--compiler") ?? defaultCompiler;

  if (!input || !target) throw new Error(usage());

  const translateArgs = [
    "scripts/translate-with-generated.mjs",
    compiler,
    input,
    "--to",
    target,
  ];
  if (output) translateArgs.push("--out", output);
  run(node, translateArgs);
} else if (command === "emit-lean" || command === "emit-ps") {
  const input = args[1];
  const output = option(args, "--out");
  const compiler = option(args, "--compiler") ?? defaultCompiler;
  if (!input) throw new Error(usage());

  const translateArgs = [
    "scripts/translate-with-generated.mjs",
    compiler,
    input,
    "--to",
    command === "emit-lean" ? "lean" : "ps",
  ];
  if (output) translateArgs.push("--out", output);
  run(node, translateArgs);
} else {
  throw new Error(usage());
}
