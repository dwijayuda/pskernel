# ProofScript SAVEF Open Knowledge Commons

**Status:** research policy and architecture proposal; non-normative.

**Working identity:** SAVEF-OPEN-COMMONS-v1.

**Research snapshot:** 2026-10-06.

**Purpose:** define how the public SAVEF knowledge graph can remain permanently open, freely mirrorable, commercially usable, forkable, extensible, and suitable for compounding machine-checkable knowledge across npm, Cargo, PyPI, Maven, Composer, GitHub, OCI, Wasm, and future ecosystems.

**Legal note:** this document is an engineering and licensing-policy proposal, not legal advice. License compatibility, patent, database-right, jurisdictional, and contributor-agreement questions should be reviewed by qualified counsel before a public governance policy is frozen.

---

# 1. Executive decision

SAVEF should distinguish **open knowledge** from **open implementation**.

The strongest policy is:

> **Canonical public SAVEF semantic knowledge should always remain open, while implementations and applications may use open or proprietary licenses.**

The public commons should include:

- formal definitions;
- specifications;
- theorem statements;
- proof source/evidence required for independent replay;
- CertifiedModuleInterfaces;
- effect/capability laws;
- compatibility/refinement proofs;
- TheoryExtensions;
- open counterexamples/generalizations that become canonical knowledge.

The public commons does not require every implementation using that knowledge to become open source.

~~~text
open semantic knowledge
        |
        +--> open implementation
        +--> proprietary implementation
        +--> npm package
        +--> Rust crate
        +--> Python package
        +--> JVM/PHP/Wasm package
        |
        v
more use
        |
        v
more discovered theorems/specifications
        |
        v
contributed Open Commons knowledge
        |
        +---------------------------> loop
~~~

The recommended licensing strategy is therefore layered, not one-license-for-everything.

---

# 2. Why LGPL should not be the universal SAVEF knowledge license

LGPL is a strong and respected open-source license, but it is primarily designed around software libraries and Combined Works.

SAVEF knowledge includes:

- theorem statements;
- proof terms;
- formal specifications;
- CertifiedModuleInterfaces;
- semantic compatibility certificates;
- WIT interfaces;
- graph metadata;
- evidence manifests.

These do not map cleanly to library-linking concepts.

Using LGPL as the universal knowledge license could introduce unnecessary questions around:

- generated bindings;
- static versus dynamic linking;
- recombination/relinking obligations;
- whether generated artifacts contain library material;
- cross-language package generation.

The public SAVEF commons should instead enforce openness directly through an explicit commons policy.

---

# 3. Why MPL-2.0 is a strong default for semantic knowledge

Mozilla describes MPL 2.0 as a file-level copyleft license.

Its design encourages modifications to MPL-covered files to remain open when distributed, while allowing those files to be combined with separately licensed code, including proprietary code.

This is unusually well aligned with SAVEF.

Example:

~~~text
JsonSpec.ps
    MPL-2.0

JsonProofs.ps
    MPL-2.0

company-application.ts
    proprietary
~~~

The company may use the open specification and proof library without automatically placing the entire application under MPL.

If it distributes modifications to MPL-covered source files, those covered modifications remain subject to MPL obligations.

Research source:
https://www.mozilla.org/en-US/MPL/2.0/FAQ/

---

# 4. Recommended license architecture

| SAVEF asset | Proposed default | Rationale |
| --- | --- | --- |
| Formal definitions | MPL-2.0 | reusable semantic knowledge with file-level reciprocity |
| Formal specifications | MPL-2.0 | keeps distributed modifications in the commons |
| Theorem/proof source | MPL-2.0 | software-like machine-readable knowledge |
| CertifiedModuleInterface | MPL-2.0 | part of reusable formal knowledge |
| Effect/capability laws | MPL-2.0 | reusable software mathematics |
| TheoryExtension | MPL-2.0 | public extensions remain open |
| Compatibility/refinement proof source | MPL-2.0 | shared compatibility knowledge |
| WIT/API interface definitions | Apache-2.0 | low-friction interoperability plus patent grant |
| Thin generated ecosystem adapters | Apache-2.0 | maximize npm/Cargo/PyPI/JVM/PHP reuse |
| Official runtime implementations | Apache-2.0 or MPL-2.0 | depends on desired implementation reciprocity |
| Package/index/mirror metadata | CC0-1.0 where appropriate | maximum copying and mirror reconstruction |
| Human documentation/tutorials | CC-BY-SA-4.0 or project-selected open docs license | open documentation growth |
| Benchmark/failure datasets | CC0-1.0 or CC-BY-4.0 where appropriate | broad research and AI reuse |
| Third-party executable implementation | author-selected policy-compatible license | proprietary and open implementations may coexist |

These are policy proposals, not legal determinations.

---

# 5. Why WIT should be permissive

WIT is an interface-definition language for the WebAssembly Component Model.

WIT defines types, functions, interfaces, worlds, and component imports/exports.

It does not define implementation behavior.

Source:
https://component-model.bytecodealliance.org/design/wit.html

Recommended split:

~~~text
WIT/API definition
    Apache-2.0

SPKF semantic theory
    MPL-2.0
~~~

Example:

~~~wit
// SPDX-License-Identifier: Apache-2.0

package proofscript:json@1.0.0;

interface codec {
    parse: func(data: list<u8>) -> result<string, string>;
}
~~~

SPKF may connect this interface to theorems such as:

~~~text
Json.parse_valid
Json.parse_deterministic
Json.encode_parse_roundtrip
~~~

WIT defines cross-language shape.

SPKF defines behavioral mathematics.

---

# 6. Why Apache-2.0 is appropriate for interfaces and adapters

Apache License 2.0 is permissive and includes an explicit contributor patent grant.

That is valuable for:

- WIT definitions;
- generated bindings;
- thin adapters;
- ecosystem interoperability packages.

Official license:
https://www.apache.org/licenses/LICENSE-2.0.html

Guidance:
https://www.apache.org/legal/apply-license.html

The interface boundary optimizes for maximum interoperability.

The semantic knowledge layer optimizes for open compounding.

---

# 7. Creative Commons placement

Creative Commons recommends against using CC licenses as the default software license.

ProofScript theorem/proof source behaves like software:

- machine parsed;
- elaborated;
- type checked;
- imported;
- compiled/erased;
- used to produce executable artifacts.

Therefore:

~~~text
proof/spec source
    software license

documentation/data/metadata
    Creative Commons where appropriate
~~~

CC FAQ:
https://creativecommons.org/faq/

CC0 is particularly useful for public index/mirror metadata because it is designed to waive copyright and related rights as broadly as possible.

CC0:
https://creativecommons.org/publicdomain/zero/1.0/legalcode.en

---

# 8. SAVEF Open Commons profile

Define:

~~~text
SAVEF-OPEN-COMMONS-v1
~~~

Logical validity and Commons eligibility remain separate.

~~~text
PSKernel / validator
    asks:
    is the semantic evidence valid?

Open Commons policy
    asks:
    may this object participate in the canonical freely mirrorable commons?
~~~

A theorem can be logically valid while remaining private or ineligible for the Open Commons.

---

# 9. Commons eligibility

Conceptual decision:

~~~text
ValidSemanticEvidence(object)
AND
OpenLicense(object)
AND
SourceAvailableWhereRequired(object)
AND
RedistributionPermitted(object)
AND
ModificationPermitted(object)
AND
CommercialUsePermitted(object)
AND
TransitiveCommonsPolicySatisfied(object)
---------------------------------------------
OpenCommonsEligible(object)
~~~

This can be mechanically checked as far as declared metadata permits.

It does not replace legal interpretation.

---

# 10. Proposed CommonsPolicy object

Conceptual object:

~~~json
{
  "schema": "spkf/1",
  "kind": "commons-policy",

  "policy": "savef-open-commons/1",

  "semanticKnowledge": {
    "preferred": "MPL-2.0"
  },

  "interfaces": {
    "preferred": "Apache-2.0"
  },

  "indexMetadata": {
    "preferred": "CC0-1.0"
  },

  "requirements": {
    "commercialUse": true,
    "redistribution": true,
    "modification": true,
    "mirroring": true,
    "sourceAccess": true
  }
}
~~~

Exact schema remains non-normative until separately frozen.

---

# 11. License is part of portable object identity

Licensing metadata SHOULD be included in the canonical SPKF object whose rights it describes.

Example:

~~~json
{
  "schema": "spkf/1",
  "kind": "theory-extension",

  "license": {
    "spdx": "MPL-2.0"
  },

  "subject": {
    "spkf": "spkf-v1:sha256:..."
  }
}
~~~

Consequently the same semantic material distributed under different declared licenses produces different SPKF objects.

This is desirable because the distributable object includes both semantic content and declared legal conditions.

---

# 12. Use SPDX license expressions

Do not invent custom license syntax.

Examples:

~~~text
MPL-2.0
Apache-2.0
CC0-1.0
CC-BY-SA-4.0
Apache-2.0 OR MIT
~~~

SPDX improves tooling, SBOM integration, policy automation, and interoperability.

SPDX:
https://spdx.github.io/spdx-spec/v3.0.1/

---

# 13. Do not invent a new ProofScript license initially

A custom ProofScript Open Knowledge License would create:

- license proliferation;
- legal-review friction;
- uncertain compatibility;
- corporate adoption barriers;
- tooling gaps.

Use established licenses first.

Consider a custom license only if production experience shows a requirement that established open licenses cannot satisfy.

---

# 14. Open knowledge does not require open applications

Example:

~~~text
SAVEF Json theory
    MPL-2.0
        |
        +--> Apache implementation
        +--> MPL implementation
        +--> proprietary implementation
        +--> proprietary application
~~~

The open theory remains reusable.

Applications retain their own licensing model where legally separate under the chosen license structure.

The intended balance is:

~~~text
maximum theorem reuse
+
open shared mathematics
+
commercial adoption
+
multiple implementation business models
~~~

---

# 15. Public contribution versus private knowledge

A license cannot force every independently discovered theorem to become public.

SAVEF therefore distinguishes:

## Private knowledge

A company or individual may keep internal theorems, proof strategies, specifications, and refinements private, subject to applicable underlying licenses.

## Contributed public knowledge

If an object is submitted to the canonical Open Commons, it MUST satisfy Commons policy.

~~~text
private SPKF object
        |
        | contributor chooses publication
        v
Open Commons validation
        |
        +-- semantic evidence valid?
        +-- open license?
        +-- source/evidence available?
        +-- policy compatible?
        |
        v
canonical public graph
~~~

---

# 16. Open Commons graph versus all known knowledge

~~~text
All known SPKF objects
        |
        +--> Open SAVEF Commons
        +--> private/local objects
        +--> external proprietary objects
        +--> restricted evidence
~~~

Only Open Commons semantic objects participate in the canonical freely mirrorable public knowledge corpus.

A proprietary implementation may point to Open Commons theory without itself entering the Commons.


---

# 17. Example: proprietary implementation over open mathematics

Open semantic subject:

~~~text
spkf:A

JsonSpec
parse_valid
parse_deterministic

license:
    MPL-2.0
~~~

Company implementation:

~~~text
SuperFastJson

license:
    proprietary

ImplementationWitness:
    implements spkf:A
~~~

The company may participate without publishing its implementation source, subject to applicable license boundaries.

If it contributes a new theorem such as:

~~~text
streaming_parser_memory_bound
~~~

to the public commons, that TheoryExtension must satisfy Open Commons policy.

---

# 18. Example: cross-ecosystem theorem contribution

Original theory:

~~~text
spkf:A
MPL-2.0
~~~

Rust contributor:

~~~text
spkf:T1

subject:
    A

theorem:
    streaming_parse_memory_bound

license:
    MPL-2.0
~~~

Python contributor:

~~~text
spkf:T2

subject:
    A

theorem:
    decode_error_partition_complete

license:
    MPL-2.0
~~~

Then npm, Cargo, PyPI, Maven, Composer, Wasm users, and AI agents may discover and reuse T1 and T2.

Runtime implementation licenses may differ.

The shared mathematical knowledge remains open.

---

# 19. OpenKnowledgeClosure

SAVEF should eventually compute an engineering-level licensing closure.

Conceptual function:

~~~text
OpenKnowledgeClosure(root)
~~~

checks:

- declared license expressions;
- source availability;
- dependency knowledge licenses;
- embedded knowledge blobs;
- public proof source;
- interface licenses;
- redistribution/mirroring policy.

Example:

~~~text
psc knowledge audit-license <root>
~~~

Possible output:

~~~text
KnowledgeRoot:
    OPEN-COMMONS

Semantic theory:
    MPL-2.0

Proof source:
    MPL-2.0

CertifiedModuleInterface:
    MPL-2.0

WIT:
    Apache-2.0

Index metadata:
    CC0-1.0

External proprietary implementation:
    OUTSIDE COMMONS CLOSURE

Commons result:
    PASS
~~~

The tool reports declared policy compatibility.

It does not provide legal advice.

---

# 20. Transitive licensing must be explicit

A KnowledgeRoot may depend on other semantic roots.

If the canonical Open Commons depends transitively on knowledge whose license forbids redistribution or modification, that root may fail Commons eligibility.

Example:

~~~text
Theory A
    MPL-2.0

imports Theory B
    proprietary
~~~

Then:

~~~text
OpenKnowledgeClosure(A)
    FAIL
~~~

unless B is modeled as an external boundary rather than redistributed semantic knowledge.

This mirrors SAVEF's existing distinction between internal formal knowledge and explicit assumptions/boundaries.

---

# 21. Boundary versus imported knowledge

A proprietary external implementation need not contaminate the Open Commons knowledge closure if it is modeled as a boundary.

Example:

~~~text
Open PostgreSQL transaction model
    MPL-2.0

foreign PostgreSQL server
    external boundary
~~~

The formal model remains open.

The external implementation is not embedded into the semantic knowledge closure.

This is essential for practical interoperability.

---

# 22. Patent considerations

Formal software knowledge can interact with software patents.

Apache-2.0 includes an explicit contributor patent grant.

MPL 2.0 also contains patent-related provisions.

This is one reason software-oriented licenses are preferable to general content licenses for machine-executable theorem/specification source.

Before freezing Commons policy, obtain legal review covering:

- theorem/proof code;
- generated implementations;
- WIT/interface definitions;
- contributor patent grants;
- AI-generated contributions;
- cross-license compatibility.

---

# 23. Contributor policy

A public SAVEF contribution should provide:

- contributor identity/provenance as required by project governance;
- SPDX license expression;
- proof/spec source;
- semantic profile;
- subject SPKF ID;
- authorship information where applicable;
- source repository/origin;
- machine-checkable evidence;
- declaration that the contribution can be redistributed under the stated terms.

The project may later use mechanisms such as:

- Developer Certificate of Origin;
- contributor agreement;
- repository-specific contribution terms.

These mechanisms remain separate from theorem validity.

---

# 24. AI-generated knowledge

AI may generate:

- theorem statements;
- proofs;
- specifications;
- counterexamples;
- generalizations.

Before an AI-generated object enters the public Commons:

1. semantic evidence is checked;
2. provenance is recorded;
3. license/origin policy is evaluated;
4. similarity/copyright-contamination policy is applied where appropriate;
5. human or policy approval occurs if required.

PSKernel can establish logical validity.

PSKernel cannot establish copyright provenance.

Those are separate authority systems.

---

# 25. Open training and retrieval corpus

A major benefit of the Open Commons is a high-quality public AI corpus containing:

~~~text
formal specification
implementation
proof
kernel acceptance/rejection
counterexample
dependency graph
repair path
generalized theorem
performance evidence
~~~

Training and retrieval must still respect the license and provenance policy of each object.

The Commons license defaults should be selected partly to make broad machine use practical.

---

# 26. Asset-specific openness

Different assets have different legal and engineering roles.

Preferred pattern:

~~~text
semantic source
    reciprocal open software license

interoperability interface
    permissive software license

index facts
    public-domain-style dedication where appropriate

documentation
    open-content license
~~~

One license should not be forced mechanically onto every artifact type.

---

# 27. Open Definition and OSI floor

Canonical Commons policy should preserve freedoms consistent with the Open Definition:

- access;
- use;
- modification;
- redistribution;
- commercial use;
- no field-of-use discrimination.

Open Definition:
https://opendefinition.org/od/2.1/en/

For software-like knowledge source, prefer OSI-approved licenses.

Open Source Definition:
https://opensource.org/osd

The canonical Commons should reject licenses with restrictions such as:

- NonCommercial;
- NoDerivatives;
- research-only use;
- registry-exclusive redistribution;
- industry/geography restrictions.

Such objects may still exist outside the canonical Open Commons.

---

# 28. Commons acceptance states

Recommended states:

~~~text
SEMANTICALLY_VALID
    evidence checks

OPEN_ELIGIBLE
    licensing/policy checks

INDEXED
    metadata/quality policy

CANONICAL
    preferred/generalized knowledge
~~~

Example:

~~~text
valid proprietary theorem

SEMANTICALLY_VALID = yes
OPEN_ELIGIBLE = no
INDEXED_PUBLIC_COMMONS = no
~~~

Another:

~~~text
valid MPL theorem

SEMANTICALLY_VALID = yes
OPEN_ELIGIBLE = yes
INDEXED = yes
CANONICAL = maybe
~~~

This prevents legal openness, logical correctness, and quality ranking from being conflated.

---

# 29. Curation remains necessary

Open licensing alone can produce:

- duplicate theorems;
- overspecialized facts;
- AI-generated spam;
- weak abstractions.

The factory may identify:

~~~text
T1
T2
T3
T4
~~~

as instances of a more reusable theorem G.

After G is checked:

~~~text
G
    canonical

T1-T4
    valid but lower-ranked
~~~

All remain open and immutable.

---

# 30. Mirroring guarantee

Every Open Commons semantic object should permit lawful mirroring.

Operational target:

~~~text
psc knowledge mirror <root>
~~~

A mirror should be able to redistribute:

- canonical knowledge root;
- theorem extensions;
- required proof source;
- CertifiedModuleInterfaces;
- required semantic artifacts;
- licensing metadata.

Executable implementations are mirrored according to their own licenses.

The semantic commons should not depend on one commercial host.

---

# 31. OCI and GitHub

SPKF Open Commons knowledge may be mirrored through OCI/GHCR.

OCI is transport, not licensing authority.

A root may be available through:

~~~text
GHCR
university OCI registry
community registry
offline snapshot
~~~

with the same SPKF semantic identity.

GitHub immutable releases can additionally archive stable Commons snapshots.

---

# 32. Package-manager bindings

Open Commons policy travels independently of ecosystem distribution.

Example:

~~~text
Theory A
    MPL-2.0

npm wrapper
    Apache-2.0

Cargo wrapper
    Apache-2.0

PyPI wrapper
    Apache-2.0

Maven wrapper
    Apache-2.0

proprietary internal implementation
    proprietary
~~~

All may point to the same open semantic theory.

---

# 33. WIT licensing rule

Recommended default:

~~~text
WIT
    Apache-2.0
~~~

Reasons:

1. WIT is an interface contract, not behavior implementation.
2. Generated bindings should have minimal licensing friction.
3. Apache-2.0 provides broad reuse and an explicit patent grant.
4. Behavioral reciprocity is enforced at the SPKF semantic-knowledge layer.

Do not use WIT licensing as the mechanism that keeps theorem knowledge open.

---

# 34. Why not GPL or AGPL for the universal semantic layer

Strong copyleft can be appropriate for specific implementations.

It is less attractive as the default universal semantic-knowledge policy because SAVEF targets reuse across:

- proprietary applications;
- cloud systems;
- embedded software;
- mobile apps;
- open-source projects;
- enterprise systems;
- research tools.

The Commons should maximize reuse of the mathematics while keeping distributed modifications to the canonical knowledge open.

A weak/file-level reciprocal model is better aligned with that objective.

Implementations may independently choose GPL/AGPL.

---

# 35. Dual licensing

A knowledge author may choose an SPDX expression such as:

~~~text
MPL-2.0 OR LicenseRef-Commercial
~~~

The Commons policy should ask whether at least one offered licensing path satisfies Open Commons requirements.

This can support commercial licensing while retaining a permanently open path.

---

# 36. License compatibility results

SAVEF may later maintain a non-authoritative license-policy knowledge base.

Concept:

~~~text
LicensePolicyResult {
    object
    commonsPolicy
    declaredLicense
    result
    policyVersion
    rationale
}
~~~

This is policy/tooling output.

It is not a theorem covering every jurisdiction.

Legal guidance can change without changing the underlying semantic theorem object.

---

# 37. Governance

The public Commons should transparently govern:

- approved license set;
- canonical theorem/spec ranking;
- spam controls;
- deprecation;
- policy migration;
- supported semantic profiles;
- mirror requirements;
- contributor policy.

Governance cannot mutate content-addressed historical objects.

It changes only:

- indexing;
- recommendation;
- active support;
- policy eligibility.

---

# 38. Policy versioning

Commons policy is versioned separately from SPKF.

Example:

~~~text
SPKF:
    spkf/1

Commons policy:
    savef-open-commons/1
~~~

A future:

~~~text
savef-open-commons/2
~~~

does not reinterpret old SPKF bytes.

This separation is important for longevity.

---

# 39. Initial implementation roadmap

## Commons-0 — licensing metadata

Add to SPKF:

~~~text
license.spdx
sourceForm
commonsPolicy
~~~

Implement:

~~~text
psc knowledge audit-license
~~~

## Commons-1 — public index enforcement

Public SAVEF index accepts only Commons-eligible semantic roots and TheoryExtensions into the canonical Commons view.

## Commons-2 — WIT/interface defaults

Official WIT and thin generated bindings use Apache-2.0 by default.

## Commons-3 — independent mirrors

Publish the canonical semantic graph to at least two independently controlled mirrors.

## Commons-4 — transitive closure

Implement OpenKnowledgeClosure.

## Commons-5 — public AI corpus

Generate an Open-Commons-only theorem/spec/failure corpus with provenance.

---

# 40. Acceptance criteria

An object qualifies for SAVEF-OPEN-COMMONS-v1 only if:

1. semantic evidence is valid under its declared assurance policy;
2. it has an SPDX-recognized or explicitly approved open license;
3. commercial use is permitted;
4. redistribution is permitted;
5. modification/derivative works are permitted;
6. mirroring is permitted;
7. required source/evidence form is accessible;
8. transitive embedded semantic knowledge satisfies Commons policy;
9. license metadata is included in content-addressed identity as defined by SPKF;
10. provenance satisfies project contribution policy.

Failing Commons eligibility does not imply semantic invalidity.

---

# 41. Questions requiring legal review before freeze

1. Is MPL-2.0 the best default for ProofScript theorem/spec source?
2. Should CertifiedModuleInterface source be MPL-covered by default?
3. How should generated proof/interface artifacts be classified?
4. Is Apache-2.0 the best default for WIT/generated bindings?
5. How should patent grants interact with formal specifications?
6. What contributor policy is appropriate for AI-assisted work?
7. How should large derived theorem indexes handle database rights?
8. Is CC0 suitable for all intended metadata jurisdictions?
9. What GPL-family compatibility paths need explicit support?
10. Is DCO sufficient or is a CLA preferable?

---

# 42. Research references

## Mozilla Public License 2.0

https://www.mozilla.org/en-US/MPL/

https://www.mozilla.org/en-US/MPL/2.0/FAQ/

Key property used here:

> file-level copyleft intended to keep covered modifications open while permitting combination with separately licensed code.

## Apache License 2.0

https://www.apache.org/licenses/LICENSE-2.0.html

https://www.apache.org/legal/apply-license.html

Key property used here:

> permissive software licensing with an explicit contributor patent grant.

## Creative Commons

https://creativecommons.org/faq/

https://creativecommons.org/publicdomain/zero/1.0/legalcode.en

Used here primarily for documentation/data/metadata rather than ProofScript software/proof source.

## WIT / WebAssembly Component Model

https://component-model.bytecodealliance.org/design/wit.html

Key distinction:

> WIT defines interfaces/worlds, not component behavior.

## Open Definition

https://opendefinition.org/od/2.1/en/

## Open Source Definition

https://opensource.org/osd

## SPDX

https://spdx.github.io/spdx-spec/v3.0.1/

---

# 43. Canonical policy recommendation

> **SAVEF should maintain a canonical Open Knowledge Commons in which formal definitions, specifications, theorem/proof source, CertifiedModuleInterfaces, effect laws, and TheoryExtensions remain openly licensed and freely mirrorable. The default research recommendation is MPL-2.0 for machine-checkable semantic knowledge, Apache-2.0 for WIT/interfaces and thin interoperability adapters, CC0-1.0 for public index/mirror metadata where appropriate, and an open-content license such as CC-BY-SA-4.0 for explanatory documentation. Runtime implementations and applications may use other licenses, including proprietary licenses, provided restricted material is not falsely represented as canonical Open Commons knowledge.**

The architectural objective is not:

> make every program open source.

It is:

> **make the shared mathematical knowledge underlying software permanently open and cumulatively improvable.**

---

# 44. Final principle

~~~text
one open theorem
        |
        +--> npm users
        +--> Rust users
        +--> Python users
        +--> JVM users
        +--> PHP users
        +--> proprietary applications
        +--> open-source applications
        +--> AI agents
        |
        v
new discoveries
        |
        v
open TheoryExtensions
        |
        v
larger shared mathematical software commons
        |
        +-------------------------------> repeat
~~~

The most important rule is:

> **Keep the knowledge open, keep interoperability permissive, and do not require every application built on top of that knowledge to share one licensing model.**

That gives SAVEF the widest adoption surface while preserving an openly compounding body of executable software mathematics.
