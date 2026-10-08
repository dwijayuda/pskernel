# PSC1 Lean Kernel Maturity Parity

This file defines what "as mature as the TypeScript Lean kernel" means for the
Lean-authored PSC1 reference kernel. It is an engineering acceptance target,
not a claim of formal equivalence to Lean 4.34.

## Required parity gates

1. **Semantic feature baseline**
   - K2 WHNF/inference/resource baseline complete.
   - K3 definitional-equality ordering matches final Lean 4.34 on direct
     differential cases.
   - K5 ordinary, mutual, indexed, functional and nested inductive admission
     baseline complete.
   - Quotient, projection, recursor, proof-irrelevance, eta, literal and native
     marker semantics are covered by direct regressions.

2. **Host-policy injection**
   - maxRecDepth and maxNatSize are explicit portable checker configuration.
   - Native evaluation is optional, fail-closed, injectable through direct
     declaration admission, inductive admission and replay.
   - Replay may consume a host-produced native-result map without linking the
     semantic kernel to Lean compiler internals.

3. **Replay assurance at least equal to the TS release profile**
   - canonical Init.Prelude,
   - K8 primitive closure,
   - ProofScript text/self-host deltas,
   - SAT/CNF, Parsec, ByteSlice, RBMap, PersistentArray and PersistentHashMap,
   - the same 114,029-constant Std release profile used by the TS lane:
     exhaustive roots 22197..23153 (957 roots) plus 64-root windows at
     0, 10000, ..., 110000.

4. **Adversarial fail-closed behavior**
   - malformed replay indices/metadata,
   - declaration collisions,
   - invalid universe/inductive metadata,
   - reserved nested names,
   - resource-boundary regressions,
   - unsupported host/native results fail closed.

5. **Runtime maturity**
   - Release-profile replay must complete reliably under bounded CI resources.
   - Performance work must preserve the semantic oracle. Lean-style caches may
     be introduced only with regression coverage for cache scope, structural
     keys, recursion accounting and lazy-delta ordering.
   - Prefer non-semantic execution improvements first (for example compiling
     the replay driver once) before changing the portable checker architecture.

## Current state

- K2 semantic baseline: **complete**.
- K5 semantic baseline: **complete**.
- K7 canonical replay protocol: **complete**, with host checker configuration
  now carried by replay state.
- K8 bounded semantic acceptance: **complete**.
- Native evaluator injection: **implemented** for checker/admission/replay;
  portable native map support is gated in CI.
- Std release-profile parity: **active on**
  `assurance/psc1-lean-std-release`.
- K3 semantic baseline: **complete** for the bounded final-Lean-4.34 ordering
  covered by direct differential regressions. Lean-style mutable success/failure
  cache parity remains a runtime-maturity/performance item rather than a missing
  semantic rule.
- Full Std environment replay, full Lean environment replay, native compiler-IR
  provider parity, and formal equivalence remain outside the completed claim.

## Claim discipline

Do not claim full Lean 4.34 compatibility, full environment equivalence, formal
kernel equivalence, or 100% completion from these gates. A parity claim here
means the Lean-authored kernel has matched the TS implementation's documented
bounded semantic and release-assurance evidence, with remaining differences
explicitly listed above.
