/-!
Experimental PSC0-v7.2 compilation of the REAL shared Core expression tree.
This is a source/build conformance probe, not a kernel checker. It imports the
current in-repository Ps.Core.Expr rather than a vendored snapshot.
-/
import Ps.Core.Expr

def pskernelWasmGcSourceCoreProbe (value : Bool) : Bool :=
  let level : PsLevel := PsLevel.zero
  let expression : PsExpr := PsExpr.sortE level
  match expression with
  | .sortE _ => value
  | _ => false
