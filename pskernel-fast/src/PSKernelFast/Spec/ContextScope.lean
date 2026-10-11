import PSKernelFast.CoreSyntaxProofs

/-!
P0 independent structural context semantics. This module does NOT import
GeneralPiFormation, the executing checker, its caches or source-rule
witnesses. It states an immutable, binder-indexed mathematical invariant,
not set-theoretic denotational soundness or proof admission.

The oldest domain is scoped in the empty context; each later domain is
scoped in its parent context at the depth where it was introduced.
-/

namespace PSKernelFast.Spec

open PSKernelFast.Core

/--
A context in newest-first de Bruijn order: each stored binder domain is
structurally scoped at the exact parent-context depth of its introduction.
This predicate is independent of the checker and independent of a runtime
container, cache or hash-consed handle.
-/
inductive ContextScoped (params : List KName) : List KExpr → Prop where
  | empty : ContextScoped params []
  | extend {ctx : List KExpr} {domain : KExpr}
      (parent : ContextScoped params ctx)
      (domainValid : KExpr.StructurallyValid params ctx.length domain) :
      ContextScoped params (domain :: ctx)

/--
A successful lookup at index `i` retrieves a domain valid in the ORIGINAL
context at depth `ctx.length - (i + 1)`. Index bounds are not assumed.
-/
theorem ContextScoped.lookup_scoped (params : List KName)
    {ctx : List KExpr} (scoped : ContextScoped params ctx)
    (index : Nat) (domain : KExpr) (lookup : ctx[index]? = some domain) :
    index < ctx.length ∧
      KExpr.StructurallyValid params (ctx.length - (index + 1)) domain := by
  induction scoped generalizing index domain with
  | empty =>
      simp at lookup
  | @extend prior stored priorScoped valid ih =>
      cases index with
      | zero =>
          have storedEq : stored = domain := by
            simpa using lookup
          subst domain
          constructor
          · simp
          · simpa using valid
      | succ older =>
          have parentLookup : prior[older]? = some domain := by
            simpa using lookup
          obtain ⟨hIndex, hDomain⟩ := ih older domain parentLookup
          constructor
          · simp only [List.length_cons]
            omega
          · have hDepth :
                (prior.length + 1) - (older + 1 + 1) =
                  prior.length - (older + 1) := by omega
            simpa only [List.length_cons, hDepth] using hDomain

end PSKernelFast.Spec
