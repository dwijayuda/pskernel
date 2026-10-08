import assert from 'node:assert/strict';
import { test } from 'node:test';
import { canonicalArtifact } from './artifact-evidence.mjs';
import { runDiverseBootstrapCampaign } from './diverse-bootstrap.mjs';

const artifact = (value, domain, contract) => canonicalArtifact(value, domain, contract);

test('DDC runner binds exact source, diversity and same-target stage-2 comparison', async () => {
  const source = artifact({ source: 'compiler' }, 'source-closure', 'fixture-source/1');
  const subject = artifact({ compiler: 'expected' }, 'compiler-binary', 'fixture-compiler/1');
  const trustedId = artifact({ compiler: 'trusted-diverse' }, 'tool', 'fixture-tool/1').identity;
  const executeId = artifact({ compiler: 'stage1-runner' }, 'tool', 'fixture-tool/1').identity;
  const result = await runDiverseBootstrapCampaign({
    sourceClosure: source,
    compilerUnderTest: subject,
    trustedDiverseCompiler: {
      identity: trustedId,
      run: async ({ source }) => {
        assert.equal(source.identity.digest, source.identity.digest);
        return artifact({ compiler: 'stage1' }, 'compiler-binary', 'fixture-compiler/1');
      },
    },
    executeCompiler: {
      identity: executeId,
      run: async ({ source, targetContract }) => {
        assert.equal(source.identity.digest, source.identity.digest);
        assert.equal(targetContract, 'fixture-compiler/1');
        return subject;
      },
    },
    independence: {
      sourceDerivation: ['implementation-a', 'implementation-b'],
      compilerToolchain: ['toolchain-a', 'toolchain-b'],
    },
    resourcePolicy: { wallMs: 1000, memoryBytes: 1024 * 1024 },
  });
  assert.equal(result.kind, 'accepted');
  const evidence = JSON.parse(result.evidence.bytes);
  assert.equal(evidence.result, 'correspondence-observed');
  assert.equal(evidence.compilerCorrectness, 'not-established');
  assert.equal(evidence.releaseAccepted, false);
});

test('DDC runner rejects weak diversity and mismatched stage-2 output', async () => {
  const source = artifact({ source: 'compiler' }, 'source-closure', 'fixture-source/1');
  const subject = artifact({ compiler: 'expected' }, 'compiler-binary', 'fixture-compiler/1');
  const adapter = identity => ({ identity, run: async () => artifact({ compiler: 'different' }, 'compiler-binary', 'fixture-compiler/1') });
  const trustedId = artifact({ tool: 'a' }, 'tool', 'fixture-tool/1').identity;
  const executeId = artifact({ tool: 'b' }, 'tool', 'fixture-tool/1').identity;
  await assert.rejects(runDiverseBootstrapCampaign({
    sourceClosure: source, compilerUnderTest: subject, trustedDiverseCompiler: adapter(trustedId),
    executeCompiler: adapter(executeId), independence: {
      sourceDerivation: ['same', 'same'], compilerToolchain: ['a', 'b'],
    }, resourcePolicy: { wallMs: 1 },
  }), /DIVERSITY_sourceDerivation/);
  const mismatch = await runDiverseBootstrapCampaign({
    sourceClosure: source, compilerUnderTest: subject, trustedDiverseCompiler: adapter(trustedId),
    executeCompiler: adapter(executeId), independence: {
      sourceDerivation: ['a', 'b'], compilerToolchain: ['a', 'b'],
    }, resourcePolicy: { wallMs: 1 },
  });
  assert.equal(mismatch.kind, 'rejectedMismatch');
  assert.equal(mismatch.compilerCorrectness, 'not-established');
});
