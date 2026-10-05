# AI Prompt — Deep Research and Iterative Design of the ProofScript Verified Ecosystem Factory

You are acting simultaneously as:

- a principal programming-language researcher;
- a formal-methods and theorem-proving architect;
- a compiler/runtime engineer;
- an AI-agent systems architect;
- a software-ecosystem and developer-product strategist;
- a security/trust/supply-chain auditor;
- an open-source migration and package-ecosystem architect.

Your job is **not** to defend the current ProofScript plan. Your job is to discover the strongest technically achievable architecture for turning ProofScript into a language/platform that can grow a trustworthy ecosystem rapidly with AI while keeping correctness claims precise, independently checkable, and auditable.

## Repository target

Repository:

`dwijayuda/pskernel`

Primary research branch:

`research/proofscript-v0.9-r3`

Primary document:

`study/proofscript-v0.9-r3-research/ProofScript_Programming_Language_IDENTITY_AND_PLANS.md`

Also inspect current implementation/architecture evidence from relevant branches, especially:

- `main`
- `psc2/selfhost-lean-kernel`
- other current ProofScript/compiler/kernel research branches when relevant.

Do not assume an old document describes the latest implementation. Inspect live branch heads and preserve unrelated work.

## Starting thesis

ProofScript is exploring a Lean-grounded programming and verification language where:

```text
ordinary code
→ strongly typed
→ specified
→ verified
→ checked deployable artifact
```

AI should be highly productive but should **not** become part of the trusted correctness boundary.

Current candidate ideas include, but are not limited to:

- Verified Software Factory / ProofScript Forge;
- ProofScript Bridge;
- ProofScript App;
- evidence graphs;
- gradual verification;
- CheckedCore / VerifiedIR;
- PSKernel;
- Lean-backed proof services;
- InterfaceIR;
- AI-generated implementations, specifications, tests, migrations, and proofs;
- rapid construction of a native ProofScript ecosystem.

These are hypotheses. You are free to replace them.

## Critical freedom

You are explicitly allowed to design systems that are **not present in the current document**.

Research broadly.

Consider:

- verified-by-construction generation;
- specification-first synthesis;
- proof-producing compilation;
- translation validation;
- certificate checking;
- proof-carrying artifacts;
- clean-room reimplementation;
- source-to-source migration;
- API/model extraction;
- differential testing;
- property testing and fuzzing;
- semantic package manifests;
- evidence graphs;
- theorem/package reuse graphs;
- package-level assurance vectors;
- multi-agent workflows;
- LLM proof repair;
- constrained DSL generation;
- foreign verification;
- interface-description languages;
- WebAssembly Component Model/WIT;
- SLSA/in-toto provenance;
- SBOMs;
- reproducible builds;
- trusted-spec governance;
- adversarial review;
- automated upstream synchronization;
- ecosystem bootstrap economics.

Do not be constrained by the current Forge/App/Bridge terminology.

## Research questions

### 1. Does ProofScript actually need a Verified Software Factory?

Determine whether the product should instead be:

- a verified package generator;
- a migration/interop system;
- a verification IDE;
- a verified ecosystem accelerator;
- a proof-carrying package system;
- a specification marketplace;
- a framework;
- a family of domain-specific factories;
- some combination;
- or something else entirely.

### 2. Can the ecosystem be grown dramatically using AI?

Investigate whether AI can make creation of:

- stdlib modules;
- data structures;
- parsers;
- codecs;
- HTTP libraries;
- SDKs;
- schema validators;
- state machines;
- crypto wrappers;
- database adapters;
- effect abstractions;
- framework libraries;
- theorem libraries;
- proof automation;
- extensions/plugins

materially cheaper while preserving auditable assurance.

Do **not** equate generated LOC with ecosystem progress.

Measure instead:

```text
human minutes per trusted capability
human minutes per reviewed specification
assurance claims per human engineering hour
proof reuse
package reuse
maintenance/refactor cost
marginal effort for package N versus package 1
```

### 3. Study rewriting/porting open-source libraries

Explicitly evaluate multiple strategies:

#### Bind

Use the foreign package as-is behind an explicit interface/assumption boundary.

#### Characterize

Add typed interfaces, conformance tests, property tests, fuzzing, and differential testing while leaving the implementation foreign.

#### Port

AI ports/restructures a suitably licensed open-source library to ProofScript while preserving provenance/license obligations and using the original implementation as a behavioral oracle where legally/technically appropriate.

#### Verified replacement

Develop a native ProofScript implementation against an approved semantic specification and prove selected properties.

#### Generate by construction

For package families with declarative inputs, generate implementations from verified combinators instead of porting one library at a time.

Examples:

- codecs from schemas;
- SDKs from OpenAPI;
- state machines from transition specs;
- validators from data models;
- serializers from type descriptions.

Do not assume an AI rewrite automatically avoids copyright/license obligations. Record source provenance and license strategy. Distinguish source-derived ports from independent/specification-driven reimplementations and recommend legal review where needed.

### 4. Design a specification system

Research whether ProofScript needs a first-class system such as a provisional `PSpec`, `SpecCapsule`, or equivalent.

Possible contents:

- public API/interface;
- semantic laws;
- preconditions/postconditions;
- invariants;
- effect/capability contract;
- error model;
- resource model;
- determinism/nondeterminism;
- foreign/environment assumptions;
- test vectors/examples;
- security properties;
- compatibility/version policy;
- performance budgets as non-logical evidence;
- source/license/provenance;
- accepted proof obligations.

Determine:

- which fields are normative;
- what is executable;
- what is proof-relevant;
- what is human-approved;
- what AI may modify;
- how a spec is versioned and hashed;
- how spec weakening is detected.

### 5. Design the AI interaction system

Do not use one omnipotent agent by default.

Explore role-separated workcells such as:

- Research/Source Agent;
- Interface Extraction Agent;
- Specification Agent;
- Specification Critic/Adversary;
- Implementation/Port Agent;
- Proof Agent;
- Counterexample/Test Agent;
- Fuzz/Differential Agent;
- Performance Agent;
- Security/Threat Agent;
- License/Provenance Agent;
- Upstream Sync Agent;
- Maintenance/Refactor Agent;
- Release/Audit Agent;
- Orchestrator.

Define write permissions.

A strong default should consider:

- Specification Agent may **propose** specs but not approve them.
- Implementation Agent may not weaken approved specs.
- Proof Agent may not change executable code/specification during a proof task unless explicitly authorized.
- AI may not add axioms, proof holes, foreign assumptions, or trusted models silently.
- Every trust-boundary delta is surfaced.
- Checker feedback is part of the agent loop.
- All AI outputs are replaceable/untrusted.

### 6. Determine the proper use of Lean 4, PSC, and PSKernel

Evaluate a division such as:

#### Lean 4

- semantic/reference oracle;
- proof development;
- theorem/tactic ecosystem;
- AI proof environment;
- external/reference checker;
- foreign verification target.

#### ProofScript / PSC

- developer-facing language;
- native package language;
- specification/contracts;
- gradual verification;
- portable application libraries.

#### PSKernel

- admission/checking authority;
- independent evidence replay;
- checked artifact identity;
- long-term small owned TCB.

#### Compiler IR

- CheckedCore;
- ErasedIR;
- VerifiedIR;
- target-specific IR;
- semantic preservation boundaries.

Do not assume this division is optimal. Improve it.

### 7. Research strongest prior art

At minimum compare:

- Lean 4 and independent kernels/checkers;
- LeanDojo;
- BRIDGE;
- P³;
- Vero;
- current AI formal-specification generation work;
- Microsoft SymCrypt + Aeneas + Lean + AI;
- Aeneas/Charon;
- Verus;
- Dafny;
- Project Everest;
- EverParse;
- HACL*/EverCrypt;
- F*;
- Fiat Cryptography;
- CompCert;
- CakeML;
- WIT / WebAssembly Component Model;
- proof-carrying code / certificates where relevant;
- SLSA;
- in-toto;
- reproducible-build systems.

Use up-to-date primary sources where possible.

Clearly distinguish:

1. what the ProofScript repository currently implements;
2. what it only plans;
3. what external systems demonstrate;
4. your own inference/proposal.

## Architecture requirements

Any serious proposal must preserve or improve these principles unless evidence strongly justifies replacing them:

1. AI is not logical proof authority.
2. Unsupported behavior fails closed.
3. CheckedCore means genuinely checked/admitted, not “prepared”.
4. Backends do not redefine ProofScript semantics.
5. Foreign behavior is an explicit assumption/model boundary.
6. Proof of source semantics is distinct from proof of backend compilation.
7. Build provenance is distinct from semantic correctness.
8. Evidence binds to exact artifact identities.
9. No generic “Verified” badge hides mixed assurance.
10. Package growth must not silently enlarge the TCB.

## Evidence architecture

Explore an explicit evidence graph.

Possible claim types:

- TypeClaim;
- SpecificationClaim;
- ProofClaim;
- BoundaryClaim;
- TranslationClaim;
- TestClaim;
- FuzzClaim;
- PerformanceClaim;
- ProvenanceClaim;
- LicenseClaim;
- ReproducibilityClaim.

Every claim should identify:

- subject artifact;
- property;
- evidence;
- checker/oracle;
- assumptions;
- dependencies;
- environment;
- status.

Evaluate whether this is better than a single assurance ladder.

## Ecosystem-growth architecture

Design a concrete system for growing the ecosystem.

Do not start with “rewrite all npm”.

Consider a portfolio algorithm:

```text
For each desired capability:
  if a foreign package is adequate:
      bind it
  if behavior needs confidence:
      characterize it
  if native semantics/portability justify the work:
      port it
  if high assurance has strong ROI:
      replace/verify it
  if many packages share one declarative structure:
      build one verified generator instead
```

Design package selection criteria:

- downstream reuse;
- semantic tractability;
- foreign-dependency burden;
- proof leverage;
- performance sensitivity;
- ecosystem importance;
- maintenance cost;
- legal/license suitability.

Design an upstream synchronization system for ports/reimplementations.

## Iterative architecture search

Do **not** stop at the first design.

### Iteration 0

Score the current Identity/Plans architecture honestly.

### Iteration 1

Design a significantly better system.

Red-team it.

Score it.

### Iteration 2+

Continue redesigning the architecture.

You may narrow the first product scope, split the system into layers, change product strategy, or replace concepts.

Do not inflate scores.

A feasibility score above 9/10 is valid only when:

- the exact scope is stated;
- all required techniques exist today or require ordinary engineering rather than speculative breakthroughs;
- the architecture has strong prior art for each difficult component;
- trust assumptions are explicit;
- the MVP is implementable by the project's realistic resources;
- the result would provide real user value;
- failure/pivot conditions are defined.

If the **general vision** cannot honestly exceed 9/10, say so.

It is acceptable—and encouraged—to find a narrower production architecture above 9/10 while retaining a lower score for the unrestricted long-term vision.

## Evaluation dimensions

Score at least:

- technical feasibility;
- formal soundness / TCB;
- architecture fit with current repo;
- implementation complexity;
- specification integrity;
- AI automation practicality;
- ecosystem acceleration;
- interoperability/migration;
- auditability;
- backend correctness story;
- performance practicality;
- developer UX;
- maintainability;
- legal/provenance manageability;
- adoption value;
- longevity;
- defensibility;
- evidence confidence.

Use both current score and potential where helpful.

## Required output

Produce:

### A. Executive conclusion

Answer:

- Can the Verified Software Factory idea be done?
- Which version is achievable today?
- Which version is not?
- What is the strongest product hypothesis?

### B. Iteration table

Show every major architecture iteration and its score.

### C. Final >9 design, if honest

Define exact scope and why it crosses 9/10.

### D. Complete architecture

Include:

- components;
- trust boundaries;
- artifacts;
- spec system;
- AI workcell;
- package migration strategies;
- evidence graph;
- release flow;
- backends;
- provenance;
- user workflows.

### E. Ecosystem bootstrap plan

Explain how to grow from:

```text
foundation
→ stdlib
→ codecs/data
→ API/protocol packages
→ effects/platform libraries
→ frameworks
→ applications
```

with AI and verification leverage.

### F. Open-source migration policy

Define bind/characterize/port/replace/generate choices, provenance/license handling, upstream synchronization, and evidence.

### G. Implementation roadmap

Map work to existing pskernel packages/contracts where possible.

Prefer incremental additions over parallel semantic implementations.

### H. Metrics and experiments

Define experiments that can falsify the ecosystem-compounding thesis.

### I. Feasibility score

Give:

- bounded MVP score;
- expanded ecosystem factory score;
- unrestricted autonomous factory score;
- evidence confidence.

### J. Revised Identity and Plans document

Update:

`study/proofscript-v0.9-r3-research/ProofScript_Programming_Language_IDENTITY_AND_PLANS.md`

Do not silently make speculative systems normative.

Mark research hypotheses clearly.

Preserve unrelated work.

If committing, fetch current branch/file state immediately before writing, use the exact current blob SHA, and make a meaningful checkpoint commit.

## Final discipline

The objective is **not** to get a high number.

The objective is to discover a system that is genuinely buildable with what exists today.

If the only honest way to exceed 9/10 is to define a constrained first product—such as a verified ecosystem accelerator for deterministic library packages—do that, and retain lower scores for broader ambitions.

Do not confuse:

```text
proof of implementation vs spec
proof of spec adequacy
proof of translation
proof of foreign environment
build provenance
runtime tests
```

They are different claims.

The best design is the one that makes these differences impossible to hide.
