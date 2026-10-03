# InterfaceIR v1 — npm / TypeScript Boundary

Status: **normative r3 binding interchange format**

Schema: `INTERFACEIR-v1.schema.json`  
Schema identity: `proofscript-interface-ir-1.0.0`

## 1. Resolution identity

An InterfaceIR file binds the runtime and type surfaces selected from an npm package. The identity includes:

- TypeScript version/profile;
- TypeScript `moduleResolution` mode;
- resolver profile `psc-node-exports-v1`;
- install/package-store identity and optional lockfile SHA-256;
- custom conditions;
- ordered effective export conditions;
- package name/version;
- exact `package.json` SHA-256;
- requested export subpath;
- ordered runtime condition trace;
- selected runtime entry, module format, and runtime-entry SHA-256;
- ordered type/declaration condition trace;
- selected declaration entry and declaration-entry SHA-256;
- every declaration-file SHA-256;
- target runtime/platform.

This is necessary because Node conditional exports can select different runtime entries and TypeScript's resolver can select explicit/versioned `types` conditions and custom conditions.

## 2. Resolution rule

The importer MUST use the declared TypeScript resolver/version for the type side and `psc-node-exports-v1` (or a future explicitly named resolver profile) for the runtime side.

It MUST record the complete ordered condition traces and the final selected entries rather than only the original module specifier.

The runtime entry bytes and selected type/declaration entry bytes are separately hashed. A package version or path alone is never sufficient binding identity.

If runtime/type entries cannot be shown to belong to the same requested package export surface under the recorded condition set, the binding rejects with `PS_DTS_EXPORT_CONDITION_MISMATCH`.

If the selected declaration branch is plausibly from a different conditional/export surface than the selected runtime branch and no explicit binding policy relates them, reject with `PS_DTS_RUNTIME_TYPE_BRANCH_MISMATCH`.

## 3. Support classes

Every declaration/type feature is classified as exactly one of:

- `native` — direct PSC type/value mapping;
- `specialized` — import-time finite specialization produces ordinary InterfaceIR;
- `runtime-adapter` — requires explicit conversion/lifetime/effect code;
- `opaque-handle` — identity-bearing foreign object;
- `import-normalization` — TypeScript-only type computation erased by a checked importer normalization result;
- `unsupported`.

Unsupported never becomes native `any`.

## 4. Required initial support matrix

| TypeScript / JS construct | r3 InterfaceIR treatment |
|---|---|
| string/boolean | native or checked text/bool adapter |
| number | runtime-adapter to chosen Float/checked Int/Nat domain |
| bigint | runtime-adapter; Nat checks nonnegativity |
| unknown / any | opaque ForeignValue; explicit refinement required |
| null / undefined / missing | explicit presence policy |
| arrays/tuples | adapter/native data according to copy/mutability policy |
| readonly | static metadata only; no deep-freeze theorem |
| literal/discriminated union | specialized/native variant where discriminator is defined |
| ambiguous structural union | runtime-adapter or unsupported |
| Promise | runtime-adapter to foreign async/App bridge |
| callback | runtime-adapter with retention/reentrancy/disposal metadata |
| class instance / DOM node | opaque-handle |
| receiver / `this` | explicit receiver metadata |
| simple generic | native/specialized when mapping is parametric and defined |
| overloads | specialized wrapper set or unsupported |
| conditional/mapped/template type | import-normalization for supported finite cases; otherwise unsupported |
| keyof / indexed access | import-normalization for finite schemas |
| branded type | validated wrapper, opaque brand, or explicit assumption |
| Iterable | runtime-adapter |
| AsyncIterable | runtime-adapter to Stream only with demand/cancel/cleanup semantics |
| type predicate/assertion signature | explicit runtime-refinement adapter; not proof by declaration alone |
| declaration/module augmentation | unsupported in Standard importer v1 unless normalized before InterfaceIR |
| callable/constructable object | explicit call/construct signatures; no implicit object-to-function coercion |

## 5. Raw, safe and specification layers

InterfaceIR records the **raw foreign shape**. Generated PSC packages may add:

- raw declarations;
- safe validators/codecs;
- resource/async adapters;
- optional logical models/specifications.

A specification about a foreign library remains an external model until implementation correspondence is separately established.

## 6. Presence

`missing`, `undefined`, `null` and `value` are distinct states in InterfaceIR.

A safe adapter may collapse them only through an explicit `presencePolicy` that reports lossiness.

## 7. Functions and effects

A function declaration records:
- receiver requirement;
- type parameters;
- parameters;
- result;
- sync kind;
- Promise/callback behavior;
- documented throw policy;
- effect/capability classification;
- overload group if any.

An arbitrary thrown JS value is not silently converted into the typed PSC error parameter.

## 8. Versioning

Changing the schema, resolver rules, support matrix or interpretation of a tagged node requires an InterfaceIR schema-version change.

The full binding identity includes the InterfaceIR bytes plus install identity, package.json identity, resolver profile, export subpath, ordered runtime/type condition traces, exact runtime-entry hash, exact type-entry/declaration hashes, TypeScript profile/version, target runtime/platform, and all referenced declaration hashes.
