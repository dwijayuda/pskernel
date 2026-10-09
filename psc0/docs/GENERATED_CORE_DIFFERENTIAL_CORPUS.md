# Generated PSKernel Core — Positive/Negative Differential Corpus

Status: **experimental, untrusted generated JS checker candidate**.

Scope: PSC0 compiler and kernel correctness, not offensive-security work.
Canonical source of truth: GitHub. No local builds or file mutations.

## Motivation

The kernel's TypeScript 7.0.2 JavaScript executable passed the runtime
smoke suite in Actions #37851336504. Basic generated-kernel smoke proves
that it can execute reductions and a few admissions; it does **not**
establish accept/reject conformance for untrusted proof terms.

This independent small-corpus lane consumes two fixed GitHub Actions
artifacts, not an unverified cached executable:

1. 79-module kernel source with canonical native-PSKernel-Core-checked
   admissions, checked-source-only receipt from run #37850559156.
2. JavaScript produced by the strict TypeScript 7.0.2 Go compiler,
   declaration/source-map emission and kernel runtime smoke in
   #37851336504.

Every file is bound to the prior checked source and transpiler report by
SHA-256 checks. This experimental candidate is neither a proof of
semantic preservation nor a transferable trusted checking certificate.

## Validation

The GitHub workflow `psc0-generated-kernel-differential.yml` builds the
native PSKernel Core provider and native prelude inventory from current
source, then executes each repository-defined providerCorpus fixture
twice, in separate independent checking implementations:

- native checked admissions through the pinned PSKernel Core provider;
- compiled JavaScript kernel through the separately decoded structured
  canonical wire and checked prelude.

All cases require the reference expected accepted/rejected decision, and
all negative cases must return a genuine kernel rejection, not a provider
crash or resource exhaustion. Both native and generated declaration
failure indices must agree with the fixture when supplied. Positive
coverage includes big naturals, polymorphism, universes, beta/let
conversion, theorems, ordinary, indexed, mutual and nested inductives;
negative coverage includes invalid types, unknown constants, loose
indices, duplicates, invalid universes and applications.

This deliberately replays every generated checker request in a bounded
child process, denying fallback to native if JS fails. The native result
is separately checked and can never substitute for the generated result.

## Acceptance meaning

A GREEN corpus increases independent evidence that generated JS and
native PSKernel Core agree on the exact tested declarations; it does
**not** justify a statement of global kernel soundness, Lean4.34
compatibility, or full joint compiler–kernel fixed point.

The stronger checks still require the generated JS kernel to replay
the actual compiler AND its own kernel admissions stream, with a
same-toolchain checked compiler and kernel source/TS/JS fixed point,
negative full-corpus conformance and explicit trusted-boundary review.

The status fields `generatedCheckerAdmitsCompiler` and
`jointCheckerFixedPoint` remain false by design.

## Current branches

- Parent: `psc0/joint-compiler-kernel-selfhost-v1` (PR #85).
- Independent differential lane: `psc0/generated-kernel-differential-v1`.
- Original TypeScript 7 benchmark: PR #86.

No proof, metatheory, compiler language semantics, or production kernel
source is modified by this test-only lane.
