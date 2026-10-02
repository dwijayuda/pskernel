# PSC3 design examples

**Evidence status: none of the Lean/PSC examples in this file were compiled in this pass.** Lean/Lake were unavailable. Native examples are candidate conformance inputs; proposed platform APIs are clearly marked. Do not infer implementation support from plausible syntax.

## 1. Ordinary data and functions

Candidate native `.ps` contents, identical when staged as `.lean`:

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

This teaches data modelling and collection callbacks without a separate TS-like grammar. UserId is a distinct structure, not an abbreviation accidentally interchangeable with all natural numbers.

Conformance cases: empty list; record update retains other fields; user/name type errors; official Lean versus owned elaboration; both target representations; exported DTO validation.

## 2. Explicit errors plus a useful theorem

```lean
import Init
set_option autoImplicit false

def debit (balance amount : Nat) : Except String Nat :=
  if amount ≤ balance then
    .ok (balance - amount)
  else
    .error "insufficient balance"

theorem debit_ok (balance amount : Nat) (h : amount ≤ balance) :
    debit balance amount = .ok (balance - amount) := by
  simp [debit, h]
```

This is a candidate example, not a locally checked proof. It establishes only the displayed property if accepted. It does not establish monetary units, authorization, race-free persistence or a globally correct financial system. Applications should use domain-specific quantities and external models appropriate to their actual requirements.

A more complete specification would cover the error branch and invariant preservation. Mutants should include reversed comparison, always-error, incorrect subtraction and missing error handling. Returning an error for every input should not satisfy a contract that promises success for valid inputs.

## 3. Async state without an implicit null convention

```lean
import Init
set_option autoImplicit false

inductive LoadState (ε α : Type) where
  | idle
  | loading (requestId : Nat)
  | success (requestId : Nat) (value : α)
  | failure (requestId : Nat) (error : ε)
```

A proposed application update function compares response IDs to the current request before accepting a result. Tests must cover stale completion, cancelled navigation, retry and request-ID rollover policy. This data declaration alone does not implement a scheduler or prove those tests.

## 4. Dependent data interaction

```lean
import Init
set_option autoImplicit false

structure SizedData where
  size : Nat
  data : Fin size → Nat

def replaceData (n : Nat) (f : Fin n → Nat) : SizedData :=
  { size := n, data := f }
```

Negative candidate: update size to an unrelated n while trying to retain arbitrary old data without a transport proof or replacement. The implementation must reject or require the dependent fields, not insert an unchecked cast. Exact native diagnostics are a pending oracle test.

## 5. Mathematical abstraction

```lean
import Init
set_option autoImplicit false
universe u

def twice {α : Type u} (f : α → α) (x : α) : α := f (f x)

theorem twice_id {α : Type u} (x : α) :
    twice (fun y => y) x = x := by
  rfl
```

This is a small universal proof example. The design corpus must also include nontrivial indexed induction, typeclass abstractions, classical assumptions, notation and proof maintenance. A one-line theorem does not establish serious theorem-library readiness.

## 6. Native intrinsic verification

The upstream pinned test suite was inspected and shows contract-bearing Id/state computations, generated `.spec` declarations, invariants and separate runtime assertions. [L03–L04](RESEARCH_SOURCES.md#lean-and-logical-foundations)

Use a fresh, independently written candidate such as the following only in the experimental native profile:

```lean
import Std.Internal.Do
set_option experimental.intrinsic true
set_option autoImplicit false

def unchanged (n : Nat) : Id Nat
    ensures result => result = n :=
  pure n
```

The import, option and single-clause form follow inspected native facilities. This candidate was not checked here. No custom repeated `ensures`, hidden source rewrite or new proof parameter is implied. Negative cases must include an intentionally false postcondition and unresolved proof evidence.

## 7. Plain-source UI, no `.psx` required

**The following names are proposed library APIs, not available imports.**

```lean
-- Proposed library illustration only.
import Psc.UI

inductive CounterMsg where
  | increment
  | reset

def updateCounter (count : Nat) (msg : CounterMsg) : Nat :=
  match msg with
  | .increment => count + 1
  | .reset => 0

def counterView (count : Nat) : View CounterMsg :=
  View.column
    [ View.text (toString count)
    , View.button CounterMsg.increment [View.text "Increment"]
    , View.button CounterMsg.reset [View.text "Reset"]
    ]
```

An eventual runtime attaches event decoding, a serialized update loop and a renderer. The view's pure shape is not proof of DOM correctness. The exact same library calls are the target for the optional quotation example in [PSX](PSX_UI_PROPOSAL.md).

## 8. Complete application module layout

This is a proposed layout, not created executable code:

```text
Inventory/
  Domain/Item.lean
  Domain/Adjustment.lean
  Domain/AdjustmentProofs.lean
  Api/Inventory.lean
  Client/Model.lean
  Client/Update.lean
  Client/View.lean
  Client/Main.lean
  Server/Inventory.lean
  Server/Store.lean
  Server/Main.lean
```

Any ordinary module may instead use `.ps` under the explicit one-source mapping; do not maintain divergent siblings. Client and server share schemas, not secret capabilities. UI markup is an optional alternative view-authoring exercise, not required for the plain-source app.

The full-app acceptance run builds the browser, service and typed external client; exercises runtime decoding, persistence, errors, cancellation and request ordering; and checks a real domain theorem. It identifies the database, renderer and compiler assumptions separately.

## 9. Foreign API example contract

A proposed imported `getUser` operation specifies an input ID codec, an output User codec, a typed expected-error set, unexpected foreign failure, Promise start/attachment behavior and cancellation support. A `.d.ts` declaration can inform this contract but cannot prove it.

Tests include nonexistent export, malformed User, negative bigint ID, missing versus undefined field, rejection with a string, detached receiver, late callback after disposal and obsolete response ID. None is silently mapped to successful typed data.

## 10. Scientific/numerical example requirements

Add a numerical model whose mathematical specification uses exact values while its execution uses Float. State an error bound or other relation before claiming correspondence. Test NaN, signed zero, overflow and input domain. Do not declare the floating implementation correct merely because an exact-arithmetic theorem passed.

## 11. Expected evidence record

For every example record source/environment identity, expected parsing/elaboration result, actual command/output, owned-checker result, executable targets tested, assumptions, and the exact theorem when present. Until a command is run, the status remains candidate/unexecuted. Passing an upstream Lean test is not evidence that PSC's parser, kernel and emitters support the same example.
