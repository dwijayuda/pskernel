# PSCV Self-Host Portable — Evidence-Audited Language Profile and Four-Backend Bootstrap

**Edition:** Research and architecture revision V3, 2026-10-08  
**Proposed source profile:** `PSCV-selfhost-portable/2` — *not yet formally adopted or implemented*  
**Destination:** `dwijayuda/pskernel/PSCV_SELFHOST_PORTABLE.md` on `main`  
**Source of truth for current execution state:** `pscv/v3-execution`, inspected commit `93add6da4e501c57f9016c7c3666ea52c87a66e7`  
**Lean semantic reference:** `4.35.0-rc3` / `470d5ce1400764999581fd26d5d72b00d990b0f4`; existing bootstrap `4.34.0` / `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`  
**Status:** design research with source-backed decisions and falsifiable implementation gates, **not** a proof of compiler correctness, backend self-host closure, measured AI proof speed, or a PSCV verified executable.  
**Audit state:** *Iteration 1 (94/100 design traceability, provisional); a later appendix will contain the independent final audit and any corrected score.*  

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

## 10. Reference link ledger

[EV-NORM]: https://github.com/dwijayuda/pskernel/blob/93add6da4e501c57f9016c7c3666ea52c87a66e7/psc15selfhost/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md
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

**Iteration 1 draft complete. The evidence-audit rubric and final 97-point check follow in the next revision; this draft makes no 97+ quality claim.**
