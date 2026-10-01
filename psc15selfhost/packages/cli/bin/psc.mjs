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
    "ProofScript self-host CLI",
    "",
    "usage:",
    "  psc bootstrap",
    "  psc build <entry.lean|entry.ps> --out <output.js|output.ts> [--compiler <compiler.js>]",
    "  psc translate <input.lean|input.ps> --to <lean|ps> [--out <output>] [--compiler <compiler.js>]",
    "  psc emit-lean <input.lean|input.ps> [--out <output.lean>] [--compiler <compiler.js>]",
    "  psc emit-ps <input.lean|input.ps> [--out <output.ps>] [--compiler <compiler.js>]",
    "  psc project emit <entry.lean|entry.ps> --to <lean|ps> --out <workspace> [--compiler <compiler.js>]",
    "  psc selfhost [--compiler <compiler.js>] [--workspace <ps-workspace>] [--out <generation>]",
    "  psc verify-selfhost",
    "  psc fixed-point",
    "",
    "defaults:",
    `  compiler: ${defaultCompiler}`,
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
  run(node, [
    "scripts/selfhost-generation.mjs",
    compiler,
    workspace,
    output,
  ]);
} else if (command === "verify-selfhost") {
  run(npm, ["run", "verify:selfhost"]);
} else if (command === "fixed-point") {
  run(npm, ["run", "fixed-point"]);
} else if (command === "build") {
  const entry = args[1];
  const output = option(args, "--out");
  const compiler = option(args, "--compiler") ?? defaultCompiler;

  if (!entry || !output) throw new Error(usage());

  run(node, [
    "scripts/compile-with-generated.mjs",
    compiler,
    entry,
    output,
  ]);
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
