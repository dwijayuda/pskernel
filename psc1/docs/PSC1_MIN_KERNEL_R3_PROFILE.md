# PSC1 MinKernel R3 operational profile

Status: standalone qualified at `695c68701437899b17a39205300cf26988322b15`,
[Linux 40486405765](https://github.com/dwijayuda/pskernel/actions/runs/40486405765).
Proof/native 122129166896 and portability/census 122129166670 are terminal success.
All 26 reports are 13 no axioms and 13 exactly propext.
This is the normalized operational batch following qualified R2. It does not
complete canonical ingress or runtime self-check.

## Runtime and precise acceptance domain

R2 runtime and proof sources are preserved. OperationalProfile.lean imports the
actual RegularCheck source; OperationalCheck.lean adds a recursive operational
term language and sequential declaration checking. The complete explicit checker
closure has four modules, 518 source lines and 22339 UTF-8 bytes. The two new
modules have 211 lines/10071 bytes. Proof modules import the runtime in place.

Terms are an embedded R2 expression, annotated lambda/application, annotated let,
a descriptor-derived projection function, or a closed primitive-schema request.
An embedded R2 expression is checked by the actual R2 inference function with
the remaining fuel and the same constant/local contexts.

A let validates its annotation, checks the value in the original local context,
checks exact structural type equality, and checks the body under the extended
context. The new binder is unavailable in the value. Type codes contain no
term-level dependencies, so no unproved substitution or dependent conversion
is hidden in this rule.

Projection signatures come from the selected registry slot and field position.
Only a family with exactly one constructor can project. Field types use the
actual R2 ground/self interpretation and older-slot lifting; the whole function
signature lifts when looking up an older registry entry. Wrong owners, fields,
major types, empty families and multi-constructor families refuse. Source names
and compiler-origin metadata grant no projection authority.

Primitive requests derive a signature from the schema. The request's universe
instance/type-argument count/index/motive/minor metadata must match, and every
supplied type code must pass the real scope/fuel validator. There is no
caller-supplied primitive type.

## Selected primitive family

The direct schemas cover Nat successor/addition/subtraction/equality/less-than,
fixed-result Nat recursion, monomorphic List nil/cons/recursion, and Option
none/some/recursion. Result and element codes may be any closed code in the
current registry, including arrows and earlier modeled data.

boolEqIte takes two Bool values and two branches of one closed result type. Its
meaning is exactly ite with proposition Eq Bool left right and decision
Bool.decEq left right. The same pair supplies both proposition and decision by
construction. Arbitrary proof/decision terms are not erased or accepted. Bare
polymorphic Eq, Decidable.rec or arbitrary ite applications are outside this
normalized grammar; R4 must prove exact matching before translating them.

Nat predecessor, Boolean negation and Boolean equality are derived schemas.
Their laws reduce to Nat.rec or the checked Bool-equality conditional. They are
not arbitrary additional canonical primitive names; absent canonical heads must
not be invented by an ingress adapter.

The CI contract set covers 29 exact source-owned foundation declarations:
Nat and its constructors/recursor/selected arithmetic, Bool and its two values,
Unit and its value, Eq/Bool.decEq, List/Option with constructors/recursors,
Decidable with its two constructors/recursor, _psc1OrderFalse, and the actual
constructive ite definition. Structured names, level-parameter identities, full
types, values and metadata are compared with the fresh exported prelude.

The model covers restricted closed instances. Contract equality alone is not a
theorem for every unrestricted dependent application of these declarations.

These comparisons are diagnostic CI checks of selected primitive contracts,
not a source/hash whitelist granting runtime authority. The complete prelude
still has 115 declarations/60 axioms; it is not wholly modeled or pruned here.

## Concrete model and computation equations

OperationalProjection extracts the actual heterogeneous constructor fields from
R2's concrete finite-branching tree carrier. Its projectionModel consumes the
successful executable projection-signature equation. Generic getter iota covers
arbitrary single-constructor field lists; the strengthened theorem connects
that law to the actual typed projectionModel used by inference.

OperationalFoundation assigns concrete host values to every schema. Fixed-result
Nat/List/Option iota equations are proved. Boolean conditionals use typed,
constructive Decidable branches; no classical decision oracle is introduced.

OperationalSource imports the actual source-owned Environment.Order. Two native
Lean theorems identify psOrderIteDeclaration and psOrderDecisionRecDeclaration
with their full expected ASTs. decisionBody_eq_ite models the exact two-minor
Decidable.rec body for every proposition and supplied decision, then
source_boolEqIte connects the Bool instance to the primitive model.

OperationalSoundness follows every actual psMinOpInfer success case. The final
operational_hasModel and operational_consistent capstones construct a model
from an empty constant context and forbid inferring the Empty code from a
successfully checked environment. They assume no arbitrary foundation model.
The Empty code denotes host Empty, not an automatic identification with every
canonical proposition named False.

DefinitionHistory records each actual declaration body, its inference/equality
equations, and the interpreted value inserted into the constant model. The
admission fold returns this history with the model. checked_definition_unfold
states that the actual constant interpreter returns the interpretation of its
checked body; previous constants preserve their earlier meanings.

Conversion remains structural equality of closed type codes. conversion_model
derives equality of interpretations from the real equality check. No general
beta/delta type-conversion engine, dependent aliases or arbitrary definition
unfolding has been added. The checked-body invariant is a prerequisite for later
conversion work, not a proof of unrestricted Core conversion.

## Corpus and execution boundary

The corpus contains 36 positives, 40 refusals and two out-of-range probes.
It covers nested lets and binder scope, every actual R2 Spec/Declaration field
shape and position, constructed records and wrong-owner projection, the selected
primitive schemas, altered minor order/type, wrong branch/major types, forged
metadata, forward references, and fuel exhaustion.

Its ordered registry fixtures reproduce the field shapes of PsMinRegTy,
PsMinRegField, PsMinRegSpec, PsMinRegTerm and PsMinRegDeclaration. The runtime
checks the general descriptor class; these fixtures do not authorize acceptance
by name, hash, record position or expected result.

Native Lean and actual PSC1-generated JavaScript execute the same checker
acceptance/refusal corpus on GitHub Actions Linux. Official Lean independently
admits the entire five-module source/test graph. This is finite execution/source
qualification, not a compiler-preservation theorem. Semantic computation laws
are Lean proofs; the checker corpus does not claim to execute a new object-language
interpreter.

The full emitted bundle includes test/shared runtime code. Runtime/test/proof
identities, bundle sizes, admissions and source-origin hashes, axiom reports,
exact workflow/job/artifact outcomes and development failures belong in the
dated R3 receipt. No local build, proof check, compiler execution or test is
part of this batch; local work only drafts text and parses retained CI data.

## R4 handoff and remaining boundaries

Canonical min/dual still return PSC1_MIN_CANONICAL_BRIDGE_UNPROVED. Official Lean
Wasm remains the production default. Full compiler min coverage remains 0/124
modules and 0/37 Practical Core; no min-checked G1/G2/G3 is qualified.

R4 must compose bounded exact bytes-to-AST decoding, source-name/slot binding,
profile recognition/translation and actual operational checker success. It must
check the exact Eq proposition and Bool.decEq operands before building boolEqIte,
not erase a decision/proof argument. Bind datatype/constructor/recursor/projection
identities through validated environments and freshness, not spelling or compiler
origin. Preserve names, levels, bodies, order and generated members.

The original Check-only 12-record target and R2's 37-record diagnostic do not
describe this enlarged four-module checker. Remeasure its complete connected
R1/R2/R3/naming/ingress implementation and foundation before claiming self-check.
The Name/codec closure still introduces String/Char operations outside these
type codes. Add required concrete semantics or prove a representation translation.

No general raw-Core translator or byte decoder is proved in R3. The normalized
success-to-model theorem and exact primitive-body results are completed at
their stated boundary; raw-input preservation, generated execution refinement
and hostile-object/aggregate heap/stack limits remain R4 obligations. Until
those paths are proved and qualified, preserve canonical refusal.

## Exact standalone identities

The five-module source/test bundle has 42728 UTF-8 B; generated TS is 134690 B
and JS is 318436 B, including shared runtime and harness. JS SHA256:
`48f0437d9d7c52b86d718e79a01e0943075ec1e23b557ef81113af4581e98bc2`.
Canonical source-admission SHA256:
`c926de2d6ff04426503f5b59f16551d7916000e00a56c33512174cd01f662a3b`.
Official Lean 4.35.0 pin:
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.

Proof artifact 12724778716 is 3716 B; GitHub-reported ZIP digest
`ae9e8e3558e36d086ee3b9b74ed41a3e4c6a5bee08c3dfe55cc3d59acecd9c22`.
Portability/closure artifact 12724978933 is 1644479 B; GitHub-reported ZIP digest
`fcbcd1642f50b7f6dfdbca02605eeec2bff75a3e457db8fad1a788f1ea6d6e63`.
The dated receipt retains exact source/proof/harness/driver identities and failed
development attempts. Only terminal passing runs qualify repairs.

Historical broader snapshot at 2026-10-27 10:14 UTC: main 40486414934 and
installed 40483267987 were in progress. A reporting push may supersede main.
Query live PR checks before claiming terminal broader qualification.
