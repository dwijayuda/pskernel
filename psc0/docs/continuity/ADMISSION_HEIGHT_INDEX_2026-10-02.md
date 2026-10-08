# Declaration-height preparation cost

The protected generated compiler replay elaborated all 55 modules, then spent
substantial time preparing canonical admissions. A 20-second CPU profile of that
actual process identified `psBridgeFindRegularHeight`, `psNameEq`, their generator
frames and garbage collection as the dominant work. The height table performed a
linear scan of preceding definitions for every referenced constant.

The encoder now stores heights in a persistent 16-bit hash trie. It uses the
existing structured-name hash and full name equality in collision buckets.
Insertion preserves newest-binding precedence; missing names still have height
zero. Admission order and the regular-height formula are unchanged. The index
is internal compiler metadata and carries no checking authority.

Validation:

- Native bridge suite: PASS, including explicit hash collisions, duplicate-name
  shadowing, persistence, absent names and distinct structured names with the
  same displayed text.
- Focused source guards and complete 55-module portable source profile: PASS.
- Recompiled checked seed on the unchanged `b5ca416d` source snapshot: real Lean
  Wasm admission and emission PASS in 81,620 ms. Both outputs are byte-identical
  to the preceding 116,782 ms checked build:
  - canonical admissions: `4075292da8bbaf27150da4b1713ab995a80670b972d4a333a5e8c01e31bf28ea`;
  - TypeScript: `69b1c8d1f0e6dbc90253c809c4aeb8106adc29abdc8a04a45805f6ea1adc48ff`.

Those timings are local observations, not controlled benchmarks. The protected
replay continues using its original code; this change does not retrofit its
running process. Generated compiler fixed-point verification remains separate.
