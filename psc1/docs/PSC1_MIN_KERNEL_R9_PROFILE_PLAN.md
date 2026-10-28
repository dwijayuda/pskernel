# R9 C1 indexed byte-source decision

Status: thirteen theorem reports passed in the Linux candidate
b852e57e12df03b0ca4517372c5725f0d337e11d
([run 40693341901](https://github.com/dwijayuda/pskernel/actions/runs/40693341901)).
The earlier 7978fa8f candidate failed two proof-script elaboration steps.
Native/generated qualification is pending; the full experiment remains open.
The stable U1/R4B checker remains unchanged. No parser/admission entry is added.

The complete compiler packet is 29889352 bytes. A linked Nat byte per input byte
does not meet the intended resource boundary. This experiment uses a pure indexed
Nat-to-Nat byte source, explicit size and bounded cursor, avoiding a whole-input
Nat list at the host boundary. A physical Uint8Array snapshot can supply scalar
bytes without new ByteArray/UInt8 compiler builtins or private runtime carriers.

State an independent read event and chronological span relation. Prove read
soundness/completeness, EOF/range refusal, actual walk/reflected span equivalence,
length/byte bounds and agreement with an independent chronological digest fold.
The digest is only a traversal witness; it never grants admission.

After Linux proof/dependency reports pass, compile the real source to strict
TypeScript/JavaScript, compare native/generated results with an independent byte
oracle, and check exact source admissions with the pinned official checker.
Exercise empty, all byte values, range errors and complete current compiler
transport bytes under existing time/memory budgets. Record callback indices,
source/output/payload hashes and process resource scope.

Physical byte-adapter fidelity and callback purity remain explicit assumptions
until separately refined. No parser, arena, declaration, universe, foundation or
full compiler theorem follows. C1a and C1/C2/C3 remain open; coverage stays 0/124.
Existing R0-R8 guards, stable public API, runtime source and production refusal
are unchanged. All project execution stays on GitHub Actions Linux.

Repeated selected CI jobs have stalled in unconditional elan installer downloads.
A shared Linux-Actions-only cache-aware helper preserves pins/test bodies/job
budgets and caps cold download/installer attempts. Its callers require Linux
qualification before adoption.
