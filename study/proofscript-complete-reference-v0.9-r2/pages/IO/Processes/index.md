<a id="io-processes"></a>

# ProofScript — 21.9. Processes

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Native IO separates a logical description from execution in a runtime environment. Console operations, mutable references, files, processes, clocks, randomness and tasks have exact APIs and effects. A file handle is a resource with identity and lifetime, not an immutable DTO. Browser, Node and Wasm hosts require explicit adapters; the existence of a Lean API does not establish that every target can implement it.

**Compiler and coverage boundary.** Retain native Task behavior rather than renaming Promise. Resource cleanup, cancellation, process termination and foreign failures need exact declared models; no undocumented async/await keyword is introduced.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [IO/Processes/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/IO/Processes/index.html). Source Git blob: `a5826ee866d41995a57f8a79490fc4164585325a`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Extends-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 21.9. Processes

<a id="The-Lean-Language-Reference--IO--Processes--Current-Process"></a>
### 21.9.1. Current Process

<a id="IO___Process___getCurrentDir"></a>

**opaque**

```text
IO.Process.getCurrentDir : IO System.FilePath
```

Returns the current working directory of the calling process.

<a id="IO___Process___setCurrentDir"></a>

**opaque**

```text
IO.Process.setCurrentDir (path : System.FilePath) : IO Unit
```

Sets the current working directory of the calling process.

<a id="IO___Process___exit"></a>

**opaque**

```text
IO.Process.exit {α : Type} : UInt8 → IO α
```

Terminates the current process with the provided exit code. `0` indicates success, all other values indicate failure.

<a id="IO___Process___getPID"></a>

**opaque**

```text
IO.Process.getPID : BaseIO UInt32
```

Returns the process ID of the calling process.

<a id="The-Lean-Language-Reference--IO--Processes--Running-Processes"></a>
### 21.9.2. Running Processes

There are three primary ways to run other programs from Lean:

1. `IO.Process.run` synchronously executes another program, returning its standard output as a string. It throws an error if the process exits with an error code other than `0`.
2. `IO.Process.output` synchronously executes another program with an empty standard input, capturing its standard output, standard error, and exit code. No error is thrown if the process terminates unsuccessfully.
3. `IO.Process.spawn` starts another program asynchronously and returns a data structure that can be used to access the process's standard input, output, and error streams.

<a id="IO___Process___run"></a>

**def**

```text
IO.Process.run (args : IO.Process.SpawnArgs)
  (input? : Option String := none) : IO String
```

Runs a process to completion, blocking until it terminates. The child process is run with a null standard input or the specified input if provided, If the child process terminates successfully with exit code 0, its standard output is returned. An exception is thrown if it terminates with any other exit code.

The specifications of standard input, output, and error handles in `args` are ignored.

<a id="Running-a-Program"></a>
Running a Program 

When run, this program concatenates its own source code with itself twice using the Unix tool `cat`.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="main-_LPAR_in-Running-a-Program_RPAR_"></a>


```proofscript
-- Main.lean begins here
const main : IO Unit := do
  let src2 ← IO.Process.run {cmd := "cat", args := #["Main.lean", "Main.lean"]}
  IO.println src2
-- Main.lean ends here
```

Its output is:

  `stdout``-- Main.lean begins here``def main : IO Unit := do``let src2 ← IO.Process.run {cmd := "cat", args := #["Main.lean", "Main.lean"]}``IO.println src2``-- Main.lean ends here``-- Main.lean begins here``def main : IO Unit := do``let src2 ← IO.Process.run {cmd := "cat", args := #["Main.lean", "Main.lean"]}``IO.println src2``-- Main.lean ends here`  
<a id="Running-a-Program-on-a-File"></a>
Running a Program on a File 

This program uses the Unix utility `grep` as a filter to find four-digit palindromes. It creates a file that contains all numbers from `0` through `9999`, and then invokes `grep` on it, reading the result from its standard output.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="main-_LPAR_in-Running-a-Program-on-a-File_RPAR_"></a>


```proofscript
const main : IO Unit := do
  -- Feed the input to the subprocess
  IO.FS.withFile "numbers.txt" .write fun h =>
    for i in [0:10000] do
      h.putStrLn (toString i)

  let palindromes ← IO.Process.run {
    cmd := "grep",
    args := #[r#"^\([0-9]\)\([0-9]\)\2\1$"#, "numbers.txt"]
  }

  let count := palindromes.trimAscii.split "\n" |>.length

  IO.println s!"There are {count} four-digit palindromes."
```

Its output is:

  `stdout``There are 90 four-digit palindromes.`  
<a id="IO___Process___output"></a>

**def**

```text
IO.Process.output (args : IO.Process.SpawnArgs)
  (input? : Option String := none) : IO IO.Process.Output
```

Runs a process to completion and captures its output and exit code. The child process is run with a null standard input or the specified input if provided, and the current process blocks until it has run to completion.

The specifications of standard input, output, and error handles in `args` are ignored.

<a id="Checking-Exit-Codes"></a>
Checking Exit Codes 

When run, this program first invokes `cat` on a nonexistent file and displays the resulting error code. It then concatenates its own source code with itself twice using the Unix tool `cat`.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="main-_LPAR_in-Checking-Exit-Codes_RPAR_"></a>


```proofscript
-- Main.lean begins here
const main : IO UInt32 := do
  let src1 ← IO.Process.output {cmd := "cat", args := #["Nonexistent.lean"]}
  IO.println s!"Exit code from failed process: {src1.exitCode}"

  let src2 ← IO.Process.output {cmd := "cat", args := #["Main.lean", "Main.lean"]}
  if src2.exitCode == 0 then
    IO.println src2.stdout
  else
    IO.eprintln "Concatenation failed"
    return 1

  return 0
-- Main.lean ends here
```

Its output is:

  `stdout``Exit code from failed process: 1``-- Main.lean begins here``def main : IO UInt32 := do``let src1 ← IO.Process.output {cmd := "cat", args := #["Nonexistent.lean"]}``IO.println s!"Exit code from failed process: {src1.exitCode}"````let src2 ← IO.Process.output {cmd := "cat", args := #["Main.lean", "Main.lean"]}``if src2.exitCode == 0 then``IO.println src2.stdout``else``IO.eprintln "Concatenation failed"``return 1````return 0``-- Main.lean ends here``-- Main.lean begins here``def main : IO UInt32 := do``let src1 ← IO.Process.output {cmd := "cat", args := #["Nonexistent.lean"]}``IO.println s!"Exit code from failed process: {src1.exitCode}"````let src2 ← IO.Process.output {cmd := "cat", args := #["Main.lean", "Main.lean"]}``if src2.exitCode == 0 then``IO.println src2.stdout``else``IO.eprintln "Concatenation failed"``return 1````return 0``-- Main.lean ends here```  
<a id="IO___Process___spawn"></a>

**opaque**

```text
IO.Process.spawn (args : IO.Process.SpawnArgs) :
  IO (IO.Process.Child args.toStdioConfig)
```

Starts a child process with the provided configuration. The child process is spawned using operating system primitives, and it can be written in any language.

The child process runs in parallel with the parent.

If the child process's standard input is a pipe, use `IO.Process.Child.takeStdin` to make it possible to close the child's standard input before the process terminates, which provides the child with an end-of-file marker.

<a id="Asynchronous-Subprocesses"></a>
Asynchronous Subprocesses 

This program uses the Unix utility `grep` as a filter to find four-digit palindromes. It feeds all numbers from `0` through `9999` to the `grep` process and then reads its result. This code is only correct when `grep` is sufficiently fast and when the output pipe is large enough to contain all 90 four-digit palindromes.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="main-_LPAR_in-Asynchronous-Subprocesses_RPAR_"></a>


```proofscript
const main : IO Unit := do
  let grep ← IO.Process.spawn {
    cmd := "grep",
    args := #[r#"^\([0-9]\)\([0-9]\)\2\1$"#],
    stdin := .piped,
    stdout := .piped,
    stderr := .null
  }

  -- Feed the input to the subprocess
  for i in [0:10000] do
    grep.stdin.putStrLn (toString i)

  -- Consume its output, after waiting 100ms for grep to process the data.
  IO.sleep 100
  let count := (← grep.stdout.readToEnd).trimAscii.split "\n" |>.length

  IO.println s!"There are {count} four-digit palindromes."
```

Its output is:

  `stdout``There are 90 four-digit palindromes.`  
<a id="IO___Process___SpawnArgs___mk"></a>

**structure**

```text
IO.Process.SpawnArgs : Type
```

Configuration for a child process to be spawned.

Use `IO.Process.spawn` to start the child process. `IO.Process.output` and `IO.Process.run` can be used when the child process should be run to completion, with its output and/or error code captured.

**Constructor**

```text
IO.Process.SpawnArgs.mk
```

**Extends**

- <a id="0-IO.Process.StdioConfig-IO.Process.SpawnArgs"></a>
  `IO.Process.StdioConfig`

**Fields**

```text
stdin : IO.Process.Stdio
```

 Inherited from 

1. `IO.Process.StdioConfig`

```text
stdout : IO.Process.Stdio
```

 Inherited from 

1. `IO.Process.StdioConfig`

```text
stderr : IO.Process.Stdio
```

 Inherited from 

1. `IO.Process.StdioConfig`

```text
cmd : String
```

Command name.

```text
args : Array String
```

Arguments for the command.

```text
cwd : Option System.FilePath
```

The child process's working directory. Inherited from the parent current process if `none`.

```text
env : Array (String × Option String)
```

Add or remove environment variables for the child process.

The child process inherits the parent's environment, as modified by `env`. Keys in the array are the names of environment variables. A `none`, causes the entry to be removed from the environment, and `some` sets the variable to the new value, adding it if necessary. Variables are processed from left to right.

```text
inheritEnv : Bool
```

Inherit environment variables from the spawning process.

```text
setsid : Bool
```

Starts the child process in a new session and process group using `setsid`. Currently a no-op on non-POSIX platforms.

<a id="IO___Process___StdioConfig___mk"></a>

**structure**

```text
IO.Process.StdioConfig : Type
```

Configuration for the standard input, output, and error handles of a child process.

**Constructor**

```text
IO.Process.StdioConfig.mk
```

**Fields**

```text
stdin : IO.Process.Stdio
```

Configuration for the process' stdin handle.

```text
stdout : IO.Process.Stdio
```

Configuration for the process' stdout handle.

```text
stderr : IO.Process.Stdio
```

Configuration for the process' stderr handle.

<a id="IO___Process___Stdio___piped"></a>

**inductive type**

```text
IO.Process.Stdio : Type
```

Whether the standard input, output, and error handles of a child process should be attached to pipes, inherited from the parent, or null.

If the stream is a pipe, then the parent process can use it to communicate with the child.

**Constructors**

```text
IO.Process.Stdio.piped : IO.Process.Stdio
```

The stream should be attached to a pipe.

```text
IO.Process.Stdio.inherit : IO.Process.Stdio
```

The stream should be inherited from the parent process.

```text
IO.Process.Stdio.null : IO.Process.Stdio
```

The stream should be empty.

<a id="IO___Process___Stdio___toHandleType"></a>

**def**

```text
IO.Process.Stdio.toHandleType : IO.Process.Stdio → Type
```

The type of handles that can be used to communicate with a child process on its standard input, output, or error streams.

For `IO.Process.Stdio.piped`, this type is `IO.FS.Handle`. Otherwise, it is `Unit`, because no communication is possible.

<a id="IO___Process___Child___stdin"></a>

**structure**

```text
IO.Process.Child (cfg : IO.Process.StdioConfig) : Type
```

A child process that was spawned with configuration `cfg`.

The configuration determines whether the child process's standard input, standard output, and standard error are `IO.FS.Handle`s or `Unit`.

**Fields**

```text
stdin : cfg.stdin.toHandleType
```

The child process's standard input handle, if it was configured as `IO.Process.Stdio.piped`, or `()` otherwise.

```text
stdout : cfg.stdout.toHandleType
```

The child process's standard output handle, if it was configured as `IO.Process.Stdio.piped`, or `()` otherwise.

```text
stderr : cfg.stderr.toHandleType
```

The child process's standard error handle, if it was configured as `IO.Process.Stdio.piped`, or `()` otherwise.

<a id="IO___Process___Child___wait"></a>

**opaque**

```text
IO.Process.Child.wait {cfg : IO.Process.StdioConfig} :
  IO.Process.Child cfg → IO UInt32
```

Blocks until the child process has exited and returns its exit code.

<a id="IO___Process___Child___tryWait"></a>

**opaque**

```text
IO.Process.Child.tryWait {cfg : IO.Process.StdioConfig} :
  IO.Process.Child cfg → IO (Option UInt32)
```

Checks whether the child has exited. Returns `none` if the process has not exited, or its exit code if it has.

<a id="IO___Process___Child___kill"></a>

**opaque**

```text
IO.Process.Child.kill {cfg : IO.Process.StdioConfig} :
  IO.Process.Child cfg → IO Unit
```

Terminates the child process using the `SIGTERM` signal or a platform analogue.

If the process was started using `SpawnArgs.setsid`, terminates the entire process group instead.

<a id="IO___Process___Child___takeStdin"></a>

**opaque**

```text
IO.Process.Child.takeStdin {cfg : IO.Process.StdioConfig} :
  IO.Process.Child cfg →
    IO
      (cfg.stdin.toHandleType ×
        IO.Process.Child
          { stdin := IO.Process.Stdio.null, stdout := cfg.stdout,
            stderr := cfg.stderr })
```

Extracts the `stdin` field from a `Child` object, allowing the handle to be closed while maintaining a reference to the child process.

File handles are closed when the last reference to them is dropped. Closing the child's standard input causes an end-of-file marker. Because the `Child` object has a reference to the standard input, this operation is necessary in order to close the stream while the process is running (e.g. to extract its exit code after calling `Child.wait`). Many processes do not terminate until their standard input is exhausted.

<a id="Closing-a-Subprocess___s-Standard-Input"></a>
Closing a Subprocess's Standard Input 

This program uses the Unix utility `grep` as a filter to find four-digit palindromes, ensuring that the subprocess terminates successfully. It feeds all numbers from `0` through `9999` to the `grep` process, then closes the process's standard input, which causes it to terminate. After checking `grep`'s exit code, the program extracts its result.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="main-_LPAR_in-Closing-a-Subprocess___s-Standard-Input_RPAR_"></a>


```proofscript
const main : IO UInt32 := do
  let grep ← do
    let (stdin, child) ← (← IO.Process.spawn {
      cmd := "grep",
      args := #[r#"^\([0-9]\)\([0-9]\)\2\1$"#],
      stdin := .piped,
      stdout := .piped,
      stderr := .null
    }).takeStdin

    -- Feed the input to the subprocess
    for i in [0:10000] do
      stdin.putStrLn (toString i)

    -- Return the child without its stdin handle.
    -- This closes the handle, because there are
    -- no more references to it.
    pure child

  -- Wait for grep to terminate
  if (← grep.wait) != 0 then
    IO.eprintln s!"grep terminated unsuccessfully"
    return 1

  -- Consume its output
  let count := (← grep.stdout.readToEnd).trimAscii.split "\n" |>.length

  IO.println s!"There are {count} four-digit palindromes."
  return 0
```

Its output is:

  `stdout``There are 90 four-digit palindromes.`  
<a id="IO___Process___Output___mk"></a>

**structure**

```text
IO.Process.Output : Type
```

The result of running a process to completion.

**Constructor**

```text
IO.Process.Output.mk
```

**Fields**

```text
exitCode : UInt32
```

The process's exit code.

```text
stdout : String
```

Everything that was written to the process's standard output.

```text
stderr : String
```

Everything that was written to the process's standard error.
