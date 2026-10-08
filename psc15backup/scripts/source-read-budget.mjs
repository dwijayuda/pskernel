import { readObservedFileBytes } from './observed-file-bytes.mjs';

export const defaultSourceReadLimits = Object.freeze({ sourceBytes: 128 * 1024 * 1024,
  fileBytes: 16 * 1024 * 1024, manifestBytes: 4 * 1024 * 1024,
  moduleCount: 4096, importEdges: 65536, importDepth: 512 });

export function createSourceReadBudget(overrides = {}) {
  if (Object.keys(overrides).some(key => !Object.hasOwn(defaultSourceReadLimits, key))) throw new Error('PSC_SOURCE_BUDGET_POLICY');
  const limits = Object.freeze({ ...defaultSourceReadLimits, ...overrides });
  if (Object.values(limits).some(value => !Number.isSafeInteger(value) || value < 0)) throw new Error('PSC_SOURCE_BUDGET_POLICY');
  const observed = { sourceBytes: 0, manifestBytes: 0, moduleCount: 0, importEdges: 0, importDepth: 0 };
  function exhausted(resource, value) {
    throw Object.assign(new Error('PSC_SOURCE_RESOURCE_EXHAUSTED: ' + resource),
      { kind: 'resourceExhausted', resource, configured: limits[resource], ...(value === undefined ? {} : { observed: value }) });
  }
  function check(resource, value) { if (!Number.isSafeInteger(value) || value > limits[resource]) exhausted(resource, value); }
  return Object.freeze({
    limits,
    declaredModules(count) {
      if (!Number.isSafeInteger(count) || count < 0) throw new Error('PSC_SOURCE_BUDGET_COUNT');
      check('moduleCount', count);
    },
    module(depth) {
      if (!Number.isSafeInteger(depth) || depth < 0) throw new Error('PSC_SOURCE_BUDGET_DEPTH');
      check('importDepth', depth); check('moduleCount', observed.moduleCount + 1);
      observed.moduleCount++; observed.importDepth = Math.max(observed.importDepth, depth);
    },
    imports(count) {
      if (!Number.isSafeInteger(count) || count < 0) throw new Error('PSC_SOURCE_BUDGET_COUNT');
      check('importEdges', observed.importEdges + count); observed.importEdges += count;
    },
    async read(file, role = 'source') {
      if (!['source', 'manifest'].includes(role)) throw new Error('PSC_SOURCE_READ_ROLE');
      const dimension = role === 'manifest' ? 'manifestBytes' : 'sourceBytes';
      const remaining = limits[dimension] - observed[dimension];
      const cap = role === 'manifest' ? remaining : Math.min(limits.fileBytes, remaining);
      let bytes;
      try { bytes = await readObservedFileBytes(file, cap); }
      catch (error) {
        if (/RESOURCE_EXHAUSTED/u.test(error.message)) exhausted(role === 'source' && limits.fileBytes < remaining ? 'fileBytes' : dimension);
        throw error;
      }
      observed[dimension] += bytes.length;
      try { return new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(bytes); }
      catch { throw Object.assign(new Error('PSC_SOURCE_INVALID_UTF8'), { kind: 'rejectedInvalid' }); }
    },
    snapshot() { return Object.freeze({ contract: 'psc-source-read-budget/1', limits,
      observed: Object.freeze({ ...observed }), enforcement: 'source-read-boundary-only',
      unobserved: Object.freeze(['compiler-internal-work', 'cpu-time', 'peak-memory', 'host-stack']) }); },
  });
}
