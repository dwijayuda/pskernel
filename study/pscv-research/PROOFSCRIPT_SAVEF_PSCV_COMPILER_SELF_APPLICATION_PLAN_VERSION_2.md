# ProofScript SAVEF PSCV Compiler Self-Application Plan — Version 2

**Status:** research, architecture, implementation, and experimental plan; non-normative.

**Working identity:** SAVEF-COMPILER-SELFAPP-v2.

**Research snapshot:** 2026-10-06.

**Target architecture/plan score:** **9.59 / 10**

**Current repository readiness for the complete experiment:** **approximately 5.72 / 10**

**Repository:** dwijayuda/pskernel

**Primary PSCV implementation baseline:** branch psc2/pscv-direct-backends, directory psc15selfhost/

**Supporting branches:**

- pscv/prove-pskernel-core-v1
- pscv/selfhost-poc-v1

**Critical assumption for this plan:**

> Do not wait for the current self-host PSCV compiler to implement every PSCV language feature. Treat the pinned Lean compiler as the immediate reference/bootstrap compiler for the PSCV Lean subset. Assume the PSCV language surface required by the experiment is available through Lean and can be compiled to native executables now.

This assumption changes the implementation strategy substantially.

SAVEF infrastructure, proof sidecars, compiler passes, FactoryBench tooling, semantic interfaces, and new compiler architecture may be written in the PSCV-compatible Lean subset and compiled by Lean immediately. The current self-host compiler becomes one implementation lane that later converges on the same semantic contracts.

---

# 1. Executive decision

The strongest way to prove SAVEF works is:

> Use SAVEF to improve, specify, prove, rebuild, and then evolve the PSCV compiler itself, while measuring whether the compiler becomes cheaper to improve as accepted compiler knowledge accumulates.

The experiment has two separate goals.

## Goal A — verified compiler architecture

Transform the compiler into a system where every important semantic stage has:

- an explicit input artifact;
- an explicit output artifact;
- a versioned pass identity;
- a machine-checkable invariant;
- an explicit preservation/refinement relation;
- proof or validation evidence;
- a deterministic content identity;
- a stable public semantic interface;
- incremental invalidation rules.

## Goal B — prove SAVEF's compounding hypothesis

Show experimentally that:

~~~text
same model
same tool policy
same compiler-task distribution
same assurance gates
same resource budget

larger accepted compiler knowledge graph
    =>
higher accepted-task success
or
lower model tokens
or
lower human intervention
or
lower proof repair cost
or
lower duplicated code/proof effort
~~~

without reducing assurance.

The compiler is both the system being built and the knowledge factory used to build its next version.

---

# 2. The most important revision from Version 1

Version 1 treated the present 55-module self-host compiler as the primary implementation subject and tried to preserve that closure while adding proof knowledge around it.

Version 2 keeps that useful experiment but removes an unnecessary dependency:

> SAVEF does not need to wait for the self-host compiler feature frontier.

Because PSCV is intentionally a subset/profile of Lean semantics, and because the experiment assumes the required PSCV subset already compiles through Lean, the architecture should use Lean as a reference bootstrap/compiler lane immediately.

The new architecture has three compiler lanes.

~~~text
                    PSCV SOURCE / COMPILER SOURCE
                              |
              +---------------+---------------+
              |               |               |
              v               v               v
      Lean Reference      PSCV Semantic    Self-host/Direct
          Lane               Lane              Lane
              |               |               |
      Lean elaborator      owned parser/    JS / Wasm /
      + kernel + LCNF      elab/Core/IR      future native
      + native codegen         |               |
              |               |               |
              +---------------+---------------+
                              |
                              v
                   shared semantic contracts
                              |
                              v
                         SAVEF knowledge
~~~

The lanes may produce different executables.

They must converge on shared semantic identities and evidence relations.

---

# 3. Why Lean is the correct bootstrap lane

Lean's processing pipeline separates parsing, macro expansion, elaboration, kernel checking, and compilation.

The trusted kernel checks elaborated core declarations independently from the compiler.

The compiler then transforms computational content into executable code. The compiler and kernel are deliberately distinct subsystems.

This is exactly the separation PSCV needs.

Research source:
https://lean-lang.org/doc/reference/latest/Elaboration-and-Compilation/

---

# 4. Lean's recursion split is especially relevant

Lean elaborates a recursive function to a pre-definition.

The compiler receives a computational form retaining programmer-oriented recursion needed for predictable execution.

The kernel receives a logically justified form where recursion has been transformed into primitive recursors, well-founded recursion, or another accepted logical construction.

Architectural principle:

> The representation best suited to logical checking does not have to be the representation best suited to compilation.

PSCV should preserve this distinction.

SAVEF knowledge should explicitly state which semantic relation connects logical checked source and runtime-oriented compiler representation rather than requiring them to be physically identical.

---

# 5. Lean compiler architecture lessons

The modern Lean compiler uses Lean Compiler Normal Form, LCNF, as its primary compiler IR.

Lean 4.30 completed end-to-end C code generation through the new LCNF backend.

LCNF is based on A-normal form and has explicit phase distinctions and a pass manager.

Research sources:

- https://lean-lang.org/doc/reference/latest/releases/v4.30.0/
- https://lean-lang.org/doc/api/Lean/Compiler/LCNF/Basic.html
- https://lean-lang.org/doc/api/Lean/Compiler/LCNF/PassManager.html
- https://lean-lang.org/doc/api/Lean/Compiler/LCNF/Passes.html

The architectural lessons are more important than copying LCNF syntax.

