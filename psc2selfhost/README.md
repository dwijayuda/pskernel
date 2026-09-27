# PSC2 self-host compiler workspace

This is the implementation home for the PSC2 language and its self-hosting
compiler. The user selected this directory on 2026-09-27 (Asia/Jakarta).
Development starts from the existing packages; it does not start a replacement
compiler architecture.

**Current state:** substantial Lean-authored compiler/backend/kernel source,
with integration and bootstrap gates still open. The documentation added here
does not certify that the compiler builds or self-hosts. See the dated
[status](STATUS.md) for measured results.

## Read in this order

1. [Governance](GOVERNANCE.md): authority, scope, invariants and change rules.
2. [Architecture](ARCHITECTURE.md): package ownership and checking boundaries.
3. [Bootstrap](BOOTSTRAP.md): source authority, generations and host transitions.
4. [Acceptance gates](ACCEPTANCE_GATES.md): exact meanings of completion claims.
5. [Roadmap](ROADMAP.md): dependency order and PSC2 feature delivery.
6. [First implementation plan](plans/01_FOUNDATION_REPAIR.md): bounded next work.
7. [Decisions](DECISIONS.md): resolved conflicts and open freeze obligations.
8. [Status](STATUS.md) and [sources](SOURCES.md): evidence and branch provenance.

The [PSC2 language reference](../PSC2%20Lang/PSC2_LANGUAGE_REFERENCE.md) governs
the planned language. These workspace documents govern implementation and
assurance; they do not silently revise language meaning.

## Three independent completion claims

| Claim | Required result |
| --- | --- |
| Compiler self-host | The declared portable compiler closure compiles itself through repeated generated generations; any external kernel is explicitly identified. |
| Compiler + kernel self-host | The kernel closure also passes source translation, generated execution, independent checking and generation parity. |
| PSC2 profile complete | Every feature required by the declared PSC2 profile has positive/negative conformance evidence. |

None of these implies formal compiler correctness or full Lean equivalence.
Use language profile names (`PSC1`, `PSC2`) independently from compiler
generation names (`G0`, `G1`, `G2`, `G3`). Older plans use PSC2 for a second
generation; that usage is not a PSC2 language-completion claim.

## Development commands

Run existing commands from this directory:

```bash
npm run check:workspace
npm run check:source
npm run check:ir-neutrality
npm run build:lake
npm run test:lean
```

They are diagnostic entry points, not a claim that all currently pass.
`check:workspace` is known to fail at the documented baseline. Lean/Lake must
be installed using the repository pin before executing Lean commands.
Do not run expensive generation loops until their prerequisite gates pass.

## Scope of this documentation change

This package records the target architecture and implementation plan. It changes
no compiler, kernel, build script, language reference or CI workflow. Proposed
interfaces, commands and artifacts are explicitly labeled as planned until
implemented. Existing `selfhost/` and other branches remain independent work
that may supply reviewed changes; this directory must earn its own evidence.
