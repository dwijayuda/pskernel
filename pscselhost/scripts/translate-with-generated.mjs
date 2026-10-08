import { readFile, writeFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const selfhostRoot = path.resolve(scriptDir, "..");

function usage() {
  return [
    "usage:",
    "  node scripts/translate-with-generated.mjs <compiler.js> <input.lean|input.ps> --to <lean|ps> [--out <output>]",
  ].join("\n");
}

function exceptTag(value) {
  if (value === null || typeof value !== "object") return undefined;
  for (const symbol of Object.getOwnPropertySymbols(value)) {
    const tag = value[symbol];
    if (tag === "ok" || tag === "error") return tag;
  }
  return undefined;
}

function unwrapExcept(value) {
  const tag = exceptTag(value);
  if (tag === "ok") return value.value;
  if (tag === "error") {
    throw new Error(
      `PSC1_TRANSLATE_FAILED: ${JSON.stringify(value.error)}`,
    );
  }
  throw new Error("PSC1_TRANSLATE_RESULT_SHAPE");
}

function sourceKind(compiler, value) {
  if (value === "lean" || value === ".lean") {
    return compiler.PsCompilerSourceKind.lean;
  }
  if (value === "ps" || value === ".ps" || value === "proofscript") {
    return compiler.PsCompilerSourceKind.proofScript;
  }
  throw new Error(`PSC1_TRANSLATE_KIND: ${value}`);
}

if (process.argv.length < 6) {
  throw new Error(usage());
}

const compilerPath = path.resolve(selfhostRoot, process.argv[2]);
const inputPath = path.resolve(selfhostRoot, process.argv[3]);
const toIndex = process.argv.indexOf("--to");
const outIndex = process.argv.indexOf("--out");
const targetText = toIndex >= 0 ? process.argv[toIndex + 1] : undefined;
const outputPath =
  outIndex >= 0
    ? path.resolve(selfhostRoot, process.argv[outIndex + 1])
    : undefined;

if (!existsSync(compilerPath)) {
  throw new Error(`PSC1_TRANSLATE_COMPILER_MISSING: ${compilerPath}`);
}
if (!targetText) throw new Error(usage());

const compiler = await import(pathToFileURL(compilerPath).href);
if (
  !("PsCompilerSourceKind" in compiler) ||
  !("psCompilerTranslateSource" in compiler)
) {
  throw new Error("PSC1_TRANSLATE_COMPILER_API_MISSING");
}

const inputKind = inputPath.endsWith(".lean")
  ? sourceKind(compiler, "lean")
  : inputPath.endsWith(".ps")
    ? sourceKind(compiler, "ps")
    : (() => { throw new Error(`PSC1_TRANSLATE_SOURCE_KIND: ${inputPath}`); })();
const targetKind = sourceKind(compiler, targetText);
const source = await readFile(inputPath, "utf8");
const translated = unwrapExcept(
  compiler.psCompilerTranslateSource(inputKind, targetKind, source),
);

if (outputPath) {
  await writeFile(outputPath, translated, "utf8");
  process.stdout.write(
    `PSC1_TRANSLATE: ${path.relative(selfhostRoot, inputPath)} -> ${path.relative(selfhostRoot, outputPath)}\n`,
  );
} else {
  process.stdout.write(translated);
}
