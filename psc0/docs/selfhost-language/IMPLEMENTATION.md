# PSC0 SH/1 implementation and qualification

Status: implementation candidate; qualification receipts decide promotion. This
document supplements the proposed contract in [SPEC.md](SPEC.md). It does not
retroactively change the historical source record or activate a strict profile.

## Implemented capability

The portable declaration-batch elaborator first uses the existing stable path.
Only `structuralRecursionInvariantArgument` invokes the new typed normalization
attempt. A definition accepted by the stable path keeps its previous lowering.
Other errors propagate; failed normalization is not retried recursively.

For a supported definition, the normalizer identifies changing explicit value
parameters by lexical binding identity. It retains the structural major and
unchanged parameters outside a private worker, moves changing state into the
worker result telescope, and applies recursive state arguments to induction
hypotheses. A separately type-checked public wrapper preserves the original
name, full type, binder kinds and argument order, including erased proof and
implicit type arguments.

For example, the intended authoring form is:

```lean
def reverseInto {alpha : Type}
    (items : List alpha) (out : List alpha) : List alpha :=
  match items with
  | List.nil => out
  | List.cons item tail => reverseInto tail (List.cons item out)
```

The compiler performs the worker transformation. It is implemented in the older
accepted subset, so the historical compiler can build the first candidate.

### Deliberate boundaries

- The definition body starts with an existing flat constructor match on an
  explicit parameter. This checkpoint does not add equation compilation,
  arbitrary wrapper peeling, mutual recursion or general termination proofs.
- Changed parameters must be runtime value parameters. Parameter domains and
  the result must not depend on the major or generalized state.
- Self calls must supply exactly the explicit parameter telescope; they may
  only recurse on an admitted constructor child. An escaping self reference is
  rejected. Ordinary partial application of the completed public definition
  remains supported.
- Name decisions use lexical identities. All internal worker parameters are
  alpha-renamed to names unavailable in source syntax. The global worker uses
  a numeric internal name component, and environment insertion checks collision.
- Unrelated nested matches retain available outer induction hypotheses but
  cannot introduce decreasing children. Descendant hypotheses are available
  only when their expected result telescope agrees with the whole worker
  result; narrower nested motives are outside this checkpoint.

The kernel/provider implementation and metatheory are unchanged on this branch.

## Preparation sessions

`PsCompilerPreparationState` stores both the environment and reversed ordered
declarations. Start, parsed-step, source-step and finish are pure portable
operations. Existing aggregate public functions delegate to the same seam.

`scripts/generated-preparation-session.mjs` retains an exact-source prefix
inside one compiler instance. Any changed module invalidates the entire later
preparation suffix, including body-only changes whose exported names and types
are unchanged. Parsed syntax has a separate LRU. Failures retain only the
successfully prepared prefix, so repaired input cannot reuse a failed suffix.

Returned preparation data is deeply frozen before the caller can observe it.
The caller must resolve/read current source on every request and bind compiler
identity to the bytes actually loaded. Compiler values cannot cross module
instances. A warm no-change request performs zero parse/elaboration/finish work.

The LRU bounds entry count and retained source-text bytes; it does not promise a
hard AST or whole-prefix heap bound. Receipts report cache reuse, invalidation,
source identities and separate timings. Preparation produces admission-ready
data, never reusable provider acceptance.

## Qualification architecture

The historical source at
`37f63c39d4a07189938046c64152bba25d789450` is a recovery input outside mutable
`dist`. Its 55 ordered source blobs are checked against the immutable baseline.
Recovery uses pinned Lean and TypeScript5.8.3. The seed cache identity includes
the historical source, toolchain and versioned recovery recipe; changing a
capability test or session helper does not invalidate this unchanged seed.

The branch-scoped workflow performs one coherent candidate gate. It builds the
native PSC frontend and makes the generated candidate consume raw authored
`.lean` and `.ps` capability examples. The corpus covers accumulator changes,
simultaneous state swapping, a state parameter before the major, function
results, generic values, proof erasure, public partial application and lexical
shadowing. Negative examples exercise the semantic boundary.

Session conformance uses the old generated seed as an independent admission
oracle for existing-subset examples. It covers cold/warm behavior, body edits,
suffix reuse, failure repair, source-kind changes, fresh module instances,
mutation attempts and parse-cache eviction.

At a promotion checkpoint the commit message contains `[sh1-qualify]`. The
same workflow first passes the candidate gate and then computes:

```text
C1 = S0(A)
C2 = C1(A)
C3 = C2(A)
```

Every generation reads current raw authoring source. C2 and C3 must have equal
canonical surface source, canonical admissions, TypeScript and JavaScript.
Receipts record the executing compiler digest, exact source closure, toolchain,
recipe and product hashes. C1/C2 equality is not a requirement: the new compiler
may legitimately improve lowering when it compiles itself.

The existing surface printer remains syntax-only. Its canonical output is
called **canonical surface source**. Lowered worker representation is compared
through **canonical admissions**. A pretty-print round trip does not substitute
for generated compilation of raw authoring forms.

## Independent acceptance axes

| Axis | Required evidence |
| --- | --- |
| Compiler-qualified capability | Current-source C2/C3 products, raw capability execution and conformance receipts |
| Kernel-checked products | Actual acceptance of exact canonical admissions by the separately pinned provider |
| Strict SH/1 runtime qualification | Complete runtime typing/layout/intrinsic obligations; an IR inventory alone is insufficient |

The native baseline at
`963030dc2d154008fccc82e7c8ed29331f138799` passed its historical full checked
self-host run [37825822957](https://github.com/dwijayuda/pskernel/actions/runs/37825822957).
That historical result does not accept newly generated worker admissions.
New products are checked through a separate pinned provider checkout.

`original-ir-inventory.mjs` examines the original PSC0 IR produced by the exact
compiler instance. It reports unknown types, scope/layout/arity findings and
unresolved obligations without expanding the portable compiler closure.
It is a diagnostic artifact and does not grant strict-profile acceptance.

## Migration order

1. Qualify the implementation while it remains consumable by the historical
   seed. Preserve the exact qualified compiler/source identity.
2. Configure a recoverable, pinned qualified seed before adopting new authoring
   forms in compiler source.
3. Migrate one useful family: Foundation.List accumulator and paired-traversal
   workers. Preserve public names/types and numeric/list semantics. Compare
   behavior with the previous qualified implementation.
4. Qualify the migrated current source at the next promotion checkpoint.
   Expand to additional families only when this evidence is complete.
5. Use prefix preparation reuse for routine iteration. Reserve full fixed-point
   and provider checking for semantic promotion checkpoints.

Do not rewrite the whole compiler mechanically, rename the profile to claim
support, or overwrite the historical 55-module baseline. Exact progress,
qualified commit/run IDs and any remaining blocker live in
[AI_WORK_STATE.md](../../AI_WORK_STATE.md).
