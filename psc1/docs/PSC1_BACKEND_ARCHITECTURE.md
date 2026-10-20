# PSC1 seven-backend architecture decisions

Audit baseline: `ea03ce125ad4d4902070d6fef92d92b51cb2e857`, 2026-10-20.
Implementation work is stacked on Practical Core PR #163; repair PR #162 stays intact.

## Source-backed findings

| Finding | Evidence at baseline | Classification and response |
| --- | --- | --- |
| Current architecture still describes PSC2/psc15selfhost and future kernel integration | `ARCHITECTURE.md` heading, admission section; `README.md` | Stale current documentation. Preserve original under history; document the actual native path. |
| Launcher and distribution packer disagree | `npm-cli/psc.js` requires the native compiler; `scripts/npm-distribution.mjs` packages archived generated JS | Installability defect. Build an unpublished native Linux package and test an installed consumer. |
| npm library resolver is disconnected from captured native imports | `npm-cli/libraries.mjs`; `host/src/Ps/Host/ProjectCompiler.lean::psHostResolveImport` | Missing capability. Resolve declared source modules with importer context and independently admit the captured closure. |
| Visibility depends on modifying printed source | `DirectBackend.lean::withoutExport`, `rustVisibility` | Architectural liability. Make public selection an input to printers, then check actual target output. |
| Target selection, ABI rules and publication inventories are spread across host and CLI code | `DirectBackend.lean`, `Main.lean`, `artifacts.mjs::publish` | Small common target plan and explicit output descriptors; keep target-specific validation separate. |
| ECMAScript/Rust prelude support is broadly emitted | `BackendTs.Module::psTsRuntimeSupport`, `BackendJs.Print::psJsPrintStackSafePrelude`, Rust runtime | Output-size liability, not logical unsoundness. New backends select helper closure; existing selective linking is changed only with real execution regressions. |
| Practical Core does not yet cover all fourteen families | `docs/PSC1_PRACTICAL_CORE_STATUS.json` | Deliberate scope boundary. Adding a backend is not permission for a language rewrite. |

## Decisions

**One admitted closure, multiple direct targets.** Keep canonical Core, independent
official Lean admission, exact ordinary runtime pairing and checked IR in Lean. No
target-language frontend, IR JSON publication endpoint or metadata trust shortcut.

**Small shared planning.** `Ps.BackendCommon.Plan` contains target identity,
public ABI checks and the existing closed specialization/revalidation operation.
It is not a plugin framework. Target capability checks remain conjunctive with full
IR validation and real target compiler/parser validation.

**Expression IR remains sufficient for the present slice.** Existing do sequencing is
already represented by typed lets, calls, branches and tagged data. Adding a control-flow
IR now would duplicate a working pipeline without supplying missing source semantics.
A future change must be justified by actual mutation/return/loop lowering requirements.

**Backend-owned readable helpers.** Python integers implement exact Nat/Int values;
saturating subtraction and zero-divisor rules need explicit semantics. PHP uses GMP
only when arbitrary-precision numeric values are required. Calls use a small explicit
generator scheduler where needed for deep recursion, without semantic fuel. A scheduler
runs generated target functions; it does not interpret Core or IR.

**Public ABI stays explicit.** JS/TS and the initial Python/PHP slice expose scalar
functions/values. Aggregates can be internal. Rust keeps its existing qualified generic
path. Component exports remain Bool-only. No machine/float or Int division/modulo
capability is inferred from a type constructor or host-language feature.

**Self-contained installation and output are separate.** The main npm toolchain carries
all built-in emitters in one native executable and its required host tooling. It does
not install every target runtime. Generated artifacts include or declare only selected
runtime dependencies. The source-library resolver never executes an npm hook during
logical checking.

**Evidence is staged.** Parsed, elaborated, admitted, lowered, target-validated, executed
and formally behavior-certified are distinct claims. Only the exact CI commit receives
qualification. Verified requests continue to refuse without fallback.

## Authoritative references consulted

- [Lean 4.35.0 implementation](https://github.com/leanprover/lean4/tree/eb6cafb7290e8bd5f2937522d8d804f58f02bafc):
  `src/Init/Data/Nat/Div/Basic.lean`, `src/Init/Data/Int/DivMod/Basic.lean`,
  runtime string and array primitives.
- [Python releases](https://www.python.org/downloads/) and
  [Python expression semantics](https://docs.python.org/3/reference/expressions.html).
- [PHP releases](https://www.php.net/releases/) and
  [GMP functions](https://www.php.net/manual/en/ref.gmp.php).
- [ECMAScript BigInt](https://tc39.es/ecma262/#sec-ecmascript-language-types-bigint-type)
  and [source map specification](https://tc39.es/source-map-spec/).
- [WebAssembly Core types](https://webassembly.github.io/spec/core/syntax/types.html)
  and [WIT reference](https://component-model.bytecodealliance.org/design/wit.html).
- [npm package metadata](https://docs.npmjs.com/cli/v11/configuring-npm/package-json)
  and [npm pack](https://docs.npmjs.com/cli/v11/commands/npm-pack).

Python 3.15.0 is the current stable release observed on 2026-10-20; Python 3.14 remains
a supported line. PHP's stable series is 8.5. Minimum requirements and exact versions
actually tested are recorded in the conformance receipt, not inferred from this survey.

## Implemented runtime selection

Native JS/TS printing now receives public visibility as structured input. The direct TS
printer emits call-free expressions without a generator wrapper. UTF-8 and stack helper
groups are selected from target IR. Rust uses an explicit helper catalogue with dependency
metadata, and Cargo dependencies follow the native plan. Wasm selects the transitive helper
call closure from lowered instructions while retaining user functions and closure references.

Every native target describes its runtime under `psc1-runtime-semantics/1`. Source target
hashes cover the canonical selected helper text before deterministic formatting. Wasm hashes
cover `psc-wasm-ir-json/1:functions`, the selected lowered helper instruction definitions.
The final artifact bytes have independent hashes in the same bundle. Runtime-free Boolean
JS/TS/Rust/core-Wasm examples and the existing target suite passed at
`5bf41561ca5031d4ecca61c614ea0ad4bfcf5908`,
[run 39361050286](https://github.com/dwijayuda/pskernel/actions/runs/39361050286).

A pinned native Lean oracle is used for numeric/Unicode/value-semantics comparisons. The
source-level Boolean equality operator remains limited to Nat and Bool. String observations
in the conformance fixture therefore use admitted length, byte-position and Char operations;
no String equality syntax is introduced to make the test pass.

## Integrated qualification

Both new emitters, native npm installation and the real optional-library consumer passed
at `1f59f46bca18e5eb2d8a6bc9670e6f632202af66`,
[run 39366310670](https://github.com/dwijayuda/pskernel/actions/runs/39366310670).
Python forward values and PHP lexical helper selection have direct-IR execution regressions.
The runtime oracle executed all seven targets in both source grammars. See the
[conformance record](PSC1_BACKEND_CONFORMANCE.md) for exact scope, interpreter versions,
artifact hashes and the policy for later heads.
