import { Name, nameEq, nameFromDotted } from '../core/name.js';

/** Names whose meaning is wired into the Lean 4 kernel/runtime boundary.
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
].map(nameFromDotted) as readonly Name[];

export function isPrimitiveName(name: Name): boolean {
  return primitiveNames.some(p => nameEq(p, name));
}
