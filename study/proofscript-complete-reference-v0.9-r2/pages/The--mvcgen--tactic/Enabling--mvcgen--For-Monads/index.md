<a id="The-Lean-Language-Reference--The--mvcgen--tactic--Enabling--mvcgen--For-Monads"></a>

# ProofScript — 17.4. Enabling mvcgen For Monads

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Verification-condition generation connects a computation to a program-logic specification. Predicate transformers, state/error behavior, supported monads and loop interfaces are part of that connection. The final proof must establish the approved property of the actual computation, not merely prove unrelated obligations emitted by a buggy generator. Intrinsic contracts are experimental at the selected pin.

**Compiler and coverage boundary.** Keep the native requires/ensures grammar, generated theorem identities, residual proof sections and assumption reports. The inherited example uses native spelling intentionally; it is already an L-class ProofScript form.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [The--mvcgen--tactic/Enabling--mvcgen--For-Monads/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/The--mvcgen--tactic/Enabling--mvcgen--For-Monads/index.html). Source Git blob: `646c5b795c2aea8ef1f8a93975ce2854daaf264a`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 17.4. Enabling mvcgen For Monads

If a monad is implemented in terms of [monad transformers](../../Functors___-Monads-and--do--Notation/Varieties-of-Monads/index.md#--tech-term-monad-transformer) that are provided by the Lean standard library, such as `ExceptT` and `StateT`, then it should not require additional instances. Other monads will require instances of `WP`, `LawfulMonad`, and `WPMonad`. The tactic has been designed to support monads that model single-threaded control with state that might be interrupted; in other words, the effects that are present in ordinary imperative programming. More exotic effects have not yet been investigated.

Once the basic instances are provided, the next step is to prove an [adequacy lemma](../Predicate-Transformers/index.md#mvcgen-adequacy). This lemma should show that the weakest precondition for running the monadic computation and asserting a desired predicate is in fact sufficient to prove the predicate.

In addition to the definition of the monad, typical libraries provide a set of primitive operators. Each of these should be provided with a [specification lemma](../Predicate-Transformers/index.md#--tech-term-Specification-lemmas). It may additionally be useful to make the internals of the state private, and export a carefully-designed set of assertion operators.

The specification lemmas for the library's primitive operators should ideally be precise specifications of the operators as predicate transformers. While it's often easier to think in terms of how the operator transforms an input state into an output state, [verification condition](../Overview/index.md#--tech-term-verification-conditions) generation will work more reliably when postconditions are completely free. This allows automation to instantiate the postcondition with the exact precondition of the next statement, rather than needing to show an entailment. In other words, specifications that specify the precondition as a function of the postcondition work better in practice than specifications that merely relate the pre- and postconditions.

<a id="Schematic-Postconditions"></a>
Schematic Postconditions 

The function `double` doubles a natural number state:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="double-_LPAR_in-Schematic-Postconditions_RPAR_"></a>


```proofscript
const double : StateM Nat Unit := do
  modify (2 * ·)
```

Thinking chronologically, a reasonable specification is that value of the output state is twice that of the input state. This is expressed using a schematic variable that stands for the initial state:
<a id="double_spec-_LPAR_in-Schematic-Postconditions_RPAR_"></a>


```proofscript
theorem double_spec :
    ⦃ fun s => ⌜s = n⌝ ⦄ double ⦃ ⇓ () s => ⌜s = 2 * n⌝ ⦄ := by
  simp [double]
  mvcgen with grind
```

However, an equivalent specification that treats the postcondition schematically will lead to smaller verification conditions when `double` is used in other functions:
<a id="better_double_spec-_LPAR_in-Schematic-Postconditions_RPAR_"></a>


```proofscript
@[spec]
theorem better_double_spec {Q : PostCond Unit (.arg Nat .pure)} :
    ⦃ fun s => Q.1 () (2 * s) ⦄ double ⦃ Q ⦄ := by
  simp [double]
  mvcgen with grind
```

The first projection of the postcondition is its stateful assertion. Now, the precondition merely states that the postcondition should hold for double the initial state.

<a id="A-Logging-Monad"></a>
A Logging Monad 

The monad `LogM` maintains an append-only log during a computation:
<a id="LogM-_LPAR_in-A-Logging-Monad_RPAR_"></a>
<a id="LogM___log-_LPAR_in-A-Logging-Monad_RPAR_"></a>
<a id="LogM___value-_LPAR_in-A-Logging-Monad_RPAR_"></a>


```proofscript
structure LogM (β : Type u) (α : Type v) : Type (max u v) where
  log : Array β
  value : α

instance : Monad (LogM β) where
  pure x := ⟨#[], x⟩
  bind x f :=
    let { log, value } := f x.value
    { log := x.log ++ log, value }
```

It has a `LawfulMonad` instance as well.

The log can be written to using `log`, and a value and the associated log can be computed using `LogM.run`.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="log-_LPAR_in-A-Logging-Monad_RPAR_"></a>
<a id="LogM___run-_LPAR_in-A-Logging-Monad_RPAR_"></a>


```proofscript
function log (v : β) : LogM β Unit := { log := #[v], value := () }

function LogM.run (x : LogM β α) : α × Array β := (x.value, x.log)
```

Rather than writing it from scratch, the `WP` instance uses `PredTrans.pushArg`. This operator was designed to model state monads, but `LogM` can be seen as a state monad that can only append to the state. This appending is visible in the body of the instance, where the initial state and the log that resulted from the action are appended:

```proofscript
instance : WP (LogM β) (.arg (Array β) .pure) where
  wp
    | { log, value } =>
      PredTrans.pushArg (fun s => PredTrans.pure (value, s ++ log))
```

The `WPMonad` instance also benefits from the conceptual model as a state monad and admits very short proofs:

```proofscript
instance : WPMonad (LogM β) (.arg (Array β) .pure) where
  wp_pure x := by
    ext
    simp [wp, pure]

  wp_bind _ _ := by
    ext
    simp [wp, bind]
```

The adequacy lemma has one important detail: the result of the weakest precondition transformation is applied to the empty array. This is necessary because the logging computation has been modeled as an append-only state, so there must be some initial state. Semantically, the empty array is the correct choice so as to not place items in a log that don't come from the program; technically, it must also be a value that commutes with the append operator on arrays.
<a id="LogM___of_wp_run_eq-_LPAR_in-A-Logging-Monad_RPAR_"></a>


```proofscript
theorem LogM.of_wp_run_eq {x : α × Array β} {prog : LogM β α}
    (h : LogM.run prog = x) (P : α × Array β → Prop) :
    (⊢ₛ wp⟦prog⟧ (⇓ v l => ⌜P (v, l)⌝) #[]) → P x := by
  rw [← h]
  intro h'
  simp [wp] at h'
  exact h'
```

Next, each operator in the library should be provided with a specification lemma. There is only one: `log`. For new monads, these proofs must often break the abstraction boundaries of [Hoare triples](../Predicate-Transformers/index.md#--tech-term-Hoare-triple) and weakest preconditions; the specifications that they provide can then be used abstractly by clients of the library.
<a id="log_spec-_LPAR_in-A-Logging-Monad_RPAR_"></a>


```proofscript
theorem log_spec {x : β} :
    ⦃ fun s => ⌜s = s'⌝ ⦄ log x ⦃ ⇓ () s => ⌜s = s'.push x⌝ ⦄ := by
  simp [log, Triple, wp]
```

A better specification for `log` uses a schematic postcondition:
<a id="log_spec_better-_LPAR_in-A-Logging-Monad_RPAR_"></a>


```proofscript
variable {Q : PostCond Unit (.arg (Array β) .pure)}

@[spec]
theorem log_spec_better {x : β} :
    ⦃ fun s => Q.1 () (s.push x) ⦄ log x ⦃ Q ⦄ := by
  simp [log, Triple, wp]
```

A function `logUntil` that logs all the natural numbers up to some bound will always result in a log whose length is equal to its argument:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="logUntil-_LPAR_in-A-Logging-Monad_RPAR_"></a>
<a id="logUntil_length-_LPAR_in-A-Logging-Monad_RPAR_"></a>


```proofscript
function logUntil (n : Nat) : LogM Nat Unit := do
  for i in 0...n do
    log i

theorem logUntil_length : (logUntil n).run.2.size = n := by
  generalize h : (logUntil n).run = x
  unfold logUntil at h
  apply LogM.of_wp_run_eq h
  mvcgen invariants
  · ⇓⟨xs, _⟩ s => ⌜xs.pos = s.size⌝
  with
    simp_all [List.Cursor.pos] <;>
    grind [Std.PRange.Nat.size_rco, Std.Rco.length_toList]
```

## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
n:Nat⊢ ⦃fun s => ⌜s = n⌝⦄ double ⦃PostCond.noThrow fun x s => ⌜s = 2 * n⌝⦄
```


### Display 2


```text
n:Nat⊢ ⦃fun s => ⌜s = n⌝⦄ modify fun x => 2 * x ⦃PostCond.noThrow fun x s => ⌜s = 2 * n⌝⦄
```


### Display 3


```text
All goals completed! 🐙
```


### Display 4


```text
Q:PostCond Unit (PostShape.arg Nat PostShape.pure)⊢ ⦃fun s => Q.fst () (2 * s)⦄ double ⦃Q⦄
```


### Display 5


```text
Q:PostCond Unit (PostShape.arg Nat PostShape.pure)⊢ ⦃fun s => Q.fst () (2 * s)⦄ modify fun x => 2 * x ⦃Q⦄
```


### Display 6


```text
α:Type ?u.5σ:List (Type u)ps:PostShapex✝:PredTrans ps αy:PredTrans ps αQ:Assertion psβ:Type ?u.20α✝:Type ?u.20x:α✝⊢ wp (pure x) = pure x
```


### Display 7


```text
α:Type ?u.5σ:List (Type u)ps:PostShapex✝:PredTrans ps αy:PredTrans ps αQ:Assertion psβ:Type ?u.20α✝:Type ?u.20x:α✝Q✝:PostCond α✝ (PostShape.arg (Array β) PostShape.pure)s✝:Array β⊢ (wp⟦pure x⟧ Q✝ s✝).down ↔ ((pure x).apply Q✝ s✝).down
```


### Display 8


```text
α:Type ?u.5σ:List (Type u)ps:PostShapex:PredTrans ps αy:PredTrans ps αQ:Assertion psβ:Type ?u.20α✝:Type ?u.20β✝:Type ?u.20x✝¹:LogM β α✝x✝:α✝ → LogM β β✝⊢ (wp do
    let a ← x✝¹
    x✝ a) =
  do
  let a ← wp x✝¹
  wp (x✝ a)
```


### Display 9


```text
α:Type ?u.5σ:List (Type u)ps:PostShapex:PredTrans ps αy:PredTrans ps αQ:Assertion psβ:Type ?u.20α✝:Type ?u.20β✝:Type ?u.20x✝¹:LogM β α✝x✝:α✝ → LogM β β✝Q✝:PostCond β✝ (PostShape.arg (Array β) PostShape.pure)s✝:Array β⊢ (wp⟦do
        let a ← x✝¹
        x✝ a⟧
      Q✝ s✝).down ↔
  ((do
          let a ← wp x✝¹
          wp (x✝ a)).apply
      Q✝ s✝).down
```


### Display 10


```text
α:Type u_1β:Type u_1x:α × Array βprog:LogM β αh:prog.run = xP:α × Array β → Prop⊢ (⊢ₛ wp⟦prog⟧ (PostCond.noThrow fun v l => ⌜P (v, l)⌝) #[]) → P x
```


### Display 11


```text
α:Type u_1β:Type u_1x:α × Array βprog:LogM β αh:prog.run = xP:α × Array β → Prop⊢ (⊢ₛ wp⟦prog⟧ (PostCond.noThrow fun v l => ⌜P (v, l)⌝) #[]) → P prog.run
```


### Display 12


```text
α:Type u_1β:Type u_1x:α × Array βprog:LogM β αh:prog.run = xP:α × Array β → Proph':⊢ₛ wp⟦prog⟧ (PostCond.noThrow fun v l => ⌜P (v, l)⌝) #[]⊢ P prog.run
```


### Display 13


```text
α:Type u_1β:Type u_1x:α × Array βprog:LogM β αh:prog.run = xP:α × Array β → Proph':P (prog.value, prog.log)⊢ P prog.run
```


### Display 14


```text
β:Types':Array βx:β⊢ ⦃fun s => ⌜s = s'⌝⦄ log x ⦃PostCond.noThrow fun x_1 s => ⌜s = s'.push x⌝⦄
```


### Display 15


```text
β:TypeQ:PostCond Unit (PostShape.arg (Array β) PostShape.pure)x:β⊢ ⦃fun s => Q.fst () (s.push x)⦄ log x ⦃Q⦄
```


### Display 16


```text
n:Nat⊢ (logUntil n).run.snd.size = n
```


### Display 17


```text
n:Natx:Unit × Array Nath:(logUntil n).run = x⊢ x.snd.size = n
```


### Display 18


```text
n:Natx:Unit × Array Nath:(do
      forIn (0...n) PUnit.unit fun i __s => do
          log i
          pure (ForInStep.yield PUnit.unit)
      pure ()).run =
  x⊢ x.snd.size = n
```


### Display 19


```text
n:Natx:Unit × Array Nath:(do
      forIn (0...n) PUnit.unit fun i __s => do
          log i
          pure (ForInStep.yield PUnit.unit)
      pure ()).run =
  x⊢ ⊢ₛ
  wp⟦do
      forIn (0...n) PUnit.unit fun i __s => do
          log i
          pure (ForInStep.yield PUnit.unit)
      pure ()⟧
    (PostCond.noThrow fun v l => ⌜(v, l).snd.size = n⌝) #[]
```

