# Sources and scope

The examples were authored for this pack, using the supported syntax and behavior present at repository commit `7a910a64743cceadc06b2a4a8a20b486d300b7f1`. Qualification uses the unchanged compiler package `proofscript@0.1.0-psc1.12` with official Lean 4.35.0 linear-memory Wasm checking.

Primary references:

- [Inference/control fixtures](https://github.com/dwijayuda/pskernel/blob/7a910a64743cceadc06b2a4a8a20b486d300b7f1/psc1/test/InferenceControlFixtures.ps): calls, lambdas, inferred parameters, namespaces, and finite control flow.
- [Bootstrap tests](https://github.com/dwijayuda/pskernel/blob/7a910a64743cceadc06b2a4a8a20b486d300b7f1/psc1/test/BootstrapTests.lean): `.ps` data and recursion fixtures, typed functions, and proof-term forms.
- [Data-model example](https://github.com/dwijayuda/pskernel/blob/7a910a64743cceadc06b2a4a8a20b486d300b7f1/psc1/test/applications/MiniCompiler/Syntax.ps): structures and inductive declarations.
- [Do-block tests](https://github.com/dwijayuda/pskernel/blob/7a910a64743cceadc06b2a4a8a20b486d300b7f1/psc1/test/DoTests.lean): checked mutation, finite loops, captures, and early returns.
- [Operator tests](https://github.com/dwijayuda/pskernel/blob/7a910a64743cceadc06b2a4a8a20b486d300b7f1/psc1/test/OperatorTests.lean): expression operators and intentional comparison-chain refusal.
- [ProofScript parser](https://github.com/dwijayuda/pskernel/blob/7a910a64743cceadc06b2a4a8a20b486d300b7f1/psc1/packages/syntax/src/Ps/Syntax/ParseProofScript.lean), [elaborator](https://github.com/dwijayuda/pskernel/blob/7a910a64743cceadc06b2a4a8a20b486d300b7f1/psc1/packages/elab/src/Ps/Elab/Declaration.lean), and [prelude](https://github.com/dwijayuda/pskernel/blob/7a910a64743cceadc06b2a4a8a20b486d300b7f1/psc1/packages/environment/src/Ps/Environment/Prelude.lean): exact current language boundaries.

The positive examples contain explicit proof terms and checked definitions. They do not introduce axioms or use `sorry`. User-defined logical encodings are named and explained as such. Imported example helpers are included locally; no external standard-library source tree is required.

Compiler package SHA-256: `9a66dcd0f92aaa60f600674fb91b31bc0d67b211d1e9e004146baa8e96502fcc`.

The compiler, kernel, self-hosting inputs, and their qualification artifacts are unchanged. Running examples provides example-specific evidence; it does not establish a new compiler fixed point or formal source-to-backend preservation theorem.
