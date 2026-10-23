# Same-source Rust build-profile comparison

The checked lexer-accumulator compiler at source 64e497ff passes all-input lexer
proofs (both grammars), 320 cases, 100001 tokens each, all existing regressions,
both full grammar audits and all ten actual G1 cases. Level-0 G2 reaches the
unchanged hard deadline at 240041 ms rather than the earlier early stack failure.
Build exactly that compiler source using established release optimization level 1.
Record profile/target build events and compare actual compiler requests. This is
not a bound increase, source-semantics change or qualification claim. Both target
profiles retain strict checking, reviewed lock/tool pins and the independent host.
