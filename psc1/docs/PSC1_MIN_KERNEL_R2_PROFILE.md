# PSC1 MinKernel R2: closed regular-data profile

Status: standalone qualified at `028dcd98fabcb0bf196c0d6f27a80bad3b666745`,
[Linux run 40469648092](https://github.com/dwijayuda/pskernel/actions/runs/40469648092).
Both proof/native 122073398746 and portability/census 122073398515 are success.
This document defines the isolated normalized calculus. The dated qualification
receipt retains all exact source, proof, run and artifact identities.

## Domain and executable contract

The R2 runtime consists of RegularProfile.lean and RegularCheck.lean. The separate
RegularNames.lean imports the existing Foundation.Name source for internal
quotation identities. No runtime module imports a proof or calls an official
checker. The original Check.lean and canonical host refusal remain intact.

Closed type codes are Empty, Unit, Nat, Bool, arrows, finite List/Option type
expressions, and relative datatype slots. All inhabit the fixed Type-0 model;
there are no object universes, free type variables, dependent Pi types or indices.
List/Option are interpreted by the pinned host types. This batch adds their type
codes, not arbitrary polymorphic source constants or new List/Option term rules.
Fuel bounds traversal depth; it is not an aggregate input-size or host-stack bound.

The newest-first registry contains first-order, nonmutual regular datatypes.
Each descriptor has zero level parameters, zero parameters, zero indices, one
motive and a minor count equal to its actual constructor list. A constructor field
is either a ground closed type using only older groups or one direct positive
self field. A function ground field may mention older groups; current self inside
a ground/function/List/Option expression refuses. Nested self, indexed families
and mutual recursion are outside this grammar.

Constructor signatures are derived from the descriptor. Ground datatype slots
shift under the new family. A recursor takes all constructor minors, then the
major; each minor takes the original fields in their original order, followed
by induction hypotheses for direct self fields, then returns the fixed result.
The request must have level instance 1, zero parameters/indices, one motive and
the exact derived minor count. These numbers are checked data, not authority
from a declaration name or compiler-origin metadata.

A recursor result code is relative to its selected family and older registry.
Looking up an older family shifts its complete signature into the ambient
registry. It cannot eliminate into an arbitrary newer family in this profile.
This deliberate restriction is represented in both executable and model.

psMinRegInfer checks actual term syntax: variables, earlier constants, Unit/Nat/
Bool literals, typed lambda/application, constructor requests and recursor
requests. psMinRegCheckEnvironment validates the entire registry and sequential
declarations from an empty constant environment. Forward constants, malformed
signatures, annotation mismatch and exhausted fuel refuse.

## Concrete mathematical model

RegularModel builds each datatype as a finite-branching inductive tree whose tag
selects a constructor and carries its ground fields. Direct recursive fields are
the children. splitArgs/joinArgs retain the exact field order. Constructor and
recursor semantic values have the executable's derived types. fold_construct is
the generic iota law for every descriptor family, not a fixture equation.

The registry model is constructed from the empty registry. SignatureModel is
discharged by that construction. inferModel consumes actual psMinRegInfer success;
declarationsModel follows the real sequential fold. regular_hasModel and
regular_consistent therefore do not assume an arbitrary foundation model. The
Empty code denotes host Empty. This is consistency of this normalized source
calculus, not consistency of unrestricted canonical Lean declarations or False.

## Source identities and representative Core bridge

Internal quotation names use chronological declaration ordinals, constructor
ordinals and a recursor component. Relative slots are rebased when extending the
registry; absolute names stay stable. The naming proofs cover injectivity,
datatype/constructor/recursor separation and disjointness from the stated
string-rooted primitive forms. These generated identities do not resolve
arbitrary external source names.

RegularSourceInstance models the actual PsMinTy.rec application retained in the
current normalized psMinTyEq worker. It fixes the exact structured names, universe
instance, constant Bool motive, four minors, field/IH order and major. The actual
R1 binder-lowering equation justifies motive instantiation. A typed CoreEval
relation for this fixed source image uses the actual imported PsMinTy constructors
and recursor, with a concrete denotation for its local major. The checked
normalized term and actual Core image evaluate to the same Bool; the used iota
equation is checked separately.

The witness executable emits the exact source expression as structured wire
syntax. Linux CI compares it structurally with a unique occurrence in the current
source-origin-bound psMinTyEq worker, including binder names and universe data.
That occurrence check is diagnostic qualification, never runtime admission by
source hash, name or frozen receipt.

A general canonical name-to-slot resolver, descriptor decoder and translation
preservation theorem remain R4 work. This representative source-image bridge
must not be promoted to a proof for every raw Core input or the full prelude.
The source model's fixed PsMinTy/Bool environment is explicit; it does not assume
the 115-entry canonical prelude is already modeled.

## Qualification and remaining boundary

The corpus has 23 positive cases, 38 refusals and two out-of-range probes.
It includes empty/no-base datatypes, multiple recursive fields, prior-family
function fields, older-slot/result rebasing, sequential declarations, all
descriptor metadata refusals, altered field/IH order, wrong minors/major,
forward references, fuel exhaustion and stable internal naming.

Native Lean and actual PSC1-generated JavaScript execute the same cases in Linux
Actions. The official independent native checker admits the complete five-module
source/test bundle. This demonstrates source admission and finite execution
agreement; generated-code preservation remains unproved. The emitted TS/JS
payload includes the harness and shared runtime and is not an isolated checker
payload or a performance result.

All new public acceptance/model/source bridge axiom reports must be present and
contain only no axioms or propext. Failed development runs never qualify a repair.
No local project build, proof check, compiler execution or test is part of this
batch.

Canonical min/dual still return PSC1_MIN_CANONICAL_BRIDGE_UNPROVED. Full compiler
min coverage remains 0/124 modules, 0/37 Practical Core and no qualified min G1/G2/G3.
R3 still needs selected foundation semantics, lets/projections and sound conversion
with definition-body invariants. R4 still needs general ingress, exact source-name
binding, translation and generated execution/resource boundaries before self-check.

## Exact standalone receipt

The checker has two explicit modules, 307 physical source lines and 12268 UTF-8 B.
Adding the quotation helper and Foundation.Name yields four modules/17081 B.
The five-module source/test graph has 32857 B; its generated 105087 B TS and
221393 B JS have JS SHA256
`59b9da87d0f27cfeba707ee9e07718bc74128a4259f901f2346783af215fe0ab`.

Proof artifact 12717967510 is 2531 B, ZIP digest
`8c091fd01587c4049f9b0a7acaf9d9f94a8731495736168209e5269bc1bbc9ce`.
Portability/closure artifact 12717887625 is 1590913 B, ZIP digest
`a8d4ef18d424aa0a595f80b1a901ebcc6f8e3b5e1dcac911b0e7f2de8b50fb85`.
These are GitHub-reported archive identities. The source witness has SHA256
`3225309cfea2f9efb4416ddd1cb1de2e5972f6e22f402047ab65c1999385f949`;
its actual occurrence is admission record 3, path `v.b.f.a.b.b.b.b.f.f.a`.

The complete fresh compiler census still has 124 modules/4747 logical members,
3465 admissions,115 prelude declarations and 60 foundation axioms. R2 does not
admit that compiler under min. Historical diagnostic counts and the current
unqualified frontier are preserved in the dated receipt.
