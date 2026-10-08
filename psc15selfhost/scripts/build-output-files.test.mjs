import assert from 'node:assert/strict';
import { test } from 'node:test';
import { artifactKey, canonicalArtifact } from './artifact-evidence.mjs';
import { collectBuildOutputFiles } from './build-output-files.mjs';

function fixture() {
  const api = canonicalArtifact(['api'], 'public-api', 'psc-public-api-ir/1');
  const origins = canonicalArtifact({ metadata: true }, 'origin-graph', 'psc-origin-graph/1');
  const internal = canonicalArtifact({ internal: true }, 'internal', 'internal/1');
  const entries = [
    { identity: api.identity, source: { kind: 'output-file', suffix: '.public-api.json' } },
    { identity: origins.identity, source: { kind: 'output-file', suffix: '.origin-graph.json' } },
    { identity: internal.identity, source: { kind: 'archive-required' } },
  ];
  return { graph: { entries }, artifacts: new Map([api, origins, internal].map(item => [artifactKey(item.identity), item.bytes])) };
}

test('new graph products automatically enter the single staging/publication inventory', () => {
  const evidence = fixture();
  const bundle = canonicalArtifact({ bundle: true }, 'artifact-bundle', 'psc-artifact-bundle/1');
  const files = collectBuildOutputFiles(evidence, [{ suffix: '.artifact-bundle.json', record: bundle }]);
  assert.deepEqual(files.map(item => item.suffix), ['.public-api.json', '.origin-graph.json', '.artifact-bundle.json']);
  assert.equal(files[0].bytes, evidence.artifacts.get(artifactKey(evidence.graph.entries[0].identity)));
});

test('duplicate, escaping and receipt-overwriting suffixes reject before publication', () => {
  for (const suffix of ['../escape', '.x/escape', '.checked.json', '.public-api.json']) {
    const evidence = fixture(); evidence.graph.entries[1].source.suffix = suffix;
    assert.throws(() => collectBuildOutputFiles(evidence), /OUTPUT_SUFFIX/);
  }
});

test('missing or changed archived output bytes cannot be published', () => {
  const evidence = fixture(), key = artifactKey(evidence.graph.entries[0].identity);
  evidence.artifacts.set(key, Buffer.from('tampered'));
  assert.throws(() => collectBuildOutputFiles(evidence), /ARTIFACT_BYTES/);
  evidence.artifacts.delete(key);
  assert.throws(() => collectBuildOutputFiles(evidence), /ARTIFACT_BYTES/);
});
