<a id="Thunk"></a>

# ProofScript — 20.21. Lazy Computations

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Nat, Int, machine integers, floats, characters, strings, bytes, options, products, sums, lists, arrays, maps, ranges, subtypes and lazy computations retain their distinct native contracts. A target representation is not their meaning. Nat subtraction saturates at zero; the selected Int quotient differs from JavaScript BigInt truncation for some negative inputs. String offsets and Unicode conversions require explicit mappings.

**Compiler and coverage boundary.** The full API entries below retain exact names and signature metadata. Distinguish a signature display from executable source. Unknown reachable primitives reject the requested executable profile.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Basic-Types/Lazy-Computations/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Basic-Types/Lazy-Computations/index.html). Source Git blob: `e08cffdd9cd1b4a05fae759e1c101eebd77b1427`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 20.21. Lazy Computations

A 
<a id="--tech-term-thunk"></a>
*thunk* delays the computation of a value. In particular, the `Thunk` type is used to delay the computation of a value in compiled code until it is explicitly requested—this request is called 
<a id="--tech-term-forcing"></a>
*forcing* the thunk. The computed value is saved, so subsequent requests do not result in recomputation. Computing values at most once, when explicitly requested, is called 
<a id="--tech-term-lazy-evaluation"></a>
*lazy evaluation*.
<a id="--index--next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
 This caching is invisible to Lean's logic, in which `Thunk` is equivalent to a function from `Unit`.

<a id="Thunk-model"></a>
### 20.21.1. Logical Model

Thunks are modeled as a single-field structure that contains a function from `Unit`. The structure's field is private, so the function itself cannot be directly accessed. Instead, `Thunk.get` should be used. From the perspective of the logic, they are equivalent; `Thunk.get` exists to be overridden in the compiler by the platform primitive that implements lazy evaluation.

<a id="Thunk___mk"></a>

**structure**

```text
Thunk.{u} (α : Type u) : Type u
```

Delays evaluation. The delayed code is evaluated at most once.

A thunk is code that constructs a value when it is requested via `Thunk.get`, `Thunk.map`, or `Thunk.bind`. The resulting value is cached, so the code is executed at most once. This is also known as lazy or call-by-need evaluation.

The Lean runtime has special support for the `Thunk` type in order to implement the caching behavior.

**Constructor**

```text
Thunk.mk.{u}
```

Constructs a new thunk from a function `Unit → α` that will be called when the thunk is first forced.

The result is cached. It is re-used when the thunk is forced again.

**Fields**

```text
fn : Unit → α
```

Extract the getter function out of a thunk. Use `Thunk.get` instead.

<a id="Thunk-runtime"></a>
### 20.21.2. Runtime Representation

<a id="thunkffi"></a>
  Memory layout of thunks

Thunks are one of the primitive object types supported by the Lean runtime. The object header contains a specific tag that indicates that an object is a thunk.

Thunks have two fields:

- `m_value` is a pointer to a saved value, which is a null pointer if the value has not yet been computed.
- `m_closure` is a closure which is to be called when the value should be computed.

The runtime system maintains the invariant that either the closure or the saved value is a null pointer. If both are null pointers, then the thunk is being forced on another thread.

When a thunk is [forced](index.md#--tech-term-forcing), the runtime system first checks whether the saved value has already been computed, returning it if so. Otherwise, it attempts to acquire a lock on the closure by atomically swapping it with a null pointer. If the lock is acquired, it is invoked to compute the value; the computed value is stored in the saved value field and the reference to the closure is dropped. If not, then another thread is already computing the value; the system waits until it is computed.

<a id="Thunk-coercions"></a>
### 20.21.3. Coercions

There is a coercion from any type `α` to `Thunk α` that converts a term `e` into `Thunk.mk fun () => e`. Because the elaborator [unfolds coercions](../../Coercions/Coercion-Insertion/index.md#coercion-insertion), evaluation of the original term `e` is delayed; the coercion is not equivalent to `Thunk.pure`.

<a id="Lazy-Lists"></a>
Lazy Lists 

Lazy lists are lists that may contain thunks. The `delayed` constructor causes part of the list to be computed on demand.
<a id="LazyList-_LPAR_in-Lazy-Lists_RPAR_"></a>
<a id="LazyList___nil-_LPAR_in-Lazy-Lists_RPAR_"></a>
<a id="LazyList___cons-_LPAR_in-Lazy-Lists_RPAR_"></a>
<a id="LazyList___delayed-_LPAR_in-Lazy-Lists_RPAR_"></a>


```proofscript
inductive LazyList (α : Type u) where
  | nil
  | cons : α → LazyList α → LazyList α
  | delayed : Thunk (LazyList α) → LazyList α
deriving Inhabited
```

Lazy lists can be converted to ordinary lists by forcing all the embedded thunks.
<a id="LazyList___toList-_LPAR_in-Lazy-Lists_RPAR_"></a>


```proofscript
def LazyList.toList : LazyList α → List α
  | .nil => []
  | .cons x xs => x :: xs.toList
  | .delayed xs => xs.get.toList
```

Many operations on lazy lists can be implemented without forcing the embedded thunks, instead building up further thunks. The body of `delayed` does not need to be an explicit call to `Thunk.mk` because of the coercion.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="LazyList___take-_LPAR_in-Lazy-Lists_RPAR_"></a>
<a id="LazyList___ofFn-_LPAR_in-Lazy-Lists_RPAR_"></a>
<a id="LazyList___append-_LPAR_in-Lazy-Lists_RPAR_"></a>


```proofscript
def LazyList.take : Nat → LazyList α → LazyList α
  | 0, _ => .nil
  | _, .nil => .nil
  | n + 1, .cons x xs => .cons x <| .delayed <| take n xs
  | n + 1, .delayed xs => .delayed <| take (n + 1) xs.get

function LazyList.ofFn (f : Fin n → α) : LazyList α :=
  Fin.foldr n (init := .nil) fun i xs =>
    .delayed <| LazyList.cons (f i) xs

function LazyList.append (xs ys : LazyList α) : LazyList α :=
  .delayed <|
    match xs with
    | .nil => ys
    | .cons x xs' => LazyList.cons x (append xs' ys)
    | .delayed xs' => append xs'.get ys
```

Laziness is ordinarily invisible to Lean programs: there is no way to check whether a thunk has been forced. However, `dbg_trace` can be used to gain insight into thunk evaluation.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="observe-_LPAR_in-Lazy-Lists_RPAR_"></a>


```proofscript
function observe (tag : String) (i : Fin n) : Nat :=
  dbg_trace "{tag}: {i.val}"
  i.val
```

The lazy lists `xs` and `ys` emit traces when evaluated.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="xs-_LPAR_in-Lazy-Lists_RPAR_"></a>
<a id="ys-_LPAR_in-Lazy-Lists_RPAR_"></a>


```proofscript
const xs := LazyList.ofFn (n := 3) (observe "xs")
const ys := LazyList.ofFn (n := 3) (observe "ys")
```

Converting `xs` to an ordinary list forces all of the embedded thunks:

```proofscript
#eval xs.toList
```

```lean
xs: 0
xs: 1
xs: 2
```

```lean
[0, 1, 2]
```

Likewise, converting `xs.append ys` to an ordinary list forces the embedded thunks:

```proofscript
#eval xs.append ys |>.toList
```

```lean
xs: 0
xs: 1
xs: 2
ys: 0
ys: 1
ys: 2
```

```lean
[0, 1, 2, 0, 1, 2]
```

Appending `xs` to itself before forcing the thunks results in a single set of traces, because each thunk's code is evaluated just once:

```proofscript
#eval xs.append xs |>.toList
```

```lean
xs: 0
xs: 1
xs: 2
```

```lean
[0, 1, 2, 0, 1, 2]
```

Finally, taking a prefix of `xs.append ys` results in only some of the thunks in `ys` being evaluated:

```proofscript
#eval xs.append ys |>.take 4 |>.toList
```

```lean
xs: 0
xs: 1
xs: 2
ys: 0
```

```lean
[0, 1, 2, 0]
```

<a id="Thunk-api"></a>
### 20.21.4. API Reference

<a id="Thunk___get"></a>

**def**

```text
Thunk.get.{u_1} {α : Type u_1} (x : Thunk α) : α
```

Gets the thunk's value. If the value is cached, it is returned in constant time; if not, it is computed.

Computed values are cached, so the value is not recomputed.

<a id="Thunk___map"></a>

**def**

```text
Thunk.map.{u_1, u_2} {α : Type u_1} {β : Type u_2} (f : α → β)
  (x : Thunk α) : Thunk β
```

Constructs a new thunk that forces `x` and then applies `x` to the result. Upon forcing, the result of `f` is cached and the reference to the thunk `x` is dropped.

<a id="Thunk___pure"></a>

**def**

```text
Thunk.pure.{u_1} {α : Type u_1} (a : α) : Thunk α
```

Stores an already-computed value in a thunk.

Because the value has already been computed, there is no laziness.

<a id="Thunk___bind"></a>

**def**

```text
Thunk.bind.{u_1, u_2} {α : Type u_1} {β : Type u_2} (x : Thunk α)
  (f : α → Thunk β) : Thunk β
```

Constructs a new thunk that applies `f` to the result of `x` when forced.

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
[0, 1, 2]xs: 0
xs: 1
xs: 2
```


### Display 2


```text
[0, 1, 2, 0, 1, 2]xs: 0
xs: 1
xs: 2
ys: 0
ys: 1
ys: 2
```


### Display 3


```text
[0, 1, 2, 0, 1, 2]xs: 0
xs: 1
xs: 2
```


### Display 4


```text
[0, 1, 2, 0]xs: 0
xs: 1
xs: 2
ys: 0
```


## Inherited reference figures

These figures describe the native reference, not a claim about an implemented PSC runtime.

![m_header Lean object header m_value Saved valuelean_object * m_closure Closurelean_object *](../../../assets/figures/figure-02.svg)

Caption labels: m_header Lean object header m_value Saved valuelean_object * m_closure Closurelean_object *
