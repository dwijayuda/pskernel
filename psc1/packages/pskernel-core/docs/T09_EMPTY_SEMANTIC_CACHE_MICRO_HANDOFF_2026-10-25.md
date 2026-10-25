## 2026-10-25 — independent333-member partial archive audit completed

Run40162335707/a1, source0e8a231f7eefbc085659142da84738f32fc866e7, job121076318277 passed. Actual ordinal32 process-status.json confirms a60-second baseline indexed/hit host timeout, with no stdout/stderr and no candidate attempt. The audit verifies32completed observations,33statuses, every actual333ZIP member and nested producer/compiler/native archives. Its report is125254bytes, SHA256df82a862e616563374186090800a87d9d882119c8899dc91285a3cf4ce6acfcd. This remains an incomplete32/56measurement protocol; no measurements were rerun and no optimization/performance qualification was established. See the updated source-bound evidence JSON and the current full499/ABBA handoff. The following text records the earlier pre-audit checkpoint.

# Current execution result: INCOMPLETE

[Run40161243172](https://github.com/dwijayuda/pskernel/actions/runs/40161243172), job121073067656, passed the independent136-member producer audit and then completed observations0-31. Observation32, indexed/hit baseline, ended as an incomplete bounded process. Its command-status file must distinguish timeout from a nonzero exit; do not infer that distinction from the generic exception. No complete56 aggregate was produced.

Partial artifact12585854601 contains333 uploaded files,10629811ZIPbytes, SHA256835a058052da746ee78aa9395514748373c29f1596bde9f3af4e8f0a1b672861. The planned separate read-only archive audit must verify those actual files, the32 completed observation chains, ordinal32 failure status, source pins and incomplete.json. Do not rerun measurements, change frozen counts, or raise limits.

Eight rows have two completed observations per variant. These partial medians are descriptive, with no confidence or overall optimization claim:

| Case | Baseline seconds | Candidate seconds | B/A |
|---|---:|---:|---:|
| empty/shallow | 3.170545 | 1.575282 | 0.496849 |
| empty/deep | 5.244501 | 0.016246 | 0.003098 |
| empty/early-open | 3.109643 | 1.626900 | 0.523179 |
| empty/late-open | 5.047983 | 0.016549 | 0.003278 |
| small/hit | 14.381678 | 15.053984 | 1.046747 |
| small/deep-miss | 19.495963 | 19.393940 | 0.994767 |
| small/early-open | 2.864284 | 3.623181 | 1.264952 |
| small/late-open | 4.600774 | 4.683979 | 1.018085 |

All32 completed observations have zero invalid results, exact consumed checksums, unchanged inputs and successful semantic controls. The small early-open row shows a26.5% increase, with both candidate timings above both baselines; this is a regression signal, not a whole-kernel attribution. Indexed rows remain unmeasured. Keep the candidate outside integration. The499-report complete gate is preparatory only, and the original full-kernel four-case regression is still required before adoption.

The original implementation handoff follows, with its execution-status sentence amended. Its predicted451-file inventory applies only to a complete run; this actual incomplete run has333 files.

# T09 empty semantic cache: isolated bounded microbenchmark

## State and scope

Original experiment implementation d3c50dcb182960d8a78b3da53a7d04fde0ec809d descends from documentation checkpoint f22236e315763ee2d1816375966788798bd4281b. This handoff records that source separately from the containing documentation commit. Integration remains the fully qualified T05 source 20224a295359abb201f56c72395690bf0bfac9fa. The original implementation checkpoint has now run as exact experiment d3c50dcb182960d8a78b3da53a7d04fde0ec809d. Run40161243172/a1 is incomplete after32 valid observations; no optimization is adopted.

The frozen protocol is `T09_EMPTY_SEMANTIC_CACHE_MICROBENCH_PROTOCOL.md`, 8606 bytes, Git blob `285fcb439f3567f9697c3d0046e129c140b0cee5`, SHA256 `3982b235c6c45c783ea5a1fa2eeedeea0f72bf07f1ea48e3bdf6651dd0b6be2e`. Its implementation is:

| Path | Bytes | SHA256 |
|---|---:|---|
| `.github/workflows/psc1-empty-semantic-cache-micro.yml` | 3533 | `2f18a9fe32420815b3cfe4a028ffc874a649702a787a377b6a779fd2dfd651ca` |
| `.github/psc1-empty-semantic-cache/micro.py` | 42339 | `083bfb78be64c4b2742c5c1447446eda78f675b757e9c880f4bb8489496a306e` |
| `psc1/scripts/pskernel-empty-semantic-cache-micro.mjs` | 14328 | `1e13989ff42143b9b5d6bf8686d4e1405d64e5f1f626161afe0ac00a30551ffa` |

Use the single push-triggered run on `work/psc1-pskernel-empty-semantic-cache-micro-20261025`. Check for an existing matching-source run before any dispatch. All execution belongs on GitHub Actions Linux; do not build locally.

## Fixed artifact and source identities

The experiment consumes paired leaf run [40158333460](https://github.com/dwijayuda/pskernel/actions/runs/40158333460), attempt 1, job 121064387870, producer source 80182d1b95894fc3daa5c7fbcfe8b1a7adb687d9. Artifact 12585423993 contains 136 files, 5226483 ZIP bytes, SHA256 adf655c16ab115565e3bbeb8204cc2d1d25c8fa98b495d0bd8849926986e4d63. Baseline kernel source is 20224a295359abb201f56c72395690bf0bfac9fa; candidate source is e503972553ae2d41d5ba7a26d7739fb32ee86b96. Shared compiler source is 80005bb250a7324772db76d51684d23fbf0fe6ed; only its already authenticated compiler binary was used by the producer. Its held kernel transform changes are not imported.

Before timing, the auditor independently reads every raw producer ZIP member with Python's standard zipfile CRC checks and compares it with official extraction. It also checks the nested 13-file compiler and 18-file native archives, all 69 native reports, exact Git source closures, nine original commands per variant, bootstrap adapter substitutions and complete receipt chains. It does not implement a custom ZIP parser or execute the archived compiler.

## Frozen execution

The job reruns the archived 1884 retained and 21 empty-cache controls for each variant. It then executes exactly 14 fixed cases in A-B-B-A order: 56 fresh processes, sequential on one runner. Actual generated empty, small and indexed maps and shallow/deep/early-open/late-open queries are constructed outside timing. The measured loop calls the actual helper and consumes both the actual Option constructor tag and expected Some payload identity. Independent snapshots include own string/Symbol fields and alias relationships.

Node 22.23.3 and its exact binary digest must match the producer tools receipt. Preserve empty PATH and NODE_OPTIONS, --expose-gc, --max-old-space-size=2048, exactly two explicit collections outside timing, fixed 4096 warm-up calls, fixed measured counts, 60-second process timeout and 25-minute job limit. No rescaling, retry, outlier removal, pooled unlike cases or timed assertions are allowed. maxRSS is explicitly whole-process memory, including import and setup.

Every launched process retains config, stdout, stderr and status before validation. A failed, missing or timed-out observation writes an incomplete result and cannot produce the complete aggregate. A successful output is expected to have 451 files, but this count is a prediction until actual inventory and upload are checked.

## Continuation and decision gate

Review the exact run/source/attempt, all 56 ordered observations, per-process controls, report/file digest chains and actual artifact metadata. If the first run fails, repair the demonstrated harness defect without weakening source, semantic, inventory or resource checks. Do not claim a timing result from a partial run.

Even a successful helper experiment does not qualify adoption or whole-kernel performance. Adoption still requires the original four-case full-kernel comparison with exact candidate artifacts and unchanged resource/fuel policy, fresh complete correctness qualification and independent artifact verification. Church acceptance and Init.Prelude timeout remain unresolved. A remains historically scoped T01F qualified; B OPEN, C FAIL, D OPEN. Metadata/decoder/replay-to-ArenaModel correspondence remains open. Preserve all historical sources and evidence; do not force-push, touch main or publish packages.
