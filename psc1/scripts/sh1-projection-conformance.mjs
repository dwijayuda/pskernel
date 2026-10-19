import assert from 'node:assert/strict';
import { invokeCompilerValueEntry } from './sh1-function-entry.mjs';

// Every syntax node, name, local declaration, and global declaration below is
// made by the compiler instance being checked. Reports contain only plain data.
export function runProjectionResolutionConformance(compiler, valueTag) {
  const cases = [];
  const label = (name) => 'PSC0_SH1_PROJECTION_' + name;
  const ok = (value, name) => {
    assert.equal(valueTag(value), 'ok', label(name));
    return value.value;
  };
  const some = (value, name) => {
    assert.equal(valueTag(value), 'some', label(name));
    return value.value;
  };
  const list = (values) => values.reduceRight(
    (tail, head) => compiler.List.cons(head, tail), compiler.List.nil());
  const array = (value) => {
    const result = [];
    while (valueTag(value) === 'cons') {
      assert(result.length < 32, label('LIST_BOUND'));
      result.push(value.head);
      value = value.tail;
    }
    assert.equal(valueTag(value), 'nil', label('LIST_SHAPE'));
    return result;
  };
  const name = (segments) => {
    assert(segments.length > 0, label('NAME_COMPONENTS'));
    return segments.slice(1).reduce(
      (parent, segment) => compiler.psNameAppendStr(parent, segment),
      compiler.psRootName(segments[0]));
  };
  const reference = (segments) => {
    const source = 'def projectionReferenceProbe : Nat := ' + segments.join('.') + '\n';
    const parsed = ok(compiler.psCompilerParseSource(
      compiler.PsCompilerSourceKind.lean, source), 'PARSE_REFERENCE');
    const declarations = array(parsed.declarations);
    assert.equal(declarations.length, 1, label('REFERENCE_DECLARATIONS'));
    assert.equal(valueTag(declarations[0]), 'definition', label('REFERENCE_DEFINITION'));
    const term = declarations[0].value;
    assert.equal(valueTag(term), 'reference', label('REFERENCE_TERM'));
    return term;
  };
  const dummyType = compiler.PsExpr.sortE(compiler.PsLevel.zero);
  const bind = (context, segments) => compiler.psLocalPushBinding(
    context, name(segments), dummyType, compiler.PsBinderInfo.explicit);
  const addGlobal = (environment, segments) => some(compiler.psEnvironmentAdd(
    environment, compiler.PsDeclaration.axiomDecl(name(segments), list([]), dummyType)),
  'ADD_GLOBAL');
  const emptyLocal = compiler.psLocalEmpty;
  const emptyEnvironment = compiler.psEnvironmentEmpty;
  const abc = reference(['alpha', 'beta', 'gamma']);
  const abcd = reference(['alpha', 'beta', 'gamma', 'delta']);
  const alpha = reference(['alpha']);
  const alphaField = reference(['alpha', 'field']);
  const resolve = (caseName, context, environment, term, expected) => {
    const result = compiler.psElabResolveReferenceBase(context, environment, term.name);
    if (expected.kind === 'none') {
      assert.equal(valueTag(result), 'none', label(caseName));
      cases.push({ name: caseName, family: 'resolution', expected: { kind: 'none' } });
      return;
    }
    const selected = some(result, caseName);
    const base = selected.fst;
    const fields = array(selected.snd);
    assert.equal(valueTag(base), expected.kind, label(caseName + '_BASE'));
    assert.deepEqual(fields, expected.fields, label(caseName + '_FIELDS'));
    if (expected.kind === 'local') {
      assert.equal(base.id, expected.id, label(caseName + '_LOCAL'));
      cases.push({
        name: caseName, family: 'resolution',
        expected: { kind: 'local', id: String(expected.id), fields: expected.fields },
      });
    } else {
      assert.equal(invokeCompilerValueEntry(compiler, 'psNameEq', [base.name, name(expected.segments)]), true,
        label(caseName + '_GLOBAL'));
      cases.push({
        name: caseName, family: 'resolution',
        expected: { kind: 'global', name: expected.segments.join('.'), fields: expected.fields },
      });
    }
  };

  const first = bind(emptyLocal, ['alpha']);
  const firstAndLonger = bind(first.context, ['alpha', 'beta']);
  const exact = bind(firstAndLonger.context, ['alpha', 'beta', 'gamma']);
  const firstGlobal = addGlobal(emptyEnvironment, ['alpha']);
  const exactGlobal = addGlobal(firstGlobal, ['alpha', 'beta', 'gamma']);
  resolve('exact-local-before-global-and-prefixes', exact.context, exactGlobal, abc,
    { kind: 'local', id: exact.id, fields: [] });
  resolve('exact-global-before-local-prefix', firstAndLonger.context, exactGlobal, abc,
    { kind: 'global', segments: ['alpha', 'beta', 'gamma'], fields: [] });
  resolve('first-local-before-first-global-and-longer-local',
    firstAndLonger.context, firstGlobal, abc,
    { kind: 'local', id: first.id, fields: ['beta', 'gamma'] });
  const onlyLonger = bind(emptyLocal, ['alpha', 'beta']);
  resolve('first-global-before-longer-local', onlyLonger.context, firstGlobal, abc,
    { kind: 'global', segments: ['alpha'], fields: ['beta', 'gamma'] });

  // The longer base is older than the shorter base: prefix length takes
  // precedence over recency between different names.
  const longest = bind(emptyLocal, ['alpha', 'beta', 'gamma']);
  const newerShorter = bind(longest.context, ['alpha', 'beta']);
  resolve('longest-proper-local-prefix-with-absent-first',
    newerShorter.context, emptyEnvironment, abcd,
    { kind: 'local', id: longest.id, fields: ['delta'] });
  resolve('shorter-proper-local-prefix-with-absent-first',
    onlyLonger.context, emptyEnvironment, abcd,
    { kind: 'local', id: onlyLonger.id, fields: ['gamma', 'delta'] });
  const multiGlobal = addGlobal(emptyEnvironment, ['alpha', 'beta']);
  resolve('multi-segment-global-is-not-a-fallback', emptyLocal, multiGlobal, abc,
    { kind: 'none' });
  const longerGlobal = addGlobal(emptyEnvironment, ['alpha', 'beta', 'gamma']);
  resolve('longer-global-does-not-displace-local-fallback',
    onlyLonger.context, longerGlobal, abcd,
    { kind: 'local', id: onlyLonger.id, fields: ['gamma', 'delta'] });

  const shadow = bind(first.context, ['alpha']);
  resolve('nearest-first-segment-local-shadow', shadow.context, emptyEnvironment, abc,
    { kind: 'local', id: shadow.id, fields: ['beta', 'gamma'] });
  const exactShadow = bind(exact.context, ['alpha', 'beta', 'gamma']);
  resolve('nearest-exact-local-shadow', exactShadow.context, exactGlobal, abc,
    { kind: 'local', id: exactShadow.id, fields: [] });
  resolve('unresolved-name', emptyLocal, emptyEnvironment, abc, { kind: 'none' });
  const unrelated = bind(emptyLocal, ['alpha', 'other']);
  resolve('unrelated-multi-segment-local', unrelated.context, emptyEnvironment, abc,
    { kind: 'none' });

  const identity = (caseName, result, expectedId) => {
    if (expectedId === null) {
      assert.equal(valueTag(result), 'none', label(caseName));
    } else {
      assert.equal(some(result, caseName), expectedId, label(caseName + '_ID'));
    }
    cases.push({
      name: caseName, family: 'exact-local-identity',
      expectedId: expectedId === null ? null : String(expectedId),
    });
  };
  const elabContext = (locals, environment = emptyEnvironment) =>
    compiler.psElabContextWithLocal(compiler.psElabContextEmpty(environment), locals);
  identity('recursion-exact-local-reference',
    compiler.psElabRecursionLocalId(first.context, alpha), first.id);
  identity('term-exact-local-reference',
    compiler.psElabSyntaxLocalId(elabContext(first.context), alpha), first.id);
  identity('recursion-projection-is-not-unchanged-state',
    compiler.psElabRecursionLocalId(first.context, alphaField), null);
  identity('term-projection-is-not-a-structural-child',
    compiler.psElabSyntaxLocalId(elabContext(first.context), alphaField), null);
  identity('recursion-global-is-not-local',
    compiler.psElabRecursionLocalId(emptyLocal, alpha), null);
  identity('term-global-is-not-local',
    compiler.psElabSyntaxLocalId(elabContext(emptyLocal, firstGlobal), alpha), null);
  const exactQualified = bind(emptyLocal, ['alpha', 'field']);
  identity('recursion-exact-qualified-local-still-has-identity',
    compiler.psElabRecursionLocalId(exactQualified.context, alphaField), exactQualified.id);
  identity('term-exact-qualified-local-still-has-identity',
    compiler.psElabSyntaxLocalId(elabContext(exactQualified.context), alphaField), exactQualified.id);

  const spanSource =
    'structure ProjectionSpanRecord where\n  count : Nat\n' +
    'def projectionSpanProbe (fuel : Nat) (options : ProjectionSpanRecord) (state : Nat) : Nat :=\n' +
    '  match fuel with\n' +
    '  | Nat.zero => Nat.add options.count state\n' +
    '  | Nat.succ remaining => projectionSpanProbe remaining options (Nat.succ state)\n';
  const spanParsed = ok(compiler.psCompilerParseSource(
    compiler.PsCompilerSourceKind.lean, spanSource), 'SPAN_PARSE');
  const spanDeclarations = array(spanParsed.declarations);
  assert.equal(spanDeclarations.length, 2, label('SPAN_DECLARATIONS'));
  const prelude = compiler.psSelfHostProdPreludeEnvironment;
  const structure = ok(compiler.psElabDeclarationBatchStable(
    prelude, spanDeclarations[0]), 'SPAN_STRUCTURE');
  const environment = ok(compiler.psAddDeclarationList(
    prelude, structure.declarations), 'SPAN_ENVIRONMENT');
  const definition = spanDeclarations[1];
  const normalized = some(ok(compiler.psElabPlanStructuralNormalization(
    environment, definition.name, definition.binders, definition.type,
    definition.value, definition.span), 'SPAN_NORMALIZE'), 'SPAN_NORMALIZED');
  const originalBody = array(definition.value.alternatives)[0].snd.fst;
  const normalizedBody = array(normalized.workerValue.alternatives)[0].snd.fst;
  assert.equal(valueTag(originalBody), 'app', label('SPAN_ORIGINAL_BODY'));
  assert.equal(valueTag(normalizedBody), 'lambda', label('SPAN_STATE_ABSTRACTION'));
  assert.equal(valueTag(normalizedBody.body), 'app', label('SPAN_NORMALIZED_BODY'));
  const originalReference = array(originalBody.args)[0];
  const rewrittenReference = array(normalizedBody.body.args)[0];
  assert.equal(valueTag(originalReference), 'reference', label('SPAN_ORIGINAL_REFERENCE'));
  assert.equal(valueTag(rewrittenReference), 'reference', label('SPAN_REWRITTEN_REFERENCE'));
  const fixedBinders = array(normalized.workerBinders);
  assert.equal(fixedBinders.length, 2, label('SPAN_FIXED_BINDER_ORDER'));
  const renamedOptions = array(fixedBinders[1].fst.name.segments);
  assert.deepEqual(array(originalReference.name.segments), ['options', 'count'],
    label('SPAN_SOURCE_PROJECTION'));
  assert.deepEqual(array(rewrittenReference.name.segments), renamedOptions.concat('count'),
    label('SPAN_BINDER_AND_FIELD'));
  const position = (value) => ({
    byteOffset: String(value.byteOffset), line: String(value.line), column: String(value.column),
  });
  const span = (value) => ({ start: position(value.start), stop: position(value.stop) });
  const originalSpan = span(originalReference.name.span);
  assert.deepEqual(span(rewrittenReference.name.span), originalSpan, label('SPAN_PRESERVED'));
  cases.push({
    name: 'normalized-parameter-projection-preserves-binder-field-and-span',
    family: 'normalization-source-span',
    expectedBinderSegments: renamedOptions, expectedFields: ['count'], expectedSpan: originalSpan,
  });

  return {
    schemaVersion: 1,
    evidence: 'owned-compiler-api-resolution-and-source-identity',
    caseCount: cases.length,
    resolutionCases: cases.filter((item) => item.family === 'resolution').length,
    exactIdentityCases: cases.filter((item) => item.family === 'exact-local-identity').length,
    normalizationSpanCases: cases.filter((item) => item.family === 'normalization-source-span').length,
    allPassed: true,
    instanceOwnership: 'All syntax and compiler data were constructed by this compiler instance.',
    cases,
  };
}
