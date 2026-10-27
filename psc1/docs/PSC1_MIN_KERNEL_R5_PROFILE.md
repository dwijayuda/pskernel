# PSC1 MinKernel R5 compiler-stage preservation profile

Status: implementation and Linux qualification pending. Continuation setting:
GPT-6.1 Sol / High. Starting remote HEAD:
`1ebdb825b05abdb7f6cc960d16b7d5ba41b75f5b`.
Read [R4's qualified boundary](PSC1_MIN_KERNEL_R4_GUIDELINE.md) first.
All proofs, builds, compiler execution and tests run on GitHub Actions Linux. A separate 10-minute compiler-preservation job checks the proof and native fixture before the unchanged 20-minute portability job.

## Selected batch and proof obligations

R4 proved native source-model consistency and executed the complete connected
checker through PSC1-generated JavaScript. It did not prove the compiler correct.
R5 begins compiler preservation with the actual application-capture/currying
sub-stage in Ps.Erasure.Expr and the selected scalar primitive emitter in
Ps.BackendTs.Expr. These are production compiler functions, imported
directly into the separate proof library, with no copied executable implementation. The former local binary lowering body is extracted into psEraseBinaryIntrinsicApplication and the actual recognizer calls it.

The independent scalar IR semantics covers Nat, Bool and Unit values, lexical
name lookup, lets, conditionals, ten binary operations and Bool.not. Unsupported
IR has no evaluation derivation. Capture histories interpret the actual reverse
accumulator in chronological order. Prove both directions between actual
psErasureWrapApplicationCaptures evaluation and that independent history.
Shadowing is explicit and arbitrary capture lengths are covered.

A separate exact-argument Invoke relation defines the curried single-argument
ABI. Prove actual psErasureCurryParameters corresponds to sequential lexical
binding for arbitrary parameter lists and matching argument lists. The composed capstone interprets actual capture lets around the actual curried expression through CapturedInvoke, rather than merely returning two unrelated witnesses. The theorem concerns scalar-result bodies; it does not cover arbitrary higher-order effects
or prove the emitter's generator scheduler.

For Nat add/sub/mul/div/mod/beq/ble/blt and Bool.and/or, prove the actual shared binary lowering stage emits the independently specified operation when its two recursive
operand erasures succeed. Compose with independent operand values and arithmetic
meaning. This is a local compositional erasure theorem: it does not establish that
the complete recursive eraser supplies those operand premises or selects this branch for every source term. In particular, source-name dispatch uses opaque bootstrap String.Internal functions and is not proved by these stage equations. Under/overapplication refuses.

Prove exact actual token-composition correspondence and arity refusal for all ten
operations, and the Nat/Bool/Unit literal ABI. The independent templates specify token lists under the existing opaque psTsJoin operation. Neither character-level concatenation nor decimal rendering is proved here. They are not a formal JavaScript parser or an ECMAScript engine model.

Every new theorem must print a unique dependency report containing no axioms or
exactly propext. Existing R0–R4 guards, 10/20-minute timeouts, 256 MiB old-space
limits and refusal rules stay in force. The proof-only library is an explicit
Lake root outside the kernel/runtime and compiler self-host import graphs.

## Integration and execution obligations

The host-only Linux driver uses actual erasure/currying and expression-emission
functions to produce direct TypeScript. Native mathematical oracles are compared
with strict-TSC-compiled JavaScript on 400 scalar cases, including zero divisors,
saturating subtraction, the 2^53 boundary and naturals beyond the 256-bit boundary. Actual emitted
operand instrumentation records single evaluation and left/right order for the
eight Nat operators, and the expected Boolean short-circuit behavior separately.
This finite observation does not establish effectful-IR preservation.

Actual capture ordering, currying and shadowing expressions execute in Node.
A separate registered test-only source fixture passes the actual atomic SH/1 source API,
original IR check and target check, then independent official admission and the
existing generated R4B exact-byte API. The exact original IR, structured origins and emitted artifacts are retained from that same computation. Its generated functions exercise computed
partial application, lexical closures and scalar operations over 294 calls compared with native execution of the exact same physical source file.
Negative original IR must fail the actual checked-emission boundary.

Repeat the complete current compiler admission census, all earlier R0–R4 tests,
and full connected ten-module R4 checker self-admission. R5 introduces a separate test fixture but no new executable minimal-kernel runtime module: the connected runtime remains ten modules,
rather than incorporating proof/host harness sources into its census.

## Preservation and trust ledger

| Boundary | R5 obligation or retained status |
| --- | --- |
| Original canonical bytes to source model | R4 theorem and full-runtime execution retained |
| Source frontend/elaboration | Actual checked source path tested; general preservation open |
| Foundation and recursive erasure dispatch | R4 native models; whole compiler bridge open |
| Capture let wrapping and parameter currying | General theorem over actual functions and declared scalar semantics |
| Selected primitive erasure | Compositional theorem with explicit recursive operand premises |
| Scalar emitter templates and literal ABI | Exact text equations; engine behavior tested finitely |
| Records/tags/List/Option/regular recursors/projections | Existing R4 finite generated evidence; general representation proof open |
| Generator stack/tail driver | Existing runtime; semantic simulation proof open |
| TypeScript-to-JavaScript and Node/BigInt | Explicit unproved toolchain/engine boundary |
| Host Uint8Array/JSON/generated factory | Existing R4 tested/trusted host ABI; no JS security theorem |
| Complete compiler graph/min G1/G2/G3 | Fresh census required; no new minimal qualification from these sub-stage proofs |

The [ECMAScript BigInt specification](https://tc39.es/ecma262/multipage/ecmascript-data-types-and-values.html#sec-ecmascript-language-types-bigint-type)
and [logical evaluation rules](https://tc39.es/ecma262/multipage/ecmascript-language-expressions.html#sec-binary-logical-operators-runtime-semantics-evaluation)
supply the intended host contracts; they are external specifications, not imported
theorems. In particular, arbitrary effectful operands cannot be justified from a
pure scalar model when the target uses short-circuit Boolean operators.

## Promotion and completion criteria

Production official Lean Wasm remains default; min/dual continue to refuse
PSC1_MIN_CANONICAL_BRIDGE_UNPROVED. No fallback, whitelist, merge or npm publish.
Do not call this batch whole-compiler soundness, full Lean conformance, compiler
self-hosting or release assurance. Full minimal compiler/Practical Core coverage
and min-qualified G1/G2/G3 remain separate until their actual obligations pass.

R5 completes only when every new printed report passes the unchanged axiom guard,
the declared native/generated and negative tests pass, fresh census and connected
self-admission pass, selected broader regressions are terminal, and immutable
source/run/job/artifact identities are recorded. A final reporting-only commit
then receives its own selected checks. Preserve all earlier history and use
one-parent, nonforce expected-HEAD updates.

## Next preservation batches

The capstones above leave explicit composition obligations. A next batch must
relate actual recursive Core erasure to the source semantics, establish erased
type/proof telescope invariants and prove capture-name freshness prevents
interference with existing locals. Extend the value model to closures, calls
and regular data before claiming higher-order or recursor preservation.

Record/tag/field and nominal carrier representations then need an exact
connection to the emitted constructor/projection/match syntax. The current
generator protocol needs a simulation covering both continuation-preserving
requests and complete-result tail requests, including repeated invocations.
Finally connect the proved target syntax to the actual emitted text, and state
the TypeScript transformation and ECMAScript implementation assumptions.

These steps are general mechanisms. A successful finite source packet,
IR-typing report, nominal module-origin census or bundle hash cannot replace
them. Compiler admission coverage also remains a different obligation from
compiler-stage semantic preservation.

## Pinned bootstrap string boundary

Inspection of [Lean's pinned String bootstrap declarations](https://github.com/leanprover/lean4/blob/eb6cafb7290e8bd5f2937522d8d804f58f02bafc/src/Init/Data/String/Bootstrap.lean)
shows String.Internal.append, length, get, next and atEnd are opaque externs.
The compiler's name-to-text dispatch and emitted text composition use them.
They have executable implementations, but the corresponding character equations
are unavailable to the kernel merely by reduction. The first R5 attempt correctly
failed when it treated those equations as definitional. No new axiom, native_decide
bridge or arbitrary string-model premise is added to make that attempt pass.

The source code now exposes the pure binary lowering body as a shared function,
and the source recognizer calls it. Its stage proof is unconditional with respect
to names/strings. Exact emitter equations retain the original opaque token join;
literal Nat equations retain opaque append and psNatToString. Actual native and
generated text behavior remains independently tested, with string/numeral
semantics and source-name dispatch listed as open composition obligations.
