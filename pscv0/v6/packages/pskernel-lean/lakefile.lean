import Lake
open Lake DSL

package proofscriptKernelLeanStandalone

lean_lib PsFoundation where
  srcDir := "source/proofscript/foundation"
  roots := #[`Ps.Foundation.Name, `Ps.Foundation.Source, `Ps.Foundation.Diagnostic]

lean_lib PsCore where
  srcDir := "source/proofscript/core"
  roots := #[
    `Ps.Core.Level, `Ps.Core.Expr, `Ps.Core.Abstract, `Ps.Core.Builtin,
    `Ps.Core.LevelSubst, `Ps.Core.Equality, `Ps.Core.Subst, `Ps.Core.Declaration
  ]

lean_lib PsEnvironment where
  srcDir := "source/proofscript/environment"
  roots := #[
    `Ps.Environment.Basic, `Ps.Environment.LocalContext, `Ps.Environment.Instances,
    `Ps.Environment.Resolve, `Ps.Environment.Prelude,
    `Ps.Environment.SelfHostPrelude, `Ps.Environment.SelfHostProd
  ]

lean_lib PsBridge where
  srcDir := "source/proofscript/bridge"
  roots := #[
    `Ps.Bridge.Json, `Ps.Bridge.CheckedAdmissions, `Ps.Bridge.Codec, `Ps.Bridge.Protocol
  ]

lean_lib PsKernelLeanProvider where
  srcDir := "source/proofscript/provider"
  roots := #[
    `PsKernelLean.Error, `PsKernelLean.Convert, `PsKernelLean.Prelude,
    `PsKernelLean.Protocol, `PsKernelLean.Admission, `PsKernelLean.Response
  ]

@[default_target]
lean_exe psc2_lean_kernel_provider where
  srcDir := "source/proofscript/provider"
  root := `PsKernelLean.Main
