# PSC2 KernelCore Phase 12 — Recursive Recursor / IH / Iota Design

Status: design for review

Date: 2026-09-30

Base acceptance branch: `psc2/kernel-core-phase11-recursive-inductive-work`

Base accepted head: `c42481c7cf514fee800ca7876057b09600483dc9`

Planning branch: `psc2/kernel-core-phase12-recursive-recursor`

## Purpose

Phase 12 extends the accepted Phase-10 ordinary recursor path to the bounded single-family recursive-inductive surface accepted by Phase 11. The trusted kernel must validate recursive minor induction-hypothesis obligations from admitted constructor types and reduce recursive-constructor recursor applications with the same rule layout used by mature `PSC1Kernel`.

The phase must not duplicate Phase-11 positivity analysis, trust caller-supplied recursive-field metadata, generate recursors inside KernelCore, or widen into mutual/nested induction or compiler cutover.

## Reference behavior to preserve

Mature `PSC1Kernel.Inductive` establishes the canonical recursive contract used by this phase:

1. constructor fields are opened in source order;
2. every accepted recursive field contributes exactly one induction-hypothesis binder to the corresponding minor;
3. IH binders come **after all constructor field binders** in the minor type;
4. for a direct recursive field, the IH target is `motive indices field`;
5. for a functional recursive field `forall args, Family ...`, the IH type is the same `forall args` telescope ending in `motive indices (field args)`;
6. computation-rule RHS lambdas bind the ordinary fixed recursor prefix and constructor fields, **not separate IH lambda binders**;
7. rule bodies synthesize recursive recursor calls internally and pass those calls to the selected minor after the constructor fields;
8. recursive iota therefore uses the existing recursor-rule shape: instantiate universe parameters, apply the fixed recursor prefix, then constructor fields; recursive calls appear in the validated rule RHS itself.

This is intentionally compatible with the existing `RecursorRule { ctor, nFields, rhs }` schema. No new persistent recursive-rule metadata is required.

## Design choice

### Chosen approach: canonical reconstruction from admitted constructors

Phase 12 reuses the Phase-11 trusted recursive-field classifier to reconstruct the expected recursive minor/IH shape from the already-admitted family and constructor metadata. Supplied `RecursorInfo` and rule metadata are accepted only when they match that independently reconstructed contract.

The declaration schema remains unchanged. KernelCore does not persist a second recursive-field table and does not trust caller-provided recursion flags to decide IH placement.

### Rejected alternative: extend `RecursorInfo` / `RecursorRule`

Adding recursive-field positions or IH counts to recursor metadata would make reduction easier to index, but it enlarges the trusted declaration surface, introduces new forgery combinations, and duplicates facts derivable from admitted constructors. This is unnecessary for the Phase-12 surface.

### Rejected alternative: generate recursive recursors inside KernelCore

Kernel-side declaration generation would remove some supplied-metadata validation work but substantially enlarges the TCB with name generation, binder synthesis, elimination-level policy and environment construction. The project architecture keeps declaration generation/elaboration above the trust boundary; the kernel validates the supplied primitive result.

Transient construction of an expected expression for comparison is allowed where it is the smallest clear validator. That is validation logic, not declaration generation: it is not stored as replacement metadata and never substitutes for validating the supplied declaration.

### Rejected alternative: type-check recursive rules only

Subject preservation alone is not enough for Lean-compatible computation metadata. A recursive rule can have the expected type while calling a different recursor, using the wrong recursive field, or omitting/reordering recursive calls. Phase 12 therefore validates the recursive rule's canonical call structure in addition to checking its type.

## Trusted architecture

Phase 12 keeps the existing separation and adds the minimum recursive-specific validation layer:

```text
RecursiveInductive.lean
  trusted positive-recursion classifier
          |
          v
RecursorCanonical.lean / Recursor.lean
  canonical field + IH validation
  canonical recursive-call validation
  supplied-recInfo validation
          |
          v
Reduce.lean
  existing ordinary rule application
  + recursive-iota evidence/tests
```

A new helper module is acceptable only if it reduces coupling and does not duplicate the Phase-11 classifier. The preferred implementation is to keep recursive-shape reconstruction next to the existing recursor canonical validator unless PSC1 recursion restrictions make a small `RecursiveRecursor.lean` module materially clearer.

## Phase-11 classifier reuse

The Phase-11 classifier remains the single authority for whether a constructor field is an accepted recursive occurrence. Phase 12 may extend its **internal summary result** so the recursor validator can reconstruct IH types, but it must not create an independent positivity recognizer.

The required trusted recursive-field description is semantic, not persistent declaration metadata. For each constructor field the validator needs enough information to distinguish:

- non-recursive field;
- direct recursive field;
- accepted functional-recursive field and its argument telescope;
- recursive result indices.

If additional binder information is required to reconstruct functional IH types, extend the internal Phase-11 field-shape summary rather than re-walking positivity with a second algorithm.

When validating a constructor telescope, fields must be opened with fresh variables in order, and the recursive classifier must run at the same binder depth used to derive each field's IH. Dependent later field domains and recursive result indices therefore see the same previously opened constructor fields as the constructor type itself.

## Recursive-family eligibility and metadata revalidation

The existing Phase-10 target predicate intentionally accepts only non-recursive Phase-8 families. Phase 12 must not weaken it globally.

Recursor validation instead gains a recursive-family path with these requirements:

1. exactly one target family in `all`;
2. target name matches its declaration;
3. `numNested = 0`;
4. constructor list is present, ordered and owned by that family;
5. each constructor is re-analysed through the existing Phase-11 recursive classifier under the same resource/budget rules;
6. the re-derived aggregate `isRec` and `isReflexive` values match the stored family metadata;
7. the target actually has recursive evidence for the recursive Phase-12 path.

This preserves the existing non-recursive Phase-10 path unchanged and prevents a forged `InductiveInfo.isRec` / `isReflexive` pair from authorizing recursive recursor semantics by itself.

## Canonical minor validation

For every constructor in the admitted target family, Phase 12 validates the corresponding supplied minor independently from the supplied recursor type.

The expected minor shape is:

```text
forall field_1 ... field_n,
forall ih_1 ... ih_k,
  motive resultIndices (Ctor params field_1 ... field_n)
```

where `ih_1 ... ih_k` correspond exactly, in recursive-field order, to fields classified recursive by the Phase-11 classifier.

For a direct recursive field `r : Family params indices`:

```text
ih : motive indices r
```

For an accepted functional recursive field:

```text
r : forall a_1 ... a_m, Family params indices
```

its IH is:

```text
ih : forall a_1 ... a_m, motive indices (r a_1 ... a_m)
```

The validator must independently check:

- constructor/family ownership and constructor order;
- ordinary field binder count and domains;
- exact recursive-field/IH count and order;
- IH argument telescope shape for functional recursion;
- IH result indices;
- IH recursive-major expression;
- final branch result `motive resultIndices (Ctor params fields)`;
- level-parameter discipline, closedness and no mvar/fvar leakage on exposed metadata;
- existing safety and resource/budget requirements.

A forged minor and matching forged rule must not become valid merely because they are self-consistent with each other.

## Canonical recursive-rule validation

For a recursive constructor, validating `rule.rhs` only by its inferred type is insufficient. The trusted validator must also pin the computation rule to the recursive fields derived from the admitted constructor.

After opening the rule's fixed prefix and ordinary constructor-field lambdas, the rule body must represent the selected minor applied in this order:

```text
minor
  field_1 ... field_n
  recursiveCall_1 ... recursiveCall_k
```

There is exactly one recursive call for each Phase-11-classified recursive field, in recursive-field order.

For a direct recursive field `r`, the canonical recursive call is the same recursor, with the same instantiated recursor universe levels and fixed arguments, applied to that field's recursive indices and then to `r` as major.

For a functional recursive field `r : forall a_1 ... a_m, Family ...`, the argument supplied to the minor is a lambda telescope over `a_1 ... a_m` whose body is that same canonical recursive call applied to `r a_1 ... a_m` with the classifier-derived indices.

Validation may construct this expected recursive-call expression transiently and compare it structurally after the same binder opening/level instantiation discipline used elsewhere in KernelCore. It must not store a generated replacement rule.

This check rejects a type-correct rule that calls another recursor/family, uses the wrong recursive field, has missing/extra recursive calls, or changes their order.

For non-recursive constructors, the accepted Phase-10 rule behavior remains unchanged.

## Recursive rule validation and provisional self-reference

Mature generated recursive computation rules contain calls to the recursor being defined. Therefore recursive rule-RHS type checking needs a temporary environment in which the already-validated recursor declaration is visible.

The safe admission sequence is:

1. validate target family, constructor ownership, recursor counts, base type shape, universe parameters, safety, canonical recursive minor/IH layout and canonical recursive-rule structure;
2. validate the recursor base type itself against the original environment;
3. create a **provisional immutable environment** containing the supplied `recInfo`;
4. validate each rule RHS's closedness, levels and inferred type in that provisional environment;
5. require the inferred rule type to match the independently reconstructed branch result;
6. if any rule fails, return an error and leave the caller's original environment unchanged;
7. only on complete success return the environment containing the recursor.

Canonical rule-structure validation must not depend on successful recursive reduction of the provisional rule itself; it inspects the supplied syntax against the classifier-derived recursive-call contract. This avoids circularly trusting the computation rule in order to validate that same rule.

## Recursive iota

No new recursive-rule payload is introduced. After Phase-12 admission succeeds, the accepted rule RHS already contains the canonical recursive calls.

The existing reduction order remains:

```text
rule.rhs
  -> instantiate recursor universe parameters
  -> apply parameters + motive + all minors
  -> apply constructor fields
  -> reapply trailing outer arguments
```

For recursive rules, applying the constructor fields exposes the rule body containing recursive recursor calls. Normal WHNF then reduces those calls as demanded.

Phase 12 must first test this existing reducer before modifying `Reduce.lean`. Production reduction code changes only if a RED recursive-iota fixture demonstrates an actual missing semantic step. This avoids adding a second runtime IH-synthesis mechanism that would disagree with the reference rule representation.

## Accepted Phase-12 surface

The first accepted recursive recursor fixtures cover the same bounded recursive surface already accepted in Phase 11:

- List-like direct recursive field;
- multiple direct recursive fields, such as a binary tree;
- accepted strictly-positive functional recursive field;
- accepted indexed recursive field.

At least one fixture must exercise an actual recursive computation beyond a single constructor layer so the test proves recursive calls are wired, not merely ordinary constructor dispatch.

## Fail-closed rejection matrix

Phase 12 adds dedicated regressions for at least:

- forged recursive-family flags that disagree with classifier-derived metadata;
- missing IH binder for a recursive field;
- extra IH binder for a non-recursive field;
- IHs in the wrong constructor-field order;
- wrong IH motive;
- wrong recursive indices in an IH;
- IH applied to the wrong recursive field;
- functional IH with missing, extra or wrong argument telescope;
- recursive minor final result forged to match a forged rule;
- missing, extra or reordered recursive calls in a rule RHS;
- rule RHS recursive call targeting the wrong recursor/family;
- rule RHS recursive call using the wrong recursive field or indices;
- wrong constructor/rule ownership or order;
- recursive rule whose type checks only under forged supplied-minor assumptions;
- failed recursive recursor admission leaving the original environment unchanged.

Existing Phase-10 forged-minor regressions remain mandatory and must stay green.

## TDD and assurance order

Implementation proceeds in this order:

1. add RED fixture(s) for direct List-like recursive minor/IH admission;
2. add RED forged-IH and forged recursive-call rejection fixtures;
3. minimally extend trusted canonical validation until those turn GREEN;
4. add RED recursive-iota fixture and first verify whether existing reduction already passes once recursive recursor admission is enabled;
5. add multi-recursive-field fixture;
6. add functional-recursive fixture;
7. add indexed-recursive fixture;
8. add recursive-family metadata-forgery regression;
9. add mature `PSC1Kernel` differential checks where the same surface overlaps;
10. run the actual KernelCore PSC1 source/self-host profile;
11. add `assurance:kernel-core:phase12` and a focused Phase-12 workflow;
12. run all Phase-1 through Phase-12 aggregate gates and full `npm run check` before acceptance.

Every trusted-code change must be justified by a failing fixture. If recursive iota becomes green without a `Reduce.lean` change after recursor admission is corrected, keep the reducer unchanged and record that as evidence.

## Source/TCB constraints

All new trusted source remains within the established PSC1 subset:

- no `partial`;
- no `unsafe`;
- no `IO`;
- no Lean/Std implementation dependencies;
- no custom macros/elaborators;
- no host `List` / `Option` in trusted KernelCore source;
- no mutable semantic caches or replay/session state;
- no stored/generated replacement recursor metadata inside KernelCore.

Use existing resource/budget paths for WHNF, checking and DefEq. Do not introduce unbounded trusted recursion.

## Files expected to change

Likely trusted files:

```text
psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/RecursiveInductive.lean
psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/RecursorCanonical.lean
psc15selfhost/packages/pskernel-core/src/Ps/KernelCore/Recursor.lean
```

`Reduce.lean` is conditional: change it only if RED recursive-iota evidence proves the accepted rule representation cannot reduce correctly with the existing implementation.

Expected non-TCB changes:

```text
psc15selfhost/test/KernelCoreRecursiveRecursor*.lean
psc15selfhost/lakefile.lean
psc15selfhost/package.json
.github/workflows/psc2-kernel-core-phase12-work.yml
.github/workflows/psc2-minimal-kernel.yml
psc15selfhost/docs/continuity/...  (acceptance only after all gates are green)
```

## Non-goals

Phase 12 explicitly does not include:

- mutual inductives;
- nested inductives;
- arbitrary higher-order positivity beyond the Phase-11 admitted classifier surface;
- source-level mutual/nested lowering inside the trusted kernel;
- general recursor declaration generation inside KernelCore;
- K conversion expansion;
- structure eta/projection expansion;
- compiler `CheckedCore` provider cutover;
- removing or replacing mature `PSC1Kernel`;
- full or formally proven Lean 4.34 equivalence.

## Acceptance criterion

Phase 12 is accepted only when the exact implementation head has permanent evidence that:

- recursive-family eligibility is re-derived from admitted constructor shapes rather than trusted from flags alone;
- recursive minors/IHs are independently tied to admitted constructor shapes;
- recursive rule RHSs contain exactly the classifier-derived canonical recursive calls;
- direct, multi-field, functional and indexed recursive recursors pass the bounded positive matrix;
- forged/missing/misordered IH or recursive-call shapes fail closed;
- recursive constructor iota computes through validated rule-RHS recursive calls;
- all earlier Phase-1 through Phase-11 guarantees remain green;
- KernelCore remains PSC1-self-host-checkable;
- the complete repository regression gate passes.

The strongest allowed post-acceptance claim remains bounded to this explicitly tested single-family recursive recursor surface.
