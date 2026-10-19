# Primitive identity at the strict source boundary

## Scope and status

This is a source-level audit of the erasure path at immutable source `cf35b6b2a3328a065721ef48cf633a44e6122362`. It records a concrete admission defect and the bounded correction prepared for the strict enforcement candidate. The audit did not execute the compiler, run tests, obtain provider acceptance, or prove general semantic preservation. Qualification belongs to the actual correction revision and its retained receipts.

The correction reserves **43 operation/adapter source symbols**, of which **38 are already present and duplicate protected** in the source prelude and **five are absent**. It separately reserves the fixed type identity **`String.Pos.Raw`**. It does not install the absent symbols, add a runtime operation, expand the grammar, or activate strict SH/1, full Standard, or PSCV conformance.

## The defect and the ownership rule

[`psErasePrimitiveApplication`](https://github.com/dwijayuda/pskernel/blob/cf35b6b2a3328a065721ef48cf633a44e6122362/psc0/packages/erasure/src/Ps/Erasure/Expr.lean#L335-L632) classifies a constant application by exact Core name spelling and argument count before ordinary declaration dispatch. Its body and declaration origin do not participate in that decision. The ordinary source environment initially installs neither `Bool.and/or/not` nor `Array.getInternal/set`. The Lean frontend accepts those qualified declaration names, so an authored definition can acquire an unrelated built-in interpretation during erasure.

For example, before the correction this raw Lean source follows the ordinary definition path:

```lean
def Bool.and (left : Bool) (right : Bool) : Bool := true
def answer : Bool := Bool.and false false
```

The authored body gives `answer` the value `true`; name-based lowering produces `boolAnd(false, false)`. This is a static source-path counterexample, not a claimed execution or kernel/provider result. The Array aliases expose the same class: the mapping drops a position as a proof without authenticating that the authored declaration assigned that position a proof type.

The source-owned entry point must reject authored declarations of the reserved names **before source preparation and erasure**. `psSh1SourceDeclarationName` exhaustively extracts the first name field of all five actual AST declaration constructors: definition, partial definition, theorem, inductive, and structure. Comparison is exact Core-style dotted text, without target-name sanitization or prefix matching. A matching operation name yields `source-intrinsic-name-reserved`; the separate Raw type name yields `source-builtin-type-name-reserved`. The finding carries the source name span and full owner name.

Canonical prelude declarations remain the authority for the installed names. Calls still require their actual elaborated types, supported saturation, erasure, original-IR typing, and target admission. The five absent names remain unavailable as canonical source declarations. A direct Core/IR caller that bypasses the source-owned entry point does not acquire this source-origin guarantee.

## Exact operation/adapter inventory

The order and spellings below equal the complete `psStringEq text` inventory in `psErasePrimitiveApplication`. Arity counts Core arguments, including erased type/proof positions; `T` and `V` give zero-based type and runtime-value positions. Prod drops its two type arguments and uses its third argument as the projection owner. The line column refers to the pinned Expr file above.

| Source symbol | Core arity and lowering | Initial source environment | Line |
|---|---|---|---:|
| `Prod.fst` | 3 → projection field 0 | Installed; duplicate protected | 367 |
| `Prod.snd` | 3 → projection field 1 | Installed; duplicate protected | 368 |
| `Int.ofNat` | 1 → intOfNat | Installed; duplicate protected | 369 |
| `Int.repr` | 1 → intRepr | Installed; duplicate protected | 380 |
| `Int.negSucc` | 1 → intNegSucc | Installed; duplicate protected | 386 |
| `Int.neg` | 1 → intNeg | Installed; duplicate protected | 397 |
| `Int.add` | 2 → intAdd | Installed; duplicate protected | 408 |
| `Int.sub` | 2 → intSub | Installed; duplicate protected | 410 |
| `Int.mul` | 2 → intMul | Installed; duplicate protected | 412 |
| `Nat.succ` | 1 → natAdd(value, 1) | Installed; duplicate protected | 414 |
| `Nat.add` | 2 → natAdd | Installed; duplicate protected | 427 |
| `Nat.sub` | 2 → natSub | Installed; duplicate protected | 429 |
| `Nat.mul` | 2 → natMul | Installed; duplicate protected | 431 |
| `Nat.div` | 2 → natDiv | Installed; duplicate protected | 433 |
| `Nat.mod` | 2 → natMod | Installed; duplicate protected | 435 |
| `Nat.beq` | 2 → natEq | Installed; duplicate protected | 437 |
| `Nat.ble` | 2 → natLe | Installed; duplicate protected | 439 |
| `Nat.blt` | 2 → natLt | Installed; duplicate protected | 441 |
| `Bool.and` | 2 → boolAnd | Absent; explicit reservation required | 443 |
| `Bool.or` | 2 → boolOr | Absent; explicit reservation required | 445 |
| `Bool.not` | 1 → boolNot | Absent; explicit reservation required | 447 |
| `Char.ofNat` | 1 → charOfNat | Installed; duplicate protected | 458 |
| `Char.toNat` | 1 → charToNat | Installed; duplicate protected | 469 |
| `String.Pos.Raw.mk` | 1 → unchanged erased argument | Installed; duplicate protected | 480 |
| `String.Pos.Raw.byteIdx` | 1 → unchanged erased argument | Installed; duplicate protected | 492 |
| `String.push` | 2 → stringPush | Installed; duplicate protected | 504 |
| `String.singleton` | 1 → stringSingleton | Installed; duplicate protected | 506 |
| `String.Internal.length` | 1 → stringLength | Installed; duplicate protected | 517 |
| `String.Internal.append` | 2 → stringAppend | Installed; duplicate protected | 528 |
| `String.utf8ByteSize` | 1 → stringUtf8ByteSize | Installed; duplicate protected | 530 |
| `String.Internal.next` | 2 → stringNext | Installed; duplicate protected | 541 |
| `String.Internal.get` | 2 → stringGet | Installed; duplicate protected | 543 |
| `String.Internal.atEnd` | 2 → stringAtEnd | Installed; duplicate protected | 545 |
| `String.Internal.extract` | 3 → stringExtract | Installed; duplicate protected | 547 |
| `Array.emptyWithCapacity` | 2; T[0], V[1] → arrayEmptyWithCapacity | Installed; duplicate protected | 558 |
| `Array.size` | 2; T[0], V[1] → arraySize | Installed; duplicate protected | 566 |
| `Array.push` | 3; T[0], V[1,2] → arrayPush | Installed; duplicate protected | 574 |
| `Array.getInternal` | 4; T[0], V[1,2]; drops [3] → arrayGet | Absent; explicit reservation required | 582 |
| `Array.getD` | 4; T[0], V[1,2,3] → arrayGetD | Installed; duplicate protected | 590 |
| `Array.set` | 5; T[0], V[1,2,3]; drops [4] → arraySet | Absent; explicit reservation required | 598 |
| `Array.setIfInBounds` | 4; T[0], V[1,2,3] → arraySetIfInBounds | Installed; duplicate protected | 606 |
| `Array.map` | 4; T[0,1], V[2,3] → arrayMap | Installed; duplicate protected | 614 |
| `Array.foldl` | 7; T[0,1], V[2,3,4,5,6] → arrayFoldl | Installed; duplicate protected | 622 |

These are 43 **source spellings**, not 43 distinct runtime laws or the 45-operation runtime contract. Prod projections and the Raw adapters are included because they also replace source meaning by name. `Nat.succ` and `Nat.add` share an IR operation. The runtime contract remains the separate finite operation/domain inventory.

## Prelude and generated-name protection

The actual source environment is `psSelfHostProdPreludeEnvironment`, constructed from `psSelfHostPreludeEnvironment` and `psBootstrapPreludeEnvironment`. The initial declarations in Prelude, SelfHostPrelude, and SelfHostProd establish the 38 installed entries above. Ordinary addition rejects duplicate Core names. The special source addition route can replace an **axiom** only for exact `Prod`, `List`, and `Option`; in this initial source environment those names have already been replaced by their owned inductive declarations. It does not grant arbitrary primitive overrides. See [source preparation](https://github.com/dwijayuda/pskernel/blob/cf35b6b2a3328a065721ef48cf633a44e6122362/psc0/packages/compiler/src/Ps/Compiler/Api.lean#L69-L123) and [declaration addition](https://github.com/dwijayuda/pskernel/blob/cf35b6b2a3328a065721ef48cf633a44e6122362/psc0/packages/elab/src/Ps/Elab/Declaration.lean#L641-L672).

Generated constructors do not reopen the five missing operation names. [`psSyntaxConstructorCoreName`](https://github.com/dwijayuda/pskernel/blob/cf35b6b2a3328a065721ef48cf633a44e6122362/psc0/packages/elab/src/Ps/Elab/Declaration.lean#L218-L229) accepts one child segment and appends it to the declared inductive name; qualified constructor headers are refused. Synthesizing a `Bool.*` or `Array.*` constructor would require redefining its already protected parent type. Every existing generated constructor/recursor addition also goes through duplicate-name checks.

## Separate fixed type identity: String.Pos.Raw

[`psErasurePrimitiveType`](https://github.com/dwijayuda/pskernel/blob/cf35b6b2a3328a065721ef48cf633a44e6122362/psc0/packages/erasure/src/Ps/Erasure/Basic.lean#L419-L498) has 19 fixed type-name cases. Nat, Int, Bool, Char, String, Unit and the 12 optional scalar names are already installed and duplicate protected. The optional types remain outside the enabled runtime profile. The only absent type identity is `String.Pos.Raw`, which this function maps to primitive Nat.

The prelude installs `String.Pos.Raw.mk` and `String.Pos.Raw.byteIdx` as **Nat → Nat** adapters ([Prelude](https://github.com/dwijayuda/pskernel/blob/cf35b6b2a3328a065721ef48cf633a44e6122362/psc0/packages/environment/src/Ps/Environment/Prelude.lean#L813-L821)); it does not install a Raw type declaration. Runtime type erasure first weak-head normalizes its input, so transparent aliases reduce before classification. An unrelated authored inductive does not reduce that way:

```lean
inductive String.Pos.Raw where
  | marker
def rawIdentity (value : String.Pos.Raw) : String.Pos.Raw := value
```

Without the source reservation, the inductive layout is named `String_Pos_Raw`, but `rawIdentity` receives the unrelated Nat → Nat runtime signature. An unused layout plus that identity body has no cross-kind equality for the IR checker to reject. This is a source/ABI classification inconsistency.

A concrete definition returning `String.Pos.Raw.marker` at result type `String.Pos.Raw` is different: the constructor is inferred as a named layout, while the result annotation erases to primitive Nat. The current checker rejects that mismatch ([constructor typing](https://github.com/dwijayuda/pskernel/blob/cf35b6b2a3328a065721ef48cf633a44e6122362/psc0/packages/compiler-ir/src/Ps/CompilerIr/Check.lean#L439-L468), [type equality](https://github.com/dwijayuda/pskernel/blob/cf35b6b2a3328a065721ef48cf633a44e6122362/psc0/packages/compiler-ir/src/Ps/CompilerIr/CheckTypes.lean#L186-L222)). Do not describe this already-refused constructor use as an observed runtime miscompile. A structure named Raw would also collide with the existing Raw.mk; the non-mk inductive above avoids that duplicate. A constructor called Raw under an unrelated `String.Pos` inductive cannot serve as a type, because its Core result is an inductive value rather than a sort.

## Other fixed substitutions in the complete erased path

The audit covered Basic, Expr, Definition, Inductive, Structure, and StructureRecursor, the complete erasure import closure used here.

| Class | Identity evidence and disposition |
|---|---|
| Nat zero/successor/recursor | Nat, Nat.zero, Nat.succ and Nat.rec are installed. The special Nat recursor scope entry uses those protected identities; zero/succ branch labels are checked against that entry. |
| Bool and Unit literal constants | Bool.true, Bool.false and Unit.unit are installed and protected. Their literal substitutions do not match an unowned authored declaration. |
| Conditional and equality lowering | Eq, Bool, Bool.true, String and ite are installed; the source Bool decision helper is also predeclared. The Bool/String condition cases add no absent identity. |
| Array runtime type | Array is an installed type constructor. The missing getInternal/set adapters are already in the 43-entry inventory. |
| General inductive/structure constructors and projections | Runtime layouts and constructor fields come from actual prepared declaration metadata; they are not selected by an unowned fixed built-in spelling. |
| General recursors, including structure `.rec` lowering | The suffix is only an initial filter. Structure lowering also requires an actual matching inductive marked as a structure, recursor metadata, constructor metadata, parameter/minor counts and supported arity. General runtime recursors likewise use prepared metadata. |
| Remaining fixed primitive type names | All 18 other cases are installed. Raw is the separate reservation above. No further absent name-only exception was found in this bounded path. |

This result is scoped to the actual source-owned erasure path; it is not a statement that arbitrary caller-supplied Core environments have authenticated built-in declarations.

## Finite refusal witnesses and frontend distinction

The five Lean definitions below are independent reservation witnesses. Their bodies deliberately differ from the source spelling's intrinsic interpretation:

```lean
def Bool.and (left : Bool) (right : Bool) : Bool := true
def Bool.or (left : Bool) (right : Bool) : Bool := false
def Bool.not (value : Bool) : Bool := value
def Array.getInternal {alpha : Type} (values : Array alpha) (index : Nat) (fallback : alpha) : alpha := fallback
def Array.set {alpha : Type} (values : Array alpha) (index : Nat) (value : alpha) (ignored : Nat) : Array alpha := values
```

The first three contradict and/or/not value laws. The fourth can replace a total fallback function by bounds-sensitive get after dropping the fallback argument. The fifth can replace an unchanged-array function by an update after dropping an ordinary Nat argument. Correct IR result types alone do not authenticate those meanings.

The corresponding raw PS inputs are deliberately **grammar refusal** witnesses:

```text
def Bool.and(left : Bool, right : Bool) : Bool := true
def Bool.or(left : Bool, right : Bool) : Bool := false
def Bool.not(value : Bool) : Bool := value
def Array.getInternal {alpha : Type}(values : Array alpha, index : Nat, fallback : alpha) : alpha := fallback
def Array.set {alpha : Type}(values : Array alpha, index : Nat, value : alpha, ignored : Nat) : Array alpha := values
```

The current new-only PS parser accepts a single identifier for a declaration header, unlike its qualified reference grammar ([declared-name parser](https://github.com/dwijayuda/pskernel/blob/cf35b6b2a3328a065721ef48cf633a44e6122362/psc0/packages/syntax/src/Ps/Syntax/ParseProofScript.lean#L1417-L1425)). These dotted declarations are rejected as `source-compiler` before the name policy; their receipt boundary is `new-only-ps-declared-name-grammar`. They are not evidence that PS currently admits qualified declarations. Only the Lean cases assert the exact policy owner/name span. The Raw inductive adds the same pair: Lean policy refusal and PS dotted-name grammar refusal.

The corrected source gate therefore has **33 negative cases: 21 prior cases, six Lean name-policy cases, and six PS grammar cases**. The accepted PS structure fixture uses its required braced body. These are candidate expectations until actual execution receipts are retained.

## Correction identities and limits

The reviewed, unattached correction blobs are:

| File | Git blob |
|---|---|
| `packages/compiler/src/Ps/Compiler/Sh1.lean` | `9aaa3a72bbfe03ed3fc4918527e2ca200537d61f` |
| `scripts/sh1-strict-source-conformance.mjs` | `7e70f4ec75a156c87dc5f1023c451f77b132bc39` |
| `scripts/sh1-strict-evidence.mjs` | `de83f067f202ef4679dfcc08132616c9d00d501a` |

The operation predicate was compared with all 43 pinned dispatch spellings; the type rule is separate; the source declaration accessor matches all actual AST variants. The gate distinguishes parser and policy boundaries, and the evidence binder expects the same 33 refusals. No compiler/runtime execution was performed as part of this review.

This correction does not change Bool short-circuit emission, Nat recursion lowering, primitive value laws, array bounds implementation, native/provider/kernel code, or the selected seed. It prevents unrelated authored declarations from acquiring fixed runtime meanings. General erasure/emitter preservation, proof-origin preservation, totality and resource equivalence remain separate obligations; `strictSh1Qualified` remains false.

## Pinned source blobs

All source links above point to the same immutable audit revision. The following exact blob inventory permits a later reviewer to separate the audited baseline from its correction:

| Path under psc0 | Git blob |
|---|---|
| [packages/erasure/src/Ps/Erasure/Basic.lean](https://github.com/dwijayuda/pskernel/blob/cf35b6b2a3328a065721ef48cf633a44e6122362/psc0/packages/erasure/src/Ps/Erasure/Basic.lean) | `e0c932e0280b9c0e2b7f7ad1974b548881f452d0` |
| [packages/erasure/src/Ps/Erasure/Expr.lean](https://github.com/dwijayuda/pskernel/blob/cf35b6b2a3328a065721ef48cf633a44e6122362/psc0/packages/erasure/src/Ps/Erasure/Expr.lean) | `28e14f991df68c4a7d49f09120a42c85c919d6a8` |
| [packages/erasure/src/Ps/Erasure/Definition.lean](https://github.com/dwijayuda/pskernel/blob/cf35b6b2a3328a065721ef48cf633a44e6122362/psc0/packages/erasure/src/Ps/Erasure/Definition.lean) | `709fc44f59bddb3c3d7354ba31ea01f296c9cde8` |
| [packages/erasure/src/Ps/Erasure/Inductive.lean](https://github.com/dwijayuda/pskernel/blob/cf35b6b2a3328a065721ef48cf633a44e6122362/psc0/packages/erasure/src/Ps/Erasure/Inductive.lean) | `857b9926a14be9e30ad2ed2ccdcd26643624d9ed` |
| [packages/erasure/src/Ps/Erasure/Structure.lean](https://github.com/dwijayuda/pskernel/blob/cf35b6b2a3328a065721ef48cf633a44e6122362/psc0/packages/erasure/src/Ps/Erasure/Structure.lean) | `7b16c9910aba8a0ce3213fd02a34a43fa64b4d75` |
| [packages/erasure/src/Ps/Erasure/StructureRecursor.lean](https://github.com/dwijayuda/pskernel/blob/cf35b6b2a3328a065721ef48cf633a44e6122362/psc0/packages/erasure/src/Ps/Erasure/StructureRecursor.lean) | `66b20621288b76153fa78db6c923f0c7b0c5d9ab` |
| [packages/environment/src/Ps/Environment/Prelude.lean](https://github.com/dwijayuda/pskernel/blob/cf35b6b2a3328a065721ef48cf633a44e6122362/psc0/packages/environment/src/Ps/Environment/Prelude.lean) | `d862ba8c806595fbf11237724089bd2282af9866` |
| [packages/environment/src/Ps/Environment/SelfHostPrelude.lean](https://github.com/dwijayuda/pskernel/blob/cf35b6b2a3328a065721ef48cf633a44e6122362/psc0/packages/environment/src/Ps/Environment/SelfHostPrelude.lean) | `b9127717d5685ae0de6e10251ba1d8d02b6e647d` |
| [packages/environment/src/Ps/Environment/SelfHostProd.lean](https://github.com/dwijayuda/pskernel/blob/cf35b6b2a3328a065721ef48cf633a44e6122362/psc0/packages/environment/src/Ps/Environment/SelfHostProd.lean) | `38485851a30f024d973392c6c8e1d86916e31466` |
| [packages/compiler/src/Ps/Compiler/Api.lean](https://github.com/dwijayuda/pskernel/blob/cf35b6b2a3328a065721ef48cf633a44e6122362/psc0/packages/compiler/src/Ps/Compiler/Api.lean) | `13614bc6eb279c93d4cbcbd8815b671beae38199` |
| [packages/elab/src/Ps/Elab/Declaration.lean](https://github.com/dwijayuda/pskernel/blob/cf35b6b2a3328a065721ef48cf633a44e6122362/psc0/packages/elab/src/Ps/Elab/Declaration.lean) | `8a8005a2ae0aa6564e075e3b224b432295c6bf05` |
| [packages/syntax/src/Ps/Syntax/Ast.lean](https://github.com/dwijayuda/pskernel/blob/cf35b6b2a3328a065721ef48cf633a44e6122362/psc0/packages/syntax/src/Ps/Syntax/Ast.lean) | `4a9daaf4179ca7fa74e9183e542891ec110fd5d7` |
| [packages/syntax/src/Ps/Syntax/ParseLean.lean](https://github.com/dwijayuda/pskernel/blob/cf35b6b2a3328a065721ef48cf633a44e6122362/psc0/packages/syntax/src/Ps/Syntax/ParseLean.lean) | `969eb9ec1b18e9ab42a1bfdf4d385e39a7fc56a3` |
| [packages/syntax/src/Ps/Syntax/ParseProofScript.lean](https://github.com/dwijayuda/pskernel/blob/cf35b6b2a3328a065721ef48cf633a44e6122362/psc0/packages/syntax/src/Ps/Syntax/ParseProofScript.lean) | `e91415c66fec9115a281c93c9459189bb919f121` |
| [packages/compiler-ir/src/Ps/CompilerIr/Check.lean](https://github.com/dwijayuda/pskernel/blob/cf35b6b2a3328a065721ef48cf633a44e6122362/psc0/packages/compiler-ir/src/Ps/CompilerIr/Check.lean) | `94b80cd7fe617e62c9a95446ff019e088d57b0b3` |
| [packages/compiler-ir/src/Ps/CompilerIr/CheckTypes.lean](https://github.com/dwijayuda/pskernel/blob/cf35b6b2a3328a065721ef48cf633a44e6122362/psc0/packages/compiler-ir/src/Ps/CompilerIr/CheckTypes.lean) | `71a4231fe23c7049c0930976c383fbc60cc5c24f` |
