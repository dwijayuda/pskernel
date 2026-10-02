# PSC3 design examples using ProofScript v0.7

**Syntax authority: [ProofScript v0.7](SYNTAX_AND_GRAMMAR_V07.md).** These are documentation/conformance candidates, not locally compiled proofs or implementation claims. `.ps` fences use `proofscript`; native/canonical `.lean` fences use `lean`; platform names and extension pseudocode are explicitly labelled.

## 1. Ordinary data and functions

Candidate `.ps` source using registered declaration/call/body forms:

```proofscript
import Init
set_option autoImplicit false

structure UserId where {
  value : Nat;
}

structure User where {
  id : UserId;
  name : String;
  active : Bool;
}

function names(users : List User) : List String :=
  users.map(fun user => user.name);

function activate(user : User) : User :=
  { user with active := true };
```

Corresponding canonical/native `.lean` source:

```lean
import Init
set_option autoImplicit false

structure UserId where
  value : Nat

structure User where
  id : UserId
  name : String
  active : Bool

def names (users : List User) : List String :=
  users.map (fun user => user.name)

def activate (user : User) : User :=
  { user with active := true }
```

The relationship is canonical lowering, not byte-identical staging. UserId is a distinct structure rather than an accidental alias for Nat. Conformance cases include empty lists, retained record fields, type errors, source maps, official canonical-Lean versus owned elaboration, runtime representations and exported DTO validation.

## 2. Explicit errors plus a useful theorem

```proofscript
import Init
set_option autoImplicit false

function debit(balance : Nat, amount : Nat) : Except String Nat :=
  if (amount ≤ balance) {
    Except.ok(balance - amount)
  } else {
    Except.error("insufficient balance")
  };

theorem debit_ok (balance amount : Nat) (h : amount ≤ balance) :
    debit(balance, amount) = Except.ok(balance - amount) := by {
  simp [debit, h]
}
```

The registered conditional has one term per branch. The theorem's tactic body retains its own grammar; do not globally insert declaration semicolons into it.

This is not a locally checked proof. If accepted, it establishes only the displayed property. It does not establish monetary units, authorization or concurrent persistence. More complete specifications cover errors and invariant preservation. Mutants include reversed comparisons, always-error results, incorrect subtraction and omitted errors; always failing must not satisfy a specification that promises success for valid inputs.

## 3. State modelling and constructor patterns

```proofscript
import Init
set_option autoImplicit false

inductive LoadState(ε : Type, α : Type) where {
  | idle;
  | loading(requestId : Nat);
  | success(requestId : Nat, value : α);
  | failure(requestId : Nat, error : ε);
}

function getOrElse(value : Option Nat, fallback : Nat) : Nat :=
  match value with {
    | .none => fallback;
    | .some x => x;
  };
```

Constructor declarations can use their registered parameter decoration. Patterns still use native Lean binding syntax: `.some x`, not `.some(x)`. Application state may use request IDs to reject stale results, but the data declaration alone does not implement cancellation or prove scheduler behavior.

## 4. Dependent data interaction

```proofscript
import Init
set_option autoImplicit false

structure SizedData where {
  size : Nat;
  data : Fin size -> Nat;
}

function replaceData(n : Nat, f : Fin n -> Nat) : SizedData :=
  { size := n, data := f };
```

A negative candidate updates size to an unrelated value while retaining arbitrary old data without evidence or replacement. It must be rejected or require dependent reconstruction, not an unchecked cast. Exact diagnostics and official-oracle acceptance are pending tests.

## 5. Mathematics and inherited scopes

```proofscript
import Init
set_option autoImplicit false
universe u

namespace Math

function twice {α : Type u}(f : α -> α, x : α) : α :=
  f(f(x));

theorem twice_id {α : Type u} (x : α) :
    twice(fun y => y, x) = x := by {
  rfl
}

end Math
```

`namespace ... end` is inherited command syntax; it is not converted to a braced command block. The corpus must also cover indexed induction, typeclasses, notation, classical assumptions and proof repair. A short theorem does not establish large-library readiness.

## 6. Contract syntax versus theorem specifications

The definition-plus-theorem example above is the base specification form. The earlier draft inspected upstream intrinsic verification at a proposed 4.34.1 pin [L03–L04](RESEARCH_SOURCES.md#lean-and-logical-foundations). Those experiments do not by themselves establish the v0.7/4.34.0 source profile.

Before adding executable intrinsic examples, verify the exact selected parser, imports/options, clause placement/count and generated-theorem behavior. Do not invent repeated `ensures`, a new final proof-section grammar, or automatic proof parameters. Missing/false obligations must fail. No intrinsic example is promoted here merely because it resembles a later upstream test.

## 7. Plain-source UI without new grammar

**Proposed library names, not available imports or an executed application.** The source spelling below follows v0.7:

```proofscript
import Psc.UI

inductive CounterMsg where {
  | increment;
  | reset;
}

function updateCounter(count : Nat, msg : CounterMsg) : Nat :=
  match msg with {
    | .increment => count + 1;
    | .reset => 0;
  };

function counterView(count : Nat) : View CounterMsg :=
  View.column([
    View.text(toString(count)),
    View.button(CounterMsg.increment, [View.text("Increment")]),
    View.button(CounterMsg.reset, [View.text("Reset")])
  ]);
```

An eventual runtime provides event decoding, serialized updates and rendering. The pure view does not prove DOM correctness. The optional `.psx` proposal must expand to the same ordinary library semantics without becoming unregistered base `.ps` grammar.

## 8. Complete application module layout

Proposed layout, not created executable code:

```text
Inventory/
  Domain/Item.ps
  Domain/Adjustment.ps
  Domain/AdjustmentProofs.ps
  Api/Inventory.ps
  Client/Model.ps
  Client/Update.ps
  Client/View.ps
  Client/Main.ps
  Server/Inventory.ps
  Server/Store.ps
  Server/Main.ps
```

A module may instead be authored as supported native `.lean`, selected by the one-source module map. Decorated `.ps` is translated before the Lean oracle; do not merely rename it or maintain diverging siblings. Optional `.psx` views require an explicit dialect and are not selected by suffix alone.

The full-app acceptance run builds browser/service/typed-client outputs and tests decoding, persistence, errors, cancellation and request ordering alongside an actual domain theorem. Database, renderer and compiler assumptions stay separate.

## 9. Foreign API contract

A proposed imported `getUser` operation identifies ID/User codecs, expected and unexpected errors, Promise attachment/start behavior and cancellation support. `.d.ts` shapes can inform, not prove, this interface.

Tests include missing exports, malformed data, negative bigint IDs, missing versus undefined fields, string rejection reasons, detached receivers, callbacks after disposal and stale responses. FFI package metadata does not authorize a new ESM-style source declaration in ordinary `.ps`.

## 10. Numerical example requirements

Use an explicit relationship between exact mathematical specifications and Float execution. Test error bounds, NaN, signed zero, overflow and input domains. An exact-arithmetic proof does not automatically establish floating-point behavior.

## 11. Grammar regression examples

Reference-derived distinctions, not executable test results:

```text
const n : Nat := 1;                  admitted alias form
function id(x : Nat) : Nat := x;     admitted alias form
f(x, y)                             two curried arguments
f((x, y))                           one tuple argument
f (x, y)                            protected native tuple application
function f(x : Nat) : Nat { x }      NOT admitted in v0.7
const n = 1                         NOT the v0.7 binding form
match v with { | .some(x) => x; }    NOT the v0.7 pattern form
namespace N { ... }                  NOT the v0.7 command form
```

Tests must exercise the actual parser/lowerer and the reference's registry/corpus. A documentation scan cannot certify grammar acceptance.

## 12. Evidence record

For each example, record original `.ps` or native `.lean`, environment identity, L/D/E features, canonical output where applicable, command/result, owned-checker verdict, targets, assumptions and exact theorem. Until run, examples remain unexecuted candidates. Official Lean acceptance of a canonical example alone does not prove PSC frontend, kernel or backend support.
