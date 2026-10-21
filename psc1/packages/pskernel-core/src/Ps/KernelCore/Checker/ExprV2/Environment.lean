import Ps.KernelCore.Core.ExprScalar

/-
Definition references retained only after successful complete declaration
admission in one checked DAG batch. Values belong to that batch's canonical
input arena and all of its append-only continuations.

This is an internal lookup table, not an untrusted admission API or a proof
certificate. The public DAG boundary creates it empty. It is never returned in
the original kernel session and never reused with another arena or environment.
-/
structure PsKernelExprV2DefinitionRef where
  name : PsKernelName
  levelParams : List PsKernelName
  value : Nat

def psKernelExprV2DefinitionRefFind
    (definitions : List PsKernelExprV2DefinitionRef) :
    PsKernelName -> Option PsKernelExprV2DefinitionRef :=
  match definitions with
  | List.nil =>
      fun (_name : PsKernelName) => Option.none
  | List.cons first rest =>
      let smaller :=
        fun (nextName : PsKernelName) =>
          let recur := psKernelExprV2DefinitionRefFind rest;
          recur nextName;
      fun (name : PsKernelName) =>
        if psKernelNameEq first.name name then Option.some first
        else smaller name
