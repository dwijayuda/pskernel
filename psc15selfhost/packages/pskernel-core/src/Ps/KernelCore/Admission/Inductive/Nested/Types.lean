import Ps.KernelCore.Admission.Inductive.Mutual.Admission

/-
Shared data for nested-inductive discovery and flattening.

These structures record the auxiliary families generated while flattening
nested recursive occurrences. Discovery, parameter rebasing, flattening, and
restoration are separated into later theory modules.
-/

structure PsKernelSimpleNestedAuxCtorMap where
  auxCtor : PsKernelName
  outerCtor : PsKernelName

structure PsKernelSimpleNestedAuxFamily where
  auxName : PsKernelName
  outerName : PsKernelName
  outerLevels : List PsKernelLevel
  fixedParams : List PsKernelExpr
  nestedTemplate : PsKernelExpr
  ctorMap : List PsKernelSimpleNestedAuxCtorMap

structure PsKernelSimpleNestedMapState where
  aux : List PsKernelSimpleNestedAuxFamily
  fresh : Nat
  created : List PsKernelSimpleMutualTypeDecl

