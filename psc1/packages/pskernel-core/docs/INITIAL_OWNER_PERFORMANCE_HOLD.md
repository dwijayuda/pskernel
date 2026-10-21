# Initial-session owner performance hold

Exact candidate: `7e36b3b1d4d563798b9f86e2840f2414899421fe`. Baseline: `deb18b9c87a5d21a406c6e5b852afb4d44785fe5`. Decision: **HOLD; do not integrate the eager importer.**

[Paired run39662962284/job119440477019](https://github.com/dwijayuda/pskernel/actions/runs/39662962284/job/119440477019) completed successfully as a measurement collection:32 fresh ABBA workers,384 exact full public calls, no missing/failed workers. Producer artifacts and all eight deployment files were authenticated before execution. Kernel fuel4096,60seconds per worker,2048MiB V8 old-space; no hard RSS limit is claimed.

Each row has two independent processes per revision, with one reported cold call, two warmups and nine measured warm calls per process. Cold means the first second-batch call after checked-session setup and a V1 outcome control, not the first kernel operation. Results are descriptive; this small benchmark is not a whole-kernel performance claim.

| Prior owners | Query | Baseline warm mean ms | Candidate warm mean ms | Candidate/baseline | Peak RSS baseline KiB | Peak RSS candidate KiB |
|---:|---|---:|---:|---:|---:|---:|
| 32 | trivial-sort | 1.204813 | 22.265948 | 18.4808 | 126008 | 183172 |
| 32 | owned-constant | 3.225236 | 23.276576 | 7.2170 | 127388 | 188872 |
| 32 | unknown-constant | 2.834184 | 23.578526 | 8.3193 | 125952 | 185816 |
| 32 | ill-typed-definition | 3.848173 | 26.018733 | 6.7613 | 126872 | 189764 |
| 128 | trivial-sort | 1.271395 | 77.633987 | 61.0621 | 172148 | 238296 |
| 128 | owned-constant | 2.423566 | 87.061367 | 35.9228 | 175224 | 250976 |
| 128 | unknown-constant | 2.936915 | 81.282230 | 27.6761 | 172996 | 241308 |
| 128 | ill-typed-definition | 3.248082 | 82.198527 | 25.3068 | 173472 | 244536 |

The candidate eagerly imports every live initial declaration type, transparent definition body and recursor rule into each fresh nonempty batch. Even a trivial sort query pays that cost. The paired experiment includes import, input validation/decoding, checking/admission and reply construction. Module loading, first checked-session construction and input construction are reported separately. Every timed result was validated after stopping the timer against the genuine V1 public operation and its exact positive or negative expectation.

The regression is severe at modest environment sizes: with128 owners, trivial checking rises from1.271395ms to77.633987ms, while checking an owned constant rises from2.423566ms to87.061367ms. Peak RSS rises by66,148 and75,752KiB respectively. At32 owners all four queries are also slower. Correct results alone do not justify promoting this implementation. The next change must avoid whole-environment import for unrelated queries, retain exact live-index authority, original/private ID separation and original failure order, and repeat these same complete calls.

All primary semantic gates at exact7e are separately green: integration39657469165, correctness39657469304 and all6 research39657469181 jobs. Both generated routes passed1515 owner assertions,24 provider CLI cases and8 provider API cases. Full Arena39657469152 remains FAIL:173 classified matches (105 accepted,60 kernel rejections,1 metadata rejection,7 transport rejections),2 safety-contract differences,17 host timeouts and1 fixed-fuel exhaustion. This hold does not erase those exact-source correctness receipts.

Driver provenance is explicit: the measured driver is from harness `f84f344d3d622777f84d2f331a53f3cd2520a50e`, SHA256 `7c8a82758b90958d973623d26e4c4dfbd900126cd737c190adffb76cb1563221`. Both kernel bundles remain the unmodified authenticated deb/7e artifacts. The earlier harness444 failed its strict Boolean CLI presence guard before any worker; it produced no performance observation.

Immutable measurement artifact12377000275:8,523,569 bytes, ZIP SHA256 `73c1304bb9d06aed779455c24332e2a25ddbee0a9e3b0dd750e1cb8410d35456`. Original full report SHA256 `26b66626b87d71fe3e1a990bac6bc48f608c3c3952190cff917581beae8bc393`. The adjacent normalized JSON preserves all values from the authenticated console records; its formatting is not represented as the original report bytes.
