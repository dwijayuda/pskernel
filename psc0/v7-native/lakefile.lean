import Lake
open Lake DSL

package pscv0Native

-- The official 4.35.0 toolchain compiles the shared sources directly.
-- The parent source workspace uses the same stable toolchain.
require proofscriptSelfhost from ".."

-- Host-only conversion and canonical decoder; no provider executable/kernel build.
-- Protocol's historical 4.34 identity functions are not used by NativeV7.
lean_lib PsKernelLean where
  srcDir := "../packages/pskernel-lean/provider"
  roots := #[`PsKernelLean.Error, `PsKernelLean.Convert,
    `PsKernelLean.Protocol, `PsKernelLean.Prelude, `PsKernelLean.Admission]

lean_lib PsV7Host where
  srcDir := "../host/src"
  roots := #[`Ps.Host.NativeV7, `Ps.Host.PrimitiveAudit, `Ps.Host.StandardClosure, `Ps.Host.StandardSource, `Ps.Host.StandardExport, `Ps.Host.RecursorSource, `Ps.Host.StandardManifest, `Ps.Host.FloatConstructive, `Ps.Host.FloatCanonical,
    `Ps.Host.FloatCanonicalContracts, `Ps.Host.MonotonicityProbe]

lean_lib PsV7ParserChecks where
  srcDir := "../scripts"
  roots := #[`Pscv0M1Harness]

-- Independent official Lean 4.35.0 GetElem source oracle. It is not part of
-- the portable compiler, restored Standard environment or trusted checker.
lean_lib PsV7GetElemOracle where
  srcDir := "../test"
  roots := #[`Pscv0GetElemOracle]

lean_lib PsV7PlatformChecks where
  srcDir := "../test"
  roots := #[`Pscv0PlatformTests]

-- Shared typed-predefinition evidence invoked by the structural fixture.
lean_lib PsV7M3PreDefinitionChecks where
  srcDir := "../test"
  roots := #[`Pscv0M3PreDefinitions]

-- Constructor-directed indexed defaults invoked by the group proof fixture.
lean_lib PsV7M3IndexedInhabitedChecks where
  srcDir := "../test"
  roots := #[`Pscv0M3IndexedInhabited]

-- Source-only omitted-result evidence invoked by the existing where fixture.
lean_lib PsV7M3ResultInferenceChecks where
  srcDir := "../test"
  roots := #[`Pscv0M3ResultInference, `Pscv0M3InputParity]

-- Independently checked native Float F1 constructive dependency oracle.
-- This remains outside the selected Standard and executable compiler.
lean_lib PsV7FloatConstructiveOracle where
  srcDir := "../test"
  roots := #[`Pscv0FloatConstructiveOracle]

@[default_target]
lean_exe pscv0_native where
  srcDir := "../scripts"
  root := `Pscv0Native
  -- Persistent-extension import runs pinned Init initializers during the WF audit.
  supportInterpreter := true

lean_exe pscv0_native_checks where
  srcDir := "../test"
  root := `Pscv0NativeTests

lean_exe pscv0_wasm_checks where
  srcDir := "../test"
  root := `Pscv0WasmTests

-- Host-only measurements against the pinned native Lean library.
lean_exe pscv0_m1_performance where
  srcDir := "../test"
  root := `Pscv0M1Performance

-- The host and portable libraries share Ps.*. Let Lake supply exact module
-- dependencies instead of an ad hoc LEAN_PATH namespace overlay.
-- Host-owned module dependencies select PsV7Host during native order authoring.
lean_exe pscv0_m3_partial_fixpoint_export where
  srcDir := "../scripts"
  root := `Pscv0M3PartialFixpointExport
  supportInterpreter := true

-- Pinned recursor metadata authoring uses the same native host owner.
lean_exe pscv0_m3_recursor_surface_export where
  srcDir := "../scripts"
  root := `Pscv0M3RecursorSurfaceExport
  supportInterpreter := true

lean_exe pscv0_m3_partial_fixpoint_probe where
  srcDir := "../scripts"
  root := `Pscv0M3PartialFixpointProbe
  supportInterpreter := true

lean_exe pscv0_m3_noncomputable where
  srcDir := "../test"
  root := `Pscv0M3Noncomputable

lean_exe pscv0_m3_partial_fixpoint where
  srcDir := "../test"
  root := `Pscv0M3PartialFixpoint

lean_exe pscv0_m3_recursive_deriving where
  srcDir := "../test"
  root := `Pscv0M3RecursiveDeriving

lean_exe pscv0_m3_inductive_groups where
  srcDir := "../test"
  root := `Pscv0M3InductiveGroups

lean_exe pscv0_m3_well_founded where
  srcDir := "../test"
  root := `Pscv0M3WellFounded

lean_exe pscv0_m3_inductive_runtime where
  srcDir := "../test"
  root := `Pscv0M3InductiveRuntime

lean_exe pscv0_m3_inductive_match where
  srcDir := "../test"
  root := `Pscv0M3InductiveMatch

lean_exe pscv0_m3_mutual_partial where
  srcDir := "../test"
  root := `Pscv0M3MutualPartial

lean_exe pscv0_m3_inductive_deriving where
  srcDir := "../test"
  root := `Pscv0M3InductiveDeriving

lean_exe pscv0_m3_mutual_structural where
  srcDir := "../test"
  root := `Pscv0M3MutualStructural

lean_exe pscv0_m3_nested_inductive where
  srcDir := "../test"
  root := `Pscv0M3NestedInductive

lean_exe pscv0_m3_where where
  srcDir := "../test"
  root := `Pscv0M3Where

lean_exe pscv0_m3_nested_deriving where
  srcDir := "../test"
  root := `Pscv0M3NestedDeriving

lean_exe pscv0_m3_group_proof_deriving where
  srcDir := "../test"
  root := `Pscv0M3GroupProofDeriving

lean_exe pscv0_m3_empty_dictionaries where
  srcDir := "../test"
  root := `Pscv0M3EmptyDictionaries

-- Standalone PSum library authoring for the typed mutual WF domain.
lean_exe pscv0_m3_mutual_well_founded_export where
  srcDir := "../scripts"
  root := `Pscv0M3MutualWellFoundedExport
  supportInterpreter := true

-- Focused typed-packing proof probe; separate from source mutual WF admission.
lean_exe pscv0_m3_mutual_packing where
  srcDir := "../test"
  root := `Pscv0M3MutualPacking
