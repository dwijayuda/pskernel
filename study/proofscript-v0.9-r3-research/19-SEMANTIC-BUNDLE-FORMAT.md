# r3 Semantic Bundle Format

Status: **normative package-boundary format**

Format identity:

~~~text
psc-semantic-bundle-v1
~~~

## 1. Purpose

A semantic bundle lets a `ps-standard` module consume checked declarations produced elsewhere, including by `ps-lean-extensible`, without importing the producing package's syntax/meta registrations into the Standard parser.

A bundle is an evidence/transport envelope. It is not proof authority by itself.

## 2. Bundle components

A bundle contains:

- exact bundle-format version;
- logical module identity;
- source package/provenance identity;
- Lean semantic pin;
- producer profile identity;
- checked declaration payload identity;
- dependency bundle identities;
- theorem/axiom dependency summary;
- syntax/meta/host-effect declarations;
- optional runtime export manifest;
- optional source-map/provenance manifest;
- exact artifact hashes.

## 3. Checked declaration payload

The manifest references one checked-declaration artifact.

Required fields:

~~~text
mediaType
moduleFormatVersion
sha256
byteLength
logicalModule
~~~

A Standard importer MUST recognize the `moduleFormatVersion`.

Unknown module formats are rejected.

The manifest does not make a caller-constructible object "checked". The importer must either:

1. recheck/reconstruct the declarations with the selected checker; or
2. consume them through a sound evidence protocol whose checker identity and assumptions are declared.

## 4. Syntax/meta isolation

For Standard semantic import, all of these MUST be empty:

~~~text
syntaxEffects
metaRegistrationEffects
hostBuildEffects
~~~

A producing Extensible package can publish a separate syntax/meta distribution for Extensible consumers, but that package is not imported through this Standard semantic surface.

## 5. Dependency closure

Every semantic dependency is listed by exact bundle identity.

A bundle import MUST fail if:

- a required bundle is missing;
- a dependency hash differs;
- the Lean semantic pin differs;
- the checker/module-format profile is incompatible;
- the axiom policy rejects a transitive assumption;
- the logical module identity collides with another selected source/bundle.

No stale sibling/fallback dependency may be substituted.

## 6. Assumptions

The bundle records transitive logical assumptions separately from runtime assumptions.

Logical assumptions include:

- user axioms;
- selected foundational/classical assumptions as required by policy;
- explicitly trusted proof shortcuts, if any.

Runtime assumptions include:

- foreign implementation/model relationships;
- target/runtime/ABI requirements;
- external service behavior.

An empty assumption list is evidence only when the selected checker/protocol establishes it.

## 7. Runtime exports

A bundle MAY refer to runtime artifacts.

Each runtime export records:

~~~text
targetProfile
runtimeAbi
artifactSha256
artifactByteLength
entry/export identity
primitive/runtime dependency manifest
preservation status
external assumptions
~~~

A checked logical bundle does not automatically authorize its runtime artifact.

## 8. Source/provenance

Optional provenance may include:

- original source module/file identity;
- grammar/profile identity;
- canonical Lean trace identity;
- source map identity;
- generator identity.

Provenance does not replace checking.

## 9. Standard import algorithm

A Standard importer:

1. verifies the bundle manifest schema/version;
2. verifies all referenced artifact hashes;
3. checks semantic/profile compatibility;
4. verifies syntax/meta/host-effect lists are empty;
5. resolves exact dependency bundles;
6. applies the selected axiom/assumption policy;
7. rechecks or validates the declaration payload through the selected evidence protocol;
8. installs only checked semantic declarations;
9. installs no parser/macro/elaborator registrations from the producing package;
10. records the bundle identity in the importing environment/cache/evidence manifest.

## 10. Identity

The canonical bundle identity is the SHA-256 of the canonical serialized manifest after all referenced artifact identities are populated.

The serialization used for hashing MUST define:

- UTF-8;
- deterministic object-key ordering;
- no insignificant whitespace;
- exact Unicode code points without normalization.

A future binary canonical encoding may replace the JSON canonicalization only under a new bundle format version.

## 11. Mutation/versioning

A changed:

- declaration payload;
- dependency bundle;
- assumption set;
- runtime artifact;
- semantic pin;
- module format;
- logical module identity

produces a different bundle identity.

SemVer/package version alone is never sufficient bundle identity.

## 12. Schema

The machine-readable envelope schema is:

`semantic-bundle.schema.json`.

The schema validates transport structure, not logical correctness.
