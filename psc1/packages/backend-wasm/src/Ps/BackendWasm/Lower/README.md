# Wasm lowering modules

Start with `../Lower.lean` for lowering state, bindings, expression/intrinsic
translation and final module construction.

`TypeInventory.lean` owns the preceding type-discovery pass:
- Collect function and Array types from structures, inductives and declarations.
- Visit declaration parameters, result and body in the retained order.
- De-duplicate by the existing bounded Wasm type key and append first occurrences.
- Retain all existing traversal fuel and exhausted-fuel behavior.

It imports only `Ps.BackendWasm.Type` and `Ps.Foundation.List`.
It cannot specialize IR, generate instructions, select a checker or publish output.

The first extraction moves 27 definitions and 935 source lines verbatim from
baseline 3089cbc369bc8a11f540c13140c7003c9dadf4a8.
`scripts/readability-module-check.mjs` checks moved and remaining bodies exactly;
the explicit Lake root and normal compiler/closure/full regression gates check
the integration. This correspondence does not claim formal compiler preservation
or new G2/G3 qualification for changed compiler source.
