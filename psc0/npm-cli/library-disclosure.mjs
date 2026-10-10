// Source-library identity and disclosure, owned by the parent host.
// This records inputs; it cannot authorize proofs or execute package code.
import { createHash } from 'node:crypto';
import { freezeDataGraph } from './checked-session.mjs';
const hash = text => createHash('sha256').update(text).digest('hex');
const compare = (a, b) => a < b ? -1 : a > b ? 1 : 0;
const object = value => value !== null && typeof value === 'object' && !Array.isArray(value);

export function assertSourceOnlyConfiguration(config) {
  if (config === undefined) return;
  if (!object(config)) throw new Error('PSC_LIBRARY_PROJECT_POLICY');
  // There is no executable extension transport in this release. Never silently
  // accept a request for one, including an apparently empty configuration.
  if (Object.hasOwn(config, 'extensions')) throw new Error('PSC_EXECUTABLE_EXTENSIONS_UNSUPPORTED');
}
export function describeSourceLibrary(meta, mapping, manifest) {
  assertSourceOnlyConfiguration(meta.proofscript);
  const library = meta.proofscript?.library;
  if (!object(library) || library.schemaVersion !== 1 || library.modulePrefix !== mapping.namespace || library.sourceRoot !== 'src') throw new Error('PSC_LIBRARY_PACKAGE_MANIFEST: ' + mapping.packageName);
  for (const key of Object.keys(library)) {
    if (!['schemaVersion', 'modulePrefix', 'sourceRoot'].includes(key)) throw new Error('PSC_LIBRARY_UNSUPPORTED_MANIFEST_FIELD: ' + JSON.stringify(key));
  }
  if (typeof meta.version !== 'string' || !/^[0-9A-Za-z.+-]{1,128}$/u.test(meta.version)) throw new Error('PSC_LIBRARY_VERSION_IDENTITY');
  const scripts = meta.scripts ?? {};
  if (!object(scripts)) throw new Error('PSC_LIBRARY_SCRIPTS_SHAPE');
  const declaredScriptNames = Object.keys(scripts).sort(compare);
  if (declaredScriptNames.length > 128 || declaredScriptNames.some(n => n.length > 128 || typeof scripts[n] !== 'string')) throw new Error('PSC_LIBRARY_SCRIPTS_SHAPE');
  return freezeDataGraph({ packageName: mapping.packageName, version: meta.version, namespace: mapping.namespace, manifest: { ...manifest }, declaredScriptNames });
}
export function createLibraryDisclosure(declaredLibraries) {
  if (!Array.isArray(declaredLibraries) || declaredLibraries.length > 256) throw new Error('PSC_LIBRARY_COUNT_LIMIT');
  const declared = structuredClone(declaredLibraries).sort((a, b) => compare(a.namespace, b.namespace));
  const loaded = new Map();
  let sealed = false, moduleCount = 0;
  return Object.freeze({
    record(metadata, moduleName, sourceKind, sourceEvidence) {
      if (sealed) throw new Error('PSC_LIBRARY_DISCLOSURE_SEALED');
      if (!declared.some(d => d.namespace === metadata.namespace && d.packageName === metadata.packageName)) throw new Error('PSC_LIBRARY_UNDECLARED_INPUT');
      const key = metadata.namespace;
      const identity = JSON.stringify(metadata);
      let entry = loaded.get(key);
      if (!entry) {
        entry = { metadata: structuredClone(metadata), identity, modules: new Map() };
        loaded.set(key, entry);
      } else if (entry.identity !== identity) throw new Error('PSC_LIBRARY_IDENTITY_CONFLICT');
      const module = { moduleName, sourceKind, ...sourceEvidence };
      const previous = entry.modules.get(moduleName);
      if (previous && JSON.stringify(previous) !== JSON.stringify(module)) throw new Error('PSC_LIBRARY_SOURCE_CONFLICT');
      if (!previous && ++moduleCount > 2048) throw new Error('PSC_LIBRARY_MODULE_LIMIT');
      entry.modules.set(moduleName, module);
    },
    seal() {
      if (sealed) throw new Error('PSC_LIBRARY_DISCLOSURE_SEALED');
      sealed = true;
      const libraries = [...loaded.values()].map(e => ({ ...e.metadata, modules: [...e.modules.values()].sort((a, b) => compare(a.moduleName, b.moduleName)) })).sort((a, b) => compare(a.namespace, b.namespace));
      const inventory = freezeDataGraph({ schema: 'psc0-source-library-disclosure/1', mode: 'source-only', declaredLibraries: declared, libraries, executedExtensions: [], proofAuthority: 'none', registryAuthenticityVerified: false, installationHistory: 'not-observed' });
      return Object.freeze({ inventory, sha256: hash('PSC0/LIBRARY-DISCLOSURE/1\0' + JSON.stringify(inventory)) });
    },
  });
}
export function libraryDisclosureNotice(disclosure) {
  const libraries = disclosure.inventory.libraries;
  const lines = ['PSC_SOURCE_LIBRARIES: ' + JSON.stringify({ mode: 'source-only', loaded: libraries.length, executedExtensions: 0, sha256: disclosure.sha256 })];
  for (const lib of libraries) lines.push('PSC_SOURCE_LIBRARY: ' + JSON.stringify({ package: lib.packageName, version: lib.version, namespace: lib.namespace, modules: lib.modules.length, manifestSha256: lib.manifest.sha256, declaredScripts: lib.declaredScriptNames.length, scriptsExecutedByCompiler: false }));
  const text = lines.join('\n') + '\n';
  if (Buffer.byteLength(text) > 256 * 1024) throw new Error('PSC_LIBRARY_DISCLOSURE_LIMIT');
  return text;
}
export async function reportLibraryDisclosure(disclosure) {
  // stderr keeps --json stdout machine-readable. Package metadata supplies no
  // logger, suppress flag or callback. An ordinary host/OS can still redirect IO.
  const text = libraryDisclosureNotice(disclosure);
  await new Promise((resolve, reject) => process.stderr.write(text, error => error ? reject(error) : resolve()));
}
