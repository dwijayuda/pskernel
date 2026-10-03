# r3 Source Profiles: Standard and Lean-Extensible

Status: **recommend adoption**

## Decision

Create two explicit <code>.ps</code> source profiles over the same Lean-compatible logical foundation:

- <code>ps-standard</code> — closed, predictable syntax for applications, packages, AI-generated code, formatting, and reproducible builds.
- <code>ps-lean-extensible</code> — advanced theorem/metaprogramming profile that permits declared Lean syntax, notation, macro, and elaborator extensions.

These are capability profiles, not different type systems.

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

A Standard package MAY depend on a package authored in the extensible profile only through interfaces that do not require importing its syntax registrations into the Standard parser.

Three dependency surfaces are distinguished:

1. **semantic exports** — checked declarations/types/theorems;
2. **runtime exports** — executable artifacts/adapters with runtime identities;
3. **syntax/meta exports** — parser, macro, tactic, elaborator, or build-time host behavior.

Standard may consume semantic/runtime exports when their profiles are compatible.

Standard may not implicitly consume syntax/meta exports.

If source import of an extensible package would register syntax in the importer, the dependency is incompatible with <code>ps-standard</code> unless that syntax package is part of the selected Standard profile itself.

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

Profile, edition, syntax registry, import closure, options, and extension identities are part of parser/elaboration cache keys.

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

Checked declarations can cross the profile boundary through a canonical declaration bundle.

Crossing does not imply proof-script or syntax-source compatibility.
For a Standard importer, an Extensible library should ideally publish:

~~~text
source package
  -> extensible parsing/elaboration
  -> checked declarations
  -> canonical checked bundle
  -> Standard semantic import
~~~

The importer still verifies/rechecks the selected evidence protocol.

This is analogous to consuming a compiled library interface without importing its compiler plugins.

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

Current evidence: **architectural design; no production profile implementation claimed**.