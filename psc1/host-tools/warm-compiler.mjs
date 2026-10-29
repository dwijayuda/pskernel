// Private host-owned loaded engine. Source and project objects cannot supply a handle.
import { pathToFileURL } from 'node:url';
import { loadDistribution, resolveEngine } from './installed-engine-resolver.mjs';
const handles = new Map(),
  loadedVariants = new Set();
export async function prepareWarmCompiler(variant) {
  if (loadedVariants.has(variant)) return; // sessionFor still verifies the graph freshly on every request.
  const selected = resolveEngine(variant, loadDistribution());
  if (selected.descriptor.kind !== 'modular-graph') return;
  for (const candidate of [selected.candidate, selected.checkCandidate].filter(Boolean)) {
    const prior = handles.get(candidate.path);
    if (prior && prior.sha256 === candidate.sha256) continue;
    const module = await import(pathToFileURL(candidate.path));
    if (typeof module.psCompilerServiceCandidate !== 'function')
      throw Error('PSC1_WARM_COMPILER_EXPORT');
    handles.set(candidate.path, {
      sha256: candidate.sha256,
      execute: module.psCompilerServiceCandidate,
    });
  }
  loadedVariants.add(variant);
}
export function warmCompiler(file, sha256) {
  const handle = handles.get(file);
  return handle?.sha256 === sha256 ? handle.execute : undefined;
}
