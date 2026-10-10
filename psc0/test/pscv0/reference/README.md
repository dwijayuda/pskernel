# Independent RC4 reference lane

The language reference pins Lean 4.35.0-rc4 at c29b6dda4f7c20e3eeaa717c4e565663c5cfa364. This independent lane checks the actual source produced by the generated portable bridge: readable native `do` and its explicit match/let lowering. A `rfl` proof relates those fixture functions for arbitrary arguments. This is not a proof of the complete bridge algorithm or a PSKernel upgrade. No mathlib dependency or kernel regeneration is involved.
