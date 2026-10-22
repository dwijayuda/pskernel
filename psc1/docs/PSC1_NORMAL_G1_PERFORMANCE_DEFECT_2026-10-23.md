# Normal generated-compiler performance regression


Resolved at source 9ee6c5ffe8ac344b349fde7eee8f5ef867bd5dde in Linux run
39829564386 (tested merge 00decc7fb81fc4023f68cdcdbf8cff1fdd028b12).
The first normal G1 case completes in 2254 ms and all ten cases pass, compared
with the prior unchanged 240-second timeout. All required gates and all 37
finite Practical Core criteria pass. The seven printer visitors now create
recursive helpers after binding traversal inputs. Fuel, heap/stack/deadline
policies, driver behavior, strict IR and existing regression tests stay intact.
Exact resolution evidence is PSC1_PRACTICAL_CORE_V1_QUALIFICATION_2026-10-23.json.
The original G2 performance defect and manual qualification remain separate.

The failed observations below are preserved as history.

Source 56663b26b51cb65e0c34c44d2d63fdb927fd36f2, tested merge
d6d3b2e8446f72208f3c1c062721a30a3c0d23fa, Linux run 39817072167.
The complete finite matrix passes all 37 criteria, all targets, minimum Python,
packages and all three compiler closures. The G1 job 119963998304 fails its
first normal small request G1-lean-modules with ETIMEDOUT after 240261 ms.
No case completes; publication is not committed. This is a normal compiler
functionality regression, separate from deferred G2/G3 qualification.

The same case completed in 2154 ms in qualified run 39683701190, source 65fa8766,
G1 job 119517775702. Its source, successful evidence and G1 remain preserved.
The newer 100000-statement JS application takes about 21 seconds versus 1.2-1.75
seconds in that baseline. All current measured application processes still
pass their original 120-second /1048576-KiB acceptance.

Current failed G1 identity:
- service f04b0af821ccdd86e657cab5ff5082161bd167463dab6f93722e3118f704f492
- closure 55f7ab205419fc83d2ac152cda0e8fbcb317eb502c3dcaa629894ee9cddf4350
- modules 86; candidate admission 404e17098156c8c7c8119a2f4787309db40433aad77a433acf41907cb93a8bef
- original IR 671be039ce45afc7884a2c7a83e4f6e02336dfd30f2ec75b9e823e3f784caebc
- specialized IR 033231baaa92eb6b0e5dc1ce5270d54e90ba0c8738a6de77fc3b057d45fe7511
- artifact 12442204879; ZIP digestb70099b7feb7ec0eec473aaa4eeb2e910ddca8a6bece26199d5c50d019464aea
- expiry 2027-01-20T16:48:19Z

Shared JS driving now protects dynamic callbacks, but wraps even call-free
inner closures in generators. The first follow-up keeps those closures plain,
retaining lexical capture, order and existing driven calls. A new escaping
closure regression runs in both JS and independently checked TS alongside the
unchanged million-call, non-tail, foreign-trap and genuine-divergence controls.
Actual application and G1 timings must demonstrate improvement; it is not yet
a claim that this change resolves the whole regression.

If the normal G1 request still fails, a failure-only V8 sampler replays one
exact retained service/request with the same 240-second limit. It verifies hashes,
calls no native compiler/checker, and never admits or publishes its response.
The original G1 gate stays failed. Raw samples and exact identities are retained
so the next correction can target measured hot functions instead of increasing
limits or weakening regression coverage. G2/G3 remain manual and deferred.


## CPU diagnosis at bb59d544

Run 39823355653, tested merge bb9e63d2ef07d0f9c42ce4acedc497e308d4da52,
G1 job 119985758321: the first normal case again times out. The failure-only
sample replays exact service e6c82386a7970ccf987caae3515367009ad8db2fb026a52605dd05cdcdbac633
and request c0a0920a43fb71cdf2f006813d3ebc0c50d091d156f62424446e3c328cb65ff3
at the same 240-second limit. No candidate is admitted or published.

Of 220620 ticks, WeakCollectionSet accounts for 38.9% total / 83.9% non-library;
WeakMapLookupHashIndex accounts for 4.0% / 8.6%. The source printer worker and
its anonymous helper closures dominate the named JS frames. Its three recursive
partial worker calls occur before the expression binder, producing eager
branching setup at each fuel level. The earlier call-free-lambda correction
did not reach this setup phase and did not materially improve application time.

Move those aliases beneath the expression binder and normalize the matching
single-helper setup in the other six JS printer visitors. This addresses the
same source representation class without redesigning the runtime or allowing
unknown strict calls in worker fusion. Existing G1, all source closures, the
million-call/strictness controls and the complete finite matrix must validate it.
