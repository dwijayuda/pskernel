import { randomUUID } from 'node:crypto';
import { artifactId, artifactKey, canonicalArtifact, canonicalBytes, verifyArtifact } from './artifact-evidence.mjs';
import { decodeComparatorJson } from './comparator-export.mjs';

export const factoryBenchArms = Object.freeze(['B0', 'B1', 'B2', 'B3', 'B4']);
const copy = value => JSON.parse(canonicalBytes(value));
const natural = value => Number.isSafeInteger(value) && value >= 0;
const text = value => typeof value === 'string' && value.length > 0;
const fail = (code, kind = 'rejectedInvalid') => { throw Object.assign(new Error('PSC_FACTORY_' + code), { kind }); };
const sameId = (left, right) => artifactKey(left) === artifactKey(right);
const maxArtifactBytes = 16 * 1024 * 1024;
function snapshot(item) {
  if (!(item?.bytes instanceof Uint8Array) || item.bytes.byteLength > maxArtifactBytes) fail('ARTIFACT_RESOURCE_EXHAUSTED', 'resourceExhausted');
  const result = { identity: copy(item.identity), bytes: Buffer.from(item.bytes) };
  verifyArtifact(result.bytes, result.identity); return result;
}
function policyValue(policy) {
  policy = snapshot(policy); const value = decodeComparatorJson(policy.bytes);
  if (value.contract !== 'psc-factory-policy/1' || !Array.isArray(value.requiredAssurance) ||
      !value.requiredAssurance.every(text) || !natural(value.minimumTasks) || value.minimumTasks < 1) fail('POLICY');
  for (const field of ['producerId', 'modelId', 'acceptorId', 'toolPolicyId']) artifactKey(value[field]);
  for (const field of ['maxModelCalls', 'maxTokens', 'maxToolCalls', 'maxCandidateBytes', 'maxWallMs']) {
    if (!natural(value.limits?.[field])) fail('LIMIT_POLICY');
  }
  if (value.limits.maxWallMs < 1 || value.limits.maxWallMs > 2147483647 ||
      value.limits.maxCandidateBytes > maxArtifactBytes) fail('LIMIT_POLICY');
  return value;
}

/** Freezing produces a salted commitment plus a PRIVATE vault. The vault must
 * stay outside the factory's filesystem/retrieval boundary. It is not encrypted
 * by this codec; deployment access control is an explicit separate obligation.
 */
export function freezeFactoryHoldout({ tasks, policy }) {
  const selected = policyValue(policy);
  if (!Array.isArray(tasks) || tasks.length < selected.minimumTasks || tasks.length > 10000) fail('TASK_COUNT');
  const ids = new Set();
  const entries = tasks.map(task => {
    if (!text(task.taskId) || ids.has(task.taskId)) fail('TASK_ID');
    ids.add(task.taskId);
    const prompt = snapshot(task.prompt), oracle = snapshot(task.oracle);
    return { taskId: task.taskId, promptId: prompt.identity, promptData: prompt.bytes.toString('base64'),
      oracleId: oracle.identity, oracleData: oracle.bytes.toString('base64') };
  });
  const vault = canonicalArtifact({ contract: 'psc-factory-holdout-private/1', policyId: policy.identity,
    salt: randomUUID(), tasks: entries }, 'factory-private-holdout', 'psc-factory-holdout-private/1');
  const seal = canonicalArtifact({ contract: 'psc-factory-holdout-seal/1', policyId: policy.identity,
    vaultId: vault.identity, taskCount: entries.length, searchableByFactory: false },
  'factory-holdout-seal', 'psc-factory-holdout-seal/1');
  return { seal: snapshot(seal), vault: snapshot(vault) };
}

function openHoldout({ seal, vault }, policy) {
  seal = snapshot(seal); vault = snapshot(vault);
  const publicValue = decodeComparatorJson(seal.bytes), privateValue = decodeComparatorJson(vault.bytes);
  if (publicValue.contract !== 'psc-factory-holdout-seal/1' || privateValue.contract !== 'psc-factory-holdout-private/1' ||
      publicValue.searchableByFactory !== false || !sameId(publicValue.vaultId, vault.identity) ||
      !sameId(publicValue.policyId, policy.identity) || !sameId(privateValue.policyId, policy.identity) ||
      !Array.isArray(privateValue.tasks) || privateValue.tasks.length !== publicValue.taskCount) fail('SEAL');
  const tasks = privateValue.tasks.map(task => {
    function decode(field, identity) {
      if (typeof field !== 'string' || field.length > Math.ceil(maxArtifactBytes / 3) * 4) fail('TASK_BYTES');
      const bytes = Buffer.from(field, 'base64');
      if (bytes.toString('base64') !== field) fail('TASK_BASE64');
      return snapshot({ bytes, identity });
    }
    return { taskId: task.taskId, prompt: decode(task.promptData, task.promptId), oracle: decode(task.oracleData, task.oracleId) };
  });
  if (tasks.some(task => !text(task.taskId)) || new Set(tasks.map(task => task.taskId)).size !== tasks.length ||
      tasks.length < policyValue(policy).minimumTasks) fail('TASK_SET');
  return tasks;
}

/** Execute a balanced B0-B4 campaign using caller-registered adapters. Adapter
 * identities and acceptance/assurance policy are fixed for every arm. Host
 * instrumentation observes calls, token usage, candidates, accepted reuse and
 * wall time. This API is not itself an adversarial process sandbox.
 */
export async function runFactoryBench({ holdout, policy, producer, model, acceptor, corpus = [],
  createReuseSession, validateNegative, toolPolicyId }) {
  holdout = { seal: snapshot(holdout.seal), vault: snapshot(holdout.vault) };
  policy = snapshot(policy); const selected = policyValue(policy), tasks = openHoldout(holdout, policy);
  if (!sameId(producer.identity, selected.producerId) || !sameId(model.identity, selected.modelId) ||
      !sameId(acceptor.identity, selected.acceptorId) || !sameId(toolPolicyId, selected.toolPolicyId)) fail('ADAPTER_POLICY');
  const adapters = { produce: producer.run, model: model.run, accept: acceptor.run };
  if (Object.values(adapters).some(fn => typeof fn !== 'function')) fail('ADAPTER');
  const forbiddenTaskIds = new Set(tasks.map(task => task.taskId));
  const forbiddenBytes = new Set(tasks.flatMap(task => [task.prompt.identity.digest, task.oracle.identity.digest]));
  if (!Array.isArray(corpus) || corpus.length > 4096) fail('CORPUS_RESOURCE_EXHAUSTED', 'resourceExhausted');
  let corpusBytes = 0;
  const index = corpus.map(entry => {
    const item = snapshot(entry.artifact);
    if (!['text', 'knowledge', 'negative'].includes(entry.kind) || !text(entry.text) || !Array.isArray(entry.originTaskIds) ||
        !entry.originTaskIds.every(text) || entry.originTaskIds.some(id => forbiddenTaskIds.has(id)) ||
        forbiddenBytes.has(item.identity.digest) ||
        forbiddenBytes.has(artifactId(Buffer.from(entry.text), 'retrieval-text', 'text/1').digest)) fail('HOLDOUT_RETRIEVAL_LEAKAGE');
    corpusBytes += item.bytes.length + Buffer.byteLength(entry.text);
    if (corpusBytes > 64 * 1024 * 1024) fail('CORPUS_RESOURCE_EXHAUSTED', 'resourceExhausted');
    return { kind: entry.kind, text: entry.text, artifact: item };
  });
  const rows = [], retained = new Map();
  for (const [taskIndex, task] of tasks.entries()) {
    // Rotate arm order deterministically across tasks to expose order effects.
    const arms = factoryBenchArms.slice(taskIndex % 5).concat(factoryBenchArms.slice(0, taskIndex % 5));
    for (const arm of arms) {
      const started = performance.now(), abort = new AbortController(), acquired = new Map(), uses = [];
      let closed = false, modelCalls = 0, tokens = 0, verifierCalls = 0, toolCalls = 0, retrievalCount = 0,
        repairCycles = 0, lastCandidate = null, previousRejected = false, session, tokensComplete = true, modelsPending = 0;
      const elapsed = () => Math.max(0, Math.ceil(performance.now() - started));
      function active() {
        if (closed || abort.signal.aborted || elapsed() > selected.limits.maxWallMs) fail('WALL_RESOURCE_EXHAUSTED', 'resourceExhausted');
      }
      function tool() { active(); if (++toolCalls > selected.limits.maxToolCalls) fail('TOOL_RESOURCE_EXHAUSTED', 'resourceExhausted'); }
      async function verify(candidate) {
        active(); candidate = snapshot(candidate);
        if (candidate.bytes.length > selected.limits.maxCandidateBytes) fail('OUTPUT_RESOURCE_EXHAUSTED', 'resourceExhausted');
        const key = artifactKey(candidate.identity);
        if (previousRejected && lastCandidate !== key) repairCycles++;
        lastCandidate = key; verifierCalls++;
        const subject = { promptId: task.prompt.identity, oracleId: task.oracle.identity, outputId: candidate.identity };
        const checked = await adapters.accept({ prompt: snapshot(task.prompt), oracle: snapshot(task.oracle),
          candidate: snapshot(candidate), subject: copy(subject), signal: abort.signal });
        active();
        if (!checked || !['accepted', 'rejectedInvalid', 'declinedUnsupported', 'resourceExhausted', 'infrastructureUnavailable', 'internalError'].includes(checked.kind)) fail('ACCEPTOR_RESULT', 'internalError');
        previousRejected = checked.kind === 'rejectedInvalid';
        if (checked.kind === 'accepted') {
          if (!canonicalBytes(checked.subject).equals(canonicalBytes(subject)) || !Array.isArray(checked.assurance) ||
              !checked.assurance.every(text)) fail('ACCEPTOR_BINDING', 'internalError');
          if (selected.requiredAssurance.some(item => !checked.assurance.includes(item))) return { kind: 'rejectedInvalid', code: 'assurance-regression' };
        }
        return copy(checked);
      }
      const tools = Object.freeze({
        async model(request) {
          tool(); if (modelCalls >= selected.limits.maxModelCalls) fail('MODEL_RESOURCE_EXHAUSTED', 'resourceExhausted');
          modelCalls++;
          modelsPending++;
          let result;
          try { result = await adapters.model({ request: copy(request), tokenBudget: Math.max(0, selected.limits.maxTokens - tokens), signal: abort.signal }); }
          catch (error) { tokensComplete = false; throw error; }
          finally { modelsPending--; }
          active();
          if (!natural(result?.usage?.inputTokens) || !natural(result?.usage?.outputTokens)) {
            tokensComplete = false; fail('MODEL_USAGE_UNAVAILABLE', 'infrastructureUnavailable');
          }
          tokens += result.usage.inputTokens + result.usage.outputTokens;
          if (!natural(tokens) || tokens > selected.limits.maxTokens) fail('TOKEN_RESOURCE_EXHAUSTED', 'resourceExhausted');
          return copy(result.output);
        },
        async retrieve(query) {
          tool(); if (arm === 'B0') fail('RETRIEVAL_DISABLED');
          if (!text(query) || query.length > 4096) fail('QUERY');
          const results = [];
          for (const entry of index) {
            if (!entry.text.includes(query) || (entry.kind === 'negative' && arm !== 'B4')) continue;
            if (arm === 'B1' || entry.kind === 'text') { results.push({ kind: 'text', text: entry.text }); continue; }
            if (entry.kind === 'negative') {
              if (typeof validateNegative !== 'function') continue;
              const valid = await validateNegative(snapshot(entry.artifact), snapshot(task.prompt));
              active(); if (valid?.kind !== 'accepted' || valid.authority !== 'advisory') continue;
              results.push({ kind: 'negative', objectId: entry.artifact.identity, text: entry.text, authority: 'advisory' });
            } else {
              if (!session) fail('KNOWLEDGE_VALIDATOR_UNAVAILABLE', 'infrastructureUnavailable');
              const handle = await session.acquire([entry.artifact.identity]); active();
              acquired.set(artifactKey(entry.artifact.identity), handle);
              results.push({ kind: 'knowledge', objectId: entry.artifact.identity,
                object: decodeComparatorJson(entry.artifact.bytes), text: entry.text });
            }
          }
          retrievalCount += results.length; return copy(results);
        },
        async reuse({ objectId, operationId, input }) {
          tool(); if (!['B3', 'B4'].includes(arm)) fail('REUSE_DISABLED');
          const handle = acquired.get(artifactKey(objectId));
          if (!session || !handle) fail('REUSE_REQUIRES_VALID_RETRIEVAL');
          if (arm === 'B3' && !['theorem', 'interface', 'pass'].includes(session.operationInfo(operationId).useType)) fail('USE_TYPE_DISABLED');
          const supplied = snapshot(input);
          const used = await session.apply(handle, { operationId, task: task.prompt, input: supplied }); active();
          uses.push({ ...used, input: supplied }); return { output: snapshot(used.output), useToken: uses.length - 1 };
        },
        async verify(candidate) { tool(); return verify(candidate); },
      });
      let timer, outcome, outputId = null, evidenceBytes = 0, reuseEvents = [], assurance = [];
      try {
        if (typeof createReuseSession === 'function') session = createReuseSession(snapshot(task.prompt), snapshot(task.oracle), arm);
        const run = (async () => {
          const proposed = await adapters.produce({ taskId: task.taskId, prompt: snapshot(task.prompt), arm, tools, signal: abort.signal });
          active(); const candidate = snapshot(proposed.candidate);
          outputId = candidate.identity; evidenceBytes = candidate.bytes.length;
          retained.set(artifactKey(candidate.identity), snapshot(candidate));
          const result = await verify(candidate);
          if (result.kind !== 'accepted') return result;
          assurance = result.assurance;
          const useTokens = proposed.usedTokens ?? [];
          if (!Array.isArray(useTokens) || !useTokens.every(natural) || new Set(useTokens).size !== useTokens.length || useTokens.some(token => token >= uses.length)) fail('REUSE_TOKENS');
          if (useTokens.length) {
            const accepted = await session.accept({ task: task.prompt, output: candidate,
              uses: useTokens.map(token => uses[token].execution), counterfactualArm: arm,
              costObservation: { modelCalls, tokens, toolCalls, verifierCalls, wallMs: elapsed() } });
            active(); if (accepted?.kind !== 'accepted') return accepted;
            reuseEvents = accepted.events.map(snapshot); evidenceBytes += reuseEvents.reduce((sum, event) => sum + event.bytes.length, 0);
            for (const event of reuseEvents) retained.set(artifactKey(event.identity), event);
            for (const token of useTokens) {
              const use = uses[token];
              for (const artifact of [use.record, use.input, use.output]) retained.set(artifactKey(artifact.identity), snapshot(artifact));
            }
          }
          return result;
        })();
        outcome = await Promise.race([run, new Promise(resolve => {
          timer = setTimeout(() => { abort.abort(); resolve({ kind: 'resourceExhausted', code: 'wall-time' }); }, selected.limits.maxWallMs);
        })]);
      } catch (error) { outcome = { kind: error.kind ?? 'internalError', code: error.message }; }
      finally {
        closed = true; clearTimeout(timer); abort.abort();
        if (modelsPending) tokensComplete = false;
        if (session) {
          const counts = session.measurements();
          verifierCalls += counts.graphChecks + counts.certificateChecks + counts.outputChecks;
          session.close();
        }
      }
      rows.push({ taskId: task.taskId, arm, outcome: outcome?.kind ?? 'internalError', code: outcome?.code ?? null,
        outputId, metrics: { accepted: outcome?.kind === 'accepted', humanInterventions: 0, modelCalls, tokens, tokensComplete,
          wallMs: elapsed(), verifierCalls, repairCycles, retrievalCount, reuseCount: reuseEvents.length,
          evidenceBytes, resourceCost: { toolCalls, cpuMicros: null, peakRssBytes: null }, assurance },
        reuseEventIds: reuseEvents.map(event => event.identity) });
    }
  }
  const summary = factoryBenchArms.map(arm => {
    const group = rows.filter(row => row.arm === arm);
    return { arm, attempts: group.length, accepted: group.filter(row => row.metrics.accepted).length,
      tokens: group.reduce((sum, row) => sum + row.metrics.tokens, 0), wallMs: group.reduce((sum, row) => sum + row.metrics.wallMs, 0),
      tokensComplete: group.every(row => row.metrics.tokensComplete),
      reuseCount: group.reduce((sum, row) => sum + row.metrics.reuseCount, 0),
      assuranceRegressions: group.filter(row => row.code === 'assurance-regression').length };
  });
  const campaign = canonicalArtifact({ contract: 'psc-factory-campaign/1', sealId: holdout.seal.identity, policyId: policy.identity,
    arms: factoryBenchArms, rows, summary, selfAmplification: 'not-established', releaseAccepted: false,
    measurementScope: 'host-instrumented adapter calls, graph/certificate/output checks; adapter-internal calls and external CPU/RSS unobserved; no human intervention API',
    remainingAssurance: ['independent sealed real task selection', 'retrieval contamination audit beyond exact bytes and declared provenance',
      'adversarial process isolation and actual model/tool identity attestation', 'statistical interpretation of accepted output, cost and assurance'] },
  'factory-campaign', 'psc-factory-campaign/1');
  return { ...campaign, privateArtifacts: [...retained.values()] };
}
