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
