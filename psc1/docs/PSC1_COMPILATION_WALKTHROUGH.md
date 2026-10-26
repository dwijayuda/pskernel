# One program from source to checked output

This walkthrough follows the current native source path on a clean Linux Actions
checkout. The installed .7 G3 path is described separately below. Both share the
portable semantic compiler; their host entry points and source identities differ.
Run these commands in Linux GitHub Actions, not on the local development machine.

## Build and run the example

From psc1, install the repository-pinned Lean and locked host dependencies exactly
as .github/workflows/psc1-maintainability.yml does, then:

~~~sh
lake build psc1 psc1_independent_checker
node scripts/compilation-walkthrough.mjs
~~~

The script writes this exact Main.lean into dist/maintainability/walkthrough:

~~~lean
def invert (flag : Bool) : Bool := if flag then false else true
~~~

The corresponding Main.ps is:

~~~text
def invert(flag : Bool) : Bool := if (flag) { false } else { true }
~~~

For each grammar the test launches the actual compiler command:

~~~sh
.lake/build/bin/psc1 build Main.lean --target js --out module.js
~~~

The harness supplies 240s supervision and the existing bounded-process profile and8MiB native Lean thread-stack policy. It checks the
public invert export by loading the **immutable** generated file in a separate
Node process: invert(false)=true, invert(true)=false. Then it changes the tiny
program to identity and requires the different results(false,true).
This is a deliberate application change, not an automatic compiler rewrite.

## Follow the actual owners

<!-- generated-pass-links:start -->
| Step | Source entry | Responsibility |
| --- | --- | --- |
| capture | [psHostCaptureProject](../host/src/Ps/Host/SourceSnapshot.lean#L62) | Capture exact dependency-ordered source bytes |
| parse | [psCompilerParseSource](../packages/compiler/src/Ps/Compiler/Api.lean#L64) | Choose one grammar and produce shared syntax |
| elaborate | [psElabModuleWithOrigins](../packages/elab/src/Ps/Elab/Declaration.lean#L1830) | Resolve and type declarations with actual ownership |
| encode | [psCompilerPrepareElaboratedWithOutput](../packages/compiler/src/Ps/Compiler/Api.lean#L101) | Encode canonical logical admissions |
| admit | [psHostLeanCheckPrepared](../host/src/Ps/Host/LeanChecked.lean#L7) | Require official independent logical acceptance |
| erase | [psCompilerVerifiedIrFromPrepared](../packages/compiler/src/Ps/Compiler/Api.lean#L293) | Erase from the same prepared declarations |
| validate | [psStrictValidateModule](../packages/compiler-ir/src/Ps/CompilerIr/Validate.lean#L20) | Validate executable IR |
| plan | [psBackendClosedPlanDetailed](../packages/backend-common/src/Ps/BackendCommon/Plan.lean#L150) | Specialize the closed public target plan |
| emit | [jsSource](../host/src/Ps/Host/DirectBackend.lean#L327) | Lower, validate and print JS |
| publish | [export function publish(](../host-tools/artifacts.mjs#L518) | Seal and publish the native bundle |
<!-- generated-pass-links:end -->

The native CLI starts in [Main.lean](../packages/cli/src/Main.lean).
Ps.Host.DirectBackend.checkedInput captures once and obtains admission.
psHostDirectPrepareFor erases the prepared declarations and requires strict IR.
ecmaPlan revalidates the specialized public target before jsSource
lowers/prints it. Ps.Host.ArtifactBundle delegates only staging/formatting/
publication to the fixed host tool. See [pass contracts](PSC1_PASS_CONTRACTS.md)
for exact obligations and refusal/resource behavior.

At each arrow, ask what the data means:
- Text/syntax has not acquired logical admission.
- Prepared declarations are the exact logical input; their names do not prove runtime behavior.
- Strict IR checks executable structure and types before and after transformations.
- Printed code remains a candidate until host checks and publication succeed.
- A sealed inventory proves integrity of these bytes, not their semantic equivalence.

## Inspect the evidence

The harness reads the real module.js.bundle.json pointer, resolves its immutable
generation and verifies every inventory hash. In that generation:
- psc1-input.json records exact sources, public names, assurance and provenance.
- admissions.json holds the canonical logical graph used for official checking.
- The manifest binds checker version/commit, target, source closure and output files.
- The generated module and declaration/source-map files are output artifacts.

It sends those exact admissions bytes to the separate actual official checker
and requires its Lean4.35 identity and accepted response. This additional replay
is logical acceptance evidence. It is not source-to-IR/backend preservation.

An ill-typed replacement(declared Bool, returned Nat) must refuse and leave the
previous manifest pointer, generation and artifact bytes unchanged. The test
restores the fixture source afterward and retains reports plus a complete
generation archive. No source in packages/ is edited by the harness.
The native legacy publisher commits its pointer before its final directory flush;
a late flush error can occur after commitment. The installed generated publisher
reports committedPublication explicitly. Inspect committed state after late native
errors; neither path permits assuming every publication error means rollback.

## Installed generated compiler path

Use [the exact .7 tarballs](PSC1_CHECKED_DISPATCH_INSTALL.md). Its public entry is
[npm-cli/universal.mjs](../npm-cli/universal.mjs), the pinned resource resolver is
[installed-engine-resolver.mjs](../host-tools/installed-engine-resolver.mjs), and
[generated-compiler-session.mjs](../host-tools/generated-compiler-session.mjs)
owns capture, the actual G3 response, independent admission, target consumption
and publication. [Compiler Service](../packages/compiler/src/Ps/Compiler/Service.lean)
is the shared portable orchestration. The installed default checker is the
genuine official C++/Emscripten linear-memory Wasm kernel.

Execution engine, requested output and independent checker are separate choices.
Component output wraps exact GC core; Python/PHP receive only admitted portable
IR and recheck it. Source/package metadata cannot choose those host capabilities.
The package remains attached to its qualified122-module source; a new123-module
development extraction does not relabel its executable or fixed-point evidence.

## A first maintainer change

Complete [the independent exercise](PSC1_MAINTAINER_EXERCISE.md) before reading
its reference solution. Explain the data and authority at each step, add one
focused compiler regression, run the actual commands and record what confused
you. Automated CI verifies reproducibility; a human trial is required before
claiming the walkthrough is understandable to fresh maintainers.
