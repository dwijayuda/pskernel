# PSC2 KernelCore Phase 13 — CheckedCore Shadow Provider Design

Date: 2026-09-30

Status: design for review

Execution branch: `psc2/kernel-core-phase13-checkedcore-shadow`

Base: accepted Phase-12 documentation head `b33e63ed6df2ad10a4a350b19af504fca45655f2`

## 1. Purpose

Phase 13 establishes the first real compiler-to-KernelCore checking boundary without making KernelCore authoritative yet.

The current minimal self-host compiler flow is:

```text
source
  -> parse
  -> elaborate against psBootstrapPreludeEnvironment
  -> PsCompilerAdmissionReadyModule
       { declarations, canonicalAdmissions }
  -> rebuild PsEnvironment
  -> erasure
  -> VerifiedIR
  -> backend
```

KernelCore is not consulted by that path today.

Phase 13 adds an additive **shadow provider**:

```text
                         existing authoritative path
Elaborated Core
     |
     v
AdmissionReadyModule --------------------------> PsEnvironment -> Erasure -> VerifiedIR
     |
     | shadow only
     v
Compiler-side KernelCore adapter
     |
     +-- convert PsName / PsLevel / PsExpr
     +-- project bootstrap prelude as explicit opaque assumptions
     +-- reconstruct supported module declarations
     v
KernelCore admission/check
     |
     v
Shadow-check result/report
```

Success means the supported ordinary-declaration bootstrap surface can be independently checked by KernelCore while the established compiler path remains unchanged and authoritative.

Phase 13 does **not** perform provider cutover.

## 2. Why this phase is intentionally bounded

Compiler `PsDeclaration` and KernelCore declaration types intentionally differ.

Most importantly, compiler `PsRecursorInfo` contains the recursor name, type, inductive names, and counts, but does not contain recursor computation-rule RHSs. Phase 12 KernelCore correctly requires canonical recursor rules and validates recursive self-calls structurally.

Therefore Phase 13 must not translate compiler recursor metadata one-for-one into trusted KernelCore recursor declarations. Doing so would either weaken Phase-12 guarantees or require new rule-generation logic in the trusted core.

The first integration slice is instead:

- bootstrap prelude: opaque assumption boundary;
- module-local definitions: KernelCore-checked;
- module-local theorems: KernelCore-checked;
- module inductive/constructor/recursor batches: explicitly unsupported by this shadow slice;
- existing compiler output: unchanged.

A later phase can reconstruct inductive/recursor candidates above the TCB and ask KernelCore to validate them.

## 3. Trust boundary

### Trusted

Only the existing `packages/pskernel-core/src/Ps/KernelCore/**` implementation remains trusted semantic code.

Phase 13 should not add compiler/elaborator datatypes or transport logic to `Ps.KernelCore`.

### Untrusted / outside the TCB

The following are outside the KernelCore TCB:

- `PsDeclaration -> PsKernelCore*` transport;
- bootstrap-prelude projection;
- declaration selection;
- shadow-report construction;
- compiler API wiring;
- test fixtures.

The adapter may be wrong. KernelCore must still validate every supported module declaration it is asked to admit.

### Explicit bootstrap assumption boundary

`psBootstrapPreludeEnvironment` is already the environment used by the current elaborator. Phase 13 projects its final declaration headers into KernelCore as opaque assumptions.

For each prelude declaration, the shadow environment keeps only:

- name;
- universe parameters;
- type.

Bodies, constructor semantics, recursor rules, recursive metadata, and implementation details are not trusted through this projection.

The projected prelude constants are inserted as assumptions before module checking. This means Phase-13 results are **relative to the existing bootstrap prelude assumptions**; they are not evidence that the prelude itself has been independently KernelCore-certified.

That limitation must remain visible in tests, docs, and allowed claims.

## 4. Placement and dependency direction

Add the adapter in the compiler package, not the kernel package:

```text
packages/compiler/src/Ps/Compiler/KernelShadow.lean
```

Intended imports:

```text
Ps.Core.Declaration
Ps.Environment.Prelude
Ps.KernelCore
```

Then `Ps.Compiler.Api` may import `Ps.Compiler.KernelShadow` and expose additive shadow APIs.

Dependency direction:

```text
Core / Environment ----+
                       v
                  Compiler.KernelShadow ----> KernelCore
                       |
                       v
                   Compiler.Api

KernelCore  -X-> Compiler
KernelCore  -X-> Elab
KernelCore  -X-> Bridge
```

No reverse import into KernelCore is allowed.

No new package is required for Phase 13; a compiler-side module is sufficient and keeps the change small.

## 5. Transport contract

Transport must be deterministic, structural, and fail closed.

### 5.1 Names

Map recursively:

```text
PsName.anonymous  -> PsKernelCoreName.anonymous
PsName.str p s    -> PsKernelCoreName.str (convert p) s
PsName.num p n    -> PsKernelCoreName.num (convert p) n
```

### 5.2 Lists

Convert host/compiler `List α` into `PsKernelCoreList β` structurally and preserve order exactly.

### 5.3 Levels

Supported:

```text
zero
succ
max
imax
param
```

A source/compiler universe metavariable is rejected by the adapter. It is not renamed into a KernelCore metavariable.

### 5.4 Binder info

Map exactly:

```text
explicit          -> default
implicit          -> implicit
strictImplicit    -> strictImplicit
instanceImplicit  -> instImplicit
```

### 5.5 Expressions

Supported structural conversion:

```text
bvar
sortE
constE
app
lam
forallE
letE
lit natural
lit string
proj
```

Compiler `PsExpr.fvar` and `PsExpr.mvar` are rejected by transport. Admission-ready module declarations are expected to be closed, so accepting either would hide a compiler-boundary defect.

KernelCore carries a `nondep` flag on `letE` while compiler `PsExpr` does not. The Phase-13 adapter must set `nondep := false` conservatively. It must never invent a nondependency claim absent from source Core.

Projection expressions may be transported structurally, but KernelCore may reject them when the required inductive metadata is not present in the Phase-13 opaque-prelude shadow environment. That is an allowed shadow limitation, not a reason to weaken KernelCore.

Metadata expressions do not exist in compiler `PsExpr`, so the adapter does not invent `mdata`.

## 6. Shadow error model

Introduce a compiler-side error type so transport/boundary failures are distinguishable from kernel semantic rejection.

Conceptually:

```text
PsCompilerKernelShadowError
  transportUniverseMetavariable
  transportFreeVariable
  transportExpressionMetavariable
  unsupportedDeclaration
  duplicatePreludeAssumption
  kernelRejected String
```

Exact constructor spelling may follow existing project conventions, but the distinction is required.

The existing `PsCompilerError` does not need to absorb these errors in Phase 13 because the authoritative compile APIs remain unchanged.

## 7. Bootstrap-prelude projection

Build a deterministic `PsKernelCoreEnvironment` from the final declarations already stored in `psBootstrapPreludeEnvironment`.

For each prelude declaration:

1. convert its name, level parameters, and type;
2. create `PsKernelCoreConstantBase`;
3. represent the header as an opaque assumption, normally `PsKernelCoreConstantInfo.axiomInfo` with `isUnsafe := false`;
4. insert it into the shadow environment with duplicate detection.

This projection intentionally does **not** call trusted admission on each prelude header in Phase 13. The prelude is an explicit imported assumption set for this first integration slice.

The shadow checker must not silently replace duplicates. A duplicate in the projected final environment is a boundary error.

The projected environment must include all final prelude declaration names visible to ordinary module expressions, including inductive types, constructors, recursors, and primitive operation declarations, but only as opaque typed constants.

This supports module checking without pretending their computation behavior has been certified.

## 8. Supported module declaration admission

Process `PsCompilerAdmissionReadyModule.declarations` in source order.

### 8.1 Definition

Convert:

- name;
- universe parameters;
- declared type;
- value.

Construct a safe KernelCore definition:

```text
safety = safe
hints = regular 0
```

`regular 0` is a deterministic Phase-13 transport default. Canonical-admission JSON height metadata is deliberately not trusted as KernelCore evidence.

Admit using the existing trusted KernelCore definition-admission path. On success, use the returned environment for checking subsequent declarations.

### 8.2 Theorem

Convert name, universe parameters, type, and proof value, then admit with the existing KernelCore theorem-admission path.

### 8.3 Explicitly unsupported in the Phase-13 module slice

Fail closed on:

```text
axiomDecl
partialDecl
opaqueDecl
inductiveDecl
constructorDecl
recursorDecl
```

Some of these are already rejected by the current canonical admission-ready boundary; the shadow checker must still define its own behavior explicitly.

In particular, inductive/constructor/recursor declarations must not be approximated as checked module declarations.

## 9. Shadow result API

Add additive APIs, conceptually:

```text
psCompilerKernelShadowCheckPrepared
    : PsCompilerAdmissionReadyModule
      -> Except PsCompilerKernelShadowError PsCompilerKernelShadowReport

psCompilerKernelShadowCheckElaborated
    : PsElabModuleResult
      -> Except PsCompilerError PsCompilerAdmissionReadyModule
      -> ...

psCompilerKernelShadowCheckSource
    : PsCompilerSourceKind
      -> String
      -> ...
```

The implementation should keep the public surface simpler than the conceptual sketch if possible. The required capabilities are:

- check an already prepared module after `psCompilerValidatePrepared` succeeds;
- convenience entry point from source for tests/users;
- return enough deterministic data to assert success and declaration count;
- never change `psCompilerVerifiedIrFromPrepared` behavior.

Recommended report shape:

```text
PsCompilerKernelShadowReport
  checkedDeclarations : Nat
  finalEnvironment : PsKernelCoreEnvironment
```

If exposing the final environment adds no test value, only the count plus a deterministic success marker is sufficient. YAGNI applies.

## 10. Prepared-artifact integrity ordering

`psCompilerKernelShadowCheckPrepared` must first validate the existing admission-ready artifact with `psCompilerValidatePrepared`.

Required ordering:

```text
prepared artifact
  -> existing canonicalAdmissions integrity check
  -> shadow transport
  -> KernelCore checking
```

A forged `canonicalAdmissions` string must therefore fail before any shadow result can be reported.

The shadow checker does not replace the existing admission-ready integrity boundary.

## 11. Existing compile path remains authoritative

Phase 13 must not modify the semantics of:

```text
psCompilerEnvironmentFromPrepared
psCompilerVerifiedIrFromPrepared
psCompilerVerifiedIrSource
backend compilation APIs
```

No existing success becomes a compile failure merely because shadow checking is unsupported or rejects it.

Shadow checking is invoked only by its explicit API/tests in this phase.

This preserves bootstrap stability while gathering independent kernel evidence.

## 12. Test strategy

Implementation follows RED -> GREEN TDD.

### 12.1 First RED fixture

Add a Phase-13 compiler/kernel-shadow test that expects a source-level API capable of checking:

```lean
def answer : Nat := 42
```

The first failure must be due to the absent Phase-13 shadow interface, not a malformed fixture.

### 12.2 Positive matrix

At minimum:

1. Lean frontend: `def answer : Nat := 42`;
2. ProofScript frontend equivalent where the current frontend supports it;
3. ordinary function definition over a prelude type;
4. dependent/polymorphic ordinary definition if accepted by the current minimal frontend;
5. theorem/proof declaration already supported by the current pipeline;
6. two sequential definitions where the second references the first.

The final case proves successful KernelCore environment threading across module declarations, not just isolated checks.

### 12.3 Negative matrix

Dedicated tests should cover:

- forged prepared `canonicalAdmissions` rejected before shadow checking;
- converted definition body with a type mismatch rejected by KernelCore;
- unknown constant rejected by KernelCore;
- duplicate module declaration rejected;
- free variable rejected at transport boundary;
- expression metavariable rejected at transport boundary;
- universe metavariable rejected at transport boundary;
- module inductive declaration rejected as unsupported by the Phase-13 shadow slice;
- constructor/recursor declaration cannot bypass that unsupported boundary.

Where creating a malformed `PsCompilerAdmissionReadyModule` directly is needed, tests must recompute or deliberately control canonical-admission integrity so the intended layer is actually exercised.

### 12.4 Noninterference regression

For a common prepared module:

```text
VerifiedIR before shadow integration == VerifiedIR after shadow integration
```

The normal TypeScript bootstrap output should remain green without calling the shadow API.

Existing Rust/WASM/TS regression suites remain required through the aggregate repository gate.

## 13. Assurance gates

Phase 13 acceptance requires, in order:

```text
RED Phase-13 fixture
  -> smallest adapter + shadow API
  -> focused Lean Phase-13 tests
  -> Phase-12 aggregate assurance remains green
  -> PSC1 source/self-host profile remains green for trusted KernelCore
  -> minimal self-host tests remain green
  -> bootstrap / fixed-point gates that are already part of repository checks
  -> independent npm run check
```

Because Phase 13 should not modify trusted KernelCore semantics, the KernelCore trusted-module count should remain 23 unless an independently justified trusted fix is discovered. Any trusted KernelCore source change upgrades the review burden and must be called out explicitly.

## 14. CI

Add a focused Phase-13 work/acceptance workflow following the established KernelCore phase pattern.

It should build at least:

```text
PsKernelCore
PsCompiler
```

and run:

- Phase-13 shadow-provider fixtures;
- inherited Phase-12 aggregate assurance;
- existing PSC1 source/self-host gate;
- final full `npm run check` for permanent acceptance.

Do not weaken or remove earlier gates.

## 15. Allowed claims after Phase 13

If all gates pass, it will be supported to say:

- compiler Core names, levels, and the supported closed expression surface can be transported deterministically into KernelCore;
- the existing bootstrap prelude can be represented as an explicit opaque assumption boundary for shadow checking;
- module-local ordinary definitions and theorems in the accepted Phase-13 slice are independently admitted by KernelCore;
- sequential checked module declarations thread through the KernelCore environment;
- forged prepared artifacts still fail the existing canonical-admission integrity boundary before shadow checking;
- the established erasure/VerifiedIR/backend path remains unchanged and green;
- KernelCore remains non-authoritative in Phase 13.

## 16. Explicit non-claims

Phase 13 does **not** establish:

- independent KernelCore certification of `psBootstrapPreludeEnvironment`;
- trusted inductive/constructor/recursor reconstruction from compiler declarations;
- KernelCore checking of every currently elaboratable PSC2 program;
- provider cutover;
- `CheckedCore` as the sole source accepted by erasure;
- removal or replacement of the existing `PsEnvironment` provider;
- mutual/nested inductive support;
- full Lean environment replay;
- full K7/K8 replay;
- formal or complete semantic equivalence with Lean 4.34.

## 17. Follow-on phases

Recommended sequence after Phase 13:

```text
Phase 13
  ordinary-definition/theorem shadow checking
        |
        v
Phase 14
  untrusted inductive + constructor + recursor candidate reconstruction
  -> KernelCore validation
        |
        v
Phase 15
  authoritative CheckedCore provider cutover
  while retaining old provider as differential/fail-safe path
        |
        v
bootstrap / self-host / fixed-point acceptance
```

Mutual and nested source induction should continue to lower above the TCB rather than expanding the trusted kernel merely for source convenience.

## 18. Design invariants

The phase is accepted only if all of these remain true:

1. **KernelCore validates; compiler transport does not confer trust.**
2. **The adapter stays outside `Ps.KernelCore`.**
3. **Prelude projection is explicitly an assumption boundary, not a certification claim.**
4. **Unsupported declarations fail closed in the shadow API.**
5. **Recursor rules are never invented or omitted inside trusted KernelCore merely to make integration easier.**
6. **The authoritative compiler/erasure/backend path is unchanged in Phase 13.**
7. **No provider cutover occurs without a later, independently accepted phase.**
8. **Every trusted KernelCore addition, if any becomes unavoidable, remains PSC1-subset/self-host-checkable.**
