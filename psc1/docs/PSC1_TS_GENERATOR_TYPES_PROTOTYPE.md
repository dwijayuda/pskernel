# Checked generator result type prototype

Isolated from the qualified PR #172 compiler. Diagnosis 39886224622 samples the
actual TypeScript 7.0.2 native checker repeatedly traversing contextual return,
conditional and yield inference in the exact generated compiler module.

Propagate already checked declaration/lambda/let result types into nested
generator IIFEs. Add explicit __ps$Computation<T> result annotations. No new
language semantics, any/cast bypass, checker weakening or changed limits.
Unknown subexpression types retain existing inference. Existing untyped
expression consumers remain byte-compatible, with an all-input fuel induction
against the retained old context visitor. The common worker owns both modes.

Run the unchanged independent TypeScript G1/G2/G3 pipeline, complete owned
closure audits for both grammars, frozen ten-case corpus, official separate
admission, strict original/transformed IR and fixed points. This prototype is
not qualified or integrated until actual Linux results and fresh normal
seven-backend qualification. No package publication or merge.

Follow-up measured execution correction: the existing structured tail emitter
has a generator mode for ordinary calls. It retains strict typed expression
preflight, the same generator runtime and exact call-by-value argument order.
Tail self calls update all parameters together after evaluating arguments;
ordinary calls yield through the existing driver. Alias escape, unsafe binding
shadowing, unsupported types and fuel failures retain the original fallback.
An all-input native fuel induction preserves the legacy pure-tail emitter.
The generated mode stays isolated pending real compiler and regression evidence.
