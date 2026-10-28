# Actual List signatures: C1 model and continuation guideline

This component addresses the exact quantified-type rejection in the unchanged
21-member `Ps.Foundation.List` production packet. It is separate from public
admission. Compiler counts remain **1/124 fresh source closures Min-admitted,
1/124 with finite runtime validation, 0/124 fully compiler-qualified**; no
Min-backed G1/G2/G3 is qualified.

Status: scoped model and actual native/generated signature qualification passed
at candidate 34fe275f0d5a72fff150aa7b77fca0e97f716456. The [module guideline](PSC1_MIN_KERNEL_MODULE_GUIDELINE.md)
and [C1/C2/C3 completion contract](PSC1_MIN_KERNEL_USABILITY_PLAN.md) remain the
overall boundaries. Immutable candidate evidence is recorded below; adoption regression runs must
retain their separate source SHA and terminal status.

All project execution is GitHub Actions Linux, using the user's GPT-6.1 Sol /
High setting. Preserve the 10-minute model job, 20-minute actual-signature job,
256 MiB Node old-generation ceiling and 120-second public-check deadline.
Keep all earlier proof roots, Source's 525 cases and the unchanged 124-module
matrix. No public rule/profile/default, protected base or npm publication change.

## What is implemented

[RankOneTypes runtime](../packages/pskernel-min/src/Ps/MinKernel/Profile/RankOneTypes.lean)
implements a signature translator on the actual PsMinCoreExpr datatype.
Monotypes contain rigid variables, Nat/Bool/Unit, arrows, List/Option,
Except and Prod. Leading forall binders whose domain is exactly Sort 1 become
scheme parameters. A scheme is an arity and a monotype body; a scheme is never
an argument of a monotype constructor.

A context entry is some stable parameter level or a term-binder hole.
Leading type binders allocate levels 0, 1, 2, ...; each ordinary arrow inserts
a hole. A bound variable can become a type only if lookup reaches a parameter.
This handles annotations beneath arbitrary term binders and nested arrow types
without confusing their de Bruijn indices with the type-parameter indices.

psMinRankSignature starts from count zero and an empty context. Its successful
result has every type variable below the resulting scheme arity, without a
caller-supplied context-validity premise. Internal helper theorems state their
ContextWF premises explicitly.

Constants have exact builtin names and empty universe-instance lists.
Higher-rank/higher-kind types, nonleading type quantification, Sort 0/2
quantifiers, unknown nominal carriers, dependent term indices and wrong
constructor arities are outside this grammar. This is the observed List
signature fragment, not a replacement for the complete compiler type system.

## Constructive model and actual algorithm refinement

[The proof module](../proofs/pskernel-min/RankOneTypes.lean) interprets monotypes
in Type under an assignment of Type-valued rigid parameters.
Quantify and SchemeDenote live in Type 1. The terminal result uses ULift
explicitly; schemes cannot be inserted into the monotype grammar.
No Type-in-Type interpretation, unprovided set-theory interface or new axiom is
used.

Lookup, BaseImage, UnaryImage, BinaryImage, TypeImage and SchemeImage are
inductive grammars that do not call the executable signature parser.
The actual lookup and type/scheme workers refine those grammars.
The existing proved name/byte equality laws establish exact builtin identities.
Context bounds imply well-formed descriptors, including through term holes.

Denote commutes with code-level renaming and substitution; their well-formedness
laws preserve parameter bounds. These operations are on the new monotype
descriptors. They do **not** establish typed substitution of actual Core terms;
R8's syntactic Core substitution refinement remains a separate component.

The model proves both:

- SchemeDenote of forall alpha, alpha has no value: instantiate alpha with Empty.
- Polymorphic identity has a value, constructed directly.

The first scheme is a well-formed type and its signature can translate
successfully. It still has no possible declaration value. This is why a
successful signature translation must never become declaration acceptance.

[Trust reports](../proofs/pskernel-min/RankOneTypesTrust.lean) cover executable
translation/bounds, model laws and non-vacuity. Thirteen reports pass:
eleven exactly propext-only and two axiom-free. No sorryAx, choice, quotient
or new axiom is admitted. These reports do not assert a new kernel consistency
theorem: the new layer has no declaration admission function or body model.

## Actual compiler data and test boundaries

The input is a fresh actual production capture of Ps.Foundation.List, not a
rewritten or specialized List program. Its complete canonical packet has
21 declarations and 57195 bytes, SHA-256
`8a37e905d2ffb9d9309ff048802b63a10eba5bd591631cc6e5298307016c7609`.
The 21 signatures comprise twelve one-parameter, six two-parameter and three
three-parameter schemes. Public and generated recursive helpers are all retained.

The Linux driver recaptures the entire 124-module graph, runs the unchanged
public Min byte checks and Source runtime probes, then reads every actual List
signature from the fresh independent producer packet. Independent pinned Lean
replays the complete List packet, not just its types.

Native Lean and actual source-owned PSC1-generated JavaScript are compared
against source-level expected signatures for all 21 records. The expectation
table is test data and never reaches the parser or a public admission path.
The parser receives only a type expression and fuel; no module/declaration
name, source hash or whitelist grants it success.

The 100 observations are:

- 63 actual-signature cases: all 21 with full, zero and short fuel.
- 21 binder-name shadowing cases, preserving exact de Bruijn structure.
- 16 scope/kind/arity controls, including escaped variables, term holes,
  higher-rank/kind types, wrong universes and unknown carriers.

The native harness imports the exact new runtime source. Its untrusted JSON
adapter retains binder information and supported universe levels.
The generated path captures the full runtime source dependency closure through
the actual source-owned frontend, checks source/target/original-IR guards,
compiles strict TypeScript, and independently replays its complete runtime
admission packet with pinned Lean 4.35.0, commit
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`.

This is a proof of Lean-source signature-worker refinement plus finite generated
compatibility evidence. It is not a general theorem about the compiler or
JavaScript execution. Provider, semantic-contract and strict-Sh1 qualification
flags remain false. The JSON adapter is not a new proved exact-byte decoder.

## Public List refusal is preserved

No stable checker entry imports this layer. The same List packet still returns
PSC1_MIN_CORE_REFUSED through the unchanged public API, without delegation.
The public first refusal remains its quantified type binder; it has not moved
to a recursor because this experimental layer is not integrated.

The isolated type component now supplies an interpretation/refinement for that
signature subproblem. Connecting it requires a typed body model and its actual
checker refinement. Type well-formedness alone cannot justify accepting a
definition, an axiom or an opaque/partial body.

Source remains the sole fresh admitted compiler module and retains all 525
finite native/generated observations. Its actual structure-compiler preservation
is still open, so its full module qualification field remains false.

## Exact next body obligation

The first List declaration is psListLengthAcc.$psc0SH.0. Its actual body has
the following structure, with alpha and xs bound explicitly:

```text
Lambda alpha.
  lambda xs.
    List.rec alpha
      (fun _ => Nat -> Nat)
      (fun count => count)
      (fun _ _ recursive count => recursive (Nat.succ count))
      xs
```

The motive is constant in the list value and its result is a monotype function.
The next C1 implementation must bind type abstraction and typed term environments
to this actual body, prove the polymorphic constant-motive List.rec rules, and
refine the actual term checker. Continue against **all 21 original List members**,
not just a successful first prefix.

The full module additionally references Nat.rec, Except.rec, Prod.mk,
Bool.decEq, Eq and ite. Their actual instantiations, minors, primitive contracts
and conditional proof arguments need a constructive interpretation.
Inspect the captured motives/arguments; do not accept an arbitrary recursor or
erase proof/type arguments by shape alone.

Separate rigid parameter bindings from typed term bindings in the body context.
Prove weakening/instantiation and coherent global-scheme use at the actual
remaining fuel and source order. A successful declaration must construct a
semantic value in SchemeDenote, with a source derivation, rather than a merely
well-formed signature. Preserve fresh names and the complete global history.

There is a concrete additional integration requirement:
psMinCoreReservedRoots currently does not reserve Except or Prod, because the
stable profile does not give them these builtin meanings. The new type grammar
does. A future connected profile must establish their exact prelude bindings,
reserved-name and shadowing laws, along with family/constructor/recursor models.
Name recognition in this isolated grammar does not prove an actual global
environment contract. Keep stable R4B behavior separate; do not silently modify
its existing accepted programs or treat an implicit prelude as arbitrary axioms.

Before public admission, compose the typed body/history model with exact-byte
decoding and actual checker-state transitions. Validate all source members,
auxiliary records, names, binder tags, universes and declared bodies. Retain
the five partial-body obligations elsewhere in the compiler graph.
Only then query the complete fresh List packet through the public byte API.
No fallback, cached-hash acceptance or trusted producer flag may replace it.

C2 must still prove actual producer erasure, scope/instantiation, runtime
representation and emitted-target preservation. C3 still needs complete public
Min admission, actual Min-backed G1/G2/G3 and installed user flows.
Do not add to the full-module count from signature tests or theorem totals.
R9 remains parked until an eligible actual module exposes a relevant resource
blocker; the 57 KB List input is a semantic/model issue.

## Retained candidate failures

The first candidate's proof failed on reserved Lean identifiers and implicit
fallback-fuel elaboration. Renaming the identifiers, making fallback fuel
explicit and reverting context validity for induction preserved the statements.
The model then passed in Linux run 40732163530.

Run 40733172760 passed the model but failed the native main-project build:
CoreBytes.olean was absent because the complete runtime closure had not been
registered there. All six runtime roots are now explicit; the isolated proof
project already registered those dependencies.

Run 40734244818 passed the model, 124-module matrix and Source's 525 cases.
The actual PSC1 source frontend then rejected leading-dot constructor terms
in the new runtime file. Fully qualified constructor names replace that
unsupported shorthand. No compiler grammar expansion or native-frontend
fallback was used. These failed runs remain failed evidence and do not qualify
generated signature execution.

## Qualified candidate evidence

[Linux run 40735903282](https://github.com/dwijayuda/pskernel/actions/runs/40735903282)
is terminal success at 34fe275f0d5a72fff150aa7b77fca0e97f716456.
Model job 122984241627 and actual-signatures job 122985123930 passed.
The complete 100-case corpus has 45 successful descriptor results and 55
expected refusals. All 21 actual full-fuel signatures pass; no source/module
admission count advances.

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| Proof ZIP 12836129410 | 4993 | 1741dcf0daac14222f866a8c848dfc701fc2a951d66a5a22e08cc1c859e4a679 |
| Actual-signature ZIP 12835844683 | 3761104 | 7ce93c23ca342cb632d88749f927e8e9bcf20a2b15e6d22dd28816cb91c803b9 |
| Actual List source | 3160 | fded5488ec5b23135838048541792d71c6f3aae0040a558a05c68c05d1e01f1f |
| New signature runtime source | 4594 | abe59ade26ca891526f4794956be24c668e6650c45931550dae1de553c509939 |
| Generated TypeScript | 204798 | 347d48e83ae7ce5698bbf65f5d770d7bf82748c03991ea496527e64a81cf8ecd |
| Generated JavaScript | 215243 | bf07b009f50b4be9c7aebc98860a3525f148fdd794169e7c40bd64607f608273 |
| Type-runtime canonical packet | 772700 | 74b099760703ce58cdd4e6d8eb9be099d97ab52d5a8b4ab32788c28e86d53fb7 |
| Native observations | 17268 | d9cee45d1106e0b222e962d1cc87dbe0d025b2142b7093960e0d49784a7d832a |
| Exact input/expectation corpus | 270323 | 226d608f518e276bc3f35ccaa91ac96d879cdc71f12a19f8495a98bf9fba518b |

The candidate's six actual runtime modules total 42040 source bytes.
Source, target and original-IR guards passed; the runtime packet passed pinned
official replay. The new runtime is not added to U1's ten-module package.
It is not part of the 124 compiler-module denominator.

The candidate recapture preserves the same full compiler inventory identity,
one fresh Source admission and Source's 525 runtime checks. The extra actual
List public query also refuses without delegation. The 13 reports were
independently read from hash-verified CI artifacts and contain exactly the
allowed dependencies. Existing 259 reports are retained; adoption adds 13
printed reports, giving 272 (44 axiom-free, 228 propext-only) once all
adopted-source proof gates pass.

Do not add more type-only milestones unless an actual body-checker obligation
requires them. The next batch must construct typed source/body witnesses and
actual checker refinement for the retained List.rec path, then cover all 21
declarations and their primitive interfaces before connecting public admission.

## Efficient reuse of existing models

[RegularModel.Denote](../proofs/pskernel-min/RegularModel.lean) already interprets
type codes under a list of Type-valued carriers, and
[RegularSoundness](../proofs/pskernel-min/RegularSoundness.lean) provides typed
local/global models. Reuse those proof patterns and the actual-success-equation
construction of [OperationalSoundness.DefinitionHistory](../proofs/pskernel-min/OperationalSoundness.lean),
which records checked bodies rather than arbitrary inhabitants.

The operational entry currently fixes its world to dataModel specs, and
SignatureModel supplies constructor/recursor meanings for registered specs.
A rigid type parameter is not such a registered inductive family.
Keep the opaque parameter world separate from nominal data declarations and
prove any indexing/embedding/offset laws explicitly when generalizing the model.

Do not introduce a zero-constructor dummy group for each type variable.
That interprets a variable as an empty carrier instead of an arbitrary type.
Giving an arbitrary parameter the corresponding empty-family eliminator would
require elimination from arbitrary A into every result type; choosing Unit and
Empty shows why that cannot be supplied. Source parameters have no invented
constructors or recursors.

For the first List profile, a separate parametric term model over the existing
monotypes and explicit constructive List/Except/Prod/Nat/Bool interfaces is
smaller than immediately rebuilding the entire dependent/universe kernel.
Preserve source/core/term roles and the exact prelude bindings. Generalize the
regular nominal registry only when an actual subsequent module requires it.
A code-level type interpretation is not enough to justify that generalization.

## Recursor motives are not ordinary rank-one term parameters

The captured List.rec call supplies a type-valued lambda,
fun (_ : List alpha) => Nat -> Nat, as its motive.
That is a family of types; it is not an ordinary monotype arrow whose codomain
can be filled with a fictitious code for Type in the same universe.

For the next body checker, recognize the actual constant-motive application
spine, reconstruct the element/result monotypes, validate the motive annotation
and binder scope, and prove the nil/cons/major rules and fold meaning.
Do not pretend the full dependent recursor is an ordinary first-class value of
the new rank-one signature grammar. Bare/partial or genuinely dependent
recursor use needs its own explicitly proved scope.

Apply the same discipline to the captured Nat.rec and Except.rec instances.
The header model does not authorize erasing motive/proof arguments or supplying
unproved source interfaces. Existing constant-motive proof patterns may be
generalized only with the actual parameter and term-role contexts preserved.

## Terminal adopted-source checkpoint

All selected workflows are terminal success at adopted source
`8df57b4f35f9873909e0d1fc3b9ca41dbba6441a`:

- [C1 model/signatures 40738340034](https://github.com/dwijayuda/pskernel/actions/runs/40738340034):
  model 122992856531 and actual-signatures 122994557515 passed.
- [Module matrix 40738340020](https://github.com/dwijayuda/pskernel/actions/runs/40738340020):
  the actual graph/frontier and unchanged counts passed.
- [Focused proof/runtime/package 40738339912](https://github.com/dwijayuda/pskernel/actions/runs/40738339912):
  proof 122992857366, preservation 122992856879 and portability 122994499625 passed.
- [Broader Linux 40738349461](https://github.com/dwijayuda/pskernel/actions/runs/40738349461):
  full/linux-scoped 123001504503 and final gate 123017955237 passed;
  benchmark was unselected/skipped.
- [Installed CLI 40738340085](https://github.com/dwijayuda/pskernel/actions/runs/40738340085):
  preflight 122992857313 and installed 122993712809 passed.

Adopted type artifact 12839201321 is 3760942 bytes, SHA-256
`0032418a311394bdf5dc9bc411e6986358a926d00da39eb161729bcec98aad49`.
Adopted model artifact 12838412097 is 4983 bytes, SHA-256
`aadc8077e24305edf7fc368123daa6f3015b9ce09513caa07ff0e01ea68edb2a`.
Their type-runtime TS/JS/canonical/input/observation identities exactly match
the qualified candidate. All 21 signatures / 100 observations pass again.

The complete adopted focused artifacts were hash-verified and their reports
deduplicated, including the global psMinCoreEncode report: 272 unique printed
reports, 44 axiom-free and 228 propext-only; no prior report is missing and no
other assumptions appear. This audit retains declarations as well as theorems;
it is not a proof-count measure of compiler qualification.

The private U1 regression package passes all 52 SDK cases, seven hostile
controls, offline installs and complete-runtime API/CLI checks. It still has
ten source modules / 103181 source bytes, and kernel.js is byte-identical:
SHA-256 `2cfe8dd6564b7ec6e968841c1ef43b01897d7ca5303095eb2b8c9b48dd27ded3`.
The current metadata-bearing tarball is 42242 bytes, SHA-256
`e9be81ba4c35701fa432aa1477dbabcbe538762dc0a5d812d4043d131201e47a`.
It does not replace or relabel the original U1 deliverable; no npm publication
occurred.

The [dated receipt](PSC1_MIN_KERNEL_LIST_TYPE_QUALIFICATION_2026-10-29.json)
retains source/run/artifact identities and the incomplete overall-goal status.
This final reporting update changes Markdown/JSON only. Project proofs,
compilation, tests and measurements ran exclusively on GitHub Actions Linux;
local operations were read-only artifact parsing, hashing and deliverable export.

**No additional compiler module is admitted by this component.** The stopping
boundary is the unresolved typed body/recursor/history model and its actual
checker refinement, followed by public-byte integration. Source C2 and all
Min-backed self-hosting generations remain unqualified.
