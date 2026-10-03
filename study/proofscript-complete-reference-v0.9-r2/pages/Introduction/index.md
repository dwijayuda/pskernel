<a id="introduction"></a>

# ProofScript — 1. Introduction

[Reference home](../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

Use ProofScript as an ordinary programming and proof language. The surface changes presentation, not the underlying meaning. In this edition function and const are definition aliases, applications may use comma-separated calls, and selected declaration and match bodies may use braces. TypeScript familiarity does not introduce JavaScript truthiness, prototype objects, arbitrary nullability, or implicit returns. The inherited detail below remains a reference for the same logical foundation, not evidence that the current PSC compiler implements every feature.

## ProofScript way of writing it


```proofscript
function greet(name: String): String :=
  "Hello, " ++ name

const greeting: String := greet("Ada")

theorem greetAda: greet("Ada") = "Hello, Ada" := by
  rfl
```

**Compiler and coverage boundary.** Keep the ps-0.9-r2 grammar identity, the stable Lean semantic pin, and implementation coverage separate. Do not rename the upstream history into ProofScript release history.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [Introduction/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/Introduction/index.html). Source Git blob: `f3cecda0e66e35638190da49c7aff6d879794eae`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

<a id="docstring-section-Constructors"></a>

---

## 1. Introduction

The *Lean Language Reference* is intended as a comprehensive, precise description of Lean. It is a reference work in which Lean users can look up detailed information, rather than a tutorial for new users. At the moment, this reference manual is a public preview. For tutorials and learning materials, please visit [the Lean documentation page](https://lean-lang.org/documentation/).

This document describes version `4.34.0-rc2` of Lean.

<a id="history-of-lean"></a>
### 1.1. History

Leonardo de Moura launched the Lean project when he was at Microsoft Research in 2013, and Lean 0.1 was officially released on June 16, 2014. The goal of the Lean project is to combine the high level of trust provided by a small, independently-implementable logical kernel with the convenience and automation of tools like SMT solvers, while scaling to large problems. This vision still guides the development of Lean, as we invest in improved automation, improved performance, and user-friendliness; the trusted core proof checker is still minimal and independent implementations exist.

The initial versions of Lean were primarily configured as C++ libraries in which client code could carry out trustworthy proofs that were independently checkable. In these early years, the design of Lean rapidly evolved towards traditional interactive provers, first with tactics written in Lua, and later with a dedicated front-end syntax. January 20, 2017 saw the first release of the Lean 3.0 series. Lean 3 achieved widespread adoption by mathematicians, and pioneered self-extensibility: tactics, notations, and top-level commands could all be defined in Lean itself. The mathematics community built Mathlib, which at the end of Lean 3 had over one million lines of formalized mathematics, with all proofs mechanically checked. The system itself, however, was still implemented in C++, which imposed limits on Lean's flexibility and made it more difficult to develop due to the diverse skills required.

Development of Lean 4 began in 2018, culminating in the 4.0 release on September 8, 2023. Lean 4 represents an important milestone: as of version 4, Lean is self-hosted—approximately 90% of the code that implements Lean is itself written in Lean. Lean 4's rich extension API provides users with the ability to adapt it to their needs, rather than relying on the core developers to add necessary features. Additionally, self-hosting makes the development process much faster, so features and performance can be delivered more quickly; Lean 4 is faster and scales to larger problems than Lean 3. Mathlib was successfully ported to Lean 4 in 2023 through a community effort supported by the Lean developers, and it has now grown to over 1.5 million lines. Even though Mathlib has grown by 50%, Lean 4 checks it faster than Lean 3 could check its smaller library. The development process for Lean 4 was approximately as long as that of all prior versions combined, and we are now delighted with its design—no further rewrites are planned.

Leonardo de Moura and his co-founder, Sebastian Ullrich, launched the Lean Focused Research Organization (FRO) nonprofit in July of 2023 within Convergent Research, with philanthropic support from the Simons Foundation International, the Alfred P. Sloan Foundation, and Richard Merkin. The FRO currently has more than ten employees working to support the growth and scalability of Lean and the broader Lean community.

<a id="typographical-conventions"></a>
### 1.2. Typographical Conventions

This document makes use of a number of typographical and layout conventions to indicate various aspects of the information being presented.

<a id="code-samples"></a>
#### 1.2.1. Lean Code

This document contains many Lean code examples. They are formatted as follows:

<!-- Presentation aliases only; canonical source retained in the edit ledger. -->
<a id="hello"></a>


```proofscript
const hello : IO Unit := IO.println "Hello, world!"
```

Compiler output (which may be errors, warnings, or just information) is shown both in the code and separately:
<a id="bogus"></a>


```proofscript
#eval s!"The answer is {2 + 2}"

theorem bogus : False := by sorry

example := Nat.succ "two"
```

Informative output, such as the result of [`#eval`](../Interacting-with-Lean/index.md#Lean___Parser___Command___eval), is shown like this:

```lean
"The answer is 4"
```

Warnings are shown like this:

```lean
declaration uses `sorry`
```

Error messages are shown like this:

```lean
Application type mismatch: The argument
  "two"
has type
  String
but is expected to have type
  Nat
in the application
  Nat.succ "two"
```

The presence of tactic proof states is indicated by the presence of small lozenges that can be clicked to show the proof state, such as after `rfl` below:

```proofscript
example : 2 + 2 = 4 := by rfl
```

Proof states may also be shown on their own. When attempting to prove that `2 + 2 = 4`, the initial proof state is:

After using `rfl`, the resulting state is:

Identifiers in code examples are hyperlinked to their documentation.

Examples of code with syntax errors are shown with an indicator of where the parser error occurred, along with the error message:

```lean
def f : Option Nat → Type  | some 0 => Unit  | => Option (f t)  | none => Empty
```

```lean
<example>:3:3-3:6: unexpected token '=>'; expected term
```

<a id="example-boxes"></a>
#### 1.2.2. Examples

Illustrative examples are in callout boxes, as below:

<a id="Even-Numbers"></a>
Even Numbers 

This is an example of an example.

One way to define even numbers is via an inductive predicate:
<a id="Even-_LPAR_in-Even-Numbers_RPAR_"></a>
<a id="Even___zero-_LPAR_in-Even-Numbers_RPAR_"></a>
<a id="Even___plusTwo-_LPAR_in-Even-Numbers_RPAR_"></a>


```proofscript
inductive Even : Nat → Prop where
  | zero : Even 0
  | plusTwo : Even n → Even (n + 2)
```

<a id="technical-terms"></a>
#### 1.2.3. Technical Terminology

<a id="--tech-term-Technical-terminology"></a>
*Technical terminology* refers to terms used in a very specific sense when writing technical material, such as this reference. Uses of [technical terminology](index.md#--tech-term-Technical-terminology) are frequently hyperlinked to their definition sites, using links like this one.

<a id="reference-boxes"></a>
#### 1.2.4. Constant, Syntax, and Tactic References

Definitions, inductive types, syntax formers, and tactics have specific descriptions. These descriptions are marked as follows:
<a id="Even"></a>
<a id="Even___zero"></a>
<a id="Even___plusTwo"></a>


```proofscript
/--
Evenness: a number is even if it can be evenly divided by two.
-/
inductive Even : Nat → Prop where
  | /-- 0 is considered even here -/
    zero : Even 0
  | /-- If `n` is even, then so is `n + 2`. -/
    plusTwo : Even n → Even (n + 2)
```

<a id="Even___zero-next"></a>

**inductive predicate**

```text
Even : Nat → Prop
```

Evenness: a number is even if it can be evenly divided by two.

**Constructors**

```text
Even.zero : Even 0
```

0 is considered even here

```text
Even.plusTwo {n : Nat} : Even n → Even (n + 2)
```

If `n` is even, then so is `n + 2`.

<a id="The-Lean-Language-Reference--Introduction--How-to-Cite-This-Work"></a>
### 1.3. How to Cite This Work

In formal citations, please cite this work as *The Lean Language Reference* by The Lean Developers. Additionally, please include the corresponding version of Lean in the citation, which is `4.34.0-rc2`.

<a id="dependency-licenses"></a>
### Open-Source Licenses

#### Editable Combobox With Both List and Inline Autocomplete Example, from the W3C's ARIA Authoring Practices Guide (APG)

 [https://www.w3.org/WAI/ARIA/apg/patterns/combobox/examples/combobox-autocomplete-both/](https://www.w3.org/WAI/ARIA/apg/patterns/combobox/examples/combobox-autocomplete-both/)

The search box component includes code derived from the example code in the linked article from the W3C's ARIA Authoring Practices Guide (APG).

 `W3C-20150513` 

##### Software and Document License - 2023 Version

Permission to copy, modify, and distribute this work, with or without modification, for any purpose and without fee or royalty is hereby granted, provided that you include the following on ALL copies of the work or portions thereof, including modifications:

* The full text of this NOTICE in a location viewable to users of the redistributed or derivative work.

* Any pre-existing intellectual property disclaimers, notices, or terms and conditions. If none exist, the W3C software and document short notice should be included.

* Notice of any changes or modifications, through a copyright statement on the new code or document such as "This software or document includes material copied from or derived from "Editable Combobox With Both List and Inline Autocomplete Example" at https://www.w3.org/WAI/ARIA/apg/patterns/combobox/examples/combobox-autocomplete-both/. Copyright © 2024 World Wide Web Consortium. https://www.w3.org/copyright/software-license-2023/"

#### elasticlunr.js

 [http://elasticlunr.com/](http://elasticlunr.com/)

Elasticlunr.js is used for full-text search

 `MIT` 

##### The MIT License

Copyright (C) 2017 by Wei Song

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#### fuzzysort v3.1.0

 [https://github.com/farzher/fuzzysort](https://github.com/farzher/fuzzysort)

The fuzzysort library is used in the search box to quickly filter results.

 `MIT` 

##### The MIT License

Copyright (c) 2018 Stephen Kamenar

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#### KaTeX

 [https://katex.org/](https://katex.org/)

KaTeX is used to render mathematical notation.

 `MIT` 

##### The MIT License

Copyright (c) 2013-2020 Khan Academy and other contributors

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#### Popper.js

 [https://popper.js.org/docs/v2/](https://popper.js.org/docs/v2/)

Popper.js is used (as a dependency of Tippy.js) to show information (primarily in Lean code) when hovering the mouse over an item of interest.

 `MIT` 

##### The MIT License

Copyright (c) 2019 Federico Zivolo

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#### Tippy.js

 [https://atomiks.github.io/tippyjs/](https://atomiks.github.io/tippyjs/)

Tippy.js is used together with Popper.js to show information (primarily in Lean code) when hovering the mouse over an item of interest.

 `MIT` 

##### The MIT License

Copyright (c) 2017-present atomiks

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Preserved native diagnostic displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
"The answer is 4"
```


### Display 2


```text
declaration uses `sorry`
```


### Display 3


```text
Application type mismatch: The argument
  "two"
has type
  String
but is expected to have type
  Nat
in the application
  Nat.succ "two"
```


## Preserved native proof-state displays

These are inherited explanatory/output displays, not additional source programs or newly executed results.
### Display 1


```text
⊢ False
```


### Display 2


```text
All goals completed! 🐙
```


### Display 3


```text
⊢ 2 + 2 = 4
```

