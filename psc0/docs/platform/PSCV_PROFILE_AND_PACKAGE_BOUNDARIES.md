# PSC0 — PSCV feature ownership, package boundaries and certified-emission design

**Status: accepted P0 architecture decision + experimental, fail-closed
implementation pilot. NOT `pscv-v1` conformance, NOT `PSCV-CERT-v1` issuance,
NOT an executable compiler.**

**Normative basis:** PSCV-RC-v2 `pscv0/PROOFSCRIPT_PSCV_LANGUAGE_REFERENCE.md`
(SHA256 `4c02626fd0b991e8526c64b65f4ffb66b9ce7b688298e82fb0309802a263db71`),
especially §2.3–2.6, Chapter 20, §21 effects/verification, §§23.9–23.10,
§24/Appendix K, §§29–30, Appendix G. Implementation observations are dated;
do not infer unseen later Core branch status from them.

## Decision 1 — do not rename the existing workspace

Keep `packages/{foundation,syntax,core,environment,meta,elab,bridge,
compiler-ir,erasure,compiler,backend-ts,bootstrap,pskernel-core,...}`.
These are already concrete package/module boundaries with Lake and npm
metadata; there is no architectural evidence that bulk renaming to
`pscore` / `psfrontend` would strengthen security. The names
`pscore`, `psfrontend`, `psbackend-ts`, and `psc` describe *logical*
interfaces and future distribution where it is justified, not obligatory
new source trees or independent npm publications.

Required invariants are enforced by import-graph contracts, pinned
interfaces, independent provider admission, isolated external execution
and the supervisor's exclusive publication authority—not source
directory spelling. Preserve the 62-module self-host compiler closure,
authoring seed, and currently selected native Core provider until each
separate qualification gate permits a change.

Do not confuse compiler `packages/core/` with the independent logical
`packages/pskernel-core/`.

## Decision 2 — assign PSCV features to their natural owner

The `pscv-v1` *language* requires every normative feature, but a required
feature does **not** have to be physically implemented by the PSCV npm
package or introduce a new kernel primitive. Canonical feature ownership:

| Feature family / normative obligation | Implementation ownership | PSCV profile responsibility |
| --- | --- | --- |
| Prop, Type, Sort, Pi, Eq, Core typing and conversion | independent PSKernel Core; compiler `core/` and `bridge/` for term encodings | select exact semantic target and approved foundation; never replace Core |
| Ordinary definitions, `function`, `const` aliases, basic application and binders | `syntax/`, `meta/`, `elab/`, `environment/` | approve exactly those source productions and deterministic choices |
| Modules, imports, namespaces, records, inductives, indexed inductives, classes, instances, coercions | generic frontend/environment, plus pinned resolver | closed module/standard environment, compiler/VC import identity |
| Dependent and refinement types, `Subtype`, `Fin`, proof fields | generic Core/elaboration + normal verified libraries | constraints on executable reachability and refinement contracts |
| Theorem declarations, proof terms and goal state | generic frontend, Core, kernel; future `prover/` if needed | exact goal/evidence profiles; closed Standard proof grammar |
| `rfl`, `apply`, `exact`, `simp`, `omega`, `grind` and Standard tactics | proof-producing tactic service(s), e.g. future `pstactics-standard`, reusing pinned Lean when available | freeze exact tactic surface, versions and proof registry; no ambient plugin mutation |
| Recursive totality, well-founded measures, `decreasing` | generic recursion elaboration + reusable verification/termination service | require total, executable closure; reject partial/unsafe |
| `requires`, `ensures`, `given`, proof-only `assert` | PSCV-owned syntax lowering + reusable contract/VC semantics in `verification/` | exact PSCV-VERIFY-v1 meaning; mandatory call/return/assert obligations |
| `invariant`, `reads`, `modifies`, `old`, error postconditions | PSCV-owned source forms + reusable WP/frame/VC machinery | constrain closed permitted effects and complete loop/exception VCs |
| `let mut`, assignment, `for`, `while`, `break`, `continue`, early return | frontend control flow and generic lowering + WP/verification services | owned verified-do subset, loop termination, approved operation models |
| `ghost`, erased state, noninterference | source relevance/erasure and `verification/` rules, ordinary `erasure/` backend pass | verified ghost-use restrictions, required erasure proof and executable closure |
| Pure, State, Reader, Except, and additional verified effects | versioned verified `Std.WP` laws/verified standard library | freeze effect/operation registry and require proper WP-law evidence |
| Data/structure invariants, verified collections | reusable dependent types and theorem/law libraries | coverage policy for exported values and constructors |
| Solver, SMT, AI proof suggestions, tactic search | untrusted optional tactic/prover packages using a bounded proof proposal protocol | may select approved producers; no oracle flags or independent proof authority |
| Approved specification identity and requirement tracing | separate `psspec`/VSDD tooling plus authenticated policy data | require canonical approved spec identity; never infer approval from comments/tags |
| FFI, IO, external services, async resources | explicit modeled boundary adapters and verified effect packages | closed profile rejects unsupported world effects; boundary profile reports exact assumptions |
| Proof and obligation closure, axiom/effect/import closure, checked erasure | reusable evidence analysis + **trusted supervisor** validation | define required evidence and fail-closed policy `pscv-closed-v1` / `pscv-boundary-v1` |
| `PSCV-CERT-v1`, `VerifiedExecutableModule` authority | **trusted `psc` supervisor** only | may configure required gate, never self-issue certificate or authorize emission |
| TS runtime ABI, type guards, project bundling and target compilation | existing `compiler-ir/`, `erasure/`, `backend-ts/` + host | require relevant preservation relation and disclose exact compiler assurance |
| Diagnostics, progress, watch, LSP, proof state UI | `psdev`, `pslsp`, future `psvscode` | read-only proposal/status consumers; cannot publish or mint proof authority |

The profile package is **composition/configuration and exact semantic policy**,
not a repository for all proofs, effect models, or algorithms. Avoid creating
empty `prover/`, `pstactics-standard/`, `verified-stdlib/`, `psspec/`
or SDK folders until an independently exercised implementation requires them.

A future official release may separately publish `@proofscript/pscv`,
`@proofscript/pstactics-standard`, `@proofscript/verification` etc.,
but only after confirming npm scope ownership, real independent demand,
artifact qualification, permissions, and release control. One logical module
does not automatically deserve an npm tarball. The current internal
`@proofscript/pscv` candidate is **private**, data-only and not activated.

## Decision 3 — open ecosystem, fixed authority

Ordinary `proofscript` installation keeps the compact checked compiler,
mandatory TS7 backend, selected Core, protected publication, and bounded
development/editor tools. `@proofscript/pscv` is optional and must be
explicitly activated as an **official versioned profile**, not an ordinary
`psc-command/1` guest (that demo returns only one build-request bit).
Profile selection does not grant authority to the package's `main`,
`scripts`, `bin`, `verified` flags, or a self-described certificate.

For full `pscv-v1`, the language grammar, Standard tactic/environment,
registry ordering, verifier semantics and final coverage policy are closed.
Optional outside solver/tactic packages may propose proof terms for a
supervisor-selected exact proposition, with selected package identity included
in the verification environment and every result checked through the chosen
kernel proof policy. Ordinary dependencies may not silently register source
syntax, elaborators, VC rules, axioms, simp or proof-oracle shortcuts.

An officially approved extension engine may *execute* via an explicitly
qualified adapter, but code isolation is separate from proof completeness:
a sandboxed VCG can still omit critical VCs. Until correctness of required
obligation generation/coverage is established, that implementation remains an
explicit versioned trusted assumption, not a proof of user intent.

### Narrow future interfaces, not a generic callback framework

1. `PSC-PROFILE-DESCRIPTOR/1` (planned): release-owned exact identity and
   enablement; parser/semantics/Standard registry versions, source profile,
   mandatory capabilities and supported backend relations.
2. `PSC-SOURCE-LOWERING/1` (planned): source bytes/spans/module graph and
   pinned environment → canonical Core candidates + origin mapping, subject
   to an explicit source-meaning/grammar validation rule.
3. `PSC-VERIFICATION-REQUEST/1` (planned): **host-selected** obligation
   plan derived from approved specification and source/program semantics.
4. `PSC-PROOF-PROPOSAL/1` (planned): bounded proof terms and exact goal IDs
   returned by tactics/VC-solvers; no ability to remove obligations.
5. `PSCV-CERT-v1` verifier (not yet implemented): checks coverage, exact
   kernel-admitted evidence, dependency/effect/axiom closure and erasure
   invariants against the same committed source/environment/spec/profile.
6. Protected `VerifiedExecutableModule` handoff and verified-artifact
   publication (not yet implemented): the only path for PSCV executable
   claims; no arbitrary JSON/guest-supplied construction.

The current experimental `psc-required-obligations/0` +
`psc-verification-proposal/0` preflight in `packages/verification/` is
**NOT** any of the qualified protocols above. It parses bounded proposal
identities and reports missing/duplicate/incorrect goals, but cannot certify
that its input obligation set is complete, kernel-check proof bytes, or
authorize executable emission. A matching proof hash is not proof checking.
It always reports `uncertified`. The release-owned
`scripts/pscv-certification-gate.mjs` intentionally has **no accepting
certification branch**. The existing `checked-build.mjs` independently
refuses any requested profile other than `checked`.

### Mandatory verified build transition (future)

```text
PscvApprovedSource + StandardEnvironment + ApprovedSpecification
       + CanonicalAdmittedDeclarations + RequiredObligationPlan
       + KernelCheckedProofs + Axiom/Effects/Imports/ErasureClosure
                         |
                         v
          release-owned PSCV-CERT-v1 validator
                         |
                         v
             VerifiedExecutableModule
                         |
                         v
    erasure → checked IR → qualified backend/ABI
                         |
                         v
         host-owned exact artifact publication
```

No alternative PSCV source→backend path, compiler-specific `--no-verify`
fallback, or successful `pscv-v1` artifact receipt on timeout/unknown.
For `pscv-boundary-v1`, external assumptions/models must be explicit in
the report; `pscv-closed-v1` rejects unmodeled world effects.

Do not conflate successful Lean proof checking with proof of source
interpretation, a *complete* set of obligations, approved human specs,
runtime/backend preservation or real-world FFI behavior.

## Decision 4 — reuse PSCVL without turning its prototype into authority

The repository already has `PSCVL/` with Lean 4.35.0-rc3 source
syntax/grammar, `Std.WP` effect relations, code for experimental
`requires`/`ensures`/`ghost` and preliminary policy. It uses Lean's
actual proof producing elaborators and kernel; `PSCVL/Main.lean` prints
UNCERTIFIED, generates no executable and explicitly separates the stricter
incomplete `check` from permissive `check-preview`.

As a **P0 real research slice**, CI checks that the existing
`PSCVL/examples/pass_contract.ps` is accepted under
`check-preview`, while `fail_unproved_contract.ps` is rejected and no
certificate/executable is generated. This validates reuse of actual Lean
intrinsic proof and WP machinery **within the preview-only syntax profile**.
It does **not** establish normative PSCV pure contract completeness or
approved specification identity. Some existing fixtures deliberately use
native Lean source conventions not admitted by the strict PSCV grammar.

Do not fork/refactor the PSCVL prototype into the base compiler now.
Move reusable functions into `verification/`, `prover/` and policy
modules only after an exact PSCV grammar/environment pin and a closed
pure contract proof-to-certificate slice have been qualified.

## Decision 5 — explicit release blockers and work plan

**Current disjoint version baselines:**
- PSC0 preview5 compiler/bootstrap and selected native provider use Lean4.34
  semantics from pinned source `963030dc2d154008fccc82e7c8ed29331f138799`.
- Uploaded PSCV RC-v2 and `PSCVL/` source target Lean4.35.0-rc3 commit
  `470d5ce1400764999581fd26d5d72b00d990b0f4`.
- The independently developing PSKernel Core refinement workstream targets
  Lean4.35.0-rc4; it has not been automatically selected as the PSC0 provider.
- The required exact ordered `STD-ENV-PSCV-V1-L435RC3-RC1` snapshot and
  PSCV verification-registry digest remain pending in the normative reference.

These are **separate** pins. No RC3→RC4 silent substitution and no
`pscv-compiler-v1` conformance until a normative re-pin decision,
frozen manifests, executable compatibility and certificate acceptance are
qualified. The ordinary compiler fixed-point may stay on its historical
pin if a qualified, explicitly versioned bridge can support the chosen
PSCV meaning.

| Stage | Work and exit gate |
| --- | --- |
| **P0 — this branch** | Keep existing folders; freeze owner/authority map; private data-only PSCV candidate; non-authoritative proposal preflight; explicit unavailable certificate gate; existing Lean pure-contract positive/negative tests |
| **P1** | Choose one exact semantic version; freeze manifests; define official profile admission/import/source lowering and protected goals; qualify package transport and isolation without auto-activation |
| **P2** | Implement an **actually certified** narrow pure contract: approved specification, independent coverage rule, exact admitted proof, trust/erasure closure, and internally protected verified handoff; bad or missing proof produces no artifact |
| **P3** | Complete base grammar and closed Standard prover; contracts/VCs/call sites, refined data, recursion, verified do, loops, ghost, effects, imports, verified standard libraries; independently validate full obligation coverage |
| **P4** | Make certified pure/verified-effect programs compile through the selected TS7 backend with accurate preservation/boundary claims; replay and binding to exact bytes |
| **P5** | Run complete normative positive/negative conformance matrix, RC/version manifests, clean-machine npm qualifications, replay proof/certificates, release identity and full assurance report |

**P0 must not be represented as a completed PSCV compiler.** The private
metadata and version-zero proposal diagnostics intentionally have no
verified-executable authority. Only the P2/next gates may change that
status with concrete evidence.

### Acceptance checks for P0

- All existing `packages/` paths, `lakefile.lean` source roots,
  `Ps.Bootstrap.SelfHost` closure and kernel implementation are unchanged.
- The `@proofscript/pscv` candidate has no executable entry or install hooks,
  declares `private:true`, has no verified capability, and records the
  unresolved environment digest explicitly.
- The reusable proposal parser rejects duplicate/unknown/mismatched goals,
  bad/empty authority input, forged `verified:true` flags, and never returns
  a verified/certified/accept token.
- The release-owned `pscv` gate never issues `VerifiedExecutableModule`
  and the existing production build continues to reject `pscv-v1`.
- Positive and negative Lean 4.35.0-rc3 PSCVL prototype contract preflight
  use actual Lean elaboration, without generating executable artifacts.
- Cloud CI records the exact commit, outputs, baseline pins and remaining
  obligations. No project/profile activation, release publication or branch
  merge occurs automatically.
