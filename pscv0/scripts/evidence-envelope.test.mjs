import assert from 'node:assert/strict';
import { test } from 'node:test';
import { artifactKey, canonicalArtifact } from './artifact-evidence.mjs';
import { createEvidenceEnvelope, verifyEvidenceEnvelope } from './evidence-envelope.mjs';

const artifact = (value, domain, contract) => canonicalArtifact(value, domain, contract);
test('evidence envelope binds executable and pipeline evidence without minting authority', async () => {
  const executable = artifact({ js: 1 }, 'javascript-output', 'typescript-emitted-file/1');
  const cert = artifact({ cert: 1 }, 'pscv-cert', 'pscv-cert/1');
  const source = artifact({ source: 1 }, 'certified-source', 'psc-certified-source/1');
  const graph = artifact({ graph: 1 }, 'build-graph', 'psc-observed-build-graph/1');
  const archive = artifact({ archive: 1 }, 'build-archive', 'psc-observed-build-archive/1');
  const iface = artifact({ interface: 1 }, 'runtime-interface', 'psc-runtime-interface-json/1');
  const provider = artifact({ provider: 1 }, 'tool-inputs', 'psc-checked-provider-inputs/1');
  const tool = artifact({ tool: 1 }, 'tool-inputs', 'psc-typescript-tool-inputs/1');
  const adapter = artifact({ plan: 1 }, 'abi-plan', 'psc-js-scalar-abi-plan/1');
  const all = [executable, cert, source, graph, archive, iface, provider, tool, adapter];
  const blobs = new Map(all.map(item => [artifactKey(item.identity), item.bytes]));
  const envelope = createEvidenceEnvelope({ executableArtifact: executable.identity, pscvCert: cert.identity,
    certifiedSource: source.identity, buildGraph: graph.identity, buildArchive: archive.identity,
    runtimeInterface: iface.identity, targetAdapters: [adapter.identity], providerInputs: [provider.identity], typeScriptToolInputs: tool.identity });
  const checked = await verifyEvidenceEnvelope(envelope, { resolveArtifact: id => blobs.get(artifactKey(id)), requireRuntimeInterface: true });
  assert.equal(checked.kind, 'accepted');
  assert.equal(checked.authority, 'audit-record-only');
  assert.equal(checked.executablePreservation, 'not-established');
  assert.equal(checked.releaseAccepted, false);
  assert.equal(JSON.parse(envelope.bytes).targetAdapters.length, 1);
  const value = JSON.parse(envelope.bytes); value.executablePreservation = 'proved';
  const forged = canonicalArtifact(value, 'evidence-envelope', 'psc-evidence-envelope/1');
  await assert.rejects(verifyEvidenceEnvelope(forged, { resolveArtifact: id => blobs.get(artifactKey(id)) }), /SCHEMA/);
});
