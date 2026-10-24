# T05 complete ordinary DAG admission — preflight checkpoint, 2026-10-25

## Status and branch ownership

The complete ordinary path is implemented in draft history. Full native/generated/canonical qualification remains pending. Integration stays at the qualified constructor source **a49d64ae494d51fdc80b688dab0922dd96403e5e**. That source passed full310 in [run40137117745](https://github.com/dwijayuda/pskernel/actions/runs/40137117745) and actual archive audit [40137395586](https://github.com/dwijayuda/pskernel/actions/runs/40137395586).

The private draft branch is **work/psc1-pskernel-t05-admission-draft-20261025**, source **09f1cad35bda9768fc15151915d88b6f3fe3be6c**. Its production ancestor **db7b9161e92c1654801f55b883cf667de2d82372** contains the three new recursor/admission modules. The public draft branch is **work/psc1-pskernel-t05-public-draft-20261025**, source **a049816b12e7f1ba82ac347158c099c18300a289**. The generated-public harness has a subsequent prepared commit **4276a684d31bc1de520adcfbb7dc00dd41a4cfd4**, correcting the exact curried structural-equality ABI. Its production and native proofs/tests are unchanged; this harness change still requires its own complete-source generated evidence.

## Actual preflight evidence

| Source | Actions run | Verified result |
| --- | --- | --- |
|6f79308b3ee3971b4e17e5803addb5196148b2bb|[40139635555](https://github.com/dwijayuda/pskernel/actions/runs/40139635555)|Elimination26 exact native reports and116 unique assertions; authentic PSC1 leaf check1632 declarations.|
|db7b9161e92c1654801f55b883cf667de2d82372|[40141120502](https://github.com/dwijayuda/pskernel/actions/runs/40141120502)|Private production compiles in pinned Lean4.35; authentic PSC1 leaf check1860 declarations.|
|09f1cad35bda9768fc15151915d88b6f3fe3be6c|[40142024947](https://github.com/dwijayuda/pskernel/actions/runs/40142024947)|27 exact native proof reports,143 unique shared assertions,18 separate official controls. Native job121015571587, attempt1.|
|a049816b12e7f1ba82ac347158c099c18300a289|[40141659022](https://github.com/dwijayuda/pskernel/actions/runs/40141659022)|8 exact public protocol reports and12 unique runtime controls. Native job121014491653, attempt1.|

The actual completed logs and source/run/attempt receipts were inspected. All these receipts explicitly remain diagnostic and unqualified. For09f1cad3, proof source SHA256 is f3c7c3de91616ba2b9e0fdeab3a9fbb2fafcb78e74e9d873fd3105763f529e47 and proof log SHA256 is30e1a952f0e4c9b29d06144056b73c8b4bd24e9c2bbed026b5491b4284d687e3.

## Implemented semantics

The qualified header and constructor workers remain prerequisites. Ordinary admission preserves their original binder syntax, checking order, fuel, local names, original constructor type roots and error precedence.

**DagOrdinaryGenerated.lean** incrementally extends a known-correct decoded prefix over newly appended canonical nodes. It decodes checked header parameters, indices, constructor fields and recursive positions into the existing pure recursor generators. Original constructor metadata reads the separate validated input table. Pure syntax generation is not a checking certificate.

**DagOrdinaryRecursorValidation.lean** checks each internally generated rule RHS before constructing/importing its expected closed type. DefEq compares the independently inferred type against that expected type. Every rule gets the same supplied fuel. Import retains the complete checked semantic owner, and the next rule gets the complete DefEq owner. No rule metadata supplied by an external caller is authoritative.

**DagOrdinaryAdmission.lean** stages the provisional datatype and constructors, calculates final recursion/reflexivity flags, applies the elimination policy, constructs the recursor plan including implicit binders and K metadata, then starts a fresh recursor-type checker. Check must be followed by mandatory Sort. The independent rule phase resets semantic caches, locals and freshness, retaining the appended arena and the established parent references plus the generated recursor reference. Callback-mutated type-phase references do not become the new rule owner. After the last DefEq, final suffix synchronization is mandatory before the sole successful environment/owner result.

**API/Dag.lean** adds an owned-command result for batch execution. Ordinary success carries its synchronized checked owner directly; it does not re-import generated ordinary metadata. The resource gate, evaluator clearing and receipt creation match existing declaration publication. A declined private worker restarts the complete original command using the original session, arena, table and request. Hard errors return no partial owner or environment. Nonordinary commands keep their existing path. The old single-command ABI remains available; production batches use the new owned worker and the existing suffix demand importer. The fixed original input table continues to bound every external command/declaration ID. A later command failure returns no successful batch.

## Exact new inventories

The intended complete native inventory is **371 = retained310 + elimination26 + private27 + public8**. No prior source's proof reports may satisfy this source's inventory.

- Elimination:116 runtime assertions, groups harness1/policy63/raw28/member12/protocol12.
- Private admission:143 shared assertions, groups harness1/matrix126/protocol16. The matrix has18 rows at fuels0,1,2,3,8,4096 plus required outcomes:14positive and4negative. It compares complete environments, recursor types/rules/flags, original prefixes, generated owners, and late error/decline behavior against frozen V1 admission.
- Official native controls:18, with14accepted/4rejected.13safe positives independently validate generated recursor types and RHS terms in pinned Lean;1unsafe positive is explicitly a contract control. It is not evidence that Lean validates unsafe bodies.
- Public handoff:12 assertions, groups harness1/routing7/boundary4. They cover direct owner retention, preserved appended syntax, original-state fallback, hard rejection, declaration limits, same-batch and cross-call recursor checking, generated-ID rejection, late batch failure, fallback input bounds and preflight precedence.

The private27 proof reports cover rule order, same fuel, full owners, fresh phase resets, established references, mandatory Sort, original input guards and final synchronization. The public8 reports cover the preflight/resource/publication boundary and complete-original fallback. These equations do not prove an arbitrary injected checker sound.

## Remaining qualification

Merge the completed private and public draft histories into the authorized work branch with history preserved, including the generated-private harness and the expanded full native-first workflow. Require the exact source to pass all371 reports, retained negative tests, all runtime suites, both complete generated routes, canonical reconstruction manifests and source closure checks. Then extend/run the artifact-only auditor against that exact source/run/attempt and inspect its archive contents and receipts before updating integration.

The full routes are TypeScript→JavaScript and canonical .ps→TypeScript→JavaScript. Retained bounded DirectJS checks have their own scope. Preserve Lean4.35 commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc, TypeScript7.0.2, Node22, fuel4096 where applicable, detached emptyPATH execution, 2048MiB old-space policy, and existing job/runtime limits. Do not describe the old-space setting as a hard RSS cap.

## Trust boundaries and separate obligations

The public untrusted boundary still replays and validates the source arena, then constructs the original decoded table. Internal helpers require canonical arena/decoded-prefix correspondence and correctly derived declaration references. Size guards alone do not establish those premises for forgeable records. Existing trusted low-level session construction remains explicitly trusted.

The general replay-to-ArenaModel and external decoder/layout proof bridges remain open. Full ordinary admission qualification does not prove full kernel soundness or performance. A/T01F remains scoped-qualified; B/broader completion is OPEN; C/full Arena remains FAIL at historical173/193 strict matches (17timeouts,1budget exhaustion,2separate unsafe/partial contract agreements); D/performance remains OPEN for Church and Init.Prelude.

## Continuation

Recover both live heads and newest run/artifact receipts. Do not duplicate a valid matching-source run. Resolve any preflight or full-route failure with focused repairs, preserve theorem statements and negative controls, and requalify changed source. Once all actual artifacts pass the exact-source audit, record the evidence and fast-forward integration non-force with an expected-SHA guard. Continue toward the highest-value remaining implementation/performance blocker; do not declare the separate open obligations complete without new exact-source evidence.
