# PSC1 Practical Core: immutable tuple bindings and namespace scopes

This increment extends draft PR #166 on the preserved seven-backend base
`5539059a47c13a3dbc9806a504775b72f7bfd0fe`. It adds immutable product binding
patterns and semantic namespace scopes in both source grammars. All fourteen
Practical Core feature families remain incomplete.

## Exact qualification

Implementation head `7e1158875cdf236a677448598bd5f677c11d4daf` passed all **34/34** steps in
[focused Linux run 39467579973](https://github.com/dwijayuda/pskernel/actions/runs/39467579973).
The workflow tested GitHub merge commit `45169fa903b6bd68c3d9cc46348f8c4487d382c3`
against the preserved PR #165 base.

The [immutable qualification receipt](PSC1_PRACTICAL_CORE_PATTERNS_NAMESPACES_QUALIFICATION_2026-10-20.json)
records exact source/tool identities, observed checks and package hashes.
[Retained evidence archive](https://github.com/dwijayuda/pskernel/actions/runs/39467579973/artifacts/12285373763):
38,945,246 bytes,
SHA-256 `86415bd383aac67e11084b580d3ce0d33834def6cf1e01681d66db5cfbcc5e58`.
GitHub's artifact retention applies; the committed receipt does not extend it.

The earlier [control/data checkpoint](PSC1_PRACTICAL_CORE_CONTROL_DATA.md) and
its immutable receipt retain their original scope. This document describes the
additional tuple and namespace surface. A later source head needs its own
successful focused Linux check.

## Immutable tuple binding patterns

The parser retains a binding-pattern tree rather than translating a source
pattern into repeated source-level projections. Supported forms are named
leaves, wildcards, Unit, grouping, nested pairs and right-associated tuples.
An optional type annotation applies to the complete pattern.

```lean
def selected : Int :=
  let (left, (_, right)) : Int × (Bool × Nat) := (-7, (true, 13));
  left + Int.ofNat right
```

The ProofScript spelling uses the same binding pattern and a newline before
the body:

```text
def selected : Int :=
  let (left, (_, right)) : Int × (Bool × Nat) := (-7, (true, 13))
  Int.add(left, Int.ofNat(right))
```

A pattern RHS is elaborated in the original scope and placed in one strict
Core let with a fresh numeric internal name. Product components are introduced
through checked projections and immutable local lets. The continuation sees
the pattern's named leaves; the RHS does not. The enclosing let remains even
when every leaf is a wildcard, so an unused pattern does not suppress an
ordinary divergent computation. Each closed let is checked in its outer
context before it is returned.

Named leaves may shadow immutable outer bindings. Previously created closures
retain the values they captured. An existing mutable controller binding cannot
be shadowed by a pattern, and assignment to a pattern-bound name is rejected.
The shared controller carries immutable pattern bindings through selected
branches, finite loops and early returns. The recursion normalizer visits
the annotation and RHS in the outer context and visits the body under all
named pattern leaves.

| Form | Selected behavior |
| --- | --- |
| `let (x, y) := value` | One RHS evaluation, two checked product fields |
| `let (x, (y, z)) := value` | Recursive product-shape checks |
| `let (x, y, z) := value` | Right-associated product pattern |
| `let (_, ((), x)) := value` | Wildcards discard names; Unit and product shapes still checked |
| `let (x, y) : Nat × Bool := value` | Whole-pattern contextual annotation |
| Ordinary `let` and selected `do let` | Share the same typed lowering |
| Duplicate named leaves | Rejected, including duplicates at different nesting depths |
| `let mut (x, y)`, pattern `<-`, singleton comma or missing fields | Rejected |

This increment does not add dependent or arbitrary constructor binding patterns,
mutable destructuring, monadic destructuring, or a new public aggregate ABI.

## Semantic namespace scopes

`namespace N` and `end N` maintain a stack of source scopes. The parser
preserves the authored declaration name and its source span and attaches a
per-declaration namespace path. The elaborator applies that path at declaration
identity boundaries. References are resolved through the elaboration context.

```lean
namespace Counter
def offset : Nat := 7
namespace Inner
def offset : Nat := 11
def score (n : Nat) : Nat := n + offset + Counter.offset
end Inner
end Counter

def result : Nat := Counter.Inner.score 5
```

Nested scopes, reopened scopes, dotted namespace paths and dotted declaration
names are supported. A dotted declaration establishes its parent namespace
while its binders, type and body are elaborated. The namespace does not leak
unqualified global names after its matching end.

| Lookup or boundary | Selected behavior |
| --- | --- |
| Lexical local | Exact local lookup takes precedence |
| Global name | Current namespace, then each enclosing namespace, then root |
| Relative qualified name | Uses the same namespace search order |
| Qualified product or structure projection | Resolves its global base, then checks fields |
| Structural self reference | Uses the same identity resolution and preserves arity, decrease and escape checks |
| Contextual `pure` | A resolved local or namespace declaration wins over sugar |
| `end N` | Must match the innermost opened command name exactly |
| Duplicate fully qualified identity | Rejected by environment insertion |
| Imports | Remain module headers; do not become namespace-local commands |
| Public exports | Continue to depend on entry-module authorship, independently of namespace identity |

For example, `namespace A.B` closes with `end A.B`; nested
`namespace A` then `namespace B` closes with `end B` then `end A`.
Mismatched, unmatched and missing ends are parser errors. Unresolved references
remain elaboration errors. No `open`, section/export aliases, unnamed ends or
root-escaped namespace/declaration commands are selected. Reference-only
`_root_.Name` spelling selects an exact root global and bypasses local/current
namespace lookup; namespace and declaration root escapes remain refused.

Tuple/array and other generated builtin references retain explicit root identity,
so a declaration such as `N.Prod.mk` cannot capture notation. Authored relative
`Prod.mk` still follows namespace lookup. Root spelling is preserved by both
printers, including named forms emitted from literal notation.

Canonical source printing may reopen a complete namespace path around each
declaration. Translation is checked against canonical independent admission,
including the ordinary logical graph for namespaced partial functions.
Generated structural workers and private while helpers retain the fully
qualified source owner.

The historical SH1 source profile explicitly refuses namespace commands and
binding-pattern terms. This increment does not silently broaden that profile
or claim full self-host qualification.

## Evidence and its limits

| Evidence | Observed result |
| --- | --- |
| Native Do suite | 101 categorical outcomes |
| Native Data suite | 135 categorical outcomes, including 30 private JS comparisons and 16 canonical round trips |
| Native While suite | 27 categorical outcomes |
| Native Namespace suite | 60 categorical outcomes, including 20 private JS comparisons |
| Native total | 323 outcomes across the four suites |
| Authentic pinned-Lean oracle | 84 fields: 82 results and two toolchain identities |
| Regular runtime corpus | 14 target/source bundles; 18 individual predicates plus combined `semantic` |
| Ordinary while | 14 finite bundles, 14 external divergence deadlines and 16 refusals; 100,000-iteration cases retained |
| All-wildcard pattern strictness | 14 additional external two-second deadlines, each with a terminating preflight |
| Namespace host boundaries | Two grammar groups, 12 refusals and ten prior-artifact preservation checks |
| Focused backend matrix | 28 groups, including the new namespace groups |
| Minimum Python 3.14.8 | Both grammars repeat regular and finite-loop execution, two ordinary divergence deadlines, two pattern strictness deadlines and 16 while refusals; 14 scripting records retained |
| Current scripting targets | Python 3.15.0 and PHP 8.5.11; 24 artifact bundles plus four boundary records |
| Installed npm/source libraries | Offline local/global installation; two real source libraries, four captured source files, independent admission and `answer = 42` |
| Preserved checks | 36 Practical Core form artifacts, five architecture groups, two Rust private-closure records and separate native kernel tests |

The Data suite has 89 explicit Data pass lines and 30 private execution lines;
16 standalone round trips are silent and must finish before its final success
marker. NamespaceTests has 38 explicit namespace pass lines and 20 private
execution lines; its two standalone round trips are also silent. The receipt
retains these reconciliation details rather than treating printed lines as
a universal test count.

The new native-Lean observations are:

| Reference program | False input | True input |
| --- | ---: | ---: |
| Nested annotated tuple binding | -22 | 6 |
| Do pattern with capture, shadowing and early return | 33 | 29 |
| Local/current/enclosing namespace lookup | 217 | 123 |

Component Wasm executes the combined Bool predicate. The other six targets
execute all 19 exported predicates. Namespace import fixtures are handwritten
in both source grammars with different dependency stems, so each grammar's
parser is exercised without import ambiguity.

The tuple and namespace runtime checks compare actual target execution with
results produced by authentic native Lean under the exact repository pin.
Each target's established public Bool predicates exercise internal products,
captures, control and imported namespace helpers. Component execution retains
the selected combined Bool export. A successful internal tuple check is not
evidence for a public compound ABI.

The strictness regression has a terminating early-return preflight and a path
whose all-wildcard tuple RHS calls an ordinary divergent function. The latter
must reach an external two-second deadline on every selected target. It must
not return, fail through a stack/fuel limit, or discard the call. No execution
fuel is inserted into generated programs.

The host namespace groups check both imported helper privacy and an authored
namespace-owned entry export, including declaration source origin. Five
frontend failures per grammar must preserve the prior output generation and
all companion hashes. A separate imported-helper component export request
must fail before publication and leave no Wasm/WIT/WAT/manifest companions.

Native outcomes include admissions, graph assertions, private execution,
translation round trips and expected refusals. They are not behavioral proofs.
The target matrices qualify the demonstrated cases, not every interaction of
the fourteen source feature families.

## Assurance and remaining work

Official Lean **4.35.0**, commit
`eb6cafb7290e8bd5f2937522d8d804f58f02bafc`, remains the independent admission
authority. The owned kernel is separately natively tested. This increment adds
no axiom, unchecked opcode, admission bypass or backend certificate.

Explicit ordinary partial execution continues to use a constructive opaque
witness and exact separately checked body, with immutable pairing verified
before erasure. Default checked and explicit verified requests retain their
existing refusal boundaries. Selected namespaced partial self and generated
while helpers use this unchanged mechanism.

The remaining broader work includes throw/try/catch and its controller/state
semantics, Prop-valued ordering with checked decision evidence, and typed IO.
Typed IO requires console line input/output plus bounded UTF-8 file read/write,
with explicit path roots, EOF/newline, size/error semantics and target adapters.
Stdout alone does not meet that contract.

Mutable and monadic binding patterns, broader namespace commands, general
dependent captures and the existing unsupported loop/effect shapes remain
outside the selected surface. Finite continuation construction and optional
array lookup retain their previously documented linear costs. Full self-host,
fixed-point, joint compiler/kernel qualification, merge, release and npm
registry publication remain outside this continuation.
