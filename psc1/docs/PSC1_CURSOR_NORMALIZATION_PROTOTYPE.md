# Bounded lexer String-to-list normalization

Exact Rust crash diagnosis 39891954467 at 5246c05af5236df2a41a4f98c2572c56dbab6ecf
shows repeated psLexStringToListFromWithFuel worker frames, after the earlier
private Rc destruction problem was corrected. The old character traversal
retains one call/generator continuation per character.

Use an accumulator and reverse once; preserve exact fuel, end/invalid byte
offset behavior, character order and input-derived bound. Native proof retains
the original definition and establishes equality for every fuel/source/offset.
No frontend, kernel, ABI, stack/heap/timeout limit or verification bypass.
The native executable also covers UTF8 offsets/fuels and 100000 source chars.

The same Cursor.lean and proof bytes are applied to both isolated target
branches. Proof, both grammar audits, genuine generations and all ten frozen
cases are mandatory in each Linux workflow. Do not claim qualification before
terminal CI. Fresh full seven-backend qualification is required after promotion.
