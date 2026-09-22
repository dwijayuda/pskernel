/**
 * Stable public library surface for pskernel.
 *
 * Keep trusted implementation modules under src/core and src/kernel. Support
 * packages should depend on this façade (or the explicit lean4export/native
 * subpaths) instead of importing internal files directly.
 */
export { Environment, KernelError } from './core/environment.js';
export type {
  ConstantInfo,
  AxiomInfo,
  DefinitionInfo,
  TheoremInfo,
  OpaqueInfo,
  InductiveInfo,
  ConstructorInfo,
  RecursorInfo,
  RecursorRule,
  QuotInfo,
  DefinitionSafety,
  ReducibilityHints
} from './core/declaration.js';
export * from './core/name.js';
export * from './core/level.js';
export * from './core/expr.js';
export { LocalContext } from './core/local-context.js';

export { Kernel } from './kernel/kernel.js';
export { TypeChecker } from './kernel/type-checker.js';
export type { KernelLimits } from './kernel/type-checker.js';

export {
  Lean4ExportReplay
} from './integration/lean4export.js';
export type {
  Lean4ExportOptions,
  ReplayStats,
  ReplayProgressOptions
} from './integration/lean4export.js';

export type {
  NativeEvaluator,
  NativeEvaluationResult,
  NativeReductionKind
} from './kernel/reduction/native.js';
