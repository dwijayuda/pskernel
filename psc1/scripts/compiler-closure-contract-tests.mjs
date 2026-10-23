import assert from 'node:assert/strict';
import { validateClosureCounts } from './compiler-closure-contract.mjs';

let checks = 0;
function pass(value, count, assurance) {
  validateClosureCounts(value, count, assurance); checks++;
}
function refuse(value, count, assurance) {
  assert.throws(() => validateClosureCounts(value, count, assurance)); checks++;
}
const checked = { assurance: 'checked', sourceCoreDeclarations: 3,
  coreDeclarations: 3, partialNames: [] };
const ordinary = { assurance: 'ordinary-checked', sourceCoreDeclarations: 3,
  coreDeclarations: 5, partialNames: ['first', 'second'] };
pass(checked, 3, 'checked');
pass(ordinary, 3, 'ordinary-checked');
pass({ ...checked, assurance: 'ordinary-checked' }, 3, 'ordinary-checked');
refuse(checked, 3, 'ordinary-checked');
refuse(ordinary, 3, 'checked');
refuse(checked, 2, 'checked');
refuse({ ...checked, sourceCoreDeclarations: 2 }, 3, 'checked');
refuse({ ...checked, coreDeclarations: 4 }, 3, 'checked');
refuse({ ...checked, coreDeclarations: 4, partialNames: ['first'] }, 3, 'checked');
refuse({ ...ordinary, partialNames: ['first', 'first'] }, 3, 'ordinary-checked');
refuse({ ...ordinary, partialNames: ['first', ''] }, 3, 'ordinary-checked');
refuse({ ...ordinary, partialNames: ['first', 0] }, 3, 'ordinary-checked');
refuse({ ...ordinary, partialNames: undefined }, 3, 'ordinary-checked');
refuse({ ...ordinary, coreDeclarations: 3 }, 3, 'ordinary-checked');
refuse({ ...ordinary, coreDeclarations: 6 }, 3, 'ordinary-checked');
refuse(checked, 0, 'checked');
refuse(checked, -1, 'checked');
refuse(checked, 3.5, 'checked');
refuse({ ...checked, coreDeclarations: 3.5 }, 3, 'checked');
refuse(checked, 3, 'verified');
console.log('PSC1_COMPILER_CLOSURE_CONTRACT: ' + checks + ' checks passed');
