import { existsSync } from "node:fs";
import { mkdir, readFile, rm, writeFile } from "node:fs/promises";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { readGeneratedSourceClosure } from "./selfhost-source-workspace.mjs";

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

const compilerExport = "psCompilerWasm32ProofScriptBytesOrEmpty";
const stringNewExport = "__ps_selfhost_string_new";
const stringSetExport = "__ps_selfhost_string_set";
const bytesIsNilExport = "__ps_selfhost_bytes_is_nil";
const bytesHeadExport = "__ps_selfhost_bytes_head";
const bytesTailExport = "__ps_selfhost_bytes_tail";

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

function stripImports(source) {
  return source
    .split(/\r?\n/u)
    .filter((line) => !/^\s*import\s+[A-Za-z0-9_.]+\s*;?\s*$/u.test(line))
    .join("\n")
    .trim();
}

function requiredFunction(exports, name) {
  const value = exports[name];
  if (typeof value !== "function") {
    throw new Error("PSC2_DIRECT_WASM_SELFHOST_EXPORT_MISSING: " + name);
  }
  return value;
}

async function loadCompiler(bytes) {
  const module = await WebAssembly.compile(bytes);
  const instance = await WebAssembly.instantiate(module, {});
  const exports = instance.exports;
  return {
    compile: requiredFunction(exports, compilerExport),
    stringNew: requiredFunction(exports, stringNewExport),
    stringSet: requiredFunction(exports, stringSetExport),
    bytesIsNil: requiredFunction(exports, bytesIsNilExport),
    bytesHead: requiredFunction(exports, bytesHeadExport),
    bytesTail: requiredFunction(exports, bytesTailExport),
  };
}

function wasmString(api, text) {
  const chars = Array.from(text);
  const value = api.stringNew(chars.length);
  for (let index = 0; index < chars.length; index += 1) {
    const codePoint = chars[index].codePointAt(0);
    if (codePoint === undefined) {
      throw new Error("PSC2_DIRECT_WASM_SELFHOST_CODEPOINT");
    }
    api.stringSet(value, index, codePoint);
  }
  return value;
}

function byteList(api, value) {
  const bytes = [];
  let cursor = value;
  const maxBytes = 512 * 1024 * 1024;
  while (api.bytesIsNil(cursor) === 0) {
    if (bytes.length >= maxBytes) {
      throw new Error("PSC2_DIRECT_WASM_SELFHOST_OUTPUT_LIMIT");
    }
    const byte = api.bytesHead(cursor);
    if (!Number.isInteger(byte) || byte < 0 || byte > 255) {
      throw new Error(
        "PSC2_DIRECT_WASM_SELFHOST_BYTE_RANGE: " + String(byte),
      );
    }
    bytes.push(byte);
    cursor = api.bytesTail(cursor);
  }
  return Uint8Array.from(bytes);
}

function compileWith(api, source) {
  const sourceValue = wasmString(api, source);
  const output = byteList(api, api.compile(sourceValue));
  if (output.length === 0) {
    throw new Error("PSC2_DIRECT_WASM_SELFHOST_COMPILE_FAILED_OR_EMPTY");
  }
  return output;
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
run(nativeCommand, nativeArgs);

const closure = await readGeneratedSourceClosure(entryPs, workspace);
if (!closure || closure.ordered.length === 0) {
  throw new Error("PSC2_DIRECT_WASM_SELFHOST_CLOSURE_EMPTY");
}
const flattenedSource =
  closure.ordered
    .map((item) => stripImports(item.source))
    .filter((source) => source.length > 0)
    .join("\n\n") + "\n";

const generation1Bytes = new Uint8Array(await readFile(generation1));
const compiler1 = await loadCompiler(generation1Bytes);
const generation2Bytes = compileWith(compiler1, flattenedSource);
await writeFile(generation2, generation2Bytes);

if (!bytesEqual(generation1Bytes, generation2Bytes)) {
  throw new Error("PSC2_DIRECT_WASM_SELFHOST_BOOTSTRAP_FIXED_POINT_MISMATCH");
}

const compiler2 = await loadCompiler(generation2Bytes);
const generation3Bytes = compileWith(compiler2, flattenedSource);
await writeFile(generation3, generation3Bytes);

if (!bytesEqual(generation2Bytes, generation3Bytes)) {
  throw new Error("PSC2_DIRECT_WASM_SELFHOST_SELF_FIXED_POINT_MISMATCH");
}

process.stdout.write(
  [
    "PSC2_DIRECT_WASM_SELFHOST_FIXED_POINT: PASS",
    "compiler=" + path.relative(root, generation2),
    "modules=" + String(closure.ordered.length),
    "closureSha256=" + closure.closureSha256,
    "bytes=" + String(generation2Bytes.length),
  ].join("\n") + "\n",
);
