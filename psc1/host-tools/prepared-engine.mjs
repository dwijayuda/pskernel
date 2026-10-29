// Host scheduling only. Every language operation calls the unchanged generated compiler.
import fs from 'node:fs';
import { createNativeWireQuoter } from './wire-quote.mjs';
import { createCompilerDataEquality } from './compiler-data-equality.mjs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { verify, readManifestBytes } from './executable/verify.mjs';
const fail = (code) => {
  throw Error('PSC1_PREPARATION_' + code);
};
function tag(value) {
  if (value?.['$ps$tag'] !== undefined) return value['$ps$tag'];
  if (value && typeof value === 'object') {
    const tags = Object.getOwnPropertySymbols(value)
      .map((key) => value[key])
      .filter((v) => typeof v === 'string');
    if (tags.length === 1) return tags[0];
  }
  fail('DATA_TAG');
}
const fields = (value) => value?.['$ps$fields'] ?? value;
const jsNil = () => ({ '$ps$tag': 'nil', '$ps$fields': {} });
const jsCons = (head, tail) => ({ '$ps$tag': 'cons', '$ps$fields': { head, tail } });
function unwrap(result) {
  const kind = tag(result),
    data = fields(result);
  if (kind === 'ok') return data.value;
  if (kind === 'error') {
    const e = data.error;
    const error = Error('PSC1_PREPARATION_REFUSED:' + e?.phase + ':' + e?.code);
    error.compilerError = e;
    throw error;
  }
  fail('RESULT_SHAPE');
}
function array(list) {
  const result = [];
  let current = list;
  while (tag(current) === 'cons') {
    if (result.length >= 8192) fail('LIST_BOUND');
    const data = fields(current);
    result.push(data.head);
    current = data.tail;
  }
  if (tag(current) !== 'nil') fail('LIST_SHAPE');
  return result;
}
export async function loadPreparedEngine({
  root,
  manifestFile,
  manifestSha256,
  variant,
  outputs = false,
}) {
  if (!['js', 'ts'].includes(variant)) fail('VARIANT');
  const check = () => verify(root, readManifestBytes(manifestFile), manifestSha256);
  const manifest = check();
  const load = (owner, name) => {
    const suffix = '@proofscript/' + owner + '/dist/' + variant + '/generated/' + name + '.mjs';
    const matches = manifest.files.filter(
      (row) => row.path === suffix || row.path.endsWith('/' + suffix),
    );
    if (matches.length !== 1) fail('MODULE_OWNER:' + name);
    return import(pathToFileURL(path.join(root, matches[0].path)));
  };
  const [service, api, ir, json, names, runtime] = await Promise.all([
    load('compiler', 'Ps.Compiler.Service'),
    load('compiler', 'Ps.Compiler.Api'),
    load('compiler-ir', 'Ps.CompilerIr.Validate'),
    load('bridge', 'Ps.Bridge.Json'),
    load('foundation', 'Ps.Foundation.Name'),
    load('foundation', 'runtime'),
  ]);
  const emitters = new Map();
  if (outputs) {
    for (const [target, name, exportName] of [
      ['js', 'Ps.BackendJs.Emit', 'Ps_Internal_JsCompilerService_emit'],
      ['ts', 'Ps.BackendTs.Emit', 'Ps_Internal_TsCompilerService_emit'],
      ['rust', 'Ps.BackendRust.Emit', 'Ps_Internal_RustCompilerService_emit'],
      ['wasm-core', 'Ps.BackendWasm.Emit', 'Ps_Internal_WasmCompilerService_emit'],
    ]) {
      const suffix = '/dist/' + variant + '/generated/' + name + '.mjs',
        matches = manifest.files.filter((row) => row.path.endsWith(suffix));
      if (matches.length !== 1) fail('EMITTER_OWNER:' + target);
      const module = await import(pathToFileURL(path.join(root, matches[0].path)).href);
      if (typeof module[exportName] !== 'function') fail('EMITTER_EXPORT:' + target);
      emitters.set(target, module[exportName]);
    }
  }
  check();
  const sameData = createCompilerDataEquality();
  const wireQuoter = createNativeWireQuoter(json.psJsonQuote);
  const nativeQuoteEntry = service.Ps_Internal_CompilerService_compilePreparedWithQuote;
  let emissionCache;
  let lastMetrics, previous;
  const constructor = (name) => {
    const value = runtime[name];
    if (!value || typeof value !== 'object') fail('DATA_ABI:' + name);
    return value;
  };
  const strings = () => (variant === 'js' ? null : constructor('List$spec$String'));
  const emptyStrings = () => (variant === 'js' ? jsNil() : strings().nil);
  const emptyGraph = () =>
    variant === 'js' ? jsNil() : constructor('List$spec$N$Prod$spec$String$N$List$spec$String').nil;
  const emptyEntry = () =>
    variant === 'js'
      ? { '$ps$tag': 'none', '$ps$fields': {} }
      : constructor('Option$spec$N$PsSyntaxModule').none;
  const sourceList = (item) =>
    variant === 'js'
      ? jsCons(item, jsNil())
      : constructor('List$spec$N$Ps_Internal_CompilerService_Source').cons(
          item,
          constructor('List$spec$N$Ps_Internal_CompilerService_Source').nil,
        );
  const entryList = (item) =>
    variant === 'js' ? jsCons(item, jsNil()) : strings().cons(item, strings().nil);

  function prepare(request, checkOnly) {
    const captureStarted = performance.now();
    const inputs = array(request.sources),
      old = previous;
    const compatible = old && old.kind === request.grammar && old.entry === request.entry;
    let prefix = 0;
    if (compatible)
      while (
        prefix < inputs.length &&
        prefix < old.inputs.length &&
        inputs[prefix].moduleName === old.inputs[prefix].moduleName &&
        inputs[prefix].text === old.inputs[prefix].text
      )
        prefix++;
    const states = compatible
      ? old.states.slice(0, prefix + 1)
      : [
          {
            state: api.psCompilerPreparationStart(request.kind),
            seen: emptyStrings(),
            graphRev: emptyGraph(),
            originsRev: emptyStrings(),
            entry: emptyEntry(),
          },
        ];
    try {
      for (let i = prefix; i < inputs.length; i++)
        states.push(
          unwrap(
            service.Ps_Internal_CompilerService_captureWorker(
              request,
              sourceList(inputs[i]),
            )(states.at(-1)),
          ),
        );
      const captured = states.at(-1);
      if (tag(captured.entry) !== 'some') fail('ENTRY_MISSING');
      unwrap(
        service.Ps_Internal_CompilerService_exactClosureWorker(captured.graphRev)(
          entryList(request.entry),
        ),
      );
      const captureMs = performance.now() - captureStarted;
      const semanticStarted = performance.now();
      const hit =
        compatible &&
        prefix === inputs.length &&
        prefix === old.inputs.length &&
        old.assurance === request.assurance;
      const semanticInput = hit
        ? old.semanticInput
        : api.psCompilerPreparationElaborated(captured.state);
      const comparisonStarted = performance.now();
      const semanticHit = !!(
        !hit &&
        compatible &&
        old.assurance === request.assurance &&
        sameData(old.semanticInput, semanticInput)
      );
      const comparisonMs = performance.now() - comparisonStarted;
      const work =
        hit || semanticHit
          ? old.work
          : unwrap(service.Ps_Internal_CompilerService_prepare(request, captured));
      const semanticMs = performance.now() - semanticStarted;
      const validationStarted = performance.now();
      // Check-only validates here, including reuse hits. Builds validate in the
      // unchanged generated compilePrepared entry point before any transform.
      if (checkOnly) unwrap(ir.psStrictValidateModule(work.raw));
      previous = {
        kind: request.grammar,
        entry: request.entry,
        assurance: request.assurance,
        inputs,
        states,
        work,
        semanticInput,
      };
      return {
        captured,
        work,
        cache: {
          prefixModules: prefix,
          preparedModules: inputs.length - prefix,
          finishHit: !!hit,
          semanticHit,
        },
        phases: {
          captureMs,
          semanticMs,
          comparisonMs,
          originalIrValidationMs: performance.now() - validationStarted,
        },
      };
    } catch (error) {
      previous = undefined;
      throw error;
    }
  }
  return Object.freeze({
    candidate(text) {
      check();
      const started = performance.now();
      lastMetrics = undefined;
      const quoteBefore = wireQuoter.metrics();
      let activeRequest,
        activeTarget,
        checkingRequest = false;
      try {
        const outer = JSON.parse(text);
        if (
          !Array.isArray(outer) ||
          outer.length !== 3 ||
          !['psc1-check-service/1', 'psc1-unified-compiler-service/2'].includes(outer[0])
        )
          fail('REQUEST');
        const checking = outer[0] === 'psc1-check-service/1',
          target = checking ? 'check' : outer[1];
        checkingRequest = checking;
        activeTarget = target;
        if (checking && outer[1] !== 'check') fail('REQUEST');
        if (!checking && (!outputs || !emitters.has(target))) fail('TARGET');
        const value = unwrap(json.psJsonParse(JSON.stringify(outer[2])));
        if (tag(value) !== 'array') fail('REQUEST');
        const selected = unwrap(
          service.Ps_Internal_CompilerService_decodeOutputRequestFields(fields(value).values),
        );
        const request = selected.fst;
        activeRequest = request;
        const io = selected.snd,
          { captured, work, cache, phases } = prepare(request, checking);
        if (checking) {
          if (io) fail('CHECK_OUTPUT_ABI');
          const origins = array(captured.originsRev)
            .reverse()
            .map((row) => JSON.parse(row));
          return JSON.stringify({
            protocol: 'psc1-check-candidate/1',
            status: 'candidate',
            candidateOnly: true,
            admission: 'not-run',
            requestId: request.requestId,
            sourceClosureDigest: request.sourceClosureDigest,
            grammar: request.grammar,
            assurance: request.assurance,
            admissions: work.admissions,
            sourceDeclarations: array(work.source).length,
            logicalDeclarations: Number(work.logicalCount),
            partialNames: array(work.partialNames).map((name) => names.psNameToString(name)),
            origins,
            irValidation: 'strict-original-no-transform',
            cache: { ...cache, phases },
            preparationMs: performance.now() - started,
          });
        }
        const targetName = { 'js': 'js', 'ts': 'ts', 'rust': 'rust', 'wasm-core': 'wasmCore' }[
          target
        ];
        const backendTarget =
          variant === 'js'
            ? { '$ps$tag': targetName, '$ps$fields': {} }
            : constructor('PsBackendTarget')[targetName];
        if (!backendTarget) fail('TARGET_ABI');
        const emit = emitters.get(target);
        const emitStarted = performance.now();
        const emitterStats = { printMs: 0, comparisonMs: 0, hit: false };
        const output = unwrap(
          (typeof nativeQuoteEntry === 'function'
            ? (...args) => nativeQuoteEntry(wireQuoter.quoteString, ...args)
            : service.Ps_Internal_CompilerService_compilePreparedWithOutputAbi)(
            io,
            backendTarget,
            (module) => (selected) => {
              const old = emissionCache,
                comparisonStarted = performance.now();
              const hit =
                old?.target === target &&
                sameData(old.module, module) &&
                sameData(old.selected, selected);
              emitterStats.comparisonMs += performance.now() - comparisonStarted;
              if (hit) {
                emitterStats.hit = true;
                return old.result;
              }
              const printStarted = performance.now(),
                result = emit(module, selected);
              emitterStats.printMs += performance.now() - printStarted;
              // At most one target result/input graph; do not accumulate target cohorts.
              if (
                tag(result) === 'ok' &&
                typeof fields(result).value?.fst === 'string' &&
                fields(result).value.fst.length <= 4194304
              )
                emissionCache = { target, module, selected, result };
              else emissionCache = undefined;
              return result;
            },
            request,
            captured,
            fields(captured.entry).value,
            work,
          ),
        );
        const quoteAfter = wireQuoter.metrics();
        lastMetrics = {
          ...cache,
          nativeQuoteCalls: quoteAfter.nativeCalls - quoteBefore.nativeCalls,
          nativeQuoteInputBytes: quoteAfter.nativeInputBytes - quoteBefore.nativeInputBytes,
          quoteFallbackCalls: quoteAfter.fallbackCalls - quoteBefore.fallbackCalls,
          preparationMs: performance.now() - started,
          phases: {
            ...phases,
            emitMs: performance.now() - emitStarted,
            printMs: emitterStats.printMs,
            emitComparisonMs: emitterStats.comparisonMs,
          },
          emitterHit: emitterStats.hit,
        };
        return output;
      } catch (error) {
        previous = undefined;
        emissionCache = undefined;
        lastMetrics = undefined;
        if (error.compilerError && typeof error.compilerError === 'object') {
          const e = error.compilerError;
          if (checkingRequest)
            return JSON.stringify({
              protocol: 'psc1-check-candidate/1',
              status: 'refused',
              phase: e.phase,
              code: e.code,
            });
          const targetName = { 'js': 'js', 'ts': 'ts', 'rust': 'rust', 'wasm-core': 'wasmCore' }[
            activeTarget
          ];
          if (targetName) {
            const backendTarget =
              variant === 'js'
                ? { '$ps$tag': targetName, '$ps$fields': {} }
                : constructor('PsBackendTarget')[targetName];
            return service.Ps_Internal_CompilerService_refused(
              backendTarget,
              activeRequest?.requestId ?? '',
              activeRequest?.sourceClosureDigest ?? '',
              e,
            );
          }
        }
        throw error;
      } finally {
        check();
      }
    },
    metrics() {
      return lastMetrics ? { ...lastMetrics } : undefined;
    },
    reset() {
      previous = undefined;
      emissionCache = undefined;
    },
    identity: { manifestSha256, sourceClosureDigest: manifest.sourceClosureDigest, variant },
  });
}
