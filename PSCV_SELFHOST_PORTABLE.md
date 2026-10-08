# PSCV Self-Host Portable — Evidence-Audited Language Profile and Four-Backend Bootstrap

**Edition:** Research and architecture revision V3, 2026-10-08  
**Proposed source profile:** `PSCV-selfhost-portable/2` — *not yet formally adopted or implemented*  
**Destination:** `dwijayuda/pskernel/PSCV_SELFHOST_PORTABLE.md` on `main`  
**Source of truth for current execution state:** `pscv/v3-execution`, inspected commit `93add6da4e501c57f9016c7c3666ea52c87a66e7`  
**Lean semantic reference:** `4.35.0-rc3` / `470d5ce1400764999581fd26d5d72b00d990b0f4`; existing bootstrap `4.34.0` / `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`  
**Status:** design research with source-backed decisions and falsifiable implementation gates, **not** a proof of compiler correctness, backend self-host closure, measured AI proof speed, or a PSCV verified executable.  
**Audit state:** **97/100 source-backed documentation/design completeness (self-audited 100-item rubric)**, three unearned evidence points; **not** an empirical correctness, proof speed or four-target certification claim.  

> **Authority and truth rule:** the [PSCV normative language reference][EV-NORM] and [V5.1 compiler design][EV-V51] control grammar, logic, runtime behavior, trust and existing compiler boundaries. This *source implementation profile* is a narrower subset, not a replacement specification. "Verified by Lean" is not "PSCV-CERT-v1", "validated IR" is not certified source, "fixed point" is not compiler-preservation evidence, and no untested source or runtime representation gains authority from this document.

## 0. Executive architecture decision

Use **one authoritative readable `.ps` compiler source tree** with two implementations that eventually produce compatible checked semantic products:

1. **Lean-hosted development frontend**: parse only PSCV-approved syntax, lower to pinned Lean syntax and typed Core, use Lean elaboration, kernel proof checking, termination checking, and proof-producing tactics; export supported executable meaning through a checked and validated *Lean-Core-to-PSCV-RuntimeIR* adapter.
2. **Native PSCV frontend**: parse, resolve, elaborate, check using the established kernel-provider contract and PSKernel independently when ready, and produce its own certified/validated runtime artifacts.
3. **Common four backends**: TypeScript, direct JavaScript, direct Wasm and Rust consume target-neutral runtime semantics, not backend-specific source semantics.
4. **Preserved bootstrap**: `PSC1-selfhost-stable/1` remains a stable seed and rollback oracle. New source-code capabilities are staged separately and do not rewrite the existing seed in place.
5. **Proof-first *language design*, implementation-first *engineering***: source features have a predeclared proof/erasure/effect contract, but development compiler implementation can proceed while proof obligations remain open; certified emission stays fail-closed.

**What to borrow:** Lean's `do` / local mutable state / ADTs / total recursion / monads; Rust's typed errors and typed intermediate languages; Go's clear loops and small helpers; CakeML/CompCert's semantic preservation boundaries; Verus/Dafny/SPARK's contracts, explicit frames, ghost separation and invariants.

**What not to borrow:** unrestricted Lean `partial`/`unsafe`/macro Meta programming, Rust's full lifetimes/aliasing/`unsafe`, Go's shared mutable map/goroutine semantics, host `IO` or unspecified numeric/text behavior as a source-language feature. Exclude these from the **closed portable compiler executable closure**; separate host/boundary code may use a declared model and distinct claim.

## 1. Primary evidence and precise provenance

This ledger distinguishes *normative requirements*, *source observations*, *external research*, and *unproved design hypotheses*. Every link is a primary document, pinned code, or repository-owned source wherever available.

| ID | Material | Directly supported observation / constraint |
|---|---|---|
| EV-NORM | [PSCV language at audited commit][EV-NORM] | `2.4` feature closure; `18.8` total recursion; `21.15` verified effects; `A.18` finite grammar; `32.9` no proof, no verified emission |
| EV-ENV | [same reference, header][EV-NORM] | Pinned `STD-ENV-PSCV-V1-L435RC3-RC1.json` **SHA-256 PENDING — release-blocking**; must not invent a lock digest |
| EV-V51 | [V5.1 standalone compiler architecture][EV-V51] | Source → Core → Checked → Certified → RuntimeIR → Validated → Specialized → 4 backends; Claim Lattice / Authority Firewall; typed product bundles |
| EV-BOOT | [existing source profile][EV-BOOT] and [portable profile][EV-PORT] | `PSC1-selfhost-stable/1` currently forbids `mutual`, `termination_by`, `let mut`, `for`, `while`, proof tactics, `deriving` and macro machinery |
| EV-STD | [self-host source standard][EV-STD] | Existing legacy 55-module compiler closure, canonical `.ps` replay, bootstrap static guard and fixed-point checks; source restrictions are *not* a future grammar promise |
| EV-STATUS | [compiler status][EV-STATUS] | Bootstrap is **compiler-only** (55 modules, **no kernel package**), default checked provider is a pinned Lean-Wasm path; current actual implementation not yet `pscv-v1` |
| EV-HOST | [production checked service][EV-HOST] | Production composition uses JS host `createCheckedCompilerService` and kernel-provider checked-session interfaces; backend driver facades are *not* production authorities |
| EV-IR | [runtime IR model][EV-IR] | `PsErasedIrModule` and `PsValidatedIrModule` are separate from semantic certification; raw `PsVerifiedIr*` naming is legacy |
| EV-WASM | [backend architecture research][EV-WASM] | Wasm target structural validation is incomplete relative to Wasm Core 3.0 full validation; native ABI, Unicode and representation concerns remain material |
| EV-M0 | [Lean bridge experiment][EV-M0] | Narrow `.ps` to pinned `.lean` plus kernel check; no source-contract lowering, certificate, full PSCV surface or four-target codegen |
| EV-LEAN | [Lean pinned compiler][EV-LEAN] / [LCNF CompilerM][EV-LEAN-CM] / [PassManager][EV-LEAN-PM] | Lean compiler actually uses ADTs, Reader/State compiler monads, `do`, `let mut`, finite `for`, local helpers |
| EV-REC | [Lean recursion reference][EV-REC] | Structural and well-founded recursion have checked termination evidence; `partial` is kernel-opaque, and unsafe compilation may diverge from logical definition |
| EV-DO | [Ullrich/de Moura ICFP 2022][EV-DO] / [mechanized supplement][EV-DO-CODE] | Formal translation rules for local mutation, early return and iteration to pure monadic code; **not** a proof of PSCV's yet-unimplemented lowering |
| EV-RUST | [rustc overview][EV-RUST] / [stage bootstrap][EV-RUST-BOOT] / [MIR passes][EV-RUST-MIR] | Typed IR/query discipline and staged compiler bootstrap; Rust compiler source has ADTs, pattern matching, Result and deliberate unsafe boundaries |
| EV-GO | [Go compiler README][EV-GO] / [Go language spec][EV-GO-SPEC] | Go compiler's parser/typecheck/IR/SSA, loops and Go-source bootstrap; native map iteration, integers and strings cannot define PSCV semantics |
| EV-COMPCERT | [CompCert semantic preservation][EV-COMPCERT] / [TCB analysis][EV-COMP-TCB] | Preservation theorem boundaries and remaining compiler/runtime trusted-base assumptions |
| EV-CAKEML | [CakeML official project][EV-CAKEML] | Functional value semantics, formally specified compiler and verified bootstrapping precedent |
| EV-VERIF | [Dafny reference][EV-DAFNY] / [Verus reference][EV-VERUS] | Loop invariants, decreasing measures, separate proof/executable artifacts and explicit contracts |
| EV-WASM-CORE | [W3C Wasm Core 3.0][EV-WASM-CORE] / [validation algorithm][EV-WASM-VAL] | Wasm validation and host embedding have narrower authority than source compiler preservation |
| EV-AI | this document's **proposed benchmark protocol** | AI proof success/maintenance efficiency is **UNMEASURED**; there is no primary controlled PSCV AI-proof-performance study to cite |

**Source inspection note:** indicative non-random samples (16 pinned Lean compiler/elab files, ~10,000 lines; 16 PSCV compiler/backend files, ~24,000 lines; additional rustc and Go compiler modules) show extensive Lean `do`/finite loops/local mutation and much more explicit PSC1 fuel-worker style. These are approximated textual observations, not random matched functions, AST-frequency measurements, causal productivity evidence or formal proof-speed data.

**Critical correctness repair of V2:** on `pscv/v3-execution`, the four modules named `packages/driver-*/src/Ps/Driver*/Compiler.lean` are now **bootstrap compatibility facades**, each identifying `scripts/compiler-checked-service.mjs` as the production mediation point [EV-HOST]. Do not cite these facades as evidence that a Lean-checked Core can already feed four first-class certified backends.

## 2. Compatibility hierarchy: portable is not the full language

The proposed implementation profile is an *admitted fragment* of the approved PSCV source language. **The full `pscv-v1` language remains larger.** For example, PSCV requires verified `while` and abstract dependent/refinement constructions for the general language, but compiler implementation source may select finite `for` and library-recursive algorithms instead; this is not a claim that `while` is globally removed from PSCV.

Hierarchy:

~~~text
Approved ProofScript / PSCV Language Reference
   └── pscv-v1, PSCV-VERIFY-v1, PSCV-CERT-v1
         └── proposed PSCV-selfhost-portable/2 (closed compiler-source fragment)
               ├── P0: small total semantic and value/effect kernel
               ├── P1: productive portable source syntax lowered into P0
               ├── P2: proof/source-only DSL and approved tactic surface
               └── H: explicit host / assurance / foreign boundary (NOT in closed P0/P1)
Existing PSC1-stable and PSC1-portable remain separate preserved bootstrap profiles.
~~~

### 2.1 P0 — small total semantic core (highest proof leverage)

**P0 values and computation:**
- Total `def` with explicit named types and finite non-recursive lambdas; structural or well-founded recursive definitions with kernel-accepted decrease.
- Positive inductive and indexed inductive families, records, constructor applications, projections, exhaustive `match`, nonescaping immutable closures.
- `Nat` and `Int` mathematically exact; exact-width `UInt8/UInt16/UInt32/UInt64` and signed variants when admitted; `Bool`, `Char`, `String` and `ByteArray` with frozen meanings; ignore float arithmetic *in the initial self-host implementation source* unless the compiler demonstrably needs it. This does **not** remove floats from PSCV's general language.
- `Option`/`Except` and finite immutable `List`/`Array`; target-independent, total mutable-state-as-value transitions with no escaping aliasable locations.
- Closed monadic `Identity`/`Reader`/`State`/`Except` effects with registered WP semantics, including exact composition order and failure behavior. No raw world IO.
- Deterministic name/class/coercion resolution relative to a frozen environment; no arbitrary open-ended metaprogramming.
- Logical `Prop`, dependent proof types, `Subtype`/`Fin`, proof terms, proof-only/ghost values; **only** erased under certified noninterference.

### 2.2 P1 — productive programming surface (proof-safe desugaring only)

- Ordinary PSCV `function`/`def`, typed generics, immutable record updates, comprehensible nested constructor matches.
- `do`, local `let mut`/assignment, early `return`, typed `let ←` and `Except` error propagation.
- **Finite** `for` over a *certified finite iterator*, with `break`/`continue` modeled by control-flow VCs and enough loop invariant evidence for any observable state.
- `where` helpers; restricted *total* mutual recursion if the named joint measure and conversion are accepted; transparent `abbrev`.
- Fixed and versioned library combinators `map`/`fold`/`traverse`, validated mutable builders and resource-bounded worklists with proven abstract value semantics. Efficient source code must not be forced into global fuel-worker style.

### 2.3 P2 — proof/specification-only surface

- Approved `requires`, `ensures`, `given`, `assert`, `errors`, `reads`, `modifies`, `old`, `ghost` and explicit `verify` as specified by PSCV normative chapters (not ad hoc parser aliases).
- Tactics (`simp only`, `omega`, `grind` and others when admitted) are untrusted *proof constructors*; kernel acceptance and allowed dependency closure establish authority.
- Compact named lemmas and opaque **theorem APIs** are acceptable; an executable opaque function body with no checked executable correspondence is not.
- Generated proof/ghost state must be erased without affecting observable runtime data, control flow or effects.

### 2.4 H / excluded

- **Excluded from portable closed executable source:** `partial`, `unsafe`, arbitrary user `axiom`, unrestricted heap aliases/raw pointers, unbounded reflective evaluation, unrestricted source `macro`/`Meta`, native-eval proof trust shortcuts, unrestricted concurrency, runtime access to unmodelled IO/FFI/network/time/randomness, ambient mutable globals.
- **Development/host boundary:** pinned Lean proof search/elaboration helpers, tooling, file/process IO and debugger services can use these host capabilities when explicitly named, outside the self-host-closure proof, with recorded trust/effect assumptions. Such dependencies cannot quietly remain when claiming portable independent closure.
- **Staged extension, not P0/P1 prerequisite:** general verified `while` and custom `deriving` expansions. Full `pscv-v1` still requires suitable `while` support; the compiler implementation profile does not necessarily need it to self-host.

### 2.5 Policy for initial feature priority

**Foundational (must precede wholesale source migration):** typed diagnostics, ADTs/structures, arrays/byte builders, exact runtime numeric/string primitives, Option/Except, frozen instances, total recursion.

**Highest developer productivity per small semantic extension:** `do` + local mutation + early return + finite `for`. The source sugar must *always* lower into P0 with explicit proof obligations; user-facing convenience is not trusted semantics.

**Higher-risk:** custom macros/deriving, unrestricted typeclass search, general `while`, aliasable heap and IO. Keep outside initial closure rather than increasing proof and backend obligations.

## 3. Exact semantic contracts for high-impact features

### 3.1 Deterministic call and error semantics

Source constructs are resolved and elaborated against **PSCV-approved environment identity**, not arbitrary ambient Lean imports. The same function specialization, implicit parameters, short-circuit behavior, pattern guards, binding scope, evaluation order and diagnostic ordering must correspond in the Lean and native frontends.

**Proposed explicit default for a portable state+error compiler API:**

~~~text
CompilerM E S A  :=  S -> Except E (A, S)
success(value, state') = Except.ok(value, state')
failure(error)         = Except.error(error)
~~~

An error discards the output state (transactional on a persistent logical model). This corresponds conceptually to `StateT S (Except E) A`, **not** `ExceptT E (StateM S) A`; the latter returns a state even on failure. This is a **proposed profile/library default**, not a statement that existing PSCV source has already standardized the transformer order. Diagnostics needing accumulation must be returned as explicit data in the error payload (or a distinct, separately specified diagnostic effect). When the caller intentionally wants retained failed-state diagnostics, it must select another named effect/contract; no accidental semantic changes under a backend runtime exception.

Public algorithm type should have a named error family and a precise exhaustion policy. If a completeness-required checker runs out of resources, report `ResourceLimit/Unknown` rather than **false rejection** or fabricated well-typed/verified acceptance. Deterministic budgets can make a function total while limiting completeness; their bounds and failure meaning belong to the API specification.

### 3.2 Local mutation / finite iteration translation

The recommended desugaring is an SSA-like typed state transformer whose evaluation relation is shared with the core, preserving the order of effects:

~~~text
let mut x := v; body       ->  state variable x_0 := v;
                              SSA versions x_1, ...; final result state
x := e                    ->  (x_next = eval(e, current_state))
early return e            ->  control outcome Return(eval(e))
break / continue          ->  control outcome Break / Continue
for x in finite_iterator  ->  recursion on finite iterator cursor/remaining measure
~~~

A real implementation must prove/check separate relations for *normal*, *return*, *break*, *continue* and *error* exits, including approved postconditions and frame effects. Mutable state cannot escape through a captured reference. Mutating the iterator while assuming it is finite is disallowed unless the iterator model explicitly proves remaining-measure decrease.

Evidence: Ullrich/de Moura's ['do' Unchained][EV-DO] proves a translation pattern for local imperativity in Lean; it does **not** prove this new PSCV translation by itself. The normative `[pscv.do.verified]` and loop sections define additional PSCV VCs [EV-NORM].

### 3.3 Total recursion and measurable fuel

- Preferred: ordinary structural recursion on ADT shape.
- Next: `termination_by` with named length/size/lexicographic measure and `decreasing_by` accepted by kernel.
- Next: a *finite worklist or bounded iterator*, with decrease over queue/remaining work or over an explicit counter.
- Explicit `fuel` is allowed **only** when `Exhausted` has well-specified typed semantics; no arbitrary "successful result" fallback. A compiler claiming complete acceptance must not quietly classify unknown as rejection.
- General `partial` is not a shortcut for P0 totality, despite frequent use in Lean's implementation.

**Proof-cost budget:** every admitted recursive family must have a tractable local termination theorem and reusable library measures. Prefer a finite iterator library to dozens of handwritten fuel workers; benchmark both. Well-founded recursion may be expensive to reduce in the kernel compared to structural recursion [EV-REC], so proof-performance testing must measure elaborator/kernel cost separately from target runtime speed.

### 3.4 Value/representation and runtime contract

**Numbers:** keep arbitrary-precision `Nat/Int` logical semantics. A compiler implementation may use `UInt32/UInt64` for bounded byte offsets/IDs as an *explicit refined/checked representation*, proved to correspond to a `Nat` domain where relevant. No silent narrowing; JavaScript `Number` cannot represent all Nat/Int values, WebAssembly i32/i64 cannot represent unbounded Nat, Rust target `usize` varies by target. Integer division, remainder, negative shifts, signedness, wrap/overflow and division-by-zero cases require exact primitive contracts.

**Text:** source positions/hashes operate on UTF-8 **byte offsets**, with explicit Unicode scalar decoding; no silent redefinition to JS/Java UTF-16, PHP host byte/array coercion, or generic character index. Normalize neither source data nor line endings without a named conversion rule. Invalid UTF-8 requires typed rejection and preserved byte positions.

**Containers:** immutable abstract ADTs/records/arrays/maps, checked bounds (or `Fin` proof indices), fixed equality/hash laws, stable deterministic ordering for all emitted artifacts. Fast internal unordered maps are allowed for lookup only; output/order-sensitive traversals must use explicit source-order vectors, sorted keys or typed ordered maps.

**Strings and byte builders:** encode append order, UTF-8 byte-size, snapshots and resource limits; a target-specific internal mutable buffer is permitted if it implements the same immutable observable value abstraction. The Wasm research notes earlier scalar-index vs UTF-8 representation performance issues [EV-WASM]; a fast representation is not automatically semantics-preserving.

**Floats:** PSCV general-purpose language retains full specified Float/Float32 behavior. The *compiler implementation subset* may exclude float arithmetic initially because NaN, -0, rounding and cross-target operators impose significant proof/portability costs without obvious compiler-core demand. This is a narrower usage profile, not a normative language removal.

**Closures:** immutable captures by value, specified call/evaluation order, no observable reference equality or general escaped mutation. Higher-rank runtime polymorphism, unrestricted reflection and open specialization are outside P0 unless proven.

**Resource semantics:** mathematical termination cannot guarantee sufficient RAM or stack. Define typed resource exhaustion where the runtime can catch it and explicit host assumptions for uncatchable OOM/traps; don't claim closed resource behavior without evidence. Deep traversals should use validated worklists/trampolines; JS proper tail calls are not a portable assumption.

### 3.5 Runtime / target evidence mapping

| Abstract source obligation | TypeScript | Direct JavaScript | Direct Wasm | Rust | Future Python/PHP/Java/Go |
|---|---|---|---|---|---|
| Nat/Int exactness | BigInt/exact runtime behind TS | BigInt/exact library | explicit arbitrary-int runtime | exact integer runtime library | Python big integers; others explicit exact library |
| Fixed-width integer | exact JS-width operators | same JS semantics | i32/i64 & checked conversions | explicit width/wrapping ops | target wrapper, not host default |
| Byte strings/source maps | UTF-8 byte arrays | UTF-8 byte arrays | immutable bytes in managed/linear memory | UTF-8 byte slices | Python bytes; Java/PHP byte discipline |
| ADTs/records | tagged constructors | tagged constructors | tagged layout/GC or managed memory | enums/structs | host tagged sum model |
| Closures | immutable capture + type erase | closure conversion/runtime closures | closure conversion | closure structs/specialization | explicit capture model |
| Local State/Except | tagged success/error values | same runtime semantics | tagged ABI/result | Result with explicit rollback | explicit tagged results |
| Collection lookup/output | unordered lookup + ordered enumeration | same | specified array/map implementation | map plus stable traversal | reject host map nondeterminism |
| Host IO | Node capability adapter | Node capability adapter | explicit WASI/import capability ABI | audited native CLI/FFI | language-specific host layer |
| Logical proof/erasure | **not** tsc's job | **not** JS engine's job | **not** Wasm validator's job | **not** rustc's job | separate checked source evidence |
| Target preservation | TS->JS and RuntimeIR relations | JsIR/JS correspondence | WasmIR/ABI/binary relation | Rust-source/rustc boundary | new backend evidence |

**Future backend policy:** Python, PHP, Java, Go and other outputs require new versioned backend descriptors, runtime primitive contracts and their own validation. They cannot force a source semantic revision merely to fit host language defaults. Performance portability is measured per target; semantic fidelity takes priority.

## 4. Compiler architecture and trustworthy layering

~~~text
Canonical ProofScript .ps source + pinned profile + approved specs
                         |
                     closed parser
                         |
               deterministic elaboration
                         |
            Lean-hosted | native PSCV
                 checked Core
                         |
            kernel proof/trust closure
                         |
             PSCV-CERT gate (when verified)
                         |
                  typed erasure
                         |
                  RuntimeIR
                         |
              strict validated IR
                         |
              specialization/evidence
                         |
        +----------------+--------------+-------------+
        |                |              |             |
    TS compiler     direct JsIR     WasmIR/binary   Rust emitter
        |                |              |             |
     pinned tsc       JS runtime      Wasm engine     pinned rustc
        |                |              |             |
        +----------------+--------------+-------------+
                         |
      target artifacts, maps, interfaces, evidence bundles
~~~

**Lean-native adapter is a *new correctness boundary*.** Lean Core terms are NOT validated PSCV RuntimeIR. The adapter must analyze exact reachable executable declarations, monomorphization/generics, inductives and recursors, closure capture, primitive mapping, recursion, proof erasure, effect semantics and import/axiom closure. Each unsupported construct must reject by a precise code; no fallback to `unsafeCast`, `undefined`, dynamic eval, arbitrary host function or external Lean call.

**Actual current production architecture:** inspected `pscv/v3-execution` `packages/driver-{ts,js,wasm,rust}/src/Ps/Driver*/Compiler.lean` each state they are **bootstrap-only compatibility facades** and point to `scripts/compiler-checked-service.mjs` [EV-HOST]. Existing checked host sessions, product identities, backend-specific artifacts and providers must be integrated through their public boundaries, not bypassed by a new wrapper. The compiler-only 55-module source closure deliberately excludes the kernel [EV-STATUS]. Re-entry claims must state whether the checker is a separate pinned provider process or an independently owned bundled PSKernel build. **A complete standalone PSCV+PSKernel distribution is stronger than a compiler-only self-host.** The profile shall not conflate the two.

**V5.1 compatibility:** don't change KernelContract, PSKernel implementation, host certified-source authority, query product identity, existing backend descriptors, Standard environment or compiler semantic spine by adopting a new source style. Planned adapters must consume declared typed interfaces. Tests/AI/optimizers/foreign backends cannot mint source/kernel/certificate authority.

## 5. Cross-language lessons and proof-friendly choices

| Reference system | Direct evidence | Chosen design feature | Rejected semantic import |
|---|---|---|---|
| Lean 4 | [LCNF source][EV-LEAN-CM], [PassManager][EV-LEAN-PM], ['do' paper][EV-DO], [termination][EV-REC] | pure small Core + ergonomic `do`/local mutation, total recursion and kernel replay | unrestricted partial/unsafe, ambient macros/Meta |
| Rust | [compiler overview][EV-RUST], [MIR passes][EV-RUST-MIR] | explicit error types, named IR passes, staged bootstrap and typed APIs | borrow/lifetime/source pointer semantics |
| Go | [official cmd/compile README][EV-GO] | readable loops, small helpers, modular compiler stages | nondeterministic map order, panic/IO |
| CakeML/CompCert | [CakeML][EV-CAKEML], [CompCert][EV-COMPCERT] | traceable semantic relations, verified-vs-generated-vs-fixed-point claims | source proof is not target compiler proof |
| Dafny/Verus | [Dafny][EV-DAFNY], [Verus][EV-VERUS] | explicit invariants/decreases, typed pure/error/state and ghost separation | arbitrary heap permissions in P0 |
| Wasm Core 3.0 | [W3C spec][EV-WASM-CORE], [validation algorithm][EV-WASM-VAL] | ABI-specific binary validation and typed target IR | Wasm validation is not source fidelity |

**Expected proof tractability, not measured superiority:** algebraic data, closed effects, finite iterators and total functions expose smaller proof surfaces than arbitrary aliasing/IO/partiality. However a pure structurally recursive definition can be easier for a prover than an SSA-lowered imperative loop. The profile admits both, provides library proofs, and requires held-out AI proof benchmarks before claiming a speedup.

## 6. Implementation, bootstrap and assurance levels

- **D0 Development:** parse/elaborate/check under pinned Lean or PSCV and emit explicitly unverified development artifacts; no certificate.
- **P1 Portable source:** native PSCV parses/elaborates the same `.ps` closure with specified source/Core correspondence to pinned Lean reference.
- **P2 Four target runnable:** source compiles to runnable *whole compiler* TS, direct JS, direct Wasm and Rust, including source ingress and host adapter.
- **P3 Independent four-way self-host:** every generated compiler can compile the *same full compiler source* to all four targets; no secret Lean/old PSC1 compiler call during re-entry. This is sixteen producer/target paths.
- **P4 Verified/certified:** source spec identity, kernel term/axiom/effect closure, VC and totality obligations, ghost/erasure safety, target preservation and approved release claims all closed. P3 does not imply P4.
- **P5 Standalone checker distribution (distinct target):** executable PSCV plus independently owned PSKernel build checked and packaged under its own KernelContract and metatheory evidence; the kernel is NOT counted in the current compiler-only seed.

**Stage0/1/2/3 vs target dimension:** stages and targets are orthogonal. Record `Stage0 seed → Stage1 compiler → Stage2 compiler → Stage3 compiler` separately for TS/JS/Wasm/Rust, plus cross-target re-entry. Fixed-point byte equality requires a fixed target+toolchain+abi+source identity; cross-target comparisons require canonical semantics/behavioral equivalence rather than impossible JS=Rust bytes.

| Executing full compiler | emit TS | emit direct JS | emit Wasm | emit Rust |
|---|---|---|---|---|
| C[TS] | required | required | required | required |
| C[JS] | required | required | required | required |
| C[Wasm] | required | required | required | required |
| C[Rust] | required | required | required | required |

**Safety against accidental fake acceptance:** four backend emitters that compile a pure test or one compiler module ≠ P2; a wasm parser without the full checked pipeline ≠ P3; Rust source without successful `rustc`/runtime ≠ P2; a compiler that calls Lean for actual checking at re-entry ≠ native PSCV P3; an unchanged Stage2→Stage3 digest ≠ formal compiler preservation. The provider requirement must name exact source/host artifact and allowed transitive code closure.

## 7. AI proof-throughput and total-cost evaluation (required, currently absent)

**Objective is not the shortest source.** Compare total agent/prover effort on fixed *approved* properties, including source implementation, generated VCs, kernel-replayed proofs, refactor maintenance and backend correspondence. A tool may produce a proof candidate but may not weaken or approve the specification or mint the certificate.

**Frozen benchmark design:** 24 tasks across lexer bounds/UTF-8, AST syntax maps, substitution and well-scopedness, instance/unifier correctness, termination, effectful parser rollback, typed IR validation, specialization preservation, emission determinism, Wasm target validation, CLI host boundaries and bootstrap fixed-point correspondence.

Use three source styles for each applicable task: **A** current PSC1 fuel/exhaustive worker; **B** new P1 `do`+local-mut+finite-for; **C** equivalent total functional fold/structural recursion. Match approved specification, initial state and observable behavior exactly; never rewrite the theorem statement to favor a candidate. Hold model/prompt budget/tool access, Lean/PSKernel and library pins constant. Repeat on multiple independent tasks/runs; report timeouts, empty-result failures and uncertainty, not only successes.

**Measurement fields:** theorem coverage by approved spec ID; completed kernel-accepted/axiom-closed proofs; failed or vacuous proof attempts; VC count/size/dependency depth; median/p95 proof latency and wall-time; tokens/tool calls/edits; proof repairs after 3 semantics-preserving refactors; compilation time/peak memory/target runtime; number of required extra lemmas; assumptions. Publish the raw attempt ledger and proof artifacts with exact source/theorem/compiler identities.

**Acceptance rule for changing profile based on AI "ease of proof":** no incorrect accepted proof or assumption laundering; success non-inferiority with uncertainty intervals; then statistically defensible proof-cost reduction or maintenance improvement. A hypothesized 20% median reduction is a *research target*, not a present finding. Lack of data prevents claiming "AI performance proven" even if this document passes a design checklist.

## 8. Phase-gated migration roadmap

1. **Freeze seed and root authority:** preserve `PSC1-selfhost-stable/1`, checked source hash, exact 55-module closure, current compiler-only/kernel-provider separation and old pipeline validation. No history deletion.
2. **Adopt the source profile with semantics crosswalk:** confirm grammar and `PSCV-VERIFY-v1` mapping, exact environment version, unsupported forms, transport/ABI and backend requirements; **block verified profile promotion until the pending Standard manifest digest is regenerated**.
3. **P0 library proof contracts:** numeric/Unicode/collections, State+Except rollback, finite iteration, bounds, deterministic builders, total measures and typed errors.
4. **Lean-host canonical `.ps` frontend:** expand PR #81's narrow bridge into a closed grammar + stable source maps, approved Lean lowering and explicit proof/assumption checking, not an ambient Lean parser acceptance.
5. **P1 syntax support + native PSCV parity:** implement and test total `do`, mutable local, finite for and effects in PSCV parser/elaborator/erasure; compare with Lean lowering at semantic/Core level.
6. **Lean Core → validated RuntimeIR path:** integration into certified source/KernelContract APIs; reject unsupported closure shapes; per-family correspondence.
7. **Four backends, incremental closure:** validate nontrivial source modules on TS/JS/Wasm/Rust, then library → syntax → meta → elaborator → core/IR → erasure → specialization → backend drivers and host API.
8. **Full four-way compiler execution:** actual target compiler execution, correct host ABI, malformed-input behavior, resource limits and complete module import closure.
9. **16-cell re-entry and staging:** Stage0 seed frozen, each four runtime compiler compiles same full source into each of four targets; cross-generated stage2/3 evidence and independent semantic comparator.
10. **Formal assurance and portable proof performance:** implement spec/VC closure, axiom/effect and ghost audit, erasure correctness, backend preservation or independent validation, controlled AI-proof study. Verify source release and compiler correctness independently.

**No proof-gate weakening:** implementation and development can progress with declared open proof obligations. No artifact claiming verified PSCV status is emitted until the approved full mandatory closure is accepted. Proof/verification and runtime/performance failures are tracked separately.

## 9. Documentation scoring discipline and blocking uncertainty

The **previous 88.2/100** was an *unvalidated subjective architecture preference score*. Do not reinterpret it as empirical success. V3 uses a **different**, explicit **100-point design-evidence checklist** split across the user's eleven criteria. The checklist asks whether the document makes a source-backed, precise, falsifiable *design decision* and a named acceptance test. A design point is **not** an implementation pass, scientific outcome or kernel proof. Such distinctions are mandatory even if design coverage exceeds 97.

**Known unclosed external facts:**
1. The normative `STD-ENV-PSCV-V1-L435RC3-RC1.json` SHA-256 is **PENDING** in the approved reference [EV-NORM]; verified release is blocked.
2. The recorded 55-module compiler bootstrap is compiler-only; provider/kernel integration is a separately owned closure [EV-STATUS].
3. PR #81 is a narrow M0 development experiment, not a fully conformant Lean 4 frontend [EV-M0].
4. V5.1 implementation remains unfinished, including target-specific adapter/evidence gaps; do not claim broad four-backend P3.
5. No controlled empirical AI proof-completion results, four-backend performance baseline or exact Wasm re-entrant host ABI contract have been produced in this research.
6. CompCert/CakeML papers support *architectural feasibility* of preservation and bootstrap, not a theorem about this PSCV project [EV-COMPCERT][EV-CAKEML].
7. A source-profile gate must test **transitive dependencies** and kernel assumptions, not just keyword occurrence or syntactic `unsafe` absence.

## 10. Proof obligations and semantic relations — implementation-ready specification

The model below is **a proposed target**, not a completed PSCV formalization. It makes the proof obligations precise enough to review independently. The existing PSCV language reference remains authority on Core, defeq, recursion, proof/erasure and effect semantics [EV-NORM].

### 10.1 The four refinement boundaries

Let `S` be a closed, well-profiled PSCV source module, `EL(S)` its Lean-checked Core elaboration, `EP(S)` its future PSKernel-checked Core elaboration, `RL`/`RP` their runtime erasures, and `Compile_t` the target backend for `t∈{TS,JS,Wasm,Rust}`. Write `Obs(M,input)` for a declared observable behavior including success/result, typed error, explicit emitted bytes, and boundary effects. Resource exhaustion belongs to a separate observable capability, not a fake semantic success.

**Boundary A: approved source -> Lean Core.**

~~~text
AcceptSource(profile, envDigest, S)
∧ LeanElaborates(S, C_L, env)
∧ LeanKernelChecks(C_L, allowedAssumptions)
⇒ SourceRelation(profile, S, C_L)
~~~

**Unproved obligation:** the final implication needs a source-fidelity/lowering theorem or independent validator for every admitted PSCV source family. Lean elaboration alone does not prove its own conformance to PSCV-owned grammar, `PS-UNIFY-v1`, frozen instance order or semantics.

**Boundary B: Lean Core ↔ PSCV checked Core.**

~~~text
CheckedLean(C_L, env_L)
∧ CheckedPSKernel(C_P, env_P)
∧ SameSemanticProfile(env_L, env_P)
⇒ CoreRelation(C_L, C_P)
~~~

This relation is a future theorem/validator requiring pin-accurate elaboration semantics, name/universe/recursor translations and proof assumptions. A double-acceptance test is useful differential evidence, **not** in itself proof of `CoreRelation`.

**Boundary C: checked Core -> erased/validated RuntimeIR.**

~~~text
Checked(C) ∧ ApprovedSpec(C) ∧ AllowedDependencyClosure(C)
∧ VerificationVCsClosed(C) ∧ ErasureSafe(C)
∧ Erase(C) = R ∧ ValidateRuntimeIR(R)
⇒ RuntimeSemanticsCorrespond(C, R)
~~~

Raw IR well-formedness alone does not establish runtime correspondence. Dependency traversal must cover imported code; `sorry`/`axiom` trust, noncomputable executable dependencies and host capabilities cannot be hidden by renamed or generated definitions. Proof and ghost state may be erased only under a noninterference argument [EV-NORM].

**Boundary D: validated RuntimeIR -> target executable.**

~~~text
ValidatedRuntimeIR(R) ∧ BackendAccepted(t, R)
∧ TargetValid(t, Compile_t(R))
∧ CorrespondenceEvidence(t, R, Compile_t(R))
⇒ Beh(Compile_t(R)) ⊑ AllowedBeh(R)
~~~

The relation's exact simulation/refinement strength, nondeterminism and resource assumptions must be fixed per backend. `TargetValid` alone (tsc/rustc/Wasm validation) is insufficient. This follows the distinction documented by CompCert between accepting a program and preserving its allowed observable behaviors [EV-COMPCERT][EV-COMP-TCB].

### 10.2 Local-mutation, finite-loop and error-state laws

For P1 source `let mut x := v; body`, target lowering must preserve substitution, capture and control-exit facts; aliased runtime references cannot escape from the mutable local. Proposed proof-shaped lemmas:

~~~text
SHP2-STATE-SSA:
  evalSource(doLocal(state, body), input)
  ≃ evalCore(lowerLocalToSSA(state, body), input)

SHP2-STATE-ERROR:
  runCompilerM(s, m) = Except.error(e)
  ⇒ no observable successful post-state was published

SHP2-FOR:
  VerifiedFiniteIterator(iter)
  ∧ validInvariant(init)
  ∧ forStepPreservesInvariant
  ∧ decreasesRemainingCursor
  ⇒ totalLoopAndExitPostcondition

SHP2-EARLY-EXIT:
  for every Return/Break/Continue/Error exit,
  corresponding reachable post/frame obligations hold

SHP2-ERASURE:
  erase(ghostOnlyChange(program)) has the same observable
  runtime behavior as erase(program), under approved premises
~~~

These are **theorem statements to instantiate in Lean/PSCV**, not actual theorem names that exist in code or claims of proved lemmas. The ICFP 2022 `do` formalization [EV-DO][EV-DO-CODE] supplies research evidence for local-mutation-as-pure-code translation, not a free proof of these PSCV-specific laws.

**Typed exception ordering:** for F0 `CompilerM Error State A := State -> Except Error (A,State)`, failures discard the successful state (logically transactional). Explicit diagnostics or partial progress must be modeled as error payload or a separately registered result type. Reject any backend lowering that retains mutable state as an untyped side effect despite this contract.

**Proof preconditions on finite `for`:** certification requires a theorem establishing iterator finiteness and bounds; if user state influences a loop's postcondition, require an invariant or an approved library theorem that implies the same initiation/preservation/exit obligations. `break` and `continue` cannot silently bypass VC checks [EV-NORM].

### 10.3 AI-proof architecture: replace opaque large goals with local certificates

For each major P0/P1 library abstraction, version:
- *logical model*: abstract value/effect relation;
- *implementation*: total function/library module and target-specific representation when any;
- *local VC*: pre/post, decreases, frame, error conditions and erasure;
- *named supporting lemmas*: ≤a manageable proof dependency scope, not an arbitrary global simp search;
- *evidence*: kernel replay, exact theorem dependency/axiom list, checked spec ID, source/Core digest and optional backend correspondence.

**Mandatory anti-vacuity rule:** `False` or weakened premises are not acceptable substitutes for approved specifications; the property must be approved independently of the candidate proof. AI agents may search, split obligations, propose lemmas and produce proof terms, but must not edit the authority-bound specification or assume away failing inputs. A module-level test is not a logical proof.

**Complexity budgeting:** collect per-function VC count, normalized expression size, maximal structural recursion depth, per-proof imported theorem closure, instance-search branch count, number of state variables exposed to each VC, and controlled proof replay time. Compare two equivalent P1 idioms experimentally rather than choosing syntax on source-line count. This metric set is a **measurement protocol**, not observed AI speedup.

### 10.4 Assurance families and untrusted boundaries

| Claim | Authority / evidence | Must NOT be inferred from |
|---|---|---|
| Syntax accepted | Closed source parser + env/profile identity | Lean accepting broader syntax |
| Source semantics correct | Pinned source/Lean Core relation | Translation printer textual parity alone |
| Kernel accepted | Lean or PSKernel checked proof term and allowed axioms | Test green or native evaluation |
| Specification approved | Immutable approved spec ID & coverage manifest | Proof of tautology or generated spec |
| Termination/effect/VC closed | Verified recursion/WP/loop/call-site proofs | `partial` or fuel count with fake result |
| Runtime erasure valid | Checked noninterference and executable closure | Successful raw IR validation |
| Backend generated well-formed target | Target-specific IR validator/tsc/rustc/Wasm checker | Kernel proof of source term |
| Backend preserves semantics | Target theorem or independently checked relation with assumptions | Successful execution of a few tests |
| Self-host compiler | Full source closure recompiled by generated target | Emitted demo or one backend printer |
| Verified independent toolchain | PSCV-CERT/ClaimSet + approved exact provider/TCB/target evidence | Fixed point, reproducibility, provenance or AI confidence |

**TCB caveat:** Lean's trusted kernel can check proof terms, but the soundness of native generated binaries also depends on erasure/compiler/runtime and foreign toolchains unless corresponding preservation evidence discharges the boundary. Research on CompCert's trusted-base subtleties [EV-COMP-TCB] is directly relevant. A proof assistant's acceptance must not silently upgrade the JS engine, tsc, rustc, Wasm validator, filesystem or WIT adapter into proved-correct components.

## 11. Feature-to-source-to-backend conformance crosswalk

**Purpose:** prevent claiming F0 merely because parsing succeeds. Every row requires positive and negative tests for *source semantics*, *self-host compiler Core*, *erasure*, *runtime*, *four backends*, *proof obligations* and *full closure*.

| F0 family (proposed) | Normative authority / Lean precedent | Portable lowering or runtime obligation | Four-target acceptance | Proof/test IDs |
|---|---|---|---|---|
| Total function, transparent `abbrev` | [EV-NORM][EV-REC] | Core binder/substitution and recursion | all four execute exact call behavior | `SHP2-TOTAL-*` |
| Indexed ADT, structure, match | [EV-NORM][EV-LEAN] | Positive constructors, recursors, typed match erasure | all four ADT variants + exhaustive cases | `SHP2-ADT-*` |
| Generic types and immutable closures | [EV-NORM][EV-RUST] | Closed specialization, explicit captures | TS/JS closures; Wasm closure conversion; Rust closure env | `SHP2-GEN-*` |
| `Option`/`Except` typed error | [EV-NORM][EV-VERUS] | Distinct success/error Core and semantic branches | no silent JS throw/Rust panic/Wasm trap | `SHP2-ERROR-*` |
| `do`/local `let mut` | [EV-NORM][EV-DO] | SSA/state WP and no alias escape | target value semantics, same exit behavior | `SHP2-SSA-*` |
| Finite `for`, break/continue | [EV-NORM][EV-DO] | Certified iterator progress, invariant/exit VCs | target-specific loops obey same order | `SHP2-FOR-*` |
| Reader/State/Except effect stack | [EV-NORM][EV-VERUS] | Explicit State→Except result, agreed rollback | compare retained vs discarded state on errors | `SHP2-WP-*` |
| Structural/well-founded recursion | [EV-NORM][EV-REC] | Kernel decrease proof and equation relation | stack-safe executable recursion/worklist | `SHP2-RECUR-*` |
| Nat/Int/fixed-width math | [EV-NORM][EV-WASM-CORE] | Exact signedness, overflow, div/mod and narrowing | JS BigInt, Wasm big Nat, Rust exact ints | `SHP2-NUM-*` |
| UTF-8 `String`/`ByteArray`/source offsets | [EV-NORM][EV-WASM] | exact bytes, scalar decoding, source positions | test surrogate/invalid-byte/large-offset cases | `SHP2-UTF8-*` |
| Array and deterministic map/builder | [EV-NORM][EV-GO-SPEC] | bounds, equality/hash and stable ordering | no unordered iteration affecting bytes | `SHP2-COLL-*` |
| Contracts/proofs and ghost state | [EV-NORM][EV-DAFNY] | approved spec + VC + checked erasure | proof/ghost eliminated on all targets | `SHP2-CERT-*` |
| Import closure, attributes, instances | [EV-NORM][EV-LEAN] | frozen environment and semantic identity | no implicit target-dependent import/deriving | `SHP2-ENV-*` |
| Typed RuntimeIR + specialization | [EV-IR][EV-V51] | constructor/ref validation & specialization relation | shared backend input and target IR checks | `SHP2-IR-*` |
| Checked kernel-provider boundary | [EV-STATUS][EV-HOST] | exact API/checked session + approved assumptions | host/provider composition explicit in each target | `SHP2-PROVIDER-*` |

For *each* feature and each of JS/TS/Wasm/Rust, generated source, target IR, actual emitted artifact, runtime execution and negative cases must be inspected independently. A future Python/PHP/Java/Go backend repeats this same feature table with its own runtime/model assumptions, without revising the ProofScript source semantics.

### 11.1 Negative-input and edge-case matrix

| Family | Distinct negative/edge obligations |
|---|---|
| Parse/lex/UTF-8 | invalid bytes, nested comments, EOF in string, malformed escaped tokens, mixed line endings, surrogate input, correct byte spans |
| Elaboration/types | nonexistent instance, conflicting name, wrongly unified metavariable, source-level coercion ambiguity, unsupported Lean macro leak |
| Termination | nondecreasing recursion, unbounded mutable iterator, fake fuel success, size proof violation, unproved while invariant |
| Effects | error returned with mutated state, missing `errors` branch, raw IO in closed profile, unmodeled FFI, invalid old/frame clause |
| ADT/generics | impossible branch, missing constructor fields, unknown type args, mismatched specialized body, higher-rank unsupported values |
| Runtime numbers | 2^53±1 in JS, 32/64-bit overflow edge, negative remainder, divide by zero, USize narrow, extreme Nat |
| Collections | array out-of-bounds, map collision and rehash, unstable hash seed, iterator invalidation, huge-index narrowing |
| Source maps | UTF-8 multibyte offsets, CRLF normalization, generated names, missing origin, invalid mapping reference |
| Wasm | invalid typed operand/control stacks, unset locals, heap refs, max memory, ABI import/export/signature mismatch, unclosed host call |
| Trust/assurance | proof hole, user axiom, noncomputable executable import, ghost leak, false postcondition, skipped mandatory spec |
| Resource | oversized input, deep AST, huge numeric literal, recursion stack, memory failure, parser/generator budget, correct typed `Unknown` |
| Self-host | hidden Lean call from Stage2, mismatched compiler source module, missing backend driver/provider, weak byte-only fixed-point claim |

**Selected Wasm standard caveat:** Wasm Core 3.0's validation algorithm [EV-WASM-VAL] tracks control, operand and local-initialization states; validation is necessary for target well-formedness but **not a preservation theorem**. The current PSCV backend research [EV-WASM] explicitly records validation/ABI incompleteness. A future four-backend acceptance document must freeze the Wasm engine feature set, memory/GC/reference strategy, host imports, capability model and re-entry CLI ABI.

### 11.2 Target-specific proof and source product integrity

- **TypeScript:** the emitted `.ts`, generated `.d.ts`/maps and pinned `tsc` conversion must correspond to observed checked exports. TS syntax/type checking alone does not verify executable semantics. Do not require TS for direct JS output; preserve independent backend evidence.
- **Direct JS:** JS representation profile, JsIR, validated printed code, exact BigInt/UTF-8 runtime and declaration/source-map consistency, plus checked CLI execution.
- **Wasm:** typed WasmIR, full target/engine validation, ABI and host import/export certificates, deep stack/runtime, exact byte memory semantics and actual executable full compiler.
- **Rust:** typed emitted Rust source, compile with pinned `rustc` and target triple, explicit runtime library, no hidden unsafe semantics admitted in P0, native CLI self-reentry.
- **All four:** artifact bundles preserve semantics, ABI, debug source maps, public API and evidence separately. A source-map failure cannot mint a kernel capability; debug metadata cannot substitute for executable semantics.

## 12. Controlled experiment and migration stop/go gates

### 12.1 Feature dependency order (not "rewrite the most broken test")

~~~text
Exact profiles + frozen Standard environment identity
   → Nat/Int/UTF-8/Array/Error & deterministic builder laws
   → do/let-mut/early-return (state+error model and generated VCs)
   → finite for + certified iterator + break/continue
   → total mutual/well-founded recursion + proof infrastructure
   → closed Lean-host frontend + exact source Core adapter
   → native PSCV frontend support for same language
   → checked erasure/RuntimeIR preservation + backend contracts
   → four whole-compiler executables
   → 16-cell full compiler re-entry
   → independent proof/performance and release assurance
~~~

**No major migration without preceding semantic family:** a new `for` parser form must not be marked self-host-safe until all backend and proof-family criteria are satisfied. A new `HashMap` convenience method must declare deterministic enumeration and exact runtime semantics. Existing source should remain on `PSC1-selfhost-stable/1` until the candidate compiled closure, not merely its lean source, is compatible.

### 12.2 First experiments before whole compiler rewrite

**Experiment A (source productivity + proof):** choose lexer cursor bounds, IR validator and AST traversal. Implement each in PSC1 style, pure P0 functional style and `do/let mut/for` P1 style. Compare identical specs, normalized IR, four target results and controlled AI proof replay.

**Experiment B (state+error):** implement a backtracking parser combinator as `State -> Except Error (Value,State)`; check rollback vs retained-state counterexamples on every backend, including compiled Wasm and native Rust. Deliberately failing parse paths must preserve semantics.

**Experiment C (full-closure feasibility):** choose a nontrivial compiler subsystem (e.g., lexer + parser + diagnostic) and compile the complete transitive import closure into TS, direct JS, Wasm and Rust. Test deep stack/resource limits. Stop if any essential runtime primitive is missing: implement it as a family, not a one-off workaround.

**Experiment D (Lean-Core runtime adapter):** prove/validate a small closed source→checked Lean Core→PSCV RuntimeIR→target diagram first, including one recursive ADT, generic call, State/Except, erased proof field, and a negative case with unsupported closure. No cert issuance during development.

**Experiment E (controlled four-compiler bootstrap):** after the entire compiler closure is portable, run actual re-entry from generated compilers; verify all 16 paths and provider dependence. Only then evaluate multi-stage fixed-point evidence and independent checker assurance.

### 12.3 Performance and correctness gate policy

For every experiment, record source lines and AST complexity **as secondary ergonomics metrics**, proof obligations, independent kernel acceptance, timeouts, compilation wall-clock/peak memory, generated artifact size, runtime CPU/memory, deep-stack behavior, exact output identity and target-specific assumptions. Optimize performance only under preserved semantics. Cross-backend comparisons must not conflate differences in JIT/native/Wasm host runtime with source-language correctness.

**AI proof study:** target a 24-task × 3-source-style × at least 5-independent-trial protocol where feasible; report total trials, failures and confidence intervals. The numerical proof-effort target is conditional on controlled measurements; no AI proof performance benefit is currently established. Prioritize reducing global theorem dependence and tracking proof-maintenance change amplification, not gaming token counts.

**Falsification rule:** if equivalent pure source systematically proves faster or runs faster with equal maintainability, downgrade ergonomic P1 features for that subsystem. If a P1 feature causes unacceptable verification complexity, do not weaken proof checks; restrict its admissible lowering, library abstraction or profile tier. If a backend cannot preserve a required F0 runtime operation, reject the output and retain a documented blocker.



## 13. Evidence-audited iteration log and conservative design score

### 13.1 Meaning and limitations of the score

**Final self-audit: 97/100 for documented, primary-source-traceable *research and design specification coverage*.**

This is **NOT** 97/100 empirical formal-verification performance, implemented feature coverage, certified soundness, independent review, backend behavior, kernel metatheory or generated compiler quality. The *same research agent* wrote and assessed the design, so the result is a **self-assessment**, not an externally validated architecture rating. Users and future independent reviewers SHOULD reduce the score whenever a purportedly covered item lacks meaningful source support, a precise design decision, or a falsifiable conformance/proof check.

The rubric contains exactly the eleven requested criteria and **100 discrete design obligations**, with one possible credit each. Credit means the document (a) distinguishes relevant observed or normative evidence from proposal, (b) specifies a concrete choice, and (c) names a test, proof obligation or observable way to reject the choice. A code/run/proof result is **NOT** required for this **design coverage** score and must not be inferred from it. Points dependent on missing empirical or implementation-specific data are conservatively withheld.

A more ambitious score such as "97% proven or operationally successful" would be unjustified with today's evidence. This design score documents readiness for **implementation experiments**, not readiness for verified PSCV release.

### 13.2 Iterative improvement record

| Stage | Concrete research/design change | Provisional design audit |
|---|---|---|
| Previous V2 | Subjective **88.2/100 preference score**, without reproducible per-point evidence. Its rubric is different and cannot be directly compared. | Superseded |
| V3 iteration 1, `39d5e63` | Audited frozen PSCV source profile, latest V5.1, Lean compiler, rustc and Go, actual bootstrap status; corrected driver facade and missing kernel closure; defined total P0 and P1 imperative sugar. | **94/100 provisional** |
| V3 iteration 2, `f987f1c` | Added four semantic relations and local VCs, closed-feature-to-four-backend crosswalk, negative conformance corpus and AI benchmarking protocol. | **96/100 provisional** |
| V3 iteration 3 (this revision) | Enumerated 100 source-evidence-dependent design obligations; ensured that unknown AI proof, runtime performance and Wasm ABI measurements remain explicit deductions; validated score totals. | **97/100 design audit** |

Only the final checklist below is arithmetically reproducible; the earlier V3-stage scores were provisional reviewer assessments, not independent measurements. Their improvement indicates added documentation/evidence and closed design ambiguity, **not** an actual improvement in the compiler runtime or proof success rates.

### 13.3 Criterion-by-criterion scoring

| Criterion | Max | Earned: documented design | Not earned | Evidence |
|---|---:|---:|---:|---|
| Soundness/fidelity | 12 | 12 | 0 | [EV-NORM] [EV-V51] [EV-COMPCERT] |
| Formal/metatheoretic verification ability and AI proof cost | 18 | 17 | 1 | [EV-NORM] [EV-REC] [EV-DO] [EV-VERUS] [EV-DAFNY] |
| Adversarial/malformed-input robustness | 8 | 8 | 0 | [EV-NORM] [EV-WASM-VAL] [EV-WASM] |
| Compatibility completeness | 8 | 8 | 0 | [EV-NORM] [EV-ENV] [EV-V51] [EV-BOOT] |
| Architecture | 10 | 10 | 0 | [EV-V51] [EV-HOST] [EV-IR] |
| Performance design | 8 | 7 | 1 | [EV-WASM] [EV-GO] [EV-RUST-MIR] |
| Portability | 10 | 9 | 1 | [EV-NORM] [EV-WASM-CORE] [EV-WASM] [EV-GO-SPEC] |
| Longevity | 6 | 6 | 0 | [EV-NORM] [EV-STD] [EV-RUST-BOOT] |
| Interoperability | 5 | 5 | 0 | [EV-V51] [EV-HOST] [EV-WASM-CORE] |
| Self-host/bootstrap | 9 | 9 | 0 | [EV-STATUS] [EV-STD] [EV-RUST-BOOT] |
| Auditability | 6 | 6 | 0 | [EV-NORM] [EV-V51] [EV-STD] [EV-COMP-TCB] |
| **Total: design-evidence traceability** | **100** | **97** | **3** | **Self-assessed design, NOT empirical implementation or proof quality** |

### 13.4 Falsifiable 100-item checklist

| Item | Falsifiable design requirement | Score | Primary research and section |
|---|---|---:|---|
| SND01 | Normative PSCV authority has precedence | 1 | [EV-NORM] [EV-V51] [EV-COMPCERT]; `0, `3, `4, `10 |
| SND02 | Frozen names/coercions/instances are explicit | 1 | [EV-NORM] [EV-V51] [EV-COMPCERT]; `0, `3, `4, `10 |
| SND03 | PSCV source-to-Lean Core relation specified | 1 | [EV-NORM] [EV-V51] [EV-COMPCERT]; `0, `3, `4, `10 |
| SND04 | Lean-to-PSKernel Core relation specified | 1 | [EV-NORM] [EV-V51] [EV-COMPCERT]; `0, `3, `4, `10 |
| SND05 | Checked Core-to-RuntimeIR relation specified | 1 | [EV-NORM] [EV-V51] [EV-COMPCERT]; `0, `3, `4, `10 |
| SND06 | RuntimeIR-to-target observable-behavior relation specified | 1 | [EV-NORM] [EV-V51] [EV-COMPCERT]; `0, `3, `4, `10 |
| SND07 | Kernel proof authority is separate from code generation | 1 | [EV-NORM] [EV-V51] [EV-COMPCERT]; `0, `3, `4, `10 |
| SND08 | Independent approved specification identity mandatory | 1 | [EV-NORM] [EV-V51] [EV-COMPCERT]; `0, `3, `4, `10 |
| SND09 | Transitive dependency and axiom closure audited | 1 | [EV-NORM] [EV-V51] [EV-COMPCERT]; `0, `3, `4, `10 |
| SND10 | Totality and well-founded recursion required | 1 | [EV-NORM] [EV-V51] [EV-COMPCERT]; `0, `3, `4, `10 |
| SND11 | Ghost erasure and noninterference mandatory | 1 | [EV-NORM] [EV-V51] [EV-COMPCERT]; `0, `3, `4, `10 |
| SND12 | Certification fails closed on open obligations | 1 | [EV-NORM] [EV-V51] [EV-COMPCERT]; `0, `3, `4, `10 |
| PRF01 | Small total P0 semantic core | 1 | [EV-NORM] [EV-REC] [EV-DO] [EV-VERUS] [EV-DAFNY]; `2, `3, `7, `10 |
| PRF02 | Inductive and structure proof boundaries | 1 | [EV-NORM] [EV-REC] [EV-DO] [EV-VERUS] [EV-DAFNY]; `2, `3, `7, `10 |
| PRF03 | Finite iterator with termination semantics | 1 | [EV-NORM] [EV-REC] [EV-DO] [EV-VERUS] [EV-DAFNY]; `2, `3, `7, `10 |
| PRF04 | SSA local mutation relational proof obligation | 1 | [EV-NORM] [EV-REC] [EV-DO] [EV-VERUS] [EV-DAFNY]; `2, `3, `7, `10 |
| PRF05 | StateT-Except rollback semantics made explicit | 1 | [EV-NORM] [EV-REC] [EV-DO] [EV-VERUS] [EV-DAFNY]; `2, `3, `7, `10 |
| PRF06 | Separate success and error specifications | 1 | [EV-NORM] [EV-REC] [EV-DO] [EV-VERUS] [EV-DAFNY]; `2, `3, `7, `10 |
| PRF07 | Break-continue-return exceptional exit VCs | 1 | [EV-NORM] [EV-REC] [EV-DO] [EV-VERUS] [EV-DAFNY]; `2, `3, `7, `10 |
| PRF08 | Named decreases proof for recursion | 1 | [EV-NORM] [EV-REC] [EV-DO] [EV-VERUS] [EV-DAFNY]; `2, `3, `7, `10 |
| PRF09 | Structural recursion preferred when effective | 1 | [EV-NORM] [EV-REC] [EV-DO] [EV-VERUS] [EV-DAFNY]; `2, `3, `7, `10 |
| PRF10 | Fuel and unknown must not fake success | 1 | [EV-NORM] [EV-REC] [EV-DO] [EV-VERUS] [EV-DAFNY]; `2, `3, `7, `10 |
| PRF11 | Reusable theorem and library lemma APIs | 1 | [EV-NORM] [EV-REC] [EV-DO] [EV-VERUS] [EV-DAFNY]; `2, `3, `7, `10 |
| PRF12 | Spec approval independent of AI proof generation | 1 | [EV-NORM] [EV-REC] [EV-DO] [EV-VERUS] [EV-DAFNY]; `2, `3, `7, `10 |
| PRF13 | Ghost runtime noninterference property | 1 | [EV-NORM] [EV-REC] [EV-DO] [EV-VERUS] [EV-DAFNY]; `2, `3, `7, `10 |
| PRF14 | Frozen theorem-instance dependence | 1 | [EV-NORM] [EV-REC] [EV-DO] [EV-VERUS] [EV-DAFNY]; `2, `3, `7, `10 |
| PRF15 | Pinned proof tooling and kernel replay | 1 | [EV-NORM] [EV-REC] [EV-DO] [EV-VERUS] [EV-DAFNY]; `2, `3, `7, `10 |
| PRF16 | Named VC size and effect-state complexity metrics | 1 | [EV-NORM] [EV-REC] [EV-DO] [EV-VERUS] [EV-DAFNY]; `2, `3, `7, `10 |
| PRF17 | Controlled 24-task three-style AI benchmark protocol | 1 | [EV-NORM] [EV-REC] [EV-DO] [EV-VERUS] [EV-DAFNY]; `2, `3, `7, `10 |
| PRF18 | Actual repeated controlled AI proof-success and maintenance-cost results **OPEN / unmeasured** | 0 | [EV-NORM] [EV-REC] [EV-DO] [EV-VERUS] [EV-DAFNY]; `2, `3, `7, `10 |
| ROB01 | Malformed UTF-8 and lexer edge cases | 1 | [EV-NORM] [EV-WASM-VAL] [EV-WASM]; `3, `11 |
| ROB02 | Ambiguous source and ill-scoped name rejection | 1 | [EV-NORM] [EV-WASM-VAL] [EV-WASM]; `3, `11 |
| ROB03 | Missing invariant and nontermination rejection | 1 | [EV-NORM] [EV-WASM-VAL] [EV-WASM]; `3, `11 |
| ROB04 | Unknown IR types and references rejection | 1 | [EV-NORM] [EV-WASM-VAL] [EV-WASM]; `3, `11 |
| ROB05 | Imported axioms and unmodeled effects rejection | 1 | [EV-NORM] [EV-WASM-VAL] [EV-WASM]; `3, `11 |
| ROB06 | Resource exhaustion classified as failure or unknown | 1 | [EV-NORM] [EV-WASM-VAL] [EV-WASM]; `3, `11 |
| ROB07 | Invalid Wasm stack-local-ABI conformance cases | 1 | [EV-NORM] [EV-WASM-VAL] [EV-WASM]; `3, `11 |
| ROB08 | Cross-backend negative execution test matrix | 1 | [EV-NORM] [EV-WASM-VAL] [EV-WASM]; `3, `11 |
| COM01 | Portable compiler subset of full PSCV language | 1 | [EV-NORM] [EV-ENV] [EV-V51] [EV-BOOT]; `1, `2, `3, `11 |
| COM02 | PSCV Appendix A.18 grammar traceability | 1 | [EV-NORM] [EV-ENV] [EV-V51] [EV-BOOT]; `1, `2, `3, `11 |
| COM03 | Lean 4.35 to PSCV elaboration relation | 1 | [EV-NORM] [EV-ENV] [EV-V51] [EV-BOOT]; `1, `2, `3, `11 |
| COM04 | Legacy 4.34 bootstrap mismatch recorded | 1 | [EV-NORM] [EV-ENV] [EV-V51] [EV-BOOT]; `1, `2, `3, `11 |
| COM05 | Standard environment pending digest is blocked | 1 | [EV-NORM] [EV-ENV] [EV-V51] [EV-BOOT]; `1, `2, `3, `11 |
| COM06 | Deterministic unification and instance precedence | 1 | [EV-NORM] [EV-ENV] [EV-V51] [EV-BOOT]; `1, `2, `3, `11 |
| COM07 | Feature mapping across runtime and four targets | 1 | [EV-NORM] [EV-ENV] [EV-V51] [EV-BOOT]; `1, `2, `3, `11 |
| COM08 | V5.1 certified typed spine unchanged | 1 | [EV-NORM] [EV-ENV] [EV-V51] [EV-BOOT]; `1, `2, `3, `11 |
| ARC01 | P0 total semantic core separated | 1 | [EV-V51] [EV-HOST] [EV-IR]; `0, `2, `4, `10, `12 |
| ARC02 | P1 productive syntax has owned lowering | 1 | [EV-V51] [EV-HOST] [EV-IR]; `0, `2, `4, `10, `12 |
| ARC03 | P2 proof and ghost relevance separated | 1 | [EV-V51] [EV-HOST] [EV-IR]; `0, `2, `4, `10, `12 |
| ARC04 | H host capability model isolated | 1 | [EV-V51] [EV-HOST] [EV-IR]; `0, `2, `4, `10, `12 |
| ARC05 | Dual Lean and native PSCV frontend relation | 1 | [EV-V51] [EV-HOST] [EV-IR]; `0, `2, `4, `10, `12 |
| ARC06 | Lean Core to RuntimeIR adapter rejects gaps | 1 | [EV-V51] [EV-HOST] [EV-IR]; `0, `2, `4, `10, `12 |
| ARC07 | KernelContract provider remains independent | 1 | [EV-V51] [EV-HOST] [EV-IR]; `0, `2, `4, `10, `12 |
| ARC08 | Actual production checked service not driver facade | 1 | [EV-V51] [EV-HOST] [EV-IR]; `0, `2, `4, `10, `12 |
| ARC09 | Validated IR cannot mint a source certificate | 1 | [EV-V51] [EV-HOST] [EV-IR]; `0, `2, `4, `10, `12 |
| ARC10 | Shared compiler source with typed artifact bundles | 1 | [EV-V51] [EV-HOST] [EV-IR]; `0, `2, `4, `10, `12 |
| PER01 | UTF-8 bytes and cursor progress modeled | 1 | [EV-WASM] [EV-GO] [EV-RUST-MIR]; `3, `7, `11, `12 |
| PER02 | Array and byte builder fast paths defined | 1 | [EV-WASM] [EV-GO] [EV-RUST-MIR]; `3, `7, `11, `12 |
| PER03 | Map lookup separated from ordered traversal | 1 | [EV-WASM] [EV-GO] [EV-RUST-MIR]; `3, `7, `11, `12 |
| PER04 | Finite loop avoids pervasive primitive fuel workers | 1 | [EV-WASM] [EV-GO] [EV-RUST-MIR]; `3, `7, `11, `12 |
| PER05 | Explicit deep-stack worklist or trampoline | 1 | [EV-WASM] [EV-GO] [EV-RUST-MIR]; `3, `7, `11, `12 |
| PER06 | Typed specializer and representation checks | 1 | [EV-WASM] [EV-GO] [EV-RUST-MIR]; `3, `7, `11, `12 |
| PER07 | Four-target benchmark protocol and resource metrics | 1 | [EV-WASM] [EV-GO] [EV-RUST-MIR]; `3, `7, `11, `12 |
| PER08 | Measured whole-compiler runtime/peak-memory performance baseline **OPEN / unmeasured** | 0 | [EV-WASM] [EV-GO] [EV-RUST-MIR]; `3, `7, `11, `12 |
| POR01 | Exact Nat and Int not silently narrowed to Number | 1 | [EV-NORM] [EV-WASM-CORE] [EV-WASM] [EV-GO-SPEC]; `3, `4, `6, `11 |
| POR02 | Fixed-width integer conversions defined | 1 | [EV-NORM] [EV-WASM-CORE] [EV-WASM] [EV-GO-SPEC]; `3, `4, `6, `11 |
| POR03 | UTF-8 bytes not host UTF-16 indexing | 1 | [EV-NORM] [EV-WASM-CORE] [EV-WASM] [EV-GO-SPEC]; `3, `4, `6, `11 |
| POR04 | ADT constructor semantic preservation | 1 | [EV-NORM] [EV-WASM-CORE] [EV-WASM] [EV-GO-SPEC]; `3, `4, `6, `11 |
| POR05 | Immutable closure captures and conversion | 1 | [EV-NORM] [EV-WASM-CORE] [EV-WASM] [EV-GO-SPEC]; `3, `4, `6, `11 |
| POR06 | Typed error values not host exceptions | 1 | [EV-NORM] [EV-WASM-CORE] [EV-WASM] [EV-GO-SPEC]; `3, `4, `6, `11 |
| POR07 | Explicit IO and host capability model | 1 | [EV-NORM] [EV-WASM-CORE] [EV-WASM] [EV-GO-SPEC]; `3, `4, `6, `11 |
| POR08 | Python-PHP-Java-Go future backend compatibility | 1 | [EV-NORM] [EV-WASM-CORE] [EV-WASM] [EV-GO-SPEC]; `3, `4, `6, `11 |
| POR09 | TS-JS-Wasm-Rust target runtime differences tracked | 1 | [EV-NORM] [EV-WASM-CORE] [EV-WASM] [EV-GO-SPEC]; `3, `4, `6, `11 |
| POR10 | Implemented pinned full-compiler Wasm host ABI with independent execution **OPEN / unmeasured** | 0 | [EV-NORM] [EV-WASM-CORE] [EV-WASM] [EV-GO-SPEC]; `3, `4, `6, `11 |
| LON01 | Versioned implementation profile identity | 1 | [EV-NORM] [EV-STD] [EV-RUST-BOOT]; `0, `2, `8, `12 |
| LON02 | Normative source grammar remains higher authority | 1 | [EV-NORM] [EV-STD] [EV-RUST-BOOT]; `0, `2, `8, `12 |
| LON03 | Pinned environment and semantic lock policy | 1 | [EV-NORM] [EV-STD] [EV-RUST-BOOT]; `0, `2, `8, `12 |
| LON04 | Single long-term .ps source after Lean retirement | 1 | [EV-NORM] [EV-STD] [EV-RUST-BOOT]; `0, `2, `8, `12 |
| LON05 | Preserved seed and rollback history | 1 | [EV-NORM] [EV-STD] [EV-RUST-BOOT]; `0, `2, `8, `12 |
| LON06 | Future feature or target requires explicit revision | 1 | [EV-NORM] [EV-STD] [EV-RUST-BOOT]; `0, `2, `8, `12 |
| INT01 | Typed host capability and optional WIT bridge | 1 | [EV-V51] [EV-HOST] [EV-WASM-CORE]; `3, `4, `6, `11 |
| INT02 | Wasm engine imports and exports boundary | 1 | [EV-V51] [EV-HOST] [EV-WASM-CORE]; `3, `4, `6, `11 |
| INT03 | TS public declaration and runtime correspondence | 1 | [EV-V51] [EV-HOST] [EV-WASM-CORE]; `3, `4, `6, `11 |
| INT04 | Rustc and tsc foreign trust explicit | 1 | [EV-V51] [EV-HOST] [EV-WASM-CORE]; `3, `4, `6, `11 |
| INT05 | Debug/source maps and evidence bundles distinct | 1 | [EV-V51] [EV-HOST] [EV-WASM-CORE]; `3, `4, `6, `11 |
| SHB01 | Frozen PSC1 seed preserved | 1 | [EV-STATUS] [EV-STD] [EV-RUST-BOOT]; `0, `4, `6, `8, `12 |
| SHB02 | 55-module compiler-only current baseline | 1 | [EV-STATUS] [EV-STD] [EV-RUST-BOOT]; `0, `4, `6, `8, `12 |
| SHB03 | Checker/kernel external provider closure accounted | 1 | [EV-STATUS] [EV-STD] [EV-RUST-BOOT]; `0, `4, `6, `8, `12 |
| SHB04 | Full compiler executable on all four targets | 1 | [EV-STATUS] [EV-STD] [EV-RUST-BOOT]; `0, `4, `6, `8, `12 |
| SHB05 | Sixteen complete producer-target re-entry cells | 1 | [EV-STATUS] [EV-STD] [EV-RUST-BOOT]; `0, `4, `6, `8, `12 |
| SHB06 | Stage0 to stage3 independent target stages | 1 | [EV-STATUS] [EV-STD] [EV-RUST-BOOT]; `0, `4, `6, `8, `12 |
| SHB07 | Same canonical .ps import closure | 1 | [EV-STATUS] [EV-STD] [EV-RUST-BOOT]; `0, `4, `6, `8, `12 |
| SHB08 | Cross-target behavior rather than false binary equality | 1 | [EV-STATUS] [EV-STD] [EV-RUST-BOOT]; `0, `4, `6, `8, `12 |
| SHB09 | P3 selfhost distinct from P4 certified and P5 kernel standalone | 1 | [EV-STATUS] [EV-STD] [EV-RUST-BOOT]; `0, `4, `6, `8, `12 |
| AUD01 | Pinned primary-source evidence ledger | 1 | [EV-NORM] [EV-V51] [EV-STD] [EV-COMP-TCB]; `1, `4, `7, `9, `10 |
| AUD02 | Observed versus proposed versus unproven labels | 1 | [EV-NORM] [EV-V51] [EV-STD] [EV-COMP-TCB]; `1, `4, `7, `9, `10 |
| AUD03 | Reproducible point rubric and arithmetic | 1 | [EV-NORM] [EV-V51] [EV-STD] [EV-COMP-TCB]; `1, `4, `7, `9, `10 |
| AUD04 | Negative tests with concrete falsifiers | 1 | [EV-NORM] [EV-V51] [EV-STD] [EV-COMP-TCB]; `1, `4, `7, `9, `10 |
| AUD05 | Separate kernel-proof-erasure-target-bootstrap claims | 1 | [EV-NORM] [EV-V51] [EV-STD] [EV-COMP-TCB]; `1, `4, `7, `9, `10 |
| AUD06 | Open empirical and ABI blockers explicit | 1 | [EV-NORM] [EV-V51] [EV-STD] [EV-COMP-TCB]; `1, `4, `7, `9, `10 |

### 13.5 Three withheld points and remaining hard release blockers

- **PRF18 (0/1):** independently repeated PSCV AI proof-success, VC cost, source refactor and theorem-maintenance benchmarks have *not* been run. Lean/Dafny/Verus research supports the rationale for local state and explicit invariants, but does not prove AI can verify PSCV faster.
- **PER08 (0/1):** full compiler compile/run speed, peak memory, output size and stack-safety baselines across all four targets have *not* been measured by this research. Optimizations remain design hypotheses.
- **POR10 (0/1):** pinned Wasm whole-compiler executable host ABI/provider adapter with proven/validated re-entry is not established. The repository backend research records validation and native host-adapter gaps.

**Not waived by 97/100:** the PSCV normative Standard environment manifest SHA-256 remains **PENDING/release-blocking** [EV-NORM]; V5.1's compiler implementation, verified-certificate gate, provider closure, target-preservation evidence and independent self-host remain incomplete. Every mandatory PSCV verified-executable condition remains binding even if the design is fully documented.

### 13.6 How an independent reviewer can falsify this score

For each claimed 1-point item: read the cited pinned primary source; inspect the referred section for a real semantic decision; identify the acceptance test or proposed theorem that can show the decision is wrong. Deduct if the citation does not support the rationale, if a rule contradicts the normative PSCV grammar, if the test would be satisfied by a vacuous success, or if the feature requires an unacknowledged backend/kernel assumption. Run the proposed 24-task AI proof comparison and all real target/runtime tests before claiming **measured** ease of proof or performance. Do not give any extra credit for self-host byte equality, tool green status, an AI confidence judgment or an unclosed certificate.

**The next honest improvement should come from the three missing experiments and independent review, not by changing thresholds or renaming criteria.**



## 14. Reference link ledger

[EV-NORM]: https://github.com/dwijayuda/pskernel/blob/93add6da4e501c57f9016c7c3666ea52c87a66e7/psc15selfhost/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md
[EV-ENV]: https://github.com/dwijayuda/pskernel/blob/93add6da4e501c57f9016c7c3666ea52c87a66e7/psc15selfhost/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md
[EV-V51]: https://github.com/dwijayuda/pskernel/blob/93add6da4e501c57f9016c7c3666ea52c87a66e7/psc15selfhost/THE_PSCV_COMPILER_REFERENCE_VERSION_5.1.md
[EV-BOOT]: https://github.com/dwijayuda/pskernel/blob/93add6da4e501c57f9016c7c3666ea52c87a66e7/psc15selfhost/selfhost-profile.json
[EV-PORT]: https://github.com/dwijayuda/pskernel/blob/93add6da4e501c57f9016c7c3666ea52c87a66e7/psc15selfhost/portable-selfhost-profile.json
[EV-STD]: https://github.com/dwijayuda/pskernel/blob/93add6da4e501c57f9016c7c3666ea52c87a66e7/psc15selfhost/docs/SELFHOST_SOURCE_STANDARD.md
[EV-STATUS]: https://github.com/dwijayuda/pskernel/blob/93add6da4e501c57f9016c7c3666ea52c87a66e7/psc15selfhost/STATUS.md
[EV-HOST]: https://github.com/dwijayuda/pskernel/blob/93add6da4e501c57f9016c7c3666ea52c87a66e7/psc15selfhost/scripts/compiler-checked-service.mjs
[EV-IR]: https://github.com/dwijayuda/pskernel/blob/93add6da4e501c57f9016c7c3666ea52c87a66e7/psc15selfhost/packages/compiler-ir/src/Ps/CompilerIr/Model.lean
[EV-WASM]: https://github.com/dwijayuda/pskernel/blob/93add6da4e501c57f9016c7c3666ea52c87a66e7/psc15selfhost/docs/BACKEND_ARCHITECTURE_RESEARCH_2026_10.md
[EV-M0]: https://github.com/dwijayuda/pskernel/pull/81
[EV-LEAN]: https://github.com/leanprover/lean4/tree/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler
[EV-LEAN-CM]: https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/CompilerM.lean
[EV-LEAN-PM]: https://github.com/leanprover/lean4/blob/470d5ce1400764999581fd26d5d72b00d990b0f4/src/Lean/Compiler/LCNF/PassManager.lean
[EV-REC]: https://lean-lang.org/doc/reference/latest/Definitions/Recursive-Definitions/
[EV-DO]: https://www.microsoft.com/en-us/research/publication/do-unchained-embracing-local-imperativity-in-a-purely-functional-language/
[EV-DO-CODE]: https://zenodo.org/records/6684085
[EV-RUST]: https://rustc-dev-guide.rust-lang.org/overview.html
[EV-RUST-BOOT]: https://rustc-dev-guide.rust-lang.org/building/bootstrapping/what-bootstrapping-does.html
[EV-RUST-MIR]: https://rustc-dev-guide.rust-lang.org/mir/passes.html
[EV-GO]: https://github.com/golang/go/blob/3b98eddbcd66230a78c4893f32099b5d3045a334/src/cmd/compile/README.md
[EV-GO-SPEC]: https://go.dev/ref/spec
[EV-COMPCERT]: https://compcert.org/man/manual001.html
[EV-COMP-TCB]: https://arxiv.org/abs/2201.10280
[EV-CAKEML]: https://cakeml.org/index.html
[EV-DAFNY]: https://dafny.org/latest/DafnyRef/DafnyRef.html
[EV-VERUS]: https://verus-lang.github.io/verus/guide/reference-exec-signature.html
[EV-WASM-CORE]: https://www.w3.org/TR/wasm-core/
[EV-WASM-VAL]: https://webassembly.github.io/spec/core/appendix/algorithm.html

---

**Final V3 design audit complete: 97/100 documented design traceability, with all implementation and experimental uncertainties preserved.**
