# Owned UTF-8 String literals — 2026-10-03

Base: `a28bf13df3c1c1776594296bc93a904a0c0cc092`, branch `psc2/selfhost-lean-kernel`. **No complete owned-checked compiler/kernel pair, joint self-hosting or release has been produced.** Owned `pskernel-core` remains the default and part of portable bootstrap. Native Lean/WASM remain explicit external references only; no fallback follows rejection, unsupported input, failed checks or exhaustion.

## Source-owned primitive fragment

`@proofscript/pskernel-core@0.1.0-checker.13`, profile `owned-utf8-string-literals/10`, adds a fixed intrinsic `String : Type` and validated Unicode-scalar UTF-8 literal typing/conversion. This is an explicitly documented kernel primitive rule, not an ordinary declaration or a reconstruction of the full Lean String logical constructor/ByteArray/proof-field model. See `packages/pskernel-core/PRIMITIVE_POLICY.md`. No general axiom or primitive ingress is added; the inventory's 36 required assumptions were not admitted wholesale.

`BuiltinText.lean` installs only the fixed fresh String name after the existing checked Nat bootstrap. Ordinary constants or records named String cannot authorize literals, and normal declaration admission rejects internal primitive markers. Every production session constructs its own environment. The host decodes strict `{k:"str",v:...}` syntax into generated constructors but does not implement typing, validation or equality.

A generated bounded UTF-8 state machine rejects non-byte naturals, malformed/overlong encodings, stray or truncated continuations, surrogate encodings and values above U+10FFFF. Each byte scan, arbitrary-precision range comparison, lookup and composed typing/conversion step consumes the enclosing budget. Empty and embedded-NUL text are supported. Equality is byte-exact: no Unicode normalization, replacement decoding or terminator truncation occurs. Beta, zeta and transparent delta can expose literals. String operations, Char, general primitive policies, and String constructor/proof-field conversion remain unsupported.

## Executed evidence

The kernel was rebuilt from source with the pinned PSC seed, not patched as semantic TS/JS. Both PSC frontends checked **795 declarations in 24 kernel modules**; canonical PS emission parity, strict TypeScript and independent native Lean checking passed. Portable closure: **79 modules, 55 compiler + 24 kernel**. This is a seed-built kernel, not a newly owned-checked full pair.

Clean Linux kernel suite: **612/612 passed**, 0 failures, 0 skips. Clean Windows host suite: **167 passed, 0 failed, 1 platform skip** out of 168; the POSIX-only baseline is covered by the complete Linux run. Focused text kernel tests: **51/51**. Real frontend and production text boundary tests: **25/25**. Counts overlap and are not additive.

All fourteen oracle/differential suites were regenerated for the final source identity. The text differential matches the explicitly pinned native Lean provider on **112/112 cases: 63 accepts and 49 rejects**. Dependent result-type witnesses force actual literal equality, including combining forms, scalar boundaries, embedded NUL and beta/zeta/delta. Raw validation tests also compare deterministic byte/scalar corpora with an independent fatal UTF-8 decoder. Two pre-existing term completeness gaps remain recorded. Finite evidence is not a soundness theorem.

Actual Lean and ProofScript programs combining String literals, record field access, sum construction and pattern matches were owned-checked, emitted, TypeScript-compiled and executed, producing `λ😀` and `hello`. Malformed host strings, forged metadata, ill-typed/discarded fields, wrong branches, collision attempts and missing String operations reject without output or fallback. Exact exhaustion and fresh-session atomicity tests passed. Source/totality, semantic-boundary, three-root closure, 14 source-isolation and bootstrap-manifest checks passed.

| Identity | SHA-256 |
| --- | --- |
| Source manifest | `92a62e0184f1cc404d27631f8a62f2551973602606f758a96fd8158b292edf82` |
| dist/foundation.js | `6ff1b9ed30c30f4638f123bc8ab8ec6e68ea4c0a6f5a00e06e8ecd5b6279f5b0` |
| dist/foundation.ts | `73dc695fbdf4b452ee58c6d5739114f3a33addbdb4a5adf4e6ca5caeb5e93d74` |
| Fresh source closure | `d3d2af290cdbac506e6d7f59152d6d48f22f771bfb3dd03e0a0bbf6fc7c526b5` |
| Fresh admissions | `9469899a2ac4be5e0d8ff9ad39d63e8f5eb176f01869ce9288dba5e5ea2e3024` |
| Text differential records | `480b0d7a881a0e97356e4fa258e2ae85f87584c35d938985c4b32dd38fc8e51a` |

The seed source is `cc79e84014ed1d49b0c31971e0a8ceb99b32472c`, executable SHA `a0673677219da539df555961129385ae4cf5099f303f0c883dd3a26f726449ff`. TypeScript is exactly 5.8.3; native Lean is 4.34.0 / `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`.

## Exact preserved inputs and blockers

| Input | Observed result |
| --- | --- |
| prefix1 (1 entries) | Accepted; 3327 transitions |
| prefix2 (2 entries) | Accepted; 6903 transitions |
| prefix3 (3 entries) | Accepted; 11549 transitions |
| prefix4 (4 entries) | Rejected: `unknownConstant`, index 3; 11779 transitions |
| PsTokenKind-alone (1 entries) | Accepted; 11159 transitions |
| PsToken-with-records-and-kind (5 entries) | Accepted; 29186 transitions |
| PsLexError-with-records (4 entries) | Accepted; 25368 transitions |
| preserved75-full (1556 entries) | Rejected: `unsupported-inductive-family`, index 80 |
| current79-full (1615 entries) | Rejected: `unsupported-inductive-family`, index 80 |

The new five-entry slice `[0,1,2,14,16]` now admits the exact preserved `PsToken` record with its String field and dependencies. The original full 75-module input is unchanged. The fresh 79-module batch contains 1615 admissions. Both full inputs pass String decoding and reject the parameterized `PsParseResult` family at index 80. **Decoder progress is not semantic-prefix acceptance**: the full batch decodes before replay; independently, `PsLexCursor` still rejects missing List/Char dependencies at index 3.

The full inventory has 1916 compiler, 795 kernel and 81 prelude declarations, with 55 required prelude declarations and 36 recorded assumptions. Complete type/body/dependency data are preserved. Next work requires validated parameterized and recursive families, the missing checked prelude, explicit primitive behavior and nested recursor handling. Full owned admission must precede emission/rebuilding of the next checked pair and its fixed-point claim.

## Recovery and retained failures

Source and evidence are built in a new isolated candidate; previous source/evidence and original replay directories were not modified. An initial Linux package run and an initial Windows host run each found an older String-absence assertion. The original inputs remain as positive regressions now that String is intrinsic; independent missing-prelude and no-leak checks remain negative. The later clean runs supersede those attempts without rewriting their logs. One guard invocation failed due to shell quoting; another correctly rejected stale evidence while regeneration was unfinished. Final guards ran only after regeneration completed.

The accompanying receipt records compressed/uncompressed identities for source snapshots, full admissions, declaration/dependency inventory, integrated prepared partition, exact probes and command logs. Rebuild only in isolation because the build replaces dist and invalidates evidence. Public authority, release and owned-pair flags stay false. This document does not claim CI success.

Semantic commit: `25aafa3e0d831d35f1e25ab8fc0f90ebef6471d3`. The accompanying `owned-text-literals-2026-10-03/receipt.json` binds the exact 79-source snapshot, full input and dependency inventory. Post-integration tests and preserved input probes passed their stated gates; no complete owned-checked pair is claimed. Both compressed and raw archive bytes are hashed and verified.
