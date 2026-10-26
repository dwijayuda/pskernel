# Names and ownership

Use responsibility-specific modules. Retain compiler package/Lean module paths
unless an individually qualified extraction requires a new module. Package guides
identify input/output, public entry, dependencies, refusals/resources and tests.
Generated maps are navigation, not a second semantic authority.

Use PascalCase Lean modules/types and descriptive lower camel case operations.
Preserve current ps/Ps prefixes, public identities, error codes and protocol fields.
Keep Worker/WithFuel and accumulator order when they explain resource/evaluation
behavior. Never globally rename by regular expression. Qualified bounded binding-aware
operations apply only within their existing scope.

Authored host files use kebab-case and camelCase functions. Prefer concrete names
over utils/common/manager. Existing backend-common identities remain. Python/Cargo
follow their own language/tool naming; do not force one spelling across languages.

Distinguish execution engine, seven output targets, optional provider and independent
official Lean4.35 checker. Candidate is unadmitted output; validated IR is not a
preservation theorem; admission requires actual acceptance of exact canonical bytes.
PsVerifiedIr/PsValidatedIr wrappers are data, not unforgeable certificates.

Public commands proofscript/psc/psc1 and package exports remain stable. Canonical
internal names describe roles; compatibility modules delegate without duplication.
Package exports organize API, not security. Metadata cannot choose arbitrary tools,
checkers or plugins.

Automation may format authored host code, derive maps, check links/body movement and
apply qualified bounded renames. Separate moves, formatting, renames and behavior.
Never hand-edit generated executors, vendored kernels or frozen evidence. Readable
runtime views must be generated from the single source definitions.

## Resource location and standalone copies

Resolve a host-owned executable/helper from its owning module or trusted installed
root. The source project's working directory is data and must not select that tool.
Keep the child working directory independent. [The real-process regression](../../test/host/process-location.test.mjs)
checks both directories and the original timeout ceiling.
Compatibility delegates preserve commands in their normal tree; isolated fixtures
must copy and pin [the implementation](../../host-tools/execution/generated-service-runner.mjs),
including dependencies in protected tool inventories. No assertion is removed to
accommodate an incomplete staged tree.
