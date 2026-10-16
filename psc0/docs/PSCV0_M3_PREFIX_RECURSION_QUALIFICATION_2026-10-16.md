# PSCV0 M3+B — prefix recursion and evolving-state qualification
16 October 2026. **Selected slice accepted; entire M3+B remains OPEN.**

## Exact implementation/test identity

- Compiler/test SHA: `8f8aa47fc3b742488bd1ce4ad15024a63c0b6d4f`. Final acceptance documentation is a distinct child; do not conflate its CI with this exact compiler.
- Full native [38928344482](https://github.com/dwijayuda/pskernel/actions/runs/38928344482): **SUCCESS**, native job `117065962490` **33/33 reported steps successful**, including setup/cleanup; none skipped. Native artifact `12059090546`; SHA-256 `5e38817f47eef5434332b2c40ed3bde8fb5d41a1d7a65fd5e05d3f1531304229`.
- F1 canonical model [38928344465](https://github.com/dwijayuda/pskernel/actions/runs/38928344465): SUCCESS.
- F2 logical operations [38928344501](https://github.com/dwijayuda/pskernel/actions/runs/38928344501): SUCCESS.
- F3/F4/platform [38928344471](https://github.com/dwijayuda/pskernel/actions/runs/38928344471): SUCCESS.
- Focused recursive Hashable/Repr/BEq/DecidableEq and new recursion [38928344644](https://github.com/dwijayuda/pskernel/actions/runs/38928344644): SUCCESS. JS direct, pinned strict TS, Rust, V8 GC core, Wasmtime components and independent pinned native-Lean equations/output passed. Focused artifact `12057652697`; SHA-256 `6810c1bb993307f038cf0ad950e1eb77850a7b1df0d235efdea5d841f3c80c3f`.

## Scope accepted

1. An ordinary fixed prefix of explicit parameter references can precede the computed structural major. It is *not* speculatively evaluated: only unchanged directly resolved local binder references may be preclassified, preserving argument order. The separately elaborated major is reused once at its actual position, type-checked against the child telescope, and recognized only by read-only definitional equality to an existing checked strict field with an existing IH.
2. The existing verified worker-normalization route may move an *evolving* (changed) prefix into recursive state, rather than rejecting a legitimate totally recursive function. Native Lean and PSC source `flipPrefix` equations and Bool-to-UInt64 outputs exercise that route across the five selected runtime lanes.
3. Source `laterChild(flag,n)` exercises a *fixed* flag before n and a computed canonical `Nat.add(k,0)` major. The mismatch negative `badLaterMajor(flag,Nat.succ(k))` rejects an unchanged/nondecreasing major by the intended elaboration rule. An earlier proposed `badPrefix` negative was erroneous: changing a state parameter can be total after checked worker normalization. The correction preserves actual strict-subterm enforcement.
4. No source-name special case, unchecked IH, kernel exemption, erasure weakening, new assumption, increased recursion/heartbeat budget or changed original benchmark sizes. Source/Standard, three-module apps, GC/component formats, native Wasmtime, Rust, measurement and artifact publication all passed.

## Explicit boundaries

- No completed general v7.2 M3+B, nested/mutual/indexed deriving, all motive/pattern elimination, well-founded recursion, P0 ordinary partial execution, partial_fixpoint P1, unsafe proof authority or verified artifact correspondence.
- The earlier fixed-discriminant multiple-scrutinee preparation `9f15ef1` failed invariant checking; no acceptance is inferred from it. The direct computed infix `k + 0` remains outside this bounded result; the canonical `Nat.add k 0` equation is the one tested.
- Pinned stable Lean 4.35.0: `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`, normative v7.2 blob `694115223777599ba28ee175e14bb642b7b6aa4b`. Earlier accepted direct-recursive deriving, performance and original M2+A receipts preserved.
- No new performance speedup claimed. The separate paired runtime study remains the only qualified List-to-Array performance improvement.

Next implementation: exact pinned `Nat.sub a 0` canonical conversion (per stable `Init/Prelude.lean`), with minimal focused positive/negative and all five replays; independent staging blobs are recorded in both current handoffs. Retain PR #109 draft/open/unmerged on its existing base; preserve all source history with expected-HEAD non-force updates.
