# PSC1 active development checkpoint

Updated 2026-10-21. GitHub APIs and Linux Actions only.
Draft PR172: https://github.com/dwijayuda/pskernel/pull/172
Branch: fix/psc1-closure-normalization-20261021
Base #171 remains1fad9ed53cda9b23ac30be9cea85e7857437564e.
Preserve history with fresh HEAD reads,expected-HEAD updates and force=false.
No merge,registry publication or branch-protection change is authorized here.

## Active unqualified typed IO continuation

Source sequencing now uses the checked Io alias of CompilerM with an explicit
String dispatcher, authored in both grammars. Commit d16e1d1bc3dd17ba09d428bd4844dbc0c46e990c
passed native, compiler closure and G1 jobs, but run39608411456 failed focused
erasure before emission. Preserve that failure: parameterized type-valued aliases
were incorrectly treated as runtime declarations. The next patch classifies the
whole checked type telescope before erasure; no kernel or IR check is bypassed.

The opt-in --abi io-dispatcher profile accepts only a String-to-String callback
input with scalar remaining inputs/results on JS/TS/Rust/Python/PHP. Default
public ABI restrictions remain. Wasm refuses explicitly until marshaling exists.
A real source application exercises bind, loops, mutation, typed recovery and
host trap separation. New execution evidence is pending Linux Actions; do not
promote this work to qualified from source inspection. Standalone Python adapter and twenty shared actual Linux policy checks are now
implemented, pending Actions validation. Rust/PHP standalone adapters and Wasm
String ABI remain the next implementation tasks. Run39610746683 exposed a
bootstrap census refusal of early-return do syntax in BackendCommon.Plan; the
same ABI policy is now expressed with structural workers, preserving its checks.

## Latest qualified implementation

Implementationf7993e3d51917e2ec18f3c758a61468f06caaeb2 qualifies at tested merge
09dd56600d4ba550f25d105d49659c824da2d5d8, Linux run39603714675 SUCCESS:
https://github.com/dwijayuda/pskernel/actions/runs/39603714675
Static,native,focused,three compiler closures,G1,host boundary,full scoped and
aggregate gates pass. The historical benchmark is skipped by dependency selection.
Receipt:docs/PSC1_INFERENCE_IO_QUALIFICATION_2026-10-21.json contains exact jobs,
source/artifact identities,tool versions,application observations and exclusions.

Both grammars/all7 targets:70 bounded inference/control +56 typed IO protocol
obligations,each observing both Bool inputs. Minimum Python adds10+8.
The real JSON-file/console application passes10 grammar/target bundles across
JS,TS,Rust,Python,PHP,plus2 on minimum Python. Twenty actual Linux capability
policy checks pass. Existing126 CompilerM +42 collection +98 JSON obligations,
minimum-runtime,runtime,typed-error,while/deadline,negative/publication and
installed-package suites remain green. Thirty-eight native contextual checks
include speculative meta rollback before a different successful constraint.

Readiness:12 finite criteria qualified,25 blocked; no complete family/application;
releaseReady=false. The pure protocol matrix does not qualify seven IO adapters.
This documentation-only descendant preserves that implementation. Its static
gate is separate from the exact full source qualification above; do not claim a
fresh full compiler qualification for a metadata-only commit.

## Current language and IO implementation

Bare lambda domains come only from the expected function telescope. Both parsers
retain typed/grouped binders and reject ambiguous/unresolved lambdas. Domains and
dependent codomains are checked sequentially with fresh binding identities.
ProofScript declaration parsing retains explicit groups around intervening
implicit binders. Failed expected-result previews restore the original meta state.
Runtime cases cover numeric/tuple/empty-array/lambda contexts,dependent calls,
nested do/loop return ownership,collection/range traversal and handler/capture
rollback. Broader unbound finite family criteria remain open.

ProofScript.System.IO defines checked requests,responses,typed errors and codecs
in independently authored IO.lean and IO.ps. The PS tests use a local PS import
root,preventing authoritative-Lean fallback from replacing the authored library.
Source programs remain pure request/response computations; this slice does not
provide a general source IO do monad or a foreign logical axiom.

host-tools/typed-io.mjs provides the explicit Linux Node capability host.
Required capabilities and unsupported configuration refuse before guest loading.
File operations use held no-follow directory descriptors,regular-file checks,
bounded fatal UTF-8 decoding and atomic replacement; console IO defines CRLF,
empty lines,unterminated lines and EOF. Permissions,symlinks,traversal,FIFO,
encoding/size refusal and previous-file preservation are tested. Compiler/checker/
application failures remain outside the source IO error channel.
Rust/Python/PHP guests execute in separate processes through the common Node host;
their standalone host adapters are not qualified. The adapter is a capability
boundary for generated checked programs,not a sandbox for arbitrary JS packages.
Full policy and API details:docs/PSC1_TYPED_IO_V1.md.

The independent native IO references import only pinned Lean and use its JSON
API. Do not concatenate PSC1's Nat-offset JSON source into native Lean: the
native String API uses String.Pos.Raw and native Ordering already exists.
The existing strict malformed-surrogate policy remains PSC1-specific.

## Authoritative scope and next work

docs/PSC1_PRACTICAL_CORE_V1_CONTRACT.json remains the fixed release contract:
fourteen families,37 finite criteria,four applications,both grammars,seven targets.
docs/PSC1_DEVELOPMENT_ROADMAP.md is the single active roadmap. Its contract-owned
workQueue now prioritizes inference/control,then typed IO,then checked ordering
and application/performance completion. Preserve working functionality.

Continue typed IO and remaining finite acceptance work:
- Complete the typed IO execution interface and standalone target adapters.
- Resolve Wasm public String ABI before claiming real core/component IO. Current
  internal strings are GC structures/byte arrays,not linear-memory pointers;
  public admission/component policy currently intersects at Bool. Preserve
  unsupported-ABI refusals until explicit marshaling and consumers qualify.
- Add general source sequencing only through checked semantics; do not smuggle
  effects into logical evaluation or turn host failures into source errors.
- Finish unbound inference/control criteria,constructive Nat/Int order and actual
  CLI/JSON-file/library/compiler-like application requirements,including measured
  large inputs under existing resource limits.
Do not reinterpret the current five-guest/common-host execution as seven standalone
adapters,complete application qualification or production release readiness.

## G1 and preserved historical evidence

Current G1 service18518dab471043762d4d01f28c97f99bb8b34f54810c27b4cfb93380404a0534
passes the ten-case v2 corpus,84 source modules,one native seed and no later native
frontend/emitter delegation. Artifact12347821634 is retained to2027-01-19.
The receipt records source closure,admission and original/specialized IR digests.
Earlier qualified G1 service9fee036b0ee9e2bdd9617bf2df0811409a4893ad8c7f59ab2ab478c0ea1be757
and artifact12333713515 remain preserved with their original successful evidence.

G2/G3/fixed-point qualification and expensive profiles stay manual until stable
feature freeze. Keep the original V8 heap-exhaustion and post-fusion timeout
defect/replay evidence; do not repoint old CPU replay to the new G1 artifact.
PSKernel-Core Expression V2 research progresses independently. Compiler admission
remains official Lean4.35.0 at eb6cafb7290e8bd5f2937522d8d804f58f02bafc.

Historical receipts remain exact facts in docs and Git history:
PSC1_JSON_APPLICATION_QUALIFICATION_2026-10-21.json,
PSC1_DEVELOPMENT_OPTIMIZATION_QUALIFICATION_2026-10-21.json,
PSC1_CI_ROUTING_QUALIFICATION_2026-10-21.json,
PSC1_G2_PERFORMANCE_DEFECT_2026-10-21.md and prior G1/source-closure receipts.

## CI and implementation rules

psc1-development.yml selects static,focused,integration and full tiers from the
last successful same-PR ancestor gate with immutable dispatch-base identity.
Failed/cancelled test debt remains; unknown policy/target/build changes select
full qualification. Static policy tests fail before expensive compiler builds.
Focused receipts may report tested subsets; full IO qualification requires the
five-guest matrix and minimum Python. Missing/stale/duplicate evidence refuses.
Admission,IR,execution and publication receipts are regenerated,never cached.
Only pinned tools and exact-source Lake objects are cached.

Manual psc1-practical-release reruns native/closures/G1/full qualification and
enforces --require-ready; it must refuse the incomplete release contract.
Keep strict original/transformed IR,ordinary pairing,negative tests,resource
policies and independent kernel admission. Preserve source normalization:
use supported constructor patterns,explicit psListLength and guarded structural
workers; avoid reintroducing unsupported nested patterns in compiler source.
Keep AI_WORK_STATE.md current and concise; historical narratives stay in Git.
