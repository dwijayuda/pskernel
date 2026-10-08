# @proofscript/pscv-extensions

Data-only extension manifests and deterministic activated extension-set fingerprinting. Installed extensions are not activated automatically. This package does not execute imported JS, WebAssembly or native code.

E0: library-only metadata; no execution. E1: syntax candidate, permitted only in a separately named extensible profile; cannot modify closed Standard or closed PSCV. E2: proof producer candidate. E3/E4: optimizer/backend candidate, separately validated later. E5: arbitrary semantic elaborator and E6: foundational semantic changes are denied in P0. In-process U3 execution is denied.

Future E1-E4 hosts must be independently isolated, resource bounded, capability restricted, and validated. The fingerprint is an identifier, not an authority token. A manifest is not an execution sandbox. No npm package may issue a checked or certified handle by writing a claim into JSON.
