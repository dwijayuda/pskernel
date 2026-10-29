// Host scheduling only. Every language operation calls the unchanged generated compiler.
import fs from 'node:fs';
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
  outputs = true,
}) {
  if (!['js', 'ts'].includes(variant)) fail('VARIANT');
  const check = () => verify(root, readManifestBytes(manifestFile), manifestSha256);
  const manifest = check();
  const load = (owner, name) =>
    import(
      pathToFileURL(
        path.join(root, '@proofscript', owner, 'dist', variant, 'generated', name + '.mjs'),
      )
    );
  const [service, api, ir, json, names, runtime] = await Promise.all([
    load('compiler', 'Ps.Compiler.Service'),
    load('compiler', 'Ps.Compiler.Api'),
    load('compiler-ir', 'Ps.CompilerIr.Validate'),
    load('bridge', 'Ps.Bridge.Json'),
    load('foundation', 'Ps.Foundation.Name'),
    load('foundation', 'runtime'),
  ]);
  check();
  let previous;
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

  function prepare(request) {
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
      const hit =
        compatible &&
        prefix === inputs.length &&
        prefix === old.inputs.length &&
        old.assurance === request.assurance;
      const work = hit
        ? old.work
        : unwrap(service.Ps_Internal_CompilerService_prepare(request, captured));
      // Validate original IR even on a preparation hit. No target transform is claimed for check.
      unwrap(ir.psStrictValidateModule(work.raw));
      previous = {
        kind: request.grammar,
        entry: request.entry,
        assurance: request.assurance,
        inputs,
        states,
        work,
      };
      return {
        captured,
        work,
        cache: { prefixModules: prefix, preparedModules: inputs.length - prefix, finishHit: !!hit },
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
      let activeRequest,
        activeTarget,
        checkingRequest = false;
      try {
        const outer = JSON.parse(text);
        if (!Array.isArray(outer) || outer.length !== 3 || outer[0] !== 'psc1-check-service/1')
          fail('REQUEST');
        const checking = outer[0] === 'psc1-check-service/1',
          target = checking ? 'check' : outer[1];
        checkingRequest = checking;
        activeTarget = target;
        if (checking && outer[1] !== 'check') fail('REQUEST');
        const value = unwrap(json.psJsonParse(JSON.stringify(outer[2])));
        if (tag(value) !== 'array') fail('REQUEST');
        const selected = unwrap(
          service.Ps_Internal_CompilerService_decodeOutputRequestFields(fields(value).values),
        );
        const request = selected.fst;
        activeRequest = request;
        const io = selected.snd,
          { captured, work, cache } = prepare(request);
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
            cache,
            preparationMs: performance.now() - started,
          });
        }
        fail('CHECK_OPERATION_REQUIRED');
      } catch (error) {
        previous = undefined;
        if (error.compilerError && typeof error.compilerError === 'object') {
          const e = error.compilerError;
          if (checkingRequest)
            return JSON.stringify({
              protocol: 'psc1-check-candidate/1',
              status: 'refused',
              phase: e.phase,
              code: e.code,
            });
        }
        throw error;
      } finally {
        check();
      }
    },
    reset() {
      previous = undefined;
    },
    identity: { manifestSha256, sourceClosureDigest: manifest.sourceClosureDigest, variant },
  });
}
