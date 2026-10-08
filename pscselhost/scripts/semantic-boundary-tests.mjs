import {
  assertSemanticBoundary,
  semanticBoundaryViolations,
} from "./semantic-boundaries.mjs";

function assert(condition, message) {
  if (!condition) throw new Error(`PSC2_SEMANTIC_BOUNDARY_TEST: ${message}`);
}

function assertHas(path, source, violation, label) {
  const violations = semanticBoundaryViolations(path, source);
  assert(
    violations.includes(violation),
    `${label}: expected ${violation}, got ${violations.join(", ") || "none"}`,
  );
}

assertHas(
  "packages/compiler/src/Ps/Compiler/Api.lean",
  "import Ps.BackendTs.Compiler\n",
  "PSC2_SEMANTIC_BOUNDARY_COMPILER_IMPORTS_BACKEND",
  "semantic compiler imported a backend",
);

assertHas(
  "packages/backend-ts/src/Ps/BackendTs/Compiler.lean",
  "import Ps.Erasure.Definition\ndef bad := psEraseCoreModule env declarations\n",
  "PSC2_SEMANTIC_BOUNDARY_DIRECT_CORE_ERASURE",
  "backend directly erased elaborated core",
);

assertHas(
  "host/src/Ps/Host/CompilerDriver.lean",
  "def bad := psEraseCoreModule env declarations\n",
  "PSC2_SEMANTIC_BOUNDARY_BACKEND_HOST_LOW_LEVEL_ERASURE",
  "host bypassed semantic compiler erasure ownership",
);

assertHas(
  "packages/compiler/src/Ps/Compiler/Api.lean",
  "import Ps.Erasure.Definition\ndef psCompilerVerifiedIrFromPrepared := psEraseCoreModule env declarations\n",
  "PSC2_SEMANTIC_BOUNDARY_ERASURE_WITHOUT_ADMISSION_VALIDATION",
  "compiler erased without validating the prepared admissions",
);

assertSemanticBoundary(
  "packages/compiler/src/Ps/Compiler/Api.lean",
  [
    "import Ps.Erasure.Definition",
    "def psCompilerValidatePrepared := true",
    "def psCompilerVerifiedIrFromPrepared :=",
    "  if psCompilerValidatePrepared then psEraseCoreModule env declarations else error",
  ].join("\n"),
);

assertSemanticBoundary(
  "packages/backend-rust/src/Ps/BackendRust/Compiler.lean",
  [
    "import Ps.Compiler.Api",
    "def emit prepared :=",
    "  match psCompilerVerifiedIrFromPrepared prepared with",
    "  | Except.ok ir => psRustEmitModule ir",
  ].join("\n"),
);

assertSemanticBoundary(
  "packages/erasure/src/Ps/Erasure/Definition.lean",
  "def psEraseCoreModule env declarations := declarations\n",
);

process.stdout.write("PSC2_SEMANTIC_BOUNDARY_CONTRACT: PASS\n");
