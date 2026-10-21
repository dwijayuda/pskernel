# Native Church DefEq diagnostic — qualified observation, incomplete kernel outcome

The host diagnostic at `56acbeddfcc0cab73ba649cf0f16405918fe4edd` passed [run 39654014643](https://github.com/dwijayuda/pskernel/actions/runs/39654014643), [job 119409393373](https://github.com/dwijayuda/pskernel/actions/runs/39654014643/job/119409393373). It compiled and executed the original V1 checker from `369bee5801bd5e4476837684fad3f7e1ca8c422c`, with the authenticated 197-node Church fixture and original 4096 fuel/60-second/2-GiB cgroup policy.

The original API admitted the first 3 requests and returned `resourceExhausted / fuel`, `kernel reduction budget exhausted`, on theorem request 3. The independent observed invocation returned the exact same typed outcome, with the input session unchanged and no partial publication. Both claimed and inferred theorem types passed exact source-structure assertions. Metadata comparison was not rerun; this is not an Arena parity pass.

All 5 observer/frozen-worker equivalence lemmas compiled, with only `propext`, `Classical.choice` and `Quot.sound` printed. Fresh controls passed: 138 transport; 3 native; 3 theorem-stage plus 9 parser negatives; 4 DefEq plus 9 parser negatives.

| Observed owning fuel | Error propagation stage |
| --- | --- |
|2|cheap-left; core WHNF receives predecessor 1|
|3–4093, selected samples|full-shape on nested applications headed by opened local `s#32`|
|4094|quick-after-core on lambda `z`|
|4095|lazy-delta on `cmul` applications|
|4096|full-shape on the two `Eq` types|

There are 47 selected error frames, below the 49-frame cap. Each term preview visits at most 24 nodes. Pinned source confirms app/app comparison descends into argument tails with predecessor DefEq fuel; core WHNF at 1 must visit the application head at 0. This explains the observed original resource error. The 14,520-application Church expansion is source-derived, not an exhaustive observation of every node.

Original admission took 0.816862 seconds; the observed run, including its independent unchanged-API comparison, took 1.713622 seconds. Neither had a host timeout or OOM. Original cgroup charged peak was 15,990,784 bytes and sampled native VmHWM lower bound 71,827,456 bytes; observed values were 18,874,368 bytes and 73,363,456 bytes. These measure different scopes and are not interchangeable RSS figures.

Artifact [12371645069](https://github.com/dwijayuda/pskernel/actions/runs/39654014643/artifacts/12371645069) contains 33,723,943 bytes; ZIP SHA256 `5840727772ed8b6bcf5e79e27f60b0af846a8ab1326aa27c09ab3e64297323cd`. Original body SHA256 remains `85526c244d94e9710a6be432164c054c742d8f7c1d3ca0d8580d0874f7815a47`; only the historical metadata header was adapted. The official reference accepts this case. The resource discrepancy therefore remains a failed compatibility gate, despite successful diagnostic collection.
