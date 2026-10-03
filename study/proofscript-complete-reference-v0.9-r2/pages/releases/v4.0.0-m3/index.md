<a id="release-v4___0___0-m3"></a>

# ProofScript — Lean 4.0.0-m3 (2022-01-31)

[Reference home](../../../README.md) · **Grammar:** `ps-0.9-r2` · **Semantic pin:** Lean 4.34.0 stable.

These articles are the mirrored Lean release notes, not ProofScript releases. They document historical syntax, APIs, implementations and changes. The page named v4.34.0 in this mirror still identifies itself as rc2. Native source at the selected stable commit overrides stale details for a current ProofScript conformance claim. Historical examples remain native and are not silently modernized.

**Compiler and coverage boundary.** The stable delta note explicitly excludes the old native-reduction kernel hooks. Upgrading the pin requires a new reference/profile review and regenerated evidence.

**Inherited detail and attribution.** The section below is adapted from the Apache-2.0 Lean reference mirrored at [releases/v4.0.0-m3/index.html](https://github.com/dwijayuda/pskernel/blob/65369c75c7b63124f1ba7f2289e573181db281f0/study/lean4-language-reference/releases/v4.0.0-m3/index.html). Source Git blob: `19402b2e9ded543bc159d51a2cb617e9b0bda195`. Its prose, API signatures and native names are retained where they describe the inherited semantics. Selected definition-keyword presentation aliases are recorded separately, not certified by a PSC parser. Native toolchains, intentional errors and historical releases keep their actual identities. The mirror contains rc2 material; the stable pin and stable-delta audit override conflicting claims.

---

## Lean 4.0.0-m3 (2022-01-31)

This is the third milestone release of Lean 4, and the last planned milestone before an official release. With almost 3000 commits improving and extending many parts of the system since the last milestone, we are now close to completing all main features we have envisioned for Lean 4.

Contributors:

```text
$ git shortlog -s -n v4.0.0-m2..v4.0.0-m3
  1719  Leonardo de Moura
   725  Sebastian Ullrich
   149  Wojciech Nawrocki
    93  Daniel Selsam
    82  Gabriel Ebner
    36  Joscha
    35  Daniel Fabian
    21  tydeu
    14  Mario Carneiro
    13  larsk21
    12  Jannis Limperg
    11  Chris Lovett
     8  Henrik Böving
     4  François G. Dorais
     4  Siddharth
     3  Joe Hendrix
     3  Scott Morrison
     3  ammkrn
     2  Josh Levine
     2  Mac
     2  Mac Malone
     2  Simon Hudon
     2  pcpthm
     1  Anders Christiansen Sørby
     1  Andrei Cheremskoy
     1  Arthur Paulino
     1  Christian Pehle
     1  Formally Verified Waffle Maker
     1  Hunter Monroe
     1  Jan Hrcek
     1  Joshua Seaton
     1  Kevin Buzzard
     1  Lorenz Leutgeb
     1  Mauricio Collares
     1  Michael Burge
     1  Paul Brinkmeier
     1  Reijo Jaakkola
     1  Severen Redwood
     1  Siddharth Bhat
     1  Tom Ball
     1  Varun Gandhi
     1  WojciechKarpiel
     1  Xavier Noria
     1  gabriel-doriath-dohler
     1  zygi
     1  Бакиновский Максим
```
