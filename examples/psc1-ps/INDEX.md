# Complete example index

| Project | Topic | Expected |
| --- | --- | --- |
| [Typed values](01-basics/01-typed-values/README.md) | Declare Nat, Bool, and String values explicitly, then select a numeric result with a Boolean flag. The result is 12. | checked |
| [Arithmetic and parentheses](01-basics/02-arithmetic-precedence/README.md) | Compare ordinary arithmetic precedence with explicit grouping in a small order calculation. The final bill is 12000. | checked |
| [Natural-number subtraction](01-basics/03-natural-subtraction/README.md) | Use subtraction for a remaining stock count and observe that Nat subtraction stops at zero. The result is zero. | checked |
| [Division and remainder](01-basics/04-division-and-remainder/README.md) | Split 29 items into boxes of six and reconstruct the original count from the quotient and remainder. The result is 29. | checked |
| [Reusable functions with several arguments](01-basics/05-reusable-functions/README.md) | Define rectangle area and perimeter functions, then call them with different dimensions. The final area is 35. | checked |
| [Conditionals produce values](01-basics/06-conditional-values/README.md) | Select a status message and a shipping fee using Boolean inputs. The final message is Ready to collect. | checked |
| [Combine Boolean rules](01-basics/07-boolean-rules/README.md) | Use conjunction, disjunction, and negation for two small scheduling rules. The final combined result is true. | checked |
| [Comparisons and Boolean equality](01-basics/08-comparisons-and-equality/README.md) | Use a threshold comparison as an if condition and == as a Bool-valued equality check. The final discount is 10. | checked |
| [Name intermediate calculations with let](01-basics/09-local-let-bindings/README.md) | Break a ticket-price calculation into typed local steps. Three tickets at 4000 with a 1000 discount and 500 fee produce 11500. | checked |
| [Functions as local values](01-basics/10-lambda-values/README.md) | Give two anonymous functions explicit function types and call them inside a local calculation. The result is 15. | checked |
| [Pass a function as an argument](01-basics/11-apply-a-function-twice/README.md) | Write applyTwice once and reuse it with two different transformations. Incrementing twice from 8 produces 10. | checked |
| [Return a function that remembers a value](01-basics/12-return-a-closure/README.md) | Build an adder that captures its offset, then call the returned function. Adding seven to 35 produces 42. | checked |
| [Compose two transformations](01-basics/13-function-composition/README.md) | Combine an increment with a doubling operation in both orders. The final result of doubling after incrementing 5 is 12. | checked |
| [Organize declarations in a namespace](01-basics/14-namespaces/README.md) | Group related pricing declarations and access them through qualified names. Two tickets plus one booking fee produce 8500. | checked |
| [One function for several types](01-basics/15-polymorphic-identity/README.md) | Use an implicit type parameter to reuse identity for Nat, Bool, and String. The final Nat result is 17. | checked |
| [String parameters and admitted operations](01-basics/16-string-functions/README.md) | Build a greeting using the exact String operations exposed by the current compiler fixtures, and inspect its length. The greeting is Hello, Ada!. | checked |
| [Traffic signals: an enum and exhaustive matching](02-data/01-traffic-signals/README.md) | Represent three states with nullary constructors and translate the selected state into a waiting time. | checked |
| [Commands with different payloads](02-data/02-commands-with-payloads/README.md) | Use one sum type for a reset command, an increment, and a command with two numeric fields. | checked |
| [Optional values and an explicit default](02-data/03-optional-values/README.md) | Handle an optional membership discount with Option.none and Option.some before calculating a price. | checked |
| [A generic Maybe type and reusable fallback](02-data/04-generic-maybe/README.md) | Define a polymorphic optional container and instantiate its generic getOr function for Nat and Bool. | checked |
| [A two-parameter Either type](02-data/05-generic-either/README.md) | Represent alternatives with different payload types and handle each alternative without a cast. | checked |
| [Nested tuples and destructuring](02-data/06-nested-tuples/README.md) | Unpack a nested product into local names and use the fields in a small weighted-score calculation. | checked |
| [A rectangle record with field projections](02-data/07-rectangle-record/README.md) | Construct a record and read its named fields to calculate area and perimeter. | checked |
| [Nested records for a shipping calculation](02-data/08-nested-records/README.md) | Embed a destination inside a parcel and follow nested field projections to calculate a delivery cost. | checked |
| [A record with a type parameter](02-data/09-generic-record/README.md) | Use a generic record that pairs a typed value with a numeric serial and read both fields. | checked |
| [A custom generic list and structural length](02-data/10-custom-list-length/README.md) | Build a recursive generic container and count its elements by recursing on the exposed tail. | checked |
| [Transforming an immutable recursive list](02-data/11-immutable-list-transform/README.md) | Rebuild a list with transformed elements, sum both versions, and keep the original available. | checked |
| [Structural recursion over natural numbers](02-data/12-triangular-recursion/README.md) | Compute a triangular number by matching on Nat.zero and Nat.succ and recursing on the predecessor. | checked |
| [Factorial as a recursive product](02-data/13-factorial-recursion/README.md) | Use a multiplicative base case and a structurally smaller recursive call to define factorial. | checked |
| [Recursion with an invariant parameter](02-data/14-power-recursion/README.md) | Compute natural powers while decreasing the exponent and preserving the base argument across recursive calls. | checked |
| [Folding a binary tree](02-data/15-binary-tree-total/README.md) | Traverse both recursive children to calculate a leaf total and a leaf count from the same tree. | checked |
| [A tiny expression interpreter](02-data/16-expression-interpreter/README.md) | Represent arithmetic syntax as a recursive data type and evaluate its tree with a total interpreter. | checked |
| [Mutable accumulator](03-control-flow/01-mutable-accumulator/README.md) | Update a local accumulator inside a checked Id block. The final balance is 12. | checked |
| [Branch updates](03-control-flow/02-branch-updates/README.md) | A branch updates a local value and the continuation sees that update. The result is 15. | checked |
| [Loop over a list](03-control-flow/03-list-loop/README.md) | Add the elements of a finite list. The total is 12. | checked |
| [Loop over an array](03-control-flow/04-array-loop/README.md) | Multiply the entries of an array literal. The product is 105. | checked |
| [Half-open numeric ranges](03-control-flow/05-range-loop/README.md) | Visit 1,2,3,4,5 using a half-open range; the result is 15. | checked |
| [Return early from a loop](03-control-flow/06-early-return/README.md) | Find the first element greater than five. The return leaves the enclosing Id block; the result is 9. | checked |
| [Nested finite loops](03-control-flow/07-nested-loops/README.md) | Add every product in a 3 by 3 multiplication table. The result is 36. | checked |
| [A closure captures the current value](03-control-flow/08-captured-local-value/README.md) | A closure keeps the value present when it is created. Updating the later local binding does not change the captured value; the result is 7. | checked |
| [Identity: reuse an existing proof](04-proofs/01-identity/README.md) | A proof of P is sufficient to establish P. Also writes the same implication as an explicit lambda. | checked |
| [Introduce an implication](04-proofs/02-implication-introduction/README.md) | Keep a proof of P while accepting an additional assumption Q; the result proves P -> Q -> P. | checked |
| [Apply an implication](04-proofs/03-modus-ponens/README.md) | Apply a proof of P -> Q to a proof of P to obtain a proof of Q. | checked |
| [Compose two implications](04-proofs/04-implication-composition/README.md) | Chain P -> Q with Q -> R to prove P -> R. | checked |
| [Change the order of assumptions](04-proofs/05-swap-assumptions/README.md) | Transform P -> Q -> R into Q -> P -> R without changing the conclusion. | checked |
| [Use one assumption twice](04-proofs/06-reuse-an-assumption/README.md) | A proof of P can fill both P inputs of P -> P -> Q. | checked |
| [Name an intermediate proof](04-proofs/07-local-proof-step/README.md) | Use a typed immutable let binding to make a two-step argument explicit. | checked |
| [Construct a conjunction with functions](04-proofs/08-conjunction-introduction/README.md) | Define a Church encoding of conjunction and prove its introduction rule from proofs of both components. | checked |
| [Extract either part of a conjunction](04-proofs/09-conjunction-projections/README.md) | Select the left or right proof from the local Church encoding of conjunction. | checked |
| [Swap the components of a conjunction](04-proofs/10-conjunction-commutativity/README.md) | Prove Both(P, Q) -> Both(Q, P) by changing the order supplied to the consumer. | checked |
| [Choose a side of a disjunction](04-proofs/11-disjunction-introduction/README.md) | Construct the local Church encoding of Either(P, Q) from a proof of P or a proof of Q. | checked |
| [Reason from both possible cases](04-proofs/12-disjunction-elimination/README.md) | To obtain R from Either(P, Q), supply one proof function for each possibility. | checked |
| [Implications in both directions](04-proofs/13-logical-equivalence/README.md) | Use a local Church encoding of equivalence to prove reflexivity and symmetry. | checked |
| [Reflexivity of explicitly defined Leibniz equality](04-proofs/14-leibniz-equality-reflexivity/README.md) | For every predicate, a proof at n is already a proof at n; this establishes Same(n, n). Same is defined locally, not the built-in Eq. | checked |
| [Transport a proof along Leibniz equality](04-proofs/15-leibniz-equality-substitution/README.md) | Apply Same(a, b) to a predicate and its proof at a, obtaining a proof at b. This is substitution for the equality defined in Support.ps. | checked |
| [Reverse and compose Leibniz equality](04-proofs/16-leibniz-equality-symmetry-transitivity/README.md) | Derive symmetry and transitivity from the explicitly defined predicate-transport equality, using reflexivity and function composition. | checked |
| [Import a helper module](05-multi-file-projects/01-import-a-helper/README.md) | Keep a reusable function in a separate source module, then call it from Main. The result is 42. | checked |
| [Three-module calculation pipeline](05-multi-file-projects/02-three-module-pipeline/README.md) | Compose a transitive dependency chain: Units -> Invoice -> Main. The final total is 950 cents. | checked |
| [Separate a data model from its policy](05-multi-file-projects/03-data-and-policy/README.md) | Define a mode in one module and a scalar policy in another. Main exposes a simple Nat result of 10. | checked |
| [Intentional error: Bool supplied where Nat is required](90-intentional-errors/01-bool-is-not-nat/README.md) | The value true has type Bool, so it cannot initialize a Nat. Repair by replacing true with 42. | rejected |
| [Intentional error: unresolved identifier](90-intentional-errors/02-unknown-name/README.md) | missingNumber has no declaration or local binding. Repair by replacing it with a natural-number literal or defining it before use. | rejected |
| [Intentional error: a number cannot prove an arbitrary proposition](90-intentional-errors/03-number-is-not-a-proof/README.md) | The theorem claims a proof of arbitrary P but supplies the Nat literal 0. Repair by accepting a premise of type P and returning it. | rejected |
| [Intentional error: a function receives the wrong argument type](90-intentional-errors/04-wrong-call-argument/README.md) | successor requires Nat, but its call supplies false. Repair the call to successor(41). | rejected |
| [Intentional error: unfinished definition](90-intentional-errors/05-missing-definition-body/README.md) | The assignment marker must be followed by a term. Repair by adding 42 after :=. | rejected |
| [Intentional error: unparenthesized comparison chain](90-intentional-errors/06-comparison-chain/README.md) | The selected comparison operators do not associate, so 1 < 2 < 3 is refused. A simple repair is an if condition containing one comparison. | rejected |
