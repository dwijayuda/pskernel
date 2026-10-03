<a id="reference-counting"></a>

# ProofScript — 12.2. Reference Counting

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

The inherited chapter describes Lean runtime mechanisms such as boxing, reference counting, threading and the native foreign-function ABI. Those are not automatic properties of JavaScript or Wasm output. ProofScript backends may choose different representations only under their stated preservation relation. An optimized or external implementation can disagree with its logical definition while the logical theorem remains valid; executable assurance must account for that gap.

**Compiler and coverage boundary.** Keep C signatures and Lean ABI names unchanged and clearly classified as native-host documentation. Do not pretend that owning an emitter proves its runtime correct.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Run-Time-Code/Reference-Counting/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Run-Time-Code/Reference-Counting/index.html). Source Git blob: `6dca9e07aece952e5ea6ff35dd4dbc7fa0305952`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## 12.2. Reference Counting

Lean uses 
<a id="--tech-term-reference-counting"></a>
*reference counting* for memory management. Each allocated object maintains a count of how many other objects refer to it. When a new reference is added, the count is incremented, and when a reference is dropped, the count is decremented. When a reference count reaches zero, the object is no longer reachable and can play no part in the further execution of the program. It is deallocated and all of its references to other objects are dropped, which may trigger further deallocations.

Reference counting provides a number of benefits:

  Reuse of Memory

If an object's reference count drops to zero just as another of the same size is to be allocated, then the original object's memory can be safely reused for the new object. As a result, many common data-structure traversals (such as `List.map`) do not need to allocate memory when there is exactly one reference to the data structure to be traversed.

  Opportunistic In-Place Updates

Primitive types, such as [strings](../../Basic-Types/Strings/index.md#String) and [arrays](../../Basic-Types/Arrays/index.md#Array), may provide operations that copy shared data but modify unshared data in-place. As long as they hold the only reference to the value being modified, many operations on these primitive types will modify it rather than copy it. This can lead to substantial performance benefits. Carefully-written `Array` code avoids the performance overhead of immutable data structures while maintaining the ease of reasoning provided by pure functions.

  Predictability

Reference counts are decremented at predictable times. As a result, reference-counted objects can be used to manage other resources, such as file handles. In Lean, a `Handle` does not need to be explicitly closed because it is closed immediately when it is no longer accessible.

  Simpler FFI

Objects managed with reference counting don't need to be relocated as part of reclaiming unused memory. This greatly simplifies interaction with code written in other languages, such as C.

The traditional drawbacks of reference counting include the performance overhead due to updating reference counts along with the inability to recognize and deallocate cyclic data. The former drawback is minimized by an analysis based on *borrowing* that allows many reference count updates to be elided. Nevertheless, multi-threaded code requires that reference count updates are synchronized between threads, which also imposes a substantial overhead. To reduce this overhead, Lean values are partitioned into those which are reachable from multiple threads and those which are not. Single-threaded reference counts can be updated much faster than multi-threaded reference counts, and many values are accessed only on a single thread. Together, these techniques greatly reduce the performance overhead of reference counting. Because the verifiable fragment of Lean cannot create cyclic data, the Lean runtime does not have a technique to detect it. Ullrich and de Moura (2019)Sebastian Ullrich and Leonardo de Moura, 2019. [“Counting Immutable Beans: Reference Counting Optimized for Purely Functional Programming”](https://arxiv.org/abs/1908.05647). In *Proceedings of the 31st Symposium on Implementation and Application of Functional Languages (IFL 2019).* provide more details on the implementation of reference counting in Lean.

<a id="The-Lean-Language-Reference--Run-Time-Code--Reference-Counting--Observing-Uniqueness"></a>
### 12.2.1. Observing Uniqueness

Ensuring that arrays and strings are uniquely referenced is key to writing fast code in Lean. The primitive `dbgTraceIfShared` can be used to check whether a data structure is aliased. When called, it returns its argument unchanged, printing the provided trace message if the argument's reference count is greater than one.

<a id="dbgTraceIfShared"></a>

**def**

```text
dbgTraceIfShared.{u} {α : Type u} (s : String) (a : α) : α
```

Display the given message if `a` is shared, that is, RC(a) > 1

Due to the specifics of how [`#eval`](../../Interacting-with-Lean/index.md#Lean___Parser___Command___eval) is implemented, using `dbgTraceIfShared` with [`#eval`](../../Interacting-with-Lean/index.md#Lean___Parser___Command___eval) can be misleading. Instead, it should be used in code that's explicitly compiled and run.

<a id="Observing-Uniqueness"></a>
Observing Uniqueness 

This program reads a line of input from the user, printing it after replacing its first character with a space. Replacing characters in a string uses an in-place update if the string is not shared and the characters are both contained in the 7-bit ASCII subset of Unicode. The `dbgTraceIfShared` call does nothing, indicating that the string will indeed be updated in place rather than copied.
<a id="main"></a>


```lean
def process (str : String) (h : str.startPos ≠ str.endPos) : IO Unit := do
  IO.println ((dbgTraceIfShared "String update" str).startPos.set ' ' h)

def main : IO Unit := do
  let line := (← (← IO.getStdin).getLine).trimAscii.copy
  if h : line.startPos ≠ line.endPos then
    process line h
```

When run with this input:

  `stdin``Here is input.` 

the program emits:

  `stdout``ere is input.` 

with an empty standard error output:

  `stderr``<empty>` 

This version of the program retains a reference to the original string, which necessitates copying the string in the call to `String.set`. This fact is visible in its standard error output.

```lean
def process (str : String) (h : str.startPos ≠ str.endPos) : IO Unit := do
  IO.println ((dbgTraceIfShared "String update" str).startPos.set ' ' h)

def main : IO Unit := do
  let line := (← (← IO.getStdin).getLine).trimAscii.copy
  if h : line.startPos ≠ line.endPos then
    process line h
  IO.println "Original input:"
  IO.println line
```

When run with this input:

  `stdin``Here is input.` 

the program emits:

  `stdout``ere is input.``Original input:``Here is input.` 

In its standard error, the message passed to `dbgTraceIfShared` is visible.

  `stderr``shared RC String update`    

<a id="The-Lean-Language-Reference--Run-Time-Code--Reference-Counting--Compiler-IR"></a>
### 12.2.2. Compiler IR

The compiler option `trace.compiler.ir.result` can be used to inspect the compiler's intermediate representation (IR) for a function. In this intermediate representation, reference counting, allocation, and reuse are explicit:

- The `isShared` operator checks whether a reference count is `1`.
- `ctor_`n allocates the nth constructor of a type.
- `proj_`n retrieves the nth field from a constructor value.
- `set`x `[`n `]` mutates the nth field of the constructor in x.
- `ret`x returns the value in x.

The specifics of reference count manipulations can depend on the results of optimization passes such as inlining. While the vast majority of Lean code doesn't require this kind of attention to achieve good performance, knowing how to diagnose unique reference issues can be very important when writing performance-critical code.

<a id="trace___compiler___ir___result"></a>

**option**

```text
trace.compiler.ir.result
```

Default value: `false`

enable/disable tracing for the given module and submodules

<a id="Reference-Counts-in-IR"></a>
Reference Counts in IR 

Compiler IR can be used to observe when reference counts are incremented, which can help diagnose situations when a value is expected to have a unique incoming reference, but is in fact shared. Here, `process` and `process'` each take a string as a parameter and modify it with `String.set`, returning a pair of strings. While `process` returns a constant string as the second element of the pair, `process'` returns the original string.

```lean
set_option trace.compiler.ir.result true
```
<a id="process-_LPAR_in-Reference-Counts-in-IR_RPAR_"></a>


```lean
def process (str : String) : String × String :=
  (str.set 0 ' ', "")
```
<a id="process___-_LPAR_in-Reference-Counts-in-IR_RPAR_"></a>


```lean
def process' (str : String) : String × String:=
  (str.set 0 ' ', str)
```

The IR for `process` includes no `inc` or `dec` instructions. If the incoming string `x_1` is a unique reference, then it is still a unique reference when passed to `String.set`, which can then use in-place modification:

```lean
[Compiler.IR] [result]
    def process._closed_0 : obj :=
      let x_1 : obj := "";
      ret x_1
    def process (x_1 : obj) : obj :=
      let x_2 : tagged := 0;
      let x_3 : u32 := 32;
      let x_4 : obj := String.set x_1 x_2 x_3;
      let x_5 : obj := process._closed_0;
      inc x_5;
      let x_6 : obj := ctor_0[Prod.mk] x_4 x_5;
      ret x_6
```

The IR for `process'`, on the other hand, increments the reference count of the string just before calling `String.set`. Thus, the modified string `x_4` is a copy, regardless of whether the original reference to `x_1` is unique:

```lean
[Compiler.IR] [result]
    def process' (x_1 : obj) : obj :=
      let x_2 : tagged := 0;
      let x_3 : u32 := 32;
      inc x_1;
      let x_4 : obj := String.set x_1 x_2 x_3;
      let x_5 : obj := ctor_0[Prod.mk] x_4 x_1;
      ret x_5
```

<a id="Memory-Reuse-in-IR"></a>
Memory Reuse in IR 

The function `discardElems` is a simplified version of `List.map` that replaces every element in a list with `()`. Inspecting its intermediate representation demonstrates that it will reuse the list's memory when its reference is unique.
<a id="discardElems-_LPAR_in-Memory-Reuse-in-IR_RPAR_"></a>


```lean
set_option trace.compiler.ir.result true

def discardElems : List α → List Unit
  | [] => []
  | x :: xs => () :: discardElems xs
```

This emits the following IR:

```lean
[Compiler.IR] [result]
    def discardElems._redArg (x_1 : tobj) : tobj :=
      case x_1 : tobj of
      List.nil →
        let x_2 : tagged := ctor_0[List.nil];
        ret x_2
      List.cons →
        let x_3 : tobj := proj[1] x_1;
        block_4 (x_5 : tobj) (x_6 : u8) :=
          let x_7 : tagged := ctor_0[PUnit.unit];
          let x_8 : tobj := discardElems._redArg x_3;
          block_9 (x_10 : obj) :=
            ret x_10;
          case x_6 : u8 of
          Bool.false →
            set x_5[1] := x_8;
            set x_5[0] := x_7;
            jmp block_9 x_5
          Bool.true →
            let x_11 : obj := ctor_1[List.cons] x_7 x_8;
            jmp block_9 x_11;
        let x_12 : u8 := isShared x_1;
        case x_12 : u8 of
        Bool.false →
          let x_13 : tobj := proj[0] x_1;
          dec x_13;
          jmp block_4 x_1 x_12
        Bool.true →
          inc x_3;
          dec x_1;
          jmp block_4 ◾ x_12[Compiler.IR] [result]
    def discardElems (x_1 : ◾) (x_2 : tobj) : tobj :=
      let x_3 : tobj := discardElems._redArg x_2;
      ret x_3
```

In the IR, the `List.cons` case explicitly checks whether the argument value is shared (i.e. whether its reference count is greater than one). If the reference is unique, the reference count of the discarded list element `x_5` is decremented and the constructor value is reused. If it is shared, a new `List.cons` is allocated in `x_11` for the result.

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
[Compiler.IR] [result]
    def process._closed_0 : obj :=
      let x_1 : obj := "";
      ret x_1
    def process (x_1 : obj) : obj :=
      let x_2 : tagged := 0;
      let x_3 : u32 := 32;
      let x_4 : obj := String.set x_1 x_2 x_3;
      let x_5 : obj := process._closed_0;
      inc x_5;
      let x_6 : obj := ctor_0[Prod.mk] x_4 x_5;
      ret x_6
```


### Display 2


```text
`String.set` has been deprecated: Use `String.Pos.Raw.set` instead

Note: The updated constant is in a different namespace. Dot notation may need to be changed (e.g., from `x.set` to `String.Pos.Raw.set x`).
```


### Display 3


```text
[Compiler.IR] [result]
    def process' (x_1 : obj) : obj :=
      let x_2 : tagged := 0;
      let x_3 : u32 := 32;
      inc x_1;
      let x_4 : obj := String.set x_1 x_2 x_3;
      let x_5 : obj := ctor_0[Prod.mk] x_4 x_1;
      ret x_5
```


### Display 4


```text
[Compiler.IR] [result]
    def discardElems._redArg (x_1 : tobj) : tobj :=
      case x_1 : tobj of
      List.nil →
        let x_2 : tagged := ctor_0[List.nil];
        ret x_2
      List.cons →
        let x_3 : tobj := proj[1] x_1;
        block_4 (x_5 : tobj) (x_6 : u8) :=
          let x_7 : tagged := ctor_0[PUnit.unit];
          let x_8 : tobj := discardElems._redArg x_3;
          block_9 (x_10 : obj) :=
            ret x_10;
          case x_6 : u8 of
          Bool.false →
            set x_5[1] := x_8;
            set x_5[0] := x_7;
            jmp block_9 x_5
          Bool.true →
            let x_11 : obj := ctor_1[List.cons] x_7 x_8;
            jmp block_9 x_11;
        let x_12 : u8 := isShared x_1;
        case x_12 : u8 of
        Bool.false →
          let x_13 : tobj := proj[0] x_1;
          dec x_13;
          jmp block_4 x_1 x_12
        Bool.true →
          inc x_3;
          dec x_1;
          jmp block_4 ◾ x_12[Compiler.IR] [result]
    def discardElems (x_1 : ◾) (x_2 : tobj) : tobj :=
      let x_3 : tobj := discardElems._redArg x_2;
      ret x_3
```


### Display 5


```text
Variable name `x` is not explicitly referenced.

Hint: The binding can be removed (if unused) or named `_` (if used implicitly). Alternatively, prefix the name with `_` to silence this warning:
  [apply] _x

Note: This linter can be disabled with `set_option linter.unusedVariables false`
```

