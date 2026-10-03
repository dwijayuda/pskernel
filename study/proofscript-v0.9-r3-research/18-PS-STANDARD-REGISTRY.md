# r3 `ps-standard` Registry

Status: **normative source-profile definition**

Profile identity:

~~~text
ps-standard@0.9-r3
~~~

Logical semantics:

~~~text
Lean 4.34.0
293d5d0c0c3f3dded4688b3ccd6a33939ac5102b
~~~

## 1. Purpose

`ps-standard` provides a closed, reproducible source syntax and fixed meta/tactic environment for ordinary application and library development.

It is not a weaker type theory.

The same admitted declarations live in the same selected Lean-compatible logical foundation as `ps-lean-extensible`.

## 2. Standard environment roots

The Standard registration environment is defined by exact versioned roots:

1. pinned Lean `Init`;
2. pinned Lean `Std` surface selected by the Standard distribution;
3. the versioned ProofScript r3 owned grammar/registry;
4. the versioned Standard tactic/formatter registry;
5. semantic imports whose bundle manifests declare **no syntax/meta registration effects**.

An implementation MUST materialize an exact registration manifest from these roots.

The implementation MUST NOT define Standard as "whatever syntax happens to be installed on the host".

## 3. Source commands allowed to affect semantics but not syntax

Standard source may use ordinary declarations such as:

- `def`, `const`, `function`;
- `theorem`, `example`, `abbrev`, `opaque`, policy-permitted `axiom`;
- `structure`, `inductive`, `class`, `instance`;
- namespaces/sections/variables/open/export according to the pinned allowed command set;
- universe declarations;
- attributes already registered in the Standard environment;
- typeclass instances;
- simp lemmas and other semantic registrations whose command syntax is already Standard;
- fixed Standard/native tactics.

These declarations can affect elaboration/proof search and therefore remain part of the environment/cache identity.

## 4. Syntax/meta mutation forbidden in ordinary Standard source

Unless a future Standard registry explicitly promotes one specific facility, ordinary `ps-standard` source MUST reject commands that create or mutate syntax/meta behavior, including user definitions of:

- `syntax`;
- `macro`;
- `macro_rules`;
- `elab`;
- `elab_rules`;
- parser extensions;
- command/term/tactic elaborator registrations;
- new notation/infix/prefix/postfix grammar;
- new tactic syntax;
- new deriving handlers;
- new attributes whose handlers execute custom Meta/host behavior;
- custom pretty-printers/unexpanders/delaborators that change Standard source round-tripping.

The fixed Standard environment may itself contain such implementation mechanisms. The restriction is on mutation by ordinary source/dependencies.

## 5. Fixed notation and tactics

Standard does not manually redefine Lean's notation semantics.

Instead, `ps-standard-registry.json` records:

- exact semantic pin;
- exact ProofScript feature registry;
- root modules;
- permitted registration classes;
- forbidden mutation classes;
- the required implementation-generated registration-closure digest.

A release claiming `ps-standard@0.9-r3` MUST publish the materialized registration closure/digest.

Two environments with different registration-closure digests are different Standard environments even if both use the same human-readable profile name.

## 6. Imports

A Standard source import resolves to one of:

1. another `ps-standard` source module under the same registry identity;
2. a pinned native/Standard module named by the distribution allowlist;
3. a **semantic bundle** imported through `19-SEMANTIC-BUNDLE-FORMAT.md`.

Importing a semantic bundle does not execute or install source syntax registrations from the producing package.

A direct import that would mutate the Standard parser/meta environment is:

~~~text
PS_PROFILE_SYNTAX_EXTENSION_FORBIDDEN
~~~

## 7. Extensible -> Standard boundary

A `ps-lean-extensible` package may publish:

- checked semantic declarations;
- theorem/assumption metadata;
- runtime exports;
- optional source/provenance data;
- a separate syntax/meta package for Extensible consumers.

A Standard consumer imports only the semantic/runtime surfaces.

The semantic bundle MUST declare:

~~~json
{
  "syntaxEffects": [],
  "metaRegistrationEffects": [],
  "hostBuildEffects": []
}
~~~

for Standard import.

Any nonempty effect list rejects Standard semantic import unless a future named profile explicitly permits it.

## 8. Tactic environment

Standard can be rich in tactics.

The rule is not "no Meta implementation"; the rule is:

> the tactic language/handlers are fixed by the Standard registry before ordinary package source is processed.

Imported theorem/simp/instance facts can affect tactic results and are part of the environment identity.

Imported packages cannot silently add a new tactic command or replace a tactic elaborator.

## 9. Formatter/LSP contract

For Standard:

- the parser category set is fixed before user package code executes;
- the formatter owns every Standard production;
- source reformatting does not require arbitrary package host code;
- refactoring can rely on a fixed grammar;
- the LSP cache key includes Standard registry digest plus semantic import identities;
- unsupported syntax is reported rather than preserved as opaque accepted text.

## 10. Host permissions

A semantic import grants no filesystem/network/process permission to build-time code.

Host execution belongs to separately declared build/plugin capabilities.

Standard source compilation MUST NOT execute a dependency's arbitrary install/build script merely to read checked semantic declarations.

## 11. Cache identity

At minimum:

~~~text
grammar identity
Standard registry version
materialized registration-closure digest
Lean semantic commit
module source identities
semantic-bundle identities
options
instances/semantic registrations
axiom policy
compiler/checker revision
~~~

contribute to the appropriate parse/elaboration/proof cache keys.

## 12. Standard versus Extensible

`ps-lean-extensible` may use declared syntax, notation, macro, tactic, elaborator, and Meta extensions.

Those extension identities and host permissions are explicit environment inputs.

An Extensible module can still produce declarations consumed by Standard through a semantic bundle.

No extension automatically becomes Standard merely because it is popular.
