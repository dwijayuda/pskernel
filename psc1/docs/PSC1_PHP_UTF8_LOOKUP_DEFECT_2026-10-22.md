# PHP UTF8 byte-lookup performance defect

Status: normal application blocker diagnosed; correction implemented, unqualified.

Run 39664407902 at 5fa88fa1842d8d8d9fa1881592ed2801d2778b37 times out
on Lean/PHP's 100000-statement / 500000-byte source at the outer 180-second
guard. The original acceptance remains 120 seconds / 1 GiB. Six Lean backends,
both focused grammars on five targets and both minimum-Python consumers pass.
Exact observations: PSC1_APPLICATION_PERFORMANCE_PROGRESS_2026-10-22.json.
No full qualification is claimed for that failed run.

PHP stringGet previously preg_split the entire String and scanned every scalar
on every lookup; next repeated it. String parameter guards also repeated UTF8
validation through recursive calls. The correction retains at most two completed
whole-String validations, keyed by immutable String values. PHP's memoized
String-key hashes avoid rescanning even two large Strings with a common prefix.
Invalid values are never cached. Existing scalar byte boundaries permit direct
byte lookup after validation; continuation positions retain the default A,
and next adds its width. GMP positions are compared with byte size before
conversion, preserving huge positions. Extraction is unchanged.

Modules selecting byte helpers reuse the same completed validation in String
parameter guards. Other profiles keep their existing inline guard, including
runtime-free String echo without GMP. Error classes and whole-input invalid
UTF8 refusal, even for out-of-range positions, remain. No capability, ABI,
IR validation or resource limit is relaxed.

A strict-IR emitted PHP regression checks Unicode/middle-byte/empty/huge cases,
extract behavior, persistent values, numeric String keys, copy-on-write and cache
eviction, malformed encodings and suffixes, argument guards and a no-GMP echo.
100000 pairs of lookups/next on two 500000-byte Strings sharing their prefix
must finish within five seconds. Actual checked compiler/CLI applications also
run in a separate focused PHP job, preserving the original focused target matrix
and per-job fifteen-minute limit. Full qualification still requires all seven
targets and minimum runtimes. These runtime tests are not source admission.
