import Ps.Foundation.Name
import Ps.Foundation.Diagnostic
import Ps.Syntax.Token
import Ps.Core.Declaration
import Ps.Core.Subst
import Ps.Core.Equality
import Ps.Core.LevelSubst
import Ps.Core.Builtin
import Ps.Core.Abstract
import Ps.Environment.Basic
import Ps.Environment.LocalContext
import Ps.Environment.Resolve
import Ps.Meta.Context
import Ps.Meta.Reduce
import Ps.Project.ModuleGraph

def main : IO Unit :=
  IO.println "ProofScript PSC1 Lean bootstrap"
