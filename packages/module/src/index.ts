export {
  canonicalJson,
  normalizeDeclarationStream,
} from './canonical.js';
export {
  createCheckedModuleArtifact,
  createModuleArtifact,
  decodeModuleArtifact,
  encodeModuleArtifact,
  loadModuleArtifact,
  moduleArtifactSummary,
  verifyModuleArtifact,
  verifyModuleDependencies,
} from './artifact.js';
export {
  CHECKED_MODULE_FORMAT_VERSION,
  DEFAULT_KERNEL,
  MODULE_FORMAT,
  MODULE_FORMAT_VERSION,
} from './artifact-types.js';
export type * from './artifact-types.js';
