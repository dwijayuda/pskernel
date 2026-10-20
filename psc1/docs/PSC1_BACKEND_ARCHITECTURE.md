# PSC1 seven-backend continuation — architecture decisions

Date: 2026-10-20. Baseline: ea03ce125ad4d4902070d6fef92d92b51cb2e857.
Branch: feature/psc1-seven-backend-npm-v1. Baseline scoped run 39349606554 passed.
New implementation is a candidate until fresh Linux evidence is recorded.

## Source-backed findings

The active native route is SourceSnapshot -> DirectBackend checkedInput/ordinaryInput
-> official Lean admission -> original-body erasure -> strict IR checking -> target
lowering -> target syntax checks -> ArtifactBundle publication. The default logical
provider is official Lean 4.35.0, not the separately tested PSKernel-Core.

CompilerIr/Model.lean has a useful expression-oriented IR with calls, lambdas,
immutable lets, branches, records, constructors and matches. Its raw wrappers are
public; Specialize.lean correctly rechecks inputs and outputs. The host session
constructor is private. Keep these checks: their role is bounded typing, not proof
of transformation equivalence.

DirectBackend.lean mixes shared admission/ownership with target orchestration.
Its old Rust visibility adjustment is textual. Artifact publication has a fixed
five-target file inventory. Existing npm metadata still describes archived PSC0,
including a TypeScript dependency; that is not a deployable native PSC1 package.
README.md and ARCHITECTURE.md describe historical bootstraps. Preserve history while
replacing their current-state claims.

## Decisions

1. Keep the validated executable IR. Do not redesign the logical kernel or frontend.
2. Add a small backend-common statement plan for Python/PHP. It normalizes operand
   evaluation order and fresh lexical names, keeping branches and matches structured.
   It is not an interpreter, VM, or public control-language extension. Lowering is
   tested, not claimed formally proved. Existing targets keep their qualified paths.
3. Add independent Lean printers for Python and PHP. Neither consumes JS, TS or the
   other target's output. The compiler owns source admission and target plans.
4. Runtime helpers belong to each backend package. Emit only selected helper closure
   into the target bundle. Trivial code does not need a general recursion runtime.
5. Python public ABI starts at the current ECMAScript-like primitive signature
   boundary. Internal generics specialize; records, ADTs and closures stay internal.
6. PHP exposes an explicit case-sensitive export table, not global case-insensitive
   functions. A lexical factory keeps helpers and implementation closures private.
   This also allows loading two generated PHP modules without helper-name collisions.
7. Use Python integer arithmetic and PHP GMP for exact Nat/Int. No float substitution.
   Extension requirements are operation-driven, not a dependency of Bool-only code.
8. General generated calls use a small iterative generator scheduler when required;
   no interpreter recursion-limit changes or semantic runtime fuel. Non-call code
   remains ordinary readable target functions. Broader optimization follows evidence.
9. New source maps are explicit PSC1 declaration-origin maps, not a false claim of
   native Python/PHP sourcemap support. Preserve unmapped helper regions.
10. npm ships a qualified platform native binary, host tools and core source library.
    Optional source libraries remain independently admitted; manifests grant no trust.
    No dynamic native compiler plugins, arbitrary FFI or kernel extension loading.
11. Optional TS+JS output must prepare one source session and publish both direct
    emissions transactionally. TypeScript is a consumer test tool, not the JS emitter.
12. Keep the bootstrap import closure unchanged. New target packages are not claimed
    self-host-qualified merely because official Lean compiles their implementation.

## Research (authoritative, checked 2026-10-20)

- Python 3.15.0 stable release: https://www.python.org/downloads/release/python-3150/
- Python 3.14 semantics: https://docs.python.org/3.14/library/stdtypes.html
  (unbounded integers; bool subtype; immutable/mutable sequences; decimal conversion limits)
- Evaluation/generators: https://docs.python.org/3.14/reference/expressions.html
- PHP support: https://www.php.net/supported-versions.php (8.4 and 8.5 supported)
- PHP integers: https://www.php.net/manual/en/language.types.integer.php
- PHP GMP: https://www.php.net/manual/en/book.gmp.php
- npm metadata: https://docs.npmjs.com/cli/v11/configuring-npm/package-json/

Target policy starts with Python 3.14/3.15 and PHP 8.4/8.5. Exact versions actually
used by CI must be recorded; policy ranges are not execution evidence.

## Scope and rollout

First qualify the shared plan and direct Python/PHP path against current source
capabilities. Then integrate selective helper evidence, dual TS/JS publication,
unpublished npm installation and an actual optional source library. Full Practical
Core language completion is not silently included. New targets must reject foreign
imports, unqualified public aggregates/generics and inactive optional scalars.

Preserved limitations: full v7.2, unrestricted Lean, source IO, behavioral
certification, general WIT ABI, full self-hosting, releases and publication are not
claims of this milestone. Track each real subset separately in AI_WORK_STATE.md.
