import {
  allowedBootstrapPackageNames,
  forbiddenBootstrapPackageNames,
  bootstrapPackageViolation,
  assertBootstrapPackageAllowed,
  assertBootstrapPolicyWellFormed,
} from "./bootstrap-closure-contract.mjs";

function assert(condition, message) {
  if (!condition) throw new Error(`PSC2_BOOTSTRAP_CONTRACT_TEST: ${message}`);
}

function assertThrowsWithPrefix(action, prefix, label) {
  try {
    action();
  } catch (error) {
    assert(
      error instanceof Error && error.message.startsWith(prefix),
      `${label}: unexpected error ${error instanceof Error ? error.message : String(error)}`,
    );
    return;
  }
  throw new Error(`PSC2_BOOTSTRAP_CONTRACT_TEST: ${label}: expected rejection`);
}

const expectedAllowed = [
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
];
const expectedForbidden = [
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
];

assertBootstrapPolicyWellFormed();
assert(
  JSON.stringify(allowedBootstrapPackageNames) === JSON.stringify(expectedAllowed),
  "allowed package policy drifted",
);
assert(
  JSON.stringify(forbiddenBootstrapPackageNames) === JSON.stringify(expectedForbidden),
  "forbidden package policy drifted",
);

for (const packageName of expectedAllowed) {
  assert(
    bootstrapPackageViolation(packageName) === undefined,
    `allowed package rejected: ${packageName}`,
  );
  assertBootstrapPackageAllowed(packageName);
}

for (const packageName of expectedForbidden) {
  const expectedPrefix = `PSC2_BOOTSTRAP_FORBIDDEN_PACKAGE: ${packageName}`;
  assert(
    bootstrapPackageViolation(packageName) === expectedPrefix,
    `forbidden package classified incorrectly: ${packageName}`,
  );
  assertThrowsWithPrefix(
    () => assertBootstrapPackageAllowed(packageName),
    expectedPrefix,
    `forbidden package accepted: ${packageName}`,
  );
}

for (const packageName of ["backend-php", "language-service", "unknown"] ) {
  const expectedPrefix = `PSC2_BOOTSTRAP_UNAPPROVED_PACKAGE: ${packageName}`;
  assert(
    bootstrapPackageViolation(packageName) === expectedPrefix,
    `unknown package classified incorrectly: ${packageName}`,
  );
  assertThrowsWithPrefix(
    () => assertBootstrapPackageAllowed(packageName),
    expectedPrefix,
    `unknown package accepted: ${packageName}`,
  );
}

process.stdout.write(
  `PSC2_BOOTSTRAP_CLOSURE_CONTRACT: PASS (${expectedAllowed.length} allowed; ${expectedForbidden.length} forbidden)\n`,
);
