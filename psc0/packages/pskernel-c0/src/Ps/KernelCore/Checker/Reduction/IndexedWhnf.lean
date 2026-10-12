import Ps.KernelCore.Core.IndexedReduction

/-
Experimental Lean-native head reduction on canonical indexed expressions.

This is the second half of the indexed execution architecture:
  * TermStore represents shared immutable expression nodes.
  * IndexedReduction handles capture-avoiding beta/zeta substitution.
  * IndexedWhnf traverses application spines without materializing raw Exprs.

Only context-free beta, zeta, metadata erasure and application-spine assembly
are implemented. This is NOT the trusted WHNF entry point: constants,
recursors, quotient, projection, native reduction and resource-policy
compatibility still belong to the existing production checker.

A caller supplies fuel explicitly. Fuel exhaustion fails closed.
-/

def psKernelC0IndexedApplySpine
    (store : PsKernelC0TermStore)
    (fn : Nat)
    (args : List Nat) :
    Option (Prod PsKernelC0TermStore Nat) :=
  match args with
  | [] => some (store, fn)
  | arg :: rest => do
      let (next, applied) ← psKernelC0Intern store (.app fn arg)
      psKernelC0IndexedApplySpine next applied rest

/--
  Indexed WHNF with an explicit unchanged-spine fast path.

  A stuck application head can only preserve its original handle if no
  metadata erasure, zeta reduction or beta reduction happened during the head
  traversal. This does not infer definitional equality from handle identity
  across stores: the original handle is returned only within the same store.
-/
def psKernelC0IndexedWhnfMachine
    (fuel : Nat)
    (store : PsKernelC0TermStore)
    (id : Nat)
    (args : List Nat)
    (original : Nat)
    (changed : Bool) :
    Option (Prod PsKernelC0TermStore Nat) :=
  match fuel with
  | 0 => none
  | remaining + 1 => do
      let stored ← psKernelC0StoreGet store id
      match stored.node with
      | .app fn arg =>
          psKernelC0IndexedWhnfMachine remaining store fn (arg :: args)
            original changed
      | .mdata _ body =>
          psKernelC0IndexedWhnfMachine remaining store body args
            original true
      | .letE _ _ value body _ => do
          let (next, opened) ← psKernelC0Instantiate1Indexed store body value
          psKernelC0IndexedWhnfMachine remaining next opened args
            original true
      | .lam _ _ body _ =>
          match args with
          | [] => some (store, id)
          | arg :: rest => do
              let (next, opened) ← psKernelC0Instantiate1Indexed store body arg
              psKernelC0IndexedWhnfMachine remaining next opened rest
                original true
      | _ =>
          if changed then
            psKernelC0IndexedApplySpine store id args
          else
            some (store, original)

/-- Demand-driven WHNF; args are earliest/innermost-first. -/
def psKernelC0IndexedWhnfWithFuel
    (fuel : Nat)
    (store : PsKernelC0TermStore)
    (id : Nat)
    (args : List Nat) :
    Option (Prod PsKernelC0TermStore Nat) :=
  psKernelC0IndexedWhnfMachine fuel store id args id (!args.isEmpty)

/--
  Exact fuel-bound fragment normalization. No interpretation of kernel
  declarations or proof terms; never use it for checked admission.
-/
def psKernelC0IndexedWhnf
    (fuel : Nat)
    (store : PsKernelC0TermStore)
    (id : Nat) :
    Option (Prod PsKernelC0TermStore Nat) :=
  psKernelC0IndexedWhnfWithFuel fuel store id []
