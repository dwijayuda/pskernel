import { verifyArtifact, artifactKey, canonicalArtifact } from './artifact-evidence.mjs';
import { decodeComparatorJson } from './comparator-export.mjs';
import { decodeIrArtifact, irEncodingContract } from './ir-artifact.mjs';

export const specializationCorrespondenceContract = 'psc-specialization-correspondence/1';
const defaults = Object.freeze({ maxBytes: 128 * 1024 * 1024, maxDepth: 512, maxNodes: 2000000,
  maxWork: 2000000, maxInstances: 16384, maxTypeDepth: 128, maxInstanceKeyBytes: 65536 });
function fail(code, kind = 'rejectedInvalid') {
  const error = new Error('PSC_SPECIALIZATION_' + code); error.kind = kind; throw error;
}

function specializationLimits(resourceLimits) {
  if (Object.keys(resourceLimits).some(key => !Object.hasOwn(defaults, key))) fail('LIMIT_POLICY');
  const bound = { ...defaults, ...resourceLimits };
  if (Object.values(bound).some(value => !Number.isSafeInteger(value) || value < 0)) fail('LIMIT_POLICY');
  if (bound.maxTypeDepth > 512) fail('LIMIT_POLICY');
  return bound;
}

/** Relational checker, independent of the Lean producer and its name mangling.
 * Each target definition must have exactly one source/ground-argument witness.
 * Expression syntax is preserved except generic calls and layout references;
 * scopes, values, operations, evaluation order and public root names are exact.
 * This is conditional on strict input/output IR validity. It neither establishes
 * those invariants nor proves the relation sound for the runtime semantics.
 */
function inspectSpecializationCorrespondence(input, output, resourceLimits, observeInstances) {
  const bound = specializationLimits(resourceLimits);
  const decode = (item, domain) => {
    if (!(item?.bytes instanceof Uint8Array) || item.bytes.byteLength > bound.maxBytes)
      fail('BYTES_EXHAUSTED', 'resourceExhausted');
    verifyArtifact(item.bytes, item.identity);
    if (item.identity.domain !== domain || item.identity.contract !== irEncodingContract) fail('ARTIFACT_CONTRACT');
    return decodeIrArtifact(item.bytes, { maxBytes: bound.maxBytes, maxDepth: bound.maxDepth, maxNodes: bound.maxNodes });
  };
  const source = decode(input, 'verified-ir'), target = decode(output, 'specialized-ir');
  let work = 0;
  const tick = (amount = 1) => {
    if (amount > bound.maxWork - work) fail('WORK_EXHAUSTED', 'resourceExhausted');
    work += amount;
  };
  const same = (a, b) => { tick(); if (a !== b) fail('CORRESPONDENCE'); };
  const equalData = (a, b) => {
    // Only bounded atomic literal/intrinsic tuples use this operation.
    same(JSON.stringify(a), JSON.stringify(b));
  };
  const tables = module => module.slice(2).map(items => {
    const result = new Map();
    for (const item of items) {
      tick(); if (result.has(item[0]) || new Set(item[1]).size !== item[1].length) fail('DUPLICATE_DEFINITION_OR_BINDER');
      result.set(item[0], item);
    }
    return result;
  });
  const original = tables(source), proposed = tables(target);
  for (const table of [original, proposed])
    for (const name of table[0].keys()) if (table[1].has(name)) fail('AMBIGUOUS_TYPE');
  for (const table of proposed) for (const item of table.values()) if (item[1].length) fail('TARGET_GENERIC');
  const pending = [], instances = new Map(), owners = new Map();
  const witnesses = observeInstances ? new Map() : undefined;
  let witnessBytes = 0;
  const schedule = task => { tick(); pending.push(task); };
  function scope(parent, names) {
    tick(names.length); return { parent, names: new Set(names) };
  }
  function local(scopeValue, name) {
    for (let current = scopeValue; current; current = current.parent) {
      tick(); if (current.names.has(name)) return true;
    }
    return false;
  }
  function ground(type, env, depth = 0) {
    tick(); if (depth >= bound.maxTypeDepth) fail('TYPE_DEPTH_EXHAUSTED', 'resourceExhausted');
    switch (type[0]) {
      case 'unknown': fail('UNKNOWN_TYPE'); break;
      case 'typeParameter': {
        if (!env.has(type[1])) fail('UNBOUND_TYPE_PARAMETER');
        // Recheck composed depth and charge expansion even for shared witnesses.
        return ground(env.get(type[1]), empty, depth + 1);
      }
      case 'primitive': return type;
      case 'named': return ['named', type[1], type[2].map(item => ground(item, env, depth + 1))];
      case 'function': return ['function', type[1].map(item => ground(item, env, depth + 1)), ground(type[2], env, depth + 1)];
      default: fail('TYPE');
    }
  }
  function instance(kind, name, arguments_, targetName) {
    tick(); const definition = original[kind].get(name), result = proposed[kind].get(targetName);
    if (!definition || !result || definition[1].length !== arguments_.length) fail('INSTANCE_TARGET_OR_ARITY');
    if (!definition[1].length) same(name, targetName);
    const argumentKey = JSON.stringify(arguments_);
    if (Buffer.byteLength(argumentKey) > bound.maxInstanceKeyBytes) fail('INSTANCE_KEY_EXHAUSTED', 'resourceExhausted');
    const key = JSON.stringify([kind, name, argumentKey]), owner = JSON.stringify([kind, targetName]);
    if (instances.has(key)) { same(instances.get(key), targetName); return; }
    if (owners.has(owner)) fail('INSTANCE_COLLISION');
    if (instances.size >= bound.maxInstances) fail('INSTANCES_EXHAUSTED', 'resourceExhausted');
    instances.set(key, targetName); owners.set(owner, key);
    if (witnesses) {
      const witness = [['structure', 'inductive', 'declaration'][kind], name, arguments_, targetName];
      witnessBytes += Buffer.byteLength(JSON.stringify(witness)) + 1;
      if (witnessBytes > bound.maxBytes) fail('WITNESS_BYTES_EXHAUSTED', 'resourceExhausted');
      witnesses.set(owner, witness);
    }
    schedule({ kind: 'definition', category: kind, a: definition, b: result,
      env: new Map(definition[1].map((binder, index) => [binder, arguments_[index]])) });
  }
  function type(a, b, env) { schedule({ kind: 'type', a: ground(a, env), b }); }
  function types(a, b, env) {
    same(a.length, b.length);
    for (let index = 0; index < a.length; index++) type(a[index], b[index], env);
  }
  function fields(a, b, env) {
    same(a.length, b.length);
    for (let index = 0; index < a.length; index++) { same(a[index][0], b[index][0]); type(a[index][1], b[index][1], env); }
  }
  function expr(a, b, env, locals) { schedule({ kind: 'expr', a, b, env, locals }); }
  function expressions(a, b, env, locals) {
    same(a.length, b.length);
    for (let index = 0; index < a.length; index++) expr(a[index], b[index], env, locals);
  }
  function layout(kind, name, args, targetName, targetArgs, env) {
    same(targetArgs.length, 0);
    instance(kind, name, args.map(item => ground(item, env)), targetName);
  }
  function expressionFields(a, b, env, locals) {
    same(a.length, b.length);
    for (let index = 0; index < a.length; index++) { same(a[index][0], b[index][0]); expr(a[index][1], b[index][1], env, locals); }
  }
  const empty = new Map();
  same(source[1].length, target[1].length);
  const importNames = new Set();
  for (let index = 0; index < source[1].length; index++) {
    const a = source[1][index], b = target[1][index];
    if (importNames.has(a[0]) || original[2].has(a[0]) || proposed[2].has(b[0])) fail('IMPORT_COLLISION');
    importNames.add(a[0]);
    for (let field = 0; field < 3; field++) same(a[field], b[field]);
    type(a[3], b[3], empty);
  }
  // All monomorphic definitions are externally observable roots. Generic
  // definitions are justified only by references encountered from these roots.
  for (let kind = 0; kind < 3; kind++)
    for (const item of original[kind].values()) if (!item[1].length) instance(kind, item[0], [], item[0]);
  while (pending.length) {
    tick(); const { kind, category, a, b, env, locals } = pending.pop();
    if (kind === 'definition') {
      if (category === 0) fields(a[2], b[2], env);
      else if (category === 1) {
        same(a[2].length, b[2].length);
        for (let index = 0; index < a[2].length; index++) {
          same(a[2][index][0], b[2][index][0]); fields(a[2][index][1], b[2][index][1], env);
        }
      } else {
        fields(a[2], b[2], env); type(a[3], b[3], env);
        expr(a[4], b[4], env, scope(null, a[2].map(parameter => parameter[0])));
      }
      continue;
    }
    if (kind === 'type') {
      same(a[0], b[0]);
      if (a[0] === 'primitive') same(a[1], b[1]);
      else if (a[0] === 'function') {
        same(a[1].length, b[1].length);
        for (let index = 0; index < a[1].length; index++) schedule({ kind, a: a[1][index], b: b[1][index] });
        schedule({ kind, a: a[2], b: b[2] });
      } else if (a[0] === 'named') {
        const category = original[0].has(a[1]) ? 0 : original[1].has(a[1]) ? 1 : -1;
        if (category >= 0) { same(b[2].length, 0); instance(category, a[1], a[2], b[1]); }
        else {
          // Built-in/external named type constructors retain their arguments.
          same(a[1], b[1]); same(a[2].length, b[2].length);
          for (let index = 0; index < a[2].length; index++) schedule({ kind, a: a[2][index], b: b[2][index] });
        }
      } else fail('GROUND_TYPE_REQUIRED');
      continue;
    }
    same(a[0], b[0]);
    switch (a[0]) {
      case 'literal': equalData(a[1], b[1]); break;
      case 'var':
        same(a[1], b[1]);
        if (!local(locals, a[1]) && original[2].get(a[1])?.[1].length) fail('GENERIC_VALUE_ESCAPE');
        break;
      case 'intrinsic': equalData(a[1], b[1]); types(a[2], b[2], env); expressions(a[3], b[3], env, locals); break;
      case 'lambda':
        fields(a[1], b[1], env); type(a[2], b[2], env);
        expr(a[3], b[3], env, scope(locals, a[1].map(parameter => parameter[0]))); break;
      case 'call': {
        const generic = a[1][0] === 'var' && !local(locals, a[1][1]) && original[2].get(a[1][1])?.[1].length;
        if (generic) {
          same(b[1][0], 'var'); same(b[2].length, 0);
          if (local(locals, b[1][1])) fail('INSTANCE_CAPTURE');
          instance(2, a[1][1], a[2].map(item => ground(item, env)), b[1][1]);
        } else {
          if (a[2].length || b[2].length) fail('UNSUPPORTED_GENERIC_CALL');
          expr(a[1], b[1], env, locals);
        }
        expressions(a[3], b[3], env, locals); break;
      }
      case 'let':
        same(a[1], b[1]); type(a[2], b[2], env); expr(a[3], b[3], env, locals);
        expr(a[4], b[4], env, scope(locals, [a[1]])); break;
      case 'if': expressions(a.slice(1), b.slice(1), env, locals); break;
      case 'record':
        layout(0, a[1], a[2], b[1], b[2], env); expressionFields(a[3], b[3], env, locals); break;
      case 'projection':
        layout(0, a[1], a[2], b[1], b[2], env); expr(a[3], b[3], env, locals); same(a[4], b[4]); break;
      case 'constructor':
        layout(1, a[1], a[3], b[1], b[3], env); same(a[2], b[2]); expressionFields(a[4], b[4], env, locals); break;
      case 'match':
        layout(1, a[1], a[2], b[1], b[2], env); expr(a[3], b[3], env, locals);
        same(a[4].length, b[4].length);
        for (let index = 0; index < a[4].length; index++) {
          const left = a[4][index], right = b[4][index]; same(left[0], right[0]); same(left[1].length, right[1].length);
          for (let field = 0; field < left[1].length; field++) {
            same(left[1][field][0], right[1][field][0]); same(left[1][field][1], right[1][field][1]);
            type(left[1][field][2], right[1][field][2], env);
          }
          expr(left[2], right[2], env, scope(locals, left[1].map(binding => binding[1])));
        }
        break;
      default: fail('EXPRESSION');
    }
  }
  for (let kind = 0; kind < 3; kind++)
    for (const name of proposed[kind].keys()) if (!owners.has(JSON.stringify([kind, name]))) fail('UNJUSTIFIED_TARGET');
  const result = Object.freeze({ contract: specializationCorrespondenceContract,
    inputId: input.identity, outputId: output.identity, inputKey: artifactKey(input.identity), outputKey: artifactKey(output.identity),
    relation: 'exact-instantiation-with-bijective-instance-names', correspondenceChecked: true,
    resourcePolicy: bound, observed: { work, instances: instances.size },
    requires: ['strict-input-ir-validity', 'strict-output-ir-validity', 'runtime-instantiation-semantics'],
    invariantValidation: false, globalPreservationProved: false, kernelAuthority: false, releaseAccepted: false });
  // Stable target-module order, independently of discovery/worklist order.
  const entries = witnesses ? proposed.flatMap((table, kind) =>
    [...table.keys()].map(name => witnesses.get(JSON.stringify([kind, name])))) : undefined;
  return { result, entries, bound };
}

export function verifySpecializationCorrespondence(input, output, resourceLimits = {}) {
  return inspectSpecializationCorrespondence(input, output, resourceLimits, false).result;
}

export const specializationInstanceMapContract = 'psc-specialization-instance-map/1';

/** Retain witnesses already established by this same bounded relation check.
 * No name-mangling heuristic, producer-supplied witness, or unchecked serialized
 * report can stand in for the relation check.
 */
export function createSpecializationInstanceMap(input, output, resourceLimits = {}) {
  const { result, entries, bound } = inspectSpecializationCorrespondence(input, output, resourceLimits, true);
  const map = canonicalArtifact({ schemaVersion: 1, contract: specializationInstanceMapContract,
    inputId: input.identity, outputId: output.identity, instances: entries,
    order: 'structure-inductive-declaration-then-target-module-order',
    correspondenceContract: specializationCorrespondenceContract,
    invariantValidation: false, globalPreservationProved: false, authority: 'debug-metadata-only'
  }, 'specialization-map', specializationInstanceMapContract);
  if (map.bytes.byteLength > bound.maxBytes) fail('WITNESS_BYTES_EXHAUSTED', 'resourceExhausted');
  return { result, map };
}

export async function verifySpecializationInstanceMap(record, {
  resolveArtifact, expectedInputId, expectedOutputId, resourceLimits = {},
} = {}) {
  verifyArtifact(record.bytes, record.identity);
  if (record.identity.domain !== 'specialization-map' || record.identity.contract !== specializationInstanceMapContract)
    fail('WITNESS_IDENTITY');
  const { maxBytes } = specializationLimits(resourceLimits);
  const value = decodeComparatorJson(record.bytes, { maxBytes, maxDepth: 512, maxNodes: 2000000 });
  if (!value || typeof value !== 'object' || Array.isArray(value) ||
      Object.keys(value).sort().join(',') !==
        'authority,contract,correspondenceContract,globalPreservationProved,inputId,instances,invariantValidation,order,outputId,schemaVersion' ||
      value.contract !== specializationInstanceMapContract || value.schemaVersion !== 1 ||
      artifactKey(value.inputId) !== artifactKey(expectedInputId) || artifactKey(value.outputId) !== artifactKey(expectedOutputId))
    fail('WITNESS_SUBJECT');
  async function resolve(identity) {
    if (!Number.isSafeInteger(identity?.byteLength) || identity.byteLength < 0 || identity.byteLength > maxBytes)
      fail('BYTES_EXHAUSTED', 'resourceExhausted');
    const bytes = await resolveArtifact(identity); verifyArtifact(bytes, identity); return { bytes, identity };
  }
  const input = await resolve(value.inputId), output = await resolve(value.outputId);
  const rebuilt = createSpecializationInstanceMap(input, output, resourceLimits);
  if (artifactKey(rebuilt.map.identity) !== artifactKey(record.identity)) fail('WITNESS_CORRESPONDENCE');
  return rebuilt.result;
}
