# Bounded design experiments — observed results

**Executed 3 October 2026 in the working container. Scope: isolated models and hand-authored TypeScript candidate runtime code only.** No code here was emitted by PSC. No Lean proof, kernel check, compiler fixed point, browser, Rust or Wasm test was run.

## 1. Environment

Observed: Python 3.13.5, Node v22.16.0, TypeScript 5.8.3. `lean` and `lake` were not found on PATH. These versions describe the experiment environment, not the proposed platform's final deployment lock.

The experiments motivate test cases and expose simple bad alternatives. Their passing result is not a soundness, termination, scheduler or compiler-preservation proof.

## 2. Finite Python policy models

The executed logic is reproducible with:

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

Observed outcomes:

| Model | Domain | Result | Limitation |
|---|---|---|---|
| Candidate Nat subtraction | 1,089 pairs, each operand 0..32 | Candidate matched `max(a-b,0)`; plain integer subtraction disagreed in 528 cases. | The model directly encodes the proposed rule; not a Lean/target compiler equivalence test. |
| Foreign absence | Four labelled states | Tagged representation retained four distinct outcomes; lossy Option-like conversion retained two. | Plain data labels only; no proxies, getters or serialization engine. |
| Weak sorting contract | 40 lists of length 0..3 over {0,1,2} | Always-empty output is sorted for all; fails permutation for 39 inputs. | Illustrates one weak specification; no general completeness checker. |
| Terminal-event arbitration | 27 sequences of three terminal events | Exactly one committed transition; first terminal event wins. | No concurrent scheduler, cleanup, fairness or external side effects. |

The natural subtraction example `(2,5)` gives -3 under ordinary integer subtraction and 0 under the candidate natural rule. This informs the backend primitive tests; it does not prove a backend.

## 3. Actual TypeScript-to-JS candidate test

The following hand-authored file was compiled with the installed real TypeScript compiler and executed with Node:

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

Executed command shape (the actual working directory was `/mnt/data/psc3_research`):

```sh
node --version
tsc --version
tsc --strict --noEmitOnError --target ES2022 --module ES2022 \
  --outDir out boundary-experiment.ts
node out/boundary-experiment.js
```

Observed compiler/execution result: success. Output reported 1,089 pair cases, the large exact-integer case passed, negative input was rejected, presence tags were `missing`, `undefined`, `null`, `value`, and the astral string had two code units and one iterated code point.

The property classifier is intentionally not a production arbitrary-object decoder. It does not establish a security boundary against getters/proxies, prototype mutation or reentrancy. The numeric test does not cover the full runtime operation set. Node and tsc success do not establish PSC preservation.

## 4. Upstream evidence versus local execution

The pinned Lean parser and intrinsic-verification test file were read from the official source. Their content informed the proposed source profile. Those upstream tests were not executed locally. Candidate Lean/PSC examples remain unexecuted; the full proposed `.psx` and platform APIs do not yet exist in this design change.

## 5. Next decisive experiments

Run exact native examples under the proposed Lean pin, including negative dependent updates and false contracts; compare owned elaboration; replay actual evidence with the independent checker; compile actual PSC output; exercise real browser/service behavior; and run the user/adoption studies in the roadmap. Do not promote these finite models into a stronger status in the meantime.
