<a id="interaction"></a>

# ProofScript — 3. Interacting with Lean

[Reference home](../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Use native inspection commands in supported lifted command slots. A #check result describes typing; #reduce performs logical reduction; #eval uses an execution route. Runtime output is not automatically evidence of a proposition. Source maps should report original .ps locations, and theorem inspection should expose exact assumptions. Commands and command-line switches belonging to the Lean executable are reference-tool operations, not newly implemented PSC commands.

## ProofScript way of writing it


```proofscript
#check Nat
#check Nat.add

#reduce Nat.add(2, 3)
#eval Nat.add(2, 3)
```

**Compiler and coverage boundary.** D-CALL in command term positions requires an explicit lifted category. Preserve options and imported registrations during incremental checking.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Interacting-with-Lean/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Interacting-with-Lean/index.html). Source Git blob: `dd92d04daf4ed6bd54c50fd05dbb70e8cc145c26`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Instance-Constructor"></a>
<a id="docstring-section-Methods"></a>
<a id="docstring-section-Instance-Constructor-next"></a>
<a id="docstring-section-Methods-next"></a>
<a id="docstring-section-Constructors-next"></a>
<a id="docstring-section-Constructors-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next"></a>
<a id="docstring-section-Methods-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next"></a>
<a id="docstring-section-Methods-next-next-next-next"></a>
<a id="docstring-section-Instance-Constructor-next-next-next-next-next"></a>

---

## 3. Interacting with Lean

Lean is designed for interactive use, rather than as a batch-mode system in which whole files are fed in and then translated to either object code or error messages. Many programming languages designed for interactive use provide a 
<a id="--tech-term-REPL"></a>
REPL,Short for “**R**ead-**E**val-**P**rint **L**oop”, because code is parsed (“read”), evaluated, and the result displayed, with this process repeated as many times as desired. at which code can be input and tested, along with commands for loading source files, type checking terms, or querying the environment. Lean's interactive features are based on a different paradigm. Rather than a separate command prompt outside of the program, Lean provides [commands](../Source-Files-and-Modules/index.md#--tech-term-commands) for accomplishing the same tasks in the context of a source file. By convention, commands that are intended for interactive use rather than as part of a durable code artifact are prefixed with `#`.

Information from Lean commands is available in the 
<a id="--tech-term-message-log"></a>
*message log*, which accumulates output from the [elaborator](../Terms/index.md#--tech-term-elaborator). Each entry in the message log is associated with a specific source range and has a 
<a id="--tech-term-severity"></a>
*severity*. There are three severities: `information` is used for messages that do not indicate a problem, `warning` indicates a potential problem, and `error` indicates a definite problem. For interactive commands, results are typically returned as informational messages that are associated with the command's leading keyword.

<a id="hash-eval"></a>
### 3.1. Evaluating Terms

The [`#eval`](index.md#Lean___Parser___Command___eval) command is used to run code as a program. In particular, it is capable of executing `IO` actions, it uses a call-by-value evaluation strategy, [`partial` functions are executed](../Definitions/Recursive-Definitions/index.md#partial-unsafe), and both types and proofs are erased. Use [`#reduce`](index.md#Lean___reduceCmd) to instead reduce terms using the reduction rules that are part of [definitional equality](../The-Type-System/index.md#--tech-term-definitional-equality).

<a id="command-next-next"></a>

**syntax**

**Evaluating Terms**

<a id="Lean___Parser___Command___eval"></a>

```ebnf
command ::= ...
    | #eval term
```

<a id="Lean___Parser___Command___evalBang"></a>

```ebnf
command ::= ...
    | #eval! term
```

`#eval e` evaluates the expression `e` by compiling it and running the compiled code. It then prints the resulting value.

- The command attempts to use `ToExpr`, `Repr`, or `ToString` instances to print the result.
- If `e` is a monadic value of type `m ty`, then the command tries to adapt the monad `m` to one of the monads that `#eval` supports, which include `IO`, `CoreM`, `MetaM`, `TermElabM`, and `CommandElabM`. Users can define `MonadEval` instances to extend the list of supported monads.

The `#eval` command gracefully degrades in capability depending on what is imported. Importing the `Lean.Elab.Command` module provides full capabilities.

Due to unsoundness, `#eval` refuses to evaluate expressions that depend on `sorry`, even indirectly, since the presence of `sorry` can lead to runtime instability and crashes. This check can be overridden with the `#eval! e` command.

Options:

- If `eval.pp` is true (default: true) then tries to use `ToExpr` instances to make use of the usual pretty printer. Otherwise, only tries using `Repr` and `ToString` instances.
- If `eval.type` is true (default: false) then pretty prints the type of the evaluated value.
- If `eval.derive.repr` is true (default: true) then attempts to auto-derive a `Repr` instance when there is no other way to print the result.

See also: `#reduce e` for evaluation by term reduction.

[`#eval`](index.md#Lean___Parser___Command___eval) always [elaborates](../Terms/index.md#--tech-term-elaborator) and compiles the provided term. It then checks whether the term transitively depends on any uses of `sorry`, in which case evaluation is terminated unless the command was invoked as [`#eval!`](index.md#Lean___Parser___Command___eval). This is because compiled code may rely on compile-time invariants (such as array lookups being in-bounds) that are ensured by proofs of suitable statements, and running code that contains incomplete proofs (or uses of `sorry` that “prove” incorrect statements) can cause Lean itself to crash.

The way the code is run depends on its type:

- If the type is in the `IO` monad, then it is executed in a context where [standard output](../IO/Files___-File-Handles___-and-Streams/index.md#--tech-term-standard-output) and [standard error](../IO/Files___-File-Handles___-and-Streams/index.md#--tech-term-standard-error) are captured and redirected to the Lean [message log](index.md#--tech-term-message-log). If the returned value's type is not `Unit`, then it is displayed as if it were the result of a non-monadic expression.
- If the type is in one of the internal Lean metaprogramming monads (`CommandElabM`, `TermElabM`, `MetaM`, or `CoreM`), then it is run in the current context. For example, the environment will contain the definitions that are in scope where [`#eval`](index.md#Lean___Parser___Command___eval) is invoked. As with `IO`, the resulting value is displayed as if it were the result of a non-monadic expression. When Lean is running under [Lake](../Build-Tools-and-Distribution/Lake/index.md#lake), its working directory (and thus the working directory for `IO` actions) is the current [`workspace`](../Build-Tools-and-Distribution/Lake/index.md#--tech-term-workspace).
- If the type is in some other monad `m`, and there is a `MonadLiftT m CommandElabM` or `MonadEvalT m CommandElabM` instance, then `MonadLiftT.monadLift` or `MonadEvalT.monadEval` is used to transform the monad into one that may be run with [`#eval`](index.md#Lean___Parser___Command___eval), after which it is run as usual.
- If the term's type is not in any of the supported monads, then it is treated as a pure value. The compiled code is run, and the result is displayed.

Auxiliary definitions or other environment modifications that result from elaborating the term in [`#eval`](index.md#Lean___Parser___Command___eval) are discarded. If the term is an action in a metaprogramming monad, then changes made to the environment by running the monadic action are preserved.

When used in a [`module`](../Source-Files-and-Modules/index.md#--tech-term-module), [`#eval`](index.md#Lean___Parser___Command___eval) reveals a difference between the way the Lean language server and the Lean compiler process files. Because it runs code at compile time, [`#eval`](index.md#Lean___Parser___Command___eval) requires that its code is available in the [meta phase](../Source-Files-and-Modules/index.md#--tech-term-meta-phase). To make easier to experiment with a module, the language server makes all imported modules available in the meta phase, while the compiler strictly adheres to the `meta` declarations. As a result, modules that use [`#guard_msgs`](index.md#Lean___guardMsgsCmd) together with [`#eval`](index.md#Lean___Parser___Command___eval) to embed lightweight tests may elaborate successfully in the language server but fail during a build. To fix this, the definitions can be imported with `meta import` in the module that contains the test:

<a id="Evaluation-and-Meta"></a>
Evaluation and Meta  `Eval/Even.lean`
<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
module
public section
function isEven (n : Nat) : Bool :=
  n % 2 = 0
```

  `Eval.lean`

```proofscript
module
import Eval.Even

/-- info: [true, false] -/
#guard_msgs in
#eval [isEven 4, isEven 5]
```

```lean
❌️ Docstring on `#guard_msgs` does not match generated message:

- info: [true, false]
+ error: Invalid `meta` definition `_eval`, `isEven` is not accessible here; consider adding `public meta import Eval.Even`
```

Importing `isEven` to the meta phase fixes the problem:

  `Eval/Even.lean`
<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
module
public section
function isEven (n : Nat) : Bool :=
  n % 2 = 0
```

  `Eval.lean`

```proofscript
module
meta import Eval.Even

/-- info: [true, false] -/
#guard_msgs in
#eval [isEven 4, isEven 5]
```

Results are displayed using a `ToExpr`, `ToString`, or `Repr` instance, if they exist. If not, and `eval.derive.repr` is `true`, Lean attempts to derive a suitable `Repr` instance. It is an error if no suitable instance can be found or derived. Setting `eval.pp` to `false` disables the use of `ToExpr` instances by [`#eval`](index.md#Lean___Parser___Command___eval).

<a id="Displaying-Output"></a>
Displaying Output 

[`#eval`](index.md#Lean___Parser___Command___eval) cannot display functions:

```proofscript
#eval fun x => x + 1
```

```lean
Could not synthesize a `ToExpr`, `Repr`, or `ToString` instance for type
  Nat → Nat
```

It is capable of deriving instances to display output that has no `ToString` or `Repr` instance:
<a id="Quadrant-_LPAR_in-Displaying-Output_RPAR_"></a>
<a id="Quadrant___nw-_LPAR_in-Displaying-Output_RPAR_"></a>
<a id="Quadrant___sw-_LPAR_in-Displaying-Output_RPAR_"></a>
<a id="Quadrant___se-_LPAR_in-Displaying-Output_RPAR_"></a>
<a id="Quadrant___ne-_LPAR_in-Displaying-Output_RPAR_"></a>


```proofscript
inductive Quadrant where
  | nw | sw | se | ne

#eval Quadrant.nw
```

```lean
Quadrant.nw
```

The derived instance is not saved. Disabling `eval.derive.repr` causes [`#eval`](index.md#Lean___Parser___Command___eval) to fail:

```proofscript
set_option eval.derive.repr false
#eval Quadrant.nw
```

```lean
Could not synthesize a `ToExpr`, `Repr`, or `ToString` instance for type
  Quadrant
```

<a id="eval___pp"></a>

**option**

```text
eval.pp
```

Default value: `true`

('#eval' command) enables using 'ToExpr' instances to pretty print the result, otherwise uses 'Repr' or 'ToString' instances

<a id="eval___type"></a>

**option**

```text
eval.type
```

Default value: `false`

('#eval' command) enables pretty printing the type of the result

<a id="eval___derive___repr"></a>

**option**

```text
eval.derive.repr
```

Default value: `true`

('#eval' command) enables auto-deriving 'Repr' instances as a fallback

Monads can be given the ability to execute in [`#eval`](index.md#Lean___Parser___Command___eval) by defining a suitable `MonadLift``MonadLift` is described in [the section on lifting monads.](../Functors___-Monads-and--do--Notation/Lifting-Monads/index.md#lifting-monads) or `MonadEval` instance. Just as `MonadLiftT` is the transitive closure of `MonadLift` instances, `MonadEvalT` is the transitive closure of `MonadEval` instances. As with `MonadLiftT` users should not define additional instances of `MonadEvalT` directly.

<a id="MonadEval___mk"></a>

**type class**

```text
MonadEval.{u, v, w} (m : semiOutParam (Type u → Type v))
  (n : Type u → Type w) : Type (max (max (u + 1) v) w)
```

Typeclass used for adapting monads. This is similar to `MonadLift`, but instances are allowed to make use of default state for the purpose of synthesizing such an instance, if necessary. Every `MonadLift` instance gives a `MonadEval` instance.

The purpose of this class is for the `#eval` command, which looks for a `MonadEval m CommandElabM` or `MonadEval m IO` instance.

**Instance Constructor**

```text
MonadEval.mk.{u, v, w}
```

**Methods**

```text
monadEval : {α : Type u} → m α → n α
```

Evaluates a value from monad `m` into monad `n`.

<a id="MonadEvalT___mk"></a>

**type class**

```text
MonadEvalT.{u, v, w} (m : Type u → Type v) (n : Type u → Type w) :
  Type (max (max (u + 1) v) w)
```

The transitive closure of `MonadEval`.

**Instance Constructor**

```text
MonadEvalT.mk.{u, v, w}
```

**Methods**

```text
monadEval : {α : Type u} → m α → n α
```

Evaluates a value from monad `m` into monad `n`.

<a id="hash-reduce"></a>
### 3.2. Reducing Terms

The [`#reduce`](index.md#Lean___reduceCmd) command repeatedly applies reductions to a term until no further reductions are possible. Reductions are performed under binders, but to avoid unexpected slowdowns, proofs and types are skipped unless the corresponding options to [`#reduce`](index.md#Lean___reduceCmd) are enabled. Unlike [`#eval`](index.md#Lean___Parser___Command___eval) command, reduction cannot have side effects and the result is displayed as a term rather than via a `ToString` or `Repr` instance.

Generally speaking, [`#reduce`](index.md#Lean___reduceCmd) is primarily useful for diagnosing issues with definitional equality and proof terms, while [`#eval`](index.md#Lean___Parser___Command___eval) is more suitable for computing the value of a term. In particular, functions defined using [well-founded recursion](../Definitions/Recursive-Definitions/index.md#--tech-term-well-founded-recursion) or as [partial fixpoints](../Definitions/Recursive-Definitions/index.md#--tech-term-partial-fixpoint) are either very slow to compute with the reduction engine, or will not reduce at all.

<a id="command-next-next-next"></a>

**syntax**

**Reducing Terms**

<a id="Lean___reduceCmd"></a>

```ebnf
command ::= ...
    | #reduce ((ident := term))* term
```

`#reduce <expression>` reduces the expression `<expression>` to its normal form. This involves applying reduction rules until no further reduction is possible.

By default, proofs and types within the expression are not reduced. Use modifiers `(proofs := true)` and `(types := true)` to reduce them. Recall that propositions are types in Lean.

**Warning:** This can be a computationally expensive operation, especially for complex expressions.

Consider using `#eval <expression>` for simple evaluation/execution of expressions.

<a id="Reducing-Functions"></a>
Reducing Functions 

Reducing a term results in its normal form in Lean's logic. Because the underlying term is reduced and then displayed, there is no need for a `ToString` or `Repr` instance. Functions can be displayed just as well as any other term.

In some cases, this normal form is short and resembles a term that a person might write:

```proofscript
#reduce (fun x => x + 1)
```

```lean
fun x => x.succ
```

In other cases, the details of [the elaboration of functions](../Definitions/Recursive-Definitions/index.md#elab-as-course-of-values) such as addition to Lean's core logic are exposed:

```proofscript
#reduce (fun x => 1 + x)
```

```lean
fun x => (Nat.rec ⟨fun x => x, PUnit.unit⟩ (fun n n_ih => ⟨fun x => (n_ih.1 x).succ, n_ih⟩) x).1 1
```

<a id="hash-check"></a>
### 3.3. Checking Types

<a id="command-next-next-next-next"></a>

**syntax**

**Checking Types**

`#check` can be used to elaborate a term and check its type.

<a id="Lean___Parser___Command___check"></a>

```ebnf
command ::= ...
    | #check term
```

If the provided term is an identifier that is the name of a global constant, then `#check` prints its signature. Otherwise, the term is elaborated as a Lean term and its type is printed.

Elaboration of the term in [`#check`](index.md#Lean___Parser___Command___check) does not require that the term is fully elaborated; it may contain metavariables. If the term as written *could* have a type, elaboration succeeds. If a required instance could never be synthesized, then elaboration fails; synthesis problems that are due to metavariables do not block elaboration.

<a id="___check--and-Underdetermined-Types"></a>
`#check` and Underdetermined Types 

In this example, the type of the list's elements is not determined, so the type contains a metavariable:

```proofscript
#check fun x => [x]
```

```lean
fun x => [x] : ?m.4 → List ?m.4
```

In this example, both the type of the terms being added and the result type of the addition are unknown, because `HAdd` allows terms of different types to be added. Behind the scenes, a metavariable represents the unknown `HAdd` instance.

```proofscript
#check fun x => x + x
```

```lean
fun x => x + x : (x : ?m.7) → ?m.8 x
```

<a id="command-next-next-next-next-next"></a>

**syntax**

**Testing Type Errors**

<a id="Lean___Parser___Command___check_failure"></a>

```ebnf
command ::= ...
    | #check_failure term
```

This variant of [`#check`](index.md#Lean___Parser___Command___check) elaborates the term using the same process as [`#check`](index.md#Lean___Parser___Command___check). If elaboration succeeds, it is an error; if it fails, there is no error. The partially-elaborated term and any type information that was discovered are added to the [message log](index.md#--tech-term-message-log).

<a id="Checking-for-Type-Errors"></a>
Checking for Type Errors 

Attempting to add a string to a natural number fails, as expected:

```proofscript
#check_failure "one" + 1
```

```lean
failed to synthesize instance of type class
  HAdd String Nat ?m.5

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```

Nonetheless, a partially-elaborated term is available:

```lean
"one" + 1 : ?m.5
```

<a id="hash-synth"></a>
### 3.4. Synthesizing Instances

<a id="command-next-next-next-next-next-next"></a>

**syntax**

**Synthesizing Instances**

<a id="Lean___Parser___Command___synth"></a>

```ebnf
command ::= ...
    | #synth term
```

The [`#synth`](index.md#Lean___Parser___Command___synth) command invokes Lean's [type class](../Type-Classes/index.md#--tech-term-type-class) resolution machinery and attempts to perform [instance synthesis](../Type-Classes/Instance-Synthesis/index.md#instance-synth) to find an instance for the given type class. If it succeeds, then the resulting instance term is output.

<a id="Synthesizing-a-Type-Class-Instance"></a>
Synthesizing a Type Class Instance  

Lean uses type classes to overload operations like addition. The `+` operator is notation for a call to `HAdd.hAdd`, which is the single method in the `HAdd` type class. This example shows that Lean will let us add two integers, and the result will be an integer:

```proofscript
#synth HAdd Int Int Int
```

```lean
instHAdd
```

By default, Lean does not show the implicit arguments in the output term. Instance arguments are implicit, however, which decreases the usefulness of this output for understanding instance synthesis. Setting the option `pp.explicit` to `true` causes Lean to display implicit arguments, including instances:

```proofscript
set_option pp.explicit true in
#synth HAdd Int Int Int
```

```lean
@instHAdd Int Int.instAdd
```

Lean does not allow the addition of integers and strings, as demonstrated by this failure of type class instance synthesis:

```proofscript
#synth HAdd Int String String
```

```lean
failed to synthesize
  HAdd Int String String

Hint: Additional diagnostic information may be available using the `set_option diagnostics true` command.
```

<a id="hash-print"></a>
### 3.5. Querying the Context

The `#print` family of commands are used to query Lean for information about definitions.

<a id="command-next-next-next-next-next-next-next"></a>

**syntax**

**Printing Definitions**

<a id="Lean___Parser___Command___print"></a>

```ebnf
command ::= ...
    | #print ident
```

Prints the definition of a constant.

Printing a definition with `#print` prints the definition as a term. Theorems that were proved using [tactics](../Tactic-Proofs/index.md#tactics) may be very large when printed as terms.

<a id="command-next-next-next-next-next-next-next-next"></a>

**syntax**

**Printing Strings**

<a id="Lean___Parser___Command___print-next"></a>

```ebnf
command ::= ...
    | #print str
```

Adds the string literal to Lean's [message log](index.md#--tech-term-message-log).

<a id="command-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Printing Axioms**

<a id="Lean___Parser___Command___printAxioms"></a>

```ebnf
command ::= ...
    | #print axioms ident
```

Lists all axioms that the constant transitively relies on. See [the documentation for axioms](../Axioms/index.md#print-axioms) for more information.

<a id="Printing-Axioms"></a>
Printing Axioms 

These two functions each swap the elements in a pair of bitvectors:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="swap-_LPAR_in-Printing-Axioms_RPAR_"></a>
<a id="swap___-_LPAR_in-Printing-Axioms_RPAR_"></a>


```proofscript
function swap (x y : BitVec 32) : BitVec 32 × BitVec 32 :=
  (y, x)

function swap' (x y : BitVec 32) : BitVec 32 × BitVec 32 :=
  let x := x ^^^ y
  let y := x ^^^ y
  let x := x ^^^ y
  (x, y)
```

They can be proven equal using [function extensionality](../The-Type-System/Functions/index.md#function-extensionality), the [simplifier](../The-Simplifier/index.md#the-simplifier), and `bv_decide`:
<a id="swap_eq_swap___-_LPAR_in-Printing-Axioms_RPAR_"></a>


```proofscript
theorem swap_eq_swap' : swap = swap' := by
  funext x y
  simp only [swap, swap', Prod.mk.injEq]
  bv_decide
```

The resulting proof makes use of a number of axioms:

```proofscript
#print axioms swap_eq_swap'
```

```lean
'swap_eq_swap'' depends on axioms: [propext, Classical.choice, Quot.sound, swap_eq_swap'._native.bv_decide.ax_3]
```

The axiom `swap_eq_swap'._native.bv_decide.ax_3` was generated by `bv_decide`, showing that native code was used to translate an external proof certificate into a Lean proof term.

<a id="command-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Printing Equations**

The command `#print equations`, which can be abbreviated `#print eqns`, displays the [equational lemmas](../Elaboration-and-Compilation/index.md#--tech-term-equational-lemmas) for a function.

<a id="Lean___Parser___Command___printEqns"></a>

```ebnf
command ::= ...
    | #print equations ident
```

<a id="Lean___Parser___Command___printEqns-next"></a>

```ebnf
command ::= ...
    | #print eqns ident
```

<a id="Printing-Equations"></a>
Printing Equations 
<a id="intersperse-_LPAR_in-Printing-Equations_RPAR_"></a>


```proofscript
def intersperse (x : α) : List α → List α
  | y :: z :: zs => y :: x :: intersperse x (z :: zs)
  | xs => xs

#print equations intersperse
```

```lean
equations:
@[backward_defeq] theorem intersperse.eq_1.{u_1} : ∀ {α : Type u_1} (x y z : α) (zs : List α),
  intersperse x (y :: z :: zs) = y :: x :: intersperse x (z :: zs)
theorem intersperse.eq_2.{u_1} : ∀ {α : Type u_1} (x : α) (x_1 : List α),
  (∀ (y z : α) (zs : List α), x_1 = y :: z :: zs → False) → intersperse x x_1 = x_1
```

It does not print the defining equation, nor the unfolding equation:

```proofscript
#check intersperse.eq_def
```

```lean
intersperse.eq_def.{u_1} {α : Type u_1} (x : α) (x✝ : List α) :
  intersperse x x✝ =
    match x✝ with
    | y :: z :: zs => y :: x :: intersperse x (z :: zs)
    | xs => xs
```

```proofscript
#check intersperse.eq_unfold
```

```lean
intersperse.eq_unfold.{u_1} :
  @intersperse = fun {α} x x_1 =>
    match x_1 with
    | y :: z :: zs => y :: x :: intersperse x (z :: zs)
    | xs => xs
```

<a id="command-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Scope Information**

`#where` gives a description of the state of the current scope scope. This includes the current namespace, `open` namespaces, `universe` and `variable` commands, and options set with `set_option`.

<a id="Lean___Parser___Command___where"></a>

```ebnf
command ::= ...
    | #where
```

<a id="Scope-Information"></a>
Scope Information 

The [`#where`](index.md#Lean___Parser___Command___where) command displays all the modifications made to the current [section scope](../Namespaces-and-Sections/index.md#--tech-term-section-scope), both in the current scope and in the scopes in which it is nested.

```proofscript
public section
open Nat

namespace A
variable (n : Nat)
namespace B

open List
set_option pp.tagAppFns true

#where

end A.B
end
```

```lean
public section

namespace A.B

open Nat List

variable (n : Nat)

set_option pp.tagAppFns true
```

<a id="command-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Checking the Lean Version**

Shows the current Lean version. Prints `Lean.versionString`.

<a id="Lean___Parser___Command___version"></a>

```ebnf
command ::= ...
    | #version
```

<a id="hash-guard_msgs"></a>
### 3.6. Testing Output with #guard_msgs

The [`#guard_msgs`](index.md#Lean___guardMsgsCmd) command can be used to ensure that the messages output by a command are as expected. Together with the interaction commands in this section, it can be used to construct a file that will only elaborate if the output is as expected; such a file can be used as a [test driver](../Build-Tools-and-Distribution/Lake/index.md#--tech-term-test-driver) in [Lake](../Build-Tools-and-Distribution/Lake/index.md#lake).

<a id="command-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

**syntax**

**Documenting Expected Output**

<a id="Lean___guardMsgsCmd"></a>

```ebnf
command ::= ...
    | docComment?
      #guard_msgs ((guardMsgsSpecElt,*))? in
      command
```

`/-- ... -/ #guard_msgs in cmd` captures the messages generated by the command `cmd` and checks that they match the contents of the docstring.

Basic example:

```proofscript
/--
error: Unknown identifier `x`
-/
#guard_msgs in
example : α := x
```

This checks that there is such an error and then consumes the message.

By default, the command captures all messages, but the filter condition can be adjusted. For example, we can select only warnings:

```text
/--
warning: declaration uses 'sorry'
-/
#guard_msgs(warning) in
example : α := sorry
```

or only errors

```proofscript
#guard_msgs(error) in
example : α := sorry
```

In the previous example, since warnings are not captured there is a warning on `sorry`. We can drop the warning completely with

```proofscript
#guard_msgs(error, drop warning) in
example : α := sorry
```

In general, `#guard_msgs` accepts a comma-separated list of configuration clauses in parentheses:

```proofscript
#guard_msgs (
```

By default, the configuration list is `(check all, whitespace := normalized, ordering := exact, positions := false)`.

Message filters select messages by severity:

- `info`, `warning`, `error`: (non-trace) messages with the given severity level.
- `trace`: trace messages
- `all`: all messages.

The filters can be prefixed with the action to take:

- `check` (the default): capture and check the message
- `drop`: drop the message
- `pass`: let the message pass through

If no filter is specified, `check all` is assumed. Otherwise, these filters are processed in left-to-right order, with an implicit `pass all` at the end.

Whitespace handling (after trimming leading and trailing whitespace):

- `whitespace := exact` requires an exact whitespace match.
- `whitespace := normalized` converts all newline characters to a space before matching (the default). This allows breaking long lines.
- `whitespace := lax` collapses whitespace to a single space before matching.

Message ordering:

- `ordering := exact` uses the exact ordering of the messages (the default).
- `ordering := sorted` sorts the messages in lexicographic order. This helps with testing commands that are non-deterministic in their ordering.

Position reporting:

- `positions := true` reports the ranges of all messages relative to the line on which `#guard_msgs` appears.
- `positions := false` does not report position info.

Substring matching:

- `substring := true` checks that the docstring appears as a substring of the output (after whitespace normalization). This is useful when you only care about part of the message.
- `substring := false` (the default) requires exact matching (modulo whitespace normalization).

Stabilizing output: When messages contain autogenerated names (e.g., metavariables like `?m.47`), the output may differ between runs or Lean versions. Use `set_option pp.mvars.anonymous false` to replace anonymous metavariables with `?_` while preserving user-named metavariables like `?a`. Alternatively, `set_option pp.mvars false` replaces all metavariables with `?_`. Similarly, `set_option pp.fvars.anonymous false` replaces loose free variable names like `_fvar.22` with `_fvar._`.

For example, `#guard_msgs (error, drop all) in cmd` means to check errors and drop everything else.

The command elaborator has special support for `#guard_msgs` for linting. The `#guard_msgs` itself wants to capture linter warnings, so it elaborates the command it is attached to as if it were a top-level command. However, the command elaborator runs linters for *all* top-level commands, which would include `#guard_msgs` itself, and would cause duplicate and/or uncaptured linter warnings. The top-level command elaborator only runs the linters if `#guard_msgs` is not present.

<a id="Testing-Return-Values"></a>
Testing Return Values 

The [`#guard_msgs`](index.md#Lean___guardMsgsCmd) command can ensure that a set of test cases pass:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="reverse-_LPAR_in-Testing-Return-Values_RPAR_"></a>
<a id="reverse___helper-_LPAR_in-Testing-Return-Values_RPAR_"></a>


```proofscript
const reverse : List α → List α := helper []
where
  helper acc
    | [] => acc
    | x :: xs => helper (x :: acc) xs

/-- info: [] -/
#guard_msgs in
#eval reverse ([] : List Nat)

/-- info: ['c', 'b', 'a'] -/
#guard_msgs in
#eval reverse "abc".toList
```

The behavior of the [`#guard_msgs`](index.md#Lean___guardMsgsCmd) command can be specified in three ways:

1. Providing a filter that selects a subset of messages to be checked
2. Specifying a whitespace comparison strategy
3. Deciding to sort messages by their content or by the order in which they were produced

These configuration options are provided in parentheses, separated by commas.

<a id="Lean___guardMsgsSpecElt"></a>

**syntax**

**Specifying #guard_msgs Behavior**

<a id="Lean___guardMsgsSpecElt-next"></a>

```ebnf
guardMsgsSpecElt ::=
    guardMsgsFilter
```

<a id="Lean___guardMsgsSpecElt-next-next"></a>

```ebnf
guardMsgsSpecElt ::= ...
    | whitespace := guardMsgsWhitespaceArg
```

<a id="Lean___guardMsgsSpecElt-next-next-next"></a>

```ebnf
guardMsgsSpecElt ::= ...
    | ordering := guardMsgsOrderingArg
```

There are three kinds of options for [`#guard_msgs`](index.md#Lean___guardMsgsCmd): filters, whitespace comparison strategies, and orderings.

<a id="Lean___guardMsgsFilter"></a>

**syntax**

**Output Filters for #guard_msgs**

<a id="Lean___guardMsgsFilter-next"></a>

```ebnf
guardMsgsFilter ::=
    drop? all
```

<a id="Lean___guardMsgsFilter-next-next"></a>

```ebnf
guardMsgsFilter ::= ...
    | drop? info
```

<a id="Lean___guardMsgsFilter-next-next-next"></a>

```ebnf
guardMsgsFilter ::= ...
    | drop? warning
```

<a id="Lean___guardMsgsFilter-next-next-next-next"></a>

```ebnf
guardMsgsFilter ::= ...
    | drop? error
```

A message filter specification for `#guard_msgs`.

- `info`, `warning`, `error`: capture (non-trace) messages with the given severity level.
- `trace`: captures trace messages
- `all`: capture all messages.

The filters can be prefixed with

- `check` (the default): capture and check the message
- `drop`: drop the message
- `pass`: let the message pass through

If no filter is specified, `check all` is assumed. Otherwise, these filters are processed in left-to-right order, with an implicit `pass all` at the end.

<a id="Lean___guardMsgsWhitespaceArg"></a>

**syntax**

**Whitespace Comparison for #guard_msgs**

<a id="Lean___guardMsgsWhitespaceArg-next"></a>

```ebnf
guardMsgsWhitespaceArg ::=
    exact
```

<a id="Lean___guardMsgsWhitespaceArg-next-next"></a>

```ebnf
guardMsgsWhitespaceArg ::= ...
    | lax
```

<a id="Lean___guardMsgsWhitespaceArg-next-next-next"></a>

```ebnf
guardMsgsWhitespaceArg ::= ...
    | normalized
```

Leading and trailing whitespace is always ignored when comparing messages. On top of that, the following settings are available:

- `whitespace := exact` requires an exact whitespace match.
- `whitespace := normalized` converts all newline characters to a space before matching (the default). This allows breaking long lines.
- `whitespace := lax` collapses whitespace to a single space before matching.

The option `guard_msgs.diff` controls the content of the error message that [`#guard_msgs`](index.md#Lean___guardMsgsCmd) produces when the expected message doesn't match the produced message. By default, [`#guard_msgs`](index.md#Lean___guardMsgsCmd) shows a line-by-line difference, with a leading `+` used to indicate lines from the produced message and a leading `-` used to indicate lines from the expected message. When messages are large and only differ by a small amount, this can make it easier to notice where they differ. Setting `guard_msgs.diff` to `false` causes [`#guard_msgs`](index.md#Lean___guardMsgsCmd) to instead show just the produced message, which can be compared with the expected message in the source file. This can be convenient if the difference between the message is confusing or overwhelming.

<a id="guard_msgs___diff"></a>

**option**

```text
guard_msgs.diff
```

Default value: `true`

When true, show a diff between expected and actual messages if they don't match.

<a id="Displaying-Differences"></a>
Displaying Differences 

The [`#guard_msgs`](index.md#Lean___guardMsgsCmd) command can be used to test definition of a rose tree `Tree` and a function `Tree.big` that creates them:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="Tree-_LPAR_in-Displaying-Differences_RPAR_"></a>
<a id="Tree___val-_LPAR_in-Displaying-Differences_RPAR_"></a>
<a id="Tree___branches-_LPAR_in-Displaying-Differences_RPAR_"></a>
<a id="Tree___big-_LPAR_in-Displaying-Differences_RPAR_"></a>


```proofscript
inductive Tree (α : Type u) : Type u where
  | val : α → Tree α
  | branches : List (Tree α) → Tree α

function Tree.big (n : Nat) : Tree Nat :=
  if n < 5 then .branches [.val n, .val (n - 1), .val n, .val (n - 2)]
  else .branches [.big (n / 2),  .big (n / 3)]
```

However, it can be difficult to spot where test failures come from when the output is large:

```proofscript
set_option guard_msgs.diff false
/--
info: Tree.branches
  [Tree.branches
     [Tree.branches
        [Tree.branches [Tree.val 2, Tree.val 1, Tree.val 2, Tree.val 0],
         Tree.branches [Tree.val 1, Tree.val 0, Tree.val 1, Tree.val 0],
      Tree.branches [Tree.val 3, Tree.val 2, Tree.val 3, Tree.val 1]],
   Tree.branches
     [Tree.branches [Tree.val 3, Tree.val 2, Tree.val 3, Tree.val 1],
      Tree.branches [Tree.val 2, Tree.val 1, Tree.val 2, Tree.val 0]]]
-/
#guard_msgs in
#eval Tree.big 20
```

The evaluation produces:

```lean
Tree.branches
  [Tree.branches
     [Tree.branches
        [Tree.branches [Tree.val 2, Tree.val 1, Tree.val 2, Tree.val 0],
         Tree.branches [Tree.val 1, Tree.val 0, Tree.val 1, Tree.val 0]],
      Tree.branches [Tree.val 3, Tree.val 2, Tree.val 3, Tree.val 1]],
   Tree.branches
     [Tree.branches [Tree.val 3, Tree.val 2, Tree.val 3, Tree.val 1],
      Tree.branches [Tree.val 2, Tree.val 1, Tree.val 2, Tree.val 0]]]
```

Without `guard_msgs.diff`, the [`#guard_msgs`](index.md#Lean___guardMsgsCmd) command reports this error:

```lean
❌️ Docstring on `#guard_msgs` does not match generated message:

info: Tree.branches
  [Tree.branches
     [Tree.branches
        [Tree.branches [Tree.val 2, Tree.val 1, Tree.val 2, Tree.val 0],
         Tree.branches [Tree.val 1, Tree.val 0, Tree.val 1, Tree.val 0]],
      Tree.branches [Tree.val 3, Tree.val 2, Tree.val 3, Tree.val 1]],
   Tree.branches
     [Tree.branches [Tree.val 3, Tree.val 2, Tree.val 3, Tree.val 1],
      Tree.branches [Tree.val 2, Tree.val 1, Tree.val 2, Tree.val 0]]]
```

Enabling `guard_msgs.diff` highlights the differences instead, making the error more apparent:

```proofscript
set_option guard_msgs.diff true in
/--
info: Tree.branches
  [Tree.branches
     [Tree.branches
        [Tree.branches [Tree.val 2, Tree.val 1, Tree.val 2, Tree.val 0],
         Tree.branches [Tree.val 1, Tree.val 0, Tree.val 1, Tree.val 0,
      Tree.branches [Tree.val 3, Tree.val 2, Tree.val 3, Tree.val 1]],
   Tree.branches
     [Tree.branches [Tree.val 3, Tree.val 2, Tree.val 3, Tree.val 1],
      Tree.branches [Tree.val 2, Tree.val 1, Tree.val 2, Tree.val 0]]]
-/
#guard_msgs in
#eval Tree.big 20
```

```lean
❌️ Docstring on `#guard_msgs` does not match generated message:

  info: Tree.branches
    [Tree.branches
       [Tree.branches
          [Tree.branches [Tree.val 2, Tree.val 1, Tree.val 2, Tree.val 0],
-          Tree.branches [Tree.val 1, Tree.val 0, Tree.val 1, Tree.val 0,
+          Tree.branches [Tree.val 1, Tree.val 0, Tree.val 1, Tree.val 0]],
        Tree.branches [Tree.val 3, Tree.val 2, Tree.val 3, Tree.val 1]],
     Tree.branches
       [Tree.branches [Tree.val 3, Tree.val 2, Tree.val 3, Tree.val 1],
        Tree.branches [Tree.val 2, Tree.val 1, Tree.val 2, Tree.val 0]]]
```

<a id="format-repr"></a>
### 3.7. Formatted Output

The `Repr` type class is used to provide a standard representation for data that can be parsed and evaluated to obtain an equivalent value. This is not a strict correctness criterion: for some types, especially those with embedded propositions, it is impossible to achieve. However, the output produced by a `Repr` instance should be as close as possible to something that can be parsed and evaluated.

In addition to being machine-readable, this representation should be convenient for humans to understand—in particular, lines should not be too long, and nested values should be indented. This is achieved through a two-step process:

1. The `Repr` instance produces an intermediate document of type `Std.Format`, which compactly represents a *set* of strings that differ with respect to the placement of newlines and indentation.
2. A rendering process selects the “best” representative from the set, according to criteria such as a desired maximum line length.

In particular, `Std.Format` can be built compositionally, so `Repr` instances don't need to take the surrounding indentation context into account.

<a id="Format"></a>
#### 3.7.1. Format

A `Format`The API described here is an adaptation of Wadler's (Philip Wadler, 2003. [“A Prettier Printer”](https://homepages.inf.ed.ac.uk/wadler/papers/prettier/prettier.pdf). In *The Fun of Programming, A symposium in honour of Professor Richard Bird's 60th birthday.*) It has been modified to be efficient in a strict language and with support for additional features such as metadata tags. is a compact representation of a set of strings. The most important `Format` operations are:

  Strings

A `String` can be made into a `Format` using the `text` constructor. This constructor is registered as a [coercion](../Coercions/index.md#coercions) from `String` to `Format`, so it is often unnecessary to invoke it explicitly. `text str` represents the singleton set that contains only `str`. If the string contains newline characters (`'\n'`), then they are unconditionally inserted as newlines into the resulting output, regardless of groups. They are, however, indented according to the current indentation level.

  Appending

Two `Format`s can be appended using the `++` operator from the `Append Format` instance.

  Groups and Newlines

The constructor `line` represents the set that contains both `"\n" ++ indent` and `" "`, where `indent` is a string with enough spaces to indent the line correctly. Imperatively, it can be thought of as a newline that will be “flattened” to a space if there is sufficient room on the current line. Newlines occur in *groups*: the nearest enclosing application of the `group` operator determines which group the newline belongs to. By default, either all `line`s in a group represent `"\n"` or all represent `" "`; groups may also be configured to fill lines, in which case the minimal number of `line`s in the group represent `"\n"`. Uses of `line` that do not belong to a group always represent `"\n"`.

  Indentation

When a newline is inserted, the output is also indented. `nest n` increases the indentation of a document by `n` spaces. This is not sufficient to represent all Lean syntax, which sometimes requires that columns align exactly. `align` is a document that ensures that the output string is at the current indentation level, inserting just spaces if possible, or a newline followed by spaces if needed.

  Tagging

Lean's interactive features require the ability to associate output with the underlying values that they represent. This allows Lean development environments to present elaborated terms when hovering over terms proof states or error messages, for example. Documents can be *tagged* with a `Nat` value `n` using `tag n`; these `Nat`s should be mapped to the underlying value in a side table.

<a id="Widths-and-Newlines"></a>
Widths and Newlines 

```proofscript
open Std Format
```

The helper `parenSeq` creates a parenthesized sequence, with grouping and indentation to make it responsive to different output widths.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="parenSeq-_LPAR_in-Widths-and-Newlines_RPAR_"></a>


```proofscript
function parenSeq (xs : List Format) : Format :=
  group <|
    nest 2 (text "(" ++ line ++ joinSep xs line) ++
    line ++
    ")"
```

This document represents a parenthesized sequence of numbers:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="lst-_LPAR_in-Widths-and-Newlines_RPAR_"></a>
<a id="lst___nums-_LPAR_in-Widths-and-Newlines_RPAR_"></a>


```proofscript
const lst : Format := parenSeq nums
where nums := [1, 2, 3, 4, 5].map (text s!"{·}")
```

Rendering it with the default line width of 120 characters places the entire sequence on one line:

```proofscript
#eval IO.println lst.pretty
```

```lean
( 1 2 3 4 5 )
```

Because all the `line`s belong to the same `group`, they will either all be rendered as spaces or all be rendered as newlines. If only 9 characters are available, all of the `line`s in `lst` become newlines:

```proofscript
#eval IO.println (lst.pretty (width := 9))
```

```lean
(
  1
  2
  3
  4
  5
)
```

This document contains three copies of `lst` in a further parenthesized sequence:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="lsts-_LPAR_in-Widths-and-Newlines_RPAR_"></a>


```proofscript
const lsts := parenSeq [lst, lst, lst]
```

At the default width, it remains on one line:

```proofscript
#eval IO.println lsts.pretty
```

```lean
( ( 1 2 3 4 5 ) ( 1 2 3 4 5 ) ( 1 2 3 4 5 ) )
```

If only 20 characters are available, each occurrence of `lst` ends up on its own line. This is because converting the outer `group` to newlines is sufficient to keep the string within 20 columns:

```proofscript
#eval IO.println (lsts.pretty (width := 20))
```

```lean
(
  ( 1 2 3 4 5 )
  ( 1 2 3 4 5 )
  ( 1 2 3 4 5 )
)
```

If only 10 characters are available, each number must be on its own line:

```proofscript
#eval IO.println (lsts.pretty (width := 10))
```

```lean
(
  (
    1
    2
    3
    4
    5
  )
  (
    1
    2
    3
    4
    5
  )
  (
    1
    2
    3
    4
    5
  )
)
```

<a id="Grouping-and-Filling"></a>
Grouping and Filling 

```proofscript
open Std Format
```

The helper `parenSeq` creates a parenthesized sequence, with each element placed on a new line and indented:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="parenSeq-_LPAR_in-Grouping-and-Filling_RPAR_"></a>


```proofscript
function parenSeq (xs : List Format) : Format :=
  nest 2 (text "(" ++ line ++ joinSep xs line) ++
  line ++
  ")"
```

`nums` contains the numbers one through twenty, as a list of formats:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="nums-_LPAR_in-Grouping-and-Filling_RPAR_"></a>


```proofscript
const nums : List Format :=
  Nat.fold 20 (init := []) fun i _ ys =>
    text s!"{20 - i}" :: ys
```

```proofscript
#eval nums
```

Because `parenSeq` does not introduce any groups, the resulting document is rendered on a single line:

```proofscript
#eval IO.println (pretty (parenSeq nums))
```

This can be fixed by grouping them. `grouped` does so with `group`, while `filled` does so with `fill`.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="grouped-_LPAR_in-Grouping-and-Filling_RPAR_"></a>
<a id="filled-_LPAR_in-Grouping-and-Filling_RPAR_"></a>


```proofscript
const grouped := group (parenSeq nums)
const filled := fill (parenSeq nums)
```

Both grouping operators cause uses of `line` to render as spaces. Given sufficient space, both render on a single line:

```proofscript
#eval IO.println (pretty grouped)
```

```lean
( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 )
```

```proofscript
#eval IO.println (pretty filled)
```

```lean
( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 )
```

However, difference become apparent when there is not sufficient space on a single line. Unless *all* newlines in a `group` can be spaces, none can:

```proofscript
#eval IO.println (pretty (width := 30) grouped)
```

```lean
(
  1
  2
  3
  4
  5
  6
  7
  8
  9
  10
  11
  12
  13
  14
  15
  16
  17
  18
  19
  20
)
```

Using `fill`, on the other hand, only inserts newlines as required to avoid being two wide:

```proofscript
#eval IO.println (pretty (width := 30) filled)
```

```lean
( 1 2 3 4 5 6 7 8 9 10 11 12
  13 14 15 16 17 18 19 20 )
```

The behavior of `fill` can be seen clearly with longer sequences:

```proofscript
#eval IO.println <|
  pretty (width := 30) (fill (parenSeq (nums ++ nums ++ nums ++ nums)))
```

```lean
( 1 2 3 4 5 6 7 8 9 10 11 12
  13 14 15 16 17 18 19 20 1 2
  3 4 5 6 7 8 9 10 11 12 13 14
  15 16 17 18 19 20 1 2 3 4 5
  6 7 8 9 10 11 12 13 14 15 16
  17 18 19 20 1 2 3 4 5 6 7 8
  9 10 11 12 13 14 15 16 17 18
  19 20 )
```

<a id="Newline-Characters-in-Strings"></a>
Newline Characters in Strings 

Including a newline character in a string causes the rendering process to unconditionally insert a newline. These newlines do, however, respect the current indentation level.

The document `str` consists of an embedded string with two newlines:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="str-_LPAR_in-Newline-Characters-in-Strings_RPAR_"></a>


```proofscript
open Std Format

const str : Format := text "abc\nxyz\n123"
```

Printing the string both with and without grouping results in the newlines being used:

```proofscript
#eval IO.println str.pretty
```

```lean
abc
xyz
123
```

```proofscript
#eval IO.println (group str).pretty
```

```lean
abc
xyz
123
```

Because the string does not terminate with a newline, the last line of the first string is on the same line as the first line of the second string:

```proofscript
#eval IO.println (str ++ str).pretty
```

```lean
abc
xyz
123abc
xyz
123
```

Increasing the indentation level, however, causes all three lines of the string to begin at the same column:

```proofscript
#eval IO.println (text "It is:" ++ indentD str).pretty
```

```lean
It is:
  abc
  xyz
  123
```

```proofscript
#eval IO.println (nest 8 <| text "It is:" ++ align true ++ str).pretty
```

```lean
It is:  abc
        xyz
        123
```

<a id="format-api"></a>
##### 3.7.1.1. Documents

<a id="Std___Format___nil"></a>

**inductive type**

```text
Std.Format : Type
```

A representation of a set of strings, in which the placement of newlines and indentation differ.

Given a specific line width, specified in columns, the string that uses the fewest lines can be selected.

The pretty-printing algorithm is based on Wadler's paper [*A Prettier Printer*](https://homepages.inf.ed.ac.uk/wadler/papers/prettier/prettier.pdf).

**Constructors**

```text
Std.Format.nil : Std.Format
```

The empty format.

```text
Std.Format.line : Std.Format
```

A position where a newline may be inserted if the current group does not fit within the allotted column width.

```text
Std.Format.align (force : Bool) : Std.Format
```

`align` tells the formatter to pad with spaces to the current indentation level, or else add a newline if we are already at or past the indent.

If `force` is true, then it will pad to the indent even if it is in a flattened group.

Example:

```text
open Std Format in
#eval IO.println (nest 2 <| "." ++ align ++ "a" ++ line ++ "b")
```

```proofscript
. a
  b
```

```text
Std.Format.text : String → Std.Format
```

A node containing a plain string.

If the string contains newlines, the formatter emits them and then indents to the current level.

```text
Std.Format.nest (indent : Int) (f : Std.Format) : Std.Format
```

`nest indent f` increases the current indentation level by `indent` while rendering `f`.

Example:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->

```proofscript
open Std Format in
function fmtList (l : List Format) : Format :=
  let f := joinSep l  ("," ++ Format.line)
  group (nest 1 <| "[" ++ f ++ "]")
```

This will be written all on one line, but if the text is too large, the formatter will put in linebreaks after the commas and indent later lines by 1.

```text
Std.Format.append : Std.Format → Std.Format → Std.Format
```

Concatenation of two `Format`s.

```text
Std.Format.group :
  Std.Format →
    (behavior :
        optParam Std.Format.FlattenBehavior
          Std.Format.FlattenBehavior.allOrNone) →
      Std.Format
```

Creates a new flattening group for the given inner `Format`.

```text
Std.Format.tag : Nat → Std.Format → Std.Format
```

Used for associating auxiliary information (e.g. `Expr`s) with `Format` objects.

<a id="Std___Format___FlattenBehavior___allOrNone"></a>

**inductive type**

```text
Std.Format.FlattenBehavior : Type
```

Determines how groups should have linebreaks inserted when the text would overfill its remaining space.

- `allOrNone` will make a linebreak on every `Format.line` in the group or none of them.

   

  ```proofscript
  [1,
   2,
   3]
  ```
- `fill` will only make linebreaks on as few `Format.line`s as possible:

   

  ```proofscript
  [1, 2,
   3]
  ```

**Constructors**

```text
Std.Format.FlattenBehavior.allOrNone :
  Std.Format.FlattenBehavior
```

Either all `Format.line`s in the group will be newlines, or all of them will be spaces.

```text
Std.Format.FlattenBehavior.fill : Std.Format.FlattenBehavior
```

As few `Format.line`s in the group as possible will be newlines.

<a id="Std___Format___fill"></a>

**def**

```text
Std.Format.fill (f : Std.Format) : Std.Format
```

Creates a group in which as few `Format.line`s as possible are rendered as newlines.

This is an alias for `Format.group`, with `FlattenBehavior` set to `fill`.

<a id="format-empty"></a>
##### 3.7.1.2. Empty Documents

The empty string does not have a single unique representative in `Std.Format`. All of the following represent the empty string:

- `.nil`
- `.text ""`
- `.text "" ++ .nil`
- `.nil ++ .text ""`

Use `Std.Format.isEmpty` to check whether a document contains zero characters, and `Std.Format.isNil` to specifically check whether it is the constructor `Std.Format.nil`.

<a id="Std___Format___isEmpty"></a>

**def**

```text
Std.Format.isEmpty : Std.Format → Bool
```

Checks whether the given format contains no characters.

<a id="Std___Format___isNil"></a>

**def**

```text
Std.Format.isNil : Std.Format → Bool
```

Checks whether a `Format` is the constructor `Format.nil`.

This does not check whether the resulting rendered strings are always empty. To do that, use `Format.isEmpty`.

<a id="format-join"></a>
##### 3.7.1.3. Sequences

The operators in this section are useful when there is some kind of repeated content, such as the elements of a list. This is typically done by including `line` in their separator parameters, using a [bracketing operator](index.md#format-brackets)

<a id="Std___Format___join"></a>

**def**

```text
Std.Format.join (xs : List Std.Format) : Std.Format
```

Concatenates a list of `Format`s with `++`.

<a id="Std___Format___joinSep"></a>

**def**

```text
Std.Format.joinSep.{u} {α : Type u} [Std.ToFormat α] :
  List α → Std.Format → Std.Format
```

Intercalates the given list with the given `sep` format.

The list items are formatting using `ToFormat.format`.

<a id="Std___Format___prefixJoin"></a>

**def**

```text
Std.Format.prefixJoin.{u} {α : Type u} [Std.ToFormat α]
  (pre : Std.Format) : List α → Std.Format
```

Concatenates the given list after prepending `pre` to each element.

The list items are formatting using `ToFormat.format`.

<a id="Std___Format___joinSuffix"></a>

**def**

```text
Std.Format.joinSuffix.{u} {α : Type u} [Std.ToFormat α] :
  List α → Std.Format → Std.Format
```

Concatenates the given list after appending the given suffix to each element.

The list items are formatting using `ToFormat.format`.

<a id="format-indent"></a>
##### 3.7.1.4. Indentation

These operators make it easier to achieve a consistent indentation style on top of `Std.Format.nest`.

<a id="Std___Format___nestD"></a>

**def**

```text
Std.Format.nestD (f : Std.Format) : Std.Format
```

Increases the indentation level by the default amount.

<a id="Std___Format___defIndent"></a>

**def**

```text
Std.Format.defIndent : Nat
```

The default indentation level, which is two spaces.

<a id="Std___Format___indentD"></a>

**def**

```text
Std.Format.indentD (f : Std.Format) : Std.Format
```

Insert a newline and then `f`, all nested by the default indent amount.

<a id="format-brackets"></a>
##### 3.7.1.5. Brackets and Parentheses

These operators make it easier to achieve a consistent parenthesization style.

<a id="Std___Format___bracket"></a>

**def**

```text
Std.Format.bracket (l : String) (f : Std.Format) (r : String) :
  Std.Format
```

Creates a format `l ++ f ++ r` with a flattening group, nesting the contents by the length of `l`.

The group's `FlattenBehavior` is `allOrNone`; for `fill` use `Std.Format.bracketFill`.

<a id="Std___Format___sbracket"></a>

**def**

```text
Std.Format.sbracket (f : Std.Format) : Std.Format
```

Creates the format `"[" ++ f ++ "]"` with a flattening group, nesting by one space.

`sbracket` is short for “square bracket”.

<a id="Std___Format___paren"></a>

**def**

```text
Std.Format.paren (f : Std.Format) : Std.Format
```

Creates the format `"(" ++ f ++ ")"` with a flattening group, nesting by one space.

<a id="Std___Format___bracketFill"></a>

**def**

```text
Std.Format.bracketFill (l : String) (f : Std.Format) (r : String) :
  Std.Format
```

Creates a format `l ++ f ++ r` with a flattening group, nesting the contents by the length of `l`.

The group's `FlattenBehavior` is `fill`; for `allOrNone` use `Std.Format.bracket`.

<a id="format-render"></a>
##### 3.7.1.6. Rendering

The `ToString Std.Format` instance invokes `Std.Format.pretty` with its default arguments.

There are two ways to render a document:

- Use `pretty` to construct a `String`. The entire string must be constructed up front before any can be sent to a user.
- Use `prettyM` to incrementally emit the `String`, using effects in some `Monad`. As soon as each line is rendered, it is emitted. This is suitable for streaming output.

<a id="Std___Format___pretty"></a>

**def**

```text
Std.Format.pretty (f : Std.Format) (width : Nat := Std.Format.defWidth)
  (indent column : Nat := 0) : String
```

Renders a `Format` to a string.

- `width`: the total width
- `indent`: the initial indentation to use for wrapped lines (subsequent wrapping may increase the indentation)
- `column`: begin the first line wrap `column` characters earlier than usual (this is useful when the output String will be printed starting at `column`)

<a id="Std___Format___defWidth"></a>

**def**

```text
Std.Format.defWidth : Nat
```

The default width of the targeted output, which is 120 columns.

<a id="Std___Format___prettyM"></a>

**def**

```text
Std.Format.prettyM {m : Type → Type} (f : Std.Format) (w : Nat)
  (indent : Nat := 0) [Monad m] [Std.Format.MonadPrettyFormat m] :
  m Unit
```

Renders a `Format` using effects in the monad `m`, using the methods of `MonadPrettyFormat`.

Each line is emitted as soon as it is rendered, rather than waiting for the entire document to be rendered.

- `w`: the total width
- `indent`: the initial indentation to use for wrapped lines (subsequent wrapping may increase the indentation)

<a id="Std___Format___MonadPrettyFormat___mk"></a>

**type class**

```text
Std.Format.MonadPrettyFormat (m : Type → Type) : Type
```

A monad that can be used to incrementally render `Format` objects.

**Instance Constructor**

```text
Std.Format.MonadPrettyFormat.mk
```

**Methods**

```text
pushOutput : String → m Unit
```

Emits the string `s`.

```text
pushNewline : Nat → m Unit
```

Emits a newline followed by `indent` columns of indentation.

```text
currColumn : m Nat
```

Gets the current column at which the next string will be emitted.

```text
startTag : Nat → m Unit
```

Starts a region tagged with `tag`.

```text
endTags : Nat → m Unit
```

Exits the scope of `count` opened tags.

<a id="The-Lean-Language-Reference--Interacting-with-Lean--Formatted-Output--Format--The--ToFormat--Class"></a>
##### 3.7.1.7. The ToFormat Class

The `Std.ToFormat` class is used to provide a standard means to format a value, with no expectation that this formatting be valid Lean syntax. These instances are used in error messages and by some of the [sequence concatenation operators](index.md#format-join).

<a id="Std___ToFormat___mk"></a>

**type class**

```text
Std.ToFormat.{u} (α : Type u) : Type u
```

Specifies a “user-facing” way to convert from the type `α` to a `Format` object. There is no expectation that the resulting string is valid code.

The `Repr` class is similar, but the expectation is that instances produce valid Lean code.

**Instance Constructor**

```text
Std.ToFormat.mk.{u}
```

**Methods**

```text
format : α → Std.Format
```

Converts a value to a `Format` object, with no expectation that the resulting string is valid code.

<a id="repr"></a>
#### 3.7.2. Repr

A `Repr` instance describes how to represent a value as a `Std.Format`. Because they should emit valid Lean syntax, these instances need to take [precedence](../Notations-and-Macros/Custom-Operators/index.md#--tech-term-precedence) into account. Inserting the maximal number of parentheses would work, but it makes it more difficult for humans to read the resulting output.

<a id="Repr___mk"></a>

**type class**

```text
Repr.{u} (α : Type u) : Type u
```

The standard way of turning values of some type into `Format`.

When rendered this `Format` should be as close as possible to something that can be parsed as the input value.

**Instance Constructor**

```text
Repr.mk.{u}
```

**Methods**

```text
reprPrec : α → Nat → Std.Format
```

Turn a value of type `α` into a `Format` at a given precedence. The precedence value can be used to avoid parentheses if they are not necessary.

<a id="repr-next"></a>

**def**

```text
repr.{u_1} {α : Type u_1} [Repr α] (a : α) : Std.Format
```

Turns `a` into a `Format` using its `Repr` instance. The precedence level is initially set to 0.

<a id="reprStr"></a>

**def**

```text
reprStr.{u_1} {α : Type u_1} [Repr α] (a : α) : String
```

Turns `a` into a `String` using its `Repr` instance, rendering the `Format` at the default width of 120 columns.

The precedence level is initially set to 0.

<a id="Maximal-Parentheses"></a>
Maximal Parentheses 

The type `NatOrInt` can contain a `Nat` or an `Int`:
<a id="NatOrInt-_LPAR_in-Maximal-Parentheses_RPAR_"></a>
<a id="NatOrInt___nat-_LPAR_in-Maximal-Parentheses_RPAR_"></a>
<a id="NatOrInt___int-_LPAR_in-Maximal-Parentheses_RPAR_"></a>


```proofscript
inductive NatOrInt where
  | nat : Nat → NatOrInt
  | int : Int → NatOrInt
```

This `Repr NatOrInt` instance ensures that the output is valid Lean syntax by inserting many parentheses:

```proofscript
instance : Repr NatOrInt where
  reprPrec x _ :=
    .nestD <| .group <|
      match x with
      | .nat n =>
          .text "(" ++ "NatOrInt.nat" ++ .line ++ "(" ++ repr n ++ "))"
      | .int i =>
          .text "(" ++ "NatOrInt.int" ++ .line ++ "(" ++ repr i ++ "))"
```

Whether it contains a `Nat`, a non-negative `Int`, or a negative `Int`, the result can be parsed:

```proofscript
open NatOrInt in
#eval do
  IO.println <| repr <| nat 3
  IO.println <| repr <| int 5
  IO.println <| repr <| int (-5)
```

```lean
(NatOrInt.nat (3))
(NatOrInt.int (5))
(NatOrInt.int (-5))
```

However, `(NatOrInt.nat (3))` is not particularly idiomatic Lean, and redundant parentheses can make it difficult to read large expressions.

The method `Repr.reprPrec` has the following signature:

```proofscript
Repr.reprPrec.{u} {α : Type u} [Repr α] : α → Nat → Std.Format
```

The first explicit parameter is the value to be represented, while the second is the [precedence](../Notations-and-Macros/Custom-Operators/index.md#--tech-term-precedence) of the context in which it occurs. This precedence can be used to decide whether to insert parentheses: if the precedence of the syntax being produced by the instance is greater than that of its context, parentheses are necessary.

<a id="repr-instance-howto"></a>
##### 3.7.2.1. How To Write a Repr Instance

Lean can produce an appropriate `Repr` instance for most types automatically using [instance deriving](../Type-Classes/Deriving-Instances/index.md#deriving-instances). In some cases, however, it's necessary to write an instance by hand:

When writing a custom `Repr` instance, please follow these conventions:

  Precedence

Check precedence, adding parentheses as needed, and pass the correct precedence to the `reprPrec` instances of embedded data. Each instance is responsible for surrounding itself in parentheses if needed; instances should generally not parenthesize recursive calls to `reprPrec`.

Function application has the maximum precedence, `max_prec`. The helpers `Repr.addAppParen` and `reprArg` respectively insert parentheses around applications when needed and pass the appropriate precedence to function arguments.

  Fully-Qualified Names

A `Repr` instance does have access to the set of open namespaces in a given position. All names of constants in the environment should be fully qualified to remove ambiguity.

  Default Nesting

Nested data should be indented using `nestD` to ensure consistent indentation across instances.

  Grouping and Line Breaks

The output of every `Repr` instance that includes line breaks should be surrounded in a `group`. Furthermore, if the resulting code contains notional expressions that are nested, a `group` should be inserted around each nested level. Line breaks should usually be inserted in the following positions:

- Between a constructor and each of its arguments
- After `:=`
- After `,`
- Between the opening and closing braces of [structure instance](../The-Type-System/Inductive-Types/index.md#--tech-term-structure-instance) notation and its contents
- After, but not before, an infix operator

  Parentheses and Brackets

Parentheses and brackets should be inserted using `Std.Format.bracket` or its specializations `Std.Format.paren` for parentheses and `Std.Format.sbracket` for square brackets. These operators align the contents of the parenthesized or bracketed expression in the same way that Lean's do. Trailing parentheses and brackets should not be placed on their own line, but rather stay with their contents.

<a id="Repr___addAppParen"></a>

**def**

```text
Repr.addAppParen (f : Std.Format) (prec : Nat) : Std.Format
```

Adds parentheses to `f` if the precedence `prec` from the context is at least that of function application.

Together with `reprArg`, this can be used to correctly parenthesize function application syntax.

<a id="reprArg"></a>

**def**

```text
reprArg.{u_1} {α : Type u_1} [Repr α] (a : α) : Std.Format
```

Turns `a` into a `Format` using its `Repr` instance, with the precedence level set to that of function application.

Together with `Repr.addAppParen`, this can be used to correctly parenthesize function application syntax.

<a id="Inductive-Types-with-Constructors"></a>
Inductive Types with Constructors 

The inductive type `N.NatOrInt` can contain a `Nat` or an `Int`:
<a id="N___NatOrInt-_LPAR_in-Inductive-Types-with-Constructors_RPAR_"></a>
<a id="N___NatOrInt___nat-_LPAR_in-Inductive-Types-with-Constructors_RPAR_"></a>
<a id="N___NatOrInt___int-_LPAR_in-Inductive-Types-with-Constructors_RPAR_"></a>


```proofscript
namespace N

inductive NatOrInt where
  | nat : Nat → NatOrInt
  | int : Int → NatOrInt
```

The `Repr NatOrInt` instance adheres to the conventions:

- The right-hand side is a function application, so it uses `Repr.addAppParen` to add parentheses if necessary.
- Parentheses are wrapped around the entire body with no additional `line`s.
- The entire function application is grouped, and it is nested the default amount.
- The function is separated from its parameters by a use of `line`; this newline will usually be a space because the `Repr Nat` and `Repr Int` instances are unlikely to produce long output.
- Recursive calls to `reprPrec` pass `max_prec` because they are in function parameter positions, and function application has the highest precedence.

```proofscript
instance : Repr NatOrInt where
  reprPrec
    | .nat n =>
      Repr.addAppParen <|
        .group <| .nestD <|
          "N.NatOrInt.nat" ++ .line ++ reprPrec n max_prec
    | .int i =>
      Repr.addAppParen <|
        .group <| .nestD <|
          "N.NatOrInt.int" ++ .line ++ reprPrec i max_prec
```

```proofscript
#eval IO.println (repr (NatOrInt.nat 5))
```

```lean
N.NatOrInt.nat 5
```

```proofscript
#eval IO.println (repr (NatOrInt.int 5))
```

```lean
N.NatOrInt.int 5
```

```proofscript
#eval IO.println (repr (NatOrInt.int (-5)))
```

```lean
N.NatOrInt.int (-5)
```

```proofscript
#eval IO.println (repr (some (NatOrInt.int (-5))))
```

```lean
some (N.NatOrInt.int (-5))
```

```proofscript
#eval IO.println (repr <| (List.range 10).map (NatOrInt.nat))
```

```lean
[N.NatOrInt.nat 0,
 N.NatOrInt.nat 1,
 N.NatOrInt.nat 2,
 N.NatOrInt.nat 3,
 N.NatOrInt.nat 4,
 N.NatOrInt.nat 5,
 N.NatOrInt.nat 6,
 N.NatOrInt.nat 7,
 N.NatOrInt.nat 8,
 N.NatOrInt.nat 9]
```

```proofscript
#eval IO.println <|
  Std.Format.pretty (width := 3) <|
    repr <| (List.range 10).map NatOrInt.nat
```

```lean
[N.NatOrInt.nat
   0,
 N.NatOrInt.nat
   1,
 N.NatOrInt.nat
   2,
 N.NatOrInt.nat
   3,
 N.NatOrInt.nat
   4,
 N.NatOrInt.nat
   5,
 N.NatOrInt.nat
   6,
 N.NatOrInt.nat
   7,
 N.NatOrInt.nat
   8,
 N.NatOrInt.nat
   9]
```

<a id="Infix-Syntax"></a>
Infix Syntax 

This example demonstrates the use of precedences to encode a left-associative pretty printer. The type `AddExpr` represents expressions with constants and addition:
<a id="AddExpr-_LPAR_in-Infix-Syntax_RPAR_"></a>
<a id="AddExpr___nat-_LPAR_in-Infix-Syntax_RPAR_"></a>
<a id="AddExpr___add-_LPAR_in-Infix-Syntax_RPAR_"></a>


```proofscript
inductive AddExpr where
  | nat : Nat → AddExpr
  | add : AddExpr → AddExpr → AddExpr
```

The `OfNat` and `Add` instances provide a more convenient syntax for `AddExpr`:

```proofscript
instance : OfNat AddExpr n where
  ofNat := .nat n

instance : Add AddExpr where
  add := .add
```

The `Repr AddExpr` instance should insert only the necessary parentheses. Lean's addition operator is left-associative, with precedence 65, so the recursive call to the left uses precedence 64 and the operator itself is parenthesized if the current context has precedence greater than or equal to 65:
<a id="AddExpr___reprPrec-_LPAR_in-Infix-Syntax_RPAR_"></a>


```proofscript
protected def AddExpr.reprPrec : AddExpr → Nat → Std.Format
  | .nat n, p  =>
    Repr.reprPrec n p
  | .add e1 e2, p =>
    let out : Std.Format :=
      .nestD <| .group <|
        AddExpr.reprPrec e1 64 ++ " " ++ "+" ++ .line ++
        AddExpr.reprPrec e2 65
    if p ≥ 65 then out.paren else out

instance : Repr AddExpr := ⟨AddExpr.reprPrec⟩
```

Regardless of the input's parenthesization, this instance inserts only the necessary parentheses:

```proofscript
#eval IO.println (repr (((2 + 3) + 4) : AddExpr))
```

```lean
2 + 3 + 4
```

```proofscript
#eval IO.println (repr ((2 + 3 + 4) : AddExpr))
```

```lean
2 + 3 + 4
```

```proofscript
#eval IO.println (repr ((2 + (3 + 4)) : AddExpr))
```

```lean
2 + (3 + 4)
```

```proofscript
#eval IO.println (repr ([2 + (3 + 4), (2 + 3) + 4] : List AddExpr))
```

```lean
[2 + (3 + 4), 2 + 3 + 4]
```

The uses of `group`, `nestD`, and `line` in the implementation lead to the expected newlines and indentation in a narrow context:

```proofscript
#eval ([2 + (3 + 4), (2 + 3) + 4] : List AddExpr)
  |> repr
  |>.pretty (width := 0)
  |> IO.println
```

```lean
[2 +
   (3 +
      4),
 2 +
     3 +
   4]
```

<a id="ReprAtom"></a>
##### 3.7.2.2. Atomic Types

When the elements of a list are sufficiently small, it can be both difficult to read and wasteful of space to render the list with one element per line. To improve readability, `List` has two `Repr` instances: one that uses `Std.Format.bracket` for its contents, and one that uses `Std.Format.bracketFill`. The latter is defined after the former and is thus selected when possible; however, it requires an instance of the empty type class `ReprAtom`.

If the `Repr` instance for a type never generates spaces or newlines, then it should have a `ReprAtom` instance. Lean has `ReprAtom` instances for types such as `String`, `UInt8`, `Nat`, `Char`, and `Bool`.

<a id="ReprAtom___mk"></a>

**type class**

```text
ReprAtom.{u} (α : Type u) : Type
```

Auxiliary class for marking types that should be considered atomic by `Repr` methods. We use it at `Repr (List α)` to decide whether `bracketFill` should be used or not.

**Instance Constructor**

```text
ReprAtom.mk.{u}
```

<a id="Atomic-Types-and--Repr"></a>
Atomic Types and `Repr` 

All constructors of the inductive type `ABC` are without parameters:
<a id="ABC-_LPAR_in-Atomic-Types-and--Repr_RPAR_"></a>
<a id="ABC___a-_LPAR_in-Atomic-Types-and--Repr_RPAR_"></a>
<a id="ABC___b-_LPAR_in-Atomic-Types-and--Repr_RPAR_"></a>
<a id="ABC___c-_LPAR_in-Atomic-Types-and--Repr_RPAR_"></a>


```proofscript
inductive ABC where
  | a
  | b
  | c
deriving Repr
```

The derived `Repr ABC` instance is used to display lists:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="abc-_LPAR_in-Atomic-Types-and--Repr_RPAR_"></a>
<a id="abcs-_LPAR_in-Atomic-Types-and--Repr_RPAR_"></a>


```proofscript
const abc : List ABC := [.a, .b, .c]

const abcs : List ABC := abc ++ abc ++ abc

#eval IO.println ((repr abcs).pretty (width := 14))
```

Because of the narrow width, line breaks are inserted:

```lean
[ABC.a,
 ABC.b,
 ABC.c,
 ABC.a,
 ABC.b,
 ABC.c,
 ABC.a,
 ABC.b,
 ABC.c]
```

However, converting the list to a `List Nat` leads to a differently-formatted result.
<a id="ABC___toNat-_LPAR_in-Atomic-Types-and--Repr_RPAR_"></a>


```proofscript
def ABC.toNat : ABC → Nat
  | .a => 0
  | .b => 1
  | .c => 2

#eval IO.print ((repr (abcs.map ABC.toNat)).pretty (width := 14))
```

There are far fewer line breaks:

```lean
[0, 1, 2, 0,
 1, 2, 0, 1,
 2]
```

This is because of the existence of a `ReprAtom Nat` instance. Adding one for `ABC` leads to similar behavior:

```proofscript
instance : ReprAtom ABC := ⟨⟩

#eval IO.println ((repr abcs).pretty (width := 14))
```

```lean
[ABC.a, ABC.b,
 ABC.c, ABC.a,
 ABC.b, ABC.c,
 ABC.a, ABC.b,
 ABC.c]
```

## Preserved grammar annotations

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
`#eval e` evaluates the expression `e` by compiling it and running the compiled code. It then
prints the resulting value.

* The command attempts to use `ToExpr`, `Repr`, or `ToString` instances to print the result.
* If `e` is a monadic value of type `m ty`, then the command tries to adapt the monad `m`
  to one of the monads that `#eval` supports, which include `IO`, `CoreM`, `MetaM`, `TermElabM`, and `CommandElabM`.
  Users can define `MonadEval` instances to extend the list of supported monads.

The `#eval` command gracefully degrades in capability depending on what is imported.
Importing the `Lean.Elab.Command` module provides full capabilities.

Due to unsoundness, `#eval` refuses to evaluate expressions that depend on `sorry`, even indirectly,
since the presence of `sorry` can lead to runtime instability and crashes.
This check can be overridden with the `#eval! e` command.

Options:
* If `eval.pp` is true (default: true) then tries to use `ToExpr` instances to make use of the
  usual pretty printer. Otherwise, only tries using `Repr` and `ToString` instances.
* If `eval.type` is true (default: false) then pretty prints the type of the evaluated value.
* If `eval.derive.repr` is true (default: true) then attempts to auto-derive a `Repr` instance
  when there is no other way to print the result.

See also: `#reduce e` for evaluation by term reduction.
```


### Display 2


```text
`#reduce <expression>` reduces the expression `<expression>` to its normal form. This
involves applying reduction rules until no further reduction is possible.

By default, proofs and types within the expression are not reduced. Use modifiers
`(proofs := true)`  and `(types := true)` to reduce them.
Recall that propositions are types in Lean.

**Warning:** This can be a computationally expensive operation,
especially for complex expressions.

Consider using `#eval <expression>` for simple evaluation/execution
of expressions.
```


### Display 3


```text
Configuration for the `#reduce` command.
```


### Display 4


```text
Prints the axioms used by a declaration, directly or indirectly.
Please consult [the reference manual](https://lean-lang.org/doc/reference/4.34.0-rc2/find/?domain=Verso.Genre.Manual.section&name=validating-proofs) to understand the significance of the output.
```


### Display 5


```text
`#where` gives a description of the state of the current scope scope.
This includes the current namespace, `open` namespaces, `universe` and `variable` commands,
and options set with `set_option`.
```


### Display 6


```text
Shows the current Lean version. Prints `Lean.versionString`.
```


### Display 7


````text
`/-- ... -/ #guard_msgs in cmd` captures the messages generated by the command `cmd`
and checks that they match the contents of the docstring.

Basic example:
```lean
/--
error: Unknown identifier `x`
-/
#guard_msgs in
example : α := x
```
This checks that there is such an error and then consumes the message.

By default, the command captures all messages, but the filter condition can be adjusted.
For example, we can select only warnings:
```lean
/--
warning: declaration uses 'sorry'
-/
#guard_msgs(warning) in
example : α := sorry
```
or only errors
```lean
#guard_msgs(error) in
example : α := sorry
```
In the previous example, since warnings are not captured there is a warning on `sorry`.
We can drop the warning completely with
```lean
#guard_msgs(error, drop warning) in
example : α := sorry
```

In general, `#guard_msgs` accepts a comma-separated list of configuration clauses in parentheses:
```
#guard_msgs (configElt,*) in cmd
```
By default, the configuration list is
`(check all, whitespace := normalized, ordering := exact, positions := false)`.

Message filters select messages by severity:
- `info`, `warning`, `error`: (non-trace) messages with the given severity level.
- `trace`: trace messages
- `all`: all messages.

The filters can be prefixed with the action to take:
- `check` (the default): capture and check the message
- `drop`: drop the message
- `pass`: let the message pass through

If no filter is specified, `check all` is assumed.  Otherwise, these filters are processed in
left-to-right order, with an implicit `pass all` at the end.

Whitespace handling (after trimming leading and trailing whitespace):
- `whitespace := exact` requires an exact whitespace match.
- `whitespace := normalized` converts all newline characters to a space before matching
  (the default). This allows breaking long lines.
- `whitespace := lax` collapses whitespace to a single space before matching.

Message ordering:
- `ordering := exact` uses the exact ordering of the messages (the default).
- `ordering := sorted` sorts the messages in lexicographic order.
  This helps with testing commands that are non-deterministic in their ordering.

Position reporting:
- `positions := true` reports the ranges of all messages relative to the line on which
  `#guard_msgs` appears.
- `positions := false` does not report position info.

Substring matching:
- `substring := true` checks that the docstring appears as a substring of the output
  (after whitespace normalization). This is useful when you only care about part of the message.
- `substring := false` (the default) requires exact matching (modulo whitespace normalization).

Stabilizing output:
When messages contain autogenerated names (e.g., metavariables like `?m.47`), the output may
differ between runs or Lean versions. Use `set_option pp.mvars.anonymous false` to replace
anonymous metavariables with `?_` while preserving user-named metavariables like `?a`.
Alternatively, `set_option pp.mvars false` replaces all metavariables with `?_`.
Similarly, `set_option pp.fvars.anonymous false` replaces loose free variable names like
`_fvar.22` with `_fvar._`.

For example, `#guard_msgs (error, drop all) in cmd` means to check errors and drop
everything else.

The command elaborator has special support for `#guard_msgs` for linting.
The `#guard_msgs` itself wants to capture linter warnings,
so it elaborates the command it is attached to as if it were a top-level command.
However, the command elaborator runs linters for *all* top-level commands,
which would include `#guard_msgs` itself, and would cause duplicate and/or uncaptured linter warnings.
The top-level command elaborator only runs the linters if `#guard_msgs` is not present.
````


### Display 8


```text
A `docComment` parses a "documentation comment" like `/-- foo -/`. This is not treated like
a regular comment (that is, as whitespace); it is parsed and forms part of the syntax tree structure.

At parse time, `docComment` checks the value of the `doc.verso` option. If it is true, the contents
are parsed as Verso markup. If not, the contents are treated as plain text or Markdown. Use
`plainDocComment` to always treat the contents as plain text.

A plain text doc comment node contains a `/--` atom and then the remainder of the comment, `foo -/`
in this example. Use `TSyntax.getDocString` to extract the body text from a doc string syntax node.
A Verso comment node contains the `/--` atom, the document's syntax tree, and a closing `-/` atom.
```


### Display 9


```text
A message filter specification for `#guard_msgs`.
- `info`, `warning`, `error`: capture (non-trace) messages with the given severity level.
- `trace`: captures trace messages
- `all`: capture all messages.

The filters can be prefixed with
- `check` (the default): capture and check the message
- `drop`: drop the message
- `pass`: let the message pass through

If no filter is specified, `check all` is assumed.  Otherwise, these filters are processed in
left-to-right order, with an implicit `pass all` at the end.
```


### Display 10


```text
Whitespace handling for `#guard_msgs`:
- `whitespace := exact` requires an exact whitespace match.
- `whitespace := normalized` converts all newline characters to a space before matching
  (the default). This allows breaking long lines.
- `whitespace := lax` collapses whitespace to a single space before matching.
In all cases, leading and trailing whitespace is trimmed before matching.
```


### Display 11


```text
Message ordering for `#guard_msgs`:
- `ordering := exact` uses the exact ordering of the messages (the default).
- `ordering := sorted` sorts the messages in lexicographic order.
  This helps with testing commands that are non-deterministic in their ordering.
```


## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
❌️ Docstring on `#guard_msgs` does not match generated message:

- info: [true, false]
+ error: Invalid `meta` definition `_eval`, `isEven` is not accessible here; consider adding `public meta import Eval.Even`
```


### Display 2


```text
Invalid `meta` definition `_eval`, `isEven` is not accessible here; consider adding `public meta import Eval.Even`
```


### Display 3


```text
Could not synthesize a `ToExpr`, `Repr`, or `ToString` instance for type
  Nat → Nat
```


### Display 4


```text
Quadrant.nw
```


### Display 5


```text
Could not synthesize a `ToExpr`, `Repr`, or `ToString` instance for type
  Quadrant
```


### Display 6


```text
fun x => x.succ
```


### Display 7


```text
fun x => (Nat.rec ⟨fun x => x, PUnit.unit⟩ (fun n n_ih => ⟨fun x => (n_ih.1 x).succ, n_ih⟩) x).1 1
```


### Display 8


```text
fun x => [x] : ?m.4 → List ?m.4
```


### Display 9


```text
fun x => x + x : (x : ?m.7) → ?m.8 x
```


### Display 10


```text
"one" + 1 : ?m.5
```


### Display 11


```text
failed to synthesize instance of type class
  HAdd String Nat ?m.5

Hint: Type class instance resolution failures can be inspected with the `set_option trace.Meta.synthInstance true` command.
```


### Display 12


```text
instHAdd
```


### Display 13


```text
@instHAdd Int Int.instAdd
```


### Display 14


```text
failed to synthesize
  HAdd Int String String

Hint: Additional diagnostic information may be available using the `set_option diagnostics true` command.
```


### Display 15


```text
'swap_eq_swap'' depends on axioms: [propext, Classical.choice, Quot.sound, swap_eq_swap'._native.bv_decide.ax_3]
```


### Display 16


```text
equations:
@[backward_defeq] theorem intersperse.eq_1.{u_1} : ∀ {α : Type u_1} (x y z : α) (zs : List α),
  intersperse x (y :: z :: zs) = y :: x :: intersperse x (z :: zs)
theorem intersperse.eq_2.{u_1} : ∀ {α : Type u_1} (x : α) (x_1 : List α),
  (∀ (y z : α) (zs : List α), x_1 = y :: z :: zs → False) → intersperse x x_1 = x_1
```


### Display 17


```text
intersperse.eq_def.{u_1} {α : Type u_1} (x : α) (x✝ : List α) :
  intersperse x x✝ =
    match x✝ with
    | y :: z :: zs => y :: x :: intersperse x (z :: zs)
    | xs => xs
```


### Display 18


```text
intersperse.eq_unfold.{u_1} :
  @intersperse = fun {α} x x_1 =>
    match x_1 with
    | y :: z :: zs => y :: x :: intersperse x (z :: zs)
    | xs => xs
```


### Display 19


```text
public section

namespace A.B

open Nat List

variable (n : Nat)

set_option pp.tagAppFns true
```


### Display 20


```text
declaration uses `sorry`
```


### Display 21


```text
❌️ Docstring on `#guard_msgs` does not match generated message:

info: Tree.branches
  [Tree.branches
     [Tree.branches
        [Tree.branches [Tree.val 2, Tree.val 1, Tree.val 2, Tree.val 0],
         Tree.branches [Tree.val 1, Tree.val 0, Tree.val 1, Tree.val 0]],
      Tree.branches [Tree.val 3, Tree.val 2, Tree.val 3, Tree.val 1]],
   Tree.branches
     [Tree.branches [Tree.val 3, Tree.val 2, Tree.val 3, Tree.val 1],
      Tree.branches [Tree.val 2, Tree.val 1, Tree.val 2, Tree.val 0]]]
```


### Display 22


```text
Tree.branches
  [Tree.branches
     [Tree.branches
        [Tree.branches [Tree.val 2, Tree.val 1, Tree.val 2, Tree.val 0],
         Tree.branches [Tree.val 1, Tree.val 0, Tree.val 1, Tree.val 0]],
      Tree.branches [Tree.val 3, Tree.val 2, Tree.val 3, Tree.val 1]],
   Tree.branches
     [Tree.branches [Tree.val 3, Tree.val 2, Tree.val 3, Tree.val 1],
      Tree.branches [Tree.val 2, Tree.val 1, Tree.val 2, Tree.val 0]]]
```


### Display 23


```text
❌️ Docstring on `#guard_msgs` does not match generated message:

  info: Tree.branches
    [Tree.branches
       [Tree.branches
          [Tree.branches [Tree.val 2, Tree.val 1, Tree.val 2, Tree.val 0],
-          Tree.branches [Tree.val 1, Tree.val 0, Tree.val 1, Tree.val 0,
+          Tree.branches [Tree.val 1, Tree.val 0, Tree.val 1, Tree.val 0]],
        Tree.branches [Tree.val 3, Tree.val 2, Tree.val 3, Tree.val 1]],
     Tree.branches
       [Tree.branches [Tree.val 3, Tree.val 2, Tree.val 3, Tree.val 1],
        Tree.branches [Tree.val 2, Tree.val 1, Tree.val 2, Tree.val 0]]]
```


### Display 24


```text
( 1 2 3 4 5 )
```


### Display 25


```text
(
  1
  2
  3
  4
  5
)
```


### Display 26


```text
( ( 1 2 3 4 5 ) ( 1 2 3 4 5 ) ( 1 2 3 4 5 ) )
```


### Display 27


```text
(
  ( 1 2 3 4 5 )
  ( 1 2 3 4 5 )
  ( 1 2 3 4 5 )
)
```


### Display 28


```text
(
  (
    1
    2
    3
    4
    5
  )
  (
    1
    2
    3
    4
    5
  )
  (
    1
    2
    3
    4
    5
  )
)
```


### Display 29


```text
[Std.Format.text "1",
 Std.Format.text "2",
 Std.Format.text "3",
 Std.Format.text "4",
 Std.Format.text "5",
 Std.Format.text "6",
 Std.Format.text "7",
 Std.Format.text "8",
 Std.Format.text "9",
 Std.Format.text "10",
 Std.Format.text "11",
 Std.Format.text "12",
 Std.Format.text "13",
 Std.Format.text "14",
 Std.Format.text "15",
 Std.Format.text "16",
 Std.Format.text "17",
 Std.Format.text "18",
 Std.Format.text "19",
 Std.Format.text "20"]
```


### Display 30


```text
(
  1
  2
  3
  4
  5
  6
  7
  8
  9
  10
  11
  12
  13
  14
  15
  16
  17
  18
  19
  20
)
```


### Display 31


```text
( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 )
```


### Display 32


```text
( 1 2 3 4 5 6 7 8 9 10 11 12
  13 14 15 16 17 18 19 20 )
```


### Display 33


```text
( 1 2 3 4 5 6 7 8 9 10 11 12
  13 14 15 16 17 18 19 20 1 2
  3 4 5 6 7 8 9 10 11 12 13 14
  15 16 17 18 19 20 1 2 3 4 5
  6 7 8 9 10 11 12 13 14 15 16
  17 18 19 20 1 2 3 4 5 6 7 8
  9 10 11 12 13 14 15 16 17 18
  19 20 )
```


### Display 34


```text
abc
xyz
123
```


### Display 35


```text
abc
xyz
123abc
xyz
123
```


### Display 36


```text
It is:
  abc
  xyz
  123
```


### Display 37


```text
It is:  abc
        xyz
        123
```


### Display 38


```text
(NatOrInt.nat (3))
(NatOrInt.int (5))
(NatOrInt.int (-5))
```


### Display 39


```text
N.NatOrInt.nat 5
```


### Display 40


```text
N.NatOrInt.int 5
```


### Display 41


```text
N.NatOrInt.int (-5)
```


### Display 42


```text
some (N.NatOrInt.int (-5))
```


### Display 43


```text
[N.NatOrInt.nat 0,
 N.NatOrInt.nat 1,
 N.NatOrInt.nat 2,
 N.NatOrInt.nat 3,
 N.NatOrInt.nat 4,
 N.NatOrInt.nat 5,
 N.NatOrInt.nat 6,
 N.NatOrInt.nat 7,
 N.NatOrInt.nat 8,
 N.NatOrInt.nat 9]
```


### Display 44


```text
[N.NatOrInt.nat
   0,
 N.NatOrInt.nat
   1,
 N.NatOrInt.nat
   2,
 N.NatOrInt.nat
   3,
 N.NatOrInt.nat
   4,
 N.NatOrInt.nat
   5,
 N.NatOrInt.nat
   6,
 N.NatOrInt.nat
   7,
 N.NatOrInt.nat
   8,
 N.NatOrInt.nat
   9]
```


### Display 45


```text
2 + 3 + 4
```


### Display 46


```text
2 + (3 + 4)
```


### Display 47


```text
[2 + (3 + 4), 2 + 3 + 4]
```


### Display 48


```text
[2 +
   (3 +
      4),
 2 +
     3 +
   4]
```


### Display 49


```text
[ABC.a,
 ABC.b,
 ABC.c,
 ABC.a,
 ABC.b,
 ABC.c,
 ABC.a,
 ABC.b,
 ABC.c]
```


### Display 50


```text
[0, 1, 2, 0,
 1, 2, 0, 1,
 2]
```


### Display 51


```text
[ABC.a, ABC.b,
 ABC.c, ABC.a,
 ABC.b, ABC.c,
 ABC.a, ABC.b,
 ABC.c]
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
⊢ swap = swap'
```


### Display 2


```text
x:BitVec 32y:BitVec 32⊢ swap x y = swap' x y
```


### Display 3


```text
x:BitVec 32y:BitVec 32⊢ y = x ^^^ y ^^^ (x ^^^ y ^^^ y) ∧ x = x ^^^ y ^^^ y
```


### Display 4


```text
All goals completed! 🐙
```

