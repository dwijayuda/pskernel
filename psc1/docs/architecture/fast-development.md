# Fast installed .ps development

This work concerns the latency of checking and compiling user programs.
It reuses the qualified modular compiler; it does not request new self-host chains.

1. Measure cold check/build and phase/resource costs on the same installed tarball.
2. Reuse the generated compiler's capture, preparation, closure and strict IR
   functions for language-only checks. An explicitly selected target/ABI retains
   full target compilation/consumer checks. A check-only result cannot publish.
3. Keep complete internal admission/source/tool identities; make exported success
   dumps optional. Minimal evidence never skips validation, admission or tool hashes.
4. Deduplicate resource aliases within each capture/pass. Retain fresh before/after
   comparisons, source identity and tamper-before-import refusal.
5. Run one private sequential Linux/Node watch worker, supervised at240s/request,
   4096MiB V8 heap/8MiB stack and64 attempts/lifetime. It has no network endpoint.
   Other hosts/runtimes keep the established one-shot watch path.
6. Reuse exact generated preparation checkpoints only within that worker. Compare
   source text, logical module order, grammar and entry; assurance changes rebuild
   preparation output. A changed module invalidates its suffix; failure clears reuse.
   Fresh independent kernel checking still runs; no disk acceptance cache exists.
7. Keep the original generated candidate service for builds. Warm loading removes
   process/module startup there; build preparation itself still follows that service.
8. Measure subsequent bottlenecks before adding finer caches or a persistent kernel.
   Preserve the official C++ linear-memory kernel. Native executors, SDK sidecar
   elimination and wider platform qualification are separate work, not prerequisites.

Baseline: [40835944173](https://github.com/dwijayuda/pskernel/actions/runs/40835944173).
The tiny .ps check is3.7–3.9s, JS build4.8–4.9s, TS build5.3–5.5s.
Instrumented host reads3.25GB for an81-byte JS output. These measurements prioritize
resource/startup overhead; they do not establish a universal speedup.

Only the focused installed regression and exact source-adoption checks are added.
Existing regressions remain intact. No registry publication or merge is authorized.
