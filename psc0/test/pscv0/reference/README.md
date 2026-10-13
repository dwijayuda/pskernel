# Independent 4.35.0 reference lane

Reference pin: Lean4.35.0 at eb6cafb7290e8bd5f2937522d8d804f58f02bafc.
The lane checks the actual readable native-do and explicit-match functions emitted by the generated portable bridge. Their universally quantified equality is proved by exhaustive `Except` constructor cases followed by `rfl`; symbolic `rfl` alone was not established.

The standalone retained-artifact lane verifies bridge/TS/admission hashes, current source equality and Linux38/38 results before reusing the original generated functions. It changes only the proof body, never the functions or equality statement. This avoids rebuilding the unchanged bridge after a reference-lane setup error. No mathlib or kernel regeneration is involved.

A successful fixture theorem is not a proof of the whole bridge algorithm, compiler semantic preservation, or PSKernel's soundness. Historical bootstrap receipts retain their original 4.34 identity; this lane does not rerun self-hosting. The original failed CI attempt retains its failure status.
