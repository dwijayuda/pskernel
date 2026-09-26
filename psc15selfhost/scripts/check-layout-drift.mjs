import { existsSync } from "node:fs";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const layoutPath = path.join(scriptDir, "workspace-layout.mjs");

if (!existsSync(layoutPath)) {
  throw new Error("PSC2_LAYOUT_SHARED_MODULE_MISSING: scripts/workspace-layout.mjs");
}

const consumers = new Map([
  ["bootstrap-project.mjs", "resolveModuleSource"],
  ["compile-with-generated.mjs", "resolveCompilerModuleSource"],
  ["emit-project-with-generated.mjs", "resolveModuleSource"],
  ["check-bootstrap-closure.mjs", "resolveModuleSource"],
]);
const forbiddenLocalLayout = [
  /function\s+moduleBasePath\b/u,
  /function\s+moduleBaseCandidates\b/u,
  /function\s+moduleSourcePath\b/u,
  /function\s+firstExisting\b/u,
];

for (const [name, resolverName] of consumers) {
  const source = await readFile(path.join(scriptDir, name), "utf8");
  if (/const\s+packageBySection\s*=\s*new\s+Map/u.test(source)) {
    throw new Error(`PSC2_LAYOUT_DUPLICATE_PACKAGE_MAP: scripts/${name}`);
  }
  for (const pattern of forbiddenLocalLayout) {
    if (pattern.test(source)) {
      throw new Error(`PSC2_LAYOUT_DUPLICATE_RESOLVER: scripts/${name}`);
    }
  }
  if (!source.includes("./workspace-layout.mjs")) {
    throw new Error(`PSC2_LAYOUT_SHARED_IMPORT_MISSING: scripts/${name}`);
  }
  if (!source.includes(resolverName)) {
    throw new Error(
      `PSC2_LAYOUT_SHARED_RESOLVER_MISSING: scripts/${name}:${resolverName}`,
    );
  }
}

const layout = await import(pathToFileURL(layoutPath).href);
const expected = new Map([
  ["Bootstrap", "bootstrap"],
  ["Foundation", "foundation"],
  ["Syntax", "syntax"],
  ["Core", "core"],
  ["KernelCore", "pskernel-core"],
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

if (!(layout.packageBySection instanceof Map)) {
  throw new Error("PSC2_LAYOUT_PACKAGE_MAP_MISSING");
}
if (layout.packageBySection.size !== expected.size) {
  throw new Error(
    `PSC2_LAYOUT_SECTION_COUNT_MISMATCH: expected ${expected.size}, got ${layout.packageBySection.size}`,
  );
}
for (const [section, packageName] of expected) {
  if (layout.packageBySection.get(section) !== packageName) {
    throw new Error(`PSC2_LAYOUT_SECTION_MISMATCH: ${section}`);
  }
}
for (const exportName of [
  "packageForModule",
  "moduleBaseCandidates",
  "resolveModuleSource",
  "resolveCompilerModuleSource",
]) {
  if (typeof layout[exportName] !== "function") {
    throw new Error(`PSC2_LAYOUT_EXPORT_MISSING: ${exportName}`);
  }
}

const fixtureRoot = await mkdtemp(path.join(os.tmpdir(), "psc2-layout-"));
try {
  const userBase = path.join(fixtureRoot, "Demo", "Core");
  await mkdir(path.dirname(userBase), { recursive: true });
  await writeFile(userBase + ".lean", "def leanVersion : Nat := 1\n", "utf8");
  await writeFile(userBase + ".ps", "def psVersion : Nat := 1;\n", "utf8");

  let userAmbiguityRejected = false;
  try {
    layout.resolveCompilerModuleSource(fixtureRoot, "Demo.Core");
  } catch (error) {
    userAmbiguityRejected =
      error instanceof Error &&
      error.message === "PSC2_LAYOUT_SOURCE_AMBIGUITY: Demo.Core";
  }
  if (!userAmbiguityRejected) {
    throw new Error("PSC2_LAYOUT_USER_AMBIGUITY_NOT_REJECTED");
  }

  const coreBase = path.join(
    fixtureRoot,
    "packages",
    "core",
    "src",
    "Ps",
    "Core",
    "Expr",
  );
  await mkdir(path.dirname(coreBase), { recursive: true });
  await writeFile(coreBase + ".lean", "def leanCore : Nat := 1\n", "utf8");
  await writeFile(coreBase + ".ps", "def psCore : Nat := 1;\n", "utf8");

  const authoritative = layout.resolveCompilerModuleSource(
    fixtureRoot,
    "Ps.Core.Expr",
  );
  if (authoritative !== coreBase + ".lean") {
    throw new Error("PSC2_LAYOUT_AUTHORITATIVE_LEAN_NOT_PREFERRED");
  }

  const preferredPs = layout.resolveModuleSource(
    fixtureRoot,
    "Ps.Core.Expr",
    ".ps",
  );
  if (preferredPs !== coreBase + ".ps") {
    throw new Error("PSC2_LAYOUT_PROJECT_SOURCE_PREFERENCE_DRIFT");
  }
} finally {
  await rm(fixtureRoot, { recursive: true, force: true });
}

const hostResolverPath = path.join(
  root,
  "host",
  "src",
  "Ps",
  "Host",
  "ProjectCompiler.lean",
);
const hostResolver = await readFile(hostResolverPath, "utf8");
if (!hostResolver.includes('| "Ps" :: "KernelCore" :: _ => some "pskernel-core"')) {
  throw new Error("PSC2_LAYOUT_HOST_KERNEL_CORE_MAPPING_MISSING");
}

process.stdout.write(
  `PSC2_LAYOUT_DRIFT: PASS (${expected.size} module sections; ${consumers.size} shared-resolver consumers; ambiguity semantics; kernel-core host mapping)\n`,
);
