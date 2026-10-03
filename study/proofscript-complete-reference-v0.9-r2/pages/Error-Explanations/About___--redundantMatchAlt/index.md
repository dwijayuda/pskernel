<a id="lean___redundantMatchAlt"></a>

# ProofScript — About: redundantMatchAlt

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

The inherited error catalog explains invalid constructors, dependent eliminations, missing instances, unresolved names and other rejected programs. These are examples of failure, not snippets to copy into a successful program. Preserve native error IDs while mapping source positions back to .ps. A syntax overlay error should be distinguished from native elaboration, proof search, kernel rejection and unavailable target primitives.

**Compiler and coverage boundary.** Keep malformed, unsupported, cancelled, exhausted and internal-error outcomes distinct. Never turn an unsupported example into a permissive fallback or suppress a failed proof to make documentation appear runnable.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Error-Explanations/About___--redundantMatchAlt/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Error-Explanations/About___--redundantMatchAlt/index.html). Source Git blob: `0b0c55c42339fcb8469f191830274bc250610829`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## About: redundantMatchAlt

Error code: `lean.redundantMatchAlt`

*Match alternative will never be reached.*

**Severity:**Error**Since:**4.22.0

This error occurs when an alternative in a pattern match can never be reached: any values that would match the provided patterns would also match some preceding alternative. Refer to the [Pattern Matching](../../Terms/Pattern-Matching/index.md#pattern-matching) manual section for additional details about pattern matching.

This error may appear in any pattern matching expression, including [`match`](../../Terms/Pattern-Matching/index.md#Lean___Parser___Term___match) expressions, equational function definitions, `if let` bindings, and monadic `let` bindings with fallback clauses.

In pattern-matches with multiple arms, this error may occur if a less-specific pattern precedes a more-specific one that it subsumes. Bear in mind that expressions are matched against patterns from top to bottom, so specific patterns should precede generic ones.

In [`if let`](../../Terms/Conditionals/index.md#termIfLet) bindings and monadic `let` bindings with fallback clauses, in which only one pattern is specified, this error indicates that the specified pattern will always be matched. In this case, the binding in question can be replaced with a standard pattern-matching `let`.

One common cause of this error is that a pattern that was intended to match a constructor was instead interpreted as a variable binding. This occurs, for instance, if a constructor name (e.g., `cons`) is written without its prefix (`List`) outside of that type's namespace. The constructor-name-as-variable linter, enabled by default, will display a warning on any variable patterns that resemble constructor names.

This error nearly always indicates an issue with the code where it appears. If needed, however, `set_option match.ignoreUnusedAlts true` will disable the check for this error and allow pattern matches with redundant alternatives to be compiled by discarding the unused arms.

<a id="The-Lean-Language-Reference--Error-Explanations--About___--redundantMatchAlt--Examples"></a>
### Examples

<a id="Incorrect-Ordering-of-Pattern-Matches"></a>
Incorrect Ordering of Pattern Matches   
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-0"></a>
Original
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-1"></a>
Fixed  
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-0"></a>

```proofscript
def seconds : List (List α) → List α
  | [] => []
  | _ :: xss => seconds xss
  | (_ :: x :: _) :: xss => x :: seconds xss
```

```lean
Redundant alternative: Any expression matching
  (head✝ :: x :: tail✝) :: xss
will match one of the preceding alternatives
```

<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-1"></a>

```proofscript
def seconds : List (List α) → List α
  | [] => []
  | (_ :: x :: _) :: xss => x :: seconds xss
  | _ :: xss => seconds xss
```

Since any expression matching `(_ :: x :: _) :: xss` will also match `_ :: xss`, the last alternative in the broken implementation is never reached. We resolve this by moving the more specific alternative before the more general one.

<a id="Unnecessary-Fallback-Clause"></a>
Unnecessary Fallback Clause   
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-0"></a>
Original
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-1"></a>
Fixed  
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-0"></a>

```proofscript
example (p : Nat × Nat) : IO Nat := do
  let (m, n) := p
    | return 0
  return m + n
```

```lean
Redundant alternative: Any expression matching
  x✝
will match one of the preceding alternatives
```

<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-1"></a>

```proofscript
example (p : Nat × Nat) : IO Nat := do
  let (m, n) := p
  return m + n
```

Here, the fallback clause serves as a catch-all for all values of `p` that do not match `(m, n)`. However, no such values exist, so the fallback clause is unnecessary and can be removed. A similar error arises when using `if let pat := e` when `e` will always match `pat`.

<a id="Pattern-Treated-as-Variable___-Not-Constructor"></a>
Pattern Treated as Variable, Not Constructor   
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-0"></a>
Original
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-button-1"></a>
Fixed  
<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-0"></a>

```proofscript
example (xs : List Nat) : Bool :=
  match xs with
  | nil => false
  | _ => true
```

```lean
Redundant alternative: Any expression matching
  x✝
will match one of the preceding alternatives
```

<a id="error-example-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-panel-1"></a>

```proofscript
example (xs : List Nat) : Bool :=
  match xs with
  | .nil => false
  | _ => true
```

In the original example, `nil` is treated as a variable, not as a constructor name, since this definition is not within the `List` namespace. Thus, all values of `xs` will match the first pattern, rendering the second unused. Notice that the constructor-name-as-variable linter displays a warning at `nil`, indicating its similarity to a valid constructor name. Using dot-prefix notation, as shown in the fixed example, or specifying the full constructor name `List.nil` achieves the intended behavior.

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
Redundant alternative: Any expression matching
  (head✝ :: x :: tail✝) :: xss
will match one of the preceding alternatives
```


### Display 2


```text
Redundant alternative: Any expression matching
  x✝
will match one of the preceding alternatives
```


### Display 3


```text
Local variable 'nil' resembles constructor 'List.nil' - write '.nil' (with a dot) or 'List.nil' to use the constructor.

Note: This linter can be disabled with `set_option linter.constructorNameAsVariable false`
```

