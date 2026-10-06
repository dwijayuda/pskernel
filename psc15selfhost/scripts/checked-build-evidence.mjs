import { artifactId, artifactKey, canonicalArtifact, canonicalBytes, passDefinition, recordPassExecution } from './artifact-evidence.mjs';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export async function readCheckedBuildHostSources() {
  const root = path.dirname(fileURLToPath(import.meta.url));
  const pending = ['checked-build.mjs'], seen = new Set(), sources = [];
  while (pending.length) {
    const relative = pending.pop();
    if (seen.has(relative)) continue;
    if (seen.size >= 256) throw new Error('PSC_BUILD_GRAPH_HOST_CLOSURE_LIMIT');
    const absolute = path.resolve(root, relative), local = path.relative(root, absolute);
    if (local === '..' || local.startsWith('..' + path.sep) || path.isAbsolute(local)) throw new Error('PSC_BUILD_GRAPH_HOST_SOURCE_ESCAPE');
    seen.add(relative);
    const bytes = await readFile(absolute);
    if (bytes.length > 16 * 1024 * 1024) throw new Error('PSC_BUILD_GRAPH_HOST_SOURCE_LIMIT');
    sources.push({ path: 'scripts/' + local.split(path.sep).join('/'), bytes });
    const source = bytes.toString('utf8');
    for (const match of source.matchAll(/(?:\bfrom\s*|\bimport\s*)['"](\.[^'"]+\.mjs)['"]/gu)) {
      pending.push(path.relative(root, path.resolve(path.dirname(absolute), match[1])));
    }
  }
  return sources.sort((left, right) => left.path < right.path ? -1 : left.path > right.path ? 1 : 0);
}

/** Actual observed build edges. Composite edges remain named as such: hidden IR
 * stages are not replaced by invented fingerprints or preservation evidence.
 * Archive builders must supply referenced source/compiler bytes for replay.
 */
export function createCheckedBuildGraph({ sourceKind, sources, admissions, typeScript,
  javaScript, declarations, sourceMap, compilerBytes, compilerKind, typeScriptCompilerBytes,
  provider, providerSecurity, kernelContract, hostSources, runtime, outputStem }) {
  const artifacts = new Map(), entries = [], executions = [];
  function add(item, source, inline = false) {
    const key = artifactKey(item.identity);
    if (!artifacts.has(key)) {
      artifacts.set(key, item.bytes);
      entries.push({ identity: item.identity, source,
        ...(inline ? { canonicalValue: JSON.parse(item.bytes) } : {}) });
    }
    return item;
  }
  function bytes(value, domain, contract, source) {
    const content = typeof value === 'string' ? Buffer.from(value) : value;
    return add({ bytes: content, identity: artifactId(content, domain, contract) }, source);
  }
  function json(value, domain, contract, source, inline = true) {
    return add(canonicalArtifact(value, domain, contract), source, inline);
  }
  const compiler = bytes(compilerBytes, 'compiler', 'psc-compiler-module/1', { kind: 'archive-required', role: compilerKind });
  const hosts = hostSources.map(item => bytes(item.bytes, 'host-source', 'psc-host-source/1',
    { kind: 'repository-file', path: item.path }));
  const implementation = json({ compiler: compiler.identity, hosts: hosts.map(item => item.identity), runtime },
    'implementation', 'psc-hosted-compiler-implementation/1', { kind: 'inline' });
  const source = json({ sourceKind, sources }, 'source-snapshot', 'psc-source-snapshot/1',
    { kind: 'archive-required', role: 'ordered-preparation-inputs' }, false);
  const core = bytes(admissions, 'canonical-admissions', 'proofscript-checked-admissions/2',
    { kind: 'output-file', suffix: '.admissions.json' });
  const security = json({ provider, providerSecurity, kernelContract }, 'acceptance-context',
    'psc-acceptance-context/1', { kind: 'inline' });
  const semanticIdentity = { providerProfile: provider.profile, kernelContract, runtimeSemantics: 'psc-runtime-semantics/1' };
  const baseDependencies = [compiler.identity, ...hosts.map(item => item.identity), security.identity];
  const assumptions = ['trusted-host-composition', 'selected-compiler-module-closure', 'selected-host-runtime',
    'selected-kernel-invocation'];
  function execute(id, input, outputs, impl, relation, parameters, dependencies, extraAssumptions = []) {
    const definition = add(passDefinition({ passId: id, version: 1, inputContract: input.identity.contract,
      outputContract: outputs[0].identity.contract, semanticRelationId: relation,
      resourceContractId: 'psc-compilation-resource/1', determinismClass: 'declared-inputs-with-trusted-host',
      totalityClass: 'partial-host-bounded', implementationId: impl.identity,
      validatorId: null, theoremIds: [], assumptionIds: [...assumptions, ...extraAssumptions] }), { kind: 'inline' }, true);
    const record = recordPassExecution({ definition, inputs: [input], outputs, parameters,
      semanticIdentity, dependencies, resourcePolicy: { contract: 'psc-checked-host-resource/1',
        enforcement: 'existing-stage-specific-limits', completeBudgetCoverage: false },
      resourceObservation: { hostObserved: true, inputBytes: input.bytes.byteLength,
        outputBytes: outputs.reduce((sum, output) => sum + output.bytes.byteLength, 0),
        unobserved: ['cpu', 'peak-memory', 'kernel-steps', 'ir-nodes'] },
      diagnostics: ['Global preservation is unproved; these records describe the executed composite edges.'], evidence: [] });
    add(record.action, { kind: 'inline' }, true); add(record, { kind: 'inline' }, true);
    executions.push(record.identity);
  }
  execute('psc-prepare-and-check/1', source, [core], implementation, 'psc-source-checked-admissions/1',
    { sourceKind, sourceCount: sources.length, observedStages: ['prepare', 'kernel-check'] }, baseDependencies,
    ['trusted-frontend-source-interpretation']);
  if (typeScript !== undefined) {
    const ts = bytes(typeScript, 'typescript-source', 'psc-typescript-source/es2022', { kind: 'output-file', suffix: '.ts' });
    execute('psc-checked-core-to-typescript/1', core, [ts], implementation, 'psc-core-runtime-refinement/1',
      { target: 'typescript', observedStages: ['checked-emission'],
        unobservedInteriorStages: ['erase', 'validate-ir', 'typescript-lower', 'typescript-print'] }, baseDependencies,
      ['trusted-erasure-and-typescript-emission']);
    if (javaScript !== undefined) {
      if (typeof outputStem !== 'string' || !outputStem) throw new Error('PSC_BUILD_GRAPH_OUTPUT_STEM');
      const tool = bytes(typeScriptCompilerBytes, 'typescript-compiler-entry', 'typescript-compiler-entry/1',
        { kind: 'archive-required', role: 'typescript-compiler-entry' });
      const outputs = [
        bytes(javaScript, 'javascript-output', 'typescript-emitted-file/1', { kind: 'output-file', suffix: '.js' }),
        bytes(declarations, 'declarations-output', 'typescript-emitted-file/1', { kind: 'output-file', suffix: '.d.ts' }),
        bytes(sourceMap, 'source-map-output', 'typescript-emitted-file/1', { kind: 'output-file', suffix: '.js.map' }),
      ];
      execute('typescript-to-es2022/1', ts, outputs, tool, 'typescript-erasure-to-es2022/1',
        { outputStem, inputClosureComplete: false,
          flags: ['--ignoreConfig', '--target', 'ES2022', '--module', 'ES2022', '--moduleResolution', 'bundler',
          '--strict', '--declaration', '--sourceMap', '--noEmitOnError', '--skipLibCheck', '--pretty', 'false'] },
        baseDependencies, ['selected-typescript-package-closure']);
    }
  }
  const graph = { schemaVersion: 1, contract: 'psc-observed-build-graph/1', authority: 'audit-record-only',
    entries, executions, coverage: 'observed-composite-edges',
    remaining: ['per-IR-stage artifacts', 'complete toolchain closure', 'independent preservation evidence', 'archive byte closure'] };
  const encoded = canonicalBytes(graph);
  return { graph, artifacts, bytes: encoded,
    identity: artifactId(encoded, 'build-graph', 'psc-observed-build-graph/1') };
}
