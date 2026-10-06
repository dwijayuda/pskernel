import { existsSync } from "node:fs";
import { mkdir, readFile, rm, writeFile } from "node:fs/promises";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath, pathToFileURL } from "node:url";
import { readGeneratedSourceClosure } from "./selfhost-source-workspace.mjs";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const outRoot = path.join(root, "dist", "direct-js-selfhost");
const workspace = path.join(outRoot, "workspace");
const entryLean = path.join(
  root,
  "packages",
  "bootstrap",
  "src",
  "Ps",
  "Bootstrap",
  "SelfHostJs.lean",
);
const entryPs = path.join(
  workspace,
  "packages",
  "bootstrap",
  "src",
  "Ps",
  "Bootstrap",
  "SelfHostJs.ps",
);
const generation1 = path.join(outRoot, "compiler.gen1.js");
const generation2 = path.join(outRoot, "compiler.gen2.js");
const generation3 = path.join(outRoot, "compiler.gen3.js");

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: root,
    encoding: "utf8",
    maxBuffer: 256 * 1024 * 1024,
    ...options,
  });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(
      [
        "PSC2_DIRECT_JS_SELFHOST_COMMAND_FAILED",
        command + " " + args.join(" "),
        result.stdout,
        result.stderr,
      ].filter(Boolean).join("\n"),
    );
  }
  return result.stdout ?? "";
}

function stripImports(source) {
  return source
    .split(/\r?\n/u)
    .filter((line) => !/^\s*import\s+[A-Za-z0-9_.]+\s*;?\s*$/u.test(line))
    .join("\n")
    .trim();
}

function printable(value) {
  try {
    return JSON.stringify(
      value,
      (_key, item) => typeof item === "bigint" ? item.toString() + "n" : item,
      2,
    );
  } catch {
    return String(value);
  }
}

function unwrapDirectExcept(value, stage) {
  if (value === null || typeof value !== "object") {
    throw new Error("PSC2_DIRECT_JS_SELFHOST_" + stage + "_RESULT_SHAPE");
  }
  const tag = value["$ps$tag"];
  const fields = value["$ps$fields"];
  if (tag === "ok" && fields && typeof fields === "object") {
    if ("value" in fields) return fields.value;
    const values = Object.values(fields);
    if (values.length === 1) return values[0];
  }
  if (tag === "error") {
    throw new Error(
      "PSC2_DIRECT_JS_SELFHOST_" + stage + "_FAILED: " + printable(fields),
    );
  }
  throw new Error(
    "PSC2_DIRECT_JS_SELFHOST_" + stage + "_RESULT_SHAPE: " + printable(value),
  );
}

async function loadCompiler(file, generation) {
  const module = await import(
    pathToFileURL(file).href + "?generation=" + String(generation)
  );
  if (typeof module.psCompilerJavaScriptProofScriptSource !== "function") {
    throw new Error(
      "PSC2_DIRECT_JS_SELFHOST_COMPILER_API_MISSING: psCompilerJavaScriptProofScriptSource",
    );
  }
  return module;
}

async function compileWith(compiler, source, stage) {
  const result = compiler.psCompilerJavaScriptProofScriptSource(source);
  const output = unwrapDirectExcept(result, stage);
  if (typeof output !== "string" || output.length === 0) {
    throw new Error("PSC2_DIRECT_JS_SELFHOST_" + stage + "_EMPTY");
  }
  return output;
}

await rm(outRoot, { recursive: true, force: true });
await mkdir(outRoot, { recursive: true });

run(process.execPath, [
  "scripts/bootstrap-project.mjs",
  path.relative(root, entryLean),
  path.relative(root, workspace),
]);

if (!existsSync(entryPs)) {
  throw new Error("PSC2_DIRECT_JS_SELFHOST_ENTRY_MISSING");
}

const nativeSuffix = process.platform === "win32" ? ".exe" : "";
const nativeCompiler = path.join(root, ".lake", "build", "bin", "psc1" + nativeSuffix);
const nativeCommand = existsSync(nativeCompiler) ? nativeCompiler : "lake";
const nativeArgs = existsSync(nativeCompiler)
  ? ["javascript", path.relative(root, entryPs)]
  : ["exe", "psc1", "javascript", path.relative(root, entryPs)];
const generation1Source = run(nativeCommand, nativeArgs);
if (generation1Source.length === 0) {
  throw new Error("PSC2_DIRECT_JS_SELFHOST_NATIVE_EMPTY");
}
await writeFile(generation1, generation1Source, "utf8");

const closure = await readGeneratedSourceClosure(entryPs, workspace);
if (!closure || closure.ordered.length === 0) {
  throw new Error("PSC2_DIRECT_JS_SELFHOST_CLOSURE_EMPTY");
}
const flattenedSource =
  closure.ordered
    .map((item) => stripImports(item.source))
    .filter((source) => source.length > 0)
    .join("\n\n") + "\n";

const compiler1 = await loadCompiler(generation1, 1);
const generation2Source = await compileWith(
  compiler1,
  flattenedSource,
  "GENERATION_2",
);
await writeFile(generation2, generation2Source, "utf8");

if (generation1Source !== generation2Source) {
  throw new Error("PSC2_DIRECT_JS_SELFHOST_BOOTSTRAP_FIXED_POINT_MISMATCH");
}

const compiler2 = await loadCompiler(generation2, 2);
const generation3Source = await compileWith(
  compiler2,
  flattenedSource,
  "GENERATION_3",
);
await writeFile(generation3, generation3Source, "utf8");

if (generation2Source !== generation3Source) {
  throw new Error("PSC2_DIRECT_JS_SELFHOST_SELF_FIXED_POINT_MISMATCH");
}

process.stdout.write(
  [
    "PSC2_DIRECT_JS_SELFHOST_FIXED_POINT: PASS",
    "compiler=" + path.relative(root, generation2),
    "modules=" + String(closure.ordered.length),
    "closureSha256=" + closure.closureSha256,
    "bytes=" + String(Buffer.byteLength(generation2Source, "utf8")),
  ].join("\n") + "\n",
);
