import Lake
open Lake DSL

package proofscriptSelfhost

lean_lib PsFoundation where
  srcDir := "packages/foundation/src"
  roots := #[
    `Ps.Foundation.Name,
    `Ps.Foundation.Source,
    `Ps.Foundation.Diagnostic
  ]

lean_lib PsSyntax where
  srcDir := "packages/syntax/src"
  roots := #[`Ps.Syntax.Token]

lean_lib PsCore where
  srcDir := "packages/core/src"
  roots := #[
    `Ps.Core.Level,
    `Ps.Core.Expr,
    `Ps.Core.Equality,
    `Ps.Core.Subst,
    `Ps.Core.Declaration
  ]

lean_lib PsEnvironment where
  srcDir := "packages/environment/src"
  roots := #[
    `Ps.Environment.Basic,
    `Ps.Environment.LocalContext,
    `Ps.Environment.Resolve
  ]

lean_lib PsProject where
  srcDir := "packages/project/src"
  roots := #[`Ps.Project.ModuleGraph]

lean_lib PsMeta where
  srcDir := "packages/meta/src"
  roots := #[
    `Ps.Meta.Context,
    `Ps.Meta.Reduce
  ]

@[default_target]
lean_exe psc1 where
  srcDir := "src"
  root := `Main
