# Checked scalar closed-plan experiment

Exact IR inventory 39896155384 shows fourteen recursive polymorphic curried
structural helpers unchanged by the generic route. Source wrapper arity does
not change the synthesized recursive helper. The existing closed worker pass
deliberately skips type-parameter declarations.

For a nonempty public interface of nongeneric primitive-only function signatures,
try the existing strict checked closed specialization/worker plan. Keep the
existing generic route for other interfaces and as fallback if that optimization
cannot plan the program. Original/post-plan public API checks, strict IR and
independent logical admission remain. No new compiler implementation or public
nominal/generic ABI substitution. Native regressions cover scalar specialization
and preservation of generic/callback/empty-interface eligibility.

Use the same source for Rust and TypeScript. Rust's experimental release build
has opt-level=0 to measure complete generated workloads without the observed
LLVM optimization build bottleneck; exact profile is recorded in the artifact.
Type/borrow checks, forbid-unsafe generated code, lock/tool pins, fifteen-minute
jobs and 240000 ms/32 MiB child limits are unchanged. No optimization level
change is a correctness or performance qualification claim. Compare actual
generation results before promotion; retain generic mode and all seven backends.
