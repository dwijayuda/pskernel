import assert from 'node:assert/strict';

function assertContractShape(contract) {
  assert.equal(contract?.schemaVersion, 1, 'prelude extension contract schema changed');
  assert.ok(Array.isArray(contract.extensions), 'prelude extension contract must contain extensions');

  const names = new Set();
  for (const extension of contract.extensions) {
    assert.equal(typeof extension.name, 'string', 'prelude extension name must be a string');
    assert.equal(
      extension.declaration?.name,
      extension.name,
      'prelude extension declaration name must match contract name',
    );
    assert.equal(
      typeof extension.insertBefore,
      'string',
      'prelude extension insertBefore anchor must be a string',
    );
    assert.ok(!names.has(extension.name), 'prelude extension names must be unique');
    names.add(extension.name);
  }
}

export function validatePreludeExtensions(actualPrelude, contract) {
  assertContractShape(contract);
  assert.ok(Array.isArray(actualPrelude), 'actual prelude declaration inventory must be an array');

  const extensionNames = new Set(contract.extensions.map(extension => extension.name));
  const actualByName = new Map();

  for (const declaration of actualPrelude) {
    assert.equal(typeof declaration?.name, 'string', 'prelude declaration must have a string name');
    assert.ok(
      !actualByName.has(declaration.name),
      'prelude declaration names must remain unique: ' + declaration.name,
    );
    actualByName.set(declaration.name, declaration);
  }

  for (const extension of contract.extensions) {
    const actual = actualByName.get(extension.name);
    assert.ok(actual, 'required prelude extension missing: ' + extension.name);
    assert.deepEqual(
      actual,
      extension.declaration,
      'prelude extension declaration changed: ' + extension.name,
    );

    const reduced = actualPrelude.filter(
      declaration =>
        !extensionNames.has(declaration.name) || declaration.name === extension.name,
    );
    const extensionIndex = reduced.findIndex(declaration => declaration.name === extension.name);
    const anchorIndex = reduced.findIndex(
      declaration => declaration.name === extension.insertBefore,
    );

    assert.ok(
      anchorIndex >= 0,
      'prelude extension anchor missing: ' +
        extension.name +
        ' -> ' +
        extension.insertBefore,
    );
    assert.equal(
      extensionIndex + 1,
      anchorIndex,
      'prelude extension insertion point changed: ' +
        extension.name +
        ' must remain immediately before ' +
        extension.insertBefore,
    );
  }

  return actualPrelude.filter(declaration => !extensionNames.has(declaration.name));
}
