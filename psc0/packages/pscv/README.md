# @proofscript/pscv (private experimental profile candidate)

**NOT a conforming PSCV compiler and NOT a verified-executable npm extension.**
The package name follows the proposed distribution design; npm scope
ownership has not been established. \`private: true\` intentionally prevents
publication. It contains only a *data* descriptor with
\`allowedToEmitVerifiedExecutable:false\`, no \`main\` entry and no npm
lifecycle hooks. Installing/copying this package **does not** activate PSCV,
replace a syntax parser, load native/JS code, or grant any authority.

The canonical source reference is the repository's PSCV normative RC-v2 at
\`pscv0/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md\` (exact documented SHA256).
Lean semantic reference is 4.35.0-rc3; the *independently refining*
PSKernel Core branch targets rc4. A semantic re-pin and complete Standard
environment verification-registry manifest must precede final conformance.
The \`proofscript\` preview still pins its separate Lean4.34 compiler/runtime.

Reusable prototype: \`PSCVL/\` supplies strict but incomplete syntax
preflight, Lean verification/effect machinery and real positive/negative
pure contract checks at its own RC3 toolchain. Its \`check-preview\` may
accept extra non-normative syntax and \`check\` accepts only a bounded strict
fragment. Both report **UNCERTIFIED** and do not emit executables.
This package currently reuses those algorithms **as a repository test/
design dependency**, not by copying/upgrading them behind an unqualified
npm API.

Feature ownership:
- General terms, dependent types, inductives and source declarations stay in
  existing \`core/\`, \`syntax/\`, \`environment/\`, \`meta/\`, \`elab/\` and kernel.
- Reusable goal/tactic and VC/WP services should emerge in \`prover/\` and
  \`verification/\` only when independently testable functionality needs them.
- Reusable effect laws live in verified standard libraries.
- This package will eventually supply the frozen PSCV grammar/policy, official
  capability composition, and versioned reference/Standard manifests.
- Only the trusted \`psc\` supervisor can validate complete obligations and
  authorize \`VerifiedExecutableModule\`, erasure and verified publication.

See \`psc0/docs/platform/PSCV_PROFILE_AND_PACKAGE_BOUNDARIES.md\` for the
implementation sequence. Until the protected state transition is qualified,
\`psc build --profile pscv-v1\` and any PSCV executable emission MUST fail.
