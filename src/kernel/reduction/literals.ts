import { Expr, app, constant, mkAppN, natLit } from '../../core/expr.js';
import { levelZero } from '../../core/level.js';
import { N } from '../names.js';

/**
 * Reproduce Lean 4.34's `string_lit_to_constructor` kernel expansion.
 *
 * Lean strings are expanded to `String.ofList` over a `List Char`, with each
 * Unicode scalar represented by `Char.ofNat`. JavaScript string iteration is
 * by Unicode code point, which matches the UTF-8 decode-to-codepoint step used
 * by the C++ kernel for valid Lean string literals.
 */
export function stringLitToConstructor(e: Expr): Expr {
  if (e.kind !== 'lit' || e.literal.kind !== 'string') throw new Error('expected string literal');

  let chars: Expr = app(constant(N.ListNil, [levelZero]), constant(N.Char));
  const codePoints = Array.from(e.literal.value, ch => ch.codePointAt(0)!);
  for (let i = codePoints.length - 1; i >= 0; i--) {
    const char = app(constant(N.CharOfNat), natLit(BigInt(codePoints[i]!)));
    chars = mkAppN(constant(N.ListCons, [levelZero]), [constant(N.Char), char, chars]);
  }
  return app(constant(N.StringOfList), chars);
}
