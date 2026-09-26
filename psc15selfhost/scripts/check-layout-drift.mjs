import { existsSync } from "node:fs";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const layoutPath = path.join(scriptDir, "workspace-layout.mjs");

if (!existsSync(layoutPath)) {
  throw new Error("PSC2_LAYOUT_SHARED_MODULE_MISSING: scripts/workspace-layout.mjs");
}

const consumers = [
  "bootstrap-project.mjs",
  "compile-with-generated.mjs",
  "emit-project-with-generated.mjs",
  "check-bootstrap-closure.mjs",
];

for (const name of consumers) {
  const source = await readFile(path.join(scriptDir, name), "utf8");
  if (/const\s+packageBySection\s*=\s*new\s+Map/u.test(source)) {
    throw new Error(`PSC2_LAYOUT_DUPLICATE_PACKAGE_MAP: scripts/${name}`);
  }
  if (!source.includes("./workspace-layout.mjs")) {
    throw new Error(`PSC2_LAYOUT_SHARED_IMPORT_MISSING: scripts/${name}`);
  }
}

const layout = await import(pathToFileURL(layoutPath).href);
const expected = new Map([
  ["Bootstrap", "bootstrap"],
  ["Foundation", "foundation"],
  ["Syntax", "syntax"],
  ["Core", "core"],
  ["Environment", "environment"],
  ["Project", "project"],
  ["Meta", "meta"],
  ["Elab", "elab"],
  ["Bridge", "bridge"],
  ["CompilerIr", "compiler-ir"],
  ["Compiler", "compiler"],
  ["Erasure", "erasure"],
  ["BackendTs", "backend-ts"],
  ["BackendRust", "backend-rust"],
  ["BackendWasm", "backend-wasm"],
]);

for (const [section, packageName] of expected) {
  if (layout.packageBySection?.get(section) !== packageName) {
    throw new Error(`PSC2_LAYOUT_SECTION_MISMATCH: ${section}`);
  }
}

process.stdout.write(
  `PSC2_LAYOUT_DRIFT: PASS (${expected.size} module sections; ${consumers.length} consumers)\n`,
);
