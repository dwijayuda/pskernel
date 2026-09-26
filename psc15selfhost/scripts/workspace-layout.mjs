export const packageBySection = new Map([
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
