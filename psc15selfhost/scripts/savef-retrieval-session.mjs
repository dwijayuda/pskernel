import { randomUUID } from 'node:crypto';
import { artifactKey, canonicalBytes, verifyArtifact } from './artifact-evidence.mjs';
import { querySavefSemanticIndex } from './savef-index.mjs';
import { knowledgeContract } from './savef-graph.mjs';

const fail = code => { throw new Error('PSC_SAVEF_RETRIEVAL_' + code); };
const copy = value => JSON.parse(canonicalBytes(value));

/** Persistent index -> fresh ValidUnder -> tool candidates.
 * Index hits alone are never returned as valid knowledge. Live tokens authorize
 * only calls into the configured knowledge-reuse session; they are not kernel,
 * CertifiedSource, cache, or release capabilities.
 */
export function createSavefRetrievalSession({
  indexRoot,
  reuseSession,
  resolveArtifact,
  limits,
}) {
  if (typeof indexRoot !== 'string' || !indexRoot ||
      !reuseSession || typeof reuseSession.acquire !== 'function' ||
      typeof reuseSession.apply !== 'function' ||
      typeof reuseSession.operationInfo !== 'function' ||
      typeof resolveArtifact !== 'function') fail('CONFIGURATION');
  let closed = false;
  const handles = new Map();
  function open() { if (closed) fail('CLOSED'); }
  return Object.freeze({
    async retrieve(query = {}) {
      open();
      const indexed = await querySavefSemanticIndex({ root: indexRoot, ...copy(query), limits });
      open();
      const results = [];
      for (const objectId of indexed.candidates) {
        const bytes = Buffer.from(await resolveArtifact(objectId));
        verifyArtifact(bytes, objectId);
        if (objectId.domain !== 'knowledge-object' || objectId.contract !== knowledgeContract) fail('OBJECT_ID');
        const value = JSON.parse(bytes);
        const handle = await reuseSession.acquire([objectId]);
        open();
        const token = randomUUID();
        handles.set(token, { handle, objectId: copy(objectId) });
        results.push(Object.freeze({
          token,
          objectId: copy(objectId),
          kind: value.kind,
          authorityClass: value.authorityClass,
          scope: copy(value.scope),
          claims: copy(value.claims),
          assumptions: copy(value.assumptions),
          payloadId: copy(value.payload),
          object: copy(value),
          authority: 'freshly-validated-retrieval-candidate',
        }));
      }
      return Object.freeze({
        indexId: copy(indexed.indexId),
        results: Object.freeze(results),
        authority: 'validated-knowledge-context-not-semantic-authority',
      });
    },
    operationInfo(operationId) {
      open();
      return reuseSession.operationInfo(operationId);
    },
    async reuse({ token, operationId, task, input }) {
      open();
      const selected = handles.get(token);
      if (!selected) fail('TOKEN');
      const result = await reuseSession.apply(selected.handle, { operationId, task, input });
      open();
      if (!handles.has(token)) fail('REVOKED');
      return Object.freeze({
        ...result,
        knowledgeObjectId: copy(selected.objectId),
        authority: 'observed-validated-knowledge-operation',
      });
    },
    revoke(token) {
      open();
      if (!handles.delete(token)) fail('TOKEN');
    },
    measurements() {
      open();
      return reuseSession.measurements();
    },
    close() {
      if (!closed) {
        handles.clear();
        reuseSession.close();
        closed = true;
      }
    },
  });
}
