import Ps.KernelCore.Check
import PSC1Kernel.TypeChecker

def psKernelCoreCheckOrderingName (value : String) : PsKernelCoreName :=
  PsKernelCoreName.str PsKernelCoreName.anonymous value

def psReferenceCheckOrderingName (value : String) : PSC1Kernel.Name :=
  PSC1Kernel.Name.str PSC1Kernel.Name.anonymous value

def psKernelCoreCheckOrderingExactError
    (result : PsKernelCoreResult String PsKernelCoreExpr)
    (expected : String) : Bool :=
  match result with
  | PsKernelCoreResult.error actual => actual == expected
  | PsKernelCoreResult.ok _ => false

def psReferenceCheckOrderingExactError
    (result : Except String PSC1Kernel.Expr)
    (expected : String) : Bool :=
  match result with
  | Except.error actual => actual == expected
  | Except.ok _ => false

def psKernelCoreCheckOrderingParity : Bool :=
  let ku := psKernelCoreCheckOrderingName "u"
  let kpoly := psKernelCoreCheckOrderingName "unsafePoly"
  let ru := psReferenceCheckOrderingName "u"
  let rpoly := psReferenceCheckOrderingName "unsafePoly"
  let ktype := PsKernelCoreExpr.sort (PsKernelCoreLevel.param ku)
  let rtype := PSC1Kernel.Expr.sort (PSC1Kernel.Level.param ru)
  let kinfo := PsKernelCoreConstantInfo.axiomInfo {
    base := {
      name := kpoly
      levelParams := PsKernelCoreList.cons ku PsKernelCoreList.nil
      type := ktype
    }
    isUnsafe := true
  }
  let rinfo := PSC1Kernel.ConstantInfo.axiomInfo {
    base := { name := rpoly, levelParams := [ru], type := rtype }
    isUnsafe := true
  }
  let kenv := psKernelCoreEnvironmentAddUnchecked psKernelCoreEnvironmentEmpty kinfo
  let renv := PSC1Kernel.Environment.addUnchecked PSC1Kernel.Environment.empty rinfo
  let kexpr := PsKernelCoreExpr.const kpoly PsKernelCoreList.nil
  let rexpr := PSC1Kernel.Expr.const rpoly []
  let kresult := psKernelCoreCheck
    16 kenv psKernelCoreLocalContextEmpty PsKernelCoreDefinitionSafety.safe kexpr
  let rresult := PSC1Kernel.check
    { PSC1Kernel.CheckerContext.empty renv with safety := PSC1Kernel.DefinitionSafety.safe }
    rexpr
  psKernelCoreCheckOrderingExactError kresult "incorrect number of universe levels" &&
    psReferenceCheckOrderingExactError rresult "incorrect number of universe levels"

def main : IO Unit := do
  if !psKernelCoreCheckOrderingParity then
    throw (IO.userError "PSC2_KERNEL_CORE_CHECK_ORDERING: FAIL")
  IO.println "PSC2_KERNEL_CORE_CHECK_ORDERING: PASS"
