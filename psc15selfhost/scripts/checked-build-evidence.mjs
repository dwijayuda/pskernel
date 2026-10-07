import { artifactId, artifactKey, canonicalArtifact, canonicalBytes, passDefinition, recordPassExecution } from './artifact-evidence.mjs';
import { createHash } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { checkedIrStageArtifacts } from './ir-artifact.mjs';

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
 * The checked builder packages every listed byte snapshot in its build archive.
 */
export function createCheckedBuildGraph({ sourceKind, sources, admissions, typeScript,
  javaScript, directJavaScript, declarations, sourceMap, compilerBytes, compilerKind, typeScriptCompilerBytes,
  provider, providerSecurity, kernelContract, hostSources, runtime, outputStem, irStages, typeScriptToolInputs, providerToolInputs = [], sourceResources, seedResources }) {
  const artifacts = new Map(), entries = [], executions = [];
  if (directJavaScript !== undefined && [typeScript, javaScript, declarations, sourceMap].some(value => value !== undefined))
    throw new Error('PSC_BUILD_GRAPH_MIXED_BACKEND_PATHS');
  let toolInputs;
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
  function bindToolInputs(snapshot, contract, domain, role) {
    const { details, files } = snapshot;
    if (details.contract !== contract || details.fullInputClosureEstablished !== false ||
        !Array.isArray(files) || !Array.isArray(details.files) || files.length !== details.files.length || !files.length)
      throw new Error('PSC_BUILD_GRAPH_TOOL_INPUTS_SCHEMA');
    const capturedFiles = files.map((item, index) => {
      const expected = details.files[index];
      if (item.path !== expected.path || !(item.bytes instanceof Uint8Array) ||
          item.bytes.byteLength !== expected.byteLength || createHash('sha256').update(item.bytes).digest('hex') !== expected.sha256 ||
          (index > 0 && files[index - 1].path >= item.path)) throw new Error('PSC_BUILD_GRAPH_TOOL_INPUTS_BYTES');
      return { path: item.path, artifact: bytes(item.bytes, domain, 'psc-tool-file-bytes/1',
        { kind: 'archive-required', role, path: item.path }).identity };
    });
    return json({ ...details, files: capturedFiles,
      stabilityObservation: contract === 'psc-typescript-tool-inputs/1' ? 'same-inventory-and-bytes-before-and-after-execution' :
        'same-explicit-file-bytes-before-and-after-checking' }, 'tool-inputs', contract, { kind: 'inline' });
  }
  const providerInputs = providerToolInputs.map(snapshot =>
    bindToolInputs(snapshot, 'psc-checked-provider-inputs/1', 'provider-tool-file', 'selected-provider-file'));
  const compiler = bytes(compilerBytes, 'compiler', 'psc-compiler-module/1', { kind: 'archive-required', role: compilerKind });
  const hosts = hostSources.map(item => bytes(item.bytes, 'host-source', 'psc-host-source/1',
    { kind: 'repository-file', path: item.path }));
  const implementation = json({ compiler: compiler.identity, hosts: hosts.map(item => item.identity), runtime },
    'implementation', 'psc-hosted-compiler-implementation/1', { kind: 'inline' });
  const source = json({ sourceKind, sources }, 'source-snapshot', 'psc-source-snapshot/1',
    { kind: 'archive-required', role: 'ordered-preparation-inputs' }, false);
  const core = bytes(admissions, 'canonical-admissions', 'proofscript-checked-admissions/2',
    { kind: 'output-file', suffix: '.admissions.json' });
  const security = json({ provider, providerSecurity, kernelContract,
    ...(providerInputs.length ? { providerInputs: providerInputs.map(item => item.identity) } : {}) }, 'acceptance-context',
    'psc-acceptance-context/1', { kind: 'inline' });
  const semanticIdentity = { providerProfile: provider.profile, kernelContract, runtimeSemantics: 'psc-runtime-semantics/1' };
  const baseDependencies = [compiler.identity, ...hosts.map(item => item.identity), security.identity,
    ...providerInputs.map(item => item.identity)];
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
        enforcement: 'existing-stage-specific-limits', completeBudgetCoverage: false,
        ...(id === 'psc-prepare-and-check/1' && sourceResources ? { sourceReading: sourceResources.limits } : {}),
        ...(id !== 'typescript-to-es2022/1' && seedResources ? { nativeSession: seedResources.limits } : {}) },
      resourceObservation: { hostObserved: true, inputBytes: input.bytes.byteLength,
        outputBytes: outputs.reduce((sum, output) => sum + output.bytes.byteLength, 0),
        ...(id === 'psc-prepare-and-check/1' && sourceResources ? { sourceReading: sourceResources.observed } : {}),
        ...(id !== 'typescript-to-es2022/1' && seedResources ? { nativeSession: seedResources.observed,
          nativeSessionScope: 'whole-shared-session-not-per-pass-attribution' } : {}),
        unobserved: ['cpu', 'peak-memory', 'kernel-steps', 'ir-nodes'] },
      diagnostics: ['Global preservation is unproved; these records describe the executed composite edges.'], evidence: [] });
    add(record.action, { kind: 'inline' }, true); add(record, { kind: 'inline' }, true);
    executions.push(record.identity);
  }
  execute('psc-prepare-and-check/1', source, [core], implementation, 'psc-source-checked-admissions/1',
    { sourceKind, sourceCount: sources.length, observedStages: ['prepare', 'kernel-check'] }, baseDependencies,
    ['trusted-frontend-source-interpretation']);
  const stages = checkedIrStageArtifacts(irStages);
  let verifiedIr;
  if (stages && (typeScript !== undefined || directJavaScript !== undefined)) {
      const runtimeIr = add(stages.runtimeIr, { kind: 'archive-required', role: 'actual-erasure-output' });
      verifiedIr = add(stages.verifiedIr, { kind: 'archive-required', role: 'actual-validation-output' });
      if (!runtimeIr.bytes.equals(verifiedIr.bytes)) throw new Error('PSC_BUILD_GRAPH_VALIDATION_CHANGED_IR');
      execute('psc-erase-checked-core/1', core, [runtimeIr], implementation, 'psc-core-runtime-refinement/1',
        { observedStages: ['erase'] }, baseDependencies, ['trusted-erasure-implementation']);
      execute('psc-validate-runtime-ir/1', runtimeIr, [verifiedIr], implementation, 'psc-runtime-ir-invariants/1',
        { observedStages: ['validate-ir'], bytesPreserved: true }, baseDependencies, ['trusted-strict-ir-validator']);
  }
  if (typeScript !== undefined) {
    const ts = bytes(typeScript, 'typescript-source', 'psc-typescript-source/es2022', { kind: 'output-file', suffix: '.ts' });
    if (verifiedIr) {
      execute('psc-verified-ir-to-typescript/1', verifiedIr, [ts], implementation, 'psc-ir-typescript-refinement/1',
        { target: 'typescript', observedStages: ['typescript-emission'],
          unobservedInteriorStages: ['typescript-lower', 'typescript-print'] }, baseDependencies,
        ['trusted-typescript-emission']);
    } else {
      execute('psc-checked-core-to-typescript/1', core, [ts], implementation, 'psc-core-runtime-refinement/1',
        { target: 'typescript', observedStages: ['checked-emission'],
          unobservedInteriorStages: ['erase', 'validate-ir', 'typescript-lower', 'typescript-print'] }, baseDependencies,
        ['trusted-erasure-and-typescript-emission']);
    }
    if (javaScript !== undefined) {
      if (typeof outputStem !== 'string' || !outputStem) throw new Error('PSC_BUILD_GRAPH_OUTPUT_STEM');
      const tool = bytes(typeScriptCompilerBytes, 'typescript-compiler-entry', 'typescript-compiler-entry/1',
        { kind: 'archive-required', role: 'typescript-compiler-entry' });
      if (typeScriptToolInputs) {
        const { details, files } = typeScriptToolInputs;
        toolInputs = bindToolInputs(typeScriptToolInputs, 'psc-typescript-tool-inputs/1', 'typescript-tool-file', 'typescript-package-file');
        const entry = files.find(item => item.path === details.entryPath);
        if (!entry || !Buffer.from(entry.bytes).equals(Buffer.from(typeScriptCompilerBytes))) throw new Error('PSC_BUILD_GRAPH_TOOL_ENTRY');
      }
      const outputs = [
        bytes(javaScript, 'javascript-output', 'typescript-emitted-file/1', { kind: 'output-file', suffix: '.js' }),
        bytes(declarations, 'declarations-output', 'typescript-emitted-file/1', { kind: 'output-file', suffix: '.d.ts' }),
        bytes(sourceMap, 'source-map-output', 'typescript-emitted-file/1', { kind: 'output-file', suffix: '.js.map' }),
      ];
      execute('typescript-to-es2022/1', ts, outputs, toolInputs ?? tool, 'typescript-erasure-to-es2022/1',
        { outputStem, inputClosureComplete: false,
          flags: ['--ignoreConfig', '--target', 'ES2022', '--module', 'ES2022', '--moduleResolution', 'bundler',
          '--strict', '--declaration', '--sourceMap', '--noEmitOnError', '--skipLibCheck', '--pretty', 'false'] },
        toolInputs ? [...baseDependencies, toolInputs.identity] : baseDependencies, ['selected-typescript-package-closure']);
    }
  }
  if (directJavaScript !== undefined) {
    if (!verifiedIr || !stages?.specializedIr) throw new Error('PSC_BUILD_GRAPH_JS_STAGES_REQUIRED');
    const specializedIr = add(stages.specializedIr, { kind: 'archive-required', role: 'actual-specialization-output' });
    execute('psc-pass-specialize/1', verifiedIr, [specializedIr], implementation, 'psc-specialization-runtime-refinement/1',
      { observedStages: ['specialize', 'validate-specialized-ir'], postcondition: 'strict-runtime-ir-invariants' },
      baseDependencies, ['trusted-specialization-implementation', 'trusted-strict-ir-validator']);
    const js = bytes(directJavaScript, 'javascript-output', 'psc-direct-javascript/es2022', { kind: 'output-file', suffix: '.js' });
    execute('psc-specialized-ir-to-javascript/1', specializedIr, [js], implementation, 'psc-ir-javascript-refinement/1',
      { target: 'javascript', wordSize: 64, observedStages: ['javascript-lower-and-stack-safe-print'],
        unobservedInteriorStages: ['javascript-target-ir'], productionPromotion: false },
      baseDependencies, ['trusted-javascript-lowering-and-printing']);
  }
  const graph = { schemaVersion: 1, contract: 'psc-observed-build-graph/1', authority: 'audit-record-only',
    entries, executions, coverage: directJavaScript !== undefined ? 'observed-erasure-validation-specialization-and-composite-backend-edges' :
      irStages ? 'observed-erasure-validation-and-composite-backend-edges' : 'observed-composite-edges',
    remaining: [directJavaScript !== undefined ? 'backend-interior artifacts and production promotion' :
      irStages ? 'specialization and backend-interior artifacts' : 'per-IR-stage artifacts',
      'complete toolchain closure', 'independent preservation evidence'] };
  const encoded = canonicalBytes(graph);
  return { graph, artifacts, bytes: encoded,
    identity: artifactId(encoded, 'build-graph', 'psc-observed-build-graph/1'),
    ...(providerInputs.length ? { providerInputs: providerInputs.map(item => item.identity) } : {}),
    ...(toolInputs ? { typeScriptToolInputs: toolInputs.identity } : {}) };
}
