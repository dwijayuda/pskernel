# Normal generated-compiler performance regression

Source 56663b26b51cb65e0c34c44d2d63fdb927fd36f2, tested merge
d6d3b2e8446f72208f3c1c062721a30a3c0d23fa, Linux run 39817072167.
The complete finite matrix passes all 37 criteria, all targets, minimum Python,
packages and all three compiler closures. The G1 job 119963998304 fails its
first normal small request G1-lean-modules with ETIMEDOUT after 240261 ms.
No case completes; publication is not committed. This is a normal compiler
functionality regression, separate from deferred G2/G3 qualification.

The same case completed in 2154 ms in qualified run 39683701190, source65fa8766,
G1 job119517775702. Its source, successful evidence and G1 remain preserved.
The newer 100000-statement JS application takes about21 seconds versus1.2-1.75
seconds in that baseline. All current measured application processes still
pass their original120-second /1048576-KiB acceptance.

Current failed G1 identity:
- service f04b0af821ccdd86e657cab5ff5082161bd167463dab6f93722e3118f704f492
- closure55f7ab205419fc83d2ac152cda0e8fbcb317eb502c3dcaa629894ee9cddf4350
- modules86; candidate admission404e17098156c8c7c8119a2f4787309db40433aad77a433acf41907cb93a8bef
- original IR671be039ce45afc7884a2c7a83e4f6e02336dfd30f2ec75b9e823e3f784caebc
- specialized IR033231baaa92eb6b0e5dc1ce5270d54e90ba0c8738a6de77fc3b057d45fe7511
- artifact12442204879; ZIP digestb70099b7feb7ec0eec473aaa4eeb2e910ddca8a6bece26199d5c50d019464aea
- expiry2027-01-20T16:48:19Z

Shared JS driving now protects dynamic callbacks, but wraps even call-free
inner closures in generators. The first follow-up keeps those closures plain,
retaining lexical capture, order and existing driven calls. A new escaping
closure regression runs in both JS and independently checked TS alongside the
unchanged million-call, non-tail, foreign-trap and genuine-divergence controls.
Actual application and G1 timings must demonstrate improvement; it is not yet
a claim that this change resolves the whole regression.

If the normal G1 request still fails, a failure-only V8 sampler replays one
exact retained service/request with the same240-second limit. It verifies hashes,
calls no native compiler/checker, and never admits or publishes its response.
The original G1 gate stays failed. Raw samples and exact identities are retained
so the next correction can target measured hot functions instead of increasing
limits or weakening regression coverage. G2/G3 remain manual and deferred.
