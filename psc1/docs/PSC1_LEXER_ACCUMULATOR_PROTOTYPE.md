# Token-list accumulator normalization

Exact closed Rust G2 replay 39898770508 at 8c2ff230 identifies repeated
psLexAllWorker$worker frames, after closed planning eliminated open generic
helpers. Both Lean and ProofScript lexer workers formerly reconstructed the
token list through recursive Except results. Accumulate reversed tokens and
reverse only on successful EOF; preserve original inputBound, fuel, cursors,
positions, error values/order and original exported worker signatures.
All-input inputBound/fuel/cursor/reversed-accumulator equalities against retained
original workers, finite trivia/error/boundary comparisons and 100001 tokens
per grammar must pass before actual generation. Same source in both branches.
No higher bounds, new compiler, token shortcut or backend-specific grammar.
