import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';

// Read-only observations of the exact prepared/Core and IR objects already
// produced by buildGeneration. The isolated probe is elaborated, never merged
// into the authoritative closure and never erased or emitted as a compiler.
const sha256 = (value) => createHash('sha256').update(value).digest('hex');
const referenceRef = '5e3a991088aaa735c8f324c4e70a7a3dee4cd69a';
const manifests = {
  F1: 'fbb5cabc6d48f16a0e91c1c4a92c6849791968b7',
  F2: 'ce035d30d64341e3214f241d682c61dac4922649',
};
const listOf = (type) => ['List', type];
const except = (error, result) => ['Except', error, result];

// Each source type and argument order is transcribed from the exact original
// public signature in the pinned manifests. Function-result state parameters
// occupy the same positions after moving into ordinary declaration headers.
const workers = [
  {
    family: 'F1', name: 'psErasureLocalNameWithFuel', outerArguments: 3,
    parameters: [['scope', 'PsErasureScope'], ['base', 'String'], ['fuel', 'Nat'], ['index', 'Nat']],
    result: 'String',
  },
  {
    family: 'F1', name: 'psErasureEtaNameWithFuel', outerArguments: 3,
    parameters: [['body', 'PsVerifiedIrExpr'], ['used', listOf('PsVerifiedIrParameter')],
      ['fuel', 'Nat'], ['index', 'Nat']],
    result: except('PsErasureError', 'String'),
  },
  {
    family: 'F1', name: 'psTsFreshMatchTempWorker', outerArguments: 2,
    parameters: [['expr', 'PsVerifiedIrExpr'], ['attempts', 'Nat'], ['index', 'Nat']],
    result: 'String',
  },
  {
    family: 'F1', name: 'psTsFreshInternalWorker', outerArguments: 3,
    parameters: [['used', listOf('String')], ['namePrefix', 'String'], ['attempts', 'Nat'], ['index', 'Nat']],
    result: 'PsTsFreshNameResult',
  },
  {
    family: 'F2', name: 'psCompilerPreparationSourcesWorker', outerArguments: 1,
    parameters: [['sources', listOf('String')], ['state', 'PsCompilerPreparationState']],
    result: except('PsCompilerError', 'PsCompilerPreparationState'),
  },
  {
    family: 'F2', name: 'psAddDeclarationListWorker', outerArguments: 1,
    parameters: [['declarations', listOf('PsDeclaration')], ['environment', 'PsEnvironment']],
    result: except('PsElabError', 'PsEnvironment'),
  },
  {
    family: 'F2', name: 'psElabDeclarationsWorker', outerArguments: 1,
    parameters: [['sources', listOf('PsSyntaxDeclaration')], ['environment', 'PsEnvironment'],
      ['declarationsRev', listOf('PsDeclaration')]],
    result: except('PsElabError', 'PsElabModuleResult'),
  },
  {
    family: 'F2', name: 'psBuildErasureDeclarationNamesWorker', outerArguments: 1,
    parameters: [['declarations', listOf('PsDeclaration')], ['state', 'PsErasureNameState']],
    result: 'PsErasureNameState',
  },
  {
    family: 'F2', name: 'psEraseDefinitionsLoopWorker', outerArguments: 3,
    parameters: [['environment', 'PsEnvironment'], ['scope', 'PsErasureScope'],
      ['declarations', listOf('PsDeclaration')], ['declarationsRev', listOf('PsVerifiedIrDeclaration')]],
    result: except('PsErasureError', listOf('PsVerifiedIrDeclaration')),
  },
  {
    family: 'F2', name: 'psPrepareRuntimeStructures', outerArguments: 3,
    parameters: [['environment', 'PsEnvironment'], ['declarations', listOf('PsDeclaration')],
      ['inputs', listOf('PsDeclaration')], ['scope', 'PsErasureScope'],
      ['structuresRev', listOf('PsVerifiedIrStructure')]],
    result: except('PsErasureError', 'PsPreparedStructuresResult'),
  },
  {
    family: 'F2', name: 'psPrepareRuntimeInductives', outerArguments: 3,
    parameters: [['environment', 'PsEnvironment'], ['declarations', listOf('PsDeclaration')],
      ['inputs', listOf('PsDeclaration')], ['scope', 'PsErasureScope'],
      ['irRev', listOf('PsVerifiedIrInductive')]],
    result: except('PsErasureError', 'PsPreparedInductivesResult'),
  },
  {
    family: 'F2', name: 'psTsBuildSymbolMap', outerArguments: 2,
    parameters: [['namePrefix', 'String'], ['names', listOf('String')], ['state', 'PsTsSymbolMapState']],
    result: 'PsTsSymbolMapState',
  },
];

function typeSource(type) {
  if (typeof type === 'string') return type;
  assert(Array.isArray(type) && type.length >= 2, 'PSC0_SH1_MIGRATION_TYPE_SPEC');
  return type[0] + ' ' + type.slice(1).map((argument) =>
    Array.isArray(argument) ? '(' + typeSource(argument) + ')' : typeSource(argument)).join(' ');
}

function fullTypeSource(worker, start = 0) {
  return worker.parameters.slice(start).map(([, type]) => typeSource(type))
    .concat(typeSource(worker.result)).join(' -> ');
}

function collectAbstractTypes(type, names) {
  if (typeof type === 'string') {
    if (type !== 'Nat' && type !== 'String') names.add(type);
    return;
  }
  assert(type[0] === 'List' || type[0] === 'Except', 'PSC0_SH1_MIGRATION_TYPE_CONSTRUCTOR');
  for (const argument of type.slice(1)) collectAbstractTypes(argument, names);
}

function signatureSource() {
  const names = new Set();
  for (const worker of workers) {
    for (const [, type] of worker.parameters) collectAbstractTypes(type, names);
    collectAbstractTypes(worker.result, names);
  }
  // These axioms model the unchanged monomorphic Type names only. The exact
  // actual worker types, including universe arguments, are compared below.
  const lines = [...names].sort().map((name) => 'axiom ' + name + ' : Type');
  workers.forEach((worker, index) => {
    lines.push('axiom sh1MigrationExpected' + index + ' : ' + fullTypeSource(worker));
  });
  workers.forEach((worker, index) => {
    const before = worker.parameters.slice(0, worker.outerArguments);
    const after = worker.parameters.slice(worker.outerArguments);
    assert(before.length > 0 && after.length > 0, 'PSC0_SH1_MIGRATION_PARTIAL_BOUNDARY');
    lines.push(
      'def sh1MigrationPartial' + index,
      '    (worker : ' + fullTypeSource(worker) + ')',
      ...worker.parameters.map(([name, type]) => '    (' + name + ' : ' + typeSource(type) + ')'),
      '    : ' + typeSource(worker.result) + ' :=',
      '  let next : ' + fullTypeSource(worker, worker.outerArguments) +
        ' := worker ' + before.map(([name]) => name).join(' ') + ';',
      '  next ' + after.map(([name]) => name).join(' '),
    );
  });
  return lines.join('\n') + '\n';
}

const isolatedSource = signatureSource();

function array(value, valueTag) {
  const result = [];
  while (valueTag(value) === 'cons') {
    assert(result.length < 20000, 'PSC0_SH1_MIGRATION_ABI_LIST_BOUND');
    result.push(value.head);
    value = value.tail;
  }
  assert.equal(valueTag(value), 'nil', 'PSC0_SH1_MIGRATION_ABI_LIST_SHAPE');
  return result;
}

function unwrap(value, valueTag, operation) {
  if (valueTag(value) === 'ok') return value.value;
  throw new Error('PSC0_SH1_MIGRATION_ABI_' + operation + ': ' + String(valueTag(value.error)));
}

function selectedCoreDeclarations(compiler, declarations, names, valueTag) {
  const wanted = new Set(names);
  const selected = new Map();
  for (const declaration of array(declarations, valueTag)) {
    const name = compiler.psNameToString(compiler.psDeclarationName(declaration));
    if (!wanted.has(name)) continue;
    assert(!selected.has(name), 'PSC0_SH1_MIGRATION_DUPLICATE_CORE_NAME: ' + name);
    assert.equal(compiler.psNameEq(compiler.psDeclarationName(declaration),
      compiler.psRootName(name)), true, 'PSC0_SH1_MIGRATION_CORE_ROOT_NAME: ' + name);
    selected.set(name, declaration);
  }
  for (const name of names) {
    assert(selected.has(name), 'PSC0_SH1_MIGRATION_MISSING_CORE_NAME: ' + name);
  }
  return selected;
}

function selectedIrDeclarations(ir, valueTag) {
  const wanted = new Set(workers.map((worker) => worker.name));
  const selected = new Map();
  for (const declaration of array(ir.declarations, valueTag)) {
    if (!wanted.has(declaration.name)) continue;
    assert(!selected.has(declaration.name),
      'PSC0_SH1_MIGRATION_DUPLICATE_IR_NAME: ' + declaration.name);
    selected.set(declaration.name, declaration);
  }
  for (const name of wanted) {
    assert(selected.has(name), 'PSC0_SH1_MIGRATION_MISSING_IR_NAME: ' + name);
  }
  return selected;
}

// Preserve constant/universe identities and every type argument. Only bound
// variable display names are alpha-insignificant; module-private tag symbols
// and JavaScript object identities never leave this owning compiler instance.
function alphaData(value, valueTag, depth = 0) {
  assert(depth < 256, 'PSC0_SH1_MIGRATION_ABI_TYPE_DEPTH');
  if (typeof value === 'bigint') return ['bigint', value.toString()];
  if (value === null || typeof value !== 'object') {
    assert(['string', 'number', 'boolean'].includes(typeof value) || value === null,
      'PSC0_SH1_MIGRATION_ABI_TYPE_SCALAR');
    return value;
  }
  const kind = valueTag(value) ?? null;
  const omitName = kind === 'forallE' || kind === 'lam' || kind === 'letE';
  return [kind, Object.keys(value).filter((key) => !(omitName && key === 'name')).sort()
    .map((key) => [key, alphaData(value[key], valueTag, depth + 1)])];
}

function dropBinders(type, count, valueTag, name) {
  let current = type;
  for (let index = 0; index < count; index++) {
    assert.equal(valueTag(current), 'forallE', 'PSC0_SH1_MIGRATION_CORE_ARITY: ' + name);
    assert.equal(valueTag(current.binder), 'explicit', 'PSC0_SH1_MIGRATION_BINDER_KIND: ' + name);
    current = current.body;
  }
  return current;
}

function expectedIrType(type) {
  if (type === 'Nat') return ['primitive', 'nat'];
  if (type === 'String') return ['primitive', 'string'];
  if (typeof type === 'string') return ['named', type, []];
  return ['named', type[0], type.slice(1).map(expectedIrType)];
}

function observedIrType(type, valueTag, depth = 0) {
  assert(depth < 128, 'PSC0_SH1_MIGRATION_ABI_IR_TYPE_DEPTH');
  switch (valueTag(type)) {
    case 'primitive': return ['primitive', valueTag(type.name)];
    case 'named':
      return ['named', type.name, array(type.arguments, valueTag)
        .map((argument) => observedIrType(argument, valueTag, depth + 1))];
    case 'typeParameter': return ['typeParameter', type.name];
    case 'function':
      return ['function', array(type.parameters, valueTag)
        .map((parameter) => observedIrType(parameter, valueTag, depth + 1)),
      observedIrType(type.result, valueTag, depth + 1)];
    default: throw new Error('PSC0_SH1_MIGRATION_UNSUPPORTED_IR_TYPE: ' + String(valueTag(type)));
  }
}

export function runMigrationWorkerAbi(compiler, prepared, ir, valueTag) {
  assert.equal(typeof valueTag, 'function', 'PSC0_SH1_MIGRATION_ABI_TAG_READER');
  for (const name of ['psCompilerPrepareSource', 'psExprAlphaEq', 'psDeclarationName',
    'psDeclarationType', 'psNameToString', 'psNameEq', 'psRootName']) {
    assert.equal(typeof compiler[name], 'function', 'PSC0_SH1_MIGRATION_ABI_EXPORT: ' + name);
  }
  const probe = unwrap(compiler.psCompilerPrepareSource(
    compiler.PsCompilerSourceKind.lean, isolatedSource), valueTag, 'ISOLATED_SIGNATURE_PROBE');
  const names = workers.map((worker) => worker.name);
  const references = workers.map((_, index) => 'sh1MigrationExpected' + index);
  const partials = workers.map((_, index) => 'sh1MigrationPartial' + index);
  const actual = selectedCoreDeclarations(compiler, prepared.declarations, names, valueTag);
  const isolated = selectedCoreDeclarations(compiler, probe.declarations,
    references.concat(partials), valueTag);
  const runtime = selectedIrDeclarations(ir, valueTag);
  const observations = workers.map((worker, index) => {
    const declaration = actual.get(worker.name);
    const reference = isolated.get(references[index]);
    const partial = isolated.get(partials[index]);
    assert.equal(valueTag(declaration), 'definitionDecl',
      'PSC0_SH1_MIGRATION_CORE_DECL_KIND: ' + worker.name);
    assert.equal(array(declaration.levelParams, valueTag).length, 0,
      'PSC0_SH1_MIGRATION_CORE_UNIVERSE_PARAMETERS: ' + worker.name);
    assert.equal(valueTag(reference), 'axiomDecl',
      'PSC0_SH1_MIGRATION_REFERENCE_DECL_KIND: ' + worker.name);
    assert.equal(valueTag(partial), 'definitionDecl',
      'PSC0_SH1_MIGRATION_PARTIAL_DECL_KIND: ' + worker.name);
    const actualType = compiler.psDeclarationType(declaration);
    const referenceType = compiler.psDeclarationType(reference);
    assert.equal(compiler.psExprAlphaEq(actualType, referenceType), true,
      'PSC0_SH1_MIGRATION_COMPLETE_PUBLIC_TYPE: ' + worker.name);
    const result = dropBinders(actualType, worker.parameters.length, valueTag, worker.name);
    assert.notEqual(valueTag(result), 'forallE',
      'PSC0_SH1_MIGRATION_UNEXPECTED_FUNCTION_RESULT: ' + worker.name);
    const remainingType = dropBinders(actualType, worker.outerArguments, valueTag, worker.name);
    const expectedRemaining = dropBinders(referenceType, worker.outerArguments, valueTag, worker.name);
    assert.equal(compiler.psExprAlphaEq(remainingType, expectedRemaining), true,
      'PSC0_SH1_MIGRATION_PUBLIC_PARTIAL_TYPE: ' + worker.name);

    const irDeclaration = runtime.get(worker.name);
    const irParameters = array(irDeclaration.parameters, valueTag);
    const runtimeSignature = {
      typeParameterCount: array(irDeclaration.typeParameters, valueTag).length,
      parameters: irParameters.map((parameter) => observedIrType(parameter.type, valueTag)),
      result: observedIrType(irDeclaration.resultType, valueTag),
    };
    const expectedRuntimeSignature = {
      typeParameterCount: 0,
      parameters: worker.parameters.map(([, type]) => expectedIrType(type)),
      result: expectedIrType(worker.result),
    };
    assert.equal(irParameters.length, worker.parameters.length,
      'PSC0_SH1_MIGRATION_RUNTIME_ARITY: ' + worker.name);
    assert.deepEqual(runtimeSignature, expectedRuntimeSignature,
      'PSC0_SH1_MIGRATION_ORDERED_IR_SIGNATURE: ' + worker.name);
    return {
      family: worker.family, name: worker.name,
      completePublicType: fullTypeSource(worker),
      coreType: alphaData(actualType, valueTag),
      originalOuterArguments: worker.outerArguments,
      remainingArgumentCount: worker.parameters.length - worker.outerArguments,
      partialApplicationType: fullTypeSource(worker, worker.outerArguments),
      genericPartialWrapperElaborated: true,
      runtimeArity: irParameters.length,
      runtimeSignature,
    };
  });
  return {
    schemaVersion: 1,
    evidence: 'actual-public-core-types-and-existing-original-ir-signatures',
    referenceRef, manifests,
    workerCount: workers.length,
    families: { F1: 4, F2: 8 },
    isolatedProbe: {
      sourceSha256: sha256(isolatedSource),
      sourceKind: 'lean',
      signatureAxioms: workers.length,
      typedGenericPartialWrappers: workers.length,
      phase: 'elaboration-and-admission-encoding',
      mergedIntoAuthoritativeClosure: false,
      erasedOrEmitted: false,
      runtimeExecuted: false,
    },
    existingPreparedObjectReadOnly: true,
    existingIrObjectReadOnly: true,
    runtimeParameterDisplayNamesCompared: false,
    fullBaselineClosurePreparedAgain: false,
    separateCompiledPartialApplicationProbe: false,
    partialApplicationRuntimeEvidence: 'existing-SH1-runtime-capability-gate',
    kernelChecked: false,
    observations,
    observationSha256: sha256(JSON.stringify(observations)),
  };
}
