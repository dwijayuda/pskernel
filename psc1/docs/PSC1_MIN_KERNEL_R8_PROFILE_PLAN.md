# R8 independent substitution and caller source semantics

Status: proposed proof batch; not qualified until GitHub Actions Linux passes.
Parent candidate: cff0d8f9fc02662ccff8fd74fa56492a2d2044ee (R7).
This is one component of C2 in [the usability contract](PSC1_MIN_KERNEL_USABILITY_PLAN.md).
Full compiler support remains open.

Define capture-avoiding lifting and single substitution as inductive relations,
using mathematical comparisons on de Bruijn indices. The relation definitions
do not call the Core lift/instantiate functions. Cover all eleven PsExpr
constructors, including under lambda, forall and let binders and projections.

Prove constructive totality, exact correspondence with the actual
psExprLiftBVarsWorker / psExprInstantiateAtWorker, and uniqueness. Connect the
public psExprInstantiate1 wrapper. Then define literal/zeta evaluation using
the independent substitution relation, prove equivalence to R7's source
relation, and compose it with the real recursive worker and public/default
entry theorem under R7's unchanged eligibility premises.

This establishes syntactic refinement to an explicitly stated capture-avoiding
relation. It does not prove well-typed substitution, type/proof classifier
soundness, runtime lets/variables/calls, freshness, closures, full compiler
preservation, target engine correctness or compiler admission. The pure zeta
relation does not evaluate erased values and is not a full call-by-value language.

Register an explicit proof root and print fourteen unique dependency reports.
Allow only no axioms or exactly propext. Preserve all existing R0-R7 checks,
job budgets, runtime byte limits and production refusal/default behavior.
Runtime source modules do not change; this batch does not increase admitted
compiler coverage. Reuse all existing native/generated and package regressions.
No local proof/build/test execution.
