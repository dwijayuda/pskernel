function normalizedPath(relativePath) {
  return relativePath.replaceAll("\\", "/");
}

export function semanticBoundaryViolations(relativePath, source) {
  const file = normalizedPath(relativePath);
  const violations = [];
  const isCompiler = file.startsWith("packages/compiler/src/");
  const isErasure = file.startsWith("packages/erasure/src/");
  const isBackend = /^packages\/backend-[^/]+\/src\//u.test(file);
  const isDriver = /^packages\/driver-[^/]+\/src\//u.test(file);
  const isHost = file.startsWith("host/src/");
  const isProduction =
    /^packages\/[^/]+\/src\//u.test(file) ||
    isHost ||
    file.startsWith("stdlib/");

  if (!isProduction) return violations;

  if (isCompiler && /^\s*import\s+Ps\.Backend/mu.test(source)) {
    violations.push("PSC2_SEMANTIC_BOUNDARY_COMPILER_IMPORTS_BACKEND");
  }

  if (isBackend && /^\s*import\s+Ps\.Compiler(?:\.|\s|$)/mu.test(source)) {
    violations.push("PSC2_SEMANTIC_BOUNDARY_BACKEND_IMPORTS_COMPILER");
  }

  if (!isCompiler && !isErasure && /^\s*import\s+Ps\.Erasure(?:\.|\s|$)/mu.test(source)) {
    violations.push("PSC2_SEMANTIC_BOUNDARY_ERASURE_IMPORT_OWNER");
  }

  if (!isCompiler && !isErasure && /\bpsEraseCoreModule\b/u.test(source)) {
    violations.push("PSC2_SEMANTIC_BOUNDARY_DIRECT_CORE_ERASURE");
  }

  if ((isBackend || isDriver || isHost) && /\bpsErase(?:CoreModule|Definition|Expr|Inductive|Structure)\b/u.test(source)) {
    violations.push("PSC2_SEMANTIC_BOUNDARY_BACKEND_HOST_LOW_LEVEL_ERASURE");
  }

  if (isCompiler && /\bpsEraseCoreModule\b/u.test(source)) {
    if (!/\bpsCompilerValidatePrepared\b/u.test(source)) {
      violations.push("PSC2_SEMANTIC_BOUNDARY_ERASURE_WITHOUT_ADMISSION_VALIDATION");
    }
    if (!/\bpsCompilerErasedIrFromPrepared\b/u.test(source)) {
      violations.push("PSC2_SEMANTIC_BOUNDARY_ERASURE_WITHOUT_ERASED_IR_BOUNDARY");
    }
    if (!/\bpsValidateErasedIrModule\b/u.test(source)) {
      violations.push("PSC2_SEMANTIC_BOUNDARY_ERASURE_WITHOUT_IR_VALIDATION");
    }
    if (!/\bpsCompilerVerifiedIrFromPrepared\b/u.test(source)) {
      violations.push("PSC2_SEMANTIC_BOUNDARY_ERASURE_OUTSIDE_VERIFIED_IR_OWNER");
    }
  }

  if ((isBackend || isDriver) && /\bpsCompilerVerifiedIrFromPrepared\b/u.test(source)) {
    // A driver may consume VerifiedIR directly through one of the typed
    // validated target APIs, or advance it through the typed specialization
    // capability before a specialized target API. Merely mentioning a
    // specialized lowerer is insufficient: the same owner must perform the
    // VerifiedIR -> SpecializedIR transition explicitly.
    const consumesValidatedIr =
      /\b(?:psTsEmitValidatedModule|psRustEmitValidatedModule|psJsEmitValidatedModule|psJsEmitValidatedModuleWithTargetProfile|psJsEmitValidatedModuleStackSafeWithTargetProfile|psWasmLowerValidatedModule)\b/u.test(source);
    const consumesSpecializedIr =
      /\bpsIrSpecializeValidatedModule\b/u.test(source) &&
      /\b(?:psWasmLowerSpecializedValidatedModule)\b/u.test(source);
    if (!consumesValidatedIr && !consumesSpecializedIr) {
      violations.push("PSC2_SEMANTIC_BOUNDARY_BACKEND_BYPASSES_VALIDATED_IR");
    }
  }

  return violations;
}

export function assertSemanticBoundary(relativePath, source) {
  const violations = semanticBoundaryViolations(relativePath, source);
  if (violations.length > 0) {
    throw new Error(`${violations[0]}: ${normalizedPath(relativePath)}`);
  }
}
