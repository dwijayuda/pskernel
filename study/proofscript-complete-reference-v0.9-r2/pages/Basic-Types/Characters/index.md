<a id="Char"></a>

# ProofScript — 20.7. Characters

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Nat, Int, machine integers, floats, characters, strings, bytes, options, products, sums, lists, arrays, maps, ranges, subtypes and lazy computations retain their distinct native contracts. A target representation is not their meaning. Nat subtraction saturates at zero; the selected Int quotient differs from JavaScript BigInt truncation for some negative inputs. String offsets and Unicode conversions require explicit mappings.

**Compiler and coverage boundary.** The full API entries below retain exact names and signature metadata. Distinguish a signature display from executable source. Unknown reachable primitives reject the requested executable profile.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Basic-Types/Characters/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Basic-Types/Characters/index.html). Source Git blob: `5685a57d1c19504d074088002f7b8a97b2cbbe6e`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Constructor-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>
<a id="docstring-section-Fields-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next-next"></a>

---

## 20.7. Characters

Characters are represented by the type `Char`, which may be any Unicode [scalar value](http://www.unicode.org/glossary/#unicode_scalar_value). While [strings](../Strings/index.md#String) are UTF-8-encoded arrays of bytes, characters are represented by full 32-bit values. Lean provides special [syntax](index.md#char-syntax) for character literals.

<a id="char-model"></a>
### 20.7.1. Logical Model

From the perspective of Lean's logic, characters consist of a 32-bit unsigned integer paired with a proof that it is a valid Unicode scalar value.

<a id="Char___mk"></a>

**structure**

```text
Char : Type
```

Characters are Unicode [scalar values](http://www.unicode.org/glossary/#unicode_scalar_value).

**Constructor**

```text
Char.mk
```

**Fields**

```text
val : UInt32
```

The underlying Unicode scalar value as a `UInt32`.

```text
valid : self.val.isValidChar
```

The value must be a legal scalar value.

<a id="char-runtime"></a>
### 20.7.2. Run-Time Representation

As a [trivial wrapper](../../The-Type-System/Inductive-Types/index.md#inductive-types-trivial-wrappers), characters are represented identically to `UInt32`. In particular, characters are represented as 32-bit immediate values in monomorphic contexts. In other words, a field of a constructor or structure of type `Char` does not require indirection to access. In polymorphic contexts, characters are [boxed](../../Run-Time-Code/Boxing/index.md#--tech-term-Boxed).

<a id="char-syntax"></a>
### 20.7.3. Syntax

Character literals consist of a single character or an escape sequence enclosed in single quotes (`'`, Unicode `'APOSTROPHE' (U+0027)`). Between these single quotes, the character literal may contain character other that `'`, including newlines, which are included literally (with the caveat that all newlines in a Lean source file are interpreted as `'\n'`, regardless of file encoding and platform). Special characters may be escaped with a backslash, so `'\''` is a character literal that contains a single quote. The following forms of escape sequences are accepted:

  `\r`, `\n`, `\t`, `\\`, `\"`, `\'`

These escape sequences have the usual meaning, mapping to `CR`, `LF`, tab, backslash, double quote, and single quote, respectively.

  `\xNN`

When `NN` is a sequence of two hexadecimal digits, this escape denotes the character whose Unicode code point is indicated by the two-digit hexadecimal code.

  `\uNNNN`

When `NN` is a sequence of two hexadecimal digits, this escape denotes the character whose Unicode code point is indicated by the four-digit hexadecimal code.

<a id="char-api"></a>
### 20.7.4. API Reference

<a id="The-Lean-Language-Reference--Basic-Types--Characters--API-Reference--Conversions"></a>
#### 20.7.4.1. Conversions

<a id="Char___ofNat"></a>

**def**

```text
Char.ofNat (n : Nat) : Char
```

Converts a `Nat` into a `Char`. If the `Nat` does not encode a valid Unicode scalar value, `'\0'` is returned instead.

<a id="Char___toNat"></a>

**def**

```text
Char.toNat (c : Char) : Nat
```

The character's Unicode code point as a `Nat`.

<a id="Char___isValidCharNat"></a>

**def**

```text
Char.isValidCharNat (n : Nat) : Prop
```

True for natural numbers that are valid [Unicode scalar values](https://www.unicode.org/glossary/#unicode_scalar_value).

<a id="Char___ofUInt8"></a>

**def**

```text
Char.ofUInt8 (n : UInt8) : Char
```

Converts an 8-bit unsigned integer into a character.

The integer's value is interpreted as a Unicode code point.

<a id="Char___toUInt8"></a>

**def**

```text
Char.toUInt8 (c : Char) : UInt8
```

Converts a character into a `UInt8` that contains its code point.

If the code point is larger than 255, it is truncated (reduced modulo 256).

There are two ways to convert a character to a string. `Char.toString` converts a character to a singleton string that consists of only that character, while `Char.quote` converts the character to a string representation of the corresponding character literal.

<a id="Char___toString"></a>

**def**

```text
Char.toString (c : Char) : String
```

Constructs a singleton string that contains only the provided character.

Examples:

- `'L'.toString = "L"`
- `'"'.toString = "\""`

<a id="Char___quote"></a>

**def**

```text
Char.quote (c : Char) : String
```

Quotes the character to its representation as a character literal, surrounded by single quotes and escaped as necessary.

Examples:

- `'L'.quote = "'L'"`
- `'"'.quote = "'\\\"'"`

<a id="From-Characters-to-Strings"></a>
From Characters to Strings 

`Char.toString` produces a string that contains only the character in question:

```proofscript
#eval 'e'.toString
```

```lean
"e"
```

```proofscript
#eval '\x65'.toString
```

```lean
"e"
```

```proofscript
#eval '"'.toString
```

```lean
"\""
```

`Char.quote` produces a string that contains a character literal, suitably escaped:

```proofscript
#eval 'e'.quote
```

```lean
"'e'"
```

```proofscript
#eval '\x65'.quote
```

```lean
"'e'"
```

```proofscript
#eval '"'.quote
```

```lean
"'\\\"'"
```

<a id="char-api-classes"></a>
#### 20.7.4.2. Character Classes

<a id="Char___isAlpha"></a>

**def**

```text
Char.isAlpha (c : Char) : Bool
```

Returns `true` if the character is an ASCII letter.

The ASCII letters are the following: `ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz`.

<a id="Char___isAlphanum"></a>

**def**

```text
Char.isAlphanum (c : Char) : Bool
```

Returns `true` if the character is an ASCII letter or digit.

The ASCII letters are the following: `ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz`. The ASCII digits are the following: `0123456789`.

<a id="Char___isDigit"></a>

**def**

```text
Char.isDigit (c : Char) : Bool
```

Returns `true` if the character is an ASCII digit.

The ASCII digits are the following: `0123456789`.

<a id="Char___isLower"></a>

**def**

```text
Char.isLower (c : Char) : Bool
```

Returns `true` if the character is a lowercase ASCII letter.

The lowercase ASCII letters are the following: `abcdefghijklmnopqrstuvwxyz`.

<a id="Char___isUpper"></a>

**def**

```text
Char.isUpper (c : Char) : Bool
```

Returns `true` if the character is a uppercase ASCII letter.

The uppercase ASCII letters are the following: `ABCDEFGHIJKLMNOPQRSTUVWXYZ`.

<a id="Char___isWhitespace"></a>

**def**

```text
Char.isWhitespace (c : Char) : Bool
```

Returns `true` if the character is a space `(' ', U+0020)`, a tab `('\t', U+0009)`, a carriage return `('\r', U+000D)`, or a newline `('\n', U+000A)`.

<a id="The-Lean-Language-Reference--Basic-Types--Characters--API-Reference--Case-Conversion"></a>
#### 20.7.4.3. Case Conversion

<a id="Char___toUpper"></a>

**def**

```text
Char.toUpper (c : Char) : Char
```

Converts a lowercase ASCII letter to the corresponding uppercase letter. Letters outside the ASCII alphabet are returned unchanged.

The lowercase ASCII letters are the following: `abcdefghijklmnopqrstuvwxyz`.

<a id="Char___toLower"></a>

**def**

```text
Char.toLower (c : Char) : Char
```

Converts an uppercase ASCII letter to the corresponding lowercase letter. Letters outside the ASCII alphabet are returned unchanged.

The uppercase ASCII letters are the following: `ABCDEFGHIJKLMNOPQRSTUVWXYZ`.

<a id="The-Lean-Language-Reference--Basic-Types--Characters--API-Reference--Comparisons"></a>
#### 20.7.4.4. Comparisons

<a id="Char___le"></a>

**def**

```text
Char.le (a b : Char) : Prop
```

One character is less than or equal to another if its code point is less than or equal to the other's.

<a id="Char___lt"></a>

**def**

```text
Char.lt (a b : Char) : Prop
```

One character is less than another if its code point is strictly less than the other's.

<a id="The-Lean-Language-Reference--Basic-Types--Characters--API-Reference--Unicode"></a>
#### 20.7.4.5. Unicode

<a id="Char___utf8Size"></a>

**def**

```text
Char.utf8Size (c : Char) : Nat
```

Returns the number of bytes required to encode this `Char` in UTF-8.

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
"e"
```


### Display 2


```text
"\""
```


### Display 3


```text
"'e'"
```


### Display 4


```text
"'\\\"'"
```

