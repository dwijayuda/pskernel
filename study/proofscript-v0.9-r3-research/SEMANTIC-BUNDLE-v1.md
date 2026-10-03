# PSC Semantic Bundle v1

Status: **normative import protocol for `ps-standard` consuming checked semantic exports**

Schema: `SEMANTIC-BUNDLE-v1.schema.json`  
Schema identity: `psc-semantic-bundle-1.0.0`

## Purpose

A Standard package may depend on a library authored/elaborated under `ps-lean-extensible` without importing that library's parser, notation, macro, tactic-elaborator or host-meta side effects.

The boundary is a semantic bundle.

## Bundle layout

~~~text
<module>.psbundle/
  bundle.json
  declarations.bin
  runtime/
    ... optional target artifacts ...
~~~

`bundle.json` is UTF-8 JSON conforming to the schema.

`declarations.bin` uses versioned format `psc-checked-decls-v1`. Its internal binary encoding is owned by the checker/module-format version; a consumer MUST NOT trust it merely because it decodes.

## Required manifest identities

The manifest binds:

- logical module name;
- source profile and source identity;
- Lean semantic version/commit;
- checker/kernel identity;
- module-format version;
- source environment identity;
- direct dependency bundle identities;
- declaration payload hash/size;
- declaration name/kind/type/body identities;
- transitive/declared axiom dependencies;
- runtime exports and their artifact hashes, if any;
- evidence status;
- syntax/meta export list.

For a bundle imported by `ps-standard`, `syntaxMetaExports` MUST be empty.

## Import protocol

A Standard importer performs, in order:

1. validate `bundle.json` against the exact schema version;
2. verify semantic pin, checker/module-format compatibility and Standard registry policy;
3. verify every dependency bundle identity;
4. hash `declarations.bin` and compare size/hash;
5. recheck/import the declaration payload through the selected genuine checker protocol;
6. verify that imported declaration names/kinds/type/body identities match the checked payload;
7. recompute/report assumption dependencies under the active axiom policy;
8. accept runtime exports only under their separately declared runtime/ABI/evidence profile;
9. reject any syntax/meta export when importing into `ps-standard`.

A manifest Boolean such as `admitted: true` is never proof authority.

## Syntax/meta isolation

The bundle carries **no executable parser registration**.

The schema reserves `syntaxMetaExports` so an Extensible-to-Extensible transport can identify such exports, but Standard requires the array to be empty.

A theorem/type imported through the bundle cannot implicitly register notation, a macro, command elaborator, tactic or build script.

## Runtime exports

Runtime entries are optional and separately identified. A logical theorem bundle can be consumed without granting filesystem/network/process capability.

A runtime export records:
- target profile;
- ABI identity;
- artifact SHA-256;
- required capabilities;
- preservation/evidence status.

Logical admission does not imply target preservation.

## Canonical identity

The content hash of the complete `.psbundle` archive may identify distribution bytes, but the semantic import identity is the tuple of manifest/payload/dependency identities checked above.

Signatures may authenticate origin; they do not replace semantic checking.
