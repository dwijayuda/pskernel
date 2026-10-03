# r3 Source Profiles: Standard and Lean-Extensible

Status: **accepted r3 profile specification; implementation pending**

## Decision

Create two explicit <code>.ps</code> source profiles over the same Lean-compatible logical foundation:

- <code>ps-standard</code> — closed, predictable syntax for applications, packages, AI-generated code, formatting, and reproducible builds.
- <code>ps-lean-extensible</code> — advanced theorem/metaprogramming profile that permits declared Lean syntax, notation, macro, and elaborator extensions.

These are capability profiles, not different type systems.

## Normative Standard registry

The exact Standard parser/tactic/attribute policy is machine-readable in:

~~~text
PS-STANDARD-REGISTRY-r3.json
registryId = ps-standard-0.9-r3
~~~

The Standard parser is a **closed snapshot**. Package imports do not mutate its parser tables.

A release claiming `ps-standard-0.9-r3` MUST publish a materialized registration-closure manifest plus its SHA-256. Extra host-installed parser/tactic/attribute registrations are not part of Standard merely because they are available locally.

The registry explicitly lists:
- accepted r3 surface features;
- accepted native command heads;
- accepted term families;
- fixed tactic heads;
- allowed attribute names;
- forbidden syntax-mutating commands;
- forbidden elaborator attributes.

Any change to that registry is a profile revision.

The Standard profile forbids source/dependency declarations such as `syntax`, `macro`, `macro_rules`, `elab`, `elab_rules`, `declare_syntax_cat`, notation/infix/prefix/postfix declarations, and direct term/command/tactic elaborator registration unless a future Standard registry version explicitly adds the construct.

A declaration admitted from either profile enters the same selected Lean 4.34 logical model.

## Why

Lean's syntax is intentionally extensible. That is valuable for theorem proving and metaprogramming, but it conflicts with the Go-like goal of a small syntax environment that formatters, LSPs, refactorers, cache keys, and AI tools can understand without executing arbitrary package registrations.

r3 makes the choice explicit instead of pretending one profile maximizes both properties.

## ps-standard

Goals:
- stable application grammar;
- deterministic formatting;
- bounded official notation;
- reproducible parsing/elaboration environments;
- explicit package capabilities;
- best editor/AI behavior.
Standard permits:
- the r3 core surface;
- the pinned built-in Lean syntax subset listed by the Standard registry;
- a versioned official notation set;
- ordinary typeclass instances and semantic declarations;
- ordinary theorem/proof libraries;
- package-provided checked declarations and runtime adapters.

Standard rejects arbitrary dependency-provided parser productions, command macros, syntax categories, and elaborators unless promoted into a new named Standard profile version.

## ps-lean-extensible

Goals:
- Lean compatibility work;
- theorem-prover research;
- custom notation;
- macros;
- elaborators;
- custom tactics;
- Meta programming.

Extensible records:
- imported syntax categories;
- macro/elaborator registrations;
- notation scopes/priorities;
- plugin/tool identities;
- host execution permissions;
- exact environment order.

A macro still has no proof authority. Its generated declarations require ordinary admission.
The profile name does not mean "all Lean source is implemented by the standalone compiler." Coverage remains capability-scoped.

## Dependency rule

A Standard package MAY depend on a package authored in the extensible profile only through interfaces that do not import its syntax/meta registrations.

Three dependency surfaces are distinguished:

1. **semantic exports** — checked declarations/types/theorems;
2. **runtime exports** — executable artifacts/adapters with runtime identities;
3. **syntax/meta exports** — parser, macro, tactic, elaborator, or build-time host behavior.

The normative Extensible-to-Standard boundary is `PSC Semantic Bundle v1`:

~~~text
SEMANTIC-BUNDLE-v1.md
SEMANTIC-BUNDLE-v1.schema.json
schemaVersion = psc-semantic-bundle-1.0.0
~~~

A Standard importer requires `syntaxMetaExports = []` and `hostBuildEffects = []`, validates all manifest/dependency/payload hashes, and rechecks/imports the declaration payload through the selected genuine checker protocol. Runtime/external assumptions remain separately reported.

Standard may consume compatible semantic/runtime exports. It may not implicitly consume syntax/meta exports.

## Package metadata

Proposed conceptual manifest fragment:

~~~json
{
  "proofscript": {
    "edition": "0.9-r3",
    "profile": "ps-standard",
    "lean": {
      "version": "4.34.0",
      "commit": "293d5d0c0c3f3dded4688b3ccd6a33939ac5102b"
    },
    "syntaxProfile": "standard-0.9-r3",
    "capabilities": ["fs.read", "net.http"],
    "extensions": []
  }
}
~~~

An extensible project can instead list exact extension packages and their identities.

Profile, edition, syntax registry, materialized registration-closure SHA-256, semantic-bundle identities, import closure, options, semantic registrations, axiom policy, and extension identities are part of the appropriate parser/elaboration/proof cache keys.

## Standard official notation

The Standard profile may include a bounded set of official notation that materially improves application/theorem code.

Adding notation to Standard is a language/profile revision, not an incidental library install.

Ordinary operator definitions that use already-registered notation mechanisms do not grant arbitrary grammar mutation.

## Tactics

Standard can provide a rich fixed tactic environment. A tactic is not excluded merely because it is implemented through Meta programming.

The distinction is whether ordinary dependencies can mutate the parser/tactic command language invisibly.

A new Standard tactic command is part of the selected fixed environment and version identity.

## LSP and formatter implications

For Standard:
- parser tables are known before package code executes;
- formatter owns the entire Standard grammar;
- refactors can depend on a closed source-category set;
- syntax highlighting does not require arbitrary host code;
- AI tools can query a deterministic symbol/grammar index.
For Extensible:
- the LSP loads the declared extension environment;
- caches include extension identities/order/options;
- formatting may delegate registered syntax to extension formatters;
- unsupported extension formatting preserves source or reports inability rather than guessing.

## Security and host permissions

Logical soundness and host security are separate.

An extensible macro may be logically untrusted yet still have filesystem/network/process permissions if the host lets it execute.

The package/build layer must declare and sandbox such permissions where possible.

A Standard package dependency must not gain host build-script capability simply by exporting a theorem.

## .lean

The source suffix <code>.lean</code> remains native Lean syntax and uses its own selected environment.

ProofScript profiles do not inject r3 source productions into <code>.lean</code>.

A project can contain both <code>.lean</code> and <code>.ps</code> modules when the manifest gives each logical module one unambiguous authoritative source.

## Interoperability between profiles

Checked declarations cross the profile boundary through `PSC Semantic Bundle v1`.

Conceptually:

~~~text
Extensible source
  -> extension-aware parse/elaboration
  -> genuine checked declarations
  -> versioned semantic bundle
  -> Standard manifest/hash validation
  -> genuine checker import/recheck
  -> Standard semantic environment
~~~

The bundle is not a proof token. A manifest flag cannot authorize unchecked declarations.

Crossing the boundary does not provide source-level syntax compatibility. The Standard parser never installs the producing package's macro/notation/elaborator tables.

Runtime exports in a bundle retain separate target/ABI/capability/preservation identities and do not grant host permissions merely because a theorem is imported.

## Diagnostics

- <code>PS_PROFILE_SYNTAX_EXTENSION_FORBIDDEN</code>;
- <code>PS_PROFILE_EXTENSION_IDENTITY_MISMATCH</code>;
- <code>PS_PROFILE_SEMANTIC_IMPORT_REQUIRED</code>;
- <code>PS_PROFILE_RUNTIME_CAPABILITY_MISSING</code>;
- <code>PS_PROFILE_UNDECLARED_HOST_PERMISSION</code>.

## Migration

Existing r2 projects default to no r3 profile.

Migration tooling analyzes imported syntax registrations:
- projects using only the Standard closure can select <code>ps-standard</code>;
- projects requiring custom syntax/macros select <code>ps-lean-extensible</code>;
- mixed packages can split syntax tooling from semantic exports.

No project is silently downgraded.

## Evidence required before freeze

- registry closure definition;
- package-resolution prototype;
- import-order/caching tests;
- Standard parser deterministic-environment tests;
- at least one Extensible theorem package consumed semantically by a Standard app;
- LSP prototype for both profiles.

Current status: **accepted r3 profile specification**. The registry and semantic-bundle format are frozen in the named companion files; no production profile implementation is claimed.