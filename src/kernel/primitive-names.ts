import { Name, nameEq, nameFromDotted } from '../core/name.js';

/** Names requiring specialized admission.
 *
 * Most are directly name-sensitive in final Lean 4.34's C++ kernel/runtime
 * boundary. Nat.pred and Nat.bitwise are additional pskernel validation
 * dependencies used to prove the canonical semantics of optimized Nat
 * primitives without letting those optimizations self-validate.
 *
 * Checked declaration APIs must never admit these as ordinary declarations.
 */
export const primitiveNames = [
  'Bool', 'Bool.false', 'Bool.true',
  'Nat', 'Nat.zero', 'Nat.succ',
  'Nat.add', 'Nat.pred', 'Nat.sub', 'Nat.mul', 'Nat.pow',
  'Nat.gcd', 'Nat.mod', 'Nat.div', 'Nat.beq', 'Nat.ble',
  'Nat.bitwise', 'Nat.land', 'Nat.lor', 'Nat.xor',
  'Nat.shiftLeft', 'Nat.shiftRight',
  'String.ofList', 'Char.ofNat',
  'eagerReduce', 'Lean.reduceBool', 'Lean.reduceNat',
].map(nameFromDotted) as readonly Name[];

export function isPrimitiveName(name: Name): boolean {
  return primitiveNames.some(p => nameEq(p, name));
}
