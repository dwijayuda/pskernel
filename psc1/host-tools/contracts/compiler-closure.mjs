import assert from 'node:assert/strict';

// Counts cover actual recorded source members separately from the admitted graph.
// Each ordinary partial adds exactly one retained private body declaration.
export function validateClosureCounts(observed, sourceCount, assurance) {
  assert.ok(['checked', 'ordinary-checked'].includes(assurance));
  assert.ok(Number.isInteger(sourceCount) && sourceCount > 0);
  assert.equal(observed.assurance, assurance);
  assert.equal(observed.sourceCoreDeclarations, sourceCount, 'complete original Core batch coverage');
  assert.ok(Number.isInteger(observed.coreDeclarations) && observed.coreDeclarations > 0);
  assert.ok(Array.isArray(observed.partialNames));
  assert.ok(observed.partialNames.every(name => typeof name === 'string' && name.length > 0));
  assert.equal(new Set(observed.partialNames).size, observed.partialNames.length);
  if (assurance === 'checked') assert.equal(observed.partialNames.length, 0);
  assert.equal(observed.coreDeclarations,
    sourceCount + observed.partialNames.length, 'exact logical expansion count');
}
