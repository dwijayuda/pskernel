import { createHash } from 'node:crypto';

const CLASSES = Object.freeze(['E0', 'E1', 'E2', 'E3', 'E4']);
const EXECUTION = Object.freeze(['U0', 'U1', 'U2']);
const NAME = /^(?:@[a-z0-9][a-z0-9._-]*\/)?[a-z0-9][a-z0-9._-]*$/u;
const PROFILE = /^[a-zA-Z0-9][a-zA-Z0-9._/-]*$/u;

function record(value, code) {
  if (value === null || typeof value !== 'object' || Array.isArray(value) ||
      (Object.getPrototypeOf(value) !== Object.prototype && Object.getPrototypeOf(value) !== null)) {
    throw new Error(code);
  }
  if (Reflect.ownKeys(value).some(key => typeof key !== 'string' ||
      !Object.hasOwn(Object.getOwnPropertyDescriptor(value, key), 'value'))) {
    throw new Error('PSCV_EXTENSION_ACCESSOR_OR_SYMBOL_DENIED');
  }
}
function distinctStrings(input, code, pattern) {
  if (!Array.isArray(input) || input.length > 64 || input.some(v => typeof v !== 'string' ||
       v.length === 0 || v.length > 128 || (pattern && !pattern.test(v))) ||
       new Set(input).size !== input.length) throw new Error(code);
  return Object.freeze([...input].sort());
}

/**
 * Descriptors are data, never executable authority. No caller-provided JS
 * function or import path is executed by this package. E5/E6/U3 are forbidden.
 * E1-E4 still require a separately implemented, isolated host and validators.
 */
export function validateExtensionManifest(value) {
  record(value, 'PSCV_EXTENSION_NOT_OBJECT');
  const fields = ['schemaVersion', 'id', 'version', 'semanticClass', 'executionClass',
    'apiVersion', 'entry', 'profiles', 'capabilities'];
  if (Object.keys(value).some(key => !fields.includes(key))) {
    throw new Error('PSCV_EXTENSION_UNKNOWN_FIELD');
  }
  if (value.schemaVersion !== 1 || value.apiVersion !== 'pscv-extension/1') {
    throw new Error('PSCV_EXTENSION_SCHEMA');
  }
  if (typeof value.id !== 'string' || value.id.length > 128 || !NAME.test(value.id) ||
      typeof value.version !== 'string' || !/^[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?$/u.test(value.version)) {
    throw new Error('PSCV_EXTENSION_IDENTITY');
  }
  if (!CLASSES.includes(value.semanticClass) || !EXECUTION.includes(value.executionClass)) {
    throw new Error('PSCV_EXTENSION_AUTHORITY_DENIED');
  }
  if (value.semanticClass === 'E0' && value.executionClass !== 'U0') {
    throw new Error('PSCV_LIBRARY_EXECUTION_FORBIDDEN');
  }
  if (value.semanticClass !== 'E0' && value.executionClass === 'U0') {
    throw new Error('PSCV_EXTENSION_EXECUTION_CLASS_REQUIRED');
  }
  if (value.executionClass === 'U0') {
    if (value.entry !== null) throw new Error('PSCV_EXTENSION_ENTRY_FORBIDDEN');
  } else if (typeof value.entry !== 'string' || !/^\.\/[a-zA-Z0-9_./-]+$/u.test(value.entry) ||
      value.entry.includes('..') || value.entry.includes('//') || value.entry.length > 256) {
    throw new Error('PSCV_EXTENSION_ENTRY_INVALID');
  }
  const profiles = distinctStrings(value.profiles, 'PSCV_EXTENSION_PROFILES', PROFILE);
  if (!profiles.length) throw new Error('PSCV_EXTENSION_PROFILES');
  const capabilities = distinctStrings(value.capabilities, 'PSCV_EXTENSION_CAPABILITIES', PROFILE);
  // This is a normalized data record; it confers no permissions to execute.
  return Object.freeze({
    schemaVersion: 1, id: value.id, version: value.version,
    semanticClass: value.semanticClass, executionClass: value.executionClass,
    apiVersion: 'pscv-extension/1', entry: value.entry,
    profiles, capabilities,
  });
}

export function selectExtensionSet({ available = [], enabled = [], profile } = {}) {
  if (typeof profile !== 'string' || !PROFILE.test(profile) ||
      !Array.isArray(available) || available.length > 128 ||
      !Array.isArray(enabled) || enabled.length > 128) {
    throw new Error('PSCV_EXTENSION_SET_INVALID');
  }
  const byId = new Map();
  for (const input of available) {
    const descriptor = validateExtensionManifest(input);
    if (byId.has(descriptor.id)) throw new Error('PSCV_EXTENSION_DUPLICATE_ID');
    byId.set(descriptor.id, descriptor);
  }
  const chosen = distinctStrings(enabled, 'PSCV_EXTENSION_ENABLED', NAME)
    .map(id => {
      const desc = byId.get(id);
      if (!desc) throw new Error('PSCV_EXTENSION_NOT_INSTALLED');
      if (!desc.profiles.includes(profile)) throw new Error('PSCV_EXTENSION_PROFILE_MISMATCH');
      // A closed PSCV source profile may not be extended with arbitrary syntax.
      if (profile !== 'ps-lean-extensible-0.9-r3' && desc.semanticClass === 'E1') {
        throw new Error('PSCV_CLOSED_PROFILE_SYNTAX_EXTENSION');
      }
      return desc;
    });
  const canonical = JSON.stringify({ contract: 'pscv-extension-set/1', profile, chosen });
  const fingerprint = createHash('sha256').update(canonical).digest('hex');
  return Object.freeze({
    contract: 'pscv-extension-set/1',
    profile,
    fingerprint,
    descriptors: Object.freeze(chosen),
    // **No activated extension code is loaded or run here.**
    executableExtensionsEnabled: false,
  });
}
