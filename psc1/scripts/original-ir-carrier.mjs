// Validate the JS carrier of live original IR before entering portable code.
// This is a representation boundary, with no expression typing or call arity rules.
// Every symbol is obtained from the same loaded compiler namespace as the IR.
function ownBrand(sample, expected) {
  if (sample === null || typeof sample !== 'object') throw new Error('PSC0_IR_CARRIER_MODEL_SAMPLE');
  const symbols = Object.getOwnPropertySymbols(sample).filter((symbol) => sample[symbol] === expected);
  if (symbols.length !== 1) throw new Error('PSC0_IR_CARRIER_MODEL_BRAND');
  return symbols[0];
}

function isWellFormedUtf16(value) {
  for (let index = 0; index < value.length; index++) {
    const unit = value.charCodeAt(index);
    if (unit >= 0xd800 && unit <= 0xdbff) {
      const next = value.charCodeAt(index + 1);
      if (!(next >= 0xdc00 && next <= 0xdfff)) return false;
      index++;
    } else if (unit >= 0xdc00 && unit <= 0xdfff) return false;
  }
  return true;
}

// maxNodes bounds model occurrences and each string's validation in UTF-16 units.
// Portable checking keeps its independent UTF-8 byte and type-work budgets.
export function inspectOriginalIrCarrier(compiler, module, { maxNodes = 5000000 } = {}) {
  if (!Number.isSafeInteger(maxNodes) || maxNodes < 1) throw new Error('PSC0_IR_CARRIER_LIMIT');
  const nil = compiler.List.nil();
  const type = compiler.PsVerifiedIrType.unknown;
  const expr = compiler.PsVerifiedIrExpr.var('__carrier');
  const brands = {};
  const forms = {};
  const recordKinds = new Set();
  const add = (kind, sample, variants, expected) => {
    brands[kind] = ownBrand(sample, expected);
    forms[kind] = variants;
  };
  const enumeration = (kind, sample, names) => add(kind, sample,
    Object.fromEntries(names.map((name) => [name, []])), names[0]);
  enumeration('primitive', compiler.PsVerifiedIrPrimitiveType.nat, [
    'nat', 'int', 'uint8', 'uint16', 'uint32', 'uint64', 'usize',
    'int8', 'int16', 'int32', 'int64', 'isize', 'float', 'float32',
    'bool', 'char', 'string', 'unit',
  ]);
  enumeration('machine', compiler.PsVerifiedIrMachineIntegerType.uint8,
    ['uint8', 'uint16', 'uint32', 'uint64', 'usize', 'int8', 'int16', 'int32', 'int64', 'isize']);
  enumeration('integerBinary', compiler.PsVerifiedIrIntegerBinaryOp.add,
    ['add', 'sub', 'mul', 'bitAnd', 'bitOr', 'bitXor']);
  enumeration('integerCompare', compiler.PsVerifiedIrIntegerCompareOp.eq,
    ['eq', 'ne', 'lt', 'le', 'gt', 'ge']);
  enumeration('floating', compiler.PsVerifiedIrFloatingType.float, ['float', 'float32']);
  enumeration('floatBinary', compiler.PsVerifiedIrFloatBinaryOp.add, ['add', 'sub', 'mul', 'div']);
  enumeration('floatCompare', compiler.PsVerifiedIrFloatCompareOp.eq, ['eq', 'ne', 'lt', 'le', 'gt', 'ge']);
  add('type', type, {
    unknown: [], typeParameter: [['name', 'string']], primitive: [['name', 'primitive']],
    function: [['parameters', 'list/type'], ['result', 'type']],
    named: [['name', 'string'], ['arguments', 'list/type']],
  }, 'unknown');
  add('literal', compiler.PsVerifiedIrLiteral.unit, {
    natural: [['value', 'nat']], integer: [['value', 'int']],
    machineInteger: [['type', 'machine'], ['value', 'int']],
    string: [['value', 'string']], bool: [['value', 'bool']], unit: [],
  }, 'unit');
  add('intrinsic', compiler.PsVerifiedIrIntrinsic.natAdd, {
    ...Object.fromEntries([
      'natAdd', 'natSub', 'natMul', 'natDiv', 'natMod', 'natEq', 'natNe', 'natLe', 'natLt',
      'intOfNat', 'intRepr', 'intNegSucc', 'intNeg', 'intAdd', 'intSub', 'intMul', 'intEq', 'intLe', 'intLt',
      'boolNot', 'boolAnd', 'boolOr', 'boolEq', 'boolNe', 'charOfNat', 'charToNat',
      'stringPush', 'stringSingleton', 'stringLength', 'stringAppend', 'stringUtf8ByteSize',
      'stringNext', 'stringGet', 'stringAtEnd', 'stringExtract', 'stringEq',
      'arrayEmptyWithCapacity', 'arraySize', 'arrayPush', 'arrayGet', 'arrayGetD',
      'arraySet', 'arraySetIfInBounds', 'arrayMap', 'arrayFoldl',
    ].map((name) => [name, []])),
    machineIntBinary: [['type', 'machine'], ['operation', 'integerBinary']],
    machineIntCompare: [['type', 'machine'], ['operation', 'integerCompare']],
    floatBinary: [['type', 'floating'], ['operation', 'floatBinary']],
    floatCompare: [['type', 'floating'], ['operation', 'floatCompare']],
  }, 'natAdd');
  add('expr', expr, {
    literal: [['value', 'literal']], var: [['name', 'string']],
    intrinsic: [['operation', 'intrinsic'], ['typeArguments', 'list/type'], ['arguments', 'list/expr']],
    lambda: [['parameters', 'list/parameter'], ['resultType', 'type'], ['body', 'expr']],
    call: [['fn', 'expr'], ['typeArguments', 'list/type'], ['arguments', 'list/expr']],
    letE: [['name', 'string'], ['type', 'type'], ['value', 'expr'], ['body', 'expr']],
    ifE: [['condition', 'expr'], ['thenBranch', 'expr'], ['elseBranch', 'expr']],
    record: [['structureName', 'string'], ['typeArguments', 'list/type'], ['fields', 'list/recordField']],
    projection: [['structureName', 'string'], ['typeArguments', 'list/type'], ['target', 'expr'], ['field', 'string']],
    constructor: [['inductiveName', 'string'], ['constructorName', 'string'], ['typeArguments', 'list/type'], ['fields', 'list/recordField']],
    matchE: [['inductiveName', 'string'], ['typeArguments', 'list/type'], ['scrutinee', 'expr'], ['alternatives', 'list/alternative']],
  }, 'var');
  const record = (kind, sample, fields) => {
    recordKinds.add(kind);
    add(kind, sample, { true: fields }, true);
  };
  record('parameter', compiler.psIrCheckMakeParameter('__carrier', type), [['name', 'string'], ['type', 'type']]);
  record('binding', compiler.psIrCheckMakeMatchBinding('field', 'value', type),
    [['field', 'string'], ['name', 'string'], ['type', 'type']]);
  record('typeParameter', compiler.psIrCheckMakeTypeParameter('T'), [['name', 'string']]);
  record('structureField', compiler.psIrCheckMakeStructureField('field', type), [['name', 'string'], ['type', 'type']]);
  record('structure', compiler.psIrCheckMakeStructure('Structure', nil, nil),
    [['name', 'string'], ['typeParameters', 'list/typeParameter'], ['fields', 'list/structureField']]);
  record('constructorField', compiler.psIrCheckMakeConstructorField('field', type), [['name', 'string'], ['type', 'type']]);
  record('constructor', compiler.psIrCheckMakeConstructor('Constructor', nil),
    [['name', 'string'], ['fields', 'list/constructorField']]);
  record('inductive', compiler.psIrCheckMakeInductive('Inductive', nil, nil),
    [['name', 'string'], ['typeParameters', 'list/typeParameter'], ['constructors', 'list/constructor']]);
  record('declaration', compiler.psIrCheckMakeDeclaration('declaration', nil, nil, type, expr),
    [['name', 'string'], ['typeParameters', 'list/typeParameter'], ['parameters', 'list/parameter'], ['resultType', 'type'], ['body', 'expr']]);
  record('import', compiler.psIrCheckMakeExternalImport('local', 'source', 'imported', type),
    [['localName', 'string'], ['source', 'string'], ['importedName', 'string'], ['type', 'type']]);
  record('module', compiler.psIrCheckMakeModule(nil, nil, nil, nil),
    [['imports', 'list/import'], ['structures', 'list/structure'], ['inductives', 'list/inductive'], ['declarations', 'list/declaration']]);
  const pairBrand = ownBrand(compiler.psIrCheckMakePair('', expr), true);
  const listBrand = ownBrand(nil, 'nil');
  for (const [kind, fields] of [
    ['recordField', [['fst', 'string'], ['snd', 'expr']]],
    ['alternative', [['fst', 'string'], ['snd', 'alternativeBody']]],
    ['alternativeBody', [['fst', 'list/binding'], ['snd', 'expr']]],
  ]) {
    recordKinds.add(kind);
    brands[kind] = pairBrand;
    forms[kind] = { true: fields };
  }
  const active = new WeakSet();
  const complete = new WeakMap();
  const pending = [{ value: module, kind: 'module', at: 'module' }];
  let visitedNodes = 0;
  const fail = (code, at, detail) => ({ accepted: false, traversalComplete: false,
    visitedNodes, finding: { code, at, detail } });
  while (pending.length) {
    const job = pending.pop();
    const { value, kind, at } = job;
    if (job.exit) {
      active.delete(value);
      if (!complete.has(value)) complete.set(value, new Set());
      complete.get(value).add(kind);
      continue;
    }
    if (++visitedNodes > maxNodes) return fail('ir-carrier-resource-limit', at, 'Carrier traversal exceeded maxNodes.');
    if (kind === 'string') {
      if (typeof value !== 'string') {
        return fail('invalid-ir-scalar-carrier', at, 'Expected canonical string carrier.');
      }
      if (value.length > maxNodes) {
        return fail('ir-carrier-resource-limit', at, 'String validation exceeded maxNodes UTF-16 units.');
      }
      if (!isWellFormedUtf16(value)) {
        return fail('invalid-ir-scalar-carrier', at, 'Expected well-formed UTF-16 string carrier.');
      }
      continue;
    }
    if (kind === 'bool' || kind === 'nat' || kind === 'int') {
      const valid = kind === 'bool' ? typeof value === 'boolean' :
        typeof value === 'bigint' && (kind === 'int' || value >= 0n);
      if (!valid) return fail('invalid-ir-scalar-carrier', at, 'Expected canonical ' + kind + ' carrier.');
      continue;
    }
    if (value === null || typeof value !== 'object' ||
        ![Object.prototype, null].includes(Object.getPrototypeOf(value))) {
      return fail('malformed-or-foreign-constructor', at, 'Expected original IR object: ' + kind);
    }
    if (complete.get(value)?.has(kind)) continue;
    if (active.has(value)) return fail('cyclic-ir-carrier', at, 'Original IR contains a cycle.');
    const properties = Object.getOwnPropertyDescriptors(value);
    const symbols = Object.getOwnPropertySymbols(value);
    const listElement = kind.startsWith('list/') ? kind.slice(5) : undefined;
    const brand = listElement ? listBrand : brands[kind];
    if (!brand || !properties[brand] || !Object.hasOwn(properties[brand], 'value') ||
        symbols.length !== 1 || symbols[0] !== brand) {
      return fail('malformed-or-foreign-constructor', at, 'Constructor does not belong to the executing compiler: ' + kind);
    }
    const tag = properties[brand].value;
    const fields = listElement ? tag === 'nil' ? [] : tag === 'cons' ?
      [['head', listElement], ['tail', kind]] : undefined :
      Object.hasOwn(forms[kind], tag) ? forms[kind][tag] : undefined;
    if (!fields || (recordKinds.has(kind) ? tag !== true : typeof tag !== 'string')) {
      return fail('malformed-or-foreign-constructor', at, 'Unknown constructor for ' + kind);
    }
    const keys = Object.keys(properties);
    if (keys.length !== fields.length || keys.some((key) => !fields.some(([name]) => name === key))) {
      return fail('malformed-ir-fields', at, 'Unexpected constructor fields for ' + kind);
    }
    for (const [name] of fields) {
      if (!properties[name] || !Object.hasOwn(properties[name], 'value')) {
        return fail('malformed-ir-fields', at + '/' + name, 'Missing field or accessor in original IR.');
      }
    }
    active.add(value);
    pending.push({ value, kind, at, exit: true });
    for (let index = fields.length - 1; index >= 0; index--) {
      const [name, childKind] = fields[index];
      pending.push({ value: properties[name].value, kind: childKind, at: at + '/' + name });
    }
  }
  return { accepted: true, traversalComplete: true, visitedNodes };
}
