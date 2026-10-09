# A rejected source

Main.ps assigns Type to a Nat. The checked source path must reject it.

Copy this directory into a working project, then run the installed compiler:

```sh
psc check Main.ps
psc build Main.ps --out Main.ts
```

Both commands must return a nonzero exit status. A fresh directory must have no Main.ts or Main.checked.json afterward. On Windows, use psc.cmd if PowerShell policy selects a blocked psc.ps1 shim.

## Preserve the last completed build

In a project created with `psc init`, first build the original `def answer : Nat := 42` in src/Main.ps. Keep a copy of src/Main.ts and src/Main.checked.json. Replace only the .ps source text with this rejected definition and run the same build again. The command must fail and both generated files must remain byte-identical to the earlier completed build.

Do not edit the generated .ts or receipt to perform this experiment. The compiler refuses to overwrite manually changed generated files. Restore the .ps source to the valid definition before resuming development.

This example demonstrates a type/admission refusal. It does not claim that all possible runtime properties are proved or that a complete PSCV contract language is implemented.
