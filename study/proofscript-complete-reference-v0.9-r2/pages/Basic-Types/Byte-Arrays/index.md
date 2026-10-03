<a id="ByteArray"></a>

# ProofScript — 20.17. Byte Arrays

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Nat, Int, machine integers, floats, characters, strings, bytes, options, products, sums, lists, arrays, maps, ranges, subtypes and lazy computations retain their distinct native contracts. A target representation is not their meaning. Nat subtraction saturates at zero; the selected Int quotient differs from JavaScript BigInt truncation for some negative inputs. String offsets and Unicode conversions require explicit mappings.

**Compiler and coverage boundary.** The full API entries below retain exact names and signature metadata. Distinguish a signature display from executable source. Unknown reachable primitives reject the requested executable profile.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Basic-Types/Byte-Arrays/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Basic-Types/Byte-Arrays/index.html). Source Git blob: `9baf9a990ef054dbd4824a4e169753d0e0e3968c`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 20.17. Byte Arrays

Byte arrays are a specialized array type that can only contain elements of type `UInt8`. Due to this restriction, they can use a much more efficient representation, with no pointer indirections. Like other arrays, byte arrays are represented in compiled code as [dynamic arrays](../Arrays/index.md#--tech-term-dynamic-arrays), and the Lean runtime specially optimizes array operations. The operations that modify byte arrays first check the array's [reference count](../../Run-Time-Code/Reference-Counting/index.md#reference-counting), and if there are no other references to the array, it is modified in place.

There is no literal syntax for byte arrays. `List.toByteArray` can be used to construct an array from a list literal.

<a id="ByteArray___mk"></a>

**structure**

```text
ByteArray : Type
```

`ByteArray` is like `Array UInt8`, but with an efficient run-time representation as a packed byte buffer.

**Constructor**

```text
ByteArray.mk
```

Packs an array of bytes into a `ByteArray`.

Converting between `Array` and `ByteArray` takes linear time.

**Fields**

```text
data : Array UInt8
```

The data contained in the byte array.

Converting between `Array` and `ByteArray` takes linear time.

<a id="The-Lean-Language-Reference--Basic-Types--Byte-Arrays--API-Reference"></a>
### 20.17.1. API Reference

<a id="The-Lean-Language-Reference--Basic-Types--Byte-Arrays--API-Reference--Constructing-Byte-Arrays"></a>
#### 20.17.1.1. Constructing Byte Arrays

<a id="ByteArray___empty"></a>

**def**

```text
ByteArray.empty : ByteArray
```

Constructs a new empty byte array with initial capacity `0`.

Use `ByteArray.emptyWithCapacity` to create an array with a greater initial capacity.

<a id="ByteArray___emptyWithCapacity"></a>

**def**

```text
ByteArray.emptyWithCapacity (c : Nat) : ByteArray
```

Constructs a new empty byte array with initial capacity `c`.

<a id="ByteArray___append"></a>

**def**

```text
ByteArray.append (a b : ByteArray) : ByteArray
```

Appends two byte arrays.

In compiled code, calls to `ByteArray.append` are replaced with the much more efficient `ByteArray.fastAppend`.

<a id="ByteArray___fastAppend"></a>

**def**

```text
ByteArray.fastAppend (a b : ByteArray) : ByteArray
```

Appends two byte arrays using fast array primitives instead of converting them into lists and back.

In compiled code, this function replaces calls to `ByteArray.append`.

<a id="ByteArray___copySlice"></a>

**def**

```text
ByteArray.copySlice (src : ByteArray) (srcOff : Nat) (dest : ByteArray)
  (destOff len : Nat) (exact : Bool := true) : ByteArray
```

Copies the slice at `[srcOff, srcOff + len)` in `src` to `[destOff, destOff + len)` in `dest`, growing `dest` if necessary. If `exact` is `false`, the capacity will be doubled when grown.

<a id="The-Lean-Language-Reference--Basic-Types--Byte-Arrays--API-Reference--Size"></a>
#### 20.17.1.2. Size

<a id="ByteArray___size"></a>

**def**

```text
ByteArray.size : ByteArray → Nat
```

Returns the number of bytes in the byte array.

This is the number of bytes actually in the array, as distinct from its capacity, which is the amount of memory presently allocated for the array.

<a id="ByteArray___usize"></a>

**def**

```text
ByteArray.usize (a : ByteArray) : USize
```

Retrieves the size of the array as a platform-specific fixed-width integer.

Because `USize` is big enough to address all memory on every platform that Lean supports, there are in practice no `ByteArray`s that have more elements that `USize` can count.

<a id="ByteArray___isEmpty"></a>

**def**

```text
ByteArray.isEmpty (s : ByteArray) : Bool
```

Returns `true` when `s` contains zero bytes.

<a id="The-Lean-Language-Reference--Basic-Types--Byte-Arrays--API-Reference--Lookups"></a>
#### 20.17.1.3. Lookups

<a id="ByteArray___get"></a>

**def**

```text
ByteArray.get (a : ByteArray) (i : Nat)
  (h : i < a.size := by get_elem_tactic) : UInt8
```

Retrieves the byte at the indicated index. Callers must prove that the index is in bounds.

Use `uget` for a more efficient alternative or `get!` for a variant that panics if the index is out of bounds.

<a id="ByteArray___uget"></a>

**def**

```text
ByteArray.uget (a : ByteArray) (i : USize)
  (h : i.toNat < a.size := by get_elem_tactic) : UInt8
```

Retrieves the byte at the indicated index. Callers must prove that the index is in bounds. The index is represented by a platform-specific fixed-width integer (either 32 or 64 bits).

Because `USize` is big enough to address all memory on every platform that Lean supports, there are in practice no `ByteArray`s for which `uget` cannot retrieve all elements.

<a id="ByteArray___get___"></a>

**def**

```text
ByteArray.get! : ByteArray → Nat → UInt8
```

Retrieves the byte at the indicated index. Panics if the index is out of bounds.

<a id="ByteArray___extract"></a>

**def**

```text
ByteArray.extract (a : ByteArray) (b e : Nat) : ByteArray
```

Copies the bytes with indices `b` (inclusive) to `e` (exclusive) to a new `ByteArray`.

<a id="The-Lean-Language-Reference--Basic-Types--Byte-Arrays--API-Reference--Conversions"></a>
#### 20.17.1.4. Conversions

<a id="ByteArray___toList"></a>

**def**

```text
ByteArray.toList (bs : ByteArray) : List UInt8
```

Converts a packed array of bytes to a linked list.

<a id="ByteArray___toUInt64BE___"></a>

**def**

```text
ByteArray.toUInt64BE! (bs : ByteArray) : UInt64
```

Interprets a `ByteArray` of size 8 as a big-endian `UInt64`.

Panics if the array's size is not 8.

<a id="ByteArray___toUInt64LE___"></a>

**def**

```text
ByteArray.toUInt64LE! (bs : ByteArray) : UInt64
```

Interprets a `ByteArray` of size 8 as a little-endian `UInt64`.

Panics if the array's size is not 8.

<a id="The-Lean-Language-Reference--Basic-Types--Byte-Arrays--API-Reference--Conversions--UTF-8"></a>
##### 20.17.1.4.1. UTF-8

<a id="ByteArray___utf8Decode___"></a>

**def**

```text
ByteArray.utf8Decode? (b : ByteArray) : Option (Array Char)
```

Decodes a sequence of characters from their UTF-8 representation. Returns `none` if the bytes are not a sequence of Unicode scalar values.

<a id="ByteArray___utf8DecodeChar___"></a>

**def**

```text
ByteArray.utf8DecodeChar? (bytes : ByteArray) (i : Nat) : Option Char
```

Decodes and returns the `Char` whose UTF-8 encoding begins at `i` in `bytes`.

Returns `none` if `i` is not the start of a valid UTF-8 encoding of a character.

<a id="ByteArray___utf8DecodeChar"></a>

**def**

```text
ByteArray.utf8DecodeChar (bytes : ByteArray) (i : Nat)
  (h : (bytes.utf8DecodeChar? i).isSome = true) : Char
```

Decodes and returns the `Char` whose UTF-8 encoding begins at `i` in `bytes`.

This function requires a proof that there is, in fact, a valid `Char` at `i`. `utf8DecodeChar?` is an alternative function that returns `Option Char` instead of requiring a proof ahead of time.

<a id="The-Lean-Language-Reference--Basic-Types--Byte-Arrays--API-Reference--Modification"></a>
#### 20.17.1.5. Modification

<a id="ByteArray___push"></a>

**def**

```text
ByteArray.push : ByteArray → UInt8 → ByteArray
```

Adds an element to the end of an array. The resulting array's size is one greater than the input array. If there are no other references to the array, then it is modified in-place.

This takes amortized `O(1)` time because `ByteArray` is represented by a dynamic array.

<a id="ByteArray___set"></a>

**def**

```text
ByteArray.set (a : ByteArray) (i : Nat) :
  UInt8 → (h : autoParam (i < a.size) ByteArray.set._auto_1) → ByteArray
```

Replaces the byte at the given index.

No bounds check is performed, but the function requires a proof that the index is in bounds. This proof can usually be omitted, and will be synthesized automatically.

The array is modified in-place if there are no other references to it.

<a id="ByteArray___uset"></a>

**def**

```text
ByteArray.uset (a : ByteArray) (i : USize) :
  UInt8 →
    (h : autoParam (i.toNat < a.size) ByteArray.uset._auto_1) →
      ByteArray
```

Replaces the byte at the given index.

No bounds check is performed, but the function requires a proof that the index is in bounds. This proof can usually be omitted, and will be synthesized automatically.

The array is modified in-place if there are no other references to it.

<a id="ByteArray___set___"></a>

**def**

```text
ByteArray.set! : ByteArray → Nat → UInt8 → ByteArray
```

Replaces the byte at the given index.

The array is modified in-place if there are no other references to it.

If the index is out of bounds, the array is returned unmodified.

<a id="The-Lean-Language-Reference--Basic-Types--Byte-Arrays--API-Reference--Iteration"></a>
#### 20.17.1.6. Iteration

<a id="ByteArray___foldl"></a>

**def**

```text
ByteArray.foldl.{v} {β : Type v} (f : β → UInt8 → β) (init : β)
  (as : ByteArray) (start : Nat := 0) (stop : Nat := as.size) : β
```

A left fold on `ByteArray` that iterates over an array from low to high indices, computing a running value.

Each element of the array is combined with the value from the prior elements using a function `f`. The initial value `init` is the starting value before any elements have been processed.

`ByteArray.foldlM` is a monadic variant of this function.

<a id="ByteArray___foldlM"></a>

**def**

```text
ByteArray.foldlM.{v, w} {β : Type v} {m : Type v → Type w} [Monad m]
  (f : β → UInt8 → m β) (init : β) (as : ByteArray) (start : Nat := 0)
  (stop : Nat := as.size) : m β
```

A monadic left fold on `ByteArray` that iterates over an array from low to high indices, computing a running value.

Each element of the array is combined with the value from the prior elements using a monadic function `f`. The initial value `init` is the starting value before any elements have been processed.

<a id="ByteArray___forIn"></a>

**def**

```text
ByteArray.forIn.{v, w} {β : Type v} {m : Type v → Type w} [Monad m]
  (as : ByteArray) (b : β) (f : UInt8 → β → m (ForInStep β)) : m β
```

The reference implementation of `ForIn.forIn` for `ByteArray`.

In compiled code, this is replaced by the more efficient `ByteArray.forInUnsafe`.

<a id="The-Lean-Language-Reference--Basic-Types--Byte-Arrays--API-Reference--Iterators"></a>
#### 20.17.1.7. Iterators

<a id="ByteArray___iter"></a>

**def**

```text
ByteArray.iter (arr : ByteArray) : ByteArray.Iterator
```

Creates an iterator at the beginning of an array.

<a id="ByteArray___Iterator___mk"></a>

**structure**

```text
ByteArray.Iterator : Type
```

Iterator over the bytes (`UInt8`) of a `ByteArray`.

Typically created by `arr.iter`, where `arr` is a `ByteArray`.

An iterator is *valid* if the position `i` is *valid* for the array `arr`, meaning `0 ≤ i ≤ arr.size`

Most operations on iterators return arbitrary values if the iterator is not valid. The functions in the `ByteArray.Iterator` API should rule out the creation of invalid iterators, with two exceptions:

- `Iterator.next iter` is invalid if `iter` is already at the end of the array (`iter.atEnd` is `true`)
- `Iterator.forward iter n`/`Iterator.nextn iter n` is invalid if `n` is strictly greater than the number of remaining bytes.

**Constructor**

```text
ByteArray.Iterator.mk
```

**Fields**

```text
array : ByteArray
```

The array the iterator is for.

```text
idx : Nat
```

The current position.

This position is not necessarily valid for the array, for instance if one keeps calling `Iterator.next` when `Iterator.atEnd` is true. If the position is not valid, then the current byte is `(default : UInt8)`.

<a id="ByteArray___Iterator___pos"></a>

**def**

```text
ByteArray.Iterator.pos (self : ByteArray.Iterator) : Nat
```

The current position.

This position is not necessarily valid for the array, for instance if one keeps calling `Iterator.next` when `Iterator.atEnd` is true. If the position is not valid, then the current byte is `(default : UInt8)`.

<a id="ByteArray___Iterator___atEnd"></a>

**def**

```text
ByteArray.Iterator.atEnd : ByteArray.Iterator → Bool
```

True if the iterator is past the array's last byte.

<a id="ByteArray___Iterator___hasNext"></a>

**def**

```text
ByteArray.Iterator.hasNext : ByteArray.Iterator → Bool
```

True if the iterator is valid; that is, it is not past the array's last byte.

<a id="ByteArray___Iterator___hasPrev"></a>

**def**

```text
ByteArray.Iterator.hasPrev : ByteArray.Iterator → Bool
```

True if the position is not zero.

<a id="ByteArray___Iterator___curr"></a>

**def**

```text
ByteArray.Iterator.curr : ByteArray.Iterator → UInt8
```

The byte at the current position.

On an invalid position, returns `(default : UInt8)`.

<a id="ByteArray___Iterator___curr___"></a>

**def**

```text
ByteArray.Iterator.curr' (it : ByteArray.Iterator)
  (h : it.hasNext = true) : UInt8
```

The byte at the current position. -

<a id="ByteArray___Iterator___next"></a>

**def**

```text
ByteArray.Iterator.next : ByteArray.Iterator → ByteArray.Iterator
```

Moves the iterator's position forward by one byte, unconditionally.

It is only valid to call this function if the iterator is not at the end of the array, **i.e.** `Iterator.atEnd` is `false`; otherwise, the resulting iterator will be invalid.

<a id="ByteArray___Iterator___next___"></a>

**def**

```text
ByteArray.Iterator.next' (it : ByteArray.Iterator)
  (_h : it.hasNext = true) : ByteArray.Iterator
```

Moves the iterator's position forward by one byte. -

<a id="ByteArray___Iterator___forward"></a>

**def**

```text
ByteArray.Iterator.forward :
  ByteArray.Iterator → Nat → ByteArray.Iterator
```

Moves the iterator's position several bytes forward.

The resulting iterator is only valid if the number of bytes to skip is less than or equal to the number of bytes left in the iterator.

<a id="ByteArray___Iterator___nextn"></a>

**def**

```text
ByteArray.Iterator.nextn : ByteArray.Iterator → Nat → ByteArray.Iterator
```

Moves the iterator's position several bytes forward.

The resulting iterator is only valid if the number of bytes to skip is less than or equal to the number of bytes left in the iterator.

<a id="ByteArray___Iterator___prev"></a>

**def**

```text
ByteArray.Iterator.prev : ByteArray.Iterator → ByteArray.Iterator
```

Decreases the iterator's position.

If the position is zero, this function is the identity.

<a id="ByteArray___Iterator___prevn"></a>

**def**

```text
ByteArray.Iterator.prevn : ByteArray.Iterator → Nat → ByteArray.Iterator
```

Moves the iterator's position several bytes back.

If asked to go back more bytes than available, stops at the beginning of the array.

<a id="ByteArray___Iterator___remainingBytes"></a>

**def**

```text
ByteArray.Iterator.remainingBytes : ByteArray.Iterator → Nat
```

The number of bytes remaining in the iterator.

<a id="ByteArray___Iterator___toEnd"></a>

**def**

```text
ByteArray.Iterator.toEnd : ByteArray.Iterator → ByteArray.Iterator
```

Moves the iterator's position to the end of the array.

Given `i : ByteArray.Iterator`, note that `i.toEnd.atEnd` is always `true`.

<a id="The-Lean-Language-Reference--Basic-Types--Byte-Arrays--API-Reference--Slices"></a>
#### 20.17.1.8. Slices

<a id="ByteArray___toByteSlice"></a>

**def**

```text
ByteArray.toByteSlice (as : ByteArray) (start : Nat := 0)
  (stop : Nat := as.size) : ByteSlice
```

Returns a byte slice of a byte array, with the given bounds.

If `start` or `stop` are not valid bounds for a byte slice, then they are clamped to byte array's size. Additionally, the starting index is clamped to the ending index.

<a id="ByteSlice"></a>

**def**

```text
ByteSlice : Type
```

A region of some underlying byte array.

A byte slice contains a byte array together with the start and end indices of a region of interest. Byte slices can be used to avoid copying or allocating space, while being more convenient than tracking the bounds by hand. The region of interest consists of every index that is both greater than or equal to `start` and strictly less than `stop`.

<a id="ByteSlice___beq"></a>

**def**

```text
ByteSlice.beq (a b : ByteSlice) : Bool
```

Comparison function

<a id="ByteSlice___byteArray"></a>

**def**

```text
ByteSlice.byteArray (xs : ByteSlice) : ByteArray
```

The underlying byte array.

<a id="ByteSlice___contains"></a>

**def**

```text
ByteSlice.contains (s : ByteSlice) (byte : UInt8) : Bool
```

Checks if the byte slice contains a specific byte value.

Returns `true` if any byte in the slice equals the given value, `false` otherwise.

<a id="ByteSlice___empty"></a>

**def**

```text
ByteSlice.empty : ByteSlice
```

The empty byte slice.

This empty byte slice is backed by an empty byte array.

<a id="ByteSlice___foldr"></a>

**def**

```text
ByteSlice.foldr.{v} {β : Type v} (f : UInt8 → β → β) (init : β)
  (as : ByteSlice) : β
```

Folds an operation from right to left over the bytes in a byte slice.

An accumulator of type `β` is constructed by starting with `init` and combining each byte of the byte slice with the current accumulator value in turn, moving from the end to the start.

Examples:

- `(ByteArray.mk #[1, 2, 3]).toByteSlice.foldr (·.toNat + ·) 0 = 6`
- `(ByteArray.mk #[1, 2, 3]).toByteSlice.popFront.foldr (·.toNat + ·) 0 = 5`

<a id="ByteSlice___foldrM"></a>

**def**

```text
ByteSlice.foldrM.{v, w} {β : Type v} {m : Type v → Type w} [Monad m]
  (f : UInt8 → β → m β) (init : β) (as : ByteSlice) : m β
```

Folds a monadic operation from right to left over the bytes in a byte slice.

An accumulator of type `β` is constructed by starting with `init` and monadically combining each byte of the byte slice with the current accumulator value in turn, moving from the end to the start. The monad in question may permit early termination or repetition.

Examples:

```text
#eval (ByteArray.mk #[1, 2, 3]).toByteSlice.foldrM (init := 0) fun x acc =>
  some x.toNat + acc
```

```proofscript
some 6
```

<a id="ByteSlice___forM"></a>

**def**

```text
ByteSlice.forM.{v, w} {m : Type v → Type w} [Monad m]
  (f : UInt8 → m PUnit) (as : ByteSlice) : m PUnit
```

Runs a monadic action on each byte of a byte slice.

The bytes are processed starting at the lowest index and moving up.

<a id="ByteSlice___get"></a>

**def**

```text
ByteSlice.get (s : ByteSlice) (i : Fin s.size) : UInt8
```

Extracts a byte from the byte slice.

The index is relative to the start of the byte slice, rather than the underlying byte array.

<a id="ByteSlice___get___"></a>

**def**

```text
ByteSlice.get! (s : ByteSlice) (i : Nat) : UInt8
```

Extracts a byte from the byte slice, or returns a default value when the index is out of bounds.

The index is relative to the start and end of the byte slice, rather than the underlying byte array. The default value is 0.

<a id="ByteSlice___getD"></a>

**def**

```text
ByteSlice.getD (s : ByteSlice) (i : Nat) (v₀ : UInt8) : UInt8
```

Extracts a byte from the byte slice, or returns a default value `v₀` when the index is out of bounds.

The index is relative to the start and end of the byte slice, rather than the underlying byte array.

<a id="ByteSlice___ofByteArray"></a>

**def**

```text
ByteSlice.ofByteArray (ba : ByteArray) : ByteSlice
```

Creates a new ByteSlice of a ByteArray

<a id="ByteSlice___size"></a>

**def**

```text
ByteSlice.size (s : ByteSlice) : Nat
```

Computes the size of the byte slice.

<a id="ByteSlice___slice"></a>

**def**

```text
ByteSlice.slice (s : ByteSlice) (start : Nat := 0)
  (stop : Nat := s.size) : ByteSlice
```

Creates a sub-slice of the byte slice with the given bounds.

If `start` or `stop` are not valid bounds for a sub-slice, then they are clamped to the slice's size. Additionally, the starting index is clamped to the ending index.

The indices are relative to the current slice, not the underlying byte array.

<a id="ByteSlice___start"></a>

**def**

```text
ByteSlice.start (xs : ByteSlice) : Nat
```

The starting index of the region of interest (inclusive).

<a id="ByteSlice___stop"></a>

**def**

```text
ByteSlice.stop (xs : ByteSlice) : Nat
```

The ending index of the region of interest (exclusive).

<a id="ByteSlice___toByteArray"></a>

**def**

```text
ByteSlice.toByteArray (s : ByteSlice) : ByteArray
```

Converts a byte slice back to a byte array by copying the relevant portion.

<a id="The-Lean-Language-Reference--Basic-Types--Byte-Arrays--API-Reference--Element-Predicates"></a>
#### 20.17.1.9. Element Predicates

<a id="ByteArray___findIdx___"></a>

**def**

```text
ByteArray.findIdx? (a : ByteArray) (p : UInt8 → Bool)
  (start : Nat := 0) : Option Nat
```

Finds the index of the first byte in `a` for which `p` returns `true`. If no byte in `a` satisfies `p`, then the result is `none`.

The variant `findFinIdx?` additionally returns a proof that the found index is in bounds.

<a id="ByteArray___findFinIdx___"></a>

**def**

```text
ByteArray.findFinIdx? (a : ByteArray) (p : UInt8 → Bool)
  (start : Nat := 0) : Option (Fin a.size)
```

Finds the index of the first byte in `a` for which `p` returns `true`. If no byte in `a` satisfies `p`, then the result is `none`.

The index is returned along with a proof that it is a valid index in the array.
