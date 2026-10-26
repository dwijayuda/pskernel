# Slim universal ProofScript package

The current Linux-qualified host is `proofscript@0.1.0-psc1.7`.
Use the [checked-dispatch install guide](PSC1_CHECKED_DISPATCH_INSTALL.md) and
[exact receipt](PSC1_CHECKED_DISPATCH_QUALIFICATION_2026-10-26.json).
The root is 3,811,703 bytes; the qualified archive contains eleven tarballs,
plus actual installed, kernel and immutable-store evidence.

The default root embeds the unchanged qualified JS/TS G3 compilers and genuine
official Lean 4.35 C++/Emscripten **linear-memory Wasm** checker. It requires no
native compiler SDK or install-time build. Rust/compiler-Wasm execution bundles,
native kernel comparison, TS/Rust output consumers, Python/PHP runtimes and
component tooling are explicit optional installations. Compiler Wasm remains GC.

Seven checked output selections share the private independent-admission and strict
IR session. Python/PHP reuse existing emit-only backends over admitted canonical
portable IR; component output packages the exact GC core with the closed Bool ABI.
The [dispatch guide](PSC1_CHECKED_DISPATCH.md) describes the ABI, authority,
consumer and platform boundaries. Broader component String/IO remains separate.

With Node 22.23.3 and the exact local tarballs:

~~~sh
npm install --offline --ignore-scripts ./proofscript-0.1.0-psc1.7.tgz
npx --no-install psc --identity
npx --no-install psc compile Main.ps --engine ts
npx --no-install psc build Main.lean --target wasm-core --publication-protocol portable-file --out dist/app
~~~

Install optional providers/consumers only as shown in the install guide.
Removing execution bundles does not remove the core candidate emitters. Checked
TS/Rust output still requires its exact pinned output consumer/SDK; the default
JS/Wasm-core paths require neither. Source/project/package metadata cannot select
tools, checker paths or publication authority.

Both pointer layouts retain [the checked-publication contract](PSC1_CHECKED_PUBLICATION.md):
immutable returned paths, sealed inventories, stale-writer refusal, precommit
prior-output preservation and explicit committed-but-durability-uncertain errors.
Actual Linux qualification does not qualify macOS/Windows transaction behavior;
those commits remain refused. New native dispatch packages are Linux x64 only.

Independent canonical admission, strict IR, runtime tests and self-host fixed
points are distinct evidence. They do not prove whole-compiler preservation.
Final universal-platform release, clean reproduction, merge and publication remain
open obligations in [the roadmap](PSC1_DEVELOPMENT_ROADMAP.md) and distribution
contract. No merge or npm registry publication is authorized.

The preceding [.6 receipt](PSC1_CHECKED_PUBLICATION_QUALIFICATION_2026-10-26.json)
and [eight-tarball install guide](PSC1_CHECKED_PUBLICATION_INSTALL.md) remain intact.
The preserved [PR #181 guide](history/PSC1_SLIM_UNIVERSAL_BEFORE_CHECKED_PUBLICATION_2026-10-26.md)
retains its frozen 120-module .4 identities. Resolve that verbatim snapshot's
original relative links at 563ee855407581d0d34adcbc450ad77863f39f94.
