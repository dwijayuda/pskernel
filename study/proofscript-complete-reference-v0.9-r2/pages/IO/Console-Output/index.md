<a id="The-Lean-Language-Reference--IO--Console-Output"></a>

# ProofScript — 21.3. Console Output

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Native IO separates a logical description from execution in a runtime environment. Console operations, mutable references, files, processes, clocks, randomness and tasks have exact APIs and effects. A file handle is a resource with identity and lifetime, not an immutable DTO. Browser, Node and Wasm hosts require explicit adapters; the existence of a Lean API does not establish that every target can implement it.

**Compiler and coverage boundary.** Retain native Task behavior rather than renaming Promise. Resource cleanup, cancellation, process termination and foreign failures need exact declared models; no undocumented async/await keyword is introduced.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [IO/Console-Output/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/IO/Console-Output/index.html). Source Git blob: `23e4343caa9945675b9660418db9bc79ea6924c1`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 21.3. Console Output

Lean includes convenience functions for writing to [standard output](../Files___-File-Handles___-and-Streams/index.md#--tech-term-standard-output) and [standard error](../Files___-File-Handles___-and-Streams/index.md#--tech-term-standard-error). All make use of `ToString` instances, and the varieties whose names end in `-ln` add a newline after the output. These convenience functions only expose a part of the functionality available [using the standard I/O streams](../Files___-File-Handles___-and-Streams/index.md#stdio). In particular, to read a line from standard input, use a combination of `IO.getStdin` and `IO.FS.Stream.getLine`.

<a id="IO___print"></a>

**def**

```text
IO.print.{u_1} {α : Type u_1} [ToString α] (s : α) : IO Unit
```

Converts `s` to a string using its `ToString α` instance, and prints it to the current standard output (as determined by `IO.getStdout`).

<a id="IO___println"></a>

**def**

```text
IO.println.{u_1} {α : Type u_1} [ToString α] (s : α) : IO Unit
```

Converts `s` to a string using its `ToString α` instance, and prints it with a trailing newline to the current standard output (as determined by `IO.getStdout`).

<a id="IO___eprint"></a>

**def**

```text
IO.eprint.{u_1} {α : Type u_1} [ToString α] (s : α) : IO Unit
```

Converts `s` to a string using its `ToString α` instance, and prints it to the current standard error (as determined by `IO.getStderr`).

<a id="IO___eprintln"></a>

**def**

```text
IO.eprintln.{u_1} {α : Type u_1} [ToString α] (s : α) : IO Unit
```

Converts `s` to a string using its `ToString α` instance, and prints it with a trailing newline to the current standard error (as determined by `IO.getStderr`).

<a id="Printing"></a>
Printing 

This program demonstrates all four convenience functions for console I/O.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="main-_LPAR_in-Printing_RPAR_"></a>


```proofscript
const main : IO Unit := do
  IO.print "This is the "
  IO.print "Lean"
  IO.println " language reference."
  IO.println "Thank you for reading it!"
  IO.eprint "Please report any "
  IO.eprint "errors"
  IO.eprintln " so they can be corrected."
```

It outputs the following to the standard output:

  `stdout``This is the Lean language reference.``Thank you for reading it!` 

and the following to the standard error:

  `stderr``Please report any errors so they can be corrected.`
