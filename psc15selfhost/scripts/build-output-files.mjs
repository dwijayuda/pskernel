import { artifactKey, verifyArtifact } from './artifact-evidence.mjs';

/** One inventory drives both staging writes and publication. Graph outputs
 * always use their archived bytes; incidental tool-created files are excluded.
 * Explicit extras are top-level evidence products not contained in the graph.
 */
export function collectBuildOutputFiles(evidence, extras = []) {
  const files = [], suffixes = new Set();
  function add(suffix, record) {
    if (typeof suffix !== 'string' || !/^\.[a-zA-Z0-9]+(?:[.-][a-zA-Z0-9]+)*$/u.test(suffix) ||
        suffix === '.checked.json' || suffixes.has(suffix)) throw new Error('PSC_BUILD_OUTPUT_SUFFIX');
    verifyArtifact(record.bytes, record.identity);
    suffixes.add(suffix); files.push(Object.freeze({ suffix, identity: record.identity, bytes: record.bytes }));
  }
  for (const entry of evidence.graph.entries) {
    if (entry.source.kind !== 'output-file') continue;
    add(entry.source.suffix, { identity: entry.identity, bytes: evidence.artifacts.get(artifactKey(entry.identity)) });
  }
  for (const extra of extras) add(extra.suffix, extra.record);
  return Object.freeze(files);
}
