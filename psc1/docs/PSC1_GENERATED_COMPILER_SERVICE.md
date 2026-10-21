# Generated JS compiler service, candidate protocol v1

Ps.BackendJs.CompilerService is the portable composition root over the production
parser/preparation/ordinary pairing, original strict IR, closed specialization,
target ABI validation, JsIR lowering/validation and stack-safe printer. It also
retains canonical original/specialized IR and actual source/member origins.
Its ONLY public scalar entry is psCompilerJsServiceCandidate: String -> String.
Implementation helpers/types use Ps.Internal.JsCompilerService ownership.

Wire request is an exact7-element JSON array:
["psc1-compiler-service/1", requestId, sourceClosureDigest, "lean"|"ps",
 "checked"|"ordinary-checked", entryModule, [[moduleName, exactSourceText], ...]].
The host computes/binds the digest; an echo is not authority. Module identities
are captured by the host. The compiler checks duplicate/missing/out-of-order
imports, entry presence and exact reverse-topological closure membership, so
extra/unreachable source modules refuse. There is no native frontend fallback.

The response is provisional DATA: candidateOnly=true and admission="not-run".
A successful candidate contains a portable admission REQUEST for the exact
retained logical graph, source/member origins, complete original/transformed IR,
public values, runtime requirements and generated source. Ordinary preparation/
erasure consumes the same immutable production work value and repeats pairing
validation. Computing pure candidate IR/text before the external checker never
authorizes publication. It changes no active checker or assurance definition.

The external host must pin service executable/channel identity, captured input,
options, target, whole candidate bytes and every artifact. It must invoke the
official independent checker on the retained exact logical admissions, validate
target/ABI and admit/publish through its own state, never through wire receipts.
A matching hash or service response is not a preservation certificate.

The NEW Linux workflow is initially a diagnostic, not a production publisher.
It checks the complete exact compiler composition first, calls the native seed
ONCE on the actual captured compiler source, independently admits that candidate,
checks G1 syntax, then disables all native frontend/seed/probe/test executables.
Only the separate kernel checker remains. It executes actual G1 compiler semantics
through a hash-checked scalar transport runner and checks/executes real compiled
corpus artifacts. Roles/argv/results, identities, graph hashes, elapsed time and
generated-process maximum RSS are retained. No larger process/stack limits or
runtime fuel are introduced. The128MiB staged candidate-file bound is separate
from the unchanged32MiB subprocess output buffer and240s process budget.

The diagnostic writes CI staging artifacts only; it does not implement the full
production session publisher or prove behavioral preservation. JS repeated
generations and Rust generations remain separate gates. G1/G2/G3 cannot be
claimed from native facade tests or from an unused generated module.

## Host session and CI publication candidate

host-tools/generated-compiler-session.mjs owns each generated JS invocation.
It snapshots exact sources, entry/grammar/assurance/request and pinned service,
runner, Node and checker identities. It reads the whole bounded response from its
own process, validates correlation/origins/counts, independently admits the exact
retained logical graph, checks target syntax and actual export inventory in
separate fixed Node processes, and binds every staged artifact. Generated wire
fields cannot select paths/tools or request publication; extra fields refuse.

Only the private one-use host state can publish. Publication rechecks identities,
the closed file inventory, every artifact byte and the captured previous current
pointer under an exclusive lock. It fsyncs and seals a content-addressed generation,
then changes one current symlink by atomic rename. Previous generations remain.
Negative boundary tests cover stale correlation, injected authority/tool fields,
invalid actual checker input, target syntax/API mismatch, changed tools/artifacts,
missing/extra/symlinked files, failed commit phases and stale concurrent sessions.
Failure after the commit point is recorded as published; durability errors do not
pretend that the old pointer is still current.

The new boundary CI job replays actual NATIVE-prepared fixture data through a
tiny fixture scalar function. It exercises real checker/session/publication state;
it is explicitly not G1 semantics. The generated diagnostic uses the same host
session for actual G1 corpus publication into a CI-only store once bootstrap works.
This host addition is pending Linux tests. G1 still has not been produced: the
actual adcb seed hit240s. No registry/release/main publication is involved.
