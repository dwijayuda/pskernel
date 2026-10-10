// Host-owned adapter for an active private child connection. JSON values are
// audit facts only. A copied/deserialized value never becomes a local handle.
import { createHash } from 'node:crypto';
import { createFrontendTransport } from './frontend-transport.mjs';
import { freezeDataGraph } from './checked-session.mjs';
const hash = text => createHash('sha256').update(text, 'utf8').digest('hex');
export async function createCompilerProcess({ compilerSha256, kernelIdentity, checkAdmissions, limits, signal }) {
  if (!/^[a-f0-9]{64}$/u.test(compilerSha256) || typeof checkAdmissions !== 'function') throw new Error('PSC_FRONTEND_HOST_IDENTITY');
  const identity = freezeDataGraph(structuredClone(kernelIdentity));
  let accepted, checkedOnce = false;
  const handles = new WeakSet();
  const transport = createFrontendTransport({ script: new URL('./frontend-worker.mjs', import.meta.url), limits, signal, onAdmissions: async text => {
    if (accepted) throw new Error('PSC_FRONTEND_MULTIPLE_ADMISSIONS');
    const result = await checkAdmissions(text);
    for (const [key, value] of Object.entries(identity)) if (result?.[key] !== value) throw new Error('PSC_FRONTEND_KERNEL_IDENTITY: ' + key);
    if (result.accepted !== true || 'errorKind' in result || 'declarationIndex' in result) throw new Error('PSC_FRONTEND_KERNEL_REJECTED: ' + String(result?.errorKind || 'invalid acceptance'));
    accepted = hash(text);
    return result;
  } });
  try {
    const facts = await transport.request('init', { compilerSha256, kernelIdentity: identity });
    if (facts?.pid !== transport.stats().childPid || facts.compilerSha256 !== compilerSha256 || facts.psProofScriptGrammarEdition !== 'ps-0.9-r3' || facts.psProofScriptGrammarMode !== 'new-only') throw new Error('PSC_FRONTEND_INIT_IDENTITY');
    function current(handle) {
      transport.assertAlive();
      if (!handle || typeof handle !== 'object' || !handles.has(handle)) throw new Error('PSC2_CHECKED_UNCHECKED_MODULE');
    }
    return Object.freeze({
      psProofScriptGrammarEdition: facts.psProofScriptGrammarEdition,
      psProofScriptGrammarMode: facts.psProofScriptGrammarMode,
      async readSourceImports(source, kind) {
        const names = await transport.request('imports', { source, kind });
        if (!Array.isArray(names) || names.length > 2048 || names.some(n => typeof n !== 'string' || !/^[A-Za-z_][A-Za-z_0-9]*(?:\.[A-Za-z_][A-Za-z_0-9]*)*$/u.test(n))) throw new Error('PSC_FRONTEND_IMPORT_SHAPE');
        return names;
      },
      async checkSources(kind, sources, binding) {
        if (checkedOnce) throw new Error('PSC_FRONTEND_CHECK_REUSE');
        checkedOnce = true;
        const texts = sources.slice(), bound = freezeDataGraph(structuredClone(binding));
        const result = await transport.request('check', { kind, sources: texts, binding: bound });
        if (!accepted || result?.canonicalAdmissionsSha256 !== accepted || result.sourceSha256 !== hash(texts.join('\n\n') + '\n') || JSON.stringify(result.binding) !== JSON.stringify(bound)) throw new Error('PSC_FRONTEND_ACCEPTED_BINDING');
        const handle = Object.freeze({ canonicalAdmissionsSha256: accepted, sourceSha256: result.sourceSha256, binding: bound, provider: identity });
        handles.add(handle); return handle;
      },
      async emit(handle) {
        current(handle);
        const result = await transport.request('emit');
        if (typeof result !== 'string' || Buffer.byteLength(result) > 32 * 1024 * 1024) throw new Error('PSC_FRONTEND_EMIT_SHAPE');
        return result;
      },
      async assertCurrent(handle) { current(handle); if (await transport.request('assert-current') !== true) throw new Error('PSC_FRONTEND_CURRENT_SHAPE'); },
      stats: () => transport.stats(),
      close: () => transport.close(),
    });
  } catch (error) { await transport.close(); throw error; }
}
