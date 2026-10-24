import Ps.BackendPython.Portable

-- Native compatibility surface. The single portable implementation is shared
-- with every generated compiler; no compiler semantics live in this adapter.
def psPythonEmitModule (validated : PsValidatedIrModule) (publicNames : List String)
    (ioAbi : Bool := false) : Except String PsPythonOutput :=
  psPythonEmitModuleWithIo validated publicNames ioAbi
