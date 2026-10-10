import { createHash } from 'node:crypto';
import { validateLibraryEmission } from './checked-project.mjs';

import { coreCheckedIdentity } from './checked-kernel-identity.mjs';
export { leanCheckedIdentity } from './checked-kernel-identity.mjs';
const hash = text => createHash('sha256').update(text, 'utf8').digest('hex');

export function unwrapCompilerResult(result, stage) {
  if (result !== null && typeof result === 'object') {
    const tags = Object.getOwnPropertySymbols(result).map(key => result[key]);
    if (tags.includes('ok') && !tags.includes('error')) return result.value;
    if (tags.includes('error') && !tags.includes('ok')) {
      throw new Error(`PSC2_CHECKED_${stage}_FAILED`);
    }
  }
  throw new Error(`PSC2_CHECKED_${stage}_RESULT_SHAPE`);
}

function freezeGraph(root) {
  const pending = [root]; const seen = new WeakSet();
  while (pending.length) {
    const value = pending.pop();
    if (value === null || typeof value !== 'object' || seen.has(value)) continue;
    seen.add(value);
    const proto = Object.getPrototypeOf(value);
    if (proto !== null && proto !== Object.prototype && proto !== Array.prototype) {
      throw new Error('PSC2_CHECKED_UNSUPPORTED_OBJECT');
    }
    for (const key of Reflect.ownKeys(value)) {
      const descriptor = Object.getOwnPropertyDescriptor(value, key);
      if (!Object.hasOwn(descriptor, 'value')) throw new Error('PSC2_CHECKED_ACCESSOR_FORBIDDEN');
      if (typeof descriptor.value === 'function') throw new Error('PSC2_CHECKED_FUNCTION_FORBIDDEN');
      pending.push(descriptor.value);
    }
    Object.freeze(value);
  }
  return root;
}

function checkedRuntimeIrOptions(compiler) {
  const defaults = compiler.psIrCheckDefaultOptions;
  if (defaults === null || typeof defaults !== 'object') {
    throw new Error('PSC2_CHECKED_IR_OPTIONS_DEFAULTS');
  }
  freezeGraph(defaults);
  const fields = ['maxSteps', 'maxTypeSteps', 'maxFindings'];
  const limits = {};
  for (const field of fields) {
    const value = defaults[field];
    if (typeof value !== 'bigint' || value < 0n || value > BigInt(Number.MAX_SAFE_INTEGER)) {
      throw new Error('PSC2_CHECKED_IR_OPTIONS_DEFAULTS: ' + field);
    }
    limits[field] = Number(value);
  }
  // Construct the options with this compiler instance's public factory. A host
  // record or a serialized accepted flag cannot substitute for the checked API.
  const options = compiler.psIrCheckOptionsWithLimits(
    defaults.maxSteps, defaults.maxTypeSteps, defaults.maxFindings,
  );
  if (options === null || typeof options !== 'object') {
    throw new Error('PSC2_CHECKED_IR_OPTIONS_RESULT');
  }
  freezeGraph(options);
  for (const field of fields) {
    if (options[field] !== defaults[field]) {
      throw new Error('PSC2_CHECKED_IR_OPTIONS_RESULT: ' + field);
    }
  }
  return Object.freeze({ options, limits: Object.freeze(limits) });
}

function admissionsFrom(compiler, prepared, project = false) {
  const api = project ? 'psCompilerProjectAdmissionsFromPrepared' : 'psCompilerAdmissionsFromPrepared';
  const source = unwrapCompilerResult(compiler[api](prepared), 'ADMISSIONS');
  if (typeof source !== 'string') throw new Error('PSC2_CHECKED_ADMISSIONS_RESULT_SHAPE');
  return source;
}

/**
 * Trusted host composition boundary. compiler and checkAdmissions are selected by
 * the host, never by a serialized receipt or an untrusted caller's checked flag.
 * Production supplies the selected, pinned kernel identity. Test doubles
 * exercise orchestration only. This does not sandbox malicious compiler/host JS
 * and does not claim a portable, universally unforgeable CheckedCore type.
 */
export function createCheckedPreparedSession(compiler, checkAdmissions, expectedIdentity = coreCheckedIdentity) {
  const identity = Object.freeze({ ...expectedIdentity });
  if (!identity.protocol || !identity.provider || !identity.profile) throw new Error('PSC2_CHECKED_IDENTITY_REQUIRED');
  for (const name of ['psCompilerPrepareSource', 'psCompilerAdmissionsFromPrepared',
    'psCompilerCheckedTypeScriptFromPrepared', 'psIrCheckOptionsWithLimits']) {
    if (typeof compiler?.[name] !== 'function') throw new Error(`PSC2_CHECKED_API_MISSING: ${name}`);
  }
  if (typeof checkAdmissions !== 'function') throw new TypeError('Expected kernel checker');
  const irPolicy = checkedRuntimeIrOptions(compiler);
  const modules = new WeakMap();
  async function checkPrepared(prepared, source, projectUnits) {
      if (prepared === null || typeof prepared !== 'object') throw new Error('PSC2_CHECKED_PREPARE_RESULT_SHAPE');
      freezeGraph(prepared);
      const admissions = admissionsFrom(compiler, prepared, projectUnits !== undefined);
      const result = await checkAdmissions(admissions);
      for (const [field, expected] of Object.entries(identity)) {
        if (result?.[field] !== expected) throw new Error(`PSC2_CHECKED_PROVIDER_IDENTITY: ${field}`);
      }
      if (typeof result.accepted !== 'boolean') throw new Error('PSC2_CHECKED_PROVIDER_RESULT');
      if (!result.accepted) throw new Error(`PSC2_KERNEL_REJECTED: ${result.errorKind ?? 'kernel-rejection'}`);
      const handle = Object.freeze({
        sourceSha256: hash(source), canonicalAdmissionsSha256: hash(admissions),
        provider: identity,
      });
      modules.set(handle, { prepared, admissions, projectUnits });
      return handle;
  }
  function emitChecked(handle, project = false) {
    const item = handle !== null && typeof handle === 'object' ? modules.get(handle) : undefined;
    if (!item) throw new Error('PSC2_CHECKED_UNCHECKED_MODULE');
    if ((item.projectUnits !== undefined) !== project) throw new Error('PSC0_LIBRARY_EMISSION_MODE');
    if (admissionsFrom(compiler, item.prepared, project) !== item.admissions) {
      throw new Error('PSC2_CHECKED_PAYLOAD_CHANGED');
    }
    // The existing portable entry owns erasure, complete original-IR typing and
    // emission of that same IR. It returns no output if the checker refuses.
    // There is no raw-emitter fallback and no second erasure/checking pass here.
    const emitter = project ? 'psCompilerCheckedTypeScriptProjectFromPrepared'
      : 'psCompilerCheckedTypeScriptFromPrepared';
    const result = unwrapCompilerResult(compiler[emitter](irPolicy.options, item.prepared), 'EMIT');
    const library = project ? validateLibraryEmission(result, item.projectUnits) : undefined;
    const output = project ? library.typeScript : result;
    if (typeof output !== 'string') throw new Error('PSC2_CHECKED_EMIT_RESULT_SHAPE');
    // Audit evidence follows only from this successful checked call. The API
    // does not return detailed counts; do not invent an independent IR report.
    // This record is not a transferable admission or emission capability.
    const validation = Object.freeze({
      schemaVersion: 1,
      kind: 'psc0-runtime-ir-checked-emission',
      emitter,
      ...(library ? { publicInterfaceSha256: library.publicInterfaceSha256 } : {}),
      sourceSha256: handle.sourceSha256,
      canonicalAdmissionsSha256: handle.canonicalAdmissionsSha256,
      typeScriptSha256: hash(output),
      runtimeIrTypingAccepted: true,
      traversalComplete: true,
      sameOriginalIrCheckedBeforeEmission: true,
      options: irPolicy.limits,
      strictSh1Qualified: false,
      semanticContractQualified: false,
    });
    return Object.freeze({ typeScript: output, validation, ...(library ? { library } : {}) });
  }
  return Object.freeze({
    async check(sourceKind, source) {
      if (typeof source !== 'string') throw new TypeError('Expected immutable source text');
      const prepared = unwrapCompilerResult(compiler.psCompilerPrepareSource(sourceKind, source), 'PREPARE');
      return checkPrepared(prepared, source);
    },
    async checkSources(sourceKind, sources) {
      if (!Array.isArray(sources) || sources.some(source => typeof source !== 'string')) {
        throw new TypeError('Expected immutable source texts');
      }
      if (typeof compiler.psCompilerPrepareSources !== 'function' ||
          typeof compiler.List?.cons !== 'function' || typeof compiler.List.nil !== 'function') {
        throw new Error('PSC2_CHECKED_API_MISSING: module preparation');
      }
      const source = sources.join('\n\n') + '\n';
      let values = compiler.List.nil();
      for (let index = sources.length - 1; index >= 0; index--) values = compiler.List.cons(sources[index], values);
      const prepared = unwrapCompilerResult(compiler.psCompilerPrepareSources(sourceKind, values), 'PREPARE');
      return checkPrepared(prepared, source);
    },
    async checkProject(sourceKind, units) {
      for (const api of ['psCompilerMakeProjectSource', 'psCompilerPrepareProject',
        'psCompilerProjectAdmissionsFromPrepared', 'psCompilerCheckedTypeScriptProjectFromPrepared']) {
        if (typeof compiler[api] !== 'function') throw new Error('PSC0_LIBRARY_API_MISSING: ' + api);
      }
      if (!Array.isArray(units) || units.length === 0 ||
          units.some(unit => typeof unit?.sourceId !== 'string' || typeof unit.source !== 'string' ||
            !Array.isArray(unit.exports) || unit.exports.some(name => typeof name !== 'string'))) {
        throw new Error('PSC0_LIBRARY_SOURCE_UNITS');
      }
      const captured = units.map(unit => ({ sourceId: unit.sourceId, source: unit.source, exports: [...unit.exports] }));
      freezeGraph(captured);
      if (typeof compiler.List?.cons !== 'function' || typeof compiler.List.nil !== 'function') {
        throw new Error('PSC0_LIBRARY_API_MISSING: List');
      }
      let inputs = compiler.List.nil();
      for (let index = captured.length - 1; index >= 0; index--) {
        const unit = captured[index]; let names = compiler.List.nil();
        for (let i = unit.exports.length - 1; i >= 0; i--) names = compiler.List.cons(unit.exports[i], names);
        const input = compiler.psCompilerMakeProjectSource(unit.sourceId, unit.source, names);
        inputs = compiler.List.cons(input, inputs);
      }
      const prepared = unwrapCompilerResult(compiler.psCompilerPrepareProject(sourceKind, inputs), 'PREPARE');
      return checkPrepared(prepared, captured.map(unit => unit.source).join('\n\n') + '\n', captured);
    },
    emitProjectChecked(handle) {
      return emitChecked(handle, true);
    },
    emit(handle) {
      return emitChecked(handle).typeScript;
    },
    emitChecked,
  });
}
