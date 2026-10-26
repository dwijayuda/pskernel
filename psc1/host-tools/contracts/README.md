# Runtime contracts

compiler-closure.mjs validates exact source/logical expansion counts. Passing it
is not independent admission or proof of compiler correctness. Reusable runtime
validators belong here; CI scripts consume them through stable compatibility exports.
