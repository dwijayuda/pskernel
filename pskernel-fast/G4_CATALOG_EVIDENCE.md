# G4.1 candidate-declaration catalog: exact scope and validation

**Source:** [`309a4b5d156dd8cab386048cc3aa2c9345713601`](https://github.com/dwijayuda/pskernel/commit/309a4b5d156dd8cab386048cc3aa2c9345713601)  
**CI:** [run 38109975956](https://github.com/dwijayuda/pskernel/actions/runs/38109975956), job `114383337660` — **PASS**  
**Pinned Lean:** 4.35.0-rc4 `c29b6dda4f7c20e3eeaa717c4e565663c5cfa364`; 35 build jobs; 14 V3 Lean source modules with no legacy imports.

`CandidateCatalog.register` preflights only **untrusted proposed** headers and bodies: name uniqueness, level parameter duplication/closedness, constant existence and level arity, selected safety/partial/unsafe caller restrictions, no forward/self reference, correct axiom/value shape, and immutable catalog snapshot behavior. Tests include positive and malformed cases and a body value with escaped binder index.

**Critical trust status:** no type inference, proof equality, inductive validity, quotients or actual admission. The catalog does not acquire logical authority by registering a candidate; its public record and map constructors are not sealed against untrusted plugins. A future *separate checked environment* must only accept fully checked results, using an explicit protected runtime boundary.

G4.1 validation tested the behavior of the persistent data structure; it **did not formally prove** the exact map lookup/insert invariants or behavioral refinement of the full Lean declaration checker. See [catalog design](G4_CANDIDATE_CATALOG.md) and [G4 plan](G4_CHECKER_PLAN.md).
