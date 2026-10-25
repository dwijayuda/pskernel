# Unary application congruence candidate — 2026-10-25

This is an isolated, unqualified production candidate. Integration remains
`dbd9db47bd8ef184583bcd5ae3feb38f3ce612c5`.
The candidate production tree is `7e92ffc478e060d282844c00f4d91e767a9894ef`.
Only `Checker/ExprV2/DefEq/FullShape.lean` and the new
`Checker/ExprV2/DefEq/UnarySpines.lean` differ from that integration source.

## Demonstrated failure and prerequisite evidence

The exact original Church body is SHA256
`85526c244d94e9710a6be432164c054c742d8f7c1d3ca0d8580d0874f7815a47`;
the header-adapted input is
`443428491e773dc131b1655bf72312517ddc29010112bb8bb241a48ab55c51c1`.
The independent admitted prefix has three requests, 197 original nodes,
249 owned nodes and five declarations.

The unchanged native/generated stage probe passed in run40197021041 at
`6553607f02a9dd1768cfc5c86922c75975d87af9`.
Its actual41-member ZIP12600726837 (3,138,376 bytes,
SHA256559693ab32bf9d4fb8b46ba14e33b0fbe403d9f7b0e338d8ab8a5093bd56ada1)
and ten source snapshots were independently read and hash-checked.
All four original/staged native/generated processes reported
`kernel reduction budget exhausted` at4096.
The first failing stage is final-defeq; the four earlier stages pass.

Native trace run40197721809 at
`2a0f0f553d4fc92d43254abb32eeb3ba4364b2da` passed.
Its actual53-member ZIP12600008561 (3,157,646 bytes,
SHA2569da14cdfe7b0236ccb532d43693a8ba1d1700cc261afa7820b9b3f020f3e3eda)
and both original/instrumented files were independently read and hash-checked.
The trace shows repeated equality of applications whose same function is
fvar node2102, then core-WHNF at zero fuel on that fvar itself.
The trace preserves the original result, stages and admitted owner.

An ephemeral native prototype accepted unchanged Church admission and all
five real admission stages. Run40199575400 at
`5f162a0302ff2ce16bfb3c197e3044b8acb97e59` also checked nine actual
ordered axiom reports, with standard axioms only. Artifact12601946365:
3,176,745 bytes, SHA256857106b3dd85723348ab2ddea76badd04fd5d55d1b97ba696a0412180bef7ffe.
This prerequisite uses the prototype's literal Lean syntax, not the final
portable spelling. Do not inherit its pass to this changed production tree.

## Candidate behavior and proof scope

A read-only plan follows unary application argument edges only when both
functions are the same fvar node ID. Its finite structural budget comes from
validated node depths. At least two frames must cancel. The residual call
receives the original complete state and supplied owning DefEq callback;
semantic fuel is neither increased nor reset. Recursion-depth scopes are
preserved. Only a positive residual comparison bypasses the original rule.
False, error, unsupported decline, a short spine or a depth failure restarts
the existing rule from its original owner.

The nine local proofs cover the executable plan's recurrence, shared-head
lookup witnesses, preservation under an application-congruent relation and
a compatible arena interpretation, a successful-plan skipped-count bound,
termination under a decreasing rank, and the exact supplied callback owner.
These are local refinement obligations, not a global kernel soundness or
backend preservation theorem.

The new20-control generated harness checks real generated constructors,
exact residual IDs, structural exhaustion, conservative head selection,
one residual callback, nonpositive fallback, recursion-depth guards and
unchanged input owners. Complete native541, both full generated routes,
original Church acceptance at4096/60s/2048MiB/emptyPATH, independent ZIP
audit and real-case frozen A-B-B-A measurements remain required before adoption.

## Existing integration evidence

Fresh dbd fullArena40195396822 is terminal FAIL:173strict matches/193,
17host timeouts, one Church resource exhaustion, two separately classified
unsafe/partial agreements, zero generic unsupported outcomes. Exact generated
comparison ZIP12601145745 is1,132,103 bytes,
SHA256ca27db6f453ed2c7e32d9140bf813ccb9a7b36938c6487d470c5a55f0238c096.
The denominator and unsafe/partial classification remain unchanged.

A remains historically scoped qualified; B OPEN, C FAIL, D OPEN.
T06 mutual/nested ID admission, T07 fallback removal and T04 ingress/import
work remain separate obligations. Full DirectJS remains unsupported.
No main merge, force push or npm publication is authorized.
