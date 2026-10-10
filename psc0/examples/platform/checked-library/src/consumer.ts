import { makeQuantity, type Quantity } from './Quantity.js';
import { readQuantity, sameQuantity } from './Main.js';

function expectRejected(label: string, operation: () => unknown): void {
  let rejected = false;
  try { operation(); } catch { rejected = true; }
  if (!rejected) throw new Error(label + ' was accepted');
}

const quantity: Quantity = makeQuantity(42n);
if (readQuantity(quantity) !== 42n) throw new Error('Unexpected ProofScript result');
if (sameQuantity(quantity) !== quantity) throw new Error('Opaque identity was lost');
if (!Object.isFrozen(quantity)) throw new Error('Public handle is mutable');

expectRejected('negative Nat', () => makeQuantity(-1n));
expectRejected('forged handle', () => readQuantity({} as Quantity));
expectRejected('frozen lookalike', () => readQuantity(Object.freeze({}) as Quantity));
expectRejected('proxy handle', () => readQuantity(new Proxy(quantity, {})));

console.log('ProofScript library answer: 42');
