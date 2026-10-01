import { Name, nameEq, nameFromDotted } from '../core/name.js';

/** Names requiring specialized admission.
 *
 * Most are directly name-sensitive in final Lean 4.34's C++ kernel/runtime
 * boundary. Nat.pred and Nat.bitwise are additional pskernel validation
 * dependencies used to prove the canonical semantics of optimized Nat
 * primitives without letting those optimizations self-validate.
 *
 * Char.ofNat and String.ofList are intentionally NOT reserved here. Lean's
 * kernel caches those names for string-literal expansion, but their declarations
 * themselves follow the ordinary declaration path.
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
  'eagerReduce', 'Lean.reduceBool', 'Lean.reduceNat',
].map(nameFromDotted) as readonly Name[];

export function isPrimitiveName(name: Name): boolean {
  return primitiveNames.some(p => nameEq(p, name));
}
