# Runtime compatibility and checked watch

Decision record, 2026-10-27. Implementation starts from PR#192 at
94e0c13f6a4b434f73c859cc0c716cb6fb8d1340. New qualification is pending.
[User guide](../guides/cli.md), [roadmap](../PSC1_DEVELOPMENT_ROADMAP.md).

## Research and decisions

npm engines accept semver ranges. The installed host had two additional exact
Node22.23.3 comparisons, so changing package.json alone could not fix the user's
PSC1_INSTALLED_NODE_PIN refusal. Both guards now use one minimum policy. Reproducible
CI retains exact runtime versions and executable identities; those facts serve
different purposes.
[Official npm engines](https://docs.npmjs.com/cli/v11/configuring-npm/package-json/#engines).

Node documents that fs.watch can stay attached to a deleted inode after an
atomic replacement and that filesystem/platform behavior differs. TypeScript
combines file/directory watching and polling fallbacks. For the existing explicit
4096-file/128MiB project boundary, metadata polling is the smallest portable first
implementation. It never substitutes mtime for a compiler/checker source identity.
Actual reads/hashes are recaptured for every attempt and before publication.
No recursive project discovery or speculative cache invalidation system is needed.
[Node caveats](https://nodejs.org/api/fs.html#caveats),
[TypeScript watch](https://www.typescriptlang.org/docs/handbook/configuring-watch.html).

Bun compatibility is not inferred from its emulated process.version. Detect
process.versions.bun, run actual Bun subprocesses, record the actual runtime and
retain independent Lean admission. Bun's --check type-checks/runs rather than
providing Node's parse-only semantics. Use an explicit JS-loader Transpiler.scan
without executing the source, then retain the separate mandatory runtime API
consumer. Actual malformed syntax and parse-only side-effect tests must pass.
[Compatibility](https://bun.sh/docs/runtime/nodejs-compat),
[Runtime flags](https://bun.com/docs/runtime),
[Transpiler API](https://bun.com/docs/runtime/transpiler).

Bun respects Node shebangs unless --bun is explicit. New host-controlled child launch arguments
disable auto-install, macros and implicit env-file loading; source data cannot
select a runtime or inject these flags. The minimum Bun1.4.4 permits these explicit
policies. Exact tested versions remain separate evidence.
[Bun execution](https://bun.com/docs/runtime#bun),
[Bun1.4](https://bun.com/blog/bun-v1.4),
[Macros](https://bun.com/docs/bundler/macros).

## Responsibilities and invariants

| Owner | Invariant and refusal behavior |
| --- | --- |
| runtime-policy.mjs | Node>=22.23.3 or Bun>=1.4.4; unsupported/malformed/prerelease versions refuse. Exact executable resources still verified before/after requests. Runtime launch/syntax differences are explicit. |
| cli-project.mjs | Source-only finite argv/project data; original fatal UTF8/BOM/exclusive/relative/non-symlink and byte/count limits remain. Missing watch paths may be observed but cannot be captured/admitted. |
| cli-watch.mjs | Config plus declared paths only; 500ms bounded metadata polling/debounce; one checked attempt at a time; one dirty follow-up; progress on stderr; no checker cache, SDK/network install or output-triggered rebuild. |
| cli-watch-worker.mjs | Private request hash plus full captured-input identity before execution; same identity immediately before publication or compile/check stdout. A stale/capture failure vetoes publication. |
| compiler-api.mjs | Existing session.execute performs genuine admission/strict original+transformed IR/target checking. A trusted synchronous beforePublish callback can only veto after execution; session.publish retains its own authority/verification. |
| proofscript-cli.mjs | Spawn arrays, streamed stdout,32MiB diagnostic cap, explicit worker whitelist; Linux process groups,130/143 and2s kill escalation. Normal one-shot commands use the same adapter. |

No watcher can make source edits atomic with output publication. The defined
linearization point is the last successful exact recapture before publish.
Edits after that point cause the next attempt. No claim of continuous source/
output equality is made. Polls observe metadata changes; adversarial filesystem
timestamp manipulation and same-user hostile path races are outside the existing
workspace model. Every completed request still validates exact bytes.

Per compiler/tool240s and independent checker120s remain unchanged, as do semantic
fuel, IR/proof/ABI refusals, memory/stack/lifetime policies and fixed-point inputs.
No G2/G3 relabeling; official kernel C++/Emscripten linear memory and compiler WasmGC
stay distinct. No source-language/compiler algorithms are rewritten.

## Required actual acceptance

- Node22.23.3 minimum, original22.23.3, Node24/26 and Bun1.4.4 minimum;
  actual installed processes, exact binary hashes, both grammars/four engines,
  output observations, genuine default independent checker and rejection.
- Actual Node20/22.0.0 and Bun1.4.0 installed refusal; help/init remain usable without checking.
- Installed watch dependency edits, atomic saves, deletion/recreation, newly
  declared missing sources, config recovery/authority injection refusal,
  unchanged last output, superseded actual staged request, interrupts.
- Checked TS/Rust/Wasm watch output for both grammars, exact optional consumers.
- Every existing installed source/CLI/global/kernel/candidate/component/provider/
  publication/IO/application/type regression. Source dependency-selected gates
  remain; unchanged frozen self-hosting is not rerun solely for host changes.

Linux qualification does not qualify Windows/macOS durability, arbitrary
runtime versions, a semantic incremental compiler, final registry publication,
or an independent human's understanding. Human trial remains pending.

The bundled independent kernel declares engines.node>=22.23.3. The root minimum
matches this existing dependency contract, so engine-strict offline installation
can succeed. Lower Node22 releases and Node20 are actual negative matrix entries.
Newer Node24/26 remain allowed and are tested separately; there is no exact user pin.

## Measured Bun minimum

Run [40446238737](https://github.com/dwijayuda/pskernel/actions/runs/40446238737)
passed the full installed suite and Bun1.4.4, but actual Bun1.4.0 failed when
WebAssembly.Module.exports enumerated the generated Wasm GC compiler's exports.
Keep that required no-delegation/export check intact. The supported minimum is
now Bun1.4.4, the measured passing release; no claim is made about the first
upstream fix. Versions1.4.1–1.4.3 remain unqualified and refused. Bun1.4.0 is an
actual negative matrix entry; the installed Bun1.4.4 gate qualifies the minimum.
The official C++ Lean checker still uses Emscripten linear memory.

## Exact Rust SDK provisioning

The e4476046 main job refused lib/rustlib/components: an ambient Rust1.90.0
install listed the same cargo/std/rustc components in a different byte order.
[Diagnostic40452300522](https://github.com/dwijayuda/pskernel/actions/runs/40452300522)
found all other60 resources identical; a fresh isolated minimal installation
matched all61 existing pins. No consumer/resource guard is changed.
[Fresh-install replay40452569506](https://github.com/dwijayuda/pskernel/actions/runs/40452569506)
then passed all11 unmodified watch cases and actual Bun1.4.0 refusal against the
exact e447 candidate. Canonical CI now installs Rust1.90.0 minimal afresh on its
disposable runner and verifies all61 resources before expensive tests. The user
recipe provisions a separate SDK and passes --rust-toolchain-root explicitly.
Earlier opaque timeout logs did not identify their target/error; this observed
reproduction explains one concrete failure class, not every historical attempt.
