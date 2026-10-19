import assert from 'node:assert/strict';
import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { inventoryOriginalIr } from './original-ir-inventory.mjs';
import { valueTag } from './sh1-capabilities.mjs';

function fixtures(c) {
  const list = (items) => items.reduceRight((tail, head) => c.List.cons(head, tail), c.List.nil());
  const E = c.PsVerifiedIrExpr, T = c.PsVerifiedIrType;
  const nat = T.primitive(c.PsVerifiedIrPrimitiveType.nat);
  const variable = (name) => E.var(name);
  const natural = (value = 7) => E.literal(c.PsVerifiedIrLiteral.natural(BigInt(value)));
  const named = (name) => T.named(name, list([]));
  const fn = (parameters, result) => T.function(list(parameters), result);
  const params = (items) => list(items.map(([name, type]) => c.psIrCheckMakeParameter(name, type)));
  const declaration = (name, body = natural(), parameters = [], result = nat, generics = []) =>
    c.psIrCheckMakeDeclaration(name,
      list(generics.map((name) => c.psIrCheckMakeTypeParameter(name))), params(parameters), result, body);
  const module = (declarations = [], structures = [], inductives = []) =>
    c.psIrCheckMakeModule(list([]), list(structures), list(inductives), list(declarations));
  const structure = (name, field = 'do') => c.psIrCheckMakeStructure(name, list([]),
    list([c.psIrCheckMakeStructureField(field, nat)]));
  const choice = (constructor = 'do') => c.psIrCheckMakeInductive('Choice', list([]),
    list([c.psIrCheckMakeConstructor(constructor, list([]))]));
  const constructor = (name = 'do') => E.constructor('Choice', name, list([]), list([]));
  const call = (name, args) => E.call(variable(name), list([]), list(args));
  const lambda = (body) => E.lambda(params([['x', nat]]), nat, body);
  const literalModule = module([declaration('value')]);
  const cases = [
    { id: 'T01-earlier-global', module: module([declaration('earlier'), declaration('later', variable('earlier'))]) },
    { id: 'T02-positive-arity-self', module: module([
      declaration('recurse', call('recurse', [variable('n')]), [['n', nat]])]),
      scope: 'Target admission only; the recursive body is not executed or claimed decreasing.' },
    { id: 'T03-local-shadow', module: module([
      declaration('first', variable('later'), [['later', nat]]), declaration('later')]) },
    { id: 'T04-let-old-binding', module: module([
      declaration('oldScope', E.letE('x', nat, variable('x'), variable('x')), [['x', nat]])]) },
    { id: 'T05-keyword-property', module: module([
      declaration('readField', E.projection('Record', list([]), variable('value'), 'do'),
        [['value', named('Record')]])], [structure('Record')]) },
    { id: 'T06-keyword-constructor', module: module([
      declaration('makeChoice', constructor(), [], named('Choice'))], [], [choice()]) },
    { id: 'T07-iife-local-name', module: module([
      declaration('argumentName', variable('__ps_a'), [['__ps_a', nat]])]) },
    { id: 'T08-unused-constructor-shadow', module: module([
      declaration('unusedName', variable('Choice'), [['Choice', nat]])], [], [choice()]) },
    { id: 'T09-generic-generator-name', module: module([
      declaration('genericName', natural(), [['n', nat]], nat, ['Generator'])]) },
    { id: 'T10-forward-global', module: module([
      declaration('first', variable('later')), declaration('later')]), code: 'target-global-order' },
    { id: 'T11-forward-in-lambda', module: module([
      declaration('first', lambda(variable('later')), [], fn([nat], nat)), declaration('later')]),
      code: 'target-global-order' },
    { id: 'T12-forward-from-function', module: module([
      declaration('first', variable('later'), [['n', nat]]), declaration('later')]), code: 'target-global-order' },
    { id: 'T13-eager-self', module: module([declaration('self', variable('self'))]), code: 'target-self-value' },
    { id: 'T14-binding-keyword', module: module([declaration('do')]), code: 'target-binding-name' },
    { id: 'T15-proto-field', module: module([], [structure('Record', '__proto__')]), code: 'target-property-name' },
    { id: 'T16-proto-constructor', module: module([], [], [choice('__proto__')]), code: 'target-property-name' },
    { id: 'T17-runtime-helper', module: module([declaration('__ps$run')]), code: 'target-runtime-name' },
    { id: 'T18-builtin-shadow', module: module([
      declaration('builtinShadow', variable('BigInt'), [['BigInt', nat]])]), code: 'target-runtime-name' },
    { id: 'T19-layout-value-collision', module: module([declaration('Choice')], [], [choice()]),
      code: 'target-global-collision' },
    { id: 'T20-private-implementation-collision', module: module([
      declaration('f', variable('n'), [['n', nat]]), declaration('__ps$impl$f')]), code: 'target-generated-name' },
    { id: 'T21-brand-collision', module: module([declaration('__ps$brand$0')], [structure('Record')]),
      code: 'target-generated-name' },
    { id: 'T22-tag-collision', module: module([declaration('__ps$tag$0')], [], [choice()]),
      code: 'target-generated-name' },
    { id: 'T23-match-temporary', module: module([
      declaration('matchShadow', variable('__ps$match$0'), [['__ps$match$0', nat]])]), code: 'target-runtime-name' },
    { id: 'T24-array-type-capture', module: module([
      declaration('genericArray', natural(), [['n', nat]], nat, ['Array'])]), code: 'target-type-capture' },
    { id: 'T25-layout-type-capture', module: module([
      declaration('genericRecord', natural(), [['n', nat]], nat, ['Record'])], [structure('Record')]),
      code: 'target-type-capture' },
    { id: 'T26-constructor-value-capture', module: module([
      declaration('captureChoice', constructor(), [['Choice', nat]], named('Choice'))], [], [choice()]),
      code: 'target-value-capture' },
    { id: 'T27-invalid-identifier', module: module([declaration('bad-name')]), code: 'target-identifier' },
    { id: 'T28-work-exhaustion', module: module(), maxSteps: 0n, code: 'target-fuel-exhausted' },
  ];
  let nested = natural();
  for (let index = 0; index < 4096; index++) nested = E.letE('depth' + index, nat, natural(), nested);
  cases.push({ id: 'T29-depth-exhaustion', module: module([declaration('deep', nested)]),
    maxSteps: 1000000n, code: 'target-depth-exhausted', targetOnly: true });
  return { cases, literalModule };
}

export async function runStrictTargetConformance({ compiler, compilerSha256, outDir }) {
  assert.equal(typeof compiler.psSh1CheckTarget, 'function', 'PSC0_SH1_TARGET_API_REQUIRED');
  const model = fixtures(compiler);
  const observations = [];
  for (const test of model.cases) {
    let typing;
    if (!test.targetOnly) {
      const inventory = inventoryOriginalIr(compiler, test.module, { compilerSha256 });
      assert.equal(inventory.runtimeIrTypingAccepted, true, 'PSC0_SH1_TARGET_FIXTURE_TYPES: ' + test.id);
      assert.equal(inventory.traversalComplete, true);
      typing = { accepted: true, traversalComplete: true,
        expressionCount: inventory.counts.expressions, findingCount: inventory.findingCount };
    } else typing = { status: 'not-attempted-target-only-depth-stress' };
    const result = compiler.psSh1CheckTarget(test.maxSteps ?? 1000000n, test.module);
    if (test.code) {
      assert.equal(valueTag(result), 'error', 'PSC0_SH1_TARGET_REFUSAL: ' + test.id);
      assert.equal(result.error.code, test.code, 'PSC0_SH1_TARGET_CODE: ' + test.id);
      assert(typeof result.error.visitedSteps === 'bigint' && result.error.visitedSteps >= 0n);
      observations.push({ id: test.id, typing, accepted: false, code: result.error.code,
        owner: result.error.owner, path: result.error.path,
        visitedSteps: Number(result.error.visitedSteps) });
    } else {
      assert.equal(valueTag(result), 'ok', 'PSC0_SH1_TARGET_ACCEPTANCE: ' + test.id);
      assert.equal(result.value.policy, 'psc0-sh1-ts-target/1');
      assert.equal(result.value.accepted, true);
      assert.equal(result.value.traversalComplete, true);
      observations.push({ id: test.id, typing, accepted: true,
        visitedSteps: Number(result.value.visitedSteps), ...(test.scope ? { scope: test.scope } : {}) });
    }
  }
  const receipt = {
    schemaVersion: 1, evidence: 'portable-target-admission-conformance', compilerSha256,
    policy: 'psc0-sh1-ts-target/1', observations,
    acceptedCases: observations.filter((item) => item.accepted).length,
    refusedCases: observations.filter((item) => !item.accepted).length,
    arbitraryTypedIrIsStrictSource: false, semanticPreservationProven: false,
    strictSh1Qualified: false, providerChecked: false,
  };
  await mkdir(outDir, { recursive: true });
  await writeFile(path.join(outDir, 'receipt.json'), JSON.stringify(receipt, null, 2) + '\n');
  process.stdout.write('PSC0_SH1_STRICT_TARGET: ' + JSON.stringify(receipt) + '\n');
  return receipt;
}
