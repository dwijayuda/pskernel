# Continue Lean4.35 kernel and cross-platform release integration

Continue draft PR #179, branch `integration/psc1-lean435-kernel-packages-20261025`,
stacked on #178/`feat/psc1-unified-selfhost-20261024`. Fetch live HEAD and run
metadata before writes. Use connected GitHub tools and cloud Actions exclusively.
Routine development/tests stay Linux; separate release qualification executes on
Linux x64/arm64, macOS x64/arm64 and Windows x64. Preserve concurrent history with
single-parent expected-HEAD non-force commits. Do not merge or publish.

Read AI_WORK_STATE.md, PSC1_DEVELOPMENT_ROADMAP.md, PSC1_KERNEL_PACKAGES.md and
PSC1_KERNEL435_QUALIFICATION_2026-10-25.json. Four-engine compiler source is frozen
at120 modules/07eedac1888aad3d4192664cea8d21a515d23985f3befd6cb365d0194fee53af.
All four genuine G1/G2/G3/fixed points remain qualified. Parent55f9327e full gate
40152772905 passed37/37/seven backends/both grammars. Do not rerun successful long
self-host chains for host/package-only changes.

## Verified native package milestone

Run40155475188 at4deb99def1dcb18fe348a184e70f8e3a74c03f04 passed all five
platforms' offline local/global installed APIs and corruption refusal. Native tgz
SHA256c8ffd49220328ec2a96ac1c4388d828df255cc21537b2484b523710fe6c17371,
6446239 bytes total, artifact12584263337 ZIP
a5cefb58f4eaf4a558b390294d24c555b763c3a0ef7f7e68aab7cfc324f58b2f.
Every native binary is below7,000,000 bytes and passes14 genuine official-reference
parity cases. Current provider closure is25 modules,
f1bd2a7d42b9473945028ffa698f244b33afeb937224c5c8e37d8c50d9de0a2b.
Host session40155831321 passes32 checks and10 Rust transport regressions;
static/types40156453697 and40156780118 pass. Additional successful provider in
that boundary suite is a real native reference, not a Wasm qualification.

## First finish the already running jobs

1. Inspect real linear-memory C++ Wasm run40154206987/job121051950567,
   source630fa36343cd1e8d19178cae200f2ad98cf017c0. It was still executing the
   compiler build step at the last snapshot. Do not cancel/restart it. Read logs
   only when terminal. On failure, diagnose actual stage/module/ABI error from
   retained logs and compatibility.patch; preserve source/toolchain/cache hashes,
   finite kernel checks and all resource limits. Never relabel old4.34 bytes.
2. Inspect native compiler platform source-admission run40157017833, sourcee2351c25.
   This builds genuine compiler binaries on Linux arm64/macOS x64+arm64/Windows x64
   and checks both source grammars/admission with SDK absent from PATH. It is a
   source/admission gate, not backend publication or npm-release qualification.
3. Inspect the latest PR #179 normal source CI and kernel static/types CI. Older
   normal snapshots cancelled by subsequent real code changes are not successes.
   Record the terminal latest code gate, not merely a green parent or static job.

## Execute Wasm packaging after genuine build success

Fetch /actions/runs/40154206987/artifacts. Select only the qualified artifact named
psc1-lean435-linear-kernel-qualified-630fa36343cd1e8d19178cae200f2ad98cf017c0,
verify its actual digest/source/job success. Commit this exact closed input to
`psc1/scripts/kernel435-wasm-package-input.json` (fill artifact and ZIP SHA256
from live metadata, never guesses):

```json
{"run":40154206987,"job":121051950567,"artifact":"ACTUAL_INTEGER_ID","zipSha256":"ACTUAL_64_HEX_DIGEST_WITHOUT_sha256_PREFIX","commit":"630fa36343cd1e8d19178cae200f2ad98cf017c0"}
```

That file triggers psc1-kernel435-wasm-package.yml: Linux assembly validates the
exact source closure, qualified bytes, linear memory, clean official C++ audit
snapshot, current source/provenance metadata and real package manifest. The same
packed tgz then executes offline local/global acceptance/rejection/corruption tests
on all five platforms. Fix genuine failures; require every platform to pass.
Keep Emscripten6.0.9 and the official C++ linear-memory kernel. Do not convert it
to Wasm GC or change PSC1's separate Wasm backend architecture.

## Execute integrated compiler/package qualification

After every Wasm package platform gate succeeds, fetch that run's packed artifact
and assembly receipt. Fill the wasm entry in this template with its actual run,
assembly job, artifact, ZIP SHA256, source commit, tgz filename and tgz SHA256.
Commit the completed object to `psc1/scripts/kernel435-integrated-inputs.json`:

```json
{
  "schema": "psc1-kernel435-integrated-package-inputs/1",
  "core": {
    "run": 40152769340,
    "job": 121047594235,
    "artifact": 12582649787,
    "zipSha256": "da6a88220337c601fcf401ea7e06a55c45988f96c0a5692d28e958ed07c61916",
    "commit": "55f9327ee738b5b2bf5d623c96280cb97de828b2",
    "tarball": "npm-generated/run-IjpP9o/tarballs/proofscript-0.1.0-psc1.3.tgz",
    "tarballSha256": "29a837faedaabb8c7e6ae30cec19ac53680084b5188de0eef2b7eabbd4f09198",
    "optional": {
      "python": {
        "file": "npm-generated/run-IjpP9o/tarballs/proofscript-backend-python-0.1.0-psc1.3.tgz",
        "sha256": "a9e26065a916ba53405897a29bdcb6b0cb4b750fef516e2948ad0c30a1a3e1bd"
      },
      "php": {
        "file": "npm-generated/run-IjpP9o/tarballs/proofscript-backend-php-0.1.0-psc1.3.tgz",
        "sha256": "7eaaa1f667e9783803e2402ce5d1adb6bd0d867faf665dbb8c5e406a260afaec"
      }
    }
  },
  "native": {
    "run": 40155475188,
    "job": 121055846346,
    "artifact": 12584263337,
    "zipSha256": "a5cefb58f4eaf4a558b390294d24c555b763c3a0ef7f7e68aab7cfc324f58b2f",
    "commit": "4deb99def1dcb18fe348a184e70f8e3a74c03f04",
    "tarball": "proofscript-pskernel-lean-4.35.0.tgz",
    "tarballSha256": "c8ffd49220328ec2a96ac1c4388d828df255cc21537b2484b523710fe6c17371"
  },
  "wasm": "FILL ONLY FROM SUCCESSFUL FIVE-PLATFORM WASM PACKAGE RUN"
}
```

This triggers psc1-kernel435-core-package.yml. It reuses all qualified compiler/G3
bytes, bundles both exact4.35 kernel packages offline, replaces the redundant large
checker with the pinned slim native provider, and updates all host/resource pins.
It must execute14 actual dual-kernel cases, both native source grammars, all four
real installed G3 engines across the full20-case corpus, negative/tamper checks and
prior-output preservation. Native compiler is unavailable during generated builds.
It then independently checks the exact frozen compiler admissions SHA256
4a43d82487eb09e6efcac248d6db211e9c2854bd2a9e04a9202affce6bdd3e39 with both kernels,
from the pinned genuine Rust qualification archive. This is logical rechecking,
not a new full-chain replay or formal compiler-preservation proof.

The new CLI is `psc kernel --identity`, `psc kernel check admissions.json
--provider native|wasm|both`, `psc kernel check-source Main.lean|ps --provider both`,
and `psc generated build ... --kernel both`. Native admission remains mandatory;
Wasm rejection/integrity/process failure must prevent publication. Tests and
assembly are prepared but must not be called qualified before those actual runs.

## Remaining complete cross-platform toolchain work

Native kernels are install-qualified on five platforms; the existing proofscript
core remains Linux x64/glibc. Source platform compiler checks alone do not change
that scope. In particular host-tools/artifacts.mjs explicitly refuses non-Linux
atomic publication, and generated session pointer/directory-fsync behavior is
Linux-oriented. Implement and qualify a portable transactional publication contract
without weakening prior-output preservation/atomicity. Also deliver native compiler
and generated Rust platform assets/transports, optional Python/PHP installation,
backend consumer parity and required final platform release gates. The Node launcher
now selects .exe on Windows and platform-specific library paths, but that is not a
complete platform release. Keep unsupported capabilities explicit until qualified.

Maintain exact receipts, AI_WORK_STATE.md and the one roadmap. Keep JS/TS/Rust/Wasm,
optional Python/PHP, independent Lean4.35, source/logical pairing, strict both IR,
negative tests, semantic fuel and memory/stack policies. G1/tools240s/checker120s,
original1800s correctness and240s performance stay unchanged. Rust-only3600s remains
G2/G3 compiler requests only. No merge or registry publication without qualification
and user authorization.
