<a id="The-Lean-Language-Reference--IO--Files___-File-Handles___-and-Streams"></a>

# ProofScript — 21.5. Files, File Handles, and Streams

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Native IO separates a logical description from execution in a runtime environment. Console operations, mutable references, files, processes, clocks, randomness and tasks have exact APIs and effects. A file handle is a resource with identity and lifetime, not an immutable DTO. Browser, Node and Wasm hosts require explicit adapters; the existence of a Lean API does not establish that every target can implement it.

**Compiler and coverage boundary.** Retain native Task behavior rather than renaming Promise. Resource cleanup, cancellation, process termination and foreign failures need exact declared models; no undocumented async/await keyword is introduced.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [IO/Files___-File-Handles___-and-Streams/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/IO/Files___-File-Handles___-and-Streams/index.html). Source Git blob: `890e76bf2fdf84109401b6080e9acf0bc009561f`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Constructors-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 21.5. Files, File Handles, and Streams

Lean provides a consistent filesystem API on all supported platforms. These are the key concepts:

<a id="--tech-term-Files"></a>
Files

Files are an abstraction provided by operating systems that provide random access to persistently-stored data, organized hierarchically into directories.

<a id="--tech-term-Directories"></a>
Directories

Directories, also known as *folders*, may contain files or other directories. Fundamentally, a directory maps names to the files and/or directories that it contains.

<a id="--tech-term-File-Handles"></a>
File Handles

File handles (`Handle`) are abstract references to files that have been opened for reading and/or writing. A file handle maintains a mode that determines whether reading and/or writing are allowed, along with a cursor that points at a specific location in the file. Reading from or writing to a file handle advances the cursor. File handles may be 
<a id="--tech-term-buffered"></a>
buffered, which means that reading from a file handle may not return the current contents of the persistent data, and writing to a file handle may not modify them immediately.

  Paths

Files are primarily accessed via 
<a id="--tech-term-paths"></a>
*paths* (`System.FilePath`). A path is a sequence of directory names, potentially terminated by a file name. They are represented by strings in which separator characters The current platform's separator characters are listed in `System.FilePath.pathSeparators`. delimit the names.

The details of paths are platform-specific. 
<a id="--tech-term-Absolute-paths"></a>
Absolute paths begin in a 
<a id="--tech-term-root-directory"></a>
*root directory*; some operating systems have a single root, while others may have multiple root directories. Relative paths do not begin in a root directory and require that some other directory be taken as a starting point. In addition to directories, paths may contain the special directory names `.`, which refers to the directory in which it is found, and `..`, which refers to prior directory in the path.

Filenames, and thus paths, may end in one or more 
<a id="--tech-term-extensions"></a>
*extensions* that identify the file's type. Extensions are delimited by the character `System.FilePath.extSeparator`. On some platforms, executable files have a special extension (`System.FilePath.exeExtension`).

<a id="--tech-term-Streams"></a>
Streams

Streams are a higher-level abstraction over files, both providing additional functionality and hiding some details of files. While [file handles](index.md#--tech-term-File-Handles) are essentially a thin wrapper around the operating system's representation, streams are implemented in Lean as a structure called `IO.FS.Stream`. Because streams are implemented in Lean, user code can create additional streams, which can be used seamlessly together with those provided in the standard library.

<a id="The-Lean-Language-Reference--IO--Files___-File-Handles___-and-Streams--Low-Level-File-API"></a>
### 21.5.1. Low-Level File API

At the lowest level, files are explicitly opened using `Handle.mk`. When the last reference to the handle object is dropped, the file is closed. There is no explicit way to close a file handle other than by ensuring that there are no references to it.

<a id="IO___FS___Handle"></a>

**opaque**

```text
IO.FS.Handle : Type
```

A reference to an opened file.

File handles wrap the underlying operating system's file descriptors. There is no explicit operation to close a file: when the last reference to a file handle is dropped, the file is closed automatically.

Handles have an associated read/write cursor that determines where reads and writes occur in the file.

<a id="IO___FS___Handle___mk"></a>

**opaque**

```text
IO.FS.Handle.mk (fn : System.FilePath) (mode : IO.FS.Mode) :
  IO IO.FS.Handle
```

Opens the file at `fn` with the given `mode`.

An exception is thrown if the file cannot be opened.

<a id="IO___FS___Mode___read"></a>

**inductive type**

```text
IO.FS.Mode : Type
```

Whether a file should be opened for reading, writing, creation and writing, or appending.

At the operating system level, this translates to the mode of a file handle (i.e., a set of `open` flags and an `fdopen` mode).

None of the modes represented by this datatype translate line endings (i.e. `O_BINARY` on Windows). Furthermore, they are not inherited across process creation (i.e. `O_NOINHERIT` on Windows and `O_CLOEXEC` elsewhere).

**Operating System Specifics:**

- Windows: [`_open`](https://learn.microsoft.com/en-us/cpp/c-runtime-library/reference/open-wopen?view=msvc-170), [`_fdopen`](https://learn.microsoft.com/en-us/cpp/c-runtime-library/reference/fdopen-wfdopen?view=msvc-170)
- Linux: [`open`](https://linux.die.net/man/2/open), [`fdopen`](https://linux.die.net/man/3/fdopen)

**Constructors**

```text
IO.FS.Mode.read : IO.FS.Mode
```

The file should be opened for reading.

The read/write cursor is positioned at the beginning of the file. It is an error if the file does not exist.

- `open` flags: `O_RDONLY`
- `fdopen` mode: `r`

```text
IO.FS.Mode.write : IO.FS.Mode
```

The file should be opened for writing.

If the file already exists, it is truncated to zero length. Otherwise, a new file is created. The read/write cursor is positioned at the beginning of the file.

- `open` flags: `O_WRONLY | O_CREAT | O_TRUNC`
- `fdopen` mode: `w`

```text
IO.FS.Mode.writeNew : IO.FS.Mode
```

A new file should be created for writing.

It is an error if the file already exists. A new file is created, with the read/write cursor positioned at the start.

- `open` flags: `O_WRONLY | O_CREAT | O_TRUNC | O_EXCL`
- `fdopen` mode: `w`

```text
IO.FS.Mode.readWrite : IO.FS.Mode
```

The file should be opened for both reading and writing.

It is an error if the file does not already exist. The read/write cursor is positioned at the start of the file.

- `open` flags: `O_RDWR`
- `fdopen` mode: `r+`

```text
IO.FS.Mode.append : IO.FS.Mode
```

The file should be opened for writing.

If the file does not already exist, it is created. If the file already exists, it is opened, and the read/write cursor is positioned at the end of the file.

- `open` flags: `O_WRONLY | O_CREAT | O_APPEND`
- `fdopen` mode: `a`

<a id="IO___FS___Handle___read"></a>

**opaque**

```text
IO.FS.Handle.read (h : IO.FS.Handle) (bytes : USize) : IO ByteArray
```

Reads up to the given number of bytes from the handle. If the returned array is empty, an end-of-file marker (EOF) has been reached.

Encountering an EOF does not close a handle. Subsequent reads may block and return more data.

<a id="IO___FS___Handle___readToEnd"></a>

**def**

```text
IO.FS.Handle.readToEnd (h : IO.FS.Handle) : IO String
```

Reads the entire remaining contents of the file handle as a UTF-8-encoded string. An exception is thrown if the contents are not valid UTF-8.

The underlying file is not automatically closed, and subsequent reads from the handle may block and/or return data.

<a id="IO___FS___Handle___readBinToEnd"></a>

**def**

```text
IO.FS.Handle.readBinToEnd (h : IO.FS.Handle) : IO ByteArray
```

Reads the entire remaining contents of the file handle until an end-of-file marker (EOF) is encountered.

The underlying file is not automatically closed upon encountering an EOF, and subsequent reads from the handle may block and/or return data.

<a id="IO___FS___Handle___readBinToEndInto"></a>

**def**

```text
IO.FS.Handle.readBinToEndInto (h : IO.FS.Handle) (buf : ByteArray) :
  IO ByteArray
```

Reads the entire remaining contents of the file handle until an end-of-file marker (EOF) is encountered.

The underlying file is not automatically closed upon encountering an EOF, and subsequent reads from the handle may block and/or return data.

<a id="IO___FS___Handle___getLine"></a>

**opaque**

```text
IO.FS.Handle.getLine (h : IO.FS.Handle) : IO String
```

Reads UTF-8-encoded text up to and including the next line break from the handle. If the returned string is empty, an end-of-file marker (EOF) has been reached.

Encountering an EOF does not close a handle. Subsequent reads may block and return more data.

<a id="IO___FS___Handle___write"></a>

**opaque**

```text
IO.FS.Handle.write (h : IO.FS.Handle) (buffer : ByteArray) : IO Unit
```

Writes the provided bytes to the handle.

Writing to a handle is typically buffered, and may not immediately modify the file on disk. Use `IO.FS.Handle.flush` to write changes to buffers to the associated device.

<a id="IO___FS___Handle___putStr"></a>

**opaque**

```text
IO.FS.Handle.putStr (h : IO.FS.Handle) (s : String) : IO Unit
```

Writes the provided string to the file handle using the UTF-8 encoding.

Writing to a handle is typically buffered, and may not immediately modify the file on disk. Use `IO.FS.Handle.flush` to write changes to buffers to the associated device.

<a id="IO___FS___Handle___putStrLn"></a>

**def**

```text
IO.FS.Handle.putStrLn (h : IO.FS.Handle) (s : String) : IO Unit
```

Writes the contents of the string to the handle, followed by a newline. Uses UTF-8.

<a id="IO___FS___Handle___flush"></a>

**opaque**

```text
IO.FS.Handle.flush (h : IO.FS.Handle) : IO Unit
```

Flushes the output buffer associated with the handle, writing any unwritten data to the associated output device.

<a id="IO___FS___Handle___rewind"></a>

**opaque**

```text
IO.FS.Handle.rewind (h : IO.FS.Handle) : IO Unit
```

Rewinds the read/write cursor to the beginning of the handle's file.

<a id="IO___FS___Handle___truncate"></a>

**opaque**

```text
IO.FS.Handle.truncate (h : IO.FS.Handle) : IO Unit
```

Truncates the handle to its read/write cursor.

This operation does not automatically flush output buffers, so the contents of the output device may not reflect the change immediately. This does not usually lead to problems because the read/write cursor includes buffered writes. However, buffered writes followed by `IO.FS.Handle.rewind`, then `IO.FS.Handle.truncate`, and then closing the file may lead to a non-empty file. If unsure, call `IO.FS.Handle.flush` before truncating.

<a id="IO___FS___Handle___isTty"></a>

**opaque**

```text
IO.FS.Handle.isTty (h : IO.FS.Handle) : BaseIO Bool
```

Returns `true` if a handle refers to a Windows console or a Unix terminal.

<a id="IO___FS___Handle___lock"></a>

**opaque**

```text
IO.FS.Handle.lock (h : IO.FS.Handle) (exclusive : Bool := true) :
  IO Unit
```

Acquires an exclusive or shared lock on the handle. Blocks to wait for the lock if necessary.

Acquiring an exclusive lock while already possessing a shared lock will **not** reliably succeed: it works on Unix-like systems but not on Windows.

<a id="IO___FS___Handle___tryLock"></a>

**opaque**

```text
IO.FS.Handle.tryLock (h : IO.FS.Handle) (exclusive : Bool := true) :
  IO Bool
```

Tries to acquire an exclusive or shared lock on the handle and returns `true` if successful. Will not block if the lock cannot be acquired, but instead returns `false`.

Acquiring an exclusive lock while already possessing a shared lock will **not** reliably succeed: it works on Unix-like systems but not on Windows.

<a id="IO___FS___Handle___unlock"></a>

**opaque**

```text
IO.FS.Handle.unlock (h : IO.FS.Handle) : IO Unit
```

Releases any previously-acquired lock on the handle. Succeeds even if no lock has been acquired.

<a id="One-File___-Multiple-Handles"></a>
One File, Multiple Handles 

This program has two handles to the same file. Because file I/O may be buffered independently for each handle, `Handle.flush` should be called when the buffers need to be synchronized with the file's actual contents. Here, the two handles proceed in lock-step through the file, with one of them a single byte ahead of the other. The first handle is used to count the number of occurrences of `'A'`, while the second is used to replace each `'A'` with `'!'`. The second handle is opened in `readWrite` mode rather than `write` mode because opening an existing file in `write` mode replaces it with an empty file. In this case, the buffers don't need to be flushed during execution because modifications occur only to parts of the file that will not be read again, but the write handle should be flushed after the loop has completed.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="main-_LPAR_in-One-File___-Multiple-Handles_RPAR_"></a>


```proofscript
open IO.FS (Handle)

const main : IO Unit := do
  IO.println s!"Starting contents: '{(← IO.FS.readFile "data").trimAscii}'"

  let h ← Handle.mk "data" .read
  let h' ← Handle.mk "data" .readWrite
  h'.rewind

  let mut count := 0
  let mut buf : ByteArray ← h.read 1
  while ok : buf.size = 1 do
    if Char.ofUInt8 buf[0] == 'A' then
      count := count + 1
      h'.write (ByteArray.empty.push '!'.toUInt8)
    else
      h'.write buf
    buf ← h.read 1

  h'.flush

  IO.println s!"Count: {count}"
  IO.println s!"Contents: '{(← IO.FS.readFile "data").trimAscii}'"
```

When run on this file:

  Input: `data``AABAABCDAB` 

the program outputs:

  `stdout``Starting contents: 'AABAABCDAB'``Count: 5``Contents: '!!B!!BCD!B'` 

Afterwards, the file contains:

  Output: `data``!!B!!BCD!B`    

<a id="The-Lean-Language-Reference--IO--Files___-File-Handles___-and-Streams--Streams"></a>
### 21.5.2. Streams

<a id="IO___FS___Stream___mk"></a>

**structure**

```text
IO.FS.Stream : Type
```

A pure-Lean abstraction of POSIX streams. These streams may represent an underlying POSIX stream or be implemented by Lean code.

Because standard input, standard output, and standard error are all `IO.FS.Stream`s that can be overridden, Lean code may capture and redirect input and output.

**Constructor**

```text
IO.FS.Stream.mk
```

**Fields**

```text
flush : IO Unit
```

Flushes the stream's output buffers.

```text
read : USize → IO ByteArray
```

Reads up to the given number of bytes from the stream.

If the returned array is empty, an end-of-file marker (EOF) has been reached. An EOF does not actually close a stream, so further reads may block and return more data.

```text
write : ByteArray → IO Unit
```

Writes the provided bytes to the stream.

If the stream represents a physical output device such as a file on disk, then the results may be buffered. Call `FS.Stream.flush` to synchronize their contents.

```text
getLine : IO String
```

Reads text up to and including the next newline from the stream.

If the returned string is empty, an end-of-file marker (EOF) has been reached. An EOF does not actually close a stream, so further reads may block and return more data.

```text
putStr : String → IO Unit
```

Writes the provided string to the stream.

```text
isTty : BaseIO Bool
```

Returns `true` if a stream refers to a Windows console or Unix terminal.

<a id="IO___FS___Stream___ofBuffer"></a>

**def**

```text
IO.FS.Stream.ofBuffer (r : IO.Ref IO.FS.Stream.Buffer) : IO.FS.Stream
```

Creates a stream from a mutable reference to a buffer.

The resulting stream simulates a file, mutating the contents of the reference in response to writes and reading from it in response to reads. These streams can be used with `IO.withStdin`, `IO.setStdin`, and the corresponding operators for standard output and standard error to redirect input and output.

<a id="IO___FS___Stream___ofHandle"></a>

**def**

```text
IO.FS.Stream.ofHandle (h : IO.FS.Handle) : IO.FS.Stream
```

Creates a Lean stream from a file handle. Each stream operation is implemented by the corresponding file handle operation.

<a id="IO___FS___Stream___putStrLn"></a>

**def**

```text
IO.FS.Stream.putStrLn (strm : IO.FS.Stream) (s : String) : IO Unit
```

Writes the contents of the string to the stream, followed by a newline.

<a id="IO___FS___Stream___Buffer___mk"></a>

**structure**

```text
IO.FS.Stream.Buffer : Type
```

A byte buffer that can simulate a file in memory.

Use `IO.FS.Stream.ofBuffer` to create a stream from a buffer.

**Constructor**

```text
IO.FS.Stream.Buffer.mk
```

**Fields**

```text
data : ByteArray
```

The contents of the buffer.

```text
pos : Nat
```

The read/write cursor's position in the buffer.

<a id="The-Lean-Language-Reference--IO--Files___-File-Handles___-and-Streams--Paths"></a>
### 21.5.3. Paths

Paths are represented by strings. Different platforms have different conventions for paths: some use slashes (`/`) as directory separators, others use backslashes (`\`). Some are case-sensitive, others are not. Different Unicode encodings and normal forms may be used to represent filenames, and some platforms consider filenames to be byte sequences rather than strings. A string that represents an [absolute path](index.md#--tech-term-Absolute-paths) on one system may not even be a valid path on another system.

To write Lean code that is as compatible as possible with multiple systems, it can be helpful to use Lean's path manipulation primitives instead of raw string manipulation. Helpers such as `System.FilePath.join` take platform-specific rules for absolute paths into account, `System.FilePath.pathSeparator` contains the appropriate path separator for the current platform, and `System.FilePath.exeExtension` contains any necessary extension for executable files. Avoid hard-coding these rules.

There is an instance of the `Div` type class for `FilePath` which allows the slash operator to be used to concatenate paths.

<a id="System___FilePath___mk"></a>

**structure**

```text
System.FilePath : Type
```

A path on the file system.

Paths consist of a sequence of directories followed by the name of a file or directory. They are delimited by a platform-dependent separator character (see `System.FilePath.pathSeparator`).

**Constructor**

```text
System.FilePath.mk
```

**Fields**

```text
toString : String
```

The string representation of the path.

<a id="System___mkFilePath"></a>

**def**

```text
System.mkFilePath (parts : List String) : System.FilePath
```

Constructs a path from a list of file names by interspersing them with the current platform's path separator.

<a id="System___FilePath___join"></a>

**def**

```text
System.FilePath.join (p sub : System.FilePath) : System.FilePath
```

Appends two paths, taking absolute paths into account. This operation is also accessible via the `/` operator.

If `sub` is an absolute path, then `p` is discarded and `sub` is returned. If `sub` is a relative path, then it is attached to `p` with the platform-specific path separator.

<a id="System___FilePath___normalize"></a>

**def**

```text
System.FilePath.normalize (p : System.FilePath) : System.FilePath
```

Normalizes a path, returning an equivalent path that may better follow platform conventions.

In particular:

- On Windows, drive letters are made uppercase.
- On platforms that support multiple path separators (that is, where `System.FilePath.pathSeparators` has length greater than one), alternative path separators are replaced with the preferred path separator.

There is no guarantee that two equivalent paths normalize to the same path.

<a id="System___FilePath___isAbsolute"></a>

**def**

```text
System.FilePath.isAbsolute (p : System.FilePath) : Bool
```

An absolute path starts at the root directory or a drive letter. Accessing files through an absolute path does not depend on the current working directory.

<a id="System___FilePath___isRelative"></a>

**def**

```text
System.FilePath.isRelative (p : System.FilePath) : Bool
```

A relative path is one that depends on the current working directory for interpretation. Relative paths do not start with the root directory or a drive letter.

<a id="System___FilePath___parent"></a>

**def**

```text
System.FilePath.parent (p : System.FilePath) : Option System.FilePath
```

Returns the parent directory of a path, if there is one.

If the path is that of the root directory or the root of a drive letter, `none` is returned. Otherwise, the path's parent directory is returned.

<a id="System___FilePath___components"></a>

**def**

```text
System.FilePath.components (p : System.FilePath) : List String
```

Splits a path into a list of individual file names at the platform-specific path separator.

<a id="System___FilePath___fileName"></a>

**def**

```text
System.FilePath.fileName (p : System.FilePath) : Option String
```

Extracts the last element of a path if it is a file or directory name.

Returns `none` if the last entry is a special name (such as `.` or `..`) or if the path is the root directory.

<a id="System___FilePath___fileStem"></a>

**def**

```text
System.FilePath.fileStem (p : System.FilePath) : Option String
```

Extracts the stem (non-extension) part of `p.fileName`.

If the filename contains multiple extensions, then only the last one is removed. Returns `none` if there is no file name at the end of the path.

Examples:

- `("app.exe" : System.FilePath).fileStem = some "app"`
- `("file.tar.gz" : System.FilePath).fileStem = some "file.tar"`
- `("files/" : System.FilePath).fileStem = none`
- `("files/picture.jpg" : System.FilePath).fileStem = some "picture"`

<a id="System___FilePath___extension"></a>

**def**

```text
System.FilePath.extension (p : System.FilePath) : Option String
```

Extracts the extension part of `p.fileName`.

If the filename contains multiple extensions, then only the last one is extracted. Returns `none` if there is no file name at the end of the path.

Examples:

- `("app.exe" : System.FilePath).extension = some "exe"`
- `("file.tar.gz" : System.FilePath).extension = some "gz"`
- `("files/" : System.FilePath).extension = none`
- `("files/picture.jpg" : System.FilePath).extension = some "jpg"`

<a id="System___FilePath___addExtension"></a>

**def**

```text
System.FilePath.addExtension (p : System.FilePath) (ext : String) :
  System.FilePath
```

Appends the extension `ext` to a path `p`.

`ext` should not have leading `.`, as this function adds one. If `ext` is the empty string, no `.` is added.

Unlike `System.FilePath.withExtension`, this does not remove any existing extension.

<a id="System___FilePath___withExtension"></a>

**def**

```text
System.FilePath.withExtension (p : System.FilePath) (ext : String) :
  System.FilePath
```

Replaces the current extension in a path `p` with `ext`, adding it if there is no extension. If the path has multiple file extensions, only the last one is replaced. If the path has no filename, or if `ext` is the empty string, then the filename is returned unmodified.

`ext` should not have a leading `.`, as this function adds one.

Examples:

- `("files/picture.jpeg" : System.FilePath).withExtension "jpg" = ⟨"files/picture.jpg"⟩`
- `("files/" : System.FilePath).withExtension "zip" = ⟨"files/"⟩`
- `("files" : System.FilePath).withExtension "zip" = ⟨"files.zip"⟩`
- `("files/archive.tar.gz" : System.FilePath).withExtension "xz" = ⟨"files.tar.xz"⟩`

<a id="System___FilePath___withFileName"></a>

**def**

```text
System.FilePath.withFileName (p : System.FilePath) (fname : String) :
  System.FilePath
```

Replaces the file name at the end of the path `p` with `fname`, placing `fname` in the parent directory of `p`.

If `p` has no parent directory, then `fname` is returned unmodified.

<a id="System___FilePath___pathSeparator"></a>

**def**

```text
System.FilePath.pathSeparator : Char
```

The character that separates directories.

On platforms that support multiple separators, `System.FilePath.pathSeparator` is the “ideal” one expected by users on the platform. `System.FilePath.pathSeparators` lists all supported separators.

<a id="System___FilePath___pathSeparators"></a>

**def**

```text
System.FilePath.pathSeparators : List Char
```

The list of all path separator characters supported on the current platform.

On platforms that support multiple separators, `System.FilePath.pathSeparator` is the “ideal” one expected by users on the platform.

<a id="System___FilePath___extSeparator"></a>

**def**

```text
System.FilePath.extSeparator : Char
```

The character that separates file extensions from file names.

<a id="System___FilePath___exeExtension"></a>

**def**

```text
System.FilePath.exeExtension : String
```

The file extension expected for executable binaries on the current platform, or `""` if there is no such extension.

<a id="The-Lean-Language-Reference--IO--Files___-File-Handles___-and-Streams--Interacting-with-the-Filesystem"></a>
### 21.5.4. Interacting with the Filesystem

Some operations on paths consult the filesystem.

<a id="IO___FS___Metadata___mk"></a>

**structure**

```text
IO.FS.Metadata : Type
```

File metadata.

The metadata for a file can be accessed with `System.FilePath.metadata`/ `System.FilePath.symlinkMetadata`.

**Constructor**

```text
IO.FS.Metadata.mk
```

**Fields**

```text
accessed : IO.FS.SystemTime
```

File access time.

```text
modified : IO.FS.SystemTime
```

File modification time.

```text
byteSize : UInt64
```

The size of the file in bytes.

```text
type : IO.FS.FileType
```

Whether the file is an ordinary file, a directory, a symbolic link, or some other kind of file.

```text
numLinks : UInt64
```

The number of hard links to the file.

<a id="System___FilePath___metadata"></a>

**opaque**

```text
System.FilePath.metadata : System.FilePath → IO IO.FS.Metadata
```

Returns metadata for the indicated file, following symlinks. Throws an exception if the file does not exist or the metadata cannot be accessed.

<a id="System___FilePath___symlinkMetadata"></a>

**opaque**

```text
System.FilePath.symlinkMetadata : System.FilePath → IO IO.FS.Metadata
```

Returns metadata for the indicated file without following symlinks. Throws an exception if the file does not exist or the metadata cannot be accessed.

<a id="System___FilePath___pathExists"></a>

**def**

```text
System.FilePath.pathExists (p : System.FilePath) : BaseIO Bool
```

Checks whether the indicated path points to a file that exists. This function will traverse symlinks.

<a id="System___FilePath___isDir"></a>

**def**

```text
System.FilePath.isDir (p : System.FilePath) : BaseIO Bool
```

Checks whether the indicated path can be read and is a directory. This function will traverse symlinks.

<a id="IO___FS___DirEntry___mk"></a>

**structure**

```text
IO.FS.DirEntry : Type
```

An entry in a directory on a filesystem.

**Constructor**

```text
IO.FS.DirEntry.mk
```

**Fields**

```text
root : System.FilePath
```

The directory in which the entry is found.

```text
fileName : String
```

The name of the entry.

<a id="IO___FS___DirEntry___path"></a>

**def**

```text
IO.FS.DirEntry.path (entry : IO.FS.DirEntry) : System.FilePath
```

The path of the file indicated by the directory entry.

<a id="System___FilePath___readDir"></a>

**opaque**

```text
System.FilePath.readDir : System.FilePath → IO (Array IO.FS.DirEntry)
```

Returns the contents of the indicated directory. Throws an exception if the file does not exist or is not a directory.

<a id="System___FilePath___walkDir"></a>

**def**

```text
System.FilePath.walkDir (p : System.FilePath)
  (enter : System.FilePath → IO Bool := fun x => pure true) :
  IO (Array System.FilePath)
```

Traverses a filesystem starting at the path `p` and exploring directories that satisfy `enter`, returning the paths visited.

The traversal is a preorder traversal, in which parent directories occur prior to any of their children. Symbolic links are followed.

<a id="IO___AccessRight___mk"></a>

**structure**

```text
IO.AccessRight : Type
```

POSIX-style file permissions.

The `FileRight` structure describes these permissions for a file's owner, members of its designated group, and all others.

**Constructor**

```text
IO.AccessRight.mk
```

**Fields**

```text
read : Bool
```

The file can be read.

```text
write : Bool
```

The file can be written to.

```text
execution : Bool
```

The file can be executed.

<a id="IO___AccessRight___flags"></a>

**def**

```text
IO.AccessRight.flags (acc : IO.AccessRight) : UInt32
```

Converts individual POSIX-style file permissions to their conventional three-bit representation.

This is the bitwise `or` of the following:

- If the file can be read, `0x4`, otherwise `0`.
- If the file can be written, `0x2`, otherwise `0`.
- If the file can be executed, `0x1`, otherwise `0`.

Examples:

- `{read := true : AccessRight}.flags = 4`
- `{read := true, write := true : AccessRight}.flags = 6`
- `{read := true, execution := true : AccessRight}.flags = 5`

<a id="IO___FileRight___mk"></a>

**structure**

```text
IO.FileRight : Type
```

POSIX-style file permissions that describe access rights for a file's owner, members of its assigned group, and all others.

**Constructor**

```text
IO.FileRight.mk
```

**Fields**

```text
user : IO.AccessRight
```

The owner's permissions to access the file.

```text
group : IO.AccessRight
```

The assigned group's permissions to access the file.

```text
other : IO.AccessRight
```

The permissions that all others have to access the file.

<a id="IO___FileRight___flags"></a>

**def**

```text
IO.FileRight.flags (acc : IO.FileRight) : UInt32
```

Converts POSIX-style file permissions to their numeric representation, with three bits each for the owner's permissions, the group's permissions, and others' permissions.

<a id="IO___setAccessRights"></a>

**def**

```text
IO.setAccessRights (filename : System.FilePath) (mode : IO.FileRight) :
  IO Unit
```

Sets the POSIX-style permissions for a file.

<a id="IO___FS___removeFile"></a>

**opaque**

```text
IO.FS.removeFile (fname : System.FilePath) : IO Unit
```

Removes (deletes) a file from the filesystem.

To remove a directory, use `IO.FS.removeDir` or `IO.FS.removeDirAll` instead.

<a id="IO___FS___rename"></a>

**opaque**

```text
IO.FS.rename (old new : System.FilePath) : IO Unit
```

Moves a file or directory `old` to the new location `new`.

This function coincides with the [POSIX `rename` function](https://pubs.opengroup.org/onlinepubs/9699919799/functions/rename.html).

<a id="IO___FS___removeDir"></a>

**opaque**

```text
IO.FS.removeDir : System.FilePath → IO Unit
```

Removes (deletes) a directory.

Removing a directory fails if the directory is not empty. Use `IO.FS.removeDirAll` to remove directories along with their contents.

<a id="IO___FS___lines"></a>

**def**

```text
IO.FS.lines (fname : System.FilePath) : IO (Array String)
```

Returns the contents of a UTF-8-encoded text file as an array of lines.

Newline markers are not included in the lines.

<a id="IO___FS___withTempFile"></a>

**def**

```text
IO.FS.withTempFile.{u_1} {m : Type → Type u_1} {α : Type} [Monad m]
  [MonadFinally m] [MonadLiftT IO m]
  (f : IO.FS.Handle → System.FilePath → m α) : m α
```

Creates a temporary file in the most secure manner possible and calls `f` with both a `Handle` to the already-opened file and its path. Afterwards, the temporary file is deleted.

There are no race conditions in the file’s creation. The file is readable and writable only by the creating user ID. Additionally on UNIX style platforms the file is executable by nobody.

Use `IO.FS.createTempFile` to avoid the automatic deletion of the temporary file.

<a id="IO___FS___withTempDir"></a>

**def**

```text
IO.FS.withTempDir.{u_1} {m : Type → Type u_1} {α : Type} [Monad m]
  [MonadFinally m] [MonadLiftT IO m] (f : System.FilePath → m α) : m α
```

Creates a temporary directory in the most secure manner possible, providing its path to an `IO` action. Afterwards, all files in the temporary directory are recursively deleted, regardless of how or when they were created.

There are no race conditions in the directory’s creation. The directory is readable and writable only by the creating user ID. Use `IO.FS.createTempDir` to avoid the automatic deletion of the directory's contents.

<a id="IO___FS___createDirAll"></a>

**opaque**

```text
IO.FS.createDirAll (p : System.FilePath) : IO Unit
```

Creates a directory at the specified path, creating all missing parents as directories.

<a id="IO___FS___writeBinFile"></a>

**def**

```text
IO.FS.writeBinFile (fname : System.FilePath) (content : ByteArray) :
  IO Unit
```

Write the provided bytes to a binary file at the specified path.

<a id="IO___FS___withFile"></a>

**def**

```text
IO.FS.withFile {α : Type} (fn : System.FilePath) (mode : IO.FS.Mode)
  (f : IO.FS.Handle → IO α) : IO α
```

Opens the file `fn` with the specified `mode` and passes the resulting file handle to `f`.

The file handle is closed when the last reference to it is dropped. If references escape `f`, then the file remains open even after `IO.FS.withFile` has finished.

<a id="IO___FS___removeDirAll"></a>

**opaque**

```text
IO.FS.removeDirAll (p : System.FilePath) : IO Unit
```

Fully remove given directory by deleting all contained files and directories in an unspecified order. Symlinks are deleted but not followed. Fails if any contained entry cannot be deleted or was newly created during execution.

<a id="IO___FS___createTempFile"></a>

**opaque**

```text
IO.FS.createTempFile : IO (IO.FS.Handle × System.FilePath)
```

Creates a temporary file in the most secure manner possible, returning both a `Handle` to the already-opened file and its path.

There are no race conditions in the file’s creation. The file is readable and writable only by the creating user ID. Additionally on UNIX style platforms the file is executable by nobody.

It is the caller's job to remove the file after use. Use `withTempFile` to ensure that the temporary file is removed.

<a id="IO___FS___createTempDir"></a>

**opaque**

```text
IO.FS.createTempDir : IO System.FilePath
```

Creates a temporary directory in the most secure manner possible, returning the new directory's path. There are no race conditions in the directory’s creation. The directory is readable and writable only by the creating user ID.

It is the caller's job to remove the directory after use. Use `withTempDir` to ensure that the temporary directory is removed.

<a id="IO___FS___readFile"></a>

**def**

```text
IO.FS.readFile (fname : System.FilePath) : IO String
```

Reads the entire contents of the UTF-8-encoded file at the given path as a `String`.

An exception is thrown if the contents of the file are not valid UTF-8. This is in addition to exceptions that may always be thrown as a result of failing to read files.

<a id="IO___FS___realPath"></a>

**opaque**

```text
IO.FS.realPath (fname : System.FilePath) : IO System.FilePath
```

Resolves a path to an absolute path that contains no '.', '..', or symbolic links.

This function coincides with the [POSIX `realpath` function](https://pubs.opengroup.org/onlinepubs/9699919799/functions/realpath.html).

<a id="IO___FS___writeFile"></a>

**def**

```text
IO.FS.writeFile (fname : System.FilePath) (content : String) : IO Unit
```

Write contents of a string to a file at the specified path using UTF-8 encoding.

<a id="IO___FS___readBinFile"></a>

**def**

```text
IO.FS.readBinFile (fname : System.FilePath) : IO ByteArray
```

Reads the entire contents of the binary file at the given path as an array of bytes.

<a id="IO___FS___createDir"></a>

**opaque**

```text
IO.FS.createDir : System.FilePath → IO Unit
```

Creates a directory at the specified path. The parent directory must already exist.

Throws an exception if the directory cannot be created.

<a id="stdio"></a>
### 21.5.5. Standard I/O

On operating systems that are derived from or inspired by Unix, 
<a id="--tech-term-standard-input"></a>
*standard input*, 
<a id="--tech-term-standard-output"></a>
*standard output*, and 
<a id="--tech-term-standard-error"></a>
*standard error* are the names of three streams that are available in each process. Generally, programs are expected to read from standard input, write ordinary output to the standard output, and error messages to the standard error. By default, standard input receives input from the console, while standard output and standard error output to the console, but all three are often redirected to or from pipes or files.

Rather than providing direct access to the operating system's standard I/O facilities, Lean wraps them in `Stream`s. Additionally, the `IO` monad contains special support for replacing or locally overriding them. This extra level of indirection makes it possible to redirect input and output within a Lean program.

<a id="IO___getStdin"></a>

**opaque**

```text
IO.getStdin : BaseIO IO.FS.Stream
```

Returns the current thread's standard input stream.

Use `IO.setStdin` to replace the current thread's standard input stream.

<a id="Reading-from-Standard-Input"></a>
Reading from Standard Input 

In this example, `IO.getStdin` and `IO.getStdout` are used to get the current standard input and output, respectively. These can be read from and written to.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="main-_LPAR_in-Reading-from-Standard-Input_RPAR_"></a>


```proofscript
const main : IO Unit := do
  let stdin ← IO.getStdin
  let stdout ← IO.getStdout
  stdout.putStrLn "Who is it?"
  let name ← stdin.getLine
  stdout.putStr "Hello, "
  stdout.putStrLn name
```

With this standard input:

  `stdin``Lean user` 

the standard output is:

  `stdout``Who is it?``Hello, Lean user`  
<a id="IO___setStdin"></a>

**opaque**

```text
IO.setStdin : IO.FS.Stream → BaseIO IO.FS.Stream
```

Replaces the standard input stream of the current thread and returns its previous value.

Use `IO.getStdin` to get the current standard input stream.

<a id="IO___withStdin"></a>

**def**

```text
IO.withStdin.{u_1} {m : Type → Type u_1} {α : Type} [Monad m]
  [MonadFinally m] [MonadLiftT BaseIO m] (h : IO.FS.Stream) (x : m α) :
  m α
```

Runs an action with the specified stream `h` as standard input, restoring the original standard input stream afterwards.

<a id="IO___getStdout"></a>

**opaque**

```text
IO.getStdout : BaseIO IO.FS.Stream
```

Returns the current thread's standard output stream.

Use `IO.setStdout` to replace the current thread's standard output stream.

<a id="IO___setStdout"></a>

**opaque**

```text
IO.setStdout : IO.FS.Stream → BaseIO IO.FS.Stream
```

Replaces the standard output stream of the current thread and returns its previous value.

Use `IO.getStdout` to get the current standard output stream.

<a id="IO___withStdout"></a>

**def**

```text
IO.withStdout.{u_1} {m : Type → Type u_1} {α : Type} [Monad m]
  [MonadFinally m] [MonadLiftT BaseIO m] (h : IO.FS.Stream) (x : m α) :
  m α
```

Runs an action with the specified stream `h` as standard output, restoring the original standard output stream afterwards.

<a id="IO___getStderr"></a>

**opaque**

```text
IO.getStderr : BaseIO IO.FS.Stream
```

Returns the current thread's standard error stream.

Use `IO.setStderr` to replace the current thread's standard error stream.

<a id="IO___setStderr"></a>

**opaque**

```text
IO.setStderr : IO.FS.Stream → BaseIO IO.FS.Stream
```

Replaces the standard error stream of the current thread and returns its previous value.

Use `IO.getStderr` to get the current standard error stream.

<a id="IO___withStderr"></a>

**def**

```text
IO.withStderr.{u_1} {m : Type → Type u_1} {α : Type} [Monad m]
  [MonadFinally m] [MonadLiftT BaseIO m] (h : IO.FS.Stream) (x : m α) :
  m α
```

Runs an action with the specified stream `h` as standard error, restoring the original standard error stream afterwards.

<a id="IO___FS___withIsolatedStreams"></a>

**def**

```text
IO.FS.withIsolatedStreams.{u_1} {m : Type → Type u_1} {α : Type}
  [Monad m] [MonadFinally m] [MonadLiftT BaseIO m] (x : m α)
  (isolateStderr : Bool := true) : m (String × α)
```

Runs an action with `stdin` emptied and `stdout` and `stderr` captured into a `String`. If `isolateStderr` is `false`, only `stdout` is captured.

<a id="Redirecting-Standard-I___O-to-Strings"></a>
Redirecting Standard I/O to Strings 

The `countdown` function counts down from a specified number, writing its progress to standard output. Using `IO.FS.withIsolatedStreams`, this output can be redirected to a string.

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="countdown-_LPAR_in-Redirecting-Standard-I___O-to-Strings_RPAR_"></a>
<a id="runCountdown-_LPAR_in-Redirecting-Standard-I___O-to-Strings_RPAR_"></a>


```proofscript
def countdown : Nat → IO Unit
  | 0 =>
    IO.println "Blastoff!"
  | n + 1 => do
    IO.println s!"{n + 1}"
    countdown n

const runCountdown : IO String := do
  let (output, ()) ← IO.FS.withIsolatedStreams (countdown 10)
  return output

#eval runCountdown
```

Running `countdown` yields a string that contains the output:

```lean
"10\n9\n8\n7\n6\n5\n4\n3\n2\n1\nBlastoff!\n"
```

<a id="The-Lean-Language-Reference--IO--Files___-File-Handles___-and-Streams--Files-and-Directories"></a>
### 21.5.6. Files and Directories

<a id="IO___currentDir"></a>

**opaque**

```text
IO.currentDir : IO System.FilePath
```

Returns the current working directory of the executing process.

<a id="IO___appPath"></a>

**opaque**

```text
IO.appPath : IO System.FilePath
```

Returns the file name of the currently-running executable.

<a id="IO___appDir"></a>

**def**

```text
IO.appDir : IO System.FilePath
```

Returns the directory that the current executable is located in.

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
"10\n9\n8\n7\n6\n5\n4\n3\n2\n1\nBlastoff!\n"
```

