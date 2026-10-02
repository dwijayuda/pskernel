# Bounded design experiments — historical results and pending syntax gates

**Historical draft-0.2 experiment record, reported 3 October 2026. Not rerun by the v0.7 syntax repair.** [ProofScript v0.7](SYNTAX_AND_GRAMMAR_V07.md) governs source grammar; Python and TypeScript below are explicitly foreign experiment code, not `.ps` examples.

No listed code was emitted by PSC. The previous report made no Lean proof, kernel, fixed-point, browser, Rust or Wasm execution claim. This repair preserves that limitation and does not infer parser acceptance from these models.

## 1. Historical environment

Reported: Python 3.13.5, Node v22.16.0 and TypeScript 5.8.3; Lean/Lake unavailable. These describe the original experiment, not the current/final platform toolchain. The earlier working directory is not assumed to exist now.

The experiments motivate negative cases. They do not establish soundness, termination, scheduler correctness or compiler preservation.

## 2. Finite Python policy models

Reproduction snippet retained from the prior report:

```python
from itertools import product
from collections import Counter

pairs = list(product(range(33), repeat=2))
def natural_sub(a, b):
    return a - b if a >= b else 0
assert all(natural_sub(a, b) == max(a - b, 0) for a, b in pairs)
plain_mismatches = sum(a - b != natural_sub(a, b) for a, b in pairs)

states = ['missing', 'undefined', 'null', 'value']
tagged = {s: (s, 17 if s == 'value' else None) for s in states}
collapsed = {s: None if s != 'value' else 17 for s in states}
assert len(set(tagged.values())) == 4

inputs = [v for n in range(4) for v in product(range(3), repeat=n)]
wrong_permutations = sum(Counter(v) != Counter(()) for v in inputs)

terminal = ['success', 'failure', 'cancelled']
sequences = list(product(terminal, repeat=3))
def finish(state, event):
    return event if state == 'running' else state
for seq in sequences:
    state, changes = 'running', 0
    for event in seq:
        new = finish(state, event)
        changes += new != state
        state = new
    assert changes == 1 and state == seq[0]

print(len(pairs), plain_mismatches)
print(len(set(tagged.values())), len(set(collapsed.values())))
print(len(inputs), wrong_permutations)
print(len(sequences))
```

Historical reported outcomes:

| Model | Domain | Result | Limitation |
|---|---|---|---|
| Nat subtraction candidate | 1,089 pairs, operands 0..32 | Matched `max(a-b,0)`; plain subtraction differed in 528 cases. | Direct model of the rule, not a Lean/PSC compiler test. |
| Absence | Four labels | Tagged form kept four outcomes; collapsed form kept two. | No getters, proxies or serialization engine. |
| Weak sorting specification | 40 lists, length 0..3 over 0..2 | Always-empty output sorted; permutation failed for 39 inputs. | One weak-spec example, not specification completeness. |
| Terminal-event model | 27 three-event sequences | One committed transition, first event wins. | No concurrency, cleanup, fairness or external effects. |

The `(2,5)` subtraction difference motivates primitive tests; it is not backend evidence.

## 3. TypeScript-to-JS candidate experiment

The previous report says the following hand-authored **TypeScript**, not ProofScript, was compiled and executed:

```typescript
// Candidate adapter experiment only; not PSC-generated code.
function natSub(a: bigint, b: bigint): bigint {
  if (a < 0n || b < 0n) throw new RangeError('not a Nat representation');
  return a >= b ? a - b : 0n;
}
function assert(ok: boolean, why: string): void {
  if (!ok) throw new Error(why);
}
let cases = 0;
for (let a = 0n; a <= 32n; a++) for (let b = 0n; b <= 32n; b++) {
  assert(natSub(a, b) === (a < b ? 0n : a - b), 'subtraction mismatch');
  cases++;
}
const large = (1n << 80n) + 3n;
assert(natSub(large, 1n) === (1n << 80n) + 2n, 'large exact integer');
let negativeRejected = false;
try { natSub(-1n, 0n); }
catch (e) { negativeRejected = e instanceof RangeError; }
assert(negativeRejected, 'negative input must be rejected');
function classify(o: Record<string, unknown>, k: string): string {
  if (!Object.hasOwn(o, k)) return 'missing';
  if (o[k] === undefined) return 'undefined';
  if (o[k] === null) return 'null';
  return 'value';
}
const tags = [classify({}, 'x'), classify({x: undefined}, 'x'),
  classify({x: null}, 'x'), classify({x: 3}, 'x')];
assert(new Set(tags).size === 4, 'boundary presence collapsed');
const text = '\u{1F600}';
assert(text.length === 2 && [...text].length === 1,
  'UTF-16 versus code-point example');
console.log(JSON.stringify({
  scope: 'candidate TS adapter tests only; not PSC output, not proof',
  pairCases: cases, largeInteger: true, negativeRejected,
  presenceTags: tags,
  astralText: {codeUnits: text.length, codePoints: [...text].length}
}));
```

Original command shape, recorded for reproduction rather than rerun here:

```sh
node --version
tsc --version
tsc --strict --noEmitOnError --target ES2022 --module ES2022 \
  --outDir out boundary-experiment.ts
node out/boundary-experiment.js
```

The prior report recorded success: 1,089 pairs, large-integer case, rejected negative input, four presence tags and two code units versus one iterated code point. It identified `/mnt/data/psc3_research` as the then-working directory. This repair makes no claim that those files persist.

The classifier is not a secure arbitrary-object decoder. Tests exclude getters/proxies, prototype mutation and reentrancy, and do not cover the entire primitive set. TS/Node success is not PSC preservation or v0.7 grammar acceptance. Its brace-bodied functions and `=` bindings are TS syntax and must not be copied into `.ps` examples.

## 4. Source evidence versus execution

Earlier upstream parser/intrinsic tests were inspected under a 4.34.1 candidate pin, not executed locally. The current syntax authority is the repository v0.7 reference with its 4.34.0 canonical baseline. Later-patch observations do not establish this source profile.

This correction reviewed source rules and rewrote documentation examples, but did not run the v0.7 parser/lowerer or Lean oracle. Candidate `.ps`, canonical `.lean`, and UI extension examples remain unexecuted. Registered/reference-specified does not mean implemented or S2-proved.

## 5. Pending v0.7 conformance experiments

Run the reference registry and positive/negative/lowering corpus using the actual frontend. Cover valid/invalid aliases; adjacent versus spaced/comment-separated calls; tuple arity; `:=` and category semicolons; braced data and match with native patterns; `fun`; inherited scopes; proof/do category boundaries; and source maps.

Then check canonical output with the exact Lean environment, compare owned elaboration, replay actual proofs and execute PSC-generated targets. `.ps` extension renaming is not the oracle experiment. Optional UI syntax needs its own explicit dialect and expansion tests.

No finite model or documentation scan substitutes for those gates.
