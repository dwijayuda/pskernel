# InterfaceIR v1 and npm / TypeScript Module Resolution

Status: **normative interop transport specification for r3**

Interface identity:

~~~text
psc-interface-ir-v1
~~~

Resolver identity:

~~~text
psc-node-exports-v1
~~~

## 1. Purpose

InterfaceIR is the versioned boundary between JavaScript/TypeScript package declarations and ProofScript foreign interfaces.

It does not make TypeScript's structural type system part of ProofScript's native type theory.

A declaration file describes a static interface; it is not runtime validation and not proof that the JavaScript implementation satisfies the declaration.

## 2. Binding identity

Every InterfaceIR package record binds together:

~~~text
package name
package version
package.json SHA-256
package install/source identity
requested export subpath
runtime target profile
module-resolution profile
runtime condition trace
selected runtime entry path + SHA-256
type condition/resolution trace
selected declaration entry path + SHA-256
TypeScript declaration-language/profile version
InterfaceIR schema version
foreign adapter profile
~~~

Changing any of these produces a different binding identity.

Package semver alone is not sufficient.

## 3. Runtime export resolution

For Node-style packages, r3 records the exact result of the package exports resolution.

The resolver:

1. loads the exact package.json bytes and records their SHA-256;
2. selects the requested export subpath;
3. applies the declared runtime target/condition set;
4. follows package exports/import/main rules according to the selected resolver profile;
5. records the ordered condition trace and selected runtime entry;
6. hashes the selected runtime artifact.

The order of conditional-export keys can affect resolution and is therefore part of the recorded resolution trace.

Example target condition profiles can include:

~~~text
node-esm: node, import, default
node-cjs: node, require, default
browser-esm: browser, import, default
~~~

Custom conditions are explicit inputs.

## 4. Declaration/type resolution

Type resolution is recorded separately from runtime resolution.

For psc-node-exports-v1:

1. use a matching exports branch with a types condition when supplied;
2. otherwise for the package root, use package-level types/typings when the selected profile permits it;
3. otherwise use the explicitly selected supported TypeScript declaration-resolution rule;
4. record the exact declaration path/hash and every resolution condition;
5. reject unresolved or ambiguous declarations.

The types condition is a typing-system condition, not a runtime condition.

The importer MUST NOT assume that the selected declaration path describes the selected runtime entry merely because both come from the same package version.

A suspicious/mismatched runtime/type branch is:

~~~text
PS_DTS_RUNTIME_TYPE_BRANCH_MISMATCH
~~~

unless a binding policy explicitly relates the branches.

## 5. Module system identity

InterfaceIR records whether the runtime entry is consumed as:

~~~text
esm-import
commonjs-require
bundler-esm
browser-esm
other-named-profile
~~~

Callable CommonJS/export-equals modules, default exports, named exports, constructors, and namespace-like values are distinct shapes.

The importer must not normalize them into one object model without an explicit adapter.

## 6. Three generated layers

### Raw layer

Represents the external interface faithfully enough to call it.

Raw types can include:

~~~text
ForeignValue
ForeignObject
ForeignHandle
ForeignPromise
ForeignCallback
ForeignSymbol
~~~

Raw does not imply safe/validated.

### Safe layer

Performs:

- numeric-domain validation;
- presence/null/undefined policy;
- plain-data snapshot/codec validation;
- handle ownership/lifetime checks;
- receiver binding;
- callback/resource management;
- Promise/App adaptation;
- thrown/rejected value classification.

### Specification layer

Optionally states logical models/theorems.

A model theorem about an abstract operation does not prove the external JS package implements that model unless a separately established adapter/foreign relationship says so.

## 7. InterfaceIR v1 declaration forms

The schema supports records for:

- constants;
- functions/call signatures;
- construct signatures;
- object/record shapes;
- variants/unions;
- classes/foreign handles;
- type aliases;
- generic declarations;
- exported namespaces/modules after supported normalization.

Each symbol includes a status such as:

~~~text
raw-unverified
runtime-validated
modeled-external
verified-adapter
trusted-assumption
unsupported
~~~

## 8. Type forms

InterfaceIR v1 type nodes include:

~~~text
unit
bool
string
number
bigint
literal
foreign-value
never
array
tuple
record
variant
function
promise
callback
handle
type-param
generic-application
opaque
~~~

A type node can carry target/presence/mutability metadata.

## 9. Presence model

Where the external API can distinguish them, InterfaceIR preserves:

~~~text
missing
undefined
null
value
~~~

An optional TypeScript property does not automatically become Option.

Each safe adapter declares its presence mapping, e.g.:

~~~text
missing -> none
undefined -> none
null -> error
value -> decode
~~~

Lossy mappings are marked as such.

## 10. Numbers

Mappings are explicit:

- JS number is a foreign floating-number domain until checked/converted;
- JS bigint can map to Int, or to Nat only after nonnegativity validation;
- fixed-width target values require range/wrapping policy;
- target arithmetic never defines PSC Nat/Int semantics.

## 11. Functions and receiver identity

A function declaration records:

~~~text
type parameters
this/receiver requirement
ordered parameters
optional/default/rest shape
return type
sync kind
throws/rejection policy
callback retention
declared effects
~~~

A method requiring this cannot be safely detached and called as an ordinary unbound function unless an adapter binds the receiver.

## 12. Overloads

An overload set is accepted only when one of these strategies is selected:

- deterministic static mapping to one PSC signature;
- explicitly named generated wrappers;
- runtime discriminator/validator;
- manual adapter.

Ambiguous overload behavior is PS_DTS_AMBIGUOUS_OVERLOAD.

PSC does not reimplement all TypeScript overload inference in the kernel.

## 13. Generics and advanced type operators

### Direct/native mapping candidates

- simple parametric generics;
- finite tuples;
- record/object data;
- literal/discriminated unions;
- simple function types.

### Import-time normalization/specialization

A bounded untrusted importer may normalize finite supported cases of:

- conditional types;
- mapped types;
- template-literal types;
- keyof;
- indexed access;
- utility aliases.

The resulting InterfaceIR is ordinary and must be validated at the boundary.

### Opaque/handle mapping

- classes with runtime identity;
- DOM nodes;
- symbols/unique symbols where logical identity is foreign;
- opaque brands without a runtime validator.

### Unsupported in Standard InterfaceIR v1 unless pre-normalized

- unbounded/recursive unsupported type-level computation;
- global augmentation that changes unrelated module types;
- module augmentation requiring ambient mutation of previously imported interfaces;
- declaration merging that cannot be deterministically normalized;
- unsupported conditional overload resolution.

Unsupported constructs never degrade to native any.

## 14. Type predicates and assertion signatures

A TypeScript type predicate or assertion signature can document/refine the TypeScript static view.

It becomes ProofScript evidence only if a safe adapter supplies an explicit runtime validator and, where a logical invariant is claimed, checked evidence connecting successful validation to that invariant.

The declaration alone is not a theorem.

## 15. Brands

A TypeScript brand/intersection can indicate intended nominality but can often be forged/bypassed at runtime.

Map it as one of:

- validated PSC wrapper;
- opaque foreign brand/handle;
- explicit trust assumption.

Never infer a native proof invariant from the brand declaration alone.

## 16. Arrays and iterables

Arrays require:

- element conversion;
- sparse-array policy;
- copy/share/mutability policy.

Iterable uses a versioned iterator adapter.

AsyncIterable maps to PSC Stream only when cancellation, demand/backpressure, failure, completion, and cleanup relations are defined.

## 17. Promise

Promise remains ForeignPromise at raw level.

The safe adapter records:

- already-started semantics;
- rejection classification;
- AbortSignal/cancellation support;
- late completion;
- callback/resource retention.

It can attach to an App/Fiber boundary but does not define PSC App semantics.

## 18. Classes and constructors

A runtime class normally maps to a foreign Handle.

InterfaceIR distinguishes:

~~~text
constructor
static member
instance member
receiver
inheritance/prototype relationship
~~~

Safe PSC wrappers expose ordinary functions/handles with explicit effects/lifetime.

## 19. Export shapes

InterfaceIR v1 distinguishes:

- default export;
- named export;
- export-equals/CommonJS callable/object;
- subpath export;
- namespace export after supported normalization.

The runtime export identity is part of the symbol identity.

## 20. Binding status and assurance

Every generated symbol records:

~~~text
sourceDeclarationSha256
runtimeArtifactSha256
bindingStatus
validationPolicy
logicalModelIdentity?
externalAssumptions
~~~

A runtime-validated symbol is not automatically a verified implementation.

## 21. Machine-readable schema

The structural JSON schema is:

~~~text
interface-ir-v1.schema.json
~~~

Schema validity checks the transport shape only.

It does not establish that the external JS package matches the declaration or that a safe adapter is correct.

## 22. Diagnostics

Normative categories include:

- PS_DTS_UNSUPPORTED_TYPE_OPERATOR
- PS_DTS_AMBIGUOUS_OVERLOAD
- PS_DTS_EXPORT_CONDITION_MISMATCH
- PS_DTS_RUNTIME_TYPE_BRANCH_MISMATCH
- PS_DTS_PRESENCE_POLICY_REQUIRED
- PS_DTS_RECEIVER_REQUIRED
- PS_DTS_RUNTIME_VALIDATION_REQUIRED
- PS_DTS_DYNAMIC_ESCAPE
- PS_DTS_MODULE_AUGMENTATION_UNSUPPORTED
- PS_DTS_DECLARATION_MERGE_UNSUPPORTED
- PS_DTS_RESOLUTION_AMBIGUOUS

## 23. Reproducibility

A published binding package records exact:

- lock/package install identity;
- package.json hash;
- runtime/type resolution traces;
- declaration hashes;
- InterfaceIR hash;
- generator/importer identity;
- target profile.

Regenerating under a different TypeScript/module-resolution profile produces a distinct binding identity.
