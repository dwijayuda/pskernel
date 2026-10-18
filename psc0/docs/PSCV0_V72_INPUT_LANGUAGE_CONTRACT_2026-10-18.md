# v7.2 contract for both PSC0 input languages

User instruction,18 October2026:
> remember that the .ps and .lean input in psc0 compiler follows v7.2 language
> (meaning language features we built for .ps and .lean as input to compile to
> .js, .ts, .rs, .wasm, .wat, etc)

**Input-language contract clarified by the user on18 October:** both `.ps`
and `.lean` files supplied to PSC0 follow the selected v7.2 language features,
semantics and assurance rules when compiling to JavaScript, TypeScript, Rust,
Wasm, WAT and other supported artifacts. This concerns compiler INPUTS; it is
not merely an instruction about the compiler implementation's .lean files.
The two source kinds keep their respective surface grammars: native Lean layout
and application in .lean, owned ProofScript spelling in .ps. Both must converge
on shared resolution/elaboration, checked Core, typed erasure, validated IR and
backends. A .lean extension cannot bypass unsupported-feature, dependency,
assumption, recursion or verification rules. Do not silently parse .lean as .ps,
treat arbitrary host Lean as accepted input, or infer input parity from native
reference tests. Record actual support separately until paired qualification
passes. Compiler implementation remains native portable .lean; self-hosting
and immediate C5 stay out of scope.

## Architecture and inspected implementation

Reference: PSCV0_LANGUAGE_REFERENCE_v7.2.md, particularly its semantic-subset
identity and source-kind grammar distinctions, combined with the explicit user
clarification above. The reference file and its immutable identity are unchanged.
Pinned implementation/correctness reference is Lean4.35.0
 eb6cafb7290e8bd5f2937522d8d804f58f02bafc. Study the corresponding pinned parser,
elaborator and tests before changing either input frontend.

Inspection atade87651 establishes a real coverage gap:
- packages/compiler/src/Ps/Compiler/Api.lean: PsCompilerSourceKind already has
  lean/proofScript. The .lean route parses to the older PsSyntaxModule and uses
  module elaboration. Its existence is not a v7.2 parity result.
- packages/syntax/src/Ps/Syntax/ParseLean.lean: declaration selection currently
  includes def, partial def, theorem, inductive and structure. It does not dispatch
  the full newer command/strategy surface implemented by Pscv0/ProgramRead.
- host/src/Ps/Host/NativeV7.lean: Request has source/sourceName but no source-kind
  selector; isolated requests always call psCompilerParsePscv0. Named modules
  also use the Pscv0 project frontend. A filename alone does not select Lean input.

These are source-inspection findings, not a newly run conformance suite. Current
main CI remains valid for exactly what it executes. Native Lean oracle definitions
are independent semantic controls, not tests of PSC0's .lean input frontend.

## Existing milestone obligations

M3+B source-strategy and cross-stage exits must include the selected .lean source
routing and feature parity. M4+C/D introduces effects/contracts with both inputs;
M5+E closes the complete source-kind/rule/assurance/backend matrix. Existing M2+A
acceptance remains its original bounded profile. No extra milestone is needed.

Use explicit source-kind ownership, two owned syntax adapters and one semantic
pipeline. Preserve source spans and names through a common command/program AST.
Share feature rules, scopes, constraints, recursion construction, proof checking,
erasure, noncomputable policy, module identity and backend lowering. Backend
selection must not change source-language meaning or grant a missing feature.
Do not duplicate the elaborator or implement parity by adding arbitrary braces,
renaming file extensions or invoking an unrestricted host compiler fallback.

At each coherent feature slice, pair representative .ps/.lean inputs and intended
refusals, compare their checked meaning with pinned Lean, then exercise relevant
existing target observers. Keep tests minimal and focused. Record implemented,
qualified and missing cells separately; ordinary output never gains a verified
identity from a successful parse, oracle result or narrower backend test.

## Pinned frontend architecture reference

Inspected Lean4.35.0 Frontend.lean:19-82, Parser/Module.lean:119-179 and
Parser/Command.lean:114-162. The native frontend keeps input/source positions,
parser state and command elaboration state distinct, passing scoped environment
and namespace/open information into command parsing. Top-level parsing owns
indentation and advances on errors; elaboration owns the command's meaning.
Modifier and contract syntax is selected structurally, not by renaming files.

Adapt those boundaries to the smaller portable compiler: explicit input kind on
requests and named modules, owned source-kind parsers into the shared program AST,
one selected semantic pipeline and accurate source provenance. Reuse existing
Lean token/layout parsing where correct, extending command/program ownership
rather than converting text through the .ps printer. Qualification must exercise
PSC0's actual .lean path; source reconstruction/C5 and host Lean oracles remain
separate. No frontend implementation change is claimed by this design note.
