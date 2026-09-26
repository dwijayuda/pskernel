import { existsSync } from "node:fs";
import path from "node:path";

export const packageBySection = new Map([
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

export function parseImports(source) {
  const imports = [];
  for (const line of source.split(/\r?\n/u)) {
    const match = line.match(/^\s*import\s+([A-Za-z0-9_.]+)\s*;?\s*$/u);
    if (match) imports.push(match[1]);
  }
  return imports;
}

export function packageForModule(moduleName) {
  const parts = moduleName.split(".");
  if (parts[0] === "ProofScript") return "stdlib";
  if (parts[0] === "Ps" && parts.length >= 2) {
    return packageBySection.get(parts[1]);
  }
  return undefined;
}

export function moduleBaseCandidates(workspaceRoot, moduleName) {
  const parts = moduleName.split(".");
  if (parts[0] === "ProofScript") {
    return [
      path.join(workspaceRoot, "packages", "stdlib", "src", ...parts),
      path.join(workspaceRoot, "packages", "stdlib", ...parts),
      path.join(workspaceRoot, "stdlib", ...parts),
    ];
  }
  if (parts[0] === "Ps" && parts.length >= 2) {
    const packageName = packageForModule(moduleName);
    if (!packageName) {
      throw new Error(`PSC2_LAYOUT_UNKNOWN_PACKAGE: ${moduleName}`);
    }
    return [
      path.join(workspaceRoot, "packages", packageName, "src", ...parts),
    ];
  }
  return [path.join(workspaceRoot, ...parts)];
}

export function firstExisting(candidates) {
  for (const candidate of candidates) {
    if (existsSync(candidate)) return candidate;
  }
  return undefined;
}

export function resolveModuleSource(
  workspaceRoot,
  moduleName,
  preferredExtension,
  options = {},
) {
  if (preferredExtension !== ".lean" && preferredExtension !== ".ps") {
    throw new Error(
      `PSC2_LAYOUT_SOURCE_EXTENSION: ${preferredExtension}`,
    );
  }
  const allowAlternate = options.allowAlternate !== false;
  const bases = moduleBaseCandidates(workspaceRoot, moduleName);
  const preferred = firstExisting(
    bases.map((base) => base + preferredExtension),
  );
  if (preferred) return preferred;
  if (!allowAlternate) return undefined;

  const alternateExtension = preferredExtension === ".lean" ? ".ps" : ".lean";
  return firstExisting(
    bases.map((base) => base + alternateExtension),
  );
}

export function resolveCompilerModuleSource(workspaceRoot, moduleName) {
  const bases = moduleBaseCandidates(workspaceRoot, moduleName);
  const lean = firstExisting(bases.map((base) => base + ".lean"));
  const proofScript = firstExisting(bases.map((base) => base + ".ps"));

  if (lean && proofScript) {
    if (moduleName.startsWith("Ps.") || moduleName.startsWith("ProofScript.")) {
      return lean;
    }
    throw new Error(`PSC2_LAYOUT_SOURCE_AMBIGUITY: ${moduleName}`);
  }
  return lean ?? proofScript;
}
