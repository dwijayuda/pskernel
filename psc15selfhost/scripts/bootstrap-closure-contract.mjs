export const allowedBootstrapPackageNames = Object.freeze([
  "bootstrap",
  "foundation",
  "syntax",
  "core",
  "environment",
  "meta",
  "elab",
  "bridge",
  "compiler-ir",
  "erasure",
  "compiler",
  "backend-ts",
  "driver-ts",
]);

export const forbiddenBootstrapPackageNames = Object.freeze([
  "stdlib",
  "project",
  "backend-js",
  "backend-rust",
  "driver-rust",
  "backend-wasm",
  "pskernel",
  "pskernel-core",
  "pskernel-core.old3",
  "pskernel-lean",
  "pskernel-lean-wasm",
]);

export const allowedBootstrapPackages = new Set(allowedBootstrapPackageNames);
export const forbiddenBootstrapPackages = new Set(forbiddenBootstrapPackageNames);

export function bootstrapPackageViolation(packageName) {
  if (forbiddenBootstrapPackages.has(packageName)) {
    return `PSC2_BOOTSTRAP_FORBIDDEN_PACKAGE: ${packageName}`;
  }
  if (!allowedBootstrapPackages.has(packageName)) {
    return `PSC2_BOOTSTRAP_UNAPPROVED_PACKAGE: ${packageName}`;
  }
  return undefined;
}

export function assertBootstrapPackageAllowed(packageName) {
  const violation = bootstrapPackageViolation(packageName);
  if (violation) throw new Error(violation);
}

export function assertBootstrapPolicyWellFormed() {
  if (allowedBootstrapPackageNames.length !== allowedBootstrapPackages.size) {
    throw new Error("PSC2_BOOTSTRAP_POLICY_DUPLICATE_ALLOWED_PACKAGE");
  }
  if (forbiddenBootstrapPackageNames.length !== forbiddenBootstrapPackages.size) {
    throw new Error("PSC2_BOOTSTRAP_POLICY_DUPLICATE_FORBIDDEN_PACKAGE");
  }
  for (const packageName of forbiddenBootstrapPackages) {
    if (allowedBootstrapPackages.has(packageName)) {
      throw new Error(`PSC2_BOOTSTRAP_POLICY_CONFLICT: ${packageName}`);
    }
  }
  if (!allowedBootstrapPackages.has("bootstrap")) {
    throw new Error("PSC2_BOOTSTRAP_POLICY_MISSING_COMPOSITION_ROOT");
  }
  if (!allowedBootstrapPackages.has("backend-ts")) {
    throw new Error("PSC2_BOOTSTRAP_POLICY_MISSING_TYPESCRIPT_BACKEND");
  }
  if (!allowedBootstrapPackages.has("driver-ts")) {
    throw new Error("PSC2_BOOTSTRAP_POLICY_MISSING_TYPESCRIPT_DRIVER");
  }
  for (const packageName of [
    "stdlib",
    "project",
    "backend-js",
    "backend-rust",
    "driver-rust",
    "backend-wasm",
    "pskernel",
    "pskernel-lean",
    "pskernel-lean-wasm",
  ]) {
    if (!forbiddenBootstrapPackages.has(packageName)) {
      throw new Error(`PSC2_BOOTSTRAP_POLICY_MISSING_FORBIDDEN_PACKAGE: ${packageName}`);
    }
  }
}

assertBootstrapPolicyWellFormed();
