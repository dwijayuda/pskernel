import assert from 'node:assert/strict';
import { test } from 'node:test';
import { execFileSync } from 'node:child_process';
import { decodeDeclarationOrigins, createDeclarationOriginGraph, verifyDeclarationOriginGraph } from './declaration-origins.mjs';
import { publicApiArtifact } from './public-api-artifact.mjs';
import { artifactKey } from './artifact-evidence.mjs';

test('actual observed elaboration preserves admissions and covers generated structure members', async () => {
  const command = process.platform === 'win32' ? '.lake/build/bin/pscv_ir_encoding_tests.exe' : '.lake/build/bin/pscv_ir_encoding_tests';
  const output = JSON.parse(execFileSync(command, ['--origins'], { encoding: 'utf8', maxBuffer: 16 * 1024 * 1024 }));
  const publicApi = publicApiArtifact(output.publicApi);
  const origins = decodeDeclarationOrigins(Buffer.from(output.origins), { sources: output.sources, publicApi: publicApi.bytes });
  assert.equal(origins[2], 2);
  assert.equal(origins[3][0][0], 0);
  const box = origins[3].find(item => item[0] === 1 && item[1].v === 'Box');
  assert.ok(box);
  const boxBatch = origins[3].filter(item => item[0] === 1 && JSON.stringify(item.slice(2)) === JSON.stringify(box.slice(2)));
  assert.ok(boxBatch.length > 1, 'generated structure members must share their actual declaration batch origin');
  const { graph, artifacts } = createDeclarationOriginGraph({ table: output.origins, sources: output.sources, publicApi });
  const records = new Map(artifacts.map(item => [artifactKey(item.identity), item.bytes]));
  const checked = await verifyDeclarationOriginGraph(graph, { resolveArtifact: id => records.get(artifactKey(id)),
    expectedPublicApiId: publicApi.identity, expectedSources: output.sources });
  assert.equal(checked.declarationOriginsChecked, true);
  assert.equal(checked.expressionCorrespondenceChecked, false);
});
