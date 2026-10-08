import { randomUUID } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import { canonicalArtifact, canonicalBytes, artifactId, artifactKey, verifyArtifact } from './artifact-evidence.mjs';
import { comparatorAdmissionsInterface, decodeComparatorExport, comparatorExportLimits, ComparatorExportError } from './comparator-export.mjs';
import { runIsolatedProducer, isolatedProducerArgs } from './isolated-producer.mjs';
import { checkAdmissionsWithKernel } from './checked-kernel-provider.mjs';
import { checkedKernelIdentity } from './checked-kernel-identity.mjs';
import { assertProviderSecurity } from './provider-security.mjs';
import { semanticDecision } from './checked-kernel-dual.mjs';

const axes = ['theoryOrigin', 'algorithmOrigin', 'sourceDerivation', 'implementationLanguage', 'compilerToolchain',
  'runtime', 'memoryManager', 'parserOrDecoder', 'sharedGeneratedSources', 'sharedLibraries', 'organization',
  'reviewLineage', 'proofFoundation', 'hardwareClass'];
const copy = value => JSON.parse(canonicalBytes(value));
const outcome = (kind, code, details = {}) => ({ kind, code, ...details, authority: 'none' });

/** The caller chooses trusted checkers, reference statements and theory base.
 * Producer-selected descriptors never choose a checker or acceptance policy.
 * Additional-axiom policy is closed; opaque/unsafe/unknown exports are declined.
 */
export async function createComparatorSession({ theoryBase, providers = ['lean434-wasm', 'pskernel-core'],
  securityProfile = 'compatibility-v1', independence, requiredDiversityAxes = ['algorithmOrigin', 'sourceDerivation'],
  requireModelCheck = false, modelChecker, check = checkAdmissionsWithKernel, produce = runIsolatedProducer } = {}) {
  if (!theoryBase) throw new Error('PSC_COMPARATOR_THEORY_BASE_REQUIRED');
  verifyArtifact(theoryBase.bytes, theoryBase.identity);
  const theoryIdentity = copy(theoryBase.identity);
  const selected = [...providers];
  if (typeof requireModelCheck !== 'boolean') throw new Error('PSC_COMPARATOR_MODEL_POLICY');
  if (selected.length < 2 || selected.length > 4 || new Set(selected).size !== selected.length) throw new Error('PSC_COMPARATOR_CHECKER_SET');
  const identities = selected.map(checkedKernelIdentity);
  const securities = selected.map(provider => assertProviderSecurity(provider, securityProfile));
  if (identities.some(value => value.profile !== identities[0].profile)) throw new Error('PSC_COMPARATOR_SEMANTIC_PROFILE');
  const registry = copy(independence ?? JSON.parse(await readFile(new URL('../profiles/assurance/INDEPENDENCE_VECTORS.json', import.meta.url), 'utf8')));
  if (registry.contract !== 'psc-independence-vector/1' || registry.semanticProfile !== identities[0].profile) throw new Error('PSC_COMPARATOR_INDEPENDENCE_PROFILE');
  const vectors = selected.map(provider => {
    const declared = registry.providers?.[provider];
    if (!declared) throw new Error('PSC_COMPARATOR_INDEPENDENCE_MISSING');
    return { provider, axes: Object.fromEntries(axes.map(axis => [axis, declared[axis] ?? 'unknown'])) };
  });
  for (const axis of requiredDiversityAxes) {
    if (!axes.includes(axis)) throw new Error('PSC_COMPARATOR_DIVERSITY_AXIS');
    const values = vectors.map(value => value.axes[axis]);
    if (values.some(value => value === 'unknown') || new Set(values.map(value => canonicalBytes(value).toString())).size < 2) throw new Error('PSC_COMPARATOR_DIVERSITY_NOT_ESTABLISHED');
  }
  const vectorArtifact = canonicalArtifact({ contract: registry.contract, vectors, requiredDiversityAxes }, 'independence', registry.contract);
  const challenges = new WeakMap(), accepted = new WeakMap(), active = new Set();
  let closed = false;
  function requireOpen() { if (closed) throw new Error('PSC_COMPARATOR_SESSION_CLOSED'); }
  function checked(handle) {
    requireOpen(); const value = accepted.get(handle);
    if (!value) throw new Error('PSC_COMPARATOR_NOT_A_LIVE_ACCEPTANCE');
    return value;
  }
  return Object.freeze({
    issue({ source, referenceAdmissions, producer, limits = {} }) {
      requireOpen(); verifyArtifact(source.bytes, source.identity);
      const bound = copy({ ...comparatorExportLimits, checkerWallTimeMs: 60000, producerWallTimeMs: 60000, ...limits });
      if (Object.values(bound).some(value => !Number.isSafeInteger(value) || value < 0)) throw new Error('PSC_COMPARATOR_BUDGET');
      if (source.bytes.length > bound.maxBytes) throw new Error('PSC_COMPARATOR_SOURCE_LIMIT');
      const expected = comparatorAdmissionsInterface(referenceAdmissions, bound);
      const configuration = copy(producer);
      isolatedProducerArgs({ ...configuration, name: 'pscv-00000000-0000-0000-0000-000000000000' });
      const value = { contract: 'psc-comparator-challenge/1', nonce: randomUUID(), sourceClosureId: source.identity,
        expectedInterfaceId: expected.identity, theoryBaseId: theoryIdentity, semanticProfile: identities[0].profile,
        providers: selected, securityProfile, independenceId: vectorArtifact.identity, requireModelCheck,
        additionalAssumptionPolicy: 'closed', producer: { image: configuration.image,
          command: configuration.command, policy: configuration.policy }, limits: bound };
      const artifact = canonicalArtifact(value, 'challenge', 'psc-comparator-challenge/1');
      const handle = Object.freeze({ identity: artifact.identity, value: copy(value) });
      challenges.set(handle, { challenge: { identity: artifact.identity, value: copy(value) }, configuration,
        source: Buffer.from(source.bytes), used: false });
      return handle;
    },
    async run(handle, { signal } = {}) {
      requireOpen();
      const state = challenges.get(handle);
      if (!state || state.used) return outcome('rejected', 'challenge-not-live-or-already-used');
      state.used = true;
      const controller = new AbortController(); active.add(controller);
      const cancel = () => controller.abort(); signal?.addEventListener('abort', cancel, { once: true });
      if (signal?.aborted) cancel();
      try {
        const { challenge } = state, bound = challenge.value.limits;
        const request = canonicalBytes({ challenge, sourceBase64: state.source.toString('base64') }, { maxBytes: bound.maxBytes });
        const produced = await produce({ ...state.configuration, input: request, signal: controller.signal,
          limits: { inputBytes: bound.maxBytes, stdoutBytes: bound.maxBytes, stderrBytes: 65536, wallTimeMs: bound.producerWallTimeMs } });
        if (closed || controller.signal.aborted) return outcome('resourceExhausted', 'comparison-cancelled');
        if (produced.kind !== 'accepted') return outcome(produced.kind === 'resourceExhausted' ? 'resourceExhausted' :
          produced.kind === 'declinedUnsupported' ? 'inconclusive' : 'infrastructureFailure', 'producer-failed', { detail: produced });
        if (produced.isolation?.contract !== 'psc-isolated-producer/1' || produced.isolation.image !== challenge.value.producer.image ||
            !canonicalBytes(produced.isolation.policy).equals(canonicalBytes(challenge.value.producer.policy))) {
          return outcome('infrastructureFailure', 'producer-isolation-binding');
        }
        const decoded = decodeComparatorExport(produced.value.stdout, challenge, bound);
        const count = JSON.parse(decoded.admissions).admissions.length;
        const decisions = [];
        for (let index = 0; index < selected.length; index++) {
          if (closed || controller.signal.aborted) return outcome('resourceExhausted', 'comparison-cancelled');
          const checkedResult = await check(decoded.admissions, selected[index], { securityProfile, timeoutMs: bound.checkerWallTimeMs });
          for (const [field, expected] of Object.entries(identities[index])) {
            if (checkedResult.result?.[field] !== expected) return outcome('infrastructureFailure', 'checker-identity-mismatch');
          }
          decisions.push(semanticDecision(checkedResult.result, count));
        }
        if (decisions.some(value => value === 'inconclusive') || new Set(decisions).size !== 1) return outcome('inconclusive', 'checker-disagreement-or-unknown', { decisions });
        if (decisions[0] !== 'accepted') return outcome('rejected', 'kernel-rejection', { decisions });
        const admissionsId = artifactId(Buffer.from(decoded.admissions), 'canonical-admissions', 'proofscript-checked-admissions/2');
        let modelEvidence = null;
        if (requireModelCheck) {
          if (typeof modelChecker !== 'function') return outcome('inconclusive', 'model-checker-unavailable');
          modelEvidence = await modelChecker(decoded.admissions, copy(challenge.value));
          if (modelEvidence?.verified !== true || artifactKey(modelEvidence.admissionsId) !== artifactKey(admissionsId) ||
              artifactKey(modelEvidence.theoryBaseId) !== artifactKey(theoryIdentity)) return outcome('inconclusive', 'model-check-not-established');
        }
        if (closed || controller.signal.aborted) return outcome('resourceExhausted', 'comparison-cancelled');
        const receipt = { contract: 'psc-comparator-acceptance/1', challengeId: challenge.identity,
          sourceClosureId: challenge.value.sourceClosureId, admissionsId, interfaceId: decoded.interface.identity,
          theoryBaseId: theoryIdentity, providerIdentities: identities, providerSecurity: securities,
          independence: JSON.parse(vectorArtifact.bytes), producerIsolation: copy(produced.isolation),
          additionalAssumptions: [], modelEvidence, executablePreservation: 'not-established' };
        const evidence = canonicalArtifact(receipt, 'comparator-acceptance', 'psc-comparator-acceptance/1');
        const capability = Object.freeze({ capability: 'psc-live-comparator-acceptance/1', evidenceId: evidence.identity });
        accepted.set(capability, { admissions: decoded.admissions, receipt: copy(receipt) });
        return { kind: 'accepted', value: capability, evidence: { identity: evidence.identity, value: copy(receipt) } };
      } catch (error) {
        if (error instanceof ComparatorExportError) return outcome(error.kind, error.code);
        if (/EXHAUSTED|SOURCE_LIMIT/u.test(error.message) || error.code === 'ETIMEDOUT') return outcome('resourceExhausted', 'comparison-budget');
        return outcome('infrastructureFailure', error.code ?? error.message);
      } finally { active.delete(controller); signal?.removeEventListener('abort', cancel); }
    },
    describe(handle) { return copy(checked(handle).receipt); },
    checkedAdmissions(handle) { return checked(handle).admissions; },
    revoke(handle) { checked(handle); accepted.delete(handle); },
    close() { closed = true; for (const controller of active) controller.abort(); },
  });
}
