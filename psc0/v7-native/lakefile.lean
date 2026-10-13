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
  roots := #[`Ps.Host.NativeV7, `Ps.Host.PrimitiveAudit, `Ps.Host.StandardClosure, `Ps.Host.StandardSource, `Ps.Host.StandardExport]

lean_lib PsV7ParserChecks where
  srcDir := "../scripts"
  roots := #[`Pscv0M1Harness]

-- Independent official Lean 4.35.0 GetElem source oracle. It is not part of
-- the portable compiler, restored Standard environment or trusted checker.
lean_lib PsV7GetElemOracle where
  srcDir := "../test"
  roots := #[`Pscv0GetElemOracle]

@[default_target]
lean_exe pscv0_native where
  srcDir := "../scripts"
  root := `Pscv0Native

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
