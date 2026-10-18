# Indexed matching with dependent majors and contexts

Source/kernel/emission positives passed preparation593a1bf/39082224478;
retained omitted-result regression is being corrected before integration. Reference: official Lean4.35.0
eb6cafb7290e8bd5f2937522d8d804f58f02bafc,
src/Lean/Meta/Tactic/Cases.lean (generalizeIndices', withNewEqs),
src/Lean/Meta/Tactic/UnifyEq.lean (heqToEq', unifyEq?),
src/Lean/Meta/Tactic/Subst.lean (substCore.tryToSkip),
and Init/Prelude.lean (HEq, eq_of_heq).
Native controls include the M3 fixedMajor example and corresponding new
fixed-context, compound-index and repeated-index definitions. Upstream cases
tests distinguish constructor elimination from unrelated general type splitting.

## Missing invariant

The constrained motive previously retained the original major but introduced
equalities only for its indices. That is enough for constant results, but cannot
refine a result or local value whose type mentions the major. Rejecting such
programs was honest but left a real native-compatible capability incomplete.

The motive now retains its original target/context and adds a final equality
between the generalized major and the original major, after the index equations.
Constraints use Eq when their actual types agree and HEq otherwise. Earlier
constraints align dependent index types and ultimately the major's family type.
Only then can checked eq_of_heq turn HEq into homogeneous equality.
The existing equality eliminator reverts dependent locals, specializes their
types and values, reopens them under fresh identities and transports the result
with Eq.rec. No in-place type mutation, free-variable cast, new axiom or unchecked
motive is introduced. All admitted proof terms still pass the official kernel.

The solver considers genuine free-variable substitutions before proof-irrelevant
conversion, matching native unifyEq?; distinct proof bindings may appear in
dependent types. Syntactically identical expressions retain the fast path. After checked
specialization, a definitionally unchanged complete target telescope skips an unnecessary
Eq.rec, following native substCore.tryToSkip; lexical alias refinement remains.
If preceding constraints cannot align heterogeneous types, elaboration refuses
rather than treating an HEq hypothesis as definitional equality.

## Validation

Extend the existing M3 inductive-match executable, not a separate broad suite:
fixed-major result, dependent hypothesis, compound and repeated indices,
impossible-case elimination, and a computational callback whose domain mentions
the fixed major. Preserve prior coverage, scope, group metadata, Prop-elimination,
induction and structural-recursion refusals. Missing actual HEq foundation is
also refused. All native oracles and portable declarations are kernel checked.

The five existing target paths gain one observer (two Bool inputs each);
required group-match runtime observations increase from40 to50, preserving all
old cases. Preparation builds/checks/emits this fixture. Main integration
executes readable JS, compiled TS, Rust, V8 GC core and Wasmtime components.
Successful emission alone is not execution or backend-preservation proof.

This belongs to M3 data/elimination and does not complete mutual WF, M4 or C5.

The omitted-result rfl regression exposed a stale-syntax check: a result
metavariable applied to the major looked dependent before branch elaboration,
even when its eventual assignment was constant. Transport elision now uses
final metavariable assignments and the existing read-only conversion, followed
by checking the reused term against the original target. Tests2552.lean and
substWithoutExpectedType.lean in the pinned source reinforce the reduction and
inference requirement. No Eq.rec rule or kernel equality is weakened.

Preparation fad13e51/39083140470 shows completed-type transport elision alone is
insufficient when result-family inference remains delayed beyond the branch.
The missing shared reducer capability is native K computation through a proof
whose type already agrees with the unique nullary constructor. See the
[K design](PSCV0_M3_K_REDUCTION_2026-10-18.md). The existing riFixedIndexEq
assertion remains unchanged; these changes have not yet qualified integration.
