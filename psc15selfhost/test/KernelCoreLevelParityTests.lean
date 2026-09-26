import Ps.KernelCore.Level
import PSC1Kernel.Level

def psKernelCoreLevelParity : Bool :=
  let kcAnon := PsKernelCoreName.anonymous
  let kcU := PsKernelCoreName.str kcAnon "u"
  let kcV := PsKernelCoreName.str kcAnon "v"
  let kcZero := PsKernelCoreLevel.zero
  let kcOne := PsKernelCoreLevel.succ kcZero
  let kcUParam := PsKernelCoreLevel.param kcU
  let kcVParam := PsKernelCoreLevel.param kcV
  let kcMaxUV := PsKernelCoreLevel.max kcUParam kcVParam
  let kcMaxVU := PsKernelCoreLevel.max kcVParam kcUParam
  let kcIMaxZero := PsKernelCoreLevel.imax kcOne kcZero
  let kcNested := PsKernelCoreLevel.succ (PsKernelCoreLevel.max kcUParam kcVParam)
  let kcMVar := PsKernelCoreLevel.mvar kcU
  let refAnon := PSC1Kernel.Name.anonymous
  let refU := PSC1Kernel.Name.str refAnon "u"
  let refV := PSC1Kernel.Name.str refAnon "v"
  let refZero := PSC1Kernel.Level.zero
  let refOne := PSC1Kernel.Level.succ refZero
  let refUParam := PSC1Kernel.Level.param refU
  let refVParam := PSC1Kernel.Level.param refV
  let refMaxUV := PSC1Kernel.Level.max refUParam refVParam
  let refMaxVU := PSC1Kernel.Level.max refVParam refUParam
  let refIMaxZero := PSC1Kernel.Level.imax refOne refZero
  let refNested := PSC1Kernel.Level.succ (PSC1Kernel.Level.max refUParam refVParam)
  (psKernelCoreLevelEquivalent kcZero kcZero == PSC1Kernel.Level.equivalent refZero refZero) &&
  (psKernelCoreLevelEquivalent kcOne kcOne == PSC1Kernel.Level.equivalent refOne refOne) &&
  (psKernelCoreLevelEquivalent kcMaxUV kcMaxVU == PSC1Kernel.Level.equivalent refMaxUV refMaxVU) &&
  (psKernelCoreLevelEquivalent kcIMaxZero kcZero == PSC1Kernel.Level.equivalent refIMaxZero refZero) &&
  (psKernelCoreLevelEq
      (psKernelCoreLevelInstantiateParams kcUParam [kcU] [kcOne])
      kcOne ==
    PSC1Kernel.Level.eq
      (PSC1Kernel.Level.instantiateParams refUParam [refU] [refOne])
      refOne) &&
  (psKernelCoreLevelEq
      (psKernelCoreLevelInstantiateParams kcVParam [kcU] [kcOne])
      kcVParam ==
    PSC1Kernel.Level.eq
      (PSC1Kernel.Level.instantiateParams refVParam [refU] [refOne])
      refVParam) &&
  (psKernelCoreLevelEq
      (psKernelCoreLevelInstantiateParams kcNested [kcU, kcV] [kcOne, kcZero])
      (PsKernelCoreLevel.succ kcOne) ==
    PSC1Kernel.Level.eq
      (PSC1Kernel.Level.instantiateParams refNested [refU, refV] [refOne, refZero])
      (PSC1Kernel.Level.succ refOne)) &&
  psKernelCoreLevelHasMVar kcMVar &&
  (!psKernelCoreLevelHasMVar kcNested)

def main : IO Unit := do
  if psKernelCoreLevelParity then
    IO.println "PSC2_KERNEL_CORE_LEVEL_PARITY: PASS"
  else
    throw (IO.userError "PSC2_KERNEL_CORE_LEVEL_PARITY: FAIL")
