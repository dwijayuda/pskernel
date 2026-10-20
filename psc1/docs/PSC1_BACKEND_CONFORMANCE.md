# PSC1 backend conformance

## Recorded successful implementation checkpoint

All seven direct targets passed the focused Linux suite at branch head
`1f59f46bca18e5eb2d8a6bc9670e6f632202af66`, [run 39366310670](https://github.com/dwijayuda/pskernel/actions/runs/39366310670).
GitHub tested merge commit `951afe99a0c876cfc87b3bb6f192b6688b33b3e9` against the preserved PR #163
base. The [machine-readable checkpoint](PSC1_SEVEN_BACKENDS_QUALIFICATION_2026-10-20.json)
records the exact identities, package hashes and artifact.

This is an observed checkpoint. A later source head needs its own successful check;
qualification is not inherited just because the branch name is unchanged. Each
current workflow additionally emits `SEVEN_BACKEND_QUALIFICATION.json` with the
tested commit, branch head, actual runtime versions, helper hashes, sizes and npm
receipts. Use the corresponding PR check and artifact for the latest exact head.

## Executed target matrix

The native Lean oracle supplies reference observations. Both supported source
grammars are compiled independently, then actual consumers execute every result.

| Target | Main runtime/tool qualification | Source corpus at the recorded checkpoint |
| --- | --- | --- |
| JavaScript | Node 22.23.3 | Both grammars, direct emitted JS |
| TypeScript | TypeScript 7.0.2 independent consumer, Node 22.23.3 | Both grammars, direct emitted TS |
| Rust | Rust/Cargo 1.90.0, exact selected numeric dependencies | Both grammars, real Cargo build and execution |
| Core Wasm | wasm-tools 1.254.0 and Node Wasm execution | Both grammars, validated binary and real instance |
| Component Wasm | wasm-tools 1.254.0 and Wasmtime 49.0.4 | Both grammars, Bool-only public interface with internal scalar checks |
| Python | CPython 3.15.0; minimum 3.14.8 compatibility checks | Both grammars, real import/calls; source, stub and origins |
| PHP | PHP 8.5.11 with selected GMP support | Both grammars, real require/calls; helper-free cases also execute with `php -n` |

The current workflow also runs the full Python scripting and reference corpus on
the minimum Python line in separate evidence directories. Consult that head's
`SEVEN_BACKEND_QUALIFICATION.json` for the observed result; the immutable checkpoint
above initially used minimum-version constant/scalar ABI compatibility checks.

The corpus covers exact large Nat arithmetic, saturating subtraction, natural
zero-divisor behavior, Int arithmetic/representation, Unicode scalars and raw UTF-8
positions, persistent arrays, closure capture and internal products. It produced
**14 executed target/source bundles** at the recorded checkpoint.

The source equality syntax remains the admitted Nat/Bool slice. String and Int
results are observed through accepted operations rather than adding unsupported
equality syntax to a fixture.

## Additional executed coverage

| Group | Evidence at the recorded checkpoint |
| --- | --- |
| New scripting artifacts | 22 retained Python/PHP groups covering constants, public ABI, huge literals/decimal strings, private generics, empty entry, symbol identity, imported ordinary declarations, non-tail recursion, ordinary recursion and divergence |
| Scripting failure boundaries | Four additional groups for prior-generation preservation and negative source/capability refusal |
| Direct scripting IR | Ten boundary groups, plus actual compound-closure, forward-value and runtime-free shadowing consumers |
| Shared planning and combined TS/JS | Five groups covering independent consumers, runtime-free Rust/Wasm, atomic pair publication, repeatability and invalid requests |
| npm metadata transport | Ten groups including nested installed versions, private modules, source containment, identity and profile |
| Existing focused backend suite | 24 passed groups |
| Existing Practical Core forms | 36 real executed artifacts |
| Existing admission/IR/kernel suites | Focused native tests retained and passed; the owned kernel is compiled/tested separately from the authoritative Lean provider |

The scripting suite executes **100,000-step non-tail recursion** and explicit
ordinary recursion. Deliberate divergence is checked with an external timeout.
PHP receives a 1 GiB test memory allowance for suspended heap frames; no compiler
budget or generated execution fuel is increased.

A **5,001-digit** input literal and decimal result execute exactly. Python runs
with `int_max_str_digits=640` and the test confirms the process-global setting
is unchanged. Wrong host scalar types, Bool-as-integer inputs, negative Nat,
invalid Unicode and bad arity are rejected.

Public export checks cover actual module keys, TypeScript declarations, Python
`__all__`/`.pyi`, PHP map keys and source ownership. Python/PHP origins honestly
declare `declaration-starts-only`; JS/TS maps refer to captured text and final output.

## Native npm and optional source package evidence

The private `proofscript@0.1.0-psc1.2` tarball passed local and global offline
installation with an initially empty cache, native/npm identity agreement,
installed direct-native build and generated JS execution without TypeScript
installed in the package.

At this checkpoint the native executable is **123,037,384 bytes**
and the installable tarball is **37,342,712 bytes**.
No non-system Lean shared library was required by the observed binary. These are
measured artifacts, not a cross-platform size or compatibility guarantee.
The qualified package environment is Linux x64 with glibc 2.39 and Node >=22.

The source-library canary installs two unpublished local npm tarballs. Its public
module imports a second package and its own private source module. Native checking
admits **four source files**, generated JS exports only `answer`, and execution
returns **42**. Private-module access, an incompatible Lean pin and an ill-typed
transitive source fail without replacing the earlier output. Metadata itself is
never treated as proof evidence.

## Artifact and reproduction

[Download the recorded checkpoint artifact](https://github.com/dwijayuda/pskernel/actions/runs/39366310670/artifacts/12239956282).
It contains readable generated bundles, exact source/admission inventories, origin
files, target plans, test receipts and installable npm tarballs. GitHub retention
for this artifact ends **2026-11-03**; a later successful run supplies its own artifact.

The focused workflow is `.github/workflows/psc1-scoped-correctness.yml`. It pins
Lean, Rust and Wasm tools, installs locked host dependencies, and explicitly invokes
the native regressions and each target consumer. Its consolidated receipt distinguishes
the branch head from GitHub's checked-out merge commit.

From `psc1` in the same qualified environment, the new primary commands are:

```sh
node scripts/backend-architecture-tests.mjs
node scripts/runtime-conformance-tests.mjs
node scripts/script-backend-tests.mjs
node scripts/npm-library-resolution-tests.mjs
node scripts/npm-native-distribution.mjs
```

The workflow supplies required consumer tools and environment variables. These
commands do not replace the earlier native admission and owned-kernel gates.

## Explicit remaining limits

The retained source subset and qualified Practical Core slice are supported; all
fourteen families are not complete. No unrestricted Lean claim is made. Int
division/modulo and fixed-width/floating runtime scalars remain outside the active
qualified profile. Python/PHP public compound ABIs and non-Bool component exports
are refused.

Python/PHP nullary declarations are pure thunks and can repeat computation. PHP
tail calls currently retain heap frames. Python/PHP origins are declaration-level
metadata, not full debugger maps. Optional library manifests/lockfiles are not
yet included in general package-version provenance. The initial native npm package
is Linux x64/glibc only.

Logical admission remains official Lean 4.35.0 at
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`. Exact ordinary logical/runtime pairing
and strict IR checks remain in place. `--assurance verified` refuses without a
behavioral certificate. No formal backend preservation, full self-host/census/
fixed-point qualification, merge, release or npm publication is claimed.

The preserved five-target Practical Core checkpoint is
`ea03ce125ad4d4902070d6fef92d92b51cb2e857`,
[run 39349606554](https://github.com/dwijayuda/pskernel/actions/runs/39349606554).
Its evidence remains in `PSC1_PRACTICAL_CORE_SLICE_1_QUALIFICATION.json`.
