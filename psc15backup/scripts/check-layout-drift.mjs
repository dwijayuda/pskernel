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
if (!(layout.packageBySection instanceof Map) || layout.packageBySection.size === 0) {
  throw new Error("PSC2_LAYOUT_SHARED_MAP_SHAPE");
}
// Preserve the established section assignments as well as checking new ones.
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
  ["BackendJs", "backend-js"],
  ["DriverTs", "driver-ts"],
  ["BackendRust", "backend-rust"],
  ["DriverRust", "driver-rust"],
  ["BackendWasm", "backend-wasm"],
]);

for (const [section, packageName] of expected) {
  if (layout.packageBySection?.get(section) !== packageName) {
    throw new Error(`PSC2_LAYOUT_SECTION_MISMATCH: ${section}`);
  }
}

const hostProjectCompiler = await readFile(
  path.join(root, "host", "src", "Ps", "Host", "ProjectCompiler.lean"),
  "utf8",
);
// Check the entire native resolver against the shared catalog. A hand-written
// expected subset let newly added package namespaces escape this comparison.
const nativeBody = hostProjectCompiler.match(
  /^def psHostPackageDirectory\b[\s\S]*?(?=^def |^partial def |$(?![\s\S]))/mu,
)?.[0];
if (!nativeBody) throw new Error("PSC2_LAYOUT_HOST_RESOLVER_MISSING");
const nativeEntries = [...nativeBody.matchAll(
  /^\s*\| "Ps" :: "([^"]+)" :: _ => some "([^"]+)"/gmu,
)].map(match => [match[1], match[2]]);
if (new Set(nativeEntries.map(([section]) => section)).size !== nativeEntries.length) {
  throw new Error("PSC2_LAYOUT_HOST_DUPLICATE_SECTION");
}
const ordered = entries => [...entries].sort(([left], [right]) => left.localeCompare(right));
if (JSON.stringify(ordered(nativeEntries)) !== JSON.stringify(ordered(layout.packageBySection))) {
  throw new Error("PSC2_LAYOUT_HOST_CATALOG_MISMATCH");
}

process.stdout.write(
  `PSC2_LAYOUT_DRIFT: PASS (${layout.packageBySection.size} module sections; ${consumers.length} consumers)\n`,
);
