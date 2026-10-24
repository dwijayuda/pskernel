# Static review of a T05 ordinary-header route artifact

`review-header-route-artifact.py` verifies one completed route at one explicit source,
run, attempt, job, and artifact. It reads source text, API JSON, terminal logs,
ZIP/tar bytes, and generated output bytes. It does not run Lean, PSC1, JavaScript,
the generated kernel, or any project test.

## Command

Run from the shared workspace root. Supply the freshly downloaded files for the
selected route; the script does not fetch anything or start any Actions run.

~~~bash
python3 t05-evidence/review-header-route-artifact.py \
  --zip t05-evidence/f5d9-generated.zip \
  --artifact-json t05-evidence/f5d9-terminal-artifacts.json \
  --artifact-id ACTUAL_GENERATED_ARTIFACT_ID \
  --run-json t05-evidence/f5d9-terminal-run.json \
  --jobs-json t05-evidence/f5d9-terminal-jobs.json \
  --job-id 120858822962 \
  --job-log t05-evidence/f5d9-generated-job.log \
  --git-blobs-json t05-evidence/f5d9-git-blobs.json \
  --source-sha f5d97bafbd48adde29101ed44f45288ae53b9c87 \
  --run-id 40089243726 \
  --attempt 1 \
  --route generated \
  --expected-source-count 146 \
  --output t05-evidence/2026-10-24-t05-f5d9-generated-artifact-review.json
~~~

For the canonical route, substitute its actual ZIP, artifact ID, terminal log, and
output path, use `--job-id 120858823020`, and use `--route canonical`.
`ACTUAL_GENERATED_ARTIFACT_ID` is deliberately not a fabricated ID; replace it with
the integer from the current artifact API result. File paths in the command are
the agreed destinations, not assertions that those files already exist.

## Input contract

- `--zip`: the original downloaded artifact ZIP, without repacking.
- `--artifact-json`: the raw GitHub artifact API object or an object containing
  `artifacts`. It must contain exactly one matching artifact ID, the API ZIP
  SHA256 and size, the exact workflow run/head identity, and the attempt-bound
  route name.
- `--run-json`: the raw GitHub workflow run object. Its repository, head SHA, run
  ID and current attempt must match the explicit expected arguments.
- `--jobs-json`: the raw GitHub jobs API object, including the selected route and
  `native-header`. The route must be completed/success; the exact-source native
  dependency must have completed successfully before the route started.
- `--job-log`: the decoded complete terminal log from the selected job. The
  script removes Actions timestamps and ANSI color sequences for comparisons.
- `--git-blobs-json`: the independently authenticated repository tree map:
  `{"sourceSha":"…","treeSha":"…","gitBlobs":{"repo/path":"git-blob-sha",…}}`.
  This must include every one of the 32 copied inputs and all 146 production
  source modules. The script hashes this input and records it in its output;
  authenticating the API/tree-map acquisition remains the caller's responsibility.
- `--source-sha`, `--run-id`, `--attempt`, `--route`, `--job-id`,
  `--artifact-id`: the independently selected expected identity, never inferred
  from a claimed PASS receipt.
- `--expected-source-count`: currently 146. This verifier deliberately rejects a
  different source count; the separate future constructor slice needs its own
  reviewed contract.
- `--output`: a fresh path for the comprehensive successful review JSON. The
  process exits nonzero on missing, inconsistent, or failed evidence. A prior
  output file is not evidence of success for a failing invocation; use the current
  exit status and a fresh output path.

## Verified contract

The verifier reads and hashes every ZIP file, rejects duplicate/unsafe paths and
nonregular members, and compares the original ZIP size/digest with GitHub's API.
The exact complete archive inventory is 223 files for `generated` and 226 files
for `canonical`. It authenticates the ordered 32 copied inputs against the
independent Git blob map, including the hidden workflow file and the four frozen
V1 references.

It independently follows all portable imports from `SelfHost.lean`, requires
exactly the 146 archived modules, matches every source byte to its copied tar
member and exact Git blob, and requires the six new header modules. For the
canonical route it additionally requires the exact corresponding `.ps` paths,
compares the tar and uploaded bootstrap manifest byte for byte, rederives the
bootstrap closure SHA256 over all 146 `.ps` members, and binds both source-check
markers and the ordered canonical recheck/build step.

Both bounded and complete generated `.js`, `.ts`, `.d.ts`, and `.js.map` files
must be present and nonempty. Source-map filenames and source bindings are
checked. The detached kernel and eight detached scripts must equal the actual
production kernel and authenticated source scripts. The strict retained
closed-cache/string-hash generated-body properties are independently rechecked
in both kernels; bounded emitted body strings must equal actual generated text.
No generated body is evaluated.

The verifier requires exact typed JSON for both 1,884-assertion cache matrices,
both scalar matrices, both short-entry matrices, and the 1,992-assertion header
matrix, including every section total. It checks all retained DAG, delayed
equality, staged ABI, transformation, prefix, owner, positive/negative, complete
checker, generated smoke, and invalid recursor markers in their archived logs
and actual terminal output.

The original producer identity must match all actual copied/executed hashes.
The original runtime receipt must embed that same identity and exact matrix,
all root-level log digests, and the actual successful time measurement. Header,
DAG, and prefix timing measurements must exit zero. The header and the whole
runtime step must remain below 1,500 seconds; the producing job retains its
75-minute workflow limit. Lean 4.35.0/its exact commit, Node 22, TypeScript 7.0.2,
fuel 4096, 2,048 MiB V8 old-space, empty PATH, and the explicit absence of a hard
RSS-limit claim remain required.

The successful report is route-scoped. It records the observed overall run
status but does not infer success for the other route, full ordinary inductive
admission, a replay-to-ArenaModel bridge, or performance qualification. It also
records that the separately verified native proof artifact was not reaudited by
this route script.

## Preparation status

The file has been checked as Python syntax using `ast.parse`. It is prepared for
the first terminal authentic route artifact at source
`f5d97bafbd48adde29101ed44f45288ae53b9c87`; preparation alone is not a completed
artifact review or a runtime test result.
