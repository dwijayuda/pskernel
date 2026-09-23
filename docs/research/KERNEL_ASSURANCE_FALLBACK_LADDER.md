# Kernel assurance fallback ladder

Status: active fallback policy for `kernel/lean434-study-hardening`.

## Why this exists

The preferred completion route is still:

```text
canonical Full Std
-> first real semantic failure
-> smallest Lean-4.34-faithful fix + regression
-> resume
-> canonical Full Lean
-> freeze behavioral matrix
-> formal equivalence
```

That route is valuable because one shared environment in canonical declaration
order exercises interactions that independent dependency closures can miss.

However, infrastructure cost must not become the project. If the exhaustive
route is blocked by runner availability, memory, wall-clock limits, or
prohibitively slow diagnosis, use the cheapest lower tier that still answers
the current question.

A lower tier may guide fixes and provide strong evidence, but it **never closes
a higher-tier gate**.

## Tier 0 — direct trusted-kernel regressions

Purpose: fastest semantic edit loop.

Use:

```text
npm test
npm run oracle:adversarial
npm run oracle:defeq
```

This is the right loop after a concrete kernel bug has already been isolated.

Exit signal: the new regression fails before the patch and passes after it,
without weakening an existing test.

## Tier 1 — bounded real corpora

Purpose: broad, repeatable evidence at manageable cost.

Use the existing:

- Init.Prelude corpus;
- Std.Internal.Parsec.Basic;
- Std.Sat.CNF.Basic;
- Std.Data.ByteSlice;
- Lean.Data.RBMap bounded roots;
- Lean.Data.PersistentArray;
- Lean.Data.PersistentHashMap.

Command:

```text
npm run check:corpus
```

These are much stronger than synthetic tests because they replay real exported
Lean declarations through the production importer and kernel.

They do not prove exhaustive Std/Lean compatibility.

## Tier 2 — cheap Std probes

Purpose: answer "did a recent kernel change break known difficult Std areas?"
without attempting all 114,029 direct roots.

### First-range smoke

```text
npm run oracle:std-probe
```

Default scope:

- Std environment constant count pinned at 114,029;
- first 250 direct roots;
- base chunk 100;
- minimum adaptive leaf 10.

### Known-hot roots

```text
npm run oracle:std-hot
```

This checks the historically troublesome small intervals around:

- 16,484
- 18,843
- 20,000
- 22,640
- 25,000
- 27,515
- 33,015
- 36,452
- 37,609

The hot probe defaults to a 2 GiB worker heap and one-root minimum adaptive
split. It is intentionally cheap enough to run before an expensive sweep.

## Tier 3 — targeted adaptive Std range

Purpose: isolate a failing direct-root interval.

General form:

```text
npm run oracle:std-range -- <start> <count> <baseChunk> <minChunk>
```

Example:

```text
npm run oracle:std-range -- 36000 1000 250 10
```

The adaptive runner:

1. exports a dependency-closed root range from official Lean 4.34;
2. replays it through production pskernel;
3. splits automatically on timeout/OOM;
4. reports the smallest failing leaf it can reach.

This is the default diagnostic replacement for repeatedly launching the whole
canonical stream.

## Tier 4 — exhaustive dependency-root coverage

Purpose: cover every direct Std root when canonical one-pass streaming is too
expensive for the available machine.

The existing adaptive/batch tooling can partition all 114,029 direct roots
into bounded intervals, each exported with its dependency closure.

This is strong behavioral evidence because every direct root is exercised, but
it is **not identical to canonical shared-environment replay**. It may miss bugs
that depend on declaration-history interactions, cache state, or admission
order across otherwise independent closures.

Allowed claim after this tier:

> all Std direct roots replay successfully through dependency-closed batches.

Disallowed claim:

> canonical Full Std passes.

## Tier 5 — canonical Full Std

Gold behavioral gate:

```text
npm run oracle:std-full
```

Properties:

- final Lean 4.34 exporter;
- canonical module/declaration order;
- one shared pskernel environment;
- replay-local intern tables discarded between shards;
- every admitted declaration contributes to the environment seen by later
  declarations.

Only this tier closes `full-Std-environment-replay`.

## Tier 6 — Full Lean environment

Do not start here while Full Std still has unexplained failures.

If resource limits make a canonical whole-Lean stream impractical, use the same
fallback sequence:

1. bounded real Lean modules;
2. known-hot module/range probes;
3. adaptive dependency-root ranges;
4. exhaustive dependency-root coverage;
5. canonical full environment when infrastructure permits.

Again, lower tiers supply evidence but cannot silently close the canonical
gate.

## Cost-based stop rules

Switch downward temporarily instead of repeatedly paying for a higher tier
when any of these happens:

1. **runner unavailable** — job receives no runner / executes zero steps;
2. **same OOM twice** without reaching a semantic declaration failure;
3. **same timeout twice** without meaningful forward progress;
4. **diagnosis cost dominates implementation cost** — the full sweep only says
   "failed" while a range probe can identify the first bad declaration much
   faster;
5. **environment cost is external** — CI quota/billing/runner restrictions are
   blocking execution rather than the kernel.

Once a concrete semantic failure is isolated, return to Tier 0/1 for the edit
loop. Re-run the higher gate only after the focused regression is green.

## What happened on 2026-09-23

Two branch-triggered GitHub Actions attempts were made:

- canonical Full Std;
- fast TypeScript kernel CI.

Both completed as failures with no executed steps and no allocated runner
(`runner_id = 0`). Therefore they provide **zero semantic evidence** about the
kernel.

The branch should not keep triggering failing Actions runs merely to reconfirm
an external execution problem. Local/alternate-runner diagnostic commands are
the preferred path until Actions can allocate a runner again.

## Cheaper alternatives for formal equivalence

Formal equivalence is the most expensive stage. Use this descending-cost
strategy before attempting a proof about arbitrary JavaScript execution.

### A. Formal semantic model + algorithm proofs

Specify the Lean-4.34-target kernel in Lean and prove:

- level operations;
- substitution/lifting;
- inference;
- WHNF/reduction;
- definitional equality;
- quotient rules;
- inductive admission/recursors;
- environment extension.

This is the preferred formal target.

### B. Translation-validation / proof-producing boundary

Instead of proving all TypeScript semantics, have pskernel emit a compact
certificate or trace that a small verified checker/model validates.

This can shrink the trusted TypeScript surface substantially.

### C. Generated implementation from a formal source

If maintaining a hand-written TS/formal correspondence becomes too expensive,
make a formally specified algorithm the source of truth and generate or
mechanically mirror the executable implementation.

### D. Differential + exhaustive behavioral assurance

If full implementation correspondence remains too costly, keep:

- canonical corpus replay;
- official differential tests;
- adversarial regressions;
- frozen Lean-4.34 source/version pins;
- deterministic acceptance matrix.

This is not a formal-equivalence claim, but it is a defensible production
assurance model.

## Claim discipline

Use the strongest claim supported by the highest completed tier.

Examples:

- Tier 2 green: "known difficult Std probes pass."
- Tier 4 green: "all direct Std roots pass dependency-closed replay."
- Tier 5 green: "canonical Full Std replay passes."
- Full Std + Full Lean green: "exhaustive targeted release environments replay
  successfully."
- Formal semantic proof: state exactly which relation/theorems were proven.
- Never collapse behavioral conformance into formal equivalence.

## Current preferred next action

Because GitHub Actions currently does not allocate a runner:

1. run `oracle:std-hot` or `oracle:std-probe` on any machine with the pinned
   Lean 4.34 toolchain;
2. if one fails, use `oracle:std-range` to isolate the minimal root interval;
3. patch only the demonstrated 4.34 parity gap;
4. keep canonical Full Std open;
5. resume canonical replay when a suitable runner is available.
