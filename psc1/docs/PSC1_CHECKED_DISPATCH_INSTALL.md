# Install the checked dispatch candidate

This is an unpublished Linux qualification artifact, not a registry release.
The exact qualification receipt identifies the successful test run, ZIP digest,
tarballs and source commits. Do not substitute similarly named earlier artifacts.

## Download and verify the qualified bytes

[Download the exact successful artifact](https://github.com/dwijayuda/pskernel/actions/runs/40250645368/artifacts/12622001061)
from [installed replay 40250645368](https://github.com/dwijayuda/pskernel/actions/runs/40250645368).
GitHub Actions artifact downloads require GitHub sign-in. If the browser shows
404 while signed out, sign in with repository access, or use the authenticated
GitHub CLI:

~~~sh
gh run download 40250645368 --repo dwijayuda/pskernel --name psc1-checked-dispatch-replay-8383c6983e5fa2f2d945b02ba4b349ab64522c64 --dir psc1-candidate
cd psc1-candidate/slim-universal/tarballs
~~~

The ZIP is 211,957,705 bytes, SHA256
`d2f0221c06736636731a4b102a88e56abd3cb6242713d510dca42673704e162e`; it expires 2027-01-24T00:42:24Z.
GitHub CLI extraction yields the tarballs plus sibling qualification/readability
reports. Verify the eleven tarballs before installation:

~~~sh
sha256sum -c <<'SHA256'
d4a0e963375366ac9b417dd1e9eb5372168c25c5230d3ce69f694274daa87043  proofscript-0.1.0-psc1.7.tgz
b203982eeb851b797f7a35a8a66f883472a6130f24f36c26b8931bd5e0881511  proofscript-pskernel-lean-wasm-4.35.0.tgz
c8ffd49220328ec2a96ac1c4388d828df255cc21537b2484b523710fe6c17371  proofscript-pskernel-lean-4.35.0.tgz
c09533b046eb213e38b679d8aa7d0bb2705d6d25a3bd253d83c94f120992106c  proofscript-compiler-rust-linux-x64-0.1.0-psc1.7.tgz
90a98bb920b0dfc72f8c72783119454544d2f2497db8df131559cd462cc36689  proofscript-compiler-wasm-0.1.0-psc1.7.tgz
da2513f4b95176d6dde8b51aab7afe8a927656c9d277369793f77f7e59371c08  typescript-7.0.2.tgz
7ecad6f67377e831856367ab062ef394f21506a611405bf8ac0ff039348637d3  typescript-typescript-linux-x64-7.0.2.tgz
0b57758a5bb074593f699f93d2267d8a80d2fcdeba19f4c61222cbb517e04309  proofscript-rust-target-consumer-linux-x64-0.1.0-psc1.6.tgz
258bb15d9f42fd96ae7099cedc6c69d354b78562d39899960d2fde0ec861c715  proofscript-backend-python-0.1.0-psc1.7.tgz
b54f3d4b9dfb1bd557b9da79b0d4c1620605c4df0e4004a01e824651318dec10  proofscript-backend-php-0.1.0-psc1.7.tgz
763983698af82ddd0350fa584f4324004cd9d44e39e285e353af0e5449c390f2  proofscript-wasm-component-tools-linux-x64-0.1.0-psc1.7.tgz
SHA256
~~~

Producer source: `7e63615b0d0713db8b252f194d5740bbb5c5893f`.
Successful installed-test commit: `8383c6983e5fa2f2d945b02ba4b349ab64522c64`.
Root: **3,811,703 bytes**. Production files and payloads are identical across
those commits. The producer's later fixture failure remains recorded as a failure;
only the successful complete replay qualifies these exact bytes.

The replay passes 40 provider corpus cases, 16 callback IO cases, eight component
groups and 98 new dispatch refusals, plus every original installed/
application/consumer/type gate. Normal source 40250678016 passes all selected
dependencies and 37/37 finite Practical Core criteria, zero blocked. See the
[exact receipt](PSC1_CHECKED_DISPATCH_QUALIFICATION_2026-10-26.json) for detailed scope.

## Root and optional output packages

Use Node **22.23.3**. Extract the qualified artifact and run from its tarball folder:

~~~sh
npm install --offline --ignore-scripts --no-audit --no-fund ./proofscript-0.1.0-psc1.7.tgz

# Install only the output providers/consumers you need.
npm install --offline --ignore-scripts --no-audit --no-fund ./proofscript-backend-python-0.1.0-psc1.7.tgz
npm install --offline --ignore-scripts --no-audit --no-fund ./proofscript-backend-php-0.1.0-psc1.7.tgz
npm install --offline --ignore-scripts --no-audit --no-fund ./proofscript-wasm-component-tools-linux-x64-0.1.0-psc1.7.tgz
~~~

The default root includes JS/TS compiler execution and the genuine official Lean
4.35 C++ checker compiled by Emscripten to **linear-memory Wasm**. Installing the
root does not install a native compiler SDK or compile anything during installation.

Python/PHP remain separate optional emit-only providers. Their validation runtimes
are bundled: Python 3.14.8 and PHP 8.5.12 with GMP. The native workers reuse PSC1's
existing backend implementations; they expose no PSC1 source frontend, admission
host or publisher. Official Lean support libraries remain linked into these native
workers. Component validation uses the pinned optional wasm-tools 1.254.0 package.

These new native packages are qualified only on the actual Ubuntu Linux x64
environment. Other OS/architecture dispatch refuses. This does not qualify a
final universal-platform toolchain.

## Compile or publish

Create Main.lean:

~~~lean
def truth : Bool := true
def negate (value : Bool) : Bool := if value then false else true
~~~

Its supported Main.ps spelling is:

~~~text
def truth : Bool := true
def negate(value : Bool) : Bool := if (value) { false } else { true }
~~~

~~~sh
npx --no-install psc build Main.lean --target python --publication-protocol portable-file --out dist/python
npx --no-install psc build Main.ps --target php --publication-protocol portable-file --out dist/php
npx --no-install psc build Main.lean --target wasm-component --publication-protocol portable-file --out dist/component
~~~

The command returns JSON containing immutable artifact and runtimeArtifact paths.
Python modules expose their advertised __all__; PHP modules return their public
API array. The component path produces an actual component binary and WIT, plus
the unchanged embedded GC core. It currently accepts the closed **Bool ABI**, at
most 16 direct parameters, supported WIT names and no callback imports.
Nat/Int/String/Unit public component interfaces and component callback IO refuse
in this dispatch path. Existing native String/IO component paths are preserved.

The compile API performs the same independent admission and target checks without
publishing. Python/PHP source uses sourceEncoding utf8. Component source uses
psc1-wasm-component-hex/1. JS/Wasm-core source encodings remain unchanged.

## Compiler engine and output target are separate

Optional execution packages add the genuine qualified Rust/compiler-Wasm engines:

~~~sh
npm install --offline --ignore-scripts ./proofscript-compiler-rust-linux-x64-0.1.0-psc1.7.tgz
npm install --offline --ignore-scripts ./proofscript-compiler-wasm-0.1.0-psc1.7.tgz
npx --no-install psc build Main.ps --engine wasm-core --target python --publication-protocol portable-file --out dist/app
~~~

Changing the execution engine does not select an admission provider or grant
the source a host capability. The default checker remains Wasm; explicit native
comparison uses the separately pinned @proofscript/pskernel-lean@4.35.0 package.

Checked TS output retains the optional TypeScript 7.0.2 SDK and its pinned Linux
x64 package. Checked Rust output retains the optional
@proofscript/rust-target-consumer-linux-x64@0.1.0-psc1.6 package plus the exactly
pinned external Rust 1.90.0 minimal toolchain. Rust execution itself needs no Rust
SDK. See the preceding checked-publication install guide for those SDK commands.

## Evidence and recovery boundaries

Every build captures exact sources, checks original/transformed IR, performs
genuine independent official admission and validates its actual output consumer
before publishing. Providers receive only admitted specialized IR and recheck its
canonical transport, strict validation and target ABI. Package metadata is data;
it cannot supply executable entries, a source frontend, checker or publication
authority. Missing, mismatched, modified or symlinked resources refuse.

All compiler/tool requests remain 240 seconds; independent checking remains
120 seconds. The aggregate CI matrix has its own supervisor deadline. Native
optional tools retain 4 GiB address space, 8 MiB stack and parent-lifetime guards.
The existing semantic fuel and source/transport policies are unchanged.

Both publication pointer layouts retain the checked-publication contract. A
precommit failure preserves the old pointer. A committed-but-durability-uncertain
error carries committedPublication; do not assume rollback or blindly retry.
Readback checks integrity, not a new independent proof.

The exact candidate replay checks ZIP/root hashes, a successful actual producer
kernel-check step and unchanged production files, then reruns every installed
gate. A failed producer is never relabeled successful; producer and test commits
are recorded separately. No compiler/kernel payload is rebuilt for a test-only
fixture correction. A production-source change requires fresh assembly.

Final platform release, broader component ABI, full provider application
acceptance and automatic source-package resolution remain separate roadmap work.
No whole-compiler semantic-preservation proof, merge or npm publication is claimed.
